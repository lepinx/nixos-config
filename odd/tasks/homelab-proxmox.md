# Homelab Proxmox — migración de la torre a infraestructura virtualizada

Proxmox en Aoostar WTR Pro (16 cores, 30 GiB RAM, 2 NICs, SSD 1TB +
2x HDD 4TB mirror, zpool ya creado). VM NixOS como server principal, Pangolin para exposición
pública, CrowdSec como seguridad, nube familiar (fotos/videos/backups).
Torre Ubuntu vieja → backups + laboratorio. Referencias: hosts/homelab/,
hosts/homelab/README.md, memoria obs 249/250/257/291.

## Specs

- S1: "Proxmox instalado en el SSD de 1TB, zpool ya creado (tank/datos);
  reveer esa parte para hacer un dataset por consumidor, o mientras
  vayamos instalando cada cosa."
- S2: "VM de NixOS como server principal" en Proxmox; `nixosConfigurations.homelab`
  reescrito para el perfil VM: ESP 1G + ext4 root en /dev/vda, red ens18,
  sin LUKS.
- S3: "usar pangolin para vpn interna y tambien para servicios web o cosas
  publicas de forma segura" — Pangolin en la VM NixOS (hay IP pública real);
  port-forward 80/443 del router ADSL; 51820/UDP queda para WireGuard personal.
  Aclaración del usuario (L7): el port-forward es el transporte, no la política
  de exposición — Pangolin rutea recursos públicos y privados por separado, así
  que reenviar 80/443 no publica nada por sí mismo; cada recurso decide si
  exige autenticación o queda abierto.
- S4: "configurar crowdsec tambien como seguridad (capaz es mejor eso que
  fail2ban)" — CrowdSec decidido (LAPI en VM NixOS, bouncers nftables en
  NixOS + Proxmox).
- S5: Router virtualizado (OPNsense, el WTR Pro tiene 2 NICs) **deferido**:
  se decide más adelante, no bloquea el resto.
- S6: "tener backups.. mi nube completa propia": Immich (fotos familia),
  Jellyfin (videos), Samba; backups con restic hacia la torre vieja.
- S7: "migrar las cosas que tengo ahi (Ubuntu: AdGuard, Hermes gateway,
  Docker) al nuevo servidor y ese usarlo tal vez como backups.. y como otro
  juguete para experimentar".
- S8: Red: Proxmox en 192.168.1.10 (estático), DHCP del router .100-.254;
  definir plan de IPs para VMs y torre.
- S9: Auditoría de todo lo ya configurado en Proxmox (instalación + zpool)
  antes de avanzar.

## Tasks

- T1 (S9): auditoría del Proxmox: version, config de red, zpool status/layout,
  storage.cfg. [route: inline, user runs audit script] [commit: —]
  Estado: cerrada — ashift=12 correcto, autotrim off (HDD, correcto),
  autoexpand off. Faltaba timer de scrub ZFS (solo hay e2scrub/xfs_scrub):
  user debe habilitar zfs-scrub-monthly@tank.timer. Flag SMR corregido:
  los discos son CMR, ver T3.
  Sin commit propio de código: el resultado quedó registrado en este ODD
  (4249ee1). Host verificado: 16 cores, 30 GiB RAM.
- T2 (S8): plan de IPs estático documentado (rango infra .2-.99, VMs, torre).
  [route: inline] [commit: b0840ec]
  Estado: hecha — hosts/README.md con tabla LAN, commiteada en b0840ec
  (retarget del host homelab); retoques posteriores en b9ebb04.
