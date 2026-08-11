# Host-specific entrypoint for the office machine.
# Generate hardware-configuration.nix from the NixOS ISO before enabling this
# host in flake.nix.
{ pkgs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/nixos/encryption.nix
    ../../modules/nixos/profiles/workstation.nix
  ];

  # SQL Server is published by ~/workspace/sql/compose.yaml as 1433:1433.
  networking.firewall.allowedTCPPorts = [ 1433 ];

  environment.systemPackages = with pkgs; [
    teams-for-linux
  ];
}
