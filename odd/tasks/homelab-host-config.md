# Feature: homelab-host-config

Goal: full versioned NixOS definition for the homelab tower, ready to install
once the user finishes data staging to the HDD.

## Hardware facts (verified 2026-09-28)

- Tower replacing Ubuntu Server; BIOS switchable to UEFI (CSM off, reinstalling).
- SSD 223.6G Kingston SA400S3 -> OS disk (disko target 1).
- HDD 931.5G WD WD10EZEX (ROTA=1) -> data disk, currently being staged with
  Cloudreve data + docker volumes by the user (Btrfs, label homelab-data).
- TPM2 present (tpm0); UEFI target means real PCR sealing is viable.
- 2 cores / 7.6 GiB RAM; static IP 192.168.1.50/24 on eno1.
- Exposure: only 80/443 TCP + 51820/UDP; SSH LAN-only; fixed public IP + own
  domain; Pangolin phase 2; CrowdSec native.

## Tasks

- [x] flake.nix: expose nixosConfigurations.homelab (enableHomeManager false)
      and diskoConfigurations.homelab (two-disk args).
- [x] hosts/homelab/disko.nix: SSD = GPT ESP + LUKS cryptroot + Btrfs
      (subvols root/home/nix); HDD = LUKS cryptdata + Btrfs with per-user
      data subvolumes; partlabel-driven, device-independent like workstation.
- [x] hosts/homelab/hardware-configuration.nix: minimal (disko supplies
      mounts), server kernel modules.
- [x] hosts/homelab/default.nix: server profile, UEFI systemd-boot, dual LUKS
      with TPM2 auto-unlock (crypttabExtraOpts), static networking eno1
      192.168.1.50, hardened SSH (keys only, LAN-only), nftables firewall
      (80/443 TCP, 51820/UDP only), samba host-local module.
- [x] hosts/homelab/samba.nix: per-user shares over Btrfs subvolumes, no
      guest; document smbpasswd setup and quota (qgroups) follow-up.
- [x] Update hosts/homelab/README.md: install sequence, post-install steps
      (passwd, smbpasswd, TPM2 enrollment, data restore), pending items
      (SSH pubkey, extra users, crowdsec phase, pangolin phase 2).
- [x] Verify: nix flake check, eval of nixosConfigurations.homelab and
      diskoConfigurations.homelab with test args.
- [x] Commit as a work unit on a feature branch.

## Evidence

- Branch: feat/homelab-host-config
- Commit: fe020bf feat(homelab): define full server host configuration / 5384cee refactor(homelab): keep data HDD out of disko feat(homelab): define full server host configuration

## Deferred (explicit non-goals for this feature)

- CrowdSec native module (phase C, post-install).
- Pangolin stack (phase 2, Docker/Podman based).
- Btrfs qgroup quotas activation (runtime step, documented).
- Additional Samba users beyond lucho.
