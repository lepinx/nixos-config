# NaN model profile for Pi agent routing

## Goal
Create a named agent-model profile that routes every Pi subagent role, and the
orchestrator, through the NaN cluster, and apply it globally on this machine.

## Scope and constraints
- The profile lives in Gentle AI mutable state (`~/.pi/gentle-ai/profiles.json`),
  never in Nix: `docs/development.md` fixes `~/.pi/` as upstream-owned mutable state.
- Model choice follows NaN's own Pi guidance: `glm5.3-flash` for coding and
  reasoning work, `deepseek-v4-flash` for long-context and high-volume roles.
- `glm5.3` (the 753B premium model) is excluded: it is not in this key's live
  catalog, so naming it would only produce a 401.
- Tool calling reliability decides the mix: `glm5.3-flash` and `deepseek-v4-flash`
  expose native function calling, while `qwen3.8-flash`, `qwen3.6` and `gemma4`
  use XML tool calling and stay out of an agentic routing profile.
- Writing the store is in scope. The global apply is a Pi TUI action
  (`/gentle:profiles`) and remains a user decision; it rewrites four surfaces:
  `models.json`, the 23 agent frontmatters, `subagents.json`, and the orchestrator
  keys in `settings.json`.
- `review-refuter` is added even though it is currently unrouted: the native
  review lifecycle refuses a refuter slot typed when its routing key is missing.
- Testing mode: configuration change, no TDD runner applies.
- No commit is authorized for this task document.

## Tasks
- [x] T1 Collect the authoritative model facts and the current routing surfaces.
- [x] T2 Write the `nan` profile into the global profiles store.
- [x] T3 Validate the store file against the gentle-pi schema.
- [x] T4 Apply the profile globally from `/gentle:profiles` and confirm the
      materialized routing.
- [x] T5 Trim SDD from the profile ahead of the next release (user decision:
      ODD is the default and SDD is unused here). The profile now carries the
      orchestrator plus the 12 surviving roles only; upstream confirmed every
      one on main.
- [x] T6 Verify the SDD file cleanup path and decide the disk-file strategy
      (user decision: wait for the release). The extension itself cleans the
      17 local SDD files at the first session start after updating past 3.7.0:
      upstream `lib/agent-assets.ts` lists all 13 `agents/sdd-*.md`, the 3
      `chains/sdd-*.chain.md` and `gentle-ai/support/sdd-status-contract.md` in
      `RETIRED_MANAGED_ASSETS`, the owner filter's `sdd-` + `strict-tdd.md`
      special case admits them at startup, and ownership proof via legacy
      migration hashes (v0.13 covers 11 agents, v2.5.0 covers `sdd-research`)
      strips frontmatter routing before hashing, so materialized openai-codex
      routing does not block deletion. On 3.7.0 nothing recreates them at
      startup (owner `sdd` is never selected); only an SDD preflight flow or
      `/gentle:install-sdd --force` would. `gentle-ai sync` (Go) is not the
      cleaning path; `pi update --extensions` plus one session start is.
- [x] T7 Add an `openai` profile mirroring the upstream Codex preset
      `recommended` (gentle-ai `internal/model/codex_model.go`): orchestrator
      `openai-codex/gpt-6-sol · medium`, explore/worker lane `gpt-6-luna · high`
      (including `jd-fix-agent`, which edits code), verify lane `gpt-6-sol ·
      medium` for `gentle-ai-verify`, the four review lenses, refuter,
      validator and both Judgment Day judges. Store re-validated: profiles
      `nan` + `openai`, 12 roles each, zero `sdd-*`, byte-equivalent normalize.
      The pre-nan routing (gpt-5.6 terra/sol/luna) stays only in the backup;
      it predates upstream's gpt-6 preset migration.
- [x] T8 Version the profiles store as a repo snapshot (user decision: no new
      justfile targets, plain `cp`). `configs/pi/gentle-ai/profiles.json` is a
      hand-refreshed copy of `~/.pi/gentle-ai/profiles.json`; docs/development.md
      documents the refresh/restore commands and the no-`home.file` rationale.
      Delivered in commit `5a4ccb7`. The dirty `modules/nixos/packages.nix`
      (pre-existing Helium extension work) was deliberately left out of the
      work-unit commit.

## Routing decision
| Bucket | Model | Thinking | Roles |
| --- | --- | --- | --- |
| Orchestrator | `nan/glm5.3-flash` | high | `orchestrator` |
| Explore, worker | `nan/deepseek-v4-flash` | medium (accepted, no depth effect) | `gentle-ai-explore` `gentle-ai-worker` |
| Review, verify, Judgment Day | `nan/glm5.3-flash` | high | `review-risk` `review-resilience` `review-readability` `review-reliability` `review-refuter` `review-validator` `jd-judge-a` `jd-judge-b` `jd-fix-agent` `gentle-ai-verify` |

