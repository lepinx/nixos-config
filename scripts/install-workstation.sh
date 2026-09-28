#!/usr/bin/env bash
#
# Guarded one-command fresh install for the `workstation` NixOS flake.
#
# Run this from a NixOS ISO, as root, from anywhere inside the cloned repo.
# It wipes the target disk, so every destructive step is gated behind a typed
# confirmation of the exact device path. Nothing here touches the repository.
#
# Disko note: the target disk is always passed explicitly to Disko via
# `--argstr diskDevice`, so auto-detection decides which disk is wiped. The
# flake's `diskDevice` is only a default; the installed system mounts by
# partlabel and stays device-independent.
#
# LUKS note: this script never reads, captures, or stores the LUKS passphrase.
# Disko prompts for it interactively during the `destroy,format,mount` run.
#
set -euo pipefail

readonly DECLARED_DISK="/dev/nvme0n1"
readonly TARGET_USER="lucho"
readonly MIN_DISK_BYTES=$((100 * 1024 * 1024 * 1024)) # 100 GiB

# Set by parse_args().
explicit_disk=""
host="workstation"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

info() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: install-workstation.sh [--disk DEV] [--host HOST]

Guarded fresh-install flow for the workstation NixOS flake. Must be run as
root from a NixOS ISO. Wipes the selected disk with Disko, installs NixOS,
sets the user password, and can optionally enroll TPM2 + PIN.

Options:
  --disk DEV   Target block device (for example /dev/nvme0n1).
               If omitted, a single eligible disk is auto-detected.
  --host HOST  NixOS host to install (default: workstation).
  -h, --help   Show this help and exit.

The selected disk is passed to Disko explicitly (--argstr diskDevice), so the
flake does not need to be edited to install on different hardware. The
installed system mounts by partlabel and is device-independent.

