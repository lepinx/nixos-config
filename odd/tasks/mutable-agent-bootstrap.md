# Bootstrap mutable agent tooling

## Goal

Close the reproducibility gap left by the declarative configuration: on a
fresh NixOS install, the pieces that pi and the agent ecosystem manage
mutably (pi extensions, codegraph, gentle-ai) are reconstructed by one
versioned, idempotent script, and the declared-vs-mutable map is documented
so nothing is forgotten.

## Constraints

- Never version or touch secrets (`auth.json`, API keys, sessions).
- The script must be idempotent: safe to re-run; skip what is already present.
- pi owns its extension lifecycle (`pi install`, `pi update --extensions`);
  Nix must not manage that directory.
- NixOS dependency: the gentle-pi postinstall needs `/usr/bin/tar` (tmpfiles
  rule); the script must check for it and point at `just switch` otherwise.
- Keep the standalone gentle-ai binary optional (pi uses the package-local
  one).
- Ordinary functional verification; no TDD runner applies to a bash script.

## Tasks

- [x] Write `scripts/bootstrap-agents.sh` (guarded, idempotent, verification at the end).
- [x] Wire `just bootstrap-agents` recipe.
- [x] Add `docs/mutable-state.md` with the declared-vs-mutable map and reconstruction steps.
- [x] Run locally to prove idempotency, commit (fbfa29a). Push left to the user after the safety-policy confirmation prompt.
