# Feature: install-secrets-clarity

Goal: make the workstation installer explicit about every secret it asks for,
so a fresh install never leaves ambiguity about which passphrase was entered
for what.

## Tasks

- [x] Add a startup "secrets plan" section to scripts/install-workstation.sh
      listing Secret 1/3 (LUKS passphrase, prompted by Disko), Secret 2/3
      (optional TPM2+PIN), and Secret 3/3 (user password via passwd), with
      storage recommendations and the note that the script cannot verify
      the LUKS passphrase and user password differ.
- [x] Print a prominent notice immediately before Disko runs, labeling the
      upcoming interactive prompt as the LUKS passphrase (Secret 1/3) and
      reminding that it is never captured or stored by the script.
- [x] Rewrite the TPM enrollment prompt to explain what TPM2 + PIN does,
      what declining implies (typing the full passphrase every boot), and
      that the PIN is chosen during systemd-cryptenroll.
- [x] Label the passwd step as Secret 3/3 and recommend choosing a password
      different from the LUKS passphrase.
- [x] Update INSTALL.md and docs/luks.md to describe the secrets plan.
- [x] Verify: bash -n, shellcheck; commit as a work unit on a feature branch.

## Evidence

- Branch: feat/install-secrets-clarity
- Commit: 0730d8c feat(install): announce and label install-time secrets
