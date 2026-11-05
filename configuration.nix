# Shared NixOS base for every NixOS host. Host-specific settings live in
# hosts/<host>-configuration.nix. The desktop is niri + Dux Shell (DMS), matching Fedora;
# the old KDE Plasma setup is in archive/plasma/.
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.talon-nix.nixosModules.talon
    inputs.dms.nixosModules.dank-material-shell
    inputs.dms-greeter.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-40.10.5"
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # --- Desktop: niri + Dux Shell (DMS) ---
  programs.niri.enable = true;
  programs.dank-material-shell = {
    enable = true;
    # Start the shell with the niri session (Fedora does this with `systemctl --user add-wants niri.service dms`).
    systemd.enable = true;
  };
  # Greeter: greetd running dms-greeter inside niri, with the user's DMS theme copied in.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = config.users.users.jordan.home;
  };
  # dotfiles/.config/xdg-desktop-portal/niri-portals.conf prefers gnome, then gtk (for FileChooser).
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  environment.systemPackages = with pkgs; [
      # Qt platform theme "kde" (set in modules/home/niri-kde-apps.nix); Fedora installs it via dnf
      kdePackages.plasma-integration

      age
      clang
      coreutils
      exfat
      filezilla
      firefox
      fzf
      gcc
      git
      glibc
      gnumake
      htop
      nfs-utils
      nodejs
      rclone
      sops
      tmux
      vim
      wget
      wl-clipboard
      xclip
      zsh
    ];

  # --- Audio, printing, services ---
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true;
  services.openssh.enable = true;
  services.flatpak.enable = true; # needed by nix-flatpak in Home Manager
  programs.talon.enable = true;

  # --- User ---
  programs.zsh.enable = true;
  users.users.jordan = {
    isNormalUser = true;
    description = "Jordan";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  # --- Secrets (sops-nix; no secrets defined yet, see backlog.md) ---
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age = {
      keyFile = "$HOME/.config/sops/age";
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };
    secrets = {};
  };

  # Release of the first install; don't change it (see `man configuration.nix`).
  system.stateVersion = "24.11";
}