There is intentionally no --yes flag: the destructive step always requires
typing the exact device path.
EOF
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --disk)
        [[ $# -ge 2 ]] || die "--disk requires an argument"
        explicit_disk="$2"
        shift 2
        ;;
      --host)
        [[ $# -ge 2 ]] || die "--host requires an argument"
        host="$2"
        shift 2
        ;;
      --yes|-y)
        die "'--yes' is not supported: destructive actions require typing the exact device path."
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1 (see --help)"
        ;;
    esac
  done
}

preflight() {
  [[ "$(uname -s)" == "Linux" ]] || die "This installer only runs on Linux."
  [[ "$(id -u)" -eq 0 ]] || die "This installer must run as root (try: sudo $0)"

  local -a missing=()
  local tool
  for tool in lsblk nix git; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    die "Missing required tools: ${missing[*]}. On the ISO try: nix-shell -p git curl"
  fi

  # Enable flakes for this session so `nix run` and `nixos-install --flake` work.
  export NIX_CONFIG="experimental-features = nix-command flakes"

  check_network
}

check_network() {
  if ! command -v curl >/dev/null 2>&1; then
    die "curl is required for the network check but was not found. On the ISO try: nix-shell -p curl"
  fi
  info "Checking network connectivity..."
  if ! curl -fsS --head --max-time 15 https://nixos.org >/dev/null 2>&1; then
    die "Network check failed: could not reach https://nixos.org. Connect the network and retry."
  fi
}

detect_repo_root() {
  local script_dir root
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  if root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" && [[ -n "$root" ]]; then
    printf '%s\n' "$root"
  else
    printf '%s\n' "$script_dir"
  fi
}

# True when the disk or any of its partitions currently has a mountpoint.
is_disk_mounted() {
  local disk="$1"
  lsblk -n -r -o MOUNTPOINTS "$disk" | grep -q '[^[:space:]]'
}

# Print auto-detected candidate disks: non-removable, non-partitioned block
# devices >= 100 GiB, without zram/loop devices, and without mounted partitions.
detect_disks() {
  local -a result=()
  local name type rm size
  while read -r name type rm size; do
    [[ "$type" == "disk" ]] || continue
    [[ "$rm" == "0" ]] || continue
    if [[ "$name" == *zram* || "$name" == *loop* ]]; then
      continue
    fi
    (( size >= MIN_DISK_BYTES )) || continue
    if is_disk_mounted "$name"; then
      continue
    fi
    result+=("$name")
  done < <(lsblk -b -d -n -p -o NAME,TYPE,RM,SIZE)

  if (( ${#result[@]} > 0 )); then
    printf '%s\n' "${result[@]}"
  fi
}

select_disk() {
  local disk

  if [[ -n "$explicit_disk" ]]; then
    [[ -b "$explicit_disk" ]] || die "Not a block device: $explicit_disk"
    disk="$explicit_disk"
    info "Using disk from --disk: $disk" >&2
    printf '%s\n' "$disk"
    return 0
  fi

  local -a candidates=()
  mapfile -t candidates < <(detect_disks)

  if (( ${#candidates[@]} == 0 )); then
    die "No eligible disk found (>= 100 GiB, non-removable, not mounted). Re-run with --disk /dev/X."
  fi
  if (( ${#candidates[@]} > 1 )); then
    warn "Multiple candidate disks found:"
    lsblk -d -o NAME,MODEL,SERIAL,SIZE,TYPE,RM "${candidates[@]}" >&2
    die "Specify the target explicitly with --disk /dev/X."
  fi

  disk="${candidates[0]}"
  info "Auto-detected disk: $disk" >&2
  printf '%s\n' "$disk"
}

show_disk_info() {
  local disk="$1"
  echo
  info "Target disk details:"
  lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,RM,MOUNTPOINTS "$disk"
  echo
}

# The flake declares a default diskDevice; Disko receives the selected disk
# explicitly (see run_disko), so a different physical disk is supported without
# editing the flake. Print an informational note when they differ.
note_disk_matches_flake() {
  local disk="$1"

  [[ "$disk" == "$DECLARED_DISK" ]] && return 0
  warn "flake.nix declares diskDevice = \"$DECLARED_DISK\"; you selected $disk."
  warn "Disko will be pointed at $disk explicitly (--argstr diskDevice), so this is safe."
  warn "The installed system mounts by partlabel and works on either disk."
}

# Typed destructive confirmation plus a fresh mount re-check.
confirm_destroy() {
  local disk="$1" typed

  warn "ALL DATA ON $disk WILL BE DESTROYED. This cannot be undone."
  read -r -p "Type the exact device path to continue (for example $disk): " typed

  if [[ "$typed" != "$disk" ]]; then
    die "Input did not match '$disk'. Aborting without changes."
  fi

  if is_disk_mounted "$disk"; then
    die "Device $disk now has mounted partitions. Unmount them and retry."
  fi
}

run_disko() {
  local disk="$1"
  info "Running Disko (destroy,format,mount) on $disk. Disko will prompt for the LUKS passphrase."
  # The explicit --argstr overrides make Disko act on the selected disk, not on
  # the flake's default diskDevice. disko.nix requires both arguments.
  (
    cd "$repo_root" && nix run github:nix-community/disko -- \
      --mode destroy,format,mount \
      --flake ".#$host" \
      --argstr diskDevice "$disk" \
      --argstr hostName "$host"
  )
}

install_nixos() {
  info "Installing NixOS: nixos-install --flake .#$host"
  ( cd "$repo_root" && nixos-install --flake ".#$host" )
}

set_user_password() {
  info "Setting the password for user '$TARGET_USER' (interactive)."
  nixos-enter --root /mnt -c "passwd $TARGET_USER"
}

# Locate the LUKS partition on the target disk; fall back to /dev/<disk>p2.
find_luks_partition() {
  local disk="$1" part
  part="$(lsblk -n -r -p -o NAME,FSTYPE "$disk" | awk '$2 == "crypto_LUKS" { print $1; exit }')"
  if [[ -n "$part" ]]; then
    printf '%s\n' "$part"
  else
    printf '%sp2\n' "$disk"
  fi
}

maybe_enroll_tpm() {
  local disk="$1" answer luks_part
  read -r -p "Enroll TPM2 + PIN now? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Skipping TPM2 + PIN. You can enroll it later; see docs/luks.md."
    tpm_enrolled="no"
    return 0
  fi

  luks_part="$(find_luks_partition "$disk")"
  info "Enrolling TPM2 + PIN on $luks_part (interactive)."
  systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-with-pin=yes "$luks_part"
  info "TPM2 + PIN enrolled. Details and recovery notes: docs/luks.md."
  tpm_enrolled="yes"
}

maybe_reboot() {
  local answer
  read -r -p "Reboot now? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Rebooting..."
    reboot
  else
    info "Next steps: reboot, unlock LUKS with your passphrase, log in, then run 'just switch'."
  fi
}

main() {
  parse_args "$@"
  preflight

  repo_root="$(detect_repo_root)"
  info "Repository root: $repo_root"
  info "Target host: $host"

  local disk
  disk="$(select_disk)"
  show_disk_info "$disk"
  note_disk_matches_flake "$disk"
  confirm_destroy "$disk"

  tpm_enrolled="no"
  run_disko "$disk"
  install_nixos
  set_user_password
  maybe_enroll_tpm "$disk"
  maybe_reboot

  echo
  info "Summary:"
  info "  - Target disk: $disk"
  info "  - Host: $host"
  info "  - Disko formatted and mounted the disk (LUKS passphrase entered by you)."
  info "  - nixos-install completed."
  info "  - Password set for user '$TARGET_USER'."
  if [[ "$tpm_enrolled" == "yes" ]]; then
    info "  - TPM2 + PIN enrolled."
  else
    info "  - TPM2 + PIN not enrolled (run it later per docs/luks.md)."
  fi
}

main "$@"
