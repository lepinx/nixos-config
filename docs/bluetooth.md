# Bluetooth troubleshooting

Notas para esta máquina NixOS/Umbriel cuando Bluetooth o auriculares emparejados
vuelvan a comportarse raro.

## Síntomas vistos

- El switch visual de Bluetooth aparece apagado y no logra activarlo.
- `bluetoothctl show` muestra:

  ```text
  Powered: no
  PowerState: off-blocked
  ```

- `rfkill list bluetooth` muestra `Soft blocked: yes`.
- Los auriculares conectan por un instante y luego rebotan.
- `bluetoothctl connect "$DEVICE"` puede fallar con:

  ```text
  org.bluez.Error.Failed br-connection-unknown
  ```

- En logs de BlueZ apareció:

  ```text
  profiles/audio/avdtp.c:avdtp_connect_cb() ... Permission denied (13)
  ```

## Estado esperado

```bash
rfkill list bluetooth
bluetoothctl show
```

Debe verse algo parecido a:

```text
Soft blocked: no
Powered: yes
PowerState: on
```

Para los auriculares:

```bash
bluetoothctl devices
DEVICE=<MAC-DE-AURICULARES>
bluetoothctl info "$DEVICE"
wpctl status
```

Debe verse:

```text
Paired: yes
Trusted: yes
Connected: yes
```

y en PipeWire:

```text
<nombre de los auriculares> [bluez5]
```

## Si Bluetooth arranca apagado

Arreglo manual inmediato:

```bash
rfkill unblock bluetooth
bluetoothctl power on
```

La configuración declarativa ya hace esto antes de iniciar BlueZ:

```nix
systemd.services.bluetooth.preStart = ''
  ${pkgs.util-linux}/bin/rfkill unblock bluetooth
'';
```

Si vuelve a pasar después de un reboot, revisar:

```bash
rfkill list bluetooth
journalctl -b -u bluetooth --no-pager
journalctl -b -u systemd-rfkill --no-pager
```

## Si los auriculares conectan y se desconectan

Primero apagar Bluetooth del teléfono u otros equipos cercanos para evitar que
el multipoint robe la conexión.

Luego hacer pairing limpio:

```bash
bluetoothctl devices
DEVICE=<MAC-DE-AURICULARES>
bluetoothctl remove "$DEVICE"
```

Poner los auriculares en pairing mode real. No alcanza con que estén encendidos:
tienen que anunciarse como disponibles para emparejar.

Después:

```bash
bluetoothctl --timeout 45 pair "$DEVICE"
bluetoothctl trust "$DEVICE"
bluetoothctl --timeout 25 connect "$DEVICE"
```

Si conecta pero no queda como salida:

```bash
wpctl status
```

Si aparece un sink de los auriculares, se puede elegir desde Noctalia o con
`wpctl set-default <id>`.

## Config actual relevante

WirePlumber está limitado a perfiles A2DP para priorizar música estable:

```nix
services.pipewire.wireplumber.extraConfig."10-bluez-a2dp" = {
  "monitor.bluez.properties" = {
    "bluez5.roles" = [
      "a2dp_sink"
      "a2dp_source"
    ];
  };
};
```

Esto desactiva deliberadamente HFP/HSP por ahora. Consecuencia: audio estéreo
estable, pero no micrófono Bluetooth de los auriculares.
