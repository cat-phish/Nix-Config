{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages =
    (with pkgs; [
      # Add desktop-specific packages here
    ])
    ++ (with pkgs-unstable; [
      # Add unstable packages here
    ]);

  home.file = {
    # "${config.xdg.configHome}/kmonad/kmonad_keychron_k2_pro.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_keychron_k2_pro.kbd;
    # };
    # "${config.xdg.configHome}/kmonad/kmonad_havit.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_havit.kbd;
    # };
    # "${config.xdg.configHome}/kmonad/kmonad_winry315.kbd" = {
    #   source = ../../dotfiles/.config/kmonad/kmonad_winry315.kbd;
    # };
  };
  # Add any desktop-specific configurations here
}
