# Agentic VM setup

How to set up `agent-vm`: a small, headless NixOS VM where coding agents run away from
your personal machines. It's built from this flake (`nixosConfigurations.agent-vm`), so
the whole VM is reproducible and is redeployed from your desktop.

The steps work on any KVM/QEMU host. The [Unraid](#unraid) and
[Fedora desktop (virt-manager)](#fedora-desktop-virt-manager) sections cover the
host-specific parts.

## Contents

1. [What you get](#what-you-get)
2. [Files in this repo](#files-in-this-repo)
3. [Step 1: Add your SSH keys](#step-1-add-your-ssh-keys)
4. [Step 2: Check the network settings](#step-2-check-the-network-settings)
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
| **Users** | `jordan`: admin and deploys (wheel, passwordless sudo). `agent`: runs the agents (no sudo) |
| **Isolation** | Can't open connections to your LAN; Tailscale ACLs stop it from reaching tailnet devices |
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
| `flake.nix` | `mkServer` helper and the `agent-vm` output; `disko` input |
| `server-configuration.nix` | Shared headless base: SSH hardening, Tailscale, firewall, nix GC, `jordan` user |
| `hosts/agent-vm-configuration.nix` | SSH keys, the `agent` user, LAN egress block, boot loader, `stateVersion` |
| `modules/nixos/agent-tools.nix` | The swappable tool layer: agent CLIs and herdr. Edit only this file to change tools |
| `modules/hardware-config/agent-vm-hardware.nix` | QEMU guest profile and the disk layout (disko) |
| `modules/home/server-shell.nix` | Your zsh/p10k/tmux/nvim/git setup for `jordan` and `agent` (Home Manager), plus direnv for per-project dev shells |

---

## Step 1: Add your SSH keys

You need **two different keys**:

- **Admin key**: your normal key (or a dedicated one) for `jordan`, used to deploy and
  for sudo.
- **Agent key**: a new key that clients (herdr-app, `hc`, plain ssh) use to log in as
  `agent`. Keep it separate so that anything holding it can't deploy or sudo.

Create the agent key on your desktop:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/agent-vm -C "agent-vm client"
```

Paste both **public** keys into `hosts/agent-vm-configuration.nix`:

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

## Step 2: Check the network settings

In `hosts/agent-vm-configuration.nix`:

```nix
lan = "10.44.44.0/24";
gateway = "10.44.44.1";
dnsServers = "{ 10.44.44.2, 10.44.44.3 }"; # Pi-holes
```

These match the home LAN. The VM can reach the gateway only for DHCP and the Pi-holes only
for DNS. Everything else on the LAN (Unraid UI, SMB, your desktops) is dropped. Change these
values if the LAN changes, or if the VM is on a different network
(see [Running a second VM elsewhere](#running-a-second-vm-elsewhere)).

If the VM's virtual disk **isn't a VirtIO disk**, change `device = "/dev/vda";` in
`modules/hardware-config/agent-vm-hardware.nix` (SATA/SCSI disks show up as `/dev/sda`).
Step 5 shows how to check.

## Step 3: Build locally

New files must be tracked by git before the flake can see them:

```sh
cd ~/.nix
git add -A
nix build '.#nixosConfigurations.agent-vm.config.system.build.toplevel' --no-link
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
| Disk | 40 GB, **VirtIO** bus, raw or qcow2 |
| Network | Bridged to the LAN (recommended) or NAT, **virtio** model |
| Boot media | Latest NixOS **minimal** ISO (x86_64), from <https://nixos.org/download/> |

### Unraid

1. **Settings → VM Manager**: make sure VMs are enabled and you know where your ISO
   share is (usually `isos`).
2. Copy the NixOS minimal ISO into the `isos` share.
3. **VMs → Add VM → Linux**, then set:
   - **Name:** `agent-vm`
   - **CPU Mode:** Host Passthrough
   - **Logical CPUs:** pick 2. Avoid CPU 0 and its hyperthread sibling, because Unraid itself uses them.
   - **Initial / Max Memory:** 4096 MB / 4096 MB
   - **Machine:** Q35 (latest)
   - **BIOS:** OVMF (not SeaBIOS)
   - **OS Install ISO:** the NixOS ISO
   - **Primary vDisk:** Auto, 40G, type **raw**, bus **VirtIO**. The default location
     `/mnt/user/domains/agent-vm/vdisk1.img` is fine, as long as `domains` is on the
     cache/SSD pool.
   - **Network Bridge:** `br0`, **Network Model:** `virtio-net`
   - **Graphics:** VNC (you only need it for the installer)
4. **Create**, then turn on **Autostart** for the VM on the VMs tab.
5. Optional but recommended: give the VM a DHCP reservation on your router, so its LAN IP
   doesn't change. You'll mostly use the Tailscale name anyway.

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

With NAT, the VM sits behind your desktop, so the egress rule needs different values.
See [Running a second VM elsewhere](#running-a-second-vm-elsewhere).

## Step 5: Boot the installer

In the VM console (Unraid **VNC**, or the virt-manager window):

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
  --flake "$HOME/.nix#agent-vm" \
  --target-host nixos@<ip>
```

nixos-anywhere:

- partitions `/dev/vda` (512 MB EFI partition and an ext4 root),
- builds the system on your desktop and copies it over,
- installs the boot loader,
- reboots.

**This wipes the VM's disk.** Double-check the IP first.

After it reboots:

- **Unraid:** edit the VM and remove the ISO (set OS Install ISO to none), then start it again.
- **virt-manager:** remove the CDROM from the boot order.

The installed system has **no passwords**. Log in with SSH using your admin key:

```sh
ssh jordan@<ip>
```

## Step 7: Set up Tailscale

Edit the tailnet policy **before** bringing the VM up, so the tag exists and the VM is
restricted from the start.

1. In the Tailscale admin console → **Access controls**, add:

   ```jsonc
   "tagOwners": {
     "tag:agents": ["autogroup:admin"],
   },
   "acls": [
     // your devices can SSH into agent VMs
     {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:agents:22"]},
     // ...your other rules. Do NOT add any rule with "src": ["tag:agents"].
   ],
   ```

   > **Important:** if your policy still has the default allow-all rule
   > (`"src": ["*"], "dst": ["*:*"]`), the VM can reach every device on your tailnet.
   > Replace it with explicit rules for your own devices first.

2. On the VM:

   ```sh
   ssh jordan@<ip>
   sudo tailscale up --advertise-tags=tag:agents
   ```

   Open the login URL it prints and approve the device. Tagged devices have key expiry
   turned off by default; check that it's off in the Machines list.

3. Confirm from your desktop: `ssh jordan@agent-vm` (MagicDNS name). Use `jordan@agent-vm`, not an `agent-vm` SSH alias: once you add the Step 8 aliases, deploy through `agent-vm-admin`.

## Step 8: Connect from your desktop

Add to `~/.ssh/config` on each machine you connect from:

```sshconfig
Host agent-vm
    HostName agent-vm            # Tailscale MagicDNS name
    User agent
    IdentityFile ~/.ssh/agent-vm
    IdentitiesOnly yes
    ForwardAgent no

Host agent-vm-admin
    HostName agent-vm
    User jordan
    ForwardAgent no
```

Test it: `ssh agent-vm` should give you a shell as `agent`.

**herdr** (current agent tool):

- **herdr-app:** Settings → Machines → Add machine → choose `agent-vm` from the SSH config.
- **CLI:** run `hc machine add agent-vm --name agent-vm`. Don't use `--install`, because `hc`
  already comes from Nix. Answer no if it offers to copy itself over.
- Then open terminals or agents on `agent-vm` from the app, or run
  `hc run --on agent-vm --cwd ~/project …`.

herdr's core starts on demand when a client connects. You don't need it running all the time.

## Step 9: Give the agents credentials

Give only the access each agent needs. **Never** copy your own `~/.ssh`, age key or tokens
onto the VM.

As `agent` (`ssh agent-vm`):

- **Claude Code:** run `claude` and log in. On a headless machine it prints a URL to open
  on your desktop.
- **Codex / opencode:** log in the same way, or set an API key in `~/.bashrc` (a key just for
  this VM, so you can revoke it on its own).
- **GitHub, per repo (preferred):** use deploy keys.
  ```sh
  ssh-keygen -t ed25519 -f ~/.ssh/<repo>-deploy -C "agent-vm <repo>"
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
  `git config --global user.name "agent-vm"` and `git config --global user.email <your-noreply>`.

## Step 10: Verify the isolation

| Check | Command | Expected result |
|---|---|---|
| No password login | `ssh -o PubkeyAuthentication=no agent-vm` | Rejected |
| No sudo for agent | `ssh agent-vm sudo true` | Fails |
| Internet works | `ssh agent-vm curl -sI https://api.anthropic.com` | HTTP response |
| LAN blocked | `ssh agent-vm curl -m5 http://10.44.44.<unraid-ip>` | Times out |
| Tailnet blocked | `ssh agent-vm ping -c2 <desktop-tailscale-ip>` | No reply |
| herdr core | `ssh agent-vm hc server status` | Running (once a client has connected) |
| Sessions persist | Open a terminal in herdr-app, close the app, reopen it | Terminal still there |
| Survives logout | Same, after all SSH sessions end | Terminal still there (see [Troubleshooting](#troubleshooting)) |
| Survives reboot | Reboot the Unraid host | VM comes back by itself |

---

## Day to day

| Task | Command (from your desktop) |
|---|---|
| Update + deploy (script) | `nix-deploy-agent-vm` (`--no-update` to skip `nix flake update`, `--dry` to only build) |
| Deploy config changes | `nix run 'nixpkgs#nixos-rebuild' -- switch --flake "$HOME/.nix#agent-vm" --target-host agent-vm-admin --sudo` |
| Build without deploying | `nix build "$HOME/.nix#nixosConfigurations.agent-vm.config.system.build.toplevel" --no-link` |
| Update packages | `nix flake update` in `~/.nix`, then deploy |
| Roll back | `ssh agent-vm-admin sudo nixos-rebuild switch --rollback`, or pick an older entry in the boot menu |
| Add or swap agent tools | Edit `modules/nixos/agent-tools.nix`, then deploy |
| Resize | Shut down, then change CPU/RAM in the hypervisor. To grow the disk, enlarge the vdisk, then run `growpart` and `resize2fs` on the VM |

**What's state and what's rebuilt:** everything outside `/home` comes from the flake. The only
thing worth backing up is `/home/agent` (agent logins and work in progress). Keep real work
pushed to git, and the VM can be rebuilt from scratch with Steps 4–6.

## Running a second VM elsewhere

Most of the config is host-agnostic. For another VM (on your desktop, the laptop, or a second
Unraid VM):

1. Copy `hosts/agent-vm-configuration.nix` to `hosts/<name>-configuration.nix`. Change
   `networking.hostName` and the network values. Reuse the hardware file if the disk is also
   VirtIO.
2. Add `<name> = mkServer "<name>";` to `nixosConfigurations` in `flake.nix`, then `git add`.
3. Network values by setup:
   - **Bridged on the home LAN:** same values as `agent-vm`.
   - **virt-manager NAT (`192.168.122.0/24`):** the "gateway" is your desktop itself, so
     block the libvirt subnet too. Set `gateway = "192.168.122.1"` and
     `dnsServers = "{ 192.168.122.1 }"` (libvirt's dnsmasq). Then add a second drop line for
     the home LAN in the nftables block:
     ```
     ip daddr 192.168.122.0/24 drop
     ip daddr 10.44.44.0/24 drop
     ```
4. Do Steps 1, 3 and 5–10 for the new VM. The same `tag:agents` ACL covers it.

## Troubleshooting

- **nixos-anywhere says it can't find `/dev/vda`.** The disk isn't on the VirtIO bus. Change the
  bus in the hypervisor, or change `device` in `agent-vm-hardware.nix` to what `lsblk` shows.
- **The VM won't boot after install (drops to the UEFI shell or "no bootable device").** The VM
  is in legacy BIOS mode. Recreate it with OVMF/UEFI.
- **`nixos-rebuild --target-host` fails copying paths ("lacks a signature").** Deploy as `jordan`,
  which is a trusted Nix user. `agent` isn't.
- **herdr core isn't running.** It's started at boot by the `herdr-core` user unit for `agent`
  (`modules/nixos/agent-tools.nix`). Check it with `ssh agent-vm systemctl --user status herdr-core`
  and `journalctl --user -u herdr-core`.
- **The VM can't resolve DNS.** The Pi-hole IPs in `dnsServers` changed, or DHCP is handing out a
  different DNS server. Update the values and deploy.
- **Tailscale only connects through a relay (DERP).** Make sure UDP 41641 is allowed. It is by
  default, through `networking.firewall.allowedUDPPorts` and the `udp sport 41641` rule.
- **Locked out (no SSH).** The hypervisor console won't help, because there are no passwords. Boot the NixOS ISO again and either fix it there or rerun Step 6 (which wipes the disk).
