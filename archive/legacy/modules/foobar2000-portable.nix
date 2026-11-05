{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  # Enable 32-bit support
  nixpkgs.config = {
    packageOverrides = pkgs: {
      wineWowPackages = pkgs.wineWowPackages.override {
        wineBuilds = [pkgs.wineWowPackages.builds.wineStaging];
      };
    };
  };
}
