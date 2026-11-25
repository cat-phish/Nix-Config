{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  nvim-config,
  emacs-config,
  ...
}: let
  # nixpkgs wraps claude with `--prefix LD_LIBRARY_PATH : <alsa-lib>/lib` so it
  # can load libasound. Everything Claude runs (Bash tool, hooks) inherits it,
  # and on Fedora non-Nix programs (e.g. Playwright's Chromium) then load Nix's
  # libasound, built against a newer glibc than Fedora's, and crash. Claude
  # itself must keep the path (patchelf-ing an RPATH in breaks the Bun binary),
  # so CLAUDE_CODE_SHELL_PREFIX strips it from each command instead.
  # See docs/claude-code.md.
  claudeAlsaLib = lib.makeLibraryPath [pkgs.alsa-lib];
  claudeShellPrefix = pkgs.writeShellScript "claude-shell-prefix" ''
    a=":${claudeAlsaLib}:"
    p=":''${LD_LIBRARY_PATH:-}:"
    while [[ $p == *"$a"* ]]; do p=''${p//"$a"/:}; done
    p=''${p#:}
    p=''${p%:}
    if [ -n "$p" ]; then export LD_LIBRARY_PATH="$p"; else unset LD_LIBRARY_PATH; fi
    # Claude passes the whole command as one string, written for $SHELL.
    if [ "$#" -eq 1 ]; then
      case "''${SHELL:-}" in
        */zsh | */bash) exec "$SHELL" -c "$1" ;;
        *) exec ${pkgs.bash}/bin/bash -c "$1" ;;
      esac
    fi
    exec "$@"
  '';
  claude-code = pkgs.symlinkJoin {
    name = "claude-code-${pkgs.claude-code.version}";
    paths = [pkgs.claude-code];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      rm $out/bin/claude
      makeWrapper ${pkgs.claude-code}/bin/claude $out/bin/claude \
        --set-default CLAUDE_CODE_SHELL_PREFIX ${claudeShellPrefix}
    '';
    inherit (pkgs.claude-code) meta;
  };
in {
  # Plasma Manager KDE Configuration
  imports = [
  ];

  # sops.secrets = {
  # beets_acoustid_api = {};
  # env_file = {};
  # };

  home.packages =
    # TEMPORARY: held back to an older nixpkgs (input nixpkgs-hold in
    # flake.nix) because they fail to build on current unstable. Move them
    # back into the list below once they build again (see backlog.md).
    (with (import inputs.nixpkgs-hold {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }); [
        codex
        herdr-desktop
      ])
    ++ (with pkgs; [
      aspell
      antigravity-cli
      bat # cat replacement with syntax highlighting
      # clang
      clang-tools
      claude-code # local wrapper above (strips alsa LD_LIBRARY_PATH from commands)
      chromedriver
      docker-compose
      eza # ls replacement
      fd
      fzf
      gh
      gitleaks
      gtest
      # gcc
      herdr
      herdr-core
      # jdk17
      jq
      # libgcc
      llvm
      # mongodb #takes too long to build from source
      navi
      nodejs_22
      oh-my-zsh
      opencode
      pnpm
      ripgrep
      # pyspark ships its own Spark (spark-submit, pyspark shell); runs on the jdk17 below.
      (python3.withPackages (ps: [ps.selenium ps.pyspark ps.numpy]))
      trivy
      uv
      vscode
      vim
      qtspim
      yazi
      zsh
      zoxide
      wezterm

      # Toolkits/Libraries
      sfml
    ])
    ++ (with pkgs-stable; [
      nerdfonts # moved to stable because the unstable requires individual fonts to be specified
    ])
    # Personal nixCats Nvim Flake
    ++ (with nvim-config; [
      packages.${pkgs.stdenv.hostPlatform.system}.nvim
      packages.${pkgs.stdenv.hostPlatform.system}.nvim-unstable
    ]);

  programs.git = {
    enable = true;
    settings = {
      user.name = "cat-phish";
      user.email = "134035929+cat-phish@users.noreply.github.com";
      init.defaultBranch = "master";
    };
    signing.format = null;
  };

  programs.lazygit = {
    enable = true;
  };

  # MongoDB server, mongosh and mongoimport/mongoexport. The nixpkgs mongodb builds from
  # source (very slow), so on Fedora it comes from MongoDB's own dnf repo. See docs/dnf.md.
  my.fedora.dnf = {
    repoFiles = ["${pkgs.writeTextDir "mongodb-org-7.0.repo" ''
      [mongodb-org-7.0]
      name=MongoDB Repository
      baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
      gpgcheck=1
      enabled=1
      gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
    ''}/mongodb-org-7.0.repo"];
    packages = ["mongodb-org" "mongodb-mongosh" "mongodb-database-tools"];
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };

  programs.emacs = {
    enable = true;
    # Native Wayland build: real touchpad pixel deltas for smooth scrolling
    # (ultra-scroll) and crisp text at fractional scale, instead of X11 via XWayland.
    package = pkgs.emacs-pgtk;
    # package = pkgs-stable.emacs.override { # xwidgets for launching org-roam ui inside emacs
    #   withXwidgets = true;
    #   withGTK3 = true;
    # };
    # Packages that need native parts built by Nix. Everything else comes from
    # package.el in the emacs-config repo.
    extraPackages = epkgs: with epkgs; [
      pdf-tools # ships a prebuilt epdfinfo server, so pdf-tools never compiles it (or runs sudo dnf)
    ];
  };
  services.emacs.enable = true;

  home.file = {
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
    ".bashrc".source = ../../dotfiles/.bashrc;
    # herdr-app keybindings (see docs/herdr.md). Out-of-store link so the app
    # can still edit the file live.
    ".config/herdr-app/keys.json".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.nix/dotfiles/.config/herdr-app/keys.json";
    ".clang-format" = {
      source = ../../dotfiles/.clang-format;
    };
    "CPPLINT.cfg".source = ../../dotfiles/CPPLINT.cfg;
    ".config/kitty" = {
      source = ../../dotfiles/.config/kitty;
      recursive = true;
    };
    ".config/emacs" = {
      source = emacs-config;
      recursive = true;
    };
    ".prettierrc" = {
      source = ../../dotfiles/.prettierrc;
    };
    ".config/opencode" = {
      source = ../../dotfiles/.config/opencode;
      recursive = true;
    };
    ".config/yazi" = {
      source = ../../dotfiles/.config/yazi;
      recursive = true;
    };
    ".p10k.zsh" = {
      source = ../../dotfiles/.p10k.zsh;
    };
    ".config/tmux/tmux.conf".source = ../../dotfiles/.config/tmux/tmux.conf;
    "${config.xdg.configHome}/tmux/scripts" = {
      source = ../../dotfiles/.config/tmux/scripts;
      recursive = true;
    };
    ".vim" = {
      source = ../../dotfiles/.vim;
      recursive = true;
    };
    ".wezterm.lua" = {
      source = ../../dotfiles/.wezterm.lua;
    };
    ".zshenv".source = ../../dotfiles/.zshenv;
    ".zshrc".source = ../../dotfiles/.zshrc;
  };
}
