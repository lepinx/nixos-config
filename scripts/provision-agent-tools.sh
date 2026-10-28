#!/usr/bin/env bash
# Reconcile only missing mutable tools. The user owns upgrades and the first
# interactive `gentle-ai` setup; never run the TUI or downgrade existing tools.
set -euo pipefail

# The installer comes from main at runtime (first install always gets the
# newest gentle-ai); the downloaded release remains
# mutable and future `gentle-ai upgrade` calls stay owned by the user.
# Always the latest installer from main: the script itself resolves the
# latest release binary via GitHub releases/latest, so nothing is pinned on
# the Nix side and first installs always get the newest gentle-ai.
if [ ! -x "$HOME/.local/bin/gentle-ai" ]; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL -o "$installer" \
    https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh
  bash "$installer" --method binary --dir "$HOME/.local/bin"
  [ -x "$HOME/.local/bin/gentle-ai" ] || { echo 'gentle-ai installation failed' >&2; exit 1; }
fi

npm_prefix="$HOME/.local/share/agent-runtime/npm"
if [ ! -x "$npm_prefix/bin/codegraph" ]; then
  npm install -g --prefix "$npm_prefix" @colbymchenry/codegraph
  [ -x "$npm_prefix/bin/codegraph" ] || { echo 'codegraph installation failed' >&2; exit 1; }
fi
