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

  # sops.secrets = {
  # };

  home.packages =
    (with pkgs; [
      ])
    ++ (with pkgs-stable; [
      ]);

  home.file = {
  };
}
