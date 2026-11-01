{
  lib,
  modulesPath,
  ...
}:

{
  # QEMU/KVM guest profile: virtio initrd modules, growPartition and the
  # qemu-guest-agent. fileSystems come from disko; this VM has no swap (the
  # Proxmox host carries it).
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