- T3 (S1): reestructurar el zpool: dataset por consumidor
  (tank/immich, tank/familia, tank/backups), migrar tank/datos. [inline/SSH]
  Estado: hecha — tank/datos (vacío) destruido; datasets creados. Timer
  zfs-scrub-monthly@tank habilitado por el usuario.
  Dato de discos (2026-11-09, corregido): los discos del mirror son **CMR**,
  no SMR — la afirmación previa de SMR fue una suposición sin verificar
  (confusión por el sufijo del modelo) y se retracta. Verificado dos veces:
  (a) identify data del disco (`WDC WD40EFZZ-68CPAN0`, 5400 rpm, 3.5
  pulgadas, SATA 6Gb/s, sin TRIM reportado — la señal habitual de SMR,
  aquí ausente);
  (b) la datasheet oficial de WD Red Plus lista `WD40EFZZ` con
  *Recording technology: CMR*. Los WD Red SMR son la familia **EFAX**
  (WD20EFAX, WD30EFAX, WD40EFAX, WD60EFAX). Consecuencia: no se devuelve
  ningún disco y no se compra ninguno — el mirror queda con los 2x WD40EFZZ
  CMR (un WD40EFPX solo diferiría en caché, 256MB vs 128MB, no vale la
  pena). Estado actual: `tank` ONLINE, mirror-0, ashift=12, autoexpand off,
  autotrim off; scrub último 2026-11-08 con 0 errores; datasets
  tank/immich, tank/familia, tank/backups vacíos, 3.51T disponibles.
  **`tank` NO está congelado**: la restricción previa de no escribir en
  `tank` hasta que lleguen CMR queda sin efecto y se elimina. Sin commit
  (operación sobre el host).
- T4 (S2): crear la VM NixOS en Proxmox (EFI/OVMF, 4-6 vCPU, 8-12 GB RAM,
  disco virtio 40-80 GB en el SSD). [route: user GUI/CLI + guía]
  Estado: hecha — VM creada (qm create 100: cpu host, 4
  cores, 12 GB, virtio 64G discard, agent, ISO minimal 26.11); el
  bootstrap del sistema quedó registrado en T6. Hardware verificado:
  VM 100 = 4 cores / 12 GiB / disco 64 GiB.
- T5 (S2): reescribir hosts/homelab para perfil VM (sin disko LUKS/TPM2,
  boot EFI virtio, sin stack de escritorio) hasta que
  `nix build .#nixosConfigurations.homelab` compile. [route: inline ODD]
  Estado: hecha — default.nix/disko.nix/hardware-configuration.nix
  reescritos (ESP 1G + ext4 root en /dev/vda, ens18 con IP .11, firewall
  22/80/443 + 51820, perfil qemu-guest); samba.nix eliminada (T9 la
  recrea sobre el mount de tank); READMEs actualizados. Verificado con
  `nix eval` del toplevel (EVAL_OK). Bug latente corregido: el diseño
  anterior dejaba SSH inaccesible (openFirewall=false sin puerto 22 en
  la allowlist). Commiteada en b0840ec.
- T6 (S2): bootstrap del sistema en la VM (nixos-install desde ISO con el
  flake). [route: user + guía]
  Estado: hecha — disko + nixos-install corrieron en la sesión live (con
  NIX_CONFIG experimental-features), la VM reinició de vuelta al ISO por
  boot order (ide2 primero, ISO enganchada) — se remontó por consola,
  password de lucho seteada vía chroot live, ISO desmontada y boot desde
  disco OK. ssh lucho@192.168.1.11 operativo. Registro commiteado en
  21f0814.
- T7 (S3): Pangolin en la VM NixOS (nativo si está empaquetado en nixpkgs,
  si no podman), port-forward 80/443, dominio home.pinol.dev. [inline ODD]
  Estado: desbloqueada — el modelo de exposición quedó fijado (S3 + L7): se
  reenvía 80/443 en el router y la exposición se decide por recurso en
  Pangolin (público vs privado con auth). Incluye corregir el comentario del
  firewall en hosts/homelab/default.nix y la sección "Exposición de red" del
  README, que afirmaban que nada se reenvía nunca.
- T8 (S4): CrowdSec + bouncer nftables en NixOS; bouncer en Proxmox. [inline]
- T9 (S6): montaje del pool en la VM (virtiofs o NFS) + datasets por servicio.
  [inline] [commit: ab062a8]
  Estado: hecha — `/tank/immich` y `/tank/familia` montados por NFS 4.2 desde
  192.168.1.10 en `/mnt/tank/{immich,familia}`
  (hosts/homelab/default.nix:32-60); el export vive en el hipervisor
  (docs/proxmox.md, receta de `/etc/exports`).
- T10 (S6): Immich (fotos familia) con datos en tank/immich. [inline]
  [commit: 5dee442]
  Estado: hecha — `services.immich` con `mediaLocation = "/mnt/tank/immich"`
  (hosts/homelab/default.nix:268-281); se toma immich 2.7.5 de
  nixpkgs-unstable porque el paquete del nixpkgs fijado está marcado inseguro;
  uid/gid 3011 alineados con el dataset.
