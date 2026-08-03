# LUKS + TPM2

La instalación activa de `workstation` usa LUKS + Btrfs.

## Estado actual

- `workstation` es el perfil diario cifrado.
- `/boot` queda sin cifrar como partición EFI.
- El resto del disco se cifra con LUKS como `cryptroot`.
- Dentro de `cryptroot` hay Btrfs con subvolúmenes para `/`, `/home` y `/nix`.
- El layout declarativo vive en `hosts/workstation/disko.nix`.
- La configuración de desbloqueo vive en `modules/nixos/encryption.nix`.

No queda un perfil alternativo para instalación cifrada: `workstation` es el
perfil único de esta máquina. La guía de reinstalación está en `INSTALL.md`.

## Modelo de seguridad

LUKS protege los datos cuando la máquina está apagada. No protege una sesión
desbloqueada ni una máquina suspendida con sesión abierta.

### Sólo passphrase LUKS

La clave para desbloquear el disco está únicamente en una passphrase humana.

- Si sacan el disco y lo conectan en otro hardware, necesitan la passphrase.
- Si roban la notebook apagada, necesitan la passphrase.
- Es el modelo más simple y fuerte, pero menos cómodo.

### TPM2 sin PIN

El secreto de desbloqueo queda sellado al TPM de esta máquina y a su estado de
arranque.

- Si sacan el disco y lo conectan en otro hardware, no tienen el TPM y no pueden
  desbloquear con ese secreto.
- Si roban la notebook completa, la propia notebook puede desbloquear el disco
  si el estado de arranque coincide.
- La seguridad pasa a depender mucho del login, del bloqueo de sesión y de que
  no haya bypass físico o de arranque.

Esto es cómodo, pero para una notebook robable es menos interesante que TPM2 +
PIN.

### TPM2 + PIN

El secreto queda sellado al TPM, pero además pide un PIN al arrancar.

- Si sacan el disco, el PIN no sirve porque falta el TPM.
- Si roban la notebook apagada, necesitan esa notebook y el PIN.
- La passphrase larga de LUKS sigue existiendo como recuperación.

Este es el punto medio recomendado para uso diario: PIN corto al arrancar,
password de usuario en el login, passphrase larga guardada fuera del repo.

## Habilitar TPM2 + PIN

La configuración declarativa ya permite desbloqueo con TPM2:

```nix
boot.initrd.luks.devices.cryptroot = {
  crypttabExtraOpts = [ "tpm2-device=auto" ];
};
```

Enrolar TPM2 + PIN:

```bash
sudo systemd-cryptenroll \
  --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-with-pin=yes \
  /dev/nvme0n1p2
```

`--wipe-slot=tpm2` elimina enrolamientos TPM2 anteriores después de crear el
nuevo. Esto evita conservar por accidente un desbloqueo TPM2 sin PIN.

Reiniciar y validar que el arranque pide PIN. Si falla, usar la passphrase larga
de recuperación.

Elegir un PIN recordable pero no trivial. El TPM tiene protección contra fuerza
bruta y puede bloquear intentos por un tiempo si se falla demasiadas veces.

Ver slots y tokens enrolados:

```bash
sudo systemd-cryptenroll /dev/nvme0n1p2
```

## Cambiar passphrase LUKS

Para cambiar la passphrase larga del disco:

```bash
sudo cryptsetup luksChangeKey /dev/nvme0n1p2
```

El comando pide la passphrase actual y luego la nueva. Elegir una passphrase
larga y única, guardarla en Bitwarden y no versionarla en este repo.

Si se quiere hacer con más margen de recuperación:

```bash
sudo cryptsetup luksAddKey /dev/nvme0n1p2
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2
sudo cryptsetup luksRemoveKey /dev/nvme0n1p2
```

Ese flujo agrega primero la passphrase nueva, la prueba y recién después elimina
la vieja.

## Validación

```bash
lsblk -f
findmnt / /home /nix /boot
sudo systemd-cryptenroll /dev/nvme0n1p2
just check
just build
```

Criterios esperados:

- La segunda partición del disco elegido aparece como `crypto_LUKS`
  (`/dev/nvme0n1p2` en esta máquina).
- `/`, `/home` y `/nix` montan desde Btrfs dentro de `cryptroot`.
- `/boot` monta desde la partición EFI sin cifrar.
- Noctalia Greeter inicia Niri.
- Red, audio, Bluetooth, Firefox, terminal y editores abren normalmente.

## Si `just switch` falla por `/boot`

Si aparece:

```text
efiSysMountPoint = '/boot' is not a mounted partition
```

montar la partición EFI y repetir:

```bash
sudo mount -t vfat \
  -o fmask=0077,dmask=0077 \
  /dev/disk/by-partlabel/disk-main-ESP \
  /boot

findmnt /boot
just switch
```

Esto puede pasar durante la transición a la configuración LUKS/Disko si la
generación activa todavía tiene un `/etc/fstab` viejo. Después de un `switch`
exitoso, la generación nueva declara `/boot` como
`/dev/disk/by-partlabel/disk-main-ESP`.

## Si `just switch` falla por `/home`

Si aparece:

```text
Failed to restart home.mount
```

y `findmnt /home` muestra `/dev/mapper/cryptroot[/home]`, el sistema ya está
montado correctamente. El fallo ocurre porque systemd intenta reiniciar el mount
de `/home` mientras la sesión gráfica y el usuario están usando archivos dentro
de `/home`.

En ese caso, reiniciar es la salida más limpia:

```bash
reboot
```

Después del reinicio, validar:

```bash
findmnt / /home /nix /boot
systemctl --failed
```

## Contraseña del usuario

La contraseña de `lucho` se define manualmente con `passwd`; no se versiona en
el repo.

No conviene publicar `hashedPassword` directamente en un repo público: aunque
no sea la contraseña en texto plano, permite ataques offline contra el hash.

`sops-nix` puede usarse más adelante para declarar un `hashedPasswordFile`,
pero no simplifica gratis la primera instalación: hay que gestionar y respaldar
la clave privada de `age` que permite descifrar el secreto durante la
instalación.

Para esta PC, el balance actual es:

- passphrase larga LUKS fuera del repo;
- PIN TPM2 fuera del repo;
- contraseña de usuario definida con `passwd`;
- adoptar `sops-nix` cuando haya secretos declarativos reales, por ejemplo
  tokens de servicios, claves WireGuard o credenciales del homelab.

## Recuperación básica

Si TPM2 + PIN falla, usar la passphrase larga de LUKS.

No borres entradas EFI viejas hasta confirmar varios arranques correctos del
sistema nuevo.
