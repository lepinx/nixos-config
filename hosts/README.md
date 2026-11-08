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
  100) definido como `nixosConfigurations.homelab`; bootstrap pendiente. La
  torre Ubuntu vieja (`192.168.1.50`) queda para backups + laboratorio.

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

## Próximo host previsto

Por ahora no hay otro host planificado. `homelab` era el próximo host y ya está
instalado en la VM de Proxmox (ver `odd/tasks/homelab-proxmox.md`).

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
