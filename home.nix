{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  # Don't change this, even when updating Home Manager; read the HM release notes first.
  home.stateVersion = "24.11";

  # Per-clone git settings for this repo (git doesn't sync .git/config, so set them on every switch):
  # - core.hooksPath: use the tracked .githooks/ (pre-commit runs gitleaks; the repo is public)
  # - rebase.autoStash: let `git pull --rebase` and the rebuild scripts work with uncommitted GUI edits
  home.activation.nixRepoGitConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    repo="${config.home.homeDirectory}/.nix"
    if [ -d "$repo/.git" ]; then
      run ${pkgs.git}/bin/git -C "$repo" config core.hooksPath .githooks
      run ${pkgs.git}/bin/git -C "$repo" config rebase.autoStash true
    fi
  '';

  # HM re-imports nixpkgs with this config; the flake-level pkgs config doesn't apply here.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-40.10.5"
  ];
  # gtk2 is marked broken (EOL) but onlyoffice-desktopeditors' FHS env still needs it (see docs/backlog.md)
  nixpkgs.config.problems.handlers = {
    "gtk+".broken = "warn";
  };
  nixpkgs.config.home-manager.useGlobalPkgs = true;

  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (python-final: python-prev: {
            pyopenjtalk-plus = python-prev.pyopenjtalk-plus.overridePythonAttrs (oldAttrs: {
              # Bypass the regex mismatch on Python 3.14 / updated pybind11
              doCheck = false;
            });
          })
        ];
    })
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
