# Machine-specific hardware configuration.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # Hibernate-to-disk: swapfile lives on the encrypted btrfs volume.
    # resume_offset was computed with:
    #   btrfs inspect-internal map-swapfile -r /swap/swapfile
    resumeDevice = "/dev/mapper/cryptroot";
    kernelParams = [ "resume_offset=5118345" ];
  };

  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  # Lid: suspend, then hibernate after the delay (RTC wake alarm).
  # Pauses < 45 min wake instantly; overnight or longer hibernates (zero drain).
  # If a btrfs balance ever relocates the swapfile, recompute resume_offset
  # with: btrfs inspect-internal map-swapfile -r /swap/swapfile
  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";
  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
