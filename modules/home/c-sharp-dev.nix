{
  config,
  pkgs,
  ...
}: let
  # Define your SDK version here (e.g., sdk_8_0, sdk_7_0)
  # You can also use dotnetCorePackages.combinePackages to bundle multiple SDKs
  dotnetPkg = pkgs.dotnetCorePackages.sdk_8_0;
in {
  home.packages = with pkgs; [
    dotnetPkg
    jetbrains.rider
  ];

  home.sessionVariables = {
    # Required for Rider and dotnet tools to locate the runtime in the Nix store
    DOTNET_ROOT = "${dotnetPkg}/share/dotnet";
  };

  # Optional: Add the global tools directory to your PATH if you use `dotnet tool install -g`
  home.sessionPath = [
    "$HOME/.dotnet/tools"
  ];
}
