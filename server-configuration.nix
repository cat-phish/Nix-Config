# Shared base for headless NixOS servers (built with mkServer in flake.nix).
# Unlike configuration.nix there is no desktop, audio, flatpak or talon.
# Host-specific settings live in hosts/<host>-configuration.nix.
{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    # Lets `nixos-rebuild --target-host jordan@<host>` copy closures built elsewhere.
    trusted-users = ["root" "jordan"];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Remote access: SSH keys only, reached over Tailscale ---
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowAgentForwarding = false;
    };
  };
  services.tailscale.enable = true;
  networking.firewall = {
    enable = true;
    # Tailscale's WireGuard port, so peers can connect directly instead of via DERP.
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # --- Admin user (deploys only) ---
  programs.zsh.enable = true;
  users.users.jordan = {
    isNormalUser = true;
    description = "Jordan";
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    # Keys are set per host (see hosts/<host>-configuration.nix).
  };
  # No passwords exist on these hosts, so wheel can't authenticate sudo any other way.
  security.sudo.wheelNeedsPassword = false;

  # Refuse to build a server nobody can log into.
  assertions = [
    {
      assertion = config.users.users.jordan.openssh.authorizedKeys.keys != [];
      message = "server-configuration.nix: set users.users.jordan.openssh.authorizedKeys.keys in the host file, or the server is unreachable after install.";
    }
  ];

  environment.systemPackages = with pkgs; [
    git
    htop
    vim
    wget
  ];

  zramSwap.enable = true;
  # system.stateVersion is set per host (release of that host's first install).
}
