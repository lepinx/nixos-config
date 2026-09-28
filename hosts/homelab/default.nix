{ ... }:

{
  imports = [
    ../../modules/nixos/profiles/server.nix
    # hardware-configuration.nix and disko.nix are added once the real
    # hardware facts (disks, boot mode, LUKS) are known.
    # Networking is declared here per host, using a dedicated module.
  ];
}
