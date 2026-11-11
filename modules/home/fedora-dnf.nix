{
  lib,
  isNixos,
  host,
  ...
}: let
  # Packages saved by `dnf-sync --save` (manual `dnf install`s you chose to keep). The script edits
  # this JSON, never .nix files; move an entry into a bundle by hand whenever you like.
  saved = builtins.fromJSON (builtins.readFile ../../setup/dnf-saved.json);
  forHost = attrs: (attrs.common or []) ++ (attrs.${host} or []);
  strList = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
  };
in {
  # dnf packages for the Fedora hosts, declared like Nix packages: set them in any bundle or host
  # file and the lists merge. Nothing is installed by Home Manager; `dnf-sync --apply` (run by
  # update-system and init.sh) reads the merged result with `nix eval` and asks before installing
  # or removing anything. Ignored on NixOS. See docs/dnf.md.
  options.my.fedora.dnf = {
    packages = strList // {description = "dnf packages to keep installed on this Fedora host.";};
    coprs = strList // {description = ''COPRs to enable, as "owner/project".'';};
    repoFiles = strList // {description = "URLs of .repo files to add with dnf config-manager addrepo.";};
    ignore = strList // {description = "Packages (globs) `dnf-sync --save` should never offer to save.";};
    swaps = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Renamed packages: { old = \"new\"; }. If old is installed, `dnf swap old new` instead of installing new.";
    };
  };

  config.my.fedora.dnf = lib.mkIf (!isNixos) {
    # (dnf-sync dedupes the merged lists; listing a package in a bundle and in the JSON is harmless)
    packages = forHost (saved.packages or {});
    ignore =
      forHost (saved.ignore or {})
      ++ [
        # Installed with reason "user" by upgrades or set up outside dnf-sync
        "kernel"
        "kernel-*"
        "nix" # init.sh (petersen/nix COPR), needed before the flake can be evaluated
        "git" # init.sh, needed to clone this repo
        # Installed by the setup/*.sh scripts, which also do non-package setup
        "docker*" # fedora-docker-setup.sh
        "containerd.io"
        "moby-engine"
        "akmod-nvidia" # fedora-nvidia-setup.sh
        "xorg-x11-drv-nvidia*"
        "nvidia-vaapi-driver"
        "libva-utils"
        "vdpauinfo"
        "dkms"
        "acpid"
        "libglvnd-*"
        "mokutil" # fedora-secureboot-mok-setup.sh
        "steam" # fedora-steam-setup.sh
        "rpmfusion-*"
        "gamemode" # fedora-gamemode-setup.sh
        "bsdtar" # fedora-xone-driver-setup.sh
        "cabextract"
      ];
  };
}
