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
    # Add or override desktop-specific files here
  };
  # Add any laptop-specific configurations here
}
