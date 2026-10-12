# Mutable vs declared state

The flake rebuilds the system and the home environment, but some pieces are
intentionally mutable: their lifecycle belongs to an upstream tool (pi, the
gentle-shell installer) or they are data, not configuration. This page maps
both layers and how to reconstruct a fresh machine completely.

## Declared (versioned, rebuilt by `just switch`)

| Piece | Where |
| --- | --- |
| System packages, desktop, umbriel, noctalia base | `modules/nixos/`, `flake.nix` |
| Home environment, fish, git, nvim, zed, yazi | `modules/home/` |
| Ghostty config (hot-reload symlink) | `configs/ghostty/config` |
| Noctalia UI overrides (hot-reload symlink) | `configs/noctalia/settings.toml` |
| Nvim and zed editor configs (hot-reload symlinks) | `configs/nvim/`, `configs/zed/` |
| `/usr/bin/tar` bridge for gentle-pi's postinstall | `modules/nixos/core.nix` (tmpfiles rule) |
| pi and codex binaries | `pkgsUnstable` (`modules/home/development.nix`) |

Rule of thumb: `readlink -f <path>` ending inside this repository is mutable
and hot-reloads; ending in `/nix/store` is declared and needs `just switch`.

## Mutable (reconstructed with `just bootstrap-agents`)

| Piece | Owner | Reconstructed by |
| --- | --- | --- |
| pi extensions (gentle-pi, gentle-engram, pi-web-access, pi-btw, nan provider, pi-mcp-adapter) | pi (`pi install`, `pi update --extensions`) | `just bootstrap-agents` |
| codegraph (npm global in the agent runtime prefix) | npm | `just bootstrap-agents` |
| standalone gentle-ai CLI (optional; pi uses the package-local binary) | gentle-shell installer | `just bootstrap-agents` (asks) |

Nix deliberately does not own these directories: pi manages its own
extension lifecycle, and a second package manager over the same tree is the
class of conflict the `/usr/bin/tar` bridge exists to avoid.

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
in-agent via `just bootstrap-agents`; revisit only if isolation from
`~/.pi/agent` becomes desirable.

## Manual steps (never automated, never versioned)

These hold secrets or personal data. After a fresh install:

1. Open pi and log in to each provider — creates `~/.pi/agent/auth.json`.
2. Export `NAN_API_KEY` in the shell profile if the nan provider is used.
3. Run `gentle-ai sync` if the standalone CLI is in use.

Everything else on a fresh machine: clone the repo, `sudo nixos-rebuild
switch --flake .#workstation` (or the guarded `just install-workstation`
from an ISO), then `just bootstrap-agents`.
