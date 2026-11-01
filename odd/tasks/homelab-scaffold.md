# Feature: homelab-scaffold

Goal: scaffold the future NixOS homelab host for versioning, without exposing
an unbuildable nixosConfigurations entry.

## Tasks

- [x] Fix modules/nixos/profiles/server.nix: remove the import of
      ../networking.nix (file does not exist; networking is declared per host).
- [x] Scaffold hosts/homelab/: default.nix importing the server profile, no
      Home Manager, no hardware-configuration yet.
- [x] Update hosts/homelab/README.md and hosts/README.md to reflect the new
      scaffold state and the pending hardware scan step.
- [x] Verify: nix flake check, nix fmt check on touched files.
- [x] Commit as a work unit on a feature branch.

## Evidence

- Branch: feat/homelab-scaffold
- Commit: 52408f2 feat(homelab): scaffold future server host (feat/homelab-scaffold)

## Open decisions (blocked on hardware facts from the old Ubuntu tower)

- TPM2 present? decides LUKS unlock model (TPM2 auto-unlock vs SSH initrd
  unlock vs console passphrase).
- Disk count/layout for disko.nix.
- Fixed IP / DHCP reservation and SSH hardening details.
- First services (undecided by user).
