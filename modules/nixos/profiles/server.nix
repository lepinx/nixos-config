{ ... }:

{
  imports = [
    ../core.nix
    ../maintenance.nix
  ];

  # Networking, boot, users and services are declared per host or via
  # dedicated service modules, never by this profile.
}
