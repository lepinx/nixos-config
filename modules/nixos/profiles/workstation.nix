{ inputs, stylixModule, ... }:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    # Selected per host in flake.nix: stable stylix for stable hosts, master
    # for the rolling workstation.
    stylixModule
    ../core.nix
    ../desktop.nix
    ../greeter.nix
    ../hardware
    ../maintenance.nix
    ../workstation-networking.nix
    ../packages.nix
    ../stylix.nix
    ../virtualization.nix
    ../workstation.nix
  ];
}
