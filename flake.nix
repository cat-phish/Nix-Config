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
      url = "git+ssh://git@github.com/cat-phish/Emacs.git";
      flake = false; # Treat as a source repo, not a flake
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darkmatter-grub-theme = {
      url = "gitlab:VandalByte/darkmatter-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    talon-nix.url = "github:nix-community/talon-nix";
    agenix.url = "github:ryantm/agenix";
    # ROS packages for palouse-robosub (kept on its own pinned nixpkgs, per upstream flake)
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
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
    darkmatter-grub-theme,
    nix-flatpak,
    talon-nix,
    agenix,
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
      # Add the overlay here so it applies to the globally passed pkgs
      overlays = [
        (final: prev: {
          python312Packages = prev.python312Packages.override {
            overrides = pyFinal: pyPrev: {
              anyio = pyPrev.anyio.overridePythonAttrs (oldAttrs: {
                doCheck = false;
              });
            };
          };
        })
      ];
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
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./configuration.nix
          ./hosts/nixos-desktop-configuration.nix
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
          nix-flatpak.nixosModules.nix-flatpak
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgs-stable;
        };
      };
      nixos-laptop = lib.nixosSystem {
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./configuration.nix
          ./hosts/nixos-laptop-configuration.nix
          # sops-nix.nixosModules.sops
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
          nix-flatpak.nixosModules.nix-flatpak
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgs-stable;
        };
      };
    };
    homeConfigurations = {
      "jordan@nixos-desktop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/nixos-desktop-home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit talon-nix;
          # host is NixOS
          isNixos = true;
        };
      };
      "jordan@nixos-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/nixos-laptop-home.nix
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit talon-nix;
          # host is NixOS
          isNixos = true;
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
          # host is not NixOS (Fedora)
          isNixos = false;
        };
      };
      "jordan@fedora-laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/fedora-laptop-home.nix
          nix-flatpak.homeManagerModules.nix-flatpak
          agenix.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit pkgs-stable;
          inherit nvim-config;
          inherit emacs-config;
          inherit talon-nix;
          # host is not NixOS (Fedora)
          isNixos = false;
        };
      };
    };
  };
}
