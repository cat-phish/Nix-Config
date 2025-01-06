{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mynvim.url = "github:cat-phish/Neovim";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    mynvim,
    ...
  }: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    nixCats = mynvim.packages.${system};
  in {
    nixosConfigurations = {
      jordans-desktop = lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/desktop/configuration-desktop.nix
        ];
        specialArgs = {
          inherit pkgs-unstable;
        };
      };
      jordans-laptop = lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/laptop/configuration-laptop.nix
        ];
        specialArgs = {
          inherit pkgs-unstable;
        };
      };
    };
    homeConfigurations = {
      "jordan@jordans-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/desktop/home-desktop.nix
        ];
        extraSpecialArgs = {
          inherit pkgs-unstable;
          inherit nixCats;
        };
      };
      "jordan@jordans-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/laptop/home-laptop.nix
        ];
        extraSpecialArgs = {
          inherit pkgs-unstable;
          inherit nixCats;
        };
      };
    };
  };
}
