{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  mynvim,
  # ensure we know this is not NixOS when invoked via the flake
  isNixos ? false,
  lib,
  ...
}: {
  # Plasma Manager KDE Configuration
  imports = [
    ../../modules/plasma-config/desktop/plasma-config.nix
    ../../modules/rclone/rclone-gdrivedesk.nix
    ../../modules/rclone/rclone-mediaserversmb.nix
    ../../modules/rclone/rclone-hetzner.nix
    inputs.sops-nix.homeManagerModules.sops
    # inputs.talon-nix.nixosModules.talon
  ];

  sops.secrets = {
    beets_acoustid_api = {};
    env_file = {};
  };

  home.packages =
    (with pkgs; [
      calibre
      chromaprint
      kid3-kde
      python312Packages.pyacoustid
      python312Packages.discogs-client
      python312Packages.flask
      python312Packages.pylyrics
      python312Packages.pyacoustid
      python312Packages.pylast
      python312Packages.requests
      qbittorrent
      noto-fonts-color-emoji
      oh-my-zsh
      wezterm
      activate-linux
      appimage-run
      asciiquarium-transparent # an aquarium, duh
      audacity
      bat # cat replacement with syntax highlighting
      chirp
      cmatrix # just take the blue pill
      deskreen
      dropbox
      eza # ls replacement
      flameshot
      ghostty
      gimp
      google-chrome
      hypnotix
      kdePackages.konversation
      kvirc
      libreoffice-fresh
      mouseless
      mpv
      multiviewer-for-f1
      navi
      neofetch
      neovide
      noisetorch
      nurl # fetching nix package options from git, maybe others
      pinta
      pocket-casts
      # python39
      puddletag
      pulseaudio
      redshift
      syncthing
      # talon-nix.packages.${builtins.currentSystem}.default
      # thefuck # correct messed up commands
      tlrc # abbreviated man pages
      # wineasio
      # winetricks
      vlc
      vscode
      winboat
      youtube-music
      yt-dlp
      zoom
      zoxide
    ])
    ++ (with pkgs-stable; [
      nerdfonts # moved to stable because the unstable requires individual fonts to be specified
      keepassxc
      restic
      # wavebox
    ])
    # Personal nixCats Nvim Flake
    ++ (with mynvim; [
      packages.${pkgs.system}.nvim
    ])
    # ++ (with talon-nix; [
    #   packages.${builtins.currentSystem}.default
    # ])
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

  programs.beets = {
    enable = true;
    package = pkgs-stable.beets.override {
      pluginOverrides = {
        copyartifacts = {
          enable = true;
          propagatedBuildInputs = [pkgs-stable.beetsPackages.copyartifacts];
        };
      };
    };
    settings = {
      directory = "/mnt/music_hdd/New/2 - Beets Sorted";
      library = "/mnt/music_hdd/New/2 - Beets Sorted/musiclibrary.blb";
      import.move = true;
      import.log = "/mnt/music_hdd/New/beets.log";

      plugins = ["lyrics" "chroma" "lastgenre" "fetchart" "discogs" "copyartifacts" "ftintitle" "fromfilename" "inline" "rewrite" "spotify" "export" "unimported"];

      paths.default = "$albumartist_sort/$album%aunique{} ($original_year) [$format]/%if{$multidisc,Disc $disc/}$track. $title";
      paths.singleton = "Non-Album/$artist/$title";
      paths.comp = "Compilations/$album%aunique{}/$track $title";
      # paths.albumtype.soundtrack = "Soundtracks/$album/$track $title";

      item_fields.multidisc = "1 if disctotal > 1 else 0";

      original_date = false;

      match.preferred = {
        countries = ["US" "GB|UK"];
        media = ["CD" "Digital Media|File"];
        original_year = true;
      };

      # replaygain = {
      #   backend = "gstreamer";
      #   auto = true;
      #   noclip = true;
      #   peak = true;
      # };

      lyrics = {
        auto = true;
        fallback = "No lyrics found";
      };

      acoustid.apikey = "$(cat ${config.sops.secrets."beets_acoustid_api".path})";

      lastgenre = {
        canonical = "";
        source = "artist";
        count = 3;
        separator = "; ";
      };

      copyartifacts.print_ignored = true;

      unimported = {
        ignore_extensions = ["jpg" "png"];
        ignore_subdirectories = ["NonMusic" "data" "temp"];
      };
    };
  };
  # Example: if you later need to add home items that should only be applied
  # on NixOS hosts (for example, user config that relies on system-level units),
  # use `lib.mkIf isNixos [ ... ]` to guard them. On Fedora (isNixos=false)
  # those blocks will be skipped.
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; []; # Add any additional packages if desired
  };

  services.emacs.enable = true;

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
    # ".ssh/.env".text = "cat ${config.sops.secrets."env_file".path}";
    ".clang-format" = {
      source = ../../dotfiles/.clang-format;
    };
    ".prettierrc" = {
      source = ../../dotfiles/.prettierrc;
    };
    ".scripts" = {
      source = ../../dotfiles/.scripts;
      recursive = true;
    };
    ".wezterm.lua" = {
      source = ../../dotfiles/.wezterm.lua;
    };
    "${config.xdg.configHome}/kmonad" = {
      source = ../../dotfiles/.config/kmonad;
      recursive = true;
    };
    "${config.xdg.dataHome}/applications/foobar2000.desktop".text = ''
      [Desktop Entry]
      Name=foobar2000
      Exec=env WINEPREFIX="$HOME/.wine-foobar2000" WINEARCH=win32 wine "$HOME/wineapps/foobar2000_2.0/foobar2000.exe"
      Type=Application
      Icon="$HOME/.nix/dotfiles/.img/foobar.jpg"
      Categories=AudioVideo;Player;
    '';
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
}
