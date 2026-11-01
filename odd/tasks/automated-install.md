# Automated workstation install

## Goal

Provide a safer one-command installer for a fresh NixOS ISO workflow that automates disk selection, Disko formatting, NixOS installation, optional TPM2+PIN enrollment, user password setup, and documentation updates.

## Constraints

- The installer must not destructively format a disk without an explicit typed confirmation.
- Secrets must never be stored in the repository.
- The fresh-install path uses `nixos-install --flake .#workstation`; post-install rebuilds keep using `just switch`.
- Keep implementation and docs in English repository artifacts unless extending existing Spanish docs. Existing install docs are Spanish, so update them consistently in Spanish.
- Do not commit automatically in this session unless the user explicitly asks for commits.

## Tasks

- [x] Add a guarded `scripts/install-workstation.sh` installer for NixOS ISO usage.
- [x] Add a `just install-workstation` convenience recipe.
- [x] Update install/encryption documentation to describe the automated flow and safety model.
- [x] Run focused syntax/format checks and report any skipped runtime checks.

## Evidence

- `scripts/install-workstation.sh` (309 lines, executable): root/Linux/tool/network preflight, NIX_CONFIG flakes export, repo-root detection, `--disk/--host/--help` parsing with explicit `--yes` rejection, disk auto-detection, mismatch abort prompt against the flake-declared `/dev/nvme0n1`, typed destructive confirmation with fresh mount re-check, Disko destroy/format/mount (LUKS passphrase handled interactively by Disko, never captured), `nixos-install`, `passwd lucho` via `nixos-enter`, optional TPM2+PIN enrollment, optional reboot, closing summary.
- `justfile`: new `install-workstation` recipe invoking the script with sudo.
- `INSTALL.md`: new Spanish "Instalación automática" section before the manual flow; manual flow kept as fallback.
- `docs/luks.md`: Spanish note that the installer can enroll TPM2+PIN at install time; manual command kept as fallback.
- Verification (gentle-ai-verify, 7/7 applicable PASS): `git status/diff` as expected; `bash -n` clean; `shellcheck` clean (0 findings); `just --list` shows `install-workstation`; script safety gates confirmed by inspection; docs confirmed. Skipped: `nix flake check` (needs network/builds; repo provides `just check`), and runtime execution of the installer (destructive by design).
- Known limitation resolved: the flake now exposes `diskoConfigurations.workstation` and the script passes `--argstr diskDevice <selected>` to Disko, so a different detected disk is handled automatically without editing `flake.nix`. The installed system mounts by partlabel (device-independent), verified against disko source (gpt.nix, luks.nix) and `nix eval` of both paths.
- Committed on branch `feat/automated-install` as `b6e97d9` (feat(install): add guarded one-command workstation installer). `modules/nixos/desktop.nix` had an unrelated local change (niri systemd-260 patch) and was deliberately left out of the commit.
