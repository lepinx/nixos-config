# Machine-specific hardware configuration.
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Typical server hardware: USB controllers, SATA/AHCI and SCSI/optical.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];

  # fileSystems and swap are supplied by disko; this host has no swap partition
  # and does not need zram.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
