{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    mynvim.url = "github:cat-phish/Neovim";
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
    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    # sops-nix,
    mynvim,
    kmonad,
    plasma-manager,
    darkmatter-grub-theme,
    nix-snapd,
    nix-flatpak,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      jordans-desktop = lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/all-personal-machines/configuration.nix
          ./hosts/desktop/configuration.nix
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
      jordans-laptop = lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/all-personal-machines/configuration.nix
          ./hosts/laptop/configuration.nix
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
      "jordan@jordans-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/all-personal-machines/home.nix
          ./hosts/desktop/home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit mynvim;
          inherit plasma-manager;
          # inherit erosanix;
        };
      };
      "jordan@jordans-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/all-personal-machines/home.nix
          ./hosts/laptop/home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit mynvim;
          inherit plasma-manager;
          # inherit erosanix;
        };
      };
    };
  };
}
