# Hosts

Este directorio separa lo que pertenece a cada máquina de los módulos
compartidos.

La regla práctica:

- `modules/nixos/`: comportamiento reusable del sistema.
- `modules/home/`: configuración reusable del usuario.
- `hosts/<nombre>/`: hardware, discos, red, pantallas y decisiones específicas
  de esa máquina.

## Hosts activos

- `workstation`: notebook personal.

## Hosts disponibles como plantillas

- `office`: notebook/PC de oficina.
- `homelab`: servidor casero.

No se agregan como `nixosConfigurations` hasta tener su
`hardware-configuration.nix` real. Así el flake sólo expone máquinas con
definición construible.

El flake pasa `hostName`, `userName`, `repoName` y `repoPath` a los módulos para
evitar rutas hardcodeadas. El `justfile` usa el hostname corto de la máquina por
defecto:

```bash
just build
```

Si hace falta apuntar a otro host manualmente, `NIXOS_HOST` funciona como
override:

```bash
NIXOS_HOST=office just build
```

## Perfiles

Los hosts importan un perfil base junto con sus módulos específicos:

- `modules/nixos/profiles/workstation.nix`: escritorio personal o laboral con
  Niri, Noctalia, greeter, apps gráficas y Home Manager.
- `modules/nixos/profiles/server.nix`: servidor/headless sin Niri, Noctalia ni
  apps de escritorio.

La plantilla `homelab` parte del perfil `server`; `workstation` y `office`
parten del perfil `workstation`.

Para `homelab`, el output del flake usa `enableHomeManager = false` o un perfil
Home Manager específico de servidor. El perfil `home/lucho` es de escritorio y
trae Noctalia, Niri y aplicaciones gráficas.

## Niri por host

`configs/niri/config.kdl.in` es una plantilla compartida. Home Manager genera el
archivo final `~/.config/niri/config.kdl` y apunta el include de outputs a
`~/.config/niri/outputs.kdl`.

Ese `outputs.kdl` sale de `hosts/${hostName}/niri-outputs.kdl`, por lo que cada
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
