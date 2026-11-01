# Simplify to a Pi-only agent runtime

## Objective
Remove OpenCode, Codex, and VS Code from the declarative NixOS configuration, then replace the FHS-wrapped Pi launcher with a host-native Pi runtime where compatibility permits it.

## Scope
- Remove declared OpenCode and Codex integration.
- Remove VS Code configuration, recommendations, and VS-Code-only compatibility configuration when no longer needed.
- Preserve Pi as the only coding agent, along with only the support components it actually needs.
- Test Pi outside the FHS wrapper using focused, non-activating checks.
- Update repository documentation to state one clear operating model.

## Constraints
- Do not remove the user's existing mutable binaries or data directories outside this repository without explicit confirmation.
- Preserve Herdr, Gentle AI, Engram, and CodeGraph unless evidence shows they are unnecessary for Pi-only use.
- Do not activate the system, commit, push, or publish without explicit authorization.
- Existing user change: `flake.lock` is modified before this feature and must not be overwritten.
- TDD: not applicable; declarative configuration and runtime integration.

## Tasks
- [x] T1 — Map the precise declared surfaces for OpenCode, Codex, VS Code, and the current FHS Pi runtime; preserve unrelated editor and terminal configuration.
- [x] T2 — Remove the obsolete agent/editor declarations and implement a host-native Pi runtime with a narrow, explicit package/state boundary.
- [x] T3 — Update documentation and run configuration plus Pi runtime checks without activation. (docs and just check/build completed per progress notes)
- [x] B1 — Diagnose and remove the unused insecure `NetworkManager-fortisslvpn-gnome-1.4.0` plugin.
- [x] B2 — Diagnose and remove the unused insecure `NetworkManager-vpnc-1.4.0` plugin.
- [x] B3 — Activate the reviewed NixOS configuration and smoke-test native Pi/Herdr integration. (activation happened across later switches; native pi 1.1.0 verified in daily use)

## Acceptance criteria
- OpenCode, Codex, and VS Code are no longer declared or recommended by this repository.
- Pi remains the sole coding-agent entry point and no longer requires the FHS wrapper if focused runtime checks pass.
- The NixOS configuration evaluates and builds without activating the system.
- Documentation clearly distinguishes Nix-declared dependencies from mutable upstream Pi/Gentle AI state.

## Progress
- T1 complete: OpenCode is in `modules/nixos/packages.nix`; Codex and the FHS Pi runtime are in `modules/home/development.nix`; VS Code is configured by `modules/home/editors.nix` and `.vscode/extensions.json`; related policy/documentation is in `modules/home/theme.nix`, `modules/nixos/core.nix`, `modules/home/default.nix`, `README.md`, and `docs/development.md`.
- T2 complete: OpenCode, the Codex wrapper, and VS Code declarations were removed. Pi/CodeGraph now use a host-native Node runtime with the npm prefix declared in Home Manager; the FHS launcher and its compatibility layers were removed. The prior VS-Code-specific `nix-ld` setting had no relationship to the active configuration surface and was left untouched pending focused verification.
- T3 documentation complete: `README.md` and `docs/development.md` now define Pi as the only coding agent and describe the native host runtime; `.vscode/extensions.json` was removed.
- B1 complete: the user confirmed FortiSSLVPN is unused, so `networkmanager-fortisslvpn` was removed from the workstation networking module.
- B2 complete: the user confirmed VPNC is unused, so `networkmanager-vpnc` was removed from the workstation networking module.
- T3 configuration validation now passes: `just check`, `just build`, and `git diff --check` passed. Nix emitted only the dirty-tree warning and a Noctalia Greeter option-rename warning.
- The user explicitly authorized `just switch`, but activation could not run in this Pi sandbox: sudo failed because `no_new_privileges` prevents elevation. No alternate activation command was attempted.
- B3 remains pending: run `just switch` in a normal host terminal, then open a new shell, verify `command -v node` and `command -v pi`, run `pi --version`, and test whether Herdr notices the expected Pi event. A Pi process exit and a completed interactive turn are distinct events, so record which one should trigger sound.
- No system activation was performed; native Pi runtime behavior remains unverified.

## Evidence
- OpenCode is declared in `modules/nixos/packages.nix`.
- Codex is an FHS wrapper in `modules/home/development.nix`.
- VS Code is configured by `modules/home/editors.nix` and `.vscode/extensions.json`; an earlier ODD record identifies a VS-Code-only `nix-ld` configuration that must be assessed before removal.
- Pi currently launches through `buildFHSEnv`, which is a likely contributor to Herdr process detection failure.

## Delivery
- No commit is authorized by the user.
