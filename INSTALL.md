# Instalación de workstation

Guía corta para reinstalar `workstation` desde una ISO de NixOS. Este flujo
destruye el disco seleccionado o autodetectado (por defecto el declarado como
`diskDevice` en `flake.nix`).

## Instalación automática

Hay un script que hace todo el flujo en un solo comando: detección del disco,
confirmación tipeada, Disko, `nixos-install`, `passwd` y, opcionalmente, el
enrolamiento de TPM2 + PIN.

Desde la ISO de NixOS, como root, clonar el repo y ejecutarlo:

```bash
cd /tmp
git clone <URL-DE-ESTE-REPO> nixos-config
cd nixos-config
sudo ./scripts/install-workstation.sh
```

Si tenés `just` disponible, la receta hace lo mismo:

```bash
just install-workstation
```

El script detecta el disco (o acepta `--disk /dev/X`), muestra modelo, tamaño y
serial, y exige tipear la ruta exacta del dispositivo antes de destruir nada.
La passphrase de LUKS la pide Disko de forma interactiva; el script no la
guarda. Al final pregunta si querés enrolar TPM2 + PIN ahora (por defecto no).

El disco seleccionado se le pasa a Disko explícitamente (`--argstr
diskDevice`), así que para instalar en otro disco no hace falta editar el
flake: alcanza con `--disk /dev/X`. El sistema instalado monta por partlabel y
funciona igual en cualquiera de los dos.

La sección manual de abajo queda como alternativa paso a paso.

## Desde la ISO

1. Bootear la ISO de NixOS, conectar red y abrir una terminal.

2. Entrar como root y habilitar flakes para esa sesión:

   ```bash
   sudo -i
   export NIX_CONFIG='experimental-features = nix-command flakes'
   ```

3. Instalar Git temporalmente si hace falta y clonar el repo:

   ```bash
   nix-shell -p git
   cd /tmp
   git clone <URL-DE-ESTE-REPO> nixos-config
   cd nixos-config
   ```

4. Verificar el disco antes de destruir nada:

   ```bash
   lsblk -f
   grep -n 'diskDevice' flake.nix
   ```

   Para esta máquina, el valor esperado es:

   ```nix
   diskDevice = "/dev/nvme0n1";
   ```

5. Formatear y montar con Disko usando la configuración del flake:

   ```bash
   nix run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake .#workstation
   ```

6. Instalar NixOS:

   ```bash
   nixos-install --flake .#workstation
   ```

7. Crear la contraseña del usuario:

   ```bash
   nixos-enter --root /mnt -c 'passwd lucho'
   ```

8. Reiniciar:

   ```bash
   reboot
   ```

## Primer arranque

En el primer arranque, desbloquear LUKS con la passphrase larga definida durante
la instalación. Esa passphrase debe guardarse fuera del repo, por ejemplo en
Bitwarden.

Después de iniciar sesión, validar:

```bash
lsblk -f
findmnt / /home /nix /boot
just build
```

## Habilitar TPM2 + PIN

TPM2 + PIN evita escribir la passphrase larga en el uso diario. El PIN sólo
sirve junto con el TPM de esta máquina; si sacan el disco y lo conectan en otro
hardware, no alcanza.

```bash
sudo systemd-cryptenroll \
  --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-with-pin=yes \
  /dev/nvme0n1p2
```

Reiniciar y confirmar que el desbloqueo pide el PIN. `--wipe-slot=tpm2` evita
conservar por accidente un enrolamiento TPM2 viejo sin PIN. La passphrase larga
queda como recuperación.
