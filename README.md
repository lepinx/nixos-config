# nixos-config

Configuración personal y reproducible para NixOS 26.05, Home Manager,
Niri y Noctalia v5. Noctalia Greeter inicia la sesión Niri.

## Uso diario

El perfil diario es `workstation`. El layout de disco usa LUKS + Btrfs:
`/boot` queda como partición EFI sin cifrar y `/`, `/home` y `/nix` viven dentro
de `cryptroot`.

```bash
just check     # evalúa el flake y detecta código Nix sin uso
just build     # construye sin activar
just boot      # deja la generación lista para el próximo arranque
just test      # activa temporalmente hasta el próximo arranque
just switch    # activa y crea una nueva generación
just update    # actualiza flake.lock, pero no activa nada
just rollback  # activa la generación anterior
just history   # muestra generaciones del sistema
just prune-generations 5 # conserva las últimas 5 generaciones y corre GC
```

Los comandos de build usan `--no-link`, por lo que no dejan un symlink
`result` en el repositorio.

Rutina recomendada: actualizar cada una o dos semanas, revisar el diff de
`flake.lock`, ejecutar `just check`, `just build` y finalmente `just switch`.
El timer semanal sólo avisa; nunca modifica ni activa el sistema.

Ejecutar `just switch` con frecuencia es seguro: cada activación crea una
generación recuperable y no modifica parcialmente el sistema si la construcción
falla. Aun así, puede reiniciar servicios y acumular generaciones/objetos hasta
el próximo GC. Durante una edición conviene usar `just build`; usar `just test`
para probar una etapa completa, y `just switch` cuando se quiere conservarla
también para el próximo arranque.

Si se acumulan demasiadas generaciones por rebuilds manuales, se puede limpiar
con `just prune-generations 5` o elegir otro número. Es prudente conservar al
menos 3 generaciones mientras el sistema cambia bastante.

Para cambios de greeter o sesión gráfica, es más prolijo usar `just boot` y
reiniciar. Así la sesión gráfica actual no se corta en caliente.

## Modelo mental

- `flake.nix` declara las fuentes y la composición del sistema.
- `flake.lock` fija revisiones exactas. Sin actualizarlo, los paquetes no avanzan.
- Construir crea una generación nueva; `switch` además la activa.
- NixOS administra hardware, servicios y sesiones.
- Home Manager administra el entorno y archivos del usuario.
- `system.stateVersion` fija la versión de compatibilidad para módulos con
  estado; no indica qué versión de NixOS está ejecutándose y no debe subirse por
  rutina.
- GC elimina generaciones y objetos Nix antiguos. No reemplaza snapshots Btrfs
  ni copias externas de tus datos.

Documentación práctica:

- [Instalación desde ISO](INSTALL.md)
- [LUKS + Disko](docs/luks.md)
- [Secretos](docs/secrets.md)
- [Desarrollo con devShells](docs/development.md)

## Mantenimiento automático

Los timers del sistema viven en `modules/nixos/maintenance.nix`.

- `nix-gc.timer`: corre todos los días y ejecuta GC con
  `--delete-older-than 7d`. Esto borra generaciones de perfiles con más de 7
  días y luego libera objetos del Nix store que ya no estén referenciados.
- `nix-optimise.timer`: corre semanalmente y deduplica archivos iguales dentro
  del Nix store. No borra generaciones.
- `fstrim.timer`: corre semanalmente y avisa al SSD/NVMe qué bloques ya no se
  usan.

`persistent = true` en el GC usa la semántica de timers de systemd: si la
máquina estaba apagada cuando tocaba correr, systemd lo ejecuta al volver a
arrancar. El GC automático conserva historial por edad, no por cantidad; si se
hacen muchas activaciones en un mismo día, pueden acumularse hasta que pasen 7
días. Para limpiar por cantidad existe `just prune-generations 5`.

Comandos útiles para inspeccionar:

