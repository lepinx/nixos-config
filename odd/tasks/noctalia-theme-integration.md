# Noctalia theme integration
Owner: Noctalia palettes; keep unrelated settings and generated outputs intact.
Delivery: no switch, commit, or push without a new user request.

## Specs
S1. "Mira que quiero tener todo bien integrado con noctalia.. pero es extremadamente feo no queda con nada.. no se que pasa" (`/tmp/gpMOosXE/pi-clipboard-92b90955-4fa6-4832-a0ca-d096c7ddcf92.png`)
S2. "a lazygit, delta, nvim todo lo que no este bien correctamente para que se adapte bien a los themes noctalia como debe ser d"

## Tasks
T1 [S1-S2] DONE: official Noctalia Lazygit template retained by owner choice, known marker contrast caveat accepted; route: inline; commit: none (withheld).
T2 [S1-S2] DONE: Delta uses Git's terminal palette feature instead of isolated defaults; route: inline; commit: none (withheld).
T3 [S1-S2] BLOCKED: structural/functional checks, Nix build and independent verification passed; awaits user's reopened-Lazygit visual confirmation; route: inline + independent verification; commit: none (withheld).

## Log
L1. Mira que quiero tener todo bien integrado con noctalia.. pero es extremadamente feo no queda con nada.. no se que pasa
L2. a lazygit, delta, nvim todo lo que no este bien correctamente para que se adapte bien a los themes noctalia como debe ser d
L3. Screenshot shows Lazygit commit diff. Current Noctalia palette Rosé Pine in settings; Lazygit config has stale fixed hex colors because its community template is disabled. Lazygit calls Delta with --no-gitconfig, bypassing the existing [delta "noctalia-ansi"] styles. The existing Neovim theme loads noctalia via the prior uncommitted cleanup. Preserve unrelated UI-written settings, including wallpaper and palette changes.
L4. T1: Noctalia rendered and merged its official Lazygit theme after enabling the template. `configs/lazygit/config.yml` gui.theme now matches Rosé Pine (primary #ebbcba, secondary #9ccfd8, on_surface #e0def4); non-theme settings and the Delta command were preserved. No commit.
L5. T2: On the same sample diff, the old `delta --no-gitconfig --syntax-theme noctalia` emitted six ANSI background escapes. The new renderer inherits Git's `noctalia-ansi` and `syntax-theme=ansi`; dark and light samples emit zero background escapes. Documentation updated; no commit.
L6. Independent verifier found official Lazygit theme pairs with 1.62:1 (`#908caa` on `#31748f`) and 1.79:1 (`#31748f` on `#eb6f92`) contrast, measured in parent with WCAG luminance calculation. These cherry-picked/marked-base marker pairs remain hard to read despite fixing the screenshot's dominant diff colors. Noctalia's official hook regenerates and overwrites the entire `gui.theme`, so direct edits will not persist. Nix flake check and Home Manager build passed; visual Lazygit inspection not observed.
L7. Owner selected: "Mantener el template oficial (más simple)". Keep the two documented low-contrast marker pairs as an accepted upstream caveat, rather than adding a local template and second integration owner. Completion checks: official hook produced matching Rosé Pine GUI palette, Delta old six vs new zero backgrounds in dark/light, Neovim colorscheme and Tree-sitter active headless, Nix evaluation/build pass. No switch, commit, or push. The user must reopen Lazygit for a visual confirmation before T3 is closed.
