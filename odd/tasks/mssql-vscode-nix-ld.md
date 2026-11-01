# Restore MSSQL extension runtime on NixOS

## Objective
Enable the dynamically linked .NET runtime acquired by VS Code so `ms-mssql.mssql` can start SQLToolsService on NixOS.

## Problem and evidence
VS Code activates `ms-mssql.mssql@1.43.0`, but its runtime fails with `NixOS cannot run dynamically linked executables intended for generic Linux environments`; SQLToolsService then terminates. No `nix-ld` configuration exists in the active NixOS configuration.

## Scope
- Modify `modules/nixos/core.nix` only for the system configuration.
- Maintain this ODD record.

## Constraints
- Do not modify VS Code extensions, SQL Server credentials, or repository SQL sources.
- Do not activate the NixOS configuration, restart VS Code, commit, or push without explicit authorization.
- TDD: not applicable; declarative Nix configuration.
- Validation: `just check` and `just build`.

## Tasks
- [x] T0 — Resolve the cross-repository routing blocker by resuming from the target `nixos-config` worktree.
- [x] T1 — Add minimal `programs.nix-ld` configuration with required library support in `modules/nixos/core.nix`.
- [x] T2 — Run focused Nix configuration checks and report the explicit activation and VS Code smoke-test steps.

## Acceptance criteria
- `programs.nix-ld` is enabled with library support needed by the VS Code-managed .NET runtime.
- Configuration checks pass, or failures are recorded exactly.
- The report distinguishes configuration validation from activation and MSSQL runtime smoke testing.

## Progress
- T0 complete. This session is rooted at the authorized target worktree.
- T1 complete. `core.nix` now accepts `pkgs`, enables `programs.nix-ld`, and supplies `pkgs.icu`.
- Writer validation passed: `nix-instantiate --parse`; evaluation confirms nix-ld is enabled and includes `icu4c`; `git diff --check -- modules/nixos/core.nix`.
- T2 complete. `just check`, `just build`, and `git diff --check` all passed. Nix warned only that the working tree is dirty due to this uncommitted change and its tracker.
- Not performed by constraint: system activation, VS Code restart, MSSQL extension runtime smoke test, commit, and push.

## Evidence
- VS Code log: `~/.config/Code/logs/20260921T095537/window1/exthost/output_logging_20260921T102000/10-SQLToolsService.log`.
- Prior tracking was preserved in Engram observation 159.

## Manual next steps
1. Review the diff, then explicitly authorize activation if desired: `just switch`.
2. Restart VS Code completely and open an MSSQL connection.
3. Confirm SQLToolsService starts without the generic-Linux/NixOS dynamic-linker error in the VS Code extension log.
