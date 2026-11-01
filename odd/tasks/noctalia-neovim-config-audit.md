# Noctalia Neovim coherence and configuration audit
Authorized correction: make Noctalia the only selected Neovim colorscheme; audit the tracked configuration for conflicts and inconsistencies without silently changing unrelated behavior.

## Specs
S1. "Si, noctalia como unico esquema me parece bien.. Si corrige.. lo de matugen no es interno?"
S2. "Quiero que valides toda mi config tambien, en busca de conflictos, o incoherencias por favor. Completo"

## Tasks
T1 [S1] Done: traced both upstream templates; disabled neovim template and removed tracked old Matugen integration; commit: ebb7494.
T2 [S1] Done (bounded): RED duplicate spec (exit 1), GREEN one spec + headless :colorscheme noctalia + :NoctaliaContrast, Noctalia TOML validation; commit: ebb7494. Full LazyVim user startup remains unverified without accessing mutable user state.
T3 [S2] Done: audited 102 tracked files by map and cross-reference scans; Nix flake check plus workstation/homelab drvPath eval pass, Nix parse/format pass, 9 TOML parse, JSON parse, 17 Lua syntax files, shellcheck -s bash pass, Noctalia settings validate pass. Commit: no repository changes (read-only audit).
T4 [S1-S2] Done: recorded proof limitations and findings below; commit: no repository changes (this file is ignored ODD state).

## Log
L1. Si, noctalia como unico esquema me parece bien.. Si corrige.. lo de matugen no es interno? Quiero que valides toda mi config tambien, en busca de conflictos, o incoherencias por favor. Completo
L2. Baseline: branch fix/noctalia-neovim-coherence from main; main contains the two preceding Noctalia commits b2a1871 and 36f1488.
L3. User explicitly authorized removal of old Matugen tracked integration; discovery: configs/nvim/lua/matugen.lua is ignored/unversioned generated state, so it was not deleted under consent premised on Git recovery. Noctalia community neovim template would recreate base16.lua unless its ID were disabled; lazyvim template remains enabled. Sources: upstream community-templates/neovim/{template.toml,apply.sh} and lazyvim/{template.toml,apply.sh}.
L4. ebb7494 is the implementation slice. Native assessment of committed range HEAD^..HEAD: medium, reviewDue false, no independent verifier. Historical two earlier commits on main total >400 lines with this one; no further implementation slice planned.
L5. Audit findings: docs/noctalia.md still claims git diff shows exactly the UI change although serializer reorders the whole file, and its 'declarative layer' list is stale against modules/home/desktop.nix (which holds only structural keys); documentation correction is separate from S1 code change. Initial shellcheck without shell dialect failed SC2148 on two scripts embedded via pkgs.writeShellApplication; rerun with -s bash passed. `nix flake check` warns unknown output diskoConfigurations (custom output consumed by Disko CLI; not a build failure). Flake check verifies deadnix and evaluations, not builds of both host systems. No other concrete contradictory settings identified in tracked files; cannot certify absence of runtime issues.
L6. User authorized inspecting /home/lucho/.config/nvim then specifically /home/lucho/.local/share/nvim and /home/lucho/.local/state/nvim. Live lazyvim.json marker present, colors/noctalia.lua and plugins/noctalia.lua resolve to repo, obsolete base16.lua/theme.lua absent. Headless real startup: ACTIVE_COLORSCHEME=noctalia, NOCTALIA_COMMAND=2, NVIM_STARTUP_EXIT=0. Wallpaper/palette transition and user-visible refresh were not exercised.
