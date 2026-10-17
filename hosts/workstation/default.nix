_:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/nixos/encryption.nix
    ../../modules/nixos/profiles/workstation.nix
  ];
}
