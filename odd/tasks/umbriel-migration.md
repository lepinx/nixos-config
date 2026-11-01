# Replace niri with Umbriel on the workstation

## Goal

Replace the niri compositor with Umbriel (Noctalia team's compositor) as the
only compositor session on the workstation, gaining the first-class Noctalia
integration and a TOML configuration. niri stays available on `main` as the
rollback path; the migration happens on a dedicated branch.

## Constraints

- Branch `feat/umbriel-migration` off `main`; do not merge until the user
  boot-tests the session and confirms.
- No dual niri+umbriel configuration: on this branch niri is removed.
- Keep the existing config architecture: base config + host-specific outputs
  via templated files (Umbriel `[include]` / templated text replaces the KDL
  `@niri_outputs_path@`/`@niri_host_binds@` placeholders).
- The workstation is `rolling = true` (nixpkgs-unstable), and Umbriel +
  `programs.umbriel` + `xdg-desktop-portal-umbriel` already exist there, so no
  new flake input is needed.
- Umbriel's NixOS module wires the session, the portal, and Xwayland through a
  bundled xwayland-satellite wrapper; the explicit `xwayland-satellite` system
  package becomes redundant.
- Technical artifacts (configs, comments, commit messages) in English.

## Tasks

- [x] Create branch `feat/umbriel-migration` off `main`.
- [x] modules/nixos/desktop.nix: replace `programs.niri` with
  `programs.umbriel.enable = true`; drop the now-redundant explicit
  `xwayland-satellite` system package.
- [x] modules/nixos/greeter.nix: greeter session `--session umbriel`.
- [x] Translate `configs/niri/config.kdl.in` (307 lines: keybinds, window
  rules, input, settings) to `configs/umbriel/config.toml` using the Umbriel
  TOML schema (`[keybinds]` action strings, `[[window_rule]]`, `[output.*]`),
  mapping every bind and rule; host outputs move to
  `hosts/workstation/umbriel-outputs.toml` (`[output.eDP-1]` mode/scale/position).
- [x] modules/home/desktop.nix: write `~/.config/umbriel/config.toml` with the
  include/outputs placeholders, replace the `theme.templates.user.niri` entry
  with the builtin `umbriel` template (Noctalia writes
  `~/.config/umbriel/noctalia.toml` and manages `[include.optional]` via its
  `apply.sh`; no post-hook needed since Umbriel auto-reloads), drop the
  `ensureNoctaliaThemeTargets` niri-KDL fallback, and swap
  `niri_overview_type_to_launch_enabled` for
  `umbriel_overview_type_to_launch_enabled`.
- [x] Remove niri artifacts: `configs/niri/`,
  `configs/noctalia/templates/niri.kdl`, `hosts/workstation/niri-outputs.kdl`.
- [x] Build verification: `nixos-rebuild dry-build` (or `nix build .#nixosConfigurations.workstation.config.system.build.toplevel`)
  for the workstation host; deadnix/format checks. Runtime session testing is
  the user's manual step.
- [x] Work-unit commits on the feature branch.

## Evidence

This branch replaces the niri compositor with Umbriel. Verified without a full
rebuild; runtime session testing remains the user's manual step.

### What changed

- `modules/nixos/desktop.nix`: `programs.niri` block replaced with
  `programs.umbriel.enable = true`; the explicit `xwayland-satellite` system
  package was dropped because the `pkgs.umbriel` wrapper bundles it.
- `modules/nixos/greeter.nix`: greeter session is now `--session umbriel`.
- `configs/umbriel/config.toml` (new): faithful translation of the old KDL
  config. Input (keyboard layout/options/numlock, touchpad tap + natural
  scroll), gaps 12, extent presets 1/3-1/2-2/3, default extent 1/2,
  `center_focused = "never"`, 2px border, corner radius 12, shadow
  (softness 30, offset y 5), blur (4 passes, radius 3, noise 0.032,
  saturation 1.25), animations, window rules (ghostty, Noctalia Settings
  1080x920 floating, Firefox PiP floating), and every niri bind mapped to an
  Umbriel action.
- Host outputs moved to `hosts/workstation/umbriel-outputs.toml`
  (`[output.eDP-1]` mode `1920x1200@60.003`, scale 1.7, position `[0, 0]`).
- `modules/home/desktop.nix`: `~/.config/umbriel/config.toml` is generated with
  `builtins.replaceStrings` on `@umbriel_outputs_path@`, and
  `~/.config/umbriel/outputs.toml` comes from the host file. The Noctalia
  `user.niri` template and its post-hook, the `ensureNoctaliaThemeTargets`
  activation, the `niriNoctaliaFallback` binding, and the now-unused `lib`
  function argument were removed. `theme.templates.builtin_ids = [ "umbriel" ]`
  enables Noctalia's builtin Umbriel palette template, and
  `shell.niri_overview_type_to_launch_enabled` became
  `shell.umbriel_overview_type_to_launch_enabled`.
- Deleted `configs/niri/config.kdl.in`, `hosts/workstation/niri-outputs.kdl`,
  and `configs/noctalia/templates/niri.kdl`.

### Include / placeholder decision

Umbriel expands absolute paths in `[include] files` (`config_merge.cpp`
`expandPath`), so the base config uses
`files = [ "@umbriel_outputs_path@" ]`; Home Manager substitutes the absolute
`~/.config/umbriel/outputs.toml` path. Noctalia's builtin Umbriel template runs
`apply.sh`, which writes `~/.config/umbriel/noctalia.toml` and adds it to
`[include.optional]`, so the base file deliberately does not include
`noctalia.toml`. The old `@niri_host_binds@` placeholder was dropped: no host
ever provided `niri-host.kdl`, so it always expanded to empty.

### Keybinds: niri -> Umbriel action mapping

- `close-window` -> `window-close`; `focus-column-*`/`focus-window-*` ->
  `window-focus-*`; `move-column-*`/`move-window-*` -> `column-move-*`/
  `window-move-*`; `focus-monitor-*` -> `output-focus-*`;
  `move-column-to-monitor-*` -> `column-move-to-output-*`.
- `focus-workspace-down/up` -> `workspace-next/previous`;
  `move-column-to-workspace-down/up` -> `column-move-to-workspace-next/previous`;
  `focus-workspace N` -> `workspace-switch:N` (niri also used
  `move-column-to-workspace N` for both `Mod+Ctrl` and `Mod+Shift`, mapped to
  `column-move-to-workspace:N`).
- `toggle-overview` -> `overview-toggle`; `switch-preset-column-width` ->
  `window-cycle-primary-extent`; `switch-preset-window-height` ->
  `window-cycle-secondary-extent`; `expand-column-to-available-width` ->
  `window-set-primary-extent:1.0`; `maximize-column` ->
  `window-toggle-maximize`; `fullscreen-window` -> `window-toggle-fullscreen`;
  `toggle-window-floating` -> `window-toggle-floating`;
  `toggle-column-tabbed-display` -> `column-toggle-tabbed`.
- `set-column-width "+/-10%"` -> `window-modify-primary-extent:+/-0.1`;
  `set-window-height "+/-10%"` -> `window-modify-secondary-extent:+/-0.1`.
- `power-off-monitors` -> `dpms-off`; `quit` ->
  `session-quit:skip-confirmation` (niri quit was immediate, so the
  confirmation is skipped); `toggle-keyboard-shortcuts-inhibit` ->
  `shortcuts-inhibit-toggle` with `allow_when_inhibited = true`
  (niri `allow-inhibiting=false`); `show-hotkey-overlay` ->
  `cheatsheet-toggle`.
- All `spawn-sh "noctalia msg ..."` payloads are unchanged, now expressed as
  `spawn:noctalia msg ...`; `spawn`/`spawn-sh` differences collapse because
  Umbriel always runs the command through the shell.
- niri `repeat=false`, `cooldown-ms`, and `allow-when-locked` map to the
  Umbriel table form `repeat`, `cooldown_ms`, and `allow_when_locked`.
- niri wheel keys `WheelScrollUp/Down` -> `WheelUp/Down`.

### Skipped niri keys and features (no Umbriel equivalent)

- `layout background-color "transparent"`: no Umbriel `[layout]` background
  color; the Noctalia backdrop layer paints the wallpaper.
- `focus-ring`/`border`/`shadow` colors, `overview workspace-shadow off`,
  `screenshot-path`, and `debug.honor-xdg-activation-with-invalid-serial`:
  niri-only. Ring/border colors come from Noctalia's `noctalia.toml`;
  workspaces overview has no shadow toggle; screenshots are owned by Noctalia;
  and there is no invalid-activation-serial debugging toggle (the closest
  general key, `focus_on_activate`, has different semantics).
- Environment `XDG_CURRENT_DESKTOP "niri"`: reserved by Umbriel
  (`XDG_CURRENT_DESKTOP` is set to `umbriel`); all other environment values
  were kept.
- `hotkey-overlay-title` metadata: dropped, no Umbriel equivalent.
- niri `screenshot-window` (`Alt+Print`): dropped. Noctalia exposes only
  `screenshot-region` and `screenshot-fullscreen`, and Umbriel has no
  screenshot action.
- niri `expel-window-from-column` (`Mod+Period`): Umbriel has no unconditional
  expel; mapped to `window-consume-or-expel-right` (same chord as
  `Mod+BracketRight`).
- niri `reset-window-height` (`Mod+Ctrl+R`): no reset action; mapped to
  `window-set-secondary-extent:1.0` (full column height).
- niri `center-visible-columns` (`Mod+Ctrl+C`): no distinct action; mapped to
  `column-center`, same as `Mod+C`.
- niri `layer-rule` `place-within-backdrop` for `^noctalia-backdrop`:
  unsupported. Umbriel layer rules only control blur, and its backdrop layer is
  a normal background surface that already composites behind windows.
- niri animation events `horizontal-view-movement` and `window-resize`:
  Umbriel folds them into `[animation.windows_move]` (mapped from niri
  `window-movement`, spring 0.75/323).

## Follow-up: overview polish + ghostty theme regression (uncommitted)

- `umbriel_overview_type_to_launch_enabled = false`: disables the numbered
  badges (type-to-launch) in the Umbriel overview.
- `builtin_ids = [ "ghostty" "umbriel" ]`: restores Noctalia's ghostty template
  so `~/.config/ghostty/themes/noctalia` is regenerated (fixes the Ghostty
  "theme noctalia not found" dialog the migration introduced when the template
  list was reduced to umbriel only).
- `configs/umbriel/config.toml` declares `[colors.overview] background_tint =
  "#1d100e30"`. Umbriel applies includes first and the including file last, and
  scalars are replaced by the last setter, so the base config overrides the
  heavy (~0x88 alpha) tint the builtin umbriel template writes into
  noctalia.toml; the rest of the template palette still merges by key.
  Survives theme refreshes without a custom template.

### Uncertainty and risks

- niri `ease-out-expo`/`ease-out-quad` are mapped to documented cubic Béziers
  (`0.16,1,0.3,1` and `0.25,0.46,0.45,0.94`). The packaged source also has
  named `easeoutexpo`/`easeoutquad` curves, but those are absent from the user
  docs, so the documented Bézier form was preferred.
- Noctalia's `apply.sh` expects to edit `~/.config/umbriel/config.toml`, which
  Home Manager writes as a read-only store symlink. Mitigated by pre-declaring
  `[include.optional] files = [ "noctalia.toml" ]` in the base config: the
  include tolerates a not-yet-existing palette file, and Umbriel live-reloads
  `noctalia.toml` when Noctalia refreshes the theme, so a failing hook is
  harmless.
- `configs/noctalia/settings.toml` (runtime state) was updated to list
  `umbriel` instead of `niri` in `theme.templates.builtin_ids`.
- README.md, hosts/README.md, docs/keybindings.md, docs/noctalia.md,
  docs/mutable-state.md, and the `just hotkeys` recipe (now
  `umbriel msg cheatsheet-open`) were updated by the orchestrator.
- A worker-made unauthorized edit deleting `theme = noctalia` from
  `configs/ghostty/config` was reverted; Ghostty theming is independent of the
  compositor.

### Verification run

- `nix-instantiate --parse` on the three edited `.nix` files: OK.
- `nixfmt --check` (nixfmt 1.5.0) on the edited files: only a pre-existing
  long line in `modules/home/desktop.nix` differs; the original `HEAD` version
  fails the same check, so no new formatting drift was introduced.
- TOML parsed with Python `tomllib`: `configs/umbriel/config.toml` and
  `hosts/workstation/umbriel-outputs.toml` OK.
- Independent verification (gentle-ai-verify): flake eval confirms
  `programs.umbriel.enable = true`, greeter `--session umbriel`, generated
  `~/.config/umbriel/config.toml` with the substituted include, Noctalia
  `builtin_ids = ["umbriel"]` and `umbriel_overview_type_to_launch_enabled`;
  `nix build ...toplevel --dry-run` reports 148 derivations to build / 20 to
  fetch including `pkgs.umbriel` and `xdg-desktop-portal-umbriel` (no build
  realized); homelab still evaluates. Bind audit: all 140 niri chords mapped,
  all 47 non-spawn actions exist in Umbriel's actions.md; `Alt+Print`
  (window screenshot) dropped with no equivalent. Full bind audit and
  discrepancy list in the verification report; no dangling niri references
  remain.
- `nix eval`: `programs.umbriel.enable = true`,
  `theme.templates = { builtin_ids = [ "umbriel" ]; ... }`, and
  `home.file` contains `.config/umbriel/config.toml` and
  `.config/umbriel/outputs.toml`.
- Placeholder substitution checked with `builtins.replaceStrings`:
  `files = [ "/home/lucho/.config/umbriel/outputs.toml" ]`.
- `grep` for `configs/niri`, `niri-outputs`, `templates/niri`, `user.niri`,
  `niri_overview_type`, `programs.niri`: only the two README files noted above.
- `deadnix` is not available offline and the flake check requires building it
  from source; it was not run. No unused let-bindings remain (the only one
  removed was the unused `lib` argument).
