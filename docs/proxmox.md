# Proxmox: aprovisionamiento del hipervisor

Este host **no está versionado en el flake**. Es la única máquina de la casa que se
administra de forma imperativa: NixOS corre dentro de una VM, y el hipervisor queda
fuera de Nix. Este documento es la receta para reconstruirlo, y la lista de lo que
hay que revisar cuando algo se rompe.

Regla de diseño: **en el Proxmox no corre ningún servicio de usuario**. Sólo
hipervisor, almacenamiento y el servidor NFS que alimenta a la VM.

## Versión

- `pve-manager` 9.2.24, kernel `7.0.14-26-pve`
- Hardware: Aoostar WTR Pro, 16 cores, 30 GiB de RAM, 2 NICs
- `vmbr0` en `192.168.1.10/24`; la segunda NIC queda libre para un futuro router

## Almacenamiento

El NVMe de 1 TB usa el layout LVM-thin por defecto de Proxmox (`pve-root` 96G,
`pve-data` thinpool, `pve-swap` 8G). Los discos de datos son un **mirror ZFS** de
2× WD40EFZZ de 4 TB.

> Sobre los discos: los WD40EFZZ son **CMR**, no SMR. El datasheet de WD Red Plus
> lo declara y el identify del disco no reporta TRIM. Los WD Red con SMR son la
> familia `EFAX` (`WD20/30/40/60EFAX`). No hace falta cambiarlos.

Datasets y quién es dueño de cada uno:

| Dataset | Uso | Cuota | Dueño (uid:gid) | Modo |
| --- | --- | --- | --- | --- |
| `tank/familia` | raíz del share familiar | — | 3000:3000 (`nas`) | 0755 |
| `tank/familia/lucho` | espacio privado | 500G | **1000:1000** | 0700 |
| `tank/familia/ricardo` | espacio privado | 500G | 3002:3002 | 0700 |
| `tank/familia/mariaelena` | espacio privado | 500G | 3003:3003 | 0700 |
| `tank/familia/compartido` | compartido, setgid | 1T | 3000:3010 (`nas:familia`) | 2775 |
| `tank/immich` | biblioteca de Immich | — | 3000:3000 (`nas`) | 0755 |
| `tank/backups` | reservado; hoy sin uso (los backups van a la torre) | — | 0:0 | 0755 |
| `tank/hypervisor` | dump de esta configuración | — | 0:0 | 0700 |

**`lucho` es 1000 y no 30xx a propósito**: en la VM `lucho` es el usuario admin con
uid 1000, y crear una segunda identidad habría cambiado el dueño de `/home/lucho`.
Se alineó el número en vez del nombre.

### Por qué importan los números y no los nombres

NFS viaja **uid/gid numéricos**, no nombres. El servidor aplica permisos con el
número que manda el cliente, y `no_root_squash` deja pasar a root. Consecuencia
práctica: el usuario `nas` existe en el Proxmox sólo por comodidad al listar
archivos. Lo que tiene que coincidir entre las dos máquinas es **el número**.

Por eso el `chown` se hace numérico y sin recursión cuando el dataset está vacío:

```bash
chown 1000:1000 /tank/familia/lucho;  chmod 700  /tank/familia/lucho
chown 3002:3002 /tank/familia/ricardo; chmod 700  /tank/familia/ricardo
chown 3003:3003 /tank/familia/mariaelena; chmod 700  /tank/familia/mariaelena
chown 3000:3010 /tank/familia/compartido; chmod 2775 /tank/familia/compartido
```

El bit **setgid** en `compartido` (el `2` de `2775`) hace que los archivos nuevos
conserven el grupo `familia` en vez del grupo primario de quien los crea.

## Usuarios del Proxmox

```bash
groupadd -g 3000 nas
useradd -u 3000 -g nas -M -d /nonexistent -s /usr/sbin/nologin nas
groupadd -g 3002 ricardo   && useradd -u 3002 -g ricardo   -M -d /nonexistent -s /usr/sbin/nologin ricardo
groupadd -g 3003 mariaelena && useradd -u 3003 -g mariaelena -M -d /nonexistent -s /usr/sbin/nologin mariaelena
groupadd -g 3010 familia
usermod -aG familia lucho ricardo mariaelena   # ver nota abajo
```

