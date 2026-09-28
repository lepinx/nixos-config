# Host homelab

Notas para un futuro servidor casero en NixOS.

Este host usa criterios distintos a una workstation:

- sin Niri, Noctalia ni Home Manager de escritorio;
- servicios declarativos;
- almacenamiento y red tratados con más cuidado;
- secretos declarativos con `sops-nix`;
- backups del servidor definidos en este host.

Estado actual:

El scaffold existe: `hosts/homelab/default.nix` importa `modules/nixos/profiles/server.nix`,
y el perfil `server` quedó corregido para traer sólo base + mantenimiento (red, boot,
usuarios y servicios se declaran por host o por módulo de servicio).

Este host todavía NO se expone como `nixosConfigurations`: falta su
`hardware-configuration.nix` real. Recién ahí el flake va a construir esta máquina.

Próximo paso: escaneo de hardware de la torre vieja con Ubuntu (presencia de TPM2,
UEFI/BIOS, discos y red). Ese relevamiento define el modelo de desbloqueo LUKS, el
layout de disko y la IP fija.

Checklist inicial:

1. Auditar servicios del servidor.
2. Listar discos, mounts y datos que no pueden perderse.
3. Definir hostname, IP fija/DHCP reservation y DNS local.
4. Elegir boot BIOS/UEFI y declarar el bootloader en el host.
5. Elegir estrategia de disco: conservar layout, migrar con Disko o reinstalar.
6. Crear el usuario administrador y habilitar SSH de forma explícita.
7. Crear módulos por servicio en `modules/nixos/services/`.
8. Agregar `nixosConfigurations.homelab` en el flake junto con el hardware real.
   Usar `enableHomeManager = false`, o crear un perfil Home Manager propio de
   servidor si realmente hace falta.

Servicios posibles:

- SSH endurecido;
- reverse proxy;
- Cloudflare Tunnel o WireGuard;
- contenedores con Podman;
- almacenamiento compartido;
- restic/rclone para backups del servidor.
