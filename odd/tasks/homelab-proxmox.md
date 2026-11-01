# Homelab Proxmox — migración de la torre a infraestructura virtualizada

Proxmox en Aoostar WTR Pro (32+ GB RAM, 2 NICs, SSD 1TB + 2x HDD 4TB mirror,
zpool ya creado). VM NixOS como server principal, Pangolin para exposición
pública, CrowdSec como seguridad, nube familiar (fotos/videos/backups).
Torre Ubuntu vieja → backups + laboratorio. Referencias: hosts/homelab/,
hosts/homelab/README.md, memoria obs 249/250/257/291.

## Specs

- S1: "Proxmox instalado en el SSD de 1TB, zpool ya creado (tank/datos);
  reveer esa parte para hacer un dataset por consumidor, o mientras
  vayamos instalando cada cosa."
- S2: "VM de NixOS como server principal" en Proxmox; `nixosConfigurations.homelab`
  reescrito para el perfil VM (el actual está diseñado para bare metal:
  disko LUKS+TPM2, systemd-boot, SATA).
- S3: "usar pangolin para vpn interna y tambien para servicios web o cosas
  publicas de forma segura" — Pangolin en la VM NixOS (hay IP pública real);
  port-forward 80/443 del router ADSL; 51820/UDP queda para WireGuard personal.
- S4: "configurar crowdsec tambien como seguridad (capaz es mejor eso que
  fail2ban)" — CrowdSec decidido (LAPI en VM NixOS, bouncers nftables en
  NixOS + Proxmox).
- S5: Router virtualizado (OPNsense, el WTR Pro tiene 2 NICs) **deferido**:
  se decide más adelante, no bloquea el resto.
- S6: "tener backups.. mi nube completa propia": Immich (fotos familia),
  Jellyfin (videos), Samba; backups con restic hacia la torre vieja.
- S7: "migrar las cosas que tengo ahi (Ubuntu: AdGuard, Hermes gateway,
  Docker) al nuevo servidor y ese usarlo tal vez como backups.. y como otro
  juguete para experimentar".
- S8: Red: Proxmox en 192.168.1.10 (estático), DHCP del router .100-.254;
  definir plan de IPs para VMs y torre.
- S9: Auditoría de todo lo ya configurado en Proxmox (instalación + zpool)
  antes de avanzar.

## Tasks

- T1 (S9): auditoría del Proxmox: version, config de red, zpool status/layout,
  storage.cfg. [route: inline, user runs audit script] [commit: —]
  Estado: cerrada — ashift=12 correcto, autotrim off (HDD, correcto),
  autoexpand off. Faltaba timer de scrub ZFS (solo hay e2scrub/xfs_scrub):
  user debe habilitar zfs-scrub-monthly@tank.timer. Flag SMR documentado.
- T2 (S8): plan de IPs estático documentado (rango infra .2-.99, VMs, torre).
  [route: inline] [commit: docs]
  Estado: hecha — hosts/README.md con tabla LAN (sin commitear).
- T3 (S1): reestructurar el zpool: dataset por consumidor
  (tank/immich, tank/familia, tank/backups), migrar tank/datos. [inline/SSH]
  Estado: hecha — tank/datos (vacío) destruido; datasets creados. Timer
  zfs-scrub-monthly@tank habilitado por el usuario.
- T4 (S2): crear la VM NixOS en Proxmox (EFI/OVMF, 4-6 vCPU, 8-12 GB RAM,
  disco virtio 40-80 GB en el SSD). [route: user GUI/CLI + guía]
  Estado: en curso — instrucciones entregadas (qm create 100: cpu host, 4
  cores, 12 GB, virtio 64G discard, agent, ISO minimal 26.11). Pendiente:
  user crea la VM y baja la ISO.
- T5 (S2): reescribir hosts/homelab para perfil VM (sin disko LUKS/TPM2,
  boot EFI virtio, sin stack de escritorio) hasta que
  `nix build .#nixosConfigurations.homelab` compile. [route: inline ODD]
  Estado: hecha — default.nix/disko.nix/hardware-configuration.nix
  reescritos (ESP 1G + ext4 root en /dev/vda, ens18 con IP .11, firewall
  22/80/443 + 51820, perfil qemu-guest); samba.nix eliminada (T9 la
  recrea sobre el mount de tank); READMEs actualizados. Verificado con
  `nix eval` del toplevel (EVAL_OK). Bug latente corregido: el diseño
  anterior dejaba SSH inaccesible (openFirewall=false sin puerto 22 en
  la allowlist). Sin commitear.
- T6 (S2): bootstrap del sistema en la VM (nixos-install desde ISO con el
  flake). [route: user + guía]
- T7 (S3): Pangolin en la VM NixOS (nativo si está empaquetado en nixpkgs,
  si no podman), port-forward 80/443, dominio home.pinol.dev. [inline ODD]
- T8 (S4): CrowdSec + bouncer nftables en NixOS; bouncer en Proxmox. [inline]
- T9 (S6): montaje del pool en la VM (virtiofs o NFS) + datasets por servicio.
  [inline]
- T10 (S6): Immich (fotos familia) con datos en tank/immich. [inline]
- T11 (S6): Jellyfin con datos en tank/familia. [inline]
- T12 (S6): restic server en la torre + job de backup nocturno desde la VM.
  [inline + torre]
- T13 (S7): migración AdGuard + Hermes gateway desde la torre a la VM.
  [inline]
- T14 (S7): rol final de la torre: backups + laboratorio (decidir siempre
  encendida vs WOL nocturno). [decision + config]

## Log

- L1 (2026-10-31, request original): "Estoy por instalar en mi nueva homelab
  (aoostar wtr pro, tengo 1tb de ssd, donde tengo pensado instalar proxmox,
  en una vm un nixos como server principal, tambien usar pangolin para vpn
  interna y tambien para servicios web o cosas publicas de feorma segura)
  configurar crowdsec tambien como seguridad (capaz es mejor eso que
  fail2ban), otra vm para opensense como router.. tengo 2 bahias discos hdd
  redgate de 4tb cada una.. pensaba un raid1 para luego usar como un samba o
  nas como truenas..." (decisión NAS: ZFS en host Proxmox, sin TrueNAS; RAM
  32+; IP pública real confirmada).
- L2 (2026-10-31): "acabo de adelantarme ya se termino de instalar proxmox...
  cree un zpool y tambien un tank/datos.. quiero auditar todo lo que tengo
  hasta ahora". IP Proxmox: 192.168.1.10, DHCP .100-.254. Surge pedido de
  roadmap ODD y preguntas de arquitectura (VM vs contenedor, manejo de
  Proxmox por SSH, estrategia de backups en la torre).
