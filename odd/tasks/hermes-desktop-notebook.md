# Feature: hermes-desktop-notebook

Install Hermes Desktop on the workstation (NixOS) via the upstream Hermes Agent
flake's Home Manager module. Desktop connects to the homelab backend later
(homelab side is a separate deferred feature; see Engram `hermes-agent-homelab`).

## Tasks

- [x] T1 — Add `hermes-agent` flake input to `flake.nix` (workstation consumes it
  via `extraSpecialArgs.inputs`).
- [x] T2 — Add `modules/home/hermes-desktop.nix` enabling only the Desktop app
  (`programs.hermes-agent.desktop`), no local gateway/backend.
- [x] T3 — Register the module in `modules/home/default.nix` imports.
- [x] T4 — Verify: `nix flake check` + eval of
  `nixosConfigurations.workstation.config.home-manager.users.lucho.programs.hermes-agent.desktop.enable`.
- [ ] T5 — Build + switch (`just`-driven or `nixos-rebuild`) and confirm the app
  launches. DEFERRED: needs user's go because the Desktop closure is heavy
  (Electron + bundled runtime, ~1GB+) and the switch restarts the user session
  components.

## Constraints

- No secrets in Nix store. Desktop config lives in `~/.hermes/` (mutable, app-owned).
- Rolling workstation (nixpkgs-unstable + HM master): hermes flake pins its own
  nixpkgs; upstream marks Nix support Tier 2 best-effort.
- Do NOT enable `services.hermes-agent` locally (backend belongs to homelab).

## Evidence

- T4: `nix eval .#nixosConfigurations.workstation.config.home-manager.users.lucho
  .programs.hermes-agent.desktop.enable` → `true`; desktop package resolves as
  `hermes-desktop-0.0.0`; `nix flake check` → all checks passed.
- T1–T3 content committed, but a concurrent session swept the staged files into
  its own `7ff9d61 test(umbriel)` commit; the work-unit commit `37ded4f`
  (feat/hermes-desktop-notebook) only carries flake.lock. History fix pending
  user approval (parallel writer may be live).
- (T5 pending user go: heavy Electron closure, session restart on switch.)
