{
  pkgs,
  pkgs-stable,
  inputs,
  ...
}: {
  environment.systemPackages = [
    inputs.winboat.packages.winboat
    pkgs.freerdp
  ];
}
