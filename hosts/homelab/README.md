# Host homelab

Servidor principal: VM NixOS sobre Proxmox (Aoostar WTR Pro, hipervisor en
`192.168.1.10`). Reemplaza al host bare metal que estaba definido para la torre
Ubuntu (ese pasó a rol de backups + laboratorio).

Criterios distintos a una workstation:

- sin stack de escritorio (Noctalia/Umbriel), perfil `server`;
- servicios declarativos;
- el disco del sistema es un virtio de 64G en el SSD del hipervisor
  (`local-lvm`); los datos pesados viven en el pool ZFS `tank` del host
  (mirror de 2 discos) y se comparten a la VM por un camino aparte;
- sin LUKS ni TPM2: eso era del diseño bare metal; en la VM el disco es
  efímero/rebuildable y la política de cifrado se discute a nivel hipervisor.

## Estado actual

El host está definido y expuesto como `nixosConfigurations.homelab`, con
`enableHomeManager = false`. Incluye:

- `hosts/homelab/disko.nix`: ESP 1G + raíz ext4 sobre `/dev/vda` (virtio);
- `hosts/homelab/hardware-configuration.nix`: perfil `qemu-guest` (módulos
  virtio, guest agent);
- `hosts/homelab/default.nix`: boot EFI (systemd-boot), IP estática
  `192.168.1.11`, SSH LAN-only con contraseña (decisión explícita del
  usuario), firewall con 22/80/443 TCP + 51820/UDP;
- secretos con `sops-nix` sobre `sops/homelab.yaml` (age contra la host key
  ed25519): password de restic, credenciales de Telegram/Hermes y la API key
  de NaN;
- `/mnt/tank/{familia,immich}` montados por NFS 4.2 desde el hipervisor, más
  dos jobs restic (`homelab` y `nas`) hacia la torre vieja por
  `sftp:tower:/srv/data/restic/homelab`;
- Samba con un share por integrante sobre `/mnt/tank/familia`, Immich sobre
  `/mnt/tank/immich` y Hermes Agent nativo.

Estado de instalación: **instalada en la VM (id 100): disko + nixos-install desde el flake aplicados, boot desde disco OK, ssh lucho@192.168.1.11 operativo (ver `odd/tasks/homelab-proxmox.md`, T6).**

## Exposición de red

Hay IP pública real y el router reenvía 80/443 TCP hacia esta VM: ese es el
puerto de entrada del edge. El reenvío **no publica nada por sí mismo** —
Pangolin rutea por recurso, con recursos públicos y recursos privados que
exigen autenticación, y 51820/UDP queda para WireGuard personal. Lo que no
pasa por Pangolin (22/445/9119) nunca se reenvía y sigue siendo LAN/VPN-only.

SSH con contraseña es una decisión explícita del usuario: solo LAN/VPN, nunca
expuesto. Si cambia el modelo de exposición, reevaluar claves SSH.

## Instalación (bootstrap de la VM)

1. VM 100 en Proxmox con la ISO minimal de NixOS (serie 26.11), boot UEFI.
2. Particionar y montar el disco con disko (reformatea solo el virtio):

   ```bash
   sudo nix run github:nix-community/disko -- --mode destroy,format,mount \
     --flake .#homelab
   ```

3. Instalar el sistema:

   ```bash
   sudo nixos-install --flake .#homelab --no-root-passwd
   ```

   El flake se puede clonar o copiar a la VM desde un `git` remoto o con
   `scp`/`rsync` desde la workstation.

## Post-instalación

1. Definir la contraseña del usuario: `passwd lucho`.
2. Verificar conectividad y que el gateway `192.168.1.1` responda.
3. Desde la workstation: `ssh lucho@192.168.1.11`.

## Pendientes

- AdGuard Home desplegado y el DHCP del router apuntando a `192.168.1.11`
  como DNS (hoy la LAN no tiene resolver propio: el contenedor de la torre
  está apagado).
- Pangolin (80/443, edge público), CrowdSec (LAPI + bouncers).
- Jellyfin con datos en `/mnt/tank/familia`.
- Verificar el primer backup restic real contra la torre
  (`sftp:tower:/srv/data/restic/homelab`): el cliente está declarado, el
  repositorio del otro lado todavía no se comprobó.
- Cuotas ZFS por dataset: follow-up en runtime.
