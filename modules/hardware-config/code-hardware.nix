# code hardware: Proxmox VE (QEMU/KVM) VM, Q35 + OVMF, one VirtIO Block disk (/dev/vda).
# Generated via `nixos-generate-config --show-hardware-config` on VM 100; fileSystems and
# swapDevices are intentionally omitted because disko below owns the disk layout.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot.initrd.availableKernelModules = ["uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