```bash
systemctl list-timers 'nix-*' 'fstrim*'
systemctl cat nix-gc.timer nix-gc.service
journalctl -u nix-gc --since '7 days ago'
```

## Recuperación

Si la sesión Niri falla, cambiar a una TTY con `Ctrl+Alt+F2`, iniciar sesión y
ejecutar `just rollback`. Si falla todo el sistema, elegir una generación
anterior en el menú de systemd-boot. La recuperación principal es TTY +
rollback.

## Política de versiones

El sistema sigue `nixos-26.05`. Niri y OpenCode provienen selectivamente de
`nixos-unstable`; Noctalia sigue su rama v5. Esto mantiene estable la base sin
congelar las aplicaciones que evolucionan rápido.

## Login, secretos y Bluetooth

Noctalia Greeter lanza Niri directamente. `gnome-keyring` está disponible y PAM
de greetd lo desbloquea para que aplicaciones como VS Code puedan usar
`gnome-libsecret` sin caer en almacenamiento inseguro.

Bluetooth se activa con BlueZ y se configura para encenderse al arrancar.
WirePlumber limita los perfiles Bluetooth a A2DP para priorizar auriculares de
música estables; esto evita que algunos modelos caigan al negociar Hands-Free.
La consecuencia deliberada es que el micrófono Bluetooth HFP permanece
desactivado en este perfil. Si el adaptador queda bloqueado manualmente por
rfkill, se puede recuperar con:

```bash
rfkill unblock bluetooth
bluetoothctl power on
```

## Navegadores

Firefox es el navegador predeterminado para HTTP/HTTPS y HTML. Helium queda
instalado como alternativa Chromium para pruebas puntuales de motor. Se evita
Google Chrome en el perfil diario para no depender de su manejo de sesión bajo
Niri/Noctalia. El repositorio no contiene perfiles, sesiones, cookies,
contraseñas ni datos de wallets.

## Dónde agregar paquetes

- `modules/nixos/packages.nix`: componentes compartidos por toda la máquina,
  programas con políticas globales y herramientas necesarias antes del login.
- `modules/home/*.nix`: aplicaciones, fuentes y herramientas del usuario de
  Home Manager. Elegir el módulo por función: escritorio, editores, shell o
  desarrollo.
- `devShell` de cada proyecto: compiladores, runtimes, bases de datos y
  formatters ligados al proyecto.

Aplicaciones personales como Ente Auth, Bitwarden CLI, Bruno, DBeaver,
LocalSend y las fuentes Nerd Font se administran desde `modules/home/desktop.nix`.
El perfil prefiere aplicaciones instaladas desde Nix/Home Manager y deja fuera
instaladores manuales, AppImages y Flatpaks.

La gestión de credenciales usa la extensión del navegador y `bitwarden-cli`.

## Desarrollo y containers

Podman es el runtime de containers del sistema. `docker` queda como alias de
`podman` para compatibilidad CLI, y `podman-compose` cubre stacks locales de
bases de datos. El socket Docker-compatible queda desactivado por defecto porque
requiere dar permisos equivalentes a Docker; se puede evaluar si VS Code
Dev Containers lo necesita de verdad.

Los runtimes, linters y CLIs específicos viven en `devShell`/`direnv` por
repositorio. El perfil global conserva sólo herramientas transversales de uso
diario.

## Editores

Zed y Neovim se configuran en `configs/zed` y `configs/nvim`. Neovim usa una
configuración chica propia; sus plugins y language servers se instalan desde
Nix/Home Manager para evitar descargas y actualizaciones al abrir el editor.

VS Code usa un modelo híbrido. Home Manager instala la aplicación, fuerza el
keyring seguro con `gnome-libsecret` y enlaza `settings.json`,
`keybindings.json` y snippets desde `configs/vscode` como symlinks mutables
fuera del store de Nix. Así quedan versionados por Git, pero VS Code puede
escribirlos sin chocar con archivos read-only. Las extensiones quedan a cargo de
VS Code Settings Sync; credenciales, conexiones SQL, hosts SSH, cachés,
perfiles, sesiones y estado quedan fuera del repositorio.

