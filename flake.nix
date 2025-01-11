{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mynvim.url = "github:cat-phish/Neovim";
    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager.url = "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
    darkmatter-grub-theme = {
      url = "gitlab:VandalByte/darkmatter-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    mynvim,
    kmonad,
    plasma-manager,
    darkmatter-grub-theme,
    ...
  }: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    # pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    pkgs-unstable = import nixpkgs-unstable {
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
        ];
        specialArgs = {
          inherit pkgs-unstable;
          inherit plasma-manager;
        };
      };
      jordans-laptop = lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/all-personal-machines/configuration.nix
          ./hosts/laptop/configuration.nix
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
        ];
        specialArgs = {
          inherit pkgs-unstable;
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
          inherit pkgs-unstable;
          inherit mynvim;
          inherit plasma-manager;
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
          inherit pkgs-unstable;
          inherit mynvim;
          inherit plasma-manager;
        };
      };
    };
  };
}
