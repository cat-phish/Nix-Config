{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    nvim-config.url = "github:cat-phish/Neovim";
    emacs-config = {
      url = "github:cat-phish/Emacs";
      flake = false; # Treat as a source repo, not a flake
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager.url = "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
    darkmatter-grub-theme = {
      url = "gitlab:VandalByte/darkmatter-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-snapd.url = "github:nix-community/nix-snapd";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
    talon-nix.url = "github:nix-community/talon-nix";
    agenix.url = "github:ryantm/agenix";
    # numennix.url = "github:anpandey/numen-nix";
    # numen = {
    #   url = "github:anpandey/numen-nix"; # or wherever the flake is
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # winboat= {
    #   url = "github:TibixDev/winboat";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # erosanix = {
    #   url = "github:emmanuelrosa/erosanix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    # sops-nix,
    nvim-config,
    emacs-config,
    kmonad,
    plasma-manager,
    darkmatter-grub-theme,
    nix-snapd,
    nix-flatpak,
    talon-nix,
    agenix,
    # numen,
    # winboat,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "ventoy-1.1.07"
        ];
      };
    };
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "ventoy-1.1.07"
        ];
      };
    };
  in {
    nixosConfigurations = {
      nixos-desktop = lib.nixosSystem {
        # inherit system; # TODO: remove? replaced with hostPlatform... below
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./configuration.nix
          # ./hosts/all-personal-machines/configuration.nix
          ./hosts/nixos-desktop-configuration.nix
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
          nix-flatpak.nixosModules.nix-flatpak
          nix-snapd.nixosModules.default
          {
            services.snap.enable = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit plasma-manager;
          # inherit erosanix;
        };
      };
      nixos-laptop = lib.nixosSystem {
        # inherit system; # TODO: remove? replaced with hostPlatform... below
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./configuration.nix
          # ./hosts/all-personal-machines/configuration.nix
          ./hosts/nixos-laptop-configuration.nix
          # sops-nix.nixosModules.sops
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
          nix-flatpak.nixosModules.nix-flatpak
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit plasma-manager;
        };
      };
    };
    homeConfigurations = {
      "jordan@nixos-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          # ./hosts/all-personal-machines/home.nix
          ./hosts/nixos-desktop-home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit plasma-manager;
          inherit talon-nix;
          # host is NixOS
          isNixos = true;
          # inherit winboat;
          # inherit erosanix;
        };
      };
      "jordan@nixos-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          # ./hosts/all-personal-machines/home.nix
          ./hosts/nixos-laptop-home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit plasma-manager;
          inherit talon-nix;
          # host is NixOS
          isNixos = true;
          # inherit winboat;
          # inherit erosanix;
        };
      };
      "jordan@fedora-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/fedora-desktop-home.nix
          nix-flatpak.homeManagerModules.nix-flatpak
          agenix.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit talon-nix;
          # inherit numen;
          # host is not NixOS (Fedora)
          isNixos = false;
        };
      };
      "jordan@fedora-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          # ./hosts/all-personal-machines/home.nix
          ./hosts/fedora-laptop-home.nix
          nix-flatpak.homeManagerModules.nix-flatpak
          agenix.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          # inherit plasma-manager;
          inherit talon-nix;
          # host is not NixOS (Fedora)
          isNixos = false;
          # inherit winboat;
          # inherit erosanix;
        };
      };
      "ubuntu@ubuntu" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/all-personal-machines/home.nix
          ./hosts/live-usb/ubuntu/home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          # inherit plasma-manager;
          inherit talon-nix;
          # host is not NixOS (Ubuntu)
          isNixos = false;
          lib = lib;
          hm = home-manager.lib;
          # inherit winboat;
          # inherit erosanix;
        };
      };
    };
  };
}
