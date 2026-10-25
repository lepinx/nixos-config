#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d "$repo/.provision-test.XXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/home"
export HOME="$scratch/home" CALLS="$scratch/calls"
: > "$CALLS"

cat > "$scratch/installer" <<'MOCK'
#!/usr/bin/env bash
printf 'installer %s\n' "$*" >> "$CALLS"
mkdir -p "$HOME/.local/bin"
touch "$HOME/.local/bin/gentle-ai"
chmod +x "$HOME/.local/bin/gentle-ai"
MOCK
cat > "$scratch/bin/npm" <<'MOCK'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$CALLS"
mkdir -p "$HOME/.local/share/agent-runtime/npm/bin"
touch "$HOME/.local/share/agent-runtime/npm/bin/codegraph"
chmod +x "$HOME/.local/share/agent-runtime/npm/bin/codegraph"
MOCK
cat > "$scratch/bin/pi" <<'MOCK'
#!/usr/bin/env bash
printf 'pi %s\n' "$*" >> "$CALLS"
MOCK
chmod +x "$scratch/bin/"*
cp "$scratch/installer" "$scratch/installer-good"
cp "$scratch/bin/npm" "$scratch/npm-good"
export PATH="$scratch/bin:$PATH"

bash "$repo/scripts/provision-agent-tools.sh" "$scratch/installer"
grep -qx "installer --method binary --dir $HOME/.local/bin" "$CALLS"
grep -qx "npm install -g --prefix $HOME/.local/share/agent-runtime/npm @colbymchenry/codegraph" "$CALLS"
[ "$(wc -l < "$CALLS")" -eq 2 ]

: > "$CALLS"
bash "$repo/scripts/provision-agent-tools.sh" "$scratch/installer"
[ ! -s "$CALLS" ] || { printf 'Provisioner changed existing mutable tools\n' >&2; exit 1; }

# A failed installer must not continue to npm or Pi or create a partial CLI.
export HOME="$scratch/offline"
mkdir -p "$HOME"
cat > "$scratch/installer" <<'MOCK'
#!/usr/bin/env bash
printf 'installer\n' >> "$CALLS"
exit 7
MOCK
: > "$CALLS"
if bash "$repo/scripts/provision-agent-tools.sh" "$scratch/installer" > "$scratch/out" 2> "$scratch/err"; then
  printf 'Provisioner accepted a failed installer\n' >&2
  exit 1
else
  status=$?
fi
[ "$status" -eq 7 ] && [ ! -s "$scratch/out" ] && [ ! -s "$scratch/err" ]
[ "$(< "$CALLS")" = installer ]
[ ! -e "$HOME/.local/bin/gentle-ai" ]

# npm failure preserves the installed CLI and retries only CodeGraph.
export HOME="$scratch/npm-failure"
mkdir -p "$HOME"
cp "$scratch/installer-good" "$scratch/installer"
cat > "$scratch/bin/npm" <<'MOCK'
#!/usr/bin/env bash
printf 'npm\n' >> "$CALLS"
exit 9
MOCK
: > "$CALLS"
if bash "$repo/scripts/provision-agent-tools.sh" "$scratch/installer" > "$scratch/out" 2> "$scratch/err"; then
  exit 1
else
  status=$?
fi
[ "$status" -eq 9 ] && [ "$(wc -l < "$CALLS")" -eq 2 ]
[ -x "$HOME/.local/bin/gentle-ai" ] && [ ! -e "$HOME/.local/share/agent-runtime/npm/bin/codegraph" ]
cp "$scratch/npm-good" "$scratch/bin/npm"
: > "$CALLS"
bash "$repo/scripts/provision-agent-tools.sh" "$scratch/installer"
[ "$(wc -l < "$CALLS")" -eq 1 ]
if grep -q '^installer ' "$CALLS"; then
  printf 'Retry reinstalled the existing CLI\n' >&2
  exit 1
fi

if grep -q '^pi' "$CALLS"; then
  printf 'Provisioner installed a Pi package outside interactive setup\n' >&2
  exit 1
fi
printf 'Provisioning CLI and CodeGraph: OK\n'
