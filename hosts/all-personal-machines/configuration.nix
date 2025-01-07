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
        fuse
        kmonad
        lsp-plugins
      ])
      ++ (with pkgs-unstable; [
        ]);
  };
}
