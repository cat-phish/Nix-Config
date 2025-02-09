{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  mynvim,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age = {
      # automatically import host SSH keys as age keys
      keyFile = "$HOME/.config/sops/age";
      # uses age key that is expected to already be in filesystem
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      # generate key if the key above does not exist
      generateKey = true;
    };

    # secrets will be output to /run/secrets
    # e.g. /run/secrets/msmtp-password
    # secrets required for user creation are handled in respective /users/<username>.nix files
    # because they will be output to /run/secrets-for-users and only when a user is assigned to a host
    secrets = {
    };
  };

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
    # Unstable Packages
    (with pkgs; [
      noto-fonts-color-emoji
      oh-my-zsh
      wezterm
    ])
    # Stable Packages
    ++ (with pkgs-stable; [
      nerdfonts # moved to stable because the unstable requires individual fonts to be specified
      keepassxc
    ])
    # Personal nixCats Nvim Flake
    ++ (with mynvim; [
      packages.${pkgs.system}.nvim
    ])
    # ++ (with inputs.erosanix; [
    #   packages.i686-linux.foobar2000
    # ])
    # Overrides
    ++ [
      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override {fonts = ["Monaspace"];})
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
    ".config/tmux/tmux.conf".source = ./dotfiles/.config/tmux/tmux.conf;
    "${config.xdg.configHome}/tmux/scripts" = {
      source = ./dotfiles/.config/tmux/scripts;
      recursive = true;
    };
    ".vim" = {
      source = ./dotfiles/.vim;
      recursive = true;
    };
    ".zshrc".source = ./dotfiles/.zshrc;
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
