# Feature: noctalia-theme-coherence

## Goal

Make Noctalia the single source of truth for system theming: animated Ghostty
cursor shader, Noctalia community templates for yazi/zed, and full Stylix
removal (GTK/QT fall back to stock Adwaita dark by user decision).

## Constraints

- Shader must be calm/classic (cursor_smear), not psychedelic.
- Noctalia state file (`configs/noctalia/settings.toml`) is out-of-store and
  wins over nix module settings; edits land there.
- Stylix removal must not break eval: wofi style colors must be hardcoded to
  the previous ayu-dark base16 values.
- Generated artifacts in English; conversation in Spanish.

## Tasks

- [x] Add Ghostty cursor_smear shader (repo file, xdg.configFile entry, two
      config lines: custom-shader + custom-shader-animation).
- [x] Enable Noctalia community templates: community_ids = ["yazi", "zed"] in
      configs/noctalia/settings.toml.
- [x] Remove Stylix: flake.nix inputs (stylix, stylix-unstable) + stylixModule
      specialArgs, workstation.nix import/param, delete modules/nixos/stylix.nix
      and modules/home/theme.nix, hardcode ayu-dark colors in shell.nix wofi style.
- [x] Verify: nix eval toplevel drvPath, nix fmt, deadnix; work-unit commits.

## Evidence

- Merged fast-forward to `main` (9c7aa67) and pushed; feature branch deleted
  locally and never existed on origin.
- Work-unit commits:
  - `e66686f` feat(ghostty): add animated cursor smear shader
    (`configs/ghostty/shaders/cursor_smear.glsl` from KroneCorylus upstream,
    `custom-shader` + `custom-shader-animation = always` in
    `configs/ghostty/config`, store symlink via `modules/home/desktop.nix`).
  - `e9639e2` feat(noctalia): enable yazi and zed community templates
    (`configs/noctalia/settings.toml`, ids verified against
    noctalia-dev/community-templates catalog).
  - `cd31f5c` style: apply nixfmt-tree formatting (drive-by reformat only).
  - `de523f1` refactor(theme): remove stylix; wofi style now uses hardcoded
    ayu-dark base16 palette. Flake lock pruned of stylix inputs.
  - `357269b`, `8bf05a5`, `cd607e6` — authored by a concurrent agent session
    (nix-ld cleanup + pkgsUnstable→pkgs migration); my parallel revert raced
    with it and `cd607e6` resolved the leftover `pkgsUnstable` uses. Coherent
    because the workstation is rolling (pkgs == nixos-unstable there) and
    homelab has no home-manager.
- Verification: `nix eval` toplevel drvPath OK for workstation and homelab;
  `deadnix --fail .` clean; `nix fmt` idempotent.
- Not run (user decision): `just switch` / full system build and runtime
  visual check of the shader; Noctalia Settings → Templates fetch of the
  community templates on next shell start.

## Follow-ups

- Optional: select theme "Noctalia" inside zed settings (template writes
  ~/.config/zed/themes/noctalia.json).
- Optional later: more community templates exist for apps in use (herdr,
  neovim, lazygit, bat, fzf, discord, thunderbird).
- Coordination: do not run two writer agent sessions on this worktree at once.
- Note: a concurrent session added `9c7aa67` (docs(mutable-state)) just before
  the merge; it rode along in the fast-forward.
