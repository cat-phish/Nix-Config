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
      eza # ls replacement
      fd
      fzf
      jq
      navi
      oh-my-zsh
      ripgrep
      vscode
      yazi
      zsh
      zoxide
      wezterm
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
      init.defaultBranch = "main";
    };
  };

  programs.lazygit = {
    enable = true;
  };

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };

  home.file = {
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
    ".bashrc".source = ../../dotfiles/.bashrc;
    ".clang-format" = {
      source = ../../dotfiles/.clang-format;
    };
    ".prettierrc" = {
      source = ../../dotfiles/.prettierrc;
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
