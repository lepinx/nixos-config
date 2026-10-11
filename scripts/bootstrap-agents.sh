#!/usr/bin/env bash
#
# Bootstrap the mutable agent tooling that the declarative NixOS config
# intentionally does not own: pi extensions (pi is their package manager),
# the npm-global codegraph helper, and optionally the standalone gentle-ai
# binary.
#
# Idempotent: every step checks before acting, so this is safe to re-run
# after any `pi update --extensions` to re-sync, or on a fresh install.
#
# Prerequisites: the NixOS configuration already switched at least once
# (pi, node, npm and the /usr/bin/tar tmpfiles rule come from the flake).
# Secrets (auth.json, API keys) are never installed or stored here; the
# final summary lists what needs manual attention.

set -euo pipefail

readonly NPM_PREFIX="$HOME/.local/share/agent-runtime/npm"
readonly PI_EXTENSIONS=(
  "npm:gentle-pi"
  "npm:gentle-engram"
  "npm:pi-web-access"
  "npm:pi-btw"
  "npm:@gtrabanco/pi-nan-provider"
  "npm:pi-mcp-adapter"
)

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

info() { printf '%s\n' "$*"; }
ok() { printf '  ok       %s\n' "$1"; }
skip() { printf '  present  %s\n' "$1"; }
manual() { printf '  MANUAL   %s\n' "$1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- prerequisites ---------------------------------------------------------

info "Prerequisites:"
command_exists pi || die "pi not found. The NixOS config provides it: just switch, then retry."
command_exists npm || die "npm not found. The NixOS config provides nodejs: just switch, then retry."

if [ ! -e /usr/bin/tar ]; then
  die "/usr/bin/tar is missing. gentle-pi's postinstall needs it: run 'just switch' first (the tmpfiles rule creates it), then retry."
fi
ok "pi, npm and /usr/bin/tar are available"

# --- pi extensions ---------------------------------------------------------

info ""
info "Pi extensions (managed by pi, not Nix):"
for source in "${PI_EXTENSIONS[@]}"; do
  pkg="${source#npm:}"
  if [ -d "$HOME/.pi/agent/npm/node_modules/$pkg" ]; then
    skip "$pkg"
  else
    info "  installing $source ..."
    pi install "$source" --no-approve
  fi
done

# --- npm-global helpers ----------------------------------------------------

info ""
info "npm-global helpers (prefix: $NPM_PREFIX):"
if command_exists codegraph; then
  skip "codegraph"
else
  npm install -g --prefix "$NPM_PREFIX" @colbymchenry/codegraph
  ok "codegraph"
fi

# --- standalone gentle-ai (optional) ---------------------------------------

info ""
if [ -x "$HOME/.local/bin/gentle-ai" ]; then
  skip "gentle-ai standalone CLI ($("$HOME/.local/bin/gentle-ai" --version 2>/dev/null || echo installed))"
else
  printf 'Install the standalone gentle-ai CLI (gentle-shell installer)? pi does not need it; it is the interactive TUI. [y/N] '
  read -r answer
  if [ "${answer:-n}" = "y" ]; then
    curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
    ok "gentle-ai standalone"
  else
    skip "gentle-ai standalone (skipped; package-local binary inside gentle-pi is what pi uses)"
  fi
fi

# --- what still needs a human ----------------------------------------------

info ""
info "Remaining manual steps (intentionally never automated):"
manual "provider auth: open pi and log in to each provider (creates ~/.pi/agent/auth.json)"
manual "NaN API key: exported as NAN_API_KEY in your shell profile if you use the nan provider"
manual "gentle-ai state sync: run 'gentle-ai sync' if you use the standalone CLI"

info ""
info "Bootstrap complete. Re-run any time; present pieces are skipped."
