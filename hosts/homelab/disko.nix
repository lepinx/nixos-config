{
  diskDeviceBoot ? "/dev/sda",
  hostName ? "homelab",
  ...
}:

let
  btrfsMountOptions = [
    "compress=zstd"
    "noatime"
    "ssd"
    "discard=async"
  ];
in
{
  # The data HDD is intentionally NOT managed by disko: it is staged with plain
  # Btrfs before install, and having disko reference it would reformat and
  # destroy that data. It is mounted by label in default.nix instead.
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
