# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  lib,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  options = {
    my.arbitrary.option = lib.mkOption {
      type = lib.types.str;
      default = "stuff";
    };
  };

  config = {
    my.arbitrary.option = "test";

    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "America/Los_Angeles";

    # Select internationalisation properties.
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

    #  services.xserver.videoDrivers = [ "nvidia" ];
    #  hardware.opengl.enable = true;
    #  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm = {
      enable = true;
      # theme = "reactplus";
    };
    services.desktopManager.plasma6.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.jordan = {
      isNormalUser = true;
      description = "Jordan";
      extraGroups = ["networkmanager" "wheel"];
      packages = with pkgs; [
        kdePackages.kate
        kdePackages.kcalc
      ];
      shell = pkgs.zsh;
    };

    # Enable sops-nix
    sops = {
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";
      age = {
        # automatically import host SSH keys as age keys
        keyFile = "$HOME/.config/sops/age";
        # uses age key that is expected to already be in filesystem
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        # generate key if the key above does not exist
        generateKey = true;
      };

      # secrets will be output to /run/secrets
      # e.g. /run/secrets/msmtp-password
      # secrets required for user creation are handled in respective /users/<username>.nix files
      # because they will be output to /run/secrets-for-users and only when a user is assigned to a host
      secrets = {
        # beets_acoustid_api = {
        #   owner = config.users.users.jordan.name;
        # };
      };
    };

    programs.zsh.enable = true;
    # Install firefox.
    # programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Enable the Flakes feature and the accompanying new nix command-line tool
    nix.settings.experimental-features = ["nix-command" "flakes"];

    # virtualisation.virtualbox.host.enable = true;
    # nixpkgs.config.virtualbox.host.enableExtensionPack = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages =
      (with pkgs; [
        # bpytop # no nix pkg
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
        nodePackages.nodejs
        rclone
        sops
        tmux
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        wget
        xclip
        zsh
      ])
      ++ (with pkgs-stable; [
        ]);

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    services.flatpak.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
