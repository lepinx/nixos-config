{ ... }:

{
  # Rolling workstation: the whole host is built from nixos-unstable by
  # mkNixos (rolling = true in flake.nix), giving a Fedora-like freshness with
  # `just rollback` as the safety net. The homelab host stays on the stable
  # release.
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/nixos/encryption.nix
    ../../modules/nixos/profiles/workstation.nix
  ];
}
