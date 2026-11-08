# gentle-shell migration

Make `gentle-shell` the single agent entrypoint on top of the nix-managed Pi, remove the Codex CLI, and keep every piece of agent config versioned and reconstructable. Route: Path A standalone launcher, `home link`, so one home (`~/.pi/agent`) stays the only source of truth.

## Specs

**S1.** "queria migrarme a gentle-shell" — gentle-shell is the only entrypoint the user launches; the harness (gentle-ai, ODD, subagents, Engram) must be loaded by default, never a bare Pi. Concretely: `gentle-shell` resolves and works from a clean shell, loads `gentle-pi`, and reuses `~/.pi/agent` (`gentle-shell home link`). No second agent home is created at `~/.gentle-shell/agent`.

**S2.** "tengo codex, que no voy a usarlo mas" — the Codex CLI is not installed by the flake and is not documented as a supported agent. The `nan` provider and the `openai` profile models (`openai-codex/*`) are provider/model ids, not the CLI: they are not removed by S2.

**S3.** "quiero dejar la config mas limpia posible.. y versionable con nixos" — every versioned file that Nix writes is still versioned, every runtime-owned file stays mutable, and `docs/mutable-state.md` plus `docs/development.md` describe exactly that split with no stale claims.

**S4.** "reportemos en issue esto" — the crash is reported against the upstream project without duplicating an existing report. Done: commented on Gentleman-Programming/gentle-shell#2580 (published 4.7.0 crash stack, catch-branch analysis), comment id 6728329169.

## Tasks

- **T1** — Provision `gentle-pi` (Path A launcher) into the existing mutable npm prefix, idempotently, as `provision-agent-tools` already does for codegraph. Covers `S1`. Done in `b222d6e` (`feat(pi): provision the gentle-shell launcher`). Risk: item 5.
- **T2** — Make `gentle-shell` the entrypoint: `gentle-shell home link` so it reuses `~/.pi/agent`, and verify launch + no isolated home. Covers `S1`. Done in `b222d6e` (launcher) and `6ca1d24` (docs); the link itself is machine state, not a repo file. Risk: none.
- **T3** — Remove Codex: drop `pkgs.codex` from `modules/home/development.nix`, drop codex claims from `docs/development.md`, document `~/.codex` as removable state. Covers `S2`, `S3`. Done in `eb3c1b1` (`chore(pi): drop the codex CLI`). Risk: item 5.
- **T4** — Reconcile the versioning docs with reality: `docs/mutable-state.md` (declared vs mutable, launcher, settings.json/subagents.json drift) and `docs/development.md` (provision list). Covers `S3`. Done in `6ca1d24` (`docs: describe the launcher entrypoint and its state`). Risk: none.

## Log

**L1** (user, verbatim): "Es que yo uso pi, con el ecostistema harness de gentle ai.. no quiero usar pi sin esto.. por eso queria migrarme a gentle-shell.. y dejar limpio, si tengo otros agentes no quiero usarlo.. tengo codex, que no voy a usarlo mas... quiero dejar la config mas limpia posible.. y versionable con nixos.. Antes de seguir con esto, reportemos en issue esto y sigamos con esta migracion + versionado en nixos"

**L2** (evidence): crash reproduced from `~/.pi/agent/crashes.json` on gentle-pi 4.7.0, stack `skill-registry.ts:950` <- `:813` (the refresh `catch` notifying through a stale ctx). Upstream #2580 already describes the mechanism; S4 resolved by commenting there instead of opening a duplicate.

**L3** (decision): `home link` over an isolated home. The user never wants Pi without the harness, so a second home would duplicate eight symlink blocks and buy no isolation. Reversible with `gentle-shell home unlink`.

**L4** (evidence): `npm i -g gentle-pi` into a scratch prefix works on this host without `go` and without `/usr/bin/tar`; npm 11 gates the postinstall behind `allowScripts`, and installing again with `--allow-scripts` produced an identical 270M tree with no gentle-ai artifact. The launcher runs regardless: `gentle-shell --version` reported `gentle-shell 4.7.0 / pi 1.5.0 / home isolated`, resolving the nix-managed Pi from PATH.

**L5** (scope, S2): `openai-codex/*` in `profiles.json` are provider/model ids for the `openai` profile (`active: nan`), not the Codex CLI. Removing the CLI does not remove them, and `~/.codex/auth.json` may back that provider, so the directory stays on disk and is documented as state.

**L6** (verification, inline): `bash -n` and `shellcheck` clean; `nix flake check` exit 0, "all checks passed"; the provision script is idempotent (second run installs nothing, exit 0); `gentle-shell home link` reports `home link /home/lucho/.pi/agent` and `~/.gentle-shell/agent` was never created; `gentle-shell -p` exited 0 in 17s and the session it wrote carries the el Gentleman persona, ODD and the `gentle-ai-explore` subagents, proving the harness — not a bare Pi — answered; `just health` reports pi, gentle-shell, codegraph, gentle-ai, engram and gentle-pi ok; the live `~/.pi/agent/settings.json` went from 5 to 4 packages with a timestamped backup.

**L7** (scope): the independent verifier was not admitted because the launch carried no `Risk: item N` declaration, and its instruction is not to retry or fabricate one. Verification stayed inline and empirical, as recorded in L6.
