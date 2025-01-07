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
        lsp-plugins
      ])
      ++ (with pkgs-unstable; [
        ]);
  };
}