## Git y archivos generados

El ignore global vive en `configs/git/ignore`. Excluye secretos locales,
resultados de builds Nix, archivos de direnv y temporales habituales. No ignora
`.env.example`, porque ese archivo suele formar parte de la documentación de un
proyecto. Yazi aporta su propio launcher XDG; no se lo asigna como manejador
predeterminado de directorios.

La identidad de Git no se versiona. Home Manager incluye `~/.gitconfig.local`
desde la configuración global de Git; crear ese archivo localmente usando
`configs/git/gitconfig.local.example` como referencia.

## Configuración visual

- Niri se configura en la plantilla `configs/niri/config.kdl.in`; Home Manager
  genera el archivo final `~/.config/niri/config.kdl`.
- La barra, tema, escala, wallpaper y Dock de Noctalia se declaran en
  `modules/home/desktop.nix`.
- La barra ocupa todo el ancho, mantiene el reloj centrado y oculta multimedia,
  Bluetooth y notificaciones cuando no tienen información útil.
- La interfaz de Noctalia permite probar cambios, pero los guarda como
  sobrescrituras mutables en `~/.local/state/noctalia/settings.toml`; ese archivo
  no pertenece al repositorio. Una vez elegido un cambio permanente, debe
  trasladarse al módulo de Home Manager para que aparezca en `git diff`.
- El wallpaper seleccionado, historiales y cachés son estado local deliberado y
  no se versionan.

## Energía y bloqueo

Noctalia bloquea la sesión tras 10 minutos de inactividad, apaga las pantallas
al minuto siguiente y suspende el equipo a los 30 minutos. La actividad vuelve
a encender las pantallas. El modo Caffeine de Noctalia inhibe temporalmente
estas acciones, por ejemplo durante una presentación o una descarga larga.

El perfil de energía se ajusta automáticamente para notebook: `performance`
cuando está enchufada y `balanced` cuando está en batería. Esto conserva la
respuesta rápida al abrir aplicaciones sin castigar autonomía/calor todo el día.

## Atajos de Niri

Los bindings se versionan en `configs/niri/config.kdl.in`. El resumen vivo se
abre con `Mod+Shift+/`, `just hotkeys` o `nixcfg hotkeys`. La documentación corta
queda en [Atajos](docs/keybindings.md).

Flechas y HJKL cubren la navegación. En los aliases con flechas, `Shift` mueve
ventanas, `Ctrl` navega monitores y `Ctrl+Shift` mueve columnas entre monitores.
`Win` más la rueda cambia de workspace. `Win+W` alterna columnas tabbed y
`Win+C` centra la columna. `Win+[` y `Win+]` incorporan o expulsan la ventana
enfocada de la columna vecina, permitiendo apilar ventanas verticalmente. Llevar
el puntero a una esquina superior abre el overview mediante los hot corners de
Niri.

## Post-instalación

La validación post-instalación cubre greeter, secretos declarativos y
capacidades opcionales.

Después de cambios de arranque, LUKS o greeter, validar:

```bash
just switch
reboot
powerprofilesctl get
firefox
ghostty
zeditor
systemctl --failed
systemctl --user --failed
```

La reinstalación desde ISO queda documentada en [INSTALL.md](INSTALL.md). El
mantenimiento de LUKS, TPM2 + PIN y passphrases queda en [LUKS + TPM2](docs/luks.md).

## Docs rápidas

- [Bluetooth troubleshooting](docs/bluetooth.md)
- [NetworkManager y VPN](docs/network.md)
- [Atajos](docs/keybindings.md)
- [Noctalia: cambios en vivo](docs/noctalia.md)
- [Energía, suspend y wakeup USB](docs/power.md)
- [Recuperación local](docs/recovery.md)
- [Instalación desde ISO](INSTALL.md)
- [LUKS + TPM2](docs/luks.md)
- [Secretos](docs/secrets.md)
