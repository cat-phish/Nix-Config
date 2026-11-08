{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # TEMPORARY (Nov 2026): packages that fail to build on current unstable
    # are taken from the unstable revision before the 2026-11-08 update:
    # codex (aws-lc-sys wants a system AWS-LC) and herdr-desktop (zstd-sys
    # can't find libzstd). Used in modules/home/dev-environment.nix; remove
    # once they build again (see backlog.md).
    nixpkgs-hold.url = "github:NixOS/nixpkgs/f9a75f41be3a74eab55d3a7679d34ad6cc0da977";
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
    # Dux Shell (formerly DankMaterialShell) and its greeter, for the NixOS hosts.
    # Fedora gets dms from the avengemedia/dms COPR instead.
    dms.url = "github:duxlabs-dev/dux-shell";
    dms-greeter.url = "github:duxlabs-dev/dux-greeter";
    talon-nix.url = "github:nix-community/talon-nix";
    # Declarative partitioning for headless servers (used by nixos-anywhere installs).
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nvim-config,
    emacs-config,
    kmonad,
    darkmatter-grub-theme,
    nix-flatpak,
    talon-nix,
    disko,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgsConfig = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "ventoy-1.1.07"
      ];
    };
    pkgs = import nixpkgs {
      inherit system;
      config = pkgsConfig;
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
      config = pkgsConfig;
    };

    # NixOS system: configuration.nix (shared) + hosts/<host>-configuration.nix
    mkNixos = host:
      lib.nixosSystem {
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./configuration.nix
          ./hosts/${host}-configuration.nix
          kmonad.nixosModules.default
          darkmatter-grub-theme.nixosModule
          nix-flatpak.nixosModules.nix-flatpak
        ];
        specialArgs = {inherit inputs pkgs-stable;};
      };

    # Headless NixOS server: server-configuration.nix (shared) + hosts/<host>-configuration.nix.
    # No desktop; deployed from another machine with nixos-anywhere / nixos-rebuild --target-host.
    mkServer = host:
      lib.nixosSystem {
        modules = [
          {nixpkgs.hostPlatform = system;}
          ./server-configuration.nix
          ./hosts/${host}-configuration.nix
          disko.nixosModules.disko
          # Shell comforts for every user listed in my.server.shellUsers (modules/home/server-shell.nix).
          home-manager.nixosModules.home-manager
          ({
            config,
            lib,
            ...
          }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit nvim-config;};
              users = lib.genAttrs config.my.server.shellUsers (_: import ./modules/home/server-shell.nix);
            };
          })
        ];
        specialArgs = {inherit inputs pkgs-stable;};
      };

    # Standalone Home Manager: home.nix (shared) + hosts/<host>-home.nix
    mkHome = {
      host,
      isNixos,
    }:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./hosts/${host}-home.nix
          nix-flatpak.homeManagerModules.nix-flatpak
        ];
        extraSpecialArgs = {
          inherit inputs pkgs-stable nvim-config emacs-config talon-nix isNixos;
        };
      };
  in {
    nixosConfigurations = {
      nixos-desktop = mkNixos "nixos-desktop";
      nixos-laptop = mkNixos "nixos-laptop";
      agent-vm = mkServer "agent-vm"; # isolated coding-agent VM on the Unraid server
    };
    homeConfigurations = {
      "jordan@fedora-desktop" = mkHome {
        host = "fedora-desktop";
        isNixos = false;
      };
      "jordan@fedora-laptop" = mkHome {
        host = "fedora-laptop";
        isNixos = false;
      };
      "jordan@nixos-desktop" = mkHome {
        host = "nixos-desktop";
        isNixos = true;
      };
      "jordan@nixos-laptop" = mkHome {
        host = "nixos-laptop";
        isNixos = true;
      };
    };
  };
}
