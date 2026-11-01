# Host homelab

Servidor principal: VM NixOS sobre Proxmox (Aoostar WTR Pro, hipervisor en
`192.168.1.10`). Reemplaza al host bare metal que estaba definido para la torre
Ubuntu (ese pas\u00f3 a rol de backups + laboratorio).

Criterios distintos a una workstation:

- sin stack de escritorio (Noctalia/Umbriel), perfil `server`;
- servicios declarativos;
- el disco del sistema es un virtio de 64G en el SSD del hipervisor
  (`local-lvm`); los datos pesados viven en el pool ZFS `tank` del host
  (mirror de 2 discos) y se comparten a la VM por un camino aparte;
- sin LUKS ni TPM2: eso era del dise\u00f1o bare metal; en la VM el disco es
  ef\u00edmero/rebuildable y la pol\u00edtica de cifrado se discute a nivel hipervisor.

## Estado actual

El host est\u00e1 definido y expuesto como `nixosConfigurations.homelab`, con
`enableHomeManager = false`. Incluye:

- `hosts/homelab/disko.nix`: ESP 1G + ra\u00edz ext4 sobre `/dev/vda` (virtio);
- `hosts/homelab/hardware-configuration.nix`: perfil `qemu-guest` (m\u00f3dulos
  virtio, guest agent);
- `hosts/homelab/default.nix`: boot EFI (systemd-boot), IP est\u00e1tica
  `192.168.1.11`, SSH LAN-only con contrase\u00f1a (decisi\u00f3n expl\u00edcita del
  usuario), firewall con 22/80/443 TCP + 51820/UDP.

Estado de instalaci\u00f3n: **definido; la VM existe en Proxmox (id 100), falta
bootstrap con el flake.**

## Exposici\u00f3n de red

El firewall abre expl\u00edcitamente 22/80/443 TCP y 51820/UDP. Todo queda
LAN/VPN-only: el router ADSL no reenv\u00eda ninguno de esos puertos desde la WAN
(hay IP p\u00fablica real; la exposici\u00f3n p\u00fabla se har\u00e1 \u00fanicamente a trav\u00e9s de
Pangolin, cuando se configure).

SSH con contrase\u00f1a es una decisi\u00f3n expl\u00edcita del usuario: solo LAN/VPN, nunca
expuesto. Si cambia el modelo de exposici\u00f3n, reevaluar claves SSH.

## Instalaci\u00f3n (bootstrap de la VM)

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

## Post-instalaci\u00f3n

1. Definir la contrase\u00f1a del usuario: `passwd lucho`.
2. Verificar conectividad y que el gateway `192.168.1.1` responda.
3. Desde la workstation: `ssh lucho@192.168.1.11`.

## Pendientes

- Compartir `tank/{immich,familia,backups}` del host hacia la VM
  (virtiofs o NFS) y retomar Samba sobre el mount point definitivo.
- Pangolin (80/443, edge p\u00fablico), CrowdSec (LAPI + bouncers).
- Immich y Jellyfin con datos en `tank`.
- Backups con restic hacia la torre.
- Cuotas ZFS por dataset: follow-up en runtime.
