{
  config,
  pkgs,
  ...
}: let
  # SDK 10 for the Roslyn version Avalonia 12's source generators need,
  # plus the .NET 8 runtime so net8.0 projects still run.
  dotnetPkg = with pkgs.dotnetCorePackages;
    combinePackages [
      sdk_10_0
      runtime_8_0
    ];
in {
  home.packages = with pkgs; [
    dotnetPkg
    jetbrains.rider
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
  };

  home.sessionPath = [
    "$HOME/.dotnet/tools"
  ];
}
