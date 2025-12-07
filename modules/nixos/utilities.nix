{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
  ];
  config = {
    environment.systemPackages =
      (with pkgs; [
        fuse
        ntfs3g # mount ntfs drives
      ])
      ++ (with pkgs-stable; [
        ]);
  };
}
