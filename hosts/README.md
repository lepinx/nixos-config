# Hosts

Este directorio separa lo que pertenece a cada máquina de los módulos
compartidos.

La regla práctica:

- `modules/nixos/`: comportamiento reusable del sistema.
- `modules/nixos/core.nix`: base independiente del tipo de máquina: Nix,
  locale y compatibilidad de estado.
- `modules/nixos/workstation.nix`: política de notebook/escritorio: boot UEFI,
  NetworkManager, usuario interactivo y contenedores locales.
- `modules/home/`: configuración reusable del usuario.
- `hosts/<nombre>/`: hardware, discos, red, pantallas y decisiones específicas
  de esa máquina.

## Hosts activos

- `workstation`: notebook personal, instalado.
- `homelab`: servidor principal, VM NixOS sobre Proxmox (`192.168.1.10`, VM id
  100) definido como `nixosConfigurations.homelab`, **instalada y booteando**
  (NixOS 26.05, SSH en `192.168.1.11`). La torre Ubuntu vieja
  (`192.168.1.50`) queda para backups (restic) + laboratorio; se planea
  reinstalarla como NixOS con lo mínimo y moverla a `192.168.1.12`.

## Asignación de IPs (LAN 192.168.1.0/24)

El router ADSL reparte DHCP en `.100-.254`. El rango `.2-.99` queda reservado
para infraestructura con IP estática:

| IP | Host | Rol |
| --- | --- | --- |
| `192.168.1.1` | Router ADSL | gateway |
| `192.168.1.2` | Switch HPE OfficeConnect 1420 | gestión |
| `192.168.1.10` | `proxmox` (Aoostar WTR Pro) | hipervisor, VMs y zpool `tank` |
| `192.168.1.11` | VM NixOS `homelab` (instalada) | server principal de servicios |
| `192.168.1.50` | Torre Ubuntu (ex-homelab) | backups (restic) + laboratorio |

Nuevas VMs o servicios con IP fija van en `.12-.99`; todo lo dinámico en el
rango DHCP.

## Caso abierto: la notebook no alcanza el LAN desde la WiFi del router

Estado: **sin causa raíz determinada**. Reportado por primera vez el 2026-09-19 y
revisado el 2026-11-09.

Qué se observó: una notebook asociada a `Covid 5Ghz` (`192.168.1.101`) llegaba
al gateway `192.168.1.1` en 1,37 ms promedio con jitter de 0,28 ms y cero
reintentos, pero tenía **100 % de pérdida** hacia `192.168.1.10`, `.11` y `.50`,
con `:8006` (Proxmox) y `:2222` (torre) filtrados. Su entrada ARP para `.50`
figuraba *REACHABLE*: el enlace de capa 2 funcionaba y el descarte era de capa 3.

Qué **no** es (verificado el 2026-11-09): **no** es un aislamiento del SSID ni de
la banda. Un celular asociado al mismo `Covid 5Ghz` (`192.168.1.100`) fue
alcanzable sin pérdida desde la notebook en `Virus`, desde la torre cableada y
desde la VM NixOS. Las dos radios son del propio router
(`Covid 2.4Ghz` = `a8:29:48:12:6e:08`, `Covid 5Ghz` = `a8:29:48:12:6e:0a`) y el
SSID **sí** puentea al LAN.

Hipótesis vigentes: (a) un bloqueo por dispositivo en el router (control de
acceso, control parental o lista de dispositivos bloqueados); (b) un estado
obsoleto de la tabla de reenvío o del ARP en el AP o su uplink después del
roaming desde `Virus`.

Consecuencia práctica: AdGuard Home (`192.168.1.50`) es el DNS primario que
reparte el DHCP, así que un cliente que realmente no alcance el LAN pierde
resolución de nombres.

El router principal es un TP-Link `XC220-G3`: un ONT de fibra con firmware
personalizado por el ISP (Aginet / TR-181), así que varias opciones están
ocultas o se administran remotamente. TP-Link documenta un caso análogo en su
propio foro: en un `EX220`, también personalizado por un ISP, las redes
Multi-SSID no accedían al LAN.

El arreglo estructural sigue siendo el plan de red segmentada: switch
administrado y APs propios en bridge, sin depender de la WiFi del router.

## Próximo host previsto

La torre Ubuntu (`192.168.1.50`) es el próximo host a convertir: reinstalación
como NixOS con lo mínimo para el target de `restic`, en `192.168.1.12`, una vez
que sus datos estén verificados fuera de ella. `homelab` ya está instalado en la
VM de Proxmox (ver `odd/tasks/homelab-proxmox.md`).

El flake pasa `hostName`, `userName` y `repoPath` a los módulos para
evitar rutas hardcodeadas. El `justfile` usa el hostname corto de la máquina por
defecto:

```bash
just build
```

## Perfiles

Los hosts importan un perfil base junto con sus módulos específicos:

- `modules/nixos/profiles/workstation.nix`: escritorio personal o laboral con
  Umbriel, Noctalia, greeter, apps gráficas y Home Manager.
- `modules/nixos/profiles/server.nix`: servidor/headless sin stack de escritorio (Noctalia/Umbriel) ni
  apps de escritorio. Sólo trae base NixOS y mantenimiento; red, boot, usuarios
  y servicios se declaran explícitamente por host o por módulo de servicio.

`homelab` parte del perfil `server`; `workstation` parte del perfil
`workstation`.

Para `homelab`, el output del flake usa `enableHomeManager = false` o un perfil
Home Manager específico de servidor. El perfil `home/lucho` es de escritorio y
trae Noctalia, Umbriel y aplicaciones gráficas.

## Umbriel por host

`configs/umbriel/config.toml` es una plantilla compartida. Home Manager genera el
archivo final `~/.config/umbriel/config.toml` y apunta el include de outputs a
`~/.config/umbriel/outputs.toml`.

Ese `outputs.toml` sale de `hosts/${hostName}/umbriel-outputs.toml`, por lo que cada
workstation puede tener monitores, escalas y posiciones propias sin contaminar
otras máquinas.

## Hardware específico

Las reglas por modelo de dispositivo pueden vivir en módulos compartidos si son
seguras para todas las máquinas. Por ejemplo, la regla Logitech está en
`modules/nixos/hardware/logitech.nix` y usa `idVendor/idProduct`, así que sirve
para cualquier receiver del mismo modelo.

Las configuraciones que dependen de una máquina concreta van en el host:

- layout de discos;
- pantallas y escala;
- hostname;
- red fija;
- GPU específica;
- servicios del servidor;
- usuarios o permisos propios de esa máquina.
