# Host homelab

Plantilla para un servidor casero en NixOS.

Este host usa criterios distintos a una workstation:

- sin Niri, Noctalia ni Home Manager de escritorio;
- servicios declarativos;
- almacenamiento y red tratados con más cuidado;
- secretos declarativos con `sops-nix`;
- backups del servidor definidos en este host.

Checklist inicial:

1. Auditar servicios del servidor.
2. Listar discos, mounts y datos que no pueden perderse.
3. Definir hostname, IP fija/DHCP reservation y DNS local.
4. Elegir boot BIOS/UEFI y declarar el bootloader en el host.
5. Elegir estrategia de disco: conservar layout, migrar con Disko o reinstalar.
6. Crear el usuario administrador y habilitar SSH de forma explícita.
7. Crear módulos por servicio en `modules/nixos/services/`.
8. Agregar `nixosConfigurations.homelab` junto con el hardware real.
   Usar `enableHomeManager = false`, o crear un perfil Home Manager propio de
   servidor si realmente hace falta.

Servicios posibles:

- SSH endurecido;
- reverse proxy;
- Cloudflare Tunnel o WireGuard;
- contenedores con Podman;
- almacenamiento compartido;
- restic/rclone para backups del servidor.