- T11 (S6): Jellyfin con datos en tank/familia. [inline]
- T12 (S6): restic server en la torre + job de backup nocturno desde la VM.
  [inline + torre] [commit: ab062a8]
  Estado: hecha — dos jobs restic (`homelab` y `nas`) con repository
  `sftp:tower:/srv/data/restic/homelab` y password desde sops
  (hosts/homelab/default.nix:98-175). Corrección: el destino es la torre vieja
  por sftp sobre `lucho@192.168.1.50:2222`, **no** `tank/backups`; ese dataset
  existe y sigue sin uso.
- T13 (S7): migración AdGuard + Hermes gateway desde la torre a la VM.
  [inline]
  Estado: inventario de la torre completado (2026-11-09). Host `pinocloud`
  192.168.1.50, Ubuntu, 2 cores, 7.6 GiB RAM; root en LVM SSD (104G usados
  de 218G) + /srv/data en HDD de 931G (34G usados, con un único
  `migration-backup-20261010` manual). 12 contenedores corriendo / 11
  compose projects bajo /srv/docker/<service>/compose.yml: traefik (dueño
  de :80/:443), cloudflared, adguard-home (:53), wg-easy (:51820/udp),
  cloudreve (~24.29GB de datos en volumen docker), homarr, uptime-kuma,
  netdata, hermes, postgres, redis, arcane (:3552). 13 stacks en staging
  SIN correr y sin imagen pulleada: ddns-updater, filebrowser, gotify,
  linkwarden (99M de datos locales), nextcloud, npm, pihole, portainer,
  rabbitmq, redis, syncthing (89M locales), vaultwarden, windows, más
  mssql y mysql dentro de databases/. Edge: Traefik con entrypoints 80/443,
  ACME por Cloudflare DNS-01, certs para ${PINOCLOUD_PUBLIC} con SANs
  *.PINOCLOUD_PUBLIC y *.PINOCLOUD_LOCAL; providers `docker`
  (exposedByDefault false) y `file` con solo 2 routers manuales
  (traefik-dashboard, openwrt) — el ruteo es casi todo por labels de
  docker. CrowdSec corre a nivel host con crowdsec-firewall-bouncer
  (firewalld/nftables); existe CROWDSEC_API_KEY en env pero NO hay
  sección del plugin crowdsec en traefik.yml. NO existe ningún job de
  backup: crontab vacío, sin restic, solo cron.daily del SO; la única
  salvaguarda es el migration-backup-20261010 manual. Los secrets viven
  en .env por stack (CF_EMAIL, CF_DNS_API_TOKEN, CROWDSEC_API_KEY,
  CLOUDFLARED_TOKEN, PINOCLOUD_LOCAL, PINOCLOUD_PUBLIC); sus valores no
  se leyeron a propósito; el repo aún no tiene input de sops-nix/agenix.
  Pendiente abierto: 104G usados en / vs ~36G que reporta
  `docker system df`; ~82G viven en /var/lib/docker solo-legible-por-root,
  ilegible para el usuario de automatización → auditar capas/volúmenes
  huérfanos antes de migrar.
  Avance (2026-11-10): Hermes ya corre nativo en la VM con credenciales desde
  sops (691b19c, a2690e5), así que no se migra ese contenedor; AdGuard sigue
  pendiente del mismo bloqueo.
  Avance (2026-11-12): AdGuard Home declarado nativo en la VM
  (`services.adguardhome`: upstreams 1.1.1.1/9.9.9.9, UI en 3000, DNS en
  53/tcp+53/udp abierto en el firewall, `mutableSettings` para que la
  credencial de admin viva solo en el host y no en el repo público). Falta
  desplegarlo y cambiar el DNS del DHCP del router a .11.
  Hallazgo (2026-11-12): la LAN quedó SIN DNS propio — los 12 contenedores de
  la torre están exited (traefik, adguard-home, wg-easy incluidos), así que
  sólo escucha 2222/ssh y 68/dhcp. Y el payload familiar NO está migrado: en
  la VM `/mnt/tank/familia` suma 159 bytes (esqueleto vacío con
  `cloudreve-legacy/{avatar,temp,uploads}` y un `conf.ini`) y
  `/mnt/tank/immich` 36K; los archivos siguen sólo en
  `/srv/data/migration-backup-20261010/docker-volumes/cloudreve.tar`
  (23,2 GB, `root:root` 644).