SDD was retired upstream (gentle-ai PR #4967, gentle-shell PR #1408, both
merged 2026-09-24/25) and is unused here, so the profile ships SDD-free: no
`sdd-*` entries. The installed 3.7.0 still carries local SDD agents; on apply,
`applyModelConfig` materializes only discoverable agents, so those local files
keep their frontmatter routing until the next release's sync cleans them.

## Evidence
- NaN `/docs/pi`: "glm5.3-flash for coding work. deepseek-v4-flash for everything
  else, which also has the widest quota on the cluster."
- `pi --list-models nan` (2026-09-27) lists `deepseek-v4-flash`, `glm5.3-flash`,
  `qwen3.8-flash`, `qwen3.6`, `gemma4`, `mimo-v2.5`, `mimo-v2.6-flash` plus
  non-chat endpoints, and no `glm5.3`.
- Quota, `GET /v1/usage` 2026-09-01..27: `deepseek-v4-flash` 29.4M of 3000M,
  `glm5.3-flash` 1.27M of 2000M. Quota is not the binding constraint.
- Profile store schema: `gentle-pi.agent_model_profiles` v1 in
  `lib/agent-profiles.ts`; entries are `{ model, thinking }` with thinking in
  `off|minimal|low|medium|high|xhigh|max`, plus the reserved `orchestrator` key.
- Apply behavior in `extensions/gentle-ai.ts`: the store claim is written first,
  then routing, then the orchestrator, with compensation on failure; agents the
  profile omits return to `inherit` instead of keeping the previous route.

## Progress
- T1 complete: model facts, live catalog, quota and schema collected read-only.
  Current routing is `openai-codex/*` in `models.json`, `subagents.json` and the
  agent frontmatters, with `review-risk`, `review-resilience` and
  `review-readability` inheriting and `review-refuter` absent.
- T2 complete: `~/.pi/gentle-ai/profiles.json` created with the `nan` profile
  (orchestrator plus 25 roles; no `active` marker, so the store does not claim a
  routing that is not materialized yet).
- T3 complete: the file round-trips through the real gentle-pi normalizer
  (`parseProfilesFileText` + `serializeProfilesFile`) with 25 roles, zero drops
  and a byte-equivalent normalize; `nan/glm5.3-flash` and
  `nan/deepseek-v4-flash` both exist in the live `pi --list-models nan` catalog.
- Revert material: `~/.pi/gentle-ai/backups/pre-nan-profile-20260927T235928Z/`
  holds `models.json`, `subagents.json`, `settings.json`, `profiles.json` and a
  copy of the 23 agent files as they were before any apply.
- Scope corrected while validating: `applyModelConfig` skips only the provider
  review roles (`review-refuter`, `review-validator`) for frontmatter and
  `subagents.json`, because those two resolve from `models.json`. The four lens
  roles are ordinary discoverable agents, so they are materialized on all three
  surfaces and no stale `openai-codex` entry survives.
- T5 complete: SDD removed from the profile by user decision. The trimmed
  store re-validates through the real normalizer: 12 roles, zero `sdd-*`
  entries, byte-equivalent normalize, 10 glm5.3-flash + 2 deepseek-v4-flash.
  Update status checked 2026-09-28: npm gentle-pi `latest` remains 3.7.0 and
  gentle-ai's newest release is v3.7.0 (2026-09-23) — no released build ships
  the SDD removal yet, so updating now changes nothing; installing straight
  from main was not offered or attempted.
- T4 complete, user-applied: the user ran the `/gentle:profiles` apply for
  `nan` themselves. Verified 2026-09-28: `models.json` (13 entries),
  `subagents.json`, the agent frontmatters and the orchestrator keys in
  `settings.json` (`nan/glm5.3-flash · high`) all carry nan routing with zero
  `gpt-5.6` references. The only remaining gpt-5.6 hit is the openai-codex
  model catalog in Pi's `models-store.json` — available models, not routing,
  regenerated by the provider's live refresh; intentionally untouched. The
  pre-apply state survives only in the backup directory (revert point).
- Incident while adding T7: rewriting the store to add the `openai` profile
  clobbered the `active: "nan"` marker the user's apply had written. Restored
  the marker and re-validated the store. Lesson: edit the store by
  read-modify-write, never by full overwrite — the apply claims `active`.
- User decision 2026-09-28: no legacy gpt-5.6 profile; gpt-6 only on the
  OpenAI side.
