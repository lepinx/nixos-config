# Diagnóstico de disco SATA

Guía corta para verificar el disco SATA viejo después de instalar NixOS en un
disco nuevo.

## Identificar los discos

No asumir que el disco viejo será siempre `sda`: confirmar por modelo y serial.

```bash
lsblk -o NAME,MODEL,SERIAL,SIZE,TRAN,MOUNTPOINTS
```

## Ver el kernel en vivo

```bash
sudo journalctl -k -f
```

Para revisar el arranque actual o el anterior:

```bash
sudo journalctl -k -b --no-pager
sudo journalctl -k -b -1 --no-pager
```

Para filtrar los fallos SATA conocidos:

```bash
sudo journalctl -k -b --no-pager | grep -Ei \
  'ata[0-9].*(exception|SError|connection status changed|hard resetting link|failed command|limiting SATA)|I/O error, dev sd'
```

## Señales del fallo observado

El WD Green presentó errores de enlace SATA, no sólo sectores defectuosos:

```text
exception Emask 0x10
SError: { PHYRdyChg CommWake DevExch }
connection status changed
failed command: READ/WRITE FPDMA QUEUED
hard resetting link
I/O error, dev sdX
limiting SATA link speed to 3.0 Gbps
```

Un inicio sano puede mostrar `SATA link up 6.0 Gbps` y `configured for
UDMA/133`, pero no debe repetir los mensajes anteriores mientras se usa el
disco.

## SMART

Instalar `smartmontools` en el sistema y consultar el dispositivo correcto:

```bash
sudo smartctl -x /dev/sdX
```

Revisar especialmente `UDMA_CRC_Error_Count`, `Reallocated_Sector_Ct`,
`Current_Pending_Sector` y `Offline_Uncorrectable`.

## Btrfs y gráfica Intel

Si el disco usa Btrfs:

```bash
btrfs device stats /
btrfs scrub status /
```

`Registered ... with drm panic` de `i915` no es un kernel panic. Para errores
gráficos reales, buscar `GPU HANG`, `i915 ... error`, `reset`, `wedged` o
`fault`.

Para conservar el journal tras reinicios, incluir en NixOS:

```nix
services.journald.extraConfig = "Storage=persistent";
```