No hay usuario `lucho` en el Proxmox: su espacio se identifica por el **uid 1000**.
Si se agrega, que sea sólo cosmético y con ese número.

## Servidor NFS

```bash
apt-get install -y --no-install-recommends nfs-kernel-server
```

`/etc/exports`:

```
/tank/familia  192.168.1.11(rw,sync,no_subtree_check,no_root_squash,crossmnt,fsid=1)
/tank/immich   192.168.1.11(rw,sync,no_subtree_check,no_root_squash,fsid=2)
```

- **`crossmnt`** es obligatorio: sin eso la VM ve `familia/` vacío porque los
  espacios de cada persona son datasets hijos, no carpetas.
- **`fsid` explícito**: evita la ambigüedad del pseudo-root de NFSv4 cuando hay
  más de un export.
- **`no_root_squash`**: Samba y restic escriben como root dentro de la VM.
- El export está restringido a la IP de la VM. Ningún otro host del LAN puede
  montarlo.

Recargar y verificar:

```bash
exportfs -ra
exportfs -v
```

## Snapshots con sanoid

Sanoid corre **acá**, no en la VM: es el dueño del pool y los snapshots ZFS no se
pueden crear desde un cliente NFS.

```bash
apt-get install -y --no-install-recommends sanoid
mkdir -p /etc/sanoid
```

`/etc/sanoid/sanoid.conf`:

```
[template_production]
	hourly = 24
	daily = 30
	monthly = 6
	autosnap = yes
	autoprune = yes

[tank/familia]
	use_template = production
	recursive = yes

[tank/immich]
	use_template = production
```

```bash
sanoid --take-snapshots --verbose   # prueba manual
systemctl enable --now sanoid.timer
zfs list -t snapshot -o name,used -r tank
```

Notas:

- `recursive = yes` cubre los datasets hijos de `familia` sin declararlos uno por uno.
- El paquete de Debian trae **`sanoid.timer` y además `/etc/cron.d/sanoid`**. Los dos
  disparan lo mismo; sanoid es idempotente por período, así que no rompe nada, pero
  si molesta conviene comentar el cron y quedarse con el timer.
- Los snapshots **no son backups**: viven en el mismo pool. Protegen de "borré un
  archivo" y de una aplicación que corrompió su biblioteca. Para eso son excelentes
  y cuestan casi nada.

## Lo que vive en el flake, no acá

Todo esto se declara en `hosts/homelab/default.nix` y no debe replicarse a mano:
usuarios y grupos de la VM, montajes NFS (`/mnt/tank/*`), Samba, Immich, Hermes,
los jobs de restic, el firewall y los secretos con sops.

## Lo que todavía falta acá

- **Dump de la configuración del hipervisor.** `/etc/pve` pesa ~8 KB y contiene
  `datacenter.cfg`, el firewall, los mappings y la definición de cada VM. El
  dataset `tank/hypervisor` está creado (modo 0700) pero **todavía no hay un job
  que vuelque la configuración ahí**. Cuando exista, entra al backup con una línea.
- **Contiene material sensible**: `/etc/pve/priv/` incluye `authkey.key` (la clave
  de autenticación del nodo), `shadow.cfg` (hashes de contraseñas) y las claves
  SSL. Por eso el dump vive en un dataset `0700 root:root`, exportado sólo a la
  VM, y viaja **cifrado** dentro de restic. No debe copiarse a ningún lugar
  legible por otros.

## Reconstrucción desde cero

1. Instalar Proxmox en el NVMe con el layout por defecto.
2. `zpool create tank mirror <disco1> <disco2>` con `ashift=12`.
3. Crear los datasets y fijar cuotas y dueños según la tabla de arriba.
4. Crear los usuarios del Proxmox.
5. `apt-get install nfs-kernel-server sanoid`, escribir `/etc/exports` y
   `/etc/sanoid/sanoid.conf`, `exportfs -ra`, habilitar ambos servicios.
6. Crear la VM 100 (OVMF/q35, cpu host, 4 cores, 12 GB, virtio 64G, agente,
   `vmbr0`) e instalar NixOS desde el flake.
7. En la VM: clonar el repo y `nixos-rebuild switch --flake .#homelab`.
8. Restaurar los secretos con la clave `age` de respaldo.
9. Verificar: montajes NFS, escritura en cada share, Immich, y que restic vuelva a
   ver el repositorio de la torre.
