# Host homelab

Servidor casero (torre) en NixOS, en reemplazo de Ubuntu Server.

Este host usa criterios distintos a una workstation:

- sin stack de escritorio (Noctalia/Umbriel);
- servicios declarativos;
- almacenamiento y red tratados con más cuidado;
- LUKS en el SSD para el sistema y un HDD de datos en Btrfs plano, montado por
  etiqueta.

## Estado actual

El host está completamente definido y expuesto como
`nixosConfigurations.homelab`, con `enableHomeManager = false`. Incluye:

- `hosts/homelab/disko.nix`: layout del SSD (ESP + LUKS + Btrfs). El HDD de datos
  queda fuera de disko a propósito;
- `hosts/homelab/hardware-configuration.nix`: hardware mínimo del servidor;
- `hosts/homelab/default.nix`: boot UEFI, desbloqueo LUKS del SSD con TPM2,
  montaje del disco de datos por etiqueta, red fija, SSH endurecido y firewall;
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
- SSD (sistema) conectado.
- HDD de datos **físicamente desconectado** durante la instalación (recomendado
  por seguridad). Disko ya no lo toca, pero desconectarlo evita cualquier error
  de dispositivo.

1. Partir, formatear y montar el SSD con disko. Solo reformatea el SSD:

   ```bash
   sudo nix run github:nix-community/disko -- --mode destroy,format,mount \
     --flake .#homelab \
     --argstr diskDeviceBoot /dev/sda
   ```

   El comando pide **una sola passphrase LUKS** (la del SSD).

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

3. Enrolar el TPM2 únicamente en el LUKS del SSD. Verificar la partición con
   `lsblk` antes de correr el comando (`/dev/sda2` es la partición LUKS del SSD):

   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-with-pin=yes /dev/sda2
   ```

   El HDD de datos no tiene LUKS, así que no se enrola nada en él: se monta
   automáticamente por etiqueta con los datos staged intactos.

## Disco de datos

El HDD de datos **no** lo gestiona disko. Se prepara y se cargan los datos desde
un live boot **antes** de instalar NixOS, como Btrfs plano:

1. Crear el filesystem con la etiqueta que espera `default.nix`:

   ```bash
   sudo mkfs.btrfs -L homelab-data /dev/sdX
   ```

2. Montarlo y crear un subvolumen por usuario:

   ```bash
   sudo mount /dev/disk/by-label/homelab-data /mnt/hdd
   sudo btrfs subvolume create /mnt/hdd/lucho
   ```

3. Copiar los datos staged dentro del subvolumen:

   ```bash
   sudo rsync -aHAX /ruta/origen/ /mnt/hdd/lucho/
   sudo umount /mnt/hdd
   ```

Como disko solo formatea el SSD, los datos del HDD sobreviven la instalación sin
cambios. `default.nix` monta el disco por etiqueta en `/srv/data/<usuario>` con
`subvol=<usuario>`.

Encriptar el disco de datos con LUKS queda como opción documentada a futuro
(próxima generación de hardware, con backups reales en su lugar).

## Pendientes

- Verificar el gateway `192.168.1.1` y los DNS `1.1.1.1` / `9.9.9.9` al momento
  de instalar.
- SSH con autenticación por contraseña: decisión explícita del usuario
  (sólo LAN/VPN, nunca expuesto). Si el modelo de exposición cambia,
  reevaluar claves SSH.
- Cuotas Btrfs (qgroup) por subvolumen: follow-up en runtime.
- Usuarios adicionales: subvolumen creado en el disco de datos durante el
  staging, recurso en `samba.nix` y `smbpasswd`.
- CrowdSec (fase C).
- Pangolin (fase 2).
