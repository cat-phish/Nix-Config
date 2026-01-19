{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  mynvim,
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
    (with pkgs; [
      aspell
      bat # cat replacement with syntax highlighting
      # clang
      clang-tools
      llvm
      eza # ls replacement
      fd
      fzf
      # gcc
      jq
      # libgcc
      navi
      oh-my-zsh
      ripgrep
      vscode
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
    ++ (with mynvim; [
      packages.${pkgs.system}.nvim
    ]);

  programs.git = {
    enable = true;
    settings = {
      user.name = "cat-phish";
      user.email = "134035929+cat-phish@users.noreply.github.com";
      init.defaultBranch = "master";
    };
  };

  programs.lazygit = {
    enable = true;
  };

  programs.emacs = {
    enable = true;
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
    ".config/kitty" = {
      source = ../../dotfiles/.config/kitty;
      recursive = true;
    };
    ".prettierrc" = {
      source = ../../dotfiles/.prettierrc;
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
