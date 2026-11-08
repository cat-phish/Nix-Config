# agent-vm: an isolated VM on the Unraid server for running coding agents.
# Agents run as the unprivileged `agent` user; nothing personal (SSH keys, sops age key,
# ~/.nix with push rights) lives here. The tools themselves are in modules/nixos/agent-tools.nix.
# Setup guide: docs/agent-vm.md.
{
  lib,
  pkgs,
  ...
}: let
  # Public keys only. jordan = the admin/deploy key; agent = the key the agent clients use.
  # Keep them different so the agent key can't deploy or sudo.
  adminKeys = [
    # "ssh-ed25519 AAAA... jordan@fedora-desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa80EdbiAlEsJgMvotXA0jcicun018mby+0Nlh6IWIp jordan@fedora-laptop"
  ];
  agentKeys = [
    # "ssh-ed25519 AAAA... agent-vm client"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIw9XfzPYZI4YWmGqj8JR7P67NN55UbyN2ks5JOmal0f agent-vm client"
  ];

  # LAN the VM must not reach (Unraid UI/SMB, desktops, other services).
  lan = "10.44.44.0/24";
  gateway = "10.44.44.1";
  dnsServers = "{ 10.44.44.2, 10.44.44.3 }"; # Pi-holes
in {
  imports = [
    ../modules/hardware-config/agent-vm-hardware.nix
    ../modules/nixos/agent-tools.nix
  ];

  networking.hostName = "agent-vm";

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  users.users.jordan.openssh.authorizedKeys.keys = adminKeys;

  # Unprivileged account that runs the agents. No wheel, no sudo.
  users.users.agent = {
    isNormalUser = true;
    description = "Coding agents";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = agentKeys;
    # Keep user services (e.g. an agent backend) alive after SSH logout.
    linger = true;
  };

  # --- Egress isolation ---
  # IPv6 off so LAN hosts can't be reached over link-local/ULA addresses.
  networking.enableIPv6 = false;
  networking.nftables = {
    enable = true;
    tables.agent-egress = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority 0; policy accept;
          ct state established,related accept
          oifname "lo" accept
          # Tailscale's own encrypted traffic to LAN peers (tailnet ACLs still apply inside).
          udp sport 41641 accept
          ip daddr ${gateway} udp dport 67 accept
          ip daddr ${dnsServers} udp dport 53 accept
          ip daddr ${dnsServers} tcp dport 53 accept
          ip daddr ${lan} drop
        }
      '';
    };
  };

  # Release of the first install; don't change it (see `man configuration.nix`).
  system.stateVersion = "26.11";
}