- T14 (S7): rol final de la torre: backups + laboratorio (decidir siempre
  encendida vs WOL nocturno). [decision + config]
  Estado: el usuario quiere reinstalarla con NixOS desde cero y dejar los
  backups andando. Decisiones del 2026-11-12: se **descarta la historia del
  repo restic** (12G en `/srv/data/restic`) y se arranca uno nuevo en la
  torre reinstalada; el rol “laboratorio” sigue sin decidir. Prerrequisitos
  antes de formatear: rescatar el payload familiar (cloudreve.tar) y los
  secretos (ver T13/T21). No existe todavía un `hosts/tower` en el repo:
  hay que escribir el perfil bare-metal (el diseño viejo con disko+LUKS
  sigue en el historial de git).
- T15 (acceso/herramientas): llave ed25519 de automatización dedicada (sin
  passphrase) instalada en lucho@192.168.1.50:2222 y lucho@192.168.1.11;
  Proxmox se maneja por ahora como root@192.168.1.10, con token API de
  solo lectura PVEAuditor como camino previsto en lugar de SSH root.
  [inline]
  Estado: pendiente la restricción `from="192.168.1.0/24"` en la línea
  de authorized_keys.
- T16 (S2): la VM NixOS tiene /etc/nixos VACÍO (sin flake ni clone de git):
  hoy solo puede reconstruirse desde la workstation vía --target-host.
  [inline]
  Estado: gap a cerrar — clonar el repo dentro de la VM para poder
  reconstruir localmente.
- T17 (S7): triage de los 25 stacks de la torre.
  [decision + user]
  Estado: triage resuelto en parte (2026-11-09). `vaultwarden` descartado
  y eliminado: el directorio solo tenía un compose.yml de 761 bytes, sin
  datos, sin imagen y sin volumen; el usuario usa Bitwarden en la nube y
  nada de ahí estaba vigente — /srv/docker/vaultwarden fue borrado
  (reversible: el compose sigue dentro del backup de migración).
  `syncthing` descartado (el usuario no lo usa): su directorio conserva
  ~89 MB de datos + config, nada borrado — pendiente decidir si esos 89 MB
  se borran también. `mysql` y `mssql` muertos: un grep sobre los compose
  de todos los stacks no encontró ninguna otra referencia a mysql,
  mariadb, mssql, puerto 3306 o puerto 1433; el volumen anónimo docker de
  86 MB sospechado de ser una de esas bds en realidad pertenece a
  `postgres-db`. Aún esperando confirmación del usuario: linkwarden
  (~99 MB), nextcloud, gotify, ddns-updater, filebrowser, rabbitmq,
  redis, npm, pihole, portainer, windows.
- T18 (backups): definir e implementar un backup real antes de mover
  cualquier dato (hoy no existe ninguno). [inline + torre]
- T19 (secrets): adoptar un almacén de secrets (sops-nix o agenix) antes
  de mover declarativamente cualquier servicio. [inline] [commit: 8625fe5]
  Estado: hecha — sops-nix adoptado: input de flake, módulo en
  hosts/homelab/default.nix:14, `.sops.yaml`, `sops/homelab.yaml` cifrado con
  age sobre la host key ed25519, y `docs/secrets.md` reescrito con la política.
- T20 (NAS): NAS **nativo NixOS, no TrueNAS** (en línea con L1/L2: ZFS
  gestionado por el host Proxmox). Requerimiento del usuario: NAS para
  compartir con la familia y que las fotos/videos sacados con el celular
  se guarden en el NAS. Dirección: **Immich** para fotos/videos (su app
  móvil hace auto-upload en segundo plano, que es el requisito de que las
  fotos del celular aterricen en el NAS) + **Samba** para shares de archivos
  familiares; un share SMB solo no resuelve el caso del upload desde el
  teléfono. [inline] [commit: 5dee442]
  Estado: hecha — Samba nativo con un share `personal` que resuelve
  `/mnt/tank/familia/%U` (una sola URL para todos, sin `[homes]`) más los
  shares por integrante y `compartido` en grupo `familia` (2775)
  (hosts/homelab/default.nix:206-275); el auto-upload del celular lo cubre
  Immich, no SMB.
