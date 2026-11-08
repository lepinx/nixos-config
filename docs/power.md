# Energía, suspend y wakeup USB

## Perfil de energía

La notebook usa `power-profiles-daemon`.

La política declarada en `modules/nixos/desktop.nix` es:

- enchufada a corriente: `performance`;
- en batería: `balanced`.

Esto mejora la sensación de apertura instantánea de aplicaciones cuando estás en
escritorio/AC, sin dejar la máquina permanentemente en modo agresivo cuando
funciona con batería.

Comandos útiles:

```bash
powerprofilesctl get
upower -d | rg "on-battery|percentage|state|energy-rate"
```

Si se quiere probar manualmente:

```bash
powerprofilesctl set performance
powerprofilesctl set balanced
```

El cambio declarativo se vuelve a aplicar al arrancar y cuando cambia el estado
del cargador.

Notas migradas desde el repo anterior para diagnosticar equipos que entran en
suspend y se despiertan casi inmediatamente.

## Diagnóstico rápido

Ver modo actual de suspend:

```bash
cat /sys/power/mem_sleep
```

Si aparece algo como:

```text
[s2idle] deep
```

el equipo está usando `s2idle`.

Listar wakeup USB sospechosos:

```bash
grep . /sys/bus/usb/devices/*/power/wakeup 2>/dev/null
```

Probar desactivar un dispositivo concreto antes de suspender:

```bash
echo disabled | sudo tee /sys/bus/usb/devices/3-4/power/wakeup
systemctl suspend
```

Volver al estado base:

```bash
echo enabled | sudo tee /sys/bus/usb/devices/3-4/power/wakeup
```

Diagnosticar el último ciclo de suspend:

```bash
journalctl -b -1 | rg "suspend|PM: suspend|wakeup|wake|ACPI"
```

## Regla Logitech antigua

La regla para el receiver Logitech `046d:c548` está declarada en
`modules/nixos/hardware/logitech.nix` (importada por
`modules/nixos/hardware/default.nix`, activa en el perfil workstation):
deshabilita el wakeup del device USB para evitar reanudaciones espurias en
`s2idle`. Si `lsusb` muestra otro receiver con el mismo problema, extender la
regla con el par vendor/product correspondiente.
