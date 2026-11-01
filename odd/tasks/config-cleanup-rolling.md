# Config cleanup after the rolling workstation

## Goal

Remove leftovers from the pre-rolling era and fix repository verification.

## Tasks

- [x] Remove orphaned `programs.nix-ld` (icu) and its doc (8bf05a5) — added for the MSSQL VS Code extension, removed with the editors cleanup.
- [x] `nix flake check` passes clean again (the base16-schemes drv error was transient store corruption; stylix removal in de523f1 also removed that dependency tree).
- [x] Drop the redundant `pkgsUnstable` indirection in home modules and the workstation-only desktop module (357269b, cd607e6) — the rolling workstation already evaluates against unstable.
- [x] Investigate and document the standalone gentle-shell launcher option (docs/mutable-state.md).

## Notes

- A concurrent session reintroduced pkgsUnstable uses in shell.nix between
  the cleanup pass and the commit; re-applied and verified with a clean
  build + flake check. Avoid running two agents on the same branch.
- Commits land on the user's active branch feat/noctalia-theme-coherence;
  merge to main is the user's call while that feature is in flight.
