# ROS 2 (jazzy) toolchain for palouse-robosub development, mirroring
# https://github.com/palouse-robosub/onboarding/blob/main/flake.nix
{
  inputs,
  pkgs,
  ...
}: let
  # nix-ros-overlay pins its own nixpkgs revision; import it separately
  # rather than overlaying the shared `pkgs` so ROS package builds stay
  # matched to the versions upstream actually tests against.
  rosNixpkgs = inputs.nix-ros-overlay.inputs.nixpkgs;
  ros-pkgs = import rosNixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [inputs.nix-ros-overlay.overlays.default];
  };

  ros-jazzy = with ros-pkgs.rosPackages.jazzy;
    buildEnv {
      paths = [
        # ros base
        ros-core
        ros-base
        rclcpp
        rclpy

        # ros msgs
        std-msgs
        geometry-msgs
        sensor-msgs
        nav-msgs

        # build
        ament-cmake
        ament-cmake-core # vectornav_msgs
        ament-cmake-python
        ament-lint-auto
        python-cmake-module

        # launch
        launch
        launch-ros
        launch-xml
      ];
    };
in {
  home.packages = with pkgs; [
    # build
    colcon
    cmake
    clang-tools

    # deps
    (python3.withPackages (ps: with ps; [pip]))

    # extra
    fastfetch
    can-utils

    ros-jazzy
  ];

  # NOTE: upstream also declares ros.cachix.org and palouse-robosub.cachix.org
  # as substituters (see the flake's `nixConfig`) so ROS builds are fetched
  # instead of compiled from source. Home Manager can't add those on a
  # non-NixOS host without `nix.package` also being set, so add them manually
  # to /etc/nix/nix.conf (as root) if you want the speedup:
  #   extra-substituters = https://ros.cachix.org https://palouse-robosub.cachix.org
  #   extra-trusted-public-keys = ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo= palouse-robosub.cachix.org-1:r2KNmfNGOZB+IhqEqDIMDaEWMYZv8ct1tdSg7n7fNKw=
}
