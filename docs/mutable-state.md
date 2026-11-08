# Mutable vs declared state

The flake rebuilds the system and the home environment, but some pieces are
intentionally mutable: their lifecycle belongs to an upstream tool (pi, the
gentle-shell installer) or they are data, not configuration. This page maps
both layers and how to reconstruct a fresh machine completely.

## Declared (versioned, rebuilt by `just switch`)

| Piece | Where |
| --- | --- |
| System packages, desktop, umbriel, noctalia base | `modules/nixos/`, `flake.nix` |
| Home environment, fish, git, nvim, yazi | `modules/home/` |
| Ghostty config (hot-reload symlink) | `configs/ghostty/config` |
| Noctalia UI overrides (hot-reload symlink) | `configs/noctalia/settings.toml` |
| Nvim config (hot-reload symlinks) | `configs/nvim/` |
| `/usr/bin/tar` bridge for gentle-pi's postinstall | `modules/nixos/core.nix` (tmpfiles rule) |
| pi binary | `modules/home/development.nix` |

Rule of thumb: `readlink -f <path>` ending inside this repository is mutable
and hot-reloads; ending in `/nix/store` is declared and needs `just switch`.

## Mutable (provisioned on first login)

| Piece | Owner | Reconstructed by |
| --- | --- | --- |
| gentle-ai CLI | upstream installer, then `gentle-ai upgrade` | Home Manager user service installs the CLI if missing |
| codegraph (npm global in the agent runtime prefix) | npm | same service installs if missing |
| `gentle-shell` launcher (supplies `gentle-pi`) | npm, in the agent runtime prefix | Home Manager user service installs it if missing |
| gentle-engram, pi-web-access, pi-btw | pi | first interactive `gentle-ai` setup for Pi |
| optional NaN media MCP tools (`@gtrabanco/pi-nan-provider`) | pi | declared in Pi settings; not provisioned by the login service |

Two runtime files look versioned but are not, and drift is expected:
`~/.gentle-shell/agent/settings.json` (Pi and its package manager rewrite it
with atomic renames and reject symlinks) and
`~/.gentle-shell/agent/subagents.json` (gentle-ai owns the subagent model
profiles). The repo copy of `settings.json` is the seed for a fresh machine,
not a live mirror. `mcp.json` and `gentle-ai/persona.json` are seeded the same
way: gentle-ai's setup and sync refuse to read a symlink they are about to
inject into, so Nix writes them once and the agent owns them from then on.

After the first login, run `gentle-ai` and select Pi to configure the ecosystem.
The service does not run the TUI or select components for you. Check automatic
installation failures with `systemctl --user status provision-agent-tools` and
`journalctl --user -u provision-agent-tools`. Missing tools are retried after
five minutes; existing mutable installations are never downgraded or replaced.

Nix declares this service but does not own the destination directories: Pi and
npm manage their own package lifecycles. The `/usr/bin/tar` bridge supports
Gentle Shell's postinstall on NixOS.

## Entrypoint: the `gentle-shell` launcher

`gentle-shell` opens the flake's `pi` with the Gentle Shell package loaded and
never edits the pi it finds. It is provisioned into the agent runtime prefix and
runs with its isolated home (`~/.gentle-shell/config.json`, `"home":
"isolated"`), so every piece of agent state lives under `~/.gentle-shell`:
`~/.gentle-shell/agent` for Pi (auth, sessions, models, packages) and
`~/.gentle-shell/gentle-ai` for the CLI (profile, models, backups). `~/.pi` is
neither written nor read.

Home Manager exports `GENTLE_AI_HOME` and `PI_CODING_AGENT_DIR` with those same
two paths. Without them a bare `pi` — or a `gentle-ai sync` run outside the
launcher — resolves `~/.pi/agent` and `~/.pi/gentle-ai` again and silently
re-creates the old split home.

Why isolated rather than `gentle-shell home link`: the linked mode wrote Pi's
state into `~/.pi/agent` and the CLI's into `~/.pi/gentle-ai`, so the harness
kept re-creating a tree this setup wants gone and every Nix-declared file had to
be mirrored under it. With the isolated home there is one tree and one owner,
and the launcher needs no `home link` step. Bare `pi` is still not the
entrypoint: it starts without the harness.

Consequences of this mode:

- `~/.gentle-shell/agent` holds Pi's `settings.json`, `auth.json`,
  `subagents.json` and the npm package prefix; `~/.gentle-shell/gentle-ai` holds
  `profiles.json`, `models.json`, `vim.json` and `background-subagents.json`.
- `profiles.json` stays an out-of-store symlink into `configs/pi/gentle-ai/`, so
  the `/gentle:profiles` panel's active-profile rewrite lands in the repo.
- `settings.json`, `mcp.json` and `gentle-ai/persona.json` are seeded regular
  files (`seedAgentSettings` in `modules/home/development.nix`). gentle-ai's
  setup and sync refuse to read a symlink they are about to inject into, which
  broke `gentle-shell setup` and `gentle-ai sync` while they were symlinks.
- `gentle-pi` is supplied by the launcher, not by Pi's package list: it is absent
  from `settings.json` and `pi update --extensions` never manages it.
- npm's lifecycle-script gate stays closed for `gentle-pi`. On Linux its
  postinstall installs no artifact at package level, so the launcher needs
  neither `go` nor `/usr/bin/tar`.
- `gentle-ai` itself stays the mutable binary in `~/.local/bin`, updated with
  `gentle-ai upgrade`.
- `~/.pi` and `~/.gentle-ai` belonged to the linked mode and are removed. If
  either reappears, the process that wrote it was missing the two exported
  variables: `home.sessionVariables` reaches a shell only at login, so a shell
  (or the agent it launches) that predates the switch still resolves the old
  paths and re-creates `~/.pi/gentle-ai/agent-status`, `~/.pi/agent/pi-pretty`
  and `~/.gentle-ai/telemetry.json`. Log out and back in once, then delete
  them; the launcher on its own writes only inside `~/.gentle-shell`.

The `/usr/bin/tar` bridge in `modules/nixos/core.nix` no longer has a known
consumer in this mode. It stays until the interactive `gentle-ai` setup and
`gentle-ai upgrade` are verified without it; remove it in its own change.

### Removed: the Codex CLI

`pkgs.codex` is no longer installed and `~/.codex/skills` no longer feeds the
skill registry. `~/.codex` itself is left on disk untouched: it holds
`auth.json`, and the `openai` profile in `configs/pi/gentle-ai/profiles.json`
references `openai-codex/*` model ids that may read it. Delete the directory
only after that profile moves to another provider; until then it is state, not
configuration.

## Manual steps (never automated, never versioned)

These hold secrets or personal data. After a fresh install:

1. Open `gentle-shell` and log in to each provider — creates
   `~/.gentle-shell/agent/auth.json`.
2. Use `/login nan` in Pi, or export `NAN_API_KEY` if preferred.
3. Run `gentle-ai` once to select Pi and configure its ecosystem; later run
   `gentle-ai sync` after upstream updates. Gentle Shell already supports NaN
   chat, `/login nan` and `/gentle:usage` without the separate media add-on.

Everything else on a fresh machine: clone the repo, `sudo nixos-rebuild
switch --flake .#workstation` (or the guarded `just install-workstation`
from an ISO), then log in. Home Manager provisions the missing CLI and tools;
run the interactive `gentle-ai` setup when ready.