- T21 (backup): inventario del backup de migración de Cloudreve en la
  torre, /srv/data/migration-backup-20261010: backup bien formado, con
  MANIFEST.md, checksums.sha256 y procedimiento de restore. Contenido
  clave: docker-volumes/cloudreve.tar 22 GB = archivos de usuario de
  Cloudreve (los datos familiares a mover, Cloudreve no se va a usar);
  docker-volumes/arcane-backups.tar 9.3 GB = copia comprimida vieja
  (abril 2026) de esos mismos archivos de Cloudreve, redundante,
  recuperable; adguard-home-root.tar 1.8 GB (casi todo query logs);
  postgres-anon-b89eecbd.tar 83 MB = datos postgres en volumen anónimo;
  wg-easy_etc_wireguard.tar = las claves WireGuard; srv-docker.tar.zst
  577 MB = todo el árbol /srv/docker, incluidos los 12 .env y
  traefik/acme.json; más tars de home/, home-extras/ y system/. Riesgo
  abierto: el backup vive en un único disco giratorio sin redundancia y
  contiene claves y credenciales privadas — home/ssh.tar.gz (claves SSH
  privadas), home-extras/tool-creds.tar.gz (~/.engram, credenciales de
  registry ~/.docker) y los 12 .env. El propio MANIFEST advierte que el
  subconjunto irreemplazable (env, acme.json, npm/letsencrypt, claves
  wg-easy, ~/.engram, ssh) pesa menos de 100 MB y debería copiarse fuera
  de la máquina. Los tars con credenciales no se abrieron a propósito.
  [torre]
  Confirmado 2026-11-12: es la única copia. El NAS nuevo no tiene el payload
  (159 bytes en `/tank/familia`, 36K en `/tank/immich`), así que formatear la
  torre destruye los 23,2 GB de archivos familiares hasta que se extraigan.
  El repo restic de la torre (12G) sí es descartable por decisión del usuario:
  contiene una copia de lo que ya vive en la VM más la config, no el payload.

## Log

- L1 (2026-10-31, request original): "Estoy por instalar en mi nueva homelab
  (aoostar wtr pro, tengo 1tb de ssd, donde tengo pensado instalar proxmox,
  en una vm un nixos como server principal, tambien usar pangolin para vpn
  interna y tambien para servicios web o cosas publicas de feorma segura)
  configurar crowdsec tambien como seguridad (capaz es mejor eso que
  fail2ban), otra vm para opensense como router.. tengo 2 bahias discos hdd
  redgate de 4tb cada una.. pensaba un raid1 para luego usar como un samba o
  nas como truenas..." (decisión NAS: ZFS en host Proxmox, sin TrueNAS; RAM
  32+; IP pública real confirmada).
- L2 (2026-10-31): "acabo de adelantarme ya se termino de instalar proxmox...
  cree un zpool y tambien un tank/datos.. quiero auditar todo lo que tengo
  hasta ahora". IP Proxmox: 192.168.1.10, DHCP .100-.254. Surge pedido de
  roadmap ODD y preguntas de arquitectura (VM vs contenedor, manejo de
  Proxmox por SSH, estrategia de backups en la torre).
- L3 (2026-11-09, discos): "Todavia no devolvi nada.. Los puedo comprar
  ahora, pero voy a tener que esperar unos dias hasta que lleguen...
  podemos seguir con otras cosas que no sea esto? los demas servicios que
  tengo en el otro homelab?"
  Y sobre arquitectura: "Me gustaria ir con Pangolin.. Te consulto Dokploy
  sirve para esta config? o ya lo tengo en pangolin.. no se como armar en
  tecnologias mi homelab.. estoy indeciso"
  Decisión: el reemplazo de discos (CMR) queda bloqueado a la espera de la
  compra; `tank` congelado para escrituras (ver T3). Mientras tanto se
  avanza con servicios: se hace el inventario de la torre (T13) y el
  triage de stacks (T17). Preferencia reconfirmada por Pangolin (en línea
  con S3); pregunta sobre si Dokploy aplica a esta config queda abierta
  para evaluar, sin decisión tomada.
- L4 (2026-11-09, acceso): "Tengo que crear llaves ssh asi podes entrar a
  los servidores asi aceleramos la configuracion"
  Decisiones: (1) llave de automatización dedicada en vez de una personal;
  (2) Proxmox por token API de solo lectura (PVEAuditor) a futuro, no SSH
  root; (3) inventariar la torre antes de migrar; (4) triagear el catálogo
  de stacks antes de migrar nada. Resultado: T15 (acceso), T13 (inventario
  de la torre) y T17 (triage) se abren/ejecutan a partir de esto.
