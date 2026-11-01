{
  diskDeviceBoot ? "/dev/vda",
  ...
}:

{
  # Proxmox VM system disk (virtio, on the host SSD / local-lvm). Family data
  # lives in the host zfs pool (tank), shared into the VM separately; this
  # disk only holds the OS.
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

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}
