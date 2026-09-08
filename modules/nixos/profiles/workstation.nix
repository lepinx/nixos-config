{ inputs, ... }:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    inputs.stylix.nixosModules.stylix
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
