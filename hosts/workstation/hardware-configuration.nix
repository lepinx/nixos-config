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

  # Lid: suspend then hibernate after 45 min (RTC wake): short pauses wake
  # instantly, long ones cost no drain.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";
  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
