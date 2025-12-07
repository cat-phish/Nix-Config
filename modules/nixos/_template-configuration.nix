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
        ])
      ++ (with pkgs-stable; [
        ]);
  };
}