- L5 (2026-11-09, discos y triage): "Me dijiste la otra vuelta que eran
  discos SMR, no CMR.. pero parece que los que tengo si son CMR, porque la
  otra vuelta me dijiste que eran SMR? y que debia cambiarlos??"
  Decisiones y hechos (no son citas): la afirmación previa de que los
  discos eran SMR se retracta como aserción no verificada; verificado que
  son CMR (identify data + datasheet WD Red Plus, ver T3); no se devuelve
  ningún disco ni se compra ninguno; `tank` deja de estar congelado.
  Triage: vaultwarden descartado y eliminado; syncthing descartado;
  mysql/mssql confirmados sin uso (ver T17).
- L6 (2026-11-09, NAS): "Actualmente tengo bitwarden en la nube.. nada de
  lo que tengo en vaultwarden esta actualizado.. borralo nomas.. syncthing
  no lo estoy usando.. las bds mysql/mssql no se si lo usa algun
  contenedor en especifico.. pero lo que mas me importa es mover el backup que
  hice de cloudreve (que no lo voy a usar) creo que habiamos quedado en
  NAS nativo de nixos.. y no truenas no? quiero un nas, para compartir con
  la familia y que las cosas que saque con mi celular, fotos videos se
  guarden en el NAS..."
  Decisión (no es cita): el NAS queda nativo NixOS (sin TrueNAS) con
  Immich (fotos/videos, auto-upload desde el celular) + Samba para shares
  familiares; dirección registrada en T20 y contenido/riesgos del backup
  en T21.
- L7 (2026-11-11, exposición): "A ver solo te quiero informar, que si hay
  que forwardear los puertos.. pero eso no necesariamente quiere decir que
  todo va a ir publico, pangolin tiene para rutear servicios tanto publicos
  como privados.. no?"
  Decisión (no es cita): el port-forward 80/443 queda como parte del diseño
  (S3/T7) y la exposición se decide por recurso en Pangolin, público o privado
  con autenticación. Se corrigen en consecuencia el comentario del firewall de
  hosts/homelab/default.nix y la sección "Exposición de red" del README.
  Resumen de la sesión: se reconciliaron los estados del documento con main
  (T9/T10/T12/T19/T20 ya estaban implementadas sin marcar).
- L8 (2026-11-12, Dokploy, tower y AdGuard): "Creo que no entra dokploy.. te
  acordas todo lo que hablamos? de ci/cd en nixos.. estuvimos hablando de
  esto, arcane tambien.. pero es de contenedores.. nosotros tenemos nativo en
  nixos.. Podes buscar todo lo que hablamos? En que estado esta el homelab
  nuevo y el viejo? Quiero saber si el otro falta migrar algo, porque me
  gustaria instalarle de nuevo nixos y dejarlo 0km con los backups andando y
  seguir configurando el homelab nuevo, con pangolin etc... configurar
  immich, el samba ya estaria creo.. quiero saber el panorama completo"
  Más tarde: "Los datos ya los tengo en el homelab nuevo no? el backup ni
  importa si ya tengo todo en el nuevo.. la historia da igual (solo para
  estar seguro)".
  Decisiones (no son citas):
  (1) **Dokploy descartado** y con eso se cierra la pregunta abierta de L3:
  el despliegue acá es `nixos-rebuild switch` sobre un flake, y Dokploy o
  Arcane asumen compose como unidad de despliegue; lo container-only real se
  reduce a pocas excepciones declaradas. CI = `nix flake check`/build, CD =
  rebuild con `--target-host` (depende de T16).
  (2) **Historia del repo restic descartada**; repo nuevo en la torre
  reinstalada (T14). Se avisó el costo: entre el wipe y la torre nueva no hay
  backup fuera de la VM.
  (3) **AdGuard Home pasa a ser nativo en la VM** (T13), próximo paso de
  implementación.
  Corrección de un supuesto del usuario, con evidencia: el payload familiar NO
  está en el homelab nuevo; “la historia da igual” aplica al repo restic, no
  a los 23,2 GB de archivos de Cloudreve, que siguen únicamente en la torre.
  No se encontró en memoria ningún registro previo de la conversación de
  CI/CD en NixOS: sólo la pregunta abierta de L3 sobre Dokploy.
