{ inputs, ... }:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
    ../core.nix
    ../desktop.nix
    ../greeter.nix
    ../hardware
    ../maintenance.nix
    ../workstation-networking.nix
    ../packages.nix
    ../virtualization.nix
    ../workstation.nix
  ];
}
