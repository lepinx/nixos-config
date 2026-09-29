# Host homelab

Servidor casero (torre) en NixOS, en reemplazo de Ubuntu Server.

Este host usa criterios distintos a una workstation:

- sin Niri, Noctalia ni Home Manager de escritorio;
- servicios declarativos;
- almacenamiento y red tratados con más cuidado;
- dos discos con LUKS: SSD para el sistema y HDD para datos.

## Estado actual

El host está completamente definido y expuesto como
`nixosConfigurations.homelab`, con `enableHomeManager = false`. Incluye:

- `hosts/homelab/disko.nix`: layout de dos discos (SSD + HDD) con LUKS y Btrfs;
- `hosts/homelab/hardware-configuration.nix`: hardware mínimo del servidor;
- `hosts/homelab/default.nix`: boot UEFI, desbloqueo LUKS con TPM2, red fija,
  SSH endurecido y firewall;
- `hosts/homelab/samba.nix`: recurso compartido por usuario.

Estado de instalación: **definido pero todavía no instalado** en la torre.

## Exposición de red

El firewall abre explícitamente 80/443 TCP y 51820/UDP. SSH queda fuera de la
lista de puertos permitidos: es accesible únicamente desde la LAN.

Samba usa `openFirewall = true`, así que agrega 445/139 TCP y 137/138 UDP a la
allowlist resultante. La torre vive detrás del router de la LAN, por lo que esos
puertos no son alcanzables desde la WAN.

## Instalación

Requisitos previos:

- UEFI activado y CSM desactivado en la BIOS.
- SSD (sistema) y HDD (datos) conectados.

1. Partir discos, formatear y montar con disko. Reformatea ambos discos:

   ```bash
   sudo nix run github:nix-community/disko -- --mode destroy,format,mount \
     --flake .#homelab \
     --argstr diskDeviceBoot /dev/sda \
     --argstr diskDeviceData /dev/sdb
   ```

   El comando pide **dos passphrases LUKS** (una por disco).

2. Instalar el sistema:

   ```bash
   sudo nixos-install --flake .#homelab
   ```

## Post-instalación

1. Definir la contraseña del usuario:

   ```bash
   passwd lucho
   ```

2. Registrar la contraseña de Samba:

   ```bash
   sudo smbpasswd -a lucho
   ```

3. Enrolar el TPM2 en ambos discos LUKS (verificar las particiones con `lsblk`
   antes de correr los comandos):

   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-with-pin=yes /dev/sda2
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-with-pin=yes /dev/sdb1
   ```

4. Restaurar los datos desde el staging montado en `/mnt` hacia
   `/srv/data/lucho`.

## Pendientes

- Agregar la clave pública SSH del usuario en `hosts/homelab/default.nix` antes
  de instalar (todavía no existe ninguna en la workstation).
- Verificar el gateway `192.168.1.1` y los DNS `1.1.1.1` / `9.9.9.9` al momento
  de instalar.
- Cuotas Btrfs (qgroup) por subvolumen: follow-up en runtime.
- Usuarios adicionales: subvolumen en `disko.nix`, recurso en `samba.nix` y
  `smbpasswd`.
- CrowdSec (fase C).
- Pangolin (fase 2).
