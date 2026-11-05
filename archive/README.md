# Archive

Nothing in this folder is imported by `flake.nix`. It's kept for reference and so it's easy to bring back.

- `legacy/`: old bootstrap scripts, unused host files and modules, and the removed `ubuntu@ubuntu` output (`ubuntu-output.nix.txt`).
- `plasma/`: the KDE Plasma + plasma-manager setup the NixOS hosts used before moving to niri + DMS.

To bring a module back, `git mv` it out of `archive/` and import it again from a host file.
