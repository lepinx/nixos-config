set shell := ["bash", "-euo", "pipefail", "-c"]

host := env("NIXOS_HOST", `hostname -s`)

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

update-input input:
    nix flake update {{ input }}

rollback:
    sudo nixos-rebuild switch --rollback

history:
    nix profile history --profile /nix/var/nix/profiles/system

health:
    systemctl --failed --no-pager
    systemctl --user --failed --no-pager

hotkeys:
    niri msg action show-hotkey-overlay

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
