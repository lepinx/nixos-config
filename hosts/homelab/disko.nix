{
  diskDeviceBoot ? "/dev/sda",
  diskDeviceData ? "/dev/sdb",
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

  # Rotational disk: no "ssd" or "discard=async" hints for the HDD.
  hddBtrfsMountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
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

    disk.data = {
      type = "disk";
      device = diskDeviceData;
      content = {
        type = "gpt";
        partitions = {
          cryptdata = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptdata";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "homelab-data"
                ];
                subvolumes = {
                  # One subvolume per user. Additional users follow the same
                  # pattern: add a "/<user>" subvolume mounted at
                  # "/srv/data/<user>" and a matching Samba share. Btrfs qgroup
                  # quotas are a documented runtime follow-up.
                  "/lucho" = {
                    mountpoint = "/srv/data/lucho";
                    mountOptions = hddBtrfsMountOptions;
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
