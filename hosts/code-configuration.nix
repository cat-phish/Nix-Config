# code (code.vm.lan): an isolated VM on the Proxmox VE host vm.lan for running coding agents.
# Agents run as the unprivileged `agent` user; nothing personal (SSH keys, sops age key,
# ~/.nix with push rights) lives here. LAN egress isolation is enforced at the Proxmox
# hypervisor firewall (`agent-isolated` Security Group).
# The tools themselves are in modules/nixos/agent-tools.nix.
# Setup guide: docs/code-vm.md.
{pkgs, ...}: let
  # Public keys only. admin = the admin/deploy key; agent = the key the agent clients use.
  # Keep them different so the agent key can't deploy or sudo.
  adminKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa80EdbiAlEsJgMvotXA0jcicun018mby+0Nlh6IWIp jordan@fedora-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAF5vqA1M8gffxvQvF5ojYUWlX4OT/bwxPBn8aCgmTF0 jordan@fedora-desktop"
    # New
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVw6soJTbmKk5uSZ4Ua9Wf0PEuPrteTazCSfXsSRP7b jordan@fedora-laptop-admin-2026-11"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLe2bPGZaRwoGPX4XSIzkWGe7ztv4noMY7GlOvTXarA jordan@fedora-desktop-admin-2026-11"
  ];
  agentKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIw9XfzPYZI4YWmGqj8JR7P67NN55UbyN2ks5JOmal0f agent-vm client"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH47GR2htvvu0yQF6+EeP07u1A3wkWXYYrdQdqoAJmG3 herdr-mobile"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrF+PEhboRipFzns/+TnHYxLfHvRfgwDbQZMjfQrtQU herdr-mobile"
  ];
in {
  imports = [
    ../modules/hardware-config/code-hardware.nix
    ../modules/nixos/agent-tools.nix
  ];

  networking.hostName = "code";
  networking.domain = "vm.lan";

  # Tailscale itself comes from server-configuration.nix (services.tailscale.enable);
  # the node is tagged tag:agent at `tailscale up` (docs/code-vm.md Step 7).

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  my.server.adminUser = "admin";
  users.users.admin.openssh.authorizedKeys.keys = adminKeys;
  my.server.shellUsers = ["admin" "agent"];

  # Unprivileged account that runs the agents. No wheel, no sudo.
  users.users.agent = {
    isNormalUser = true;
    description = "Coding agents";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = agentKeys;
    # Keep user services (e.g. an agent backend) alive after SSH logout.
    linger = true;
  };

  # In hosts/code-configuration.nix
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # LAN egress filtering is enforced by the Proxmox host firewall.
  # Keep IPv6 off so LAN hosts can't be reached over link-local/ULA addresses.
  networking.enableIPv6 = false;

  # Release of the first install; don't change it (see `man configuration.nix`).
  system.stateVersion = "26.11";
}
