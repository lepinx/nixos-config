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
| pi and codex binaries | `modules/home/development.nix` |

Rule of thumb: `readlink -f <path>` ending inside this repository is mutable
and hot-reloads; ending in `/nix/store` is declared and needs `just switch`.

## Mutable (provisioned on first login)

| Piece | Owner | Reconstructed by |
| --- | --- | --- |
| gentle-ai CLI | upstream installer, then `gentle-ai upgrade` | Home Manager user service installs the CLI if missing |
| codegraph (npm global in the agent runtime prefix) | npm | same service installs if missing |
| gentle-pi, gentle-engram, pi-web-access, pi-btw | pi | first interactive `gentle-ai` setup for Pi |
| optional NaN media MCP tools (`@gtrabanco/pi-nan-provider`) | pi | declared in Pi settings; not provisioned by the login service |

After the first login, run `gentle-ai` and select Pi to configure the ecosystem.
The service does not run the TUI or select components for you. Check automatic
installation failures with `systemctl --user status provision-agent-tools` and
`journalctl --user -u provision-agent-tools`. Missing tools are retried after
five minutes; existing mutable installations are never downgraded or replaced.

Nix declares this service but does not own the destination directories: Pi and
npm manage their own package lifecycles. The `/usr/bin/tar` bridge supports
Gentle Shell's postinstall on NixOS.

## Alternative: standalone `gentle-shell` launcher

Upstream also ships a launcher that runs Pi with the Gentle Shell package
from its own home (`~/.gentle-shell/agent`) or, with `--link`, reusing this
machine's `~/.pi/agent` (sign-ins, models, chats). Installed with
`npm i -g gentle-pi`; it never modifies the pi install it finds.

Trade-off for this setup: the in-agent install (current) keeps one pi home
and one lifecycle; the standalone launcher isolates Gentle Shell from
`~/.pi/agent` at the cost of a second home and an npm-global launcher that
`pi update --extensions` does not manage. Neither mode avoids the
postinstall `/usr/bin/tar` requirement on NixOS. Current choice:
in-agent via the interactive `gentle-ai` setup; revisit only if isolation
from `~/.pi/agent` becomes desirable.

## Manual steps (never automated, never versioned)

These hold secrets or personal data. After a fresh install:

1. Open pi and log in to each provider — creates `~/.pi/agent/auth.json`.
2. Use `/login nan` in Pi, or export `NAN_API_KEY` if preferred.
3. Run `gentle-ai` once to select Pi and configure its ecosystem; later run
   `gentle-ai sync` after upstream updates. Gentle Shell already supports NaN
   chat, `/login nan` and `/gentle:usage` without the separate media add-on.

Everything else on a fresh machine: clone the repo, `sudo nixos-rebuild
switch --flake .#workstation` (or the guarded `just install-workstation`
from an ISO), then log in. Home Manager provisions the missing CLI and tools;
run the interactive `gentle-ai` setup when ready.
