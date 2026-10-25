#!/usr/bin/env bash
# Reconcile only missing mutable tools. The user owns upgrades and the first
# interactive `gentle-ai` setup; never run the TUI or downgrade existing tools.
set -euo pipefail

# Nix fetches and hashes the installer source; the downloaded release remains
# mutable and future `gentle-ai upgrade` calls stay owned by the user.
installer="${1:?expected the Nix-verified Gentle AI installer path}"
if [ ! -x "$HOME/.local/bin/gentle-ai" ]; then
  bash "$installer" --method binary --dir "$HOME/.local/bin"
  [ -x "$HOME/.local/bin/gentle-ai" ] || { echo 'gentle-ai installation failed' >&2; exit 1; }
fi

npm_prefix="$HOME/.local/share/agent-runtime/npm"
if [ ! -x "$npm_prefix/bin/codegraph" ]; then
  npm install -g --prefix "$npm_prefix" @colbymchenry/codegraph
  [ -x "$npm_prefix/bin/codegraph" ] || { echo 'codegraph installation failed' >&2; exit 1; }
fi
