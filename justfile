set shell := ["bash", "-euo", "pipefail", "-c"]

host := env("NIXOS_HOST", `hostname -s`)
repo_root := justfile_directory()

default:
    @just --list

check:
    nix flake check

build:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel --no-link

switch:
    sudo nixos-rebuild switch --flake .#{{ host }}

boot:
    sudo nixos-rebuild boot --flake .#{{ host }}

test:
    sudo nixos-rebuild test --flake .#{{ host }}

update:
    nix flake update

# Update the lock and switch in one step; recover with `just rollback`.
up: update switch

update-input input:
    nix flake update {{ input }}

rollback:
    sudo nixos-rebuild switch --rollback

history:
    nix profile history --profile /nix/var/nix/profiles/system

health:
    #!/usr/bin/env bash
    set -uo pipefail
    systemctl --failed --no-pager
    systemctl --user --failed --no-pager

    echo
    echo "Mutable agent components (missing entries are provisioned on login):"
    check() {
        if command -v "$1" >/dev/null 2>&1; then
            printf '  ok       %s\n' "$1"
        else
            printf '  MISSING  %s  (install: %s)\n' "$1" "$2"
        fi
    }
    check pi 'provided by the flake; run just switch'
    check codex 'provided by the flake; run just switch'
    check codegraph 'check: systemctl --user status provision-agent-tools'
    check gentle-ai 'check: systemctl --user status provision-agent-tools'
    check engram 'run the first interactive gentle-ai setup for Pi'
    if [ -d "$HOME/.pi/agent/npm/node_modules/gentle-pi" ]; then
        echo '  ok       gentle-pi (Pi extension)'
    else
        echo '  MISSING  gentle-pi (Pi extension)  (run the first interactive gentle-ai setup for Pi)'
    fi

hotkeys:
    umbriel msg cheatsheet-open

warnings lines="120":
    journalctl -p warning..alert -b --no-pager -n {{ lines }}
    journalctl --user -p warning..alert -b --no-pager -n {{ lines }}

greeter-logs lines="160":
    journalctl -b -u greetd --no-pager -n {{ lines }}
    journalctl -b -t greetd --no-pager -n {{ lines }}

session-logs lines="200":
    journalctl --user -b --no-pager -n {{ lines }}

capture-logs lines="240":
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "$HOME/.local/state/nixos-config/logs"
    report="$HOME/.local/state/nixos-config/logs/diagnostics-$(date +%Y%m%d-%H%M%S).log"

    {
      echo "# diagnostics $(date --iso-8601=seconds)"
      echo
      echo "## failed system units"
      systemctl --failed --no-pager || true
      echo
      echo "## failed user units"
      systemctl --user --failed --no-pager || true
      echo
      echo "## system warnings/errors from current boot"
      journalctl -p warning..alert -b --no-pager -n {{ lines }} || true
      echo
      echo "## user warnings/errors from current boot"
      journalctl --user -p warning..alert -b --no-pager -n {{ lines }} || true
      echo
      echo "## greetd logs from current boot"
      journalctl -b -u greetd --no-pager -n {{ lines }} || true
      echo
      echo "## recent user session logs"
      journalctl --user -b --no-pager -n {{ lines }} || true
    } | tee "$report"

    echo "Wrote $report"

gc:
    sudo nix store gc

prune-generations keep="5":
    [[ "{{ keep }}" =~ ^[0-9]+$ ]]
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +{{ keep }}
    sudo nix store gc

# Run the guarded fresh-install flow (destructive; from a NixOS ISO)
install-workstation:
    sudo bash scripts/install-workstation.sh
