{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  nvim-config,
  emacs-config,
  ...
}: {
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
      claude-code
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
      jq
      # libgcc
      llvm
      # mongodb #takes too long to build from source
      navi
      nodejs_22
      oh-my-zsh
      # TODO: drop override once nixpkgs fixes the opencode node_modules hash (broken in 2.2.5)
      (opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        };
      }))
      pnpm
      pre-commit
      ripgrep
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

  programs.emacs = {
    enable = true;
    # Native Wayland build: real touchpad pixel deltas for smooth scrolling
    # (ultra-scroll) and crisp text at fractional scale, instead of X11 via XWayland.
    package = pkgs.emacs-pgtk;
    # package = pkgs-stable.emacs.override { # xwidgets for launching org-roam ui inside emacs
    #   withXwidgets = true;
    #   withGTK3 = true;
    # };
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };
  services.emacs.enable = true;

  home.file = {
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
    ".bashrc".source = ../../dotfiles/.bashrc;
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
    ".zshrc".source = ../../dotfiles/.zshrc;
  };
}
