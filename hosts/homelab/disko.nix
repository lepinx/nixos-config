{
  diskDeviceBoot ? "/dev/sda",
  hostName ? "homelab",
  ...
}:

let
  # SSD (OS disk) mount options: same as the workstation layout.
  btrfsMountOptions = [
    "compress=zstd"
    "noatime"
    "ssd"
    "discard=async"
  ];
in
{
  # The data HDD is intentionally NOT managed by disko. It is staged with plain
  # Btrfs from a live boot before install (label `homelab-data`, one subvolume
  # per user), and mounted declaratively by filesystem label in default.nix, so
  # the staged data survives the install untouched. Letting disko reference the
  # data disk would reformat it and destroy that staged data. Encrypting the
  # data disk with LUKS is a documented future option for the next hardware
  # generation (with real backups in place).
  disko.devices = {
    disk.boot = {
      type = "disk";
      device = diskDeviceBoot;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };

          cryptroot = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  hostName
                ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = btrfsMountOptions;
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = btrfsMountOptions;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = btrfsMountOptions;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
