{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
  ];
  config = {
    environment.systemPackages =
      (with pkgs; [
        kmonad
        lsp-plugins
      ])
      ++ (with pkgs-unstable; [
        ]);
  };
}
