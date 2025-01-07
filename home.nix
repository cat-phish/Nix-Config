{
  config,
  pkgs,
  pkgs-unstable,
  mynvim,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jordan";
  home.homeDirectory = "/home/jordan";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  nixpkgs.config.allowUnfree = true;

  programs.git = {
    enable = true;
    userName = "cat-phish";
    userEmail = "134035929+cat-phish@users.noreply.github.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.lazygit = {
    enable = true;
  };

  # programs.zsh = {
  #   enable = true;
  # };

  # programs.neovim = { # NOTE: deprecated in favor of nixCats flake
  #   enable = true;
  #   package = pkgs.neovim-nightly;
  #   withNodJs = true;
  #   extraPackages = with pkgs; [
  #     lua-language-server
  #     stylua
  #     ripgrep
  #     gnumake
  #   ];
  #   plugins = [
  #     pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  #   ];
  # };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    # Stable Packages
    (with pkgs; [
      keepassxc

      oh-my-zsh
    ])
    # Unstable Packages
    ++ (with pkgs-unstable; [
      wezterm
    ])
    # Personal nixCats Nvim Flake
    ++ (with mynvim; [
      packages.${pkgs.system}.nvim
    ])
    # Overrides
    ++ [
      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      (pkgs.nerdfonts.override {fonts = ["Monaspace"];})
    ]
    # Scripts
    ++ [
      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # ++
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # Add ~/.nix/dotfiles/ dotfiles individually here
    ".bashrc".source = ./dotfiles/.bashrc;
    "${config.xdg.configHome}/tmux" = {
      source = ./dotfiles/.config/tmux;
      recursive = true;
    };
    ".vim" = {
      source = ./dotfiles/.vim;
      recursive = true;
    };
    ".zshrc".source = ./dotfiles/.zshrc;

    # Recursively adds dotfiles from ~/.nix/dotfiles/config/
    # "${config.xdg.configHome}" = {
    #   source = ./dotfiles/.config;
    #   recursive = true;
    # };
  };
  # programs.bash.enable = true; # deprecated in favor of exist existing bashrc

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    SHELL = pkgs.zsh;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
