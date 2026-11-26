# Agentic VM setup

How to set up `code` (`code.vm.lan`): a small, headless NixOS VM where coding agents run
away from your personal machines. It's built from this flake (`nixosConfigurations.code`),
so the whole VM is reproducible and is redeployed from your desktop. It runs on the Proxmox
VE host `vm.lan`; clients log in as `agent@code.vm.lan`, deploys go to `admin@code.vm.lan`.

The steps work on any KVM/QEMU host. The [Proxmox VE](#proxmox-ve) and
[Fedora desktop (virt-manager)](#fedora-desktop-virt-manager) sections cover the
host-specific parts.

**History:** this VM was called `agent-vm` and was meant for the Unraid server, with LAN
egress blocked by an nftables table inside the guest. It was renamed to `code` and moved to
Proxmox VE (Nov 2026). LAN isolation now lives in the Proxmox firewall (`agent-isolated`
security group), where the guest can't turn it off, so the guest nftables block and its
`lan`/`gateway`/`dnsServers` values were removed. The agent key file is still
`~/.ssh/agent-vm` (comment `agent-vm client`); it's only a label.

## Contents

1. [What you get](#what-you-get)
2. [Files in this repo](#files-in-this-repo)
3. [Step 1: Add your SSH keys](#step-1-add-your-ssh-keys)
4. [Step 2: Check the disk and network](#step-2-check-the-disk-and-network)
5. [Step 3: Build locally](#step-3-build-locally)
6. [Step 4: Create the VM](#step-4-create-the-vm)
7. [Step 5: Boot the installer](#step-5-boot-the-installer)
8. [Step 6: Install NixOS with nixos-anywhere](#step-6-install-nixos-with-nixos-anywhere)
9. [Step 7: Set up Tailscale](#step-7-set-up-tailscale)
10. [Step 8: Connect from your desktop](#step-8-connect-from-your-desktop)
11. [Step 9: Give the agents credentials](#step-9-give-the-agents-credentials)
12. [Step 10: Verify the isolation](#step-10-verify-the-isolation)
13. [Day to day](#day-to-day)
14. [Running a second VM elsewhere](#running-a-second-vm-elsewhere)
15. [Troubleshooting](#troubleshooting)

---

## What you get

| | |
|---|---|
| **OS** | Headless NixOS: no desktop, audio, flatpak or talon |
| **Size** | 2 vCPU, 4 GB RAM, 40 GB disk (enough for 1–3 agents doing light builds) |
| **Access** | SSH with keys only, over Tailscale (and over the LAN) |
| **Users** | `admin`: admin and deploys (wheel, passwordless sudo). `agent`: runs the agents (no sudo) |
| **Isolation** | The Proxmox firewall (`agent-isolated` security group) stops it opening connections to your LAN; Tailscale ACLs stop it from reaching tailnet devices |
| **Tools** | claude-code, codex, opencode, antigravity (`agy`), git, gh, gitleaks, node 22, python 3 + uv, rootless Docker + compose, ripgrep, fd, jq, tmux, your nvim/zsh setup, herdr-core (`hc`) |

**What isolation means here:** agents run in a separate VM as an unprivileged user. They
have none of your SSH keys, the sops age key, a `~/.nix` checkout with push rights, or
your browser profiles. Agents can only push to repos you give them a key for (Step 9).
They can still reach the internet, which they need for model APIs and package registries.

**The VM never needs your GitHub SSH key or the age key.** Everything is built on your
desktop and copied over.

## Files in this repo

| File | What it does |
|---|---|
| `flake.nix` | `mkServer` helper and the `code` output; `disko` input |
| `server-configuration.nix` | Shared headless base: SSH hardening, Tailscale, firewall, nix GC, configurable admin account (`admin` on `code`) |
| `hosts/code-configuration.nix` | Hostname/domain, SSH keys, the `agent` user, IPv6 off, boot loader, `stateVersion` |
| `modules/nixos/agent-tools.nix` | The swappable tool layer: agent CLIs and herdr. Edit only this file to change tools |
| `modules/hardware-config/code-hardware.nix` | QEMU guest profile and the disk layout (disko). Placeholder until regenerated on Proxmox (Step 6) |
| `modules/home/server-shell.nix` | Your zsh/p10k/tmux/nvim/git setup for `admin` and `agent` (Home Manager), plus direnv for per-project dev shells |

---

## Step 1: Add your SSH keys

You need **two different keys**:

- **Admin key**: your normal key (or a dedicated one) for `admin`, used to deploy and
  for sudo.
- **Agent key**: a new key that clients (herdr-app, `hc`, plain ssh) use to log in as
  `agent`. Keep it separate so that anything holding it can't deploy or sudo.

Create the agent key on your desktop:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/agent-vm -C "agent-vm client"
```

Paste both **public** keys into `hosts/code-configuration.nix`:

```nix
adminKeys = [
  "ssh-ed25519 AAAA... jordan@fedora-desktop"   # contents of your admin .pub
];
agentKeys = [
  "ssh-ed25519 AAAA... agent-vm client"         # contents of ~/.ssh/agent-vm.pub
];
```

Public keys are safe to commit to this public repo. The build fails on purpose until
`adminKeys` has at least one key, so you can't install a VM you can't log into.

## Step 2: Check the disk and network

The guest has no LAN rules of its own: egress is filtered by the Proxmox firewall
([Proxmox VE](#proxmox-ve)). The guest only keeps IPv6 off, so LAN hosts can't be reached
over link-local/ULA addresses that a v4-only firewall rule set would miss.

If the VM's virtual disk **isn't a VirtIO Block disk**, change `device = "/dev/vda";` in
`modules/hardware-config/code-hardware.nix` (SATA disks and Proxmox's default SCSI bus
show up as `/dev/sda`). Step 5 shows how to check.

## Step 3: Build locally

New files must be tracked by git before the flake can see them:

```sh
cd ~/.nix
git add -A
nix build '.#nixosConfigurations.code.config.system.build.toplevel' --no-link
```

If that succeeds, the config is ready. Commit it when you're happy with it.

---

## Step 4: Create the VM

Use these settings on any hypervisor:

| Setting | Value |
|---|---|
| Firmware | **UEFI** (OVMF). The config uses systemd-boot and won't boot in legacy BIOS mode |
| Machine | Q35 |
| CPU | 2 vCPU, host-passthrough |
| RAM | 4 GB (zram swap is enabled) |
| Disk | 40 GB, **VirtIO Block** bus, raw or qcow2 |
| Network | Bridged to the LAN (recommended) or NAT, **virtio** model |
| Boot media | Latest NixOS **minimal** ISO (x86_64), from <https://nixos.org/download/> |

### Proxmox VE

1. Upload the NixOS minimal ISO: **Datacenter → vm → local → ISO Images → Upload**
   (or **Download from URL**).
2. **Create VM**:
   - **General:** Name `code`, tick **Start at boot**.
   - **OS:** the NixOS ISO, type Linux 6.x.
   - **System:** Machine **q35**, BIOS **OVMF (UEFI)**, add an EFI disk, **Qemu Agent** on
     (the guest runs `services.qemuGuest`). Pre-enrolled keys **off** (Secure Boot isn't set up).
   - **Disks:** 40 GB, bus **VirtIO Block** (shows up as `/dev/vda`), discard on if the
     storage is thin.
   - **CPU:** 2 cores, type `host`.
   - **Memory:** 4096 MB.
   - **Network:** bridge `vmbr0`, model **VirtIO**, **Firewall** ticked.
3. **Firewall:** the isolation lives here, not in the guest.
   - Make sure the firewall is enabled at **Datacenter → Firewall → Options** and on the
     VM (**code → Firewall → Options → Firewall: Yes**).
   - Apply the `agent-isolated` security group (**code → Firewall → Insert: Security Group**).
     It must allow, in this order: DHCP to the gateway (`10.44.44.1`, UDP 67), DNS to the
     Pi-holes (`10.44.44.2`, `10.44.44.3`, UDP/TCP 53), Tailscale (UDP 41641 out); then drop
     everything else to `10.44.44.0/24`; then allow the rest (internet).
   - Inbound, allow SSH (TCP 22) from your desktops' LAN IPs, so `ssh agent@code.vm.lan` works
     without Tailscale. Leave the VM's default inbound policy at DROP.
   - Turn on **IP filter** / MAC filter in the VM's firewall options so the guest can't
     change its address to dodge the rules.
4. Give the VM a DHCP reservation on the router, and add a **Pi-hole local DNS record**
   `code.vm.lan → <VM IP>` on both Pi-holes. `code.vm.lan` is the name everything in this
   repo uses.

### Fedora desktop (virt-manager)

To run a copy locally for testing, or as a second agent VM:

1. Install libvirt: `sudo dnf install @virtualization`, then
   `sudo systemctl enable --now libvirtd`.
2. In virt-manager: **New VM → Local install media** → the NixOS ISO → choose a generic
   Linux OS type. Set 4096 MB RAM, 2 CPUs and a 40 GB disk.
3. Tick **Customize configuration before install**:
   - **Overview:** Chipset Q35, Firmware **UEFI x86_64** (OVMF_CODE).
   - **Disk:** bus **VirtIO**.
   - **NIC:** model **virtio**. Network source is either the default NAT (`192.168.122.0/24`)
     or a bridge if you have one.
4. **Begin Installation**.

With NAT, the VM sits behind your desktop and there's no Proxmox firewall in front of it.
See [Running a second VM elsewhere](#running-a-second-vm-elsewhere).

## Step 5: Boot the installer

In the VM console (Proxmox **Console** (noVNC), or the virt-manager window):

```sh
passwd          # set a temporary password for the `nixos` user (only lives in the live ISO)
ip -4 a         # note the VM's IP address
lsblk           # confirm the disk is /dev/vda (VirtIO); if it's /dev/sda, see Step 2
```

From your desktop, check that you can log in with `ssh nixos@<ip>`.

## Step 6: Install NixOS with nixos-anywhere

Run this from your **desktop**:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake "$HOME/.nix#code" \
  --target-host nixos@<ip>
```

nixos-anywhere:

- partitions `/dev/vda` (512 MB EFI partition and an ext4 root),
- builds the system on your desktop and copies it over,
- installs the boot loader,
- reboots.

**This wipes the VM's disk.** Double-check the IP first.

After it reboots:

- **Proxmox:** **code → Hardware → CD/DVD Drive → Do not use any media**, then start it again.
- **virt-manager:** remove the CDROM from the boot order.

The installed system has **no passwords**. Log in with SSH using your admin key:

```sh
ssh admin@<ip>
```

**Regenerate the hardware config.** `code-hardware.nix` is a placeholder carried over from the
Unraid VM. Once the Proxmox VM has booted:

```sh
ssh admin@<ip> nixos-generate-config --show-hardware-config
```

Copy the `boot.initrd.*`, `boot.kernelModules` and similar lines into
`modules/hardware-config/code-hardware.nix`, keep the disko block, and leave out the
generated `fileSystems`/`swapDevices` (disko declares those). Build, commit and deploy.

## Step 7: Set up Tailscale

Edit the tailnet policy **before** bringing the VM up, so the tag exists and the VM is
restricted from the start.

1. In the Tailscale admin console → **Access controls**, add:

   ```jsonc
   "tagOwners": {
     "tag:agent": ["autogroup:admin"],
   },
   "acls": [
     // your devices can SSH into agent VMs
     {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:agent:22"]},
     // ...your other rules. Do NOT add any rule with "src": ["tag:agent"].
   ],
   ```

   > **Important:** if your policy still has the default allow-all rule
   > (`"src": ["*"], "dst": ["*:*"]`), the VM can reach every device on your tailnet.
   > Replace it with explicit rules for your own devices first.

2. On the VM:

   ```sh
   ssh admin@<ip>
   sudo tailscale up --advertise-tags=tag:agent
   ```

   Open the login URL it prints and approve the device. Tagged devices have key expiry
   turned off by default; check that it's off in the Machines list.

3. Confirm from your desktop: `ssh admin@code` (MagicDNS name). On the LAN, `code.vm.lan`
   works too; the Step 8 aliases use it.

4. **`tailscale serve` for PWA testing.** Tailscale is enabled for every `mkServer` host by
   `server-configuration.nix`. `tailscale serve` needs root or a Tailscale operator, so run
   it as `admin` (`sudo tailscale serve --bg 3000`) for a port `agent` is listening on, and
   enable **HTTPS certificates** in the admin console (DNS page) for the `https://code.<tailnet>.ts.net`
   URL. Making `agent` the operator (`--operator=agent`) would let agents run it themselves,
   but also reconfigure or stop Tailscale, so it isn't set.

## Step 8: Connect from your desktop

Add to `~/.ssh/config` on each machine you connect from:

```sshconfig
Host code
    HostName code.vm.lan         # Pi-hole record; use `code` (MagicDNS) off the LAN
    User agent
    IdentityFile ~/.ssh/agent-vm
    IdentitiesOnly yes
    ForwardAgent no

Host code-admin
    HostName code.vm.lan
    User admin
    ForwardAgent no

Host vm                          # the Proxmox VE host; used by update-system
    HostName vm.lan
    User root
    ForwardAgent no
```

The SSH config isn't managed by Home Manager (it lives in `~/.ssh`, outside the repo).
Test it: `ssh code` (same as `ssh agent@code.vm.lan`) should give you a shell as `agent`.
`nix-deploy-code` deploys through `code-admin` (`admin@code.vm.lan`).

**Renaming an existing VM's admin account:** `my.server.adminUser = "admin"` in
`hosts/code-configuration.nix` selects the account used for sudo, trusted Nix uploads,
and the login-key assertion. It must be inside the module's `in { ... }` configuration;
putting it in `let` only creates an unused local binding. The `agent` account stays
unprivileged, and Home Manager configures shells for `admin` and `agent`.

For a VM still running the old `jordan` configuration, deploy once using the existing
login (run this from your desktop):

```sh
nix run 'nixpkgs#nixos-rebuild' -- switch \
  --flake "$HOME/.nix#code" --target-host jordan@code.vm.lan --sudo
```

Then set `User admin` in your desktop's `code-admin` SSH alias and check
`ssh code-admin whoami` and `ssh code-admin sudo -n true`. This creates a new account
with `/home/admin`; it does not move `/home/jordan` or its files. Keep the agent key
separate from the admin keys; comments such as `jordan@fedora-desktop` on public keys
identify their source and do not set the VM login name.

**herdr** (current agent tool):

- **herdr-app:** Settings → Machines → Add machine → choose `code` from the SSH config. If you
  added it as `agent-vm` before the rename, remove that machine and add `code`.
- **CLI:** run `hc machine add code --name code`. Don't use `--install`, because `hc`
  already comes from Nix. Answer no if it offers to copy itself over.
- Then open terminals or agents on `code` from the app, or run
  `hc run --on code --cwd ~/project …`. Under the hood this is `ssh agent@code.vm.lan hc connect`.

herdr's core starts on demand when a client connects. You don't need it running all the time.

## Step 9: Give the agents credentials

Give only the access each agent needs. **Never** copy your own `~/.ssh`, age key or tokens
onto the VM.

As `agent` (`ssh code`):

- **Claude Code:** run `claude` and log in. On a headless machine it prints a URL to open
  on your desktop.
- **Codex / opencode:** log in the same way, or set an API key in `~/.bashrc` (a key just for
  this VM, so you can revoke it on its own).
- **GitHub, per repo (preferred):** use deploy keys.
  ```sh
  ssh-keygen -t ed25519 -f ~/.ssh/<repo>-deploy -C "code <repo>"
  ```
  Add the `.pub` under the repo's **Settings → Deploy keys** and tick write access only if
  agents need to push. Then map it in `~/.ssh/config` on the VM:
  ```sshconfig
  Host github-<repo>
      HostName github.com
      IdentityFile ~/.ssh/<repo>-deploy
  ```
  and clone with `git clone git@github-<repo>:cat-phish/<repo>.git`.
- **GitHub, several repos:** a **fine-grained** personal access token limited to those repos.
  Run `gh auth login` and paste the token.
- **Git identity:**
  `git config --global user.name "code"` and `git config --global user.email <your-noreply>`.

## Step 10: Verify the isolation

| Check | Command | Expected result |
|---|---|---|
| No password login | `ssh -o PubkeyAuthentication=no code` | Rejected |
| No sudo for agent | `ssh code sudo true` | Fails |
| Internet works | `ssh code curl -sI https://api.anthropic.com` | HTTP response |
| DNS works | `ssh code getent hosts github.com` | An address (Pi-holes allowed) |
| LAN blocked | `ssh code curl -m5 https://vm.lan:8006` | Times out (Proxmox UI) |
| LAN blocked | `ssh code curl -m5 http://10.44.44.<desktop-ip>` | Times out |
| Tailnet blocked | `ssh code ping -c2 <desktop-tailscale-ip>` | No reply |
| herdr core | `ssh code hc server status` | Running |
| Sessions persist | Open a terminal in herdr-app, close the app, reopen it | Terminal still there |
| Survives logout | Same, after all SSH sessions end | Terminal still there (see [Troubleshooting](#troubleshooting)) |
| Survives reboot | Reboot the Proxmox host | VM comes back by itself (Start at boot) |

---

## Day to day

| Task | Command (from your desktop) |
|---|---|
| Update everything (prompts) | `update-system`, answer **y** to the VM and/or Proxmox prompts (see [below](#updating-from-update-system)) |
| Update + deploy (script) | `nix-deploy-code` (`--no-update` to skip `nix flake update`, `--dry` to only build) |
| Deploy config changes | `nix run 'nixpkgs#nixos-rebuild' -- switch --flake "$HOME/.nix#code" --target-host code-admin --sudo` |
| Build without deploying | `nix build "$HOME/.nix#nixosConfigurations.code.config.system.build.toplevel" --no-link` |
| Update packages | `nix flake update` in `~/.nix`, then deploy |
| Roll back | `nix-deploy-code --rollback` (runs `ssh -t code-admin sudo nixos-rebuild switch --rollback`), or pick an older entry in the boot menu |
| Add or swap agent tools | Edit `modules/nixos/agent-tools.nix`, then deploy |
| Resize | Shut down, then change CPU/RAM in the hypervisor. To grow the disk, enlarge it (**Hardware → Disk Action → Resize**), then run `growpart` and `resize2fs` on the VM |

**What's state and what's rebuilt:** everything outside `/home` comes from the flake. The only
thing worth backing up is `/home/agent` (agent logins and work in progress). Keep real work
pushed to git, and the VM can be rebuilt from scratch with Steps 4–6.

### Updating from update-system

`update-system` (the regular desktop/laptop update) also offers to update the Proxmox host and
the agent VM, so they don't drift without needing a separate routine. They aren't updated on
every run: right after the sudo prompt it asks, for each one, `Update ... at the end of this
run? [y/N]` (default no), and runs the chosen ones after the local system is done. Asking up
front means the rest of the run needs no attention.

- **How long since the last update** is shown before each prompt, in red with `[!]` once it's
  14 days or more (`REMOTE_WARN_DAYS` in the script). The time is read from the machines
  themselves over SSH, so it's the same whether you update from the desktop or the laptop, and
  nothing is stored in the repo:
  - VM: the modification time of `/nix/var/nix/profiles/system`, which every deploy replaces.
  - Proxmox: the newest `dist-upgrade`/`full-upgrade` in `/var/log/apt/history.log*`. The web
    UI's **Upgrade** button and `pveupgrade` both run `apt-get dist-upgrade`, so upgrades done
    there count too. If the logs have none (e.g. rotated away), it says so in red.
- **Unreachable** (laptop away from home, Tailscale down, or the SSH key needs a passphrase
  that no agent has): the probe uses `BatchMode` and a 5 s timeout, prints `[-] ...
  unreachable` and skips that machine without asking.
- **Proxmox** is upgraded first (host before guest) with `ssh -t vm 'apt-get update && apt-get
  dist-upgrade'`, interactively, so apt's confirmations and config questions work. It needs the
  `vm` alias above (`root@vm.lan`). If a new kernel was installed or `/var/run/reboot-required`
  exists, it asks `Reboot vm now? [y/N]` (default no), because a reboot also stops the code VM.
  If it does reboot, the VM deploy is skipped for that run; run `nix-deploy-code --no-update`
  once the VM is back.
- **VM** is deployed with `nix-deploy-code --no-update --target code-admin`: `update-system`
  has already updated, committed and pushed `flake.lock`, so the VM gets the same inputs as the
  desktops.
- **Flags:** `--vm`, `--pve`, `--remote` (both) update without asking; `--no-remote` skips the
  checks and prompts entirely.

## Running a second VM elsewhere

Most of the config is host-agnostic. For another VM (on your desktop, the laptop, or a second
Proxmox VM):

1. Copy `hosts/code-configuration.nix` to `hosts/<name>-configuration.nix`. Change
   `networking.hostName` (and `networking.domain` if it isn't on `vm.lan`). Reuse the
   hardware file if the disk is also VirtIO Block, or generate a new one.
2. Add `<name> = mkServer "<name>";` to `nixosConfigurations` in `flake.nix`, then `git add`.
3. Isolation by setup:
   - **Another Proxmox VM:** apply the same `agent-isolated` security group.
   - **virt-manager NAT (`192.168.122.0/24`) or any host without a firewall in front:** the
     guest has no LAN rules of its own any more, so it can reach your LAN. Either filter it on
     the host (libvirt `nwfilter`, or nftables on the desktop's `virbr0` forward path), or
     revive the guest nftables block from git history (`git log -S agent-egress`) in that
     host's file, dropping both `192.168.122.0/24` and `10.44.44.0/24`.
4. Do Steps 1, 3 and 5–10 for the new VM. The same `tag:agent` ACL covers it.

## Troubleshooting

- **nixos-anywhere says it can't find `/dev/vda`.** The disk isn't on the VirtIO bus. Change the
  bus in the hypervisor, or change `device` in `code-hardware.nix` to what `lsblk` shows.
- **The VM won't boot after install (drops to the UEFI shell or "no bootable device").** The VM
  is in legacy BIOS mode. Recreate it with OVMF/UEFI.
- **`nixos-rebuild --target-host` fails copying paths ("lacks a signature").** Deploy as `admin`,
  which is a trusted Nix user. `agent` isn't.
- **herdr core isn't running.** It's started at boot by the `herdr-core` user unit for `agent`
  (`modules/nixos/agent-tools.nix`). Check it with `ssh code systemctl --user status herdr-core`
  and `journalctl --user -u herdr-core`.
- **The VM can't resolve DNS, or gets no IP.** The `agent-isolated` security group must allow
  DHCP to the gateway and DNS to both Pi-holes before its LAN drop rule. Check the rule order
  and the Pi-hole IPs in the group.
- **`code.vm.lan` doesn't resolve from the desktop.** Add the local DNS record on both Pi-holes,
  or use the MagicDNS name `code`.
- **SSH to `code.vm.lan` times out but Tailscale works.** The VM's inbound firewall on Proxmox
  doesn't allow TCP 22 from your desktop's LAN IP.
- **Tailscale only connects through a relay (DERP).** UDP 41641 must be allowed: the guest opens
  it through `networking.firewall.allowedUDPPorts`, and `agent-isolated` must allow it out.
- **Locked out (no SSH).** The hypervisor console won't help, because there are no passwords. Boot the NixOS ISO again and either fix it there or rerun Step 6 (which wipes the disk).
