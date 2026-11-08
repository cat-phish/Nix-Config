# Terminal comforts for headless servers (agent-vm): the same zsh, p10k, tmux, nvim and
# git setup as the desktops, without anything graphical. Used for both `jordan` and
# `agent` through the Home Manager NixOS module in mkServer (flake.nix).
# zsh plugins (zinit, p10k) and tmux plugins (tpm) clone themselves from GitHub on first start.
{
  pkgs,
  nvim-config,
  ...
}: {
  home.stateVersion = "26.11";

  home.packages = with pkgs; [
    bat
    eza
    fzf
    lazygit
    yazi
    zoxide
    nvim-config.packages.${pkgs.stdenv.hostPlatform.system}.nvim
    nvim-config.packages.${pkgs.stdenv.hostPlatform.system}.nvim-unstable
  ];

  home.sessionVariables.EDITOR = "nvim";

  # Per-project dev tools: a flake.nix/shell.nix plus `.envrc` containing `use flake`
  # (or `use nix`) loads the project's tools on cd. Run `direnv allow` once per project.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = false; # .zshrc isn't HM-managed; it hooks direnv itself
  };

  programs.git = {
    enable = true;
    settings.init.defaultBranch = "master";
  };

  home.file = {
    ".zshrc".source = ../../dotfiles/.zshrc;
    ".p10k.zsh".source = ../../dotfiles/.p10k.zsh;
    ".config/tmux/tmux.conf".source = ../../dotfiles/.config/tmux/tmux.conf;
    ".config/tmux/scripts" = {
      source = ../../dotfiles/.config/tmux/scripts;
      recursive = true;
    };
    ".config/yazi" = {
      source = ../../dotfiles/.config/yazi;
      recursive = true;
    };
  };
}
