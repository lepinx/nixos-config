# Rolling workstation packages

## Goal

Give the workstation a Fedora-like freshness while keeping the declarative
NixOS workflow: nixos-unstable as the default package set for the workstation
host (homelab stays on stable), plus a `just up` recipe as the daily
update-and-switch command.

## Constraints

- Homelab keeps the stable `nixpkgs` (26.05) package set: servers prefer stability.
- Mixing an external `nixpkgs.pkgs` (unstable) into a 26.05 NixOS module system
  is unsupported and breaks in the modular-services machinery
  (`lib.importService` missing in unstable's `lib/services/lib.nix` when the
  module set comes from `pkgs.path` but the eval lib is 26.05). The supported
  pattern is a separate rolling `nixosSystem` built entirely from
  nixpkgs-unstable, with home-manager master and stylix master as its
  matching module inputs.
- No automatic unattended updates; updates stay user-triggered (`just up`).
- Keep implementation and docs in English repository artifacts.

## Tasks

- [x] Wire `nixpkgs.pkgs = pkgsUnstable` into `hosts/workstation/default.nix`. (abandoned: unsupported mixing)
- [x] Add a rolling `mkNixos` path in flake.nix: nixpkgs-unstable + home-manager master + stylix master for the workstation host.
- [x] Verify `nix build .#nixosConfigurations.workstation.config.system.build.toplevel` succeeds.
- [x] Add `just up` recipe (update + switch) to the justfile.
- [x] Commit as a work unit on the current feature branch. (5e59320)
