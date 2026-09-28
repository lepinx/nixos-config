# Noctalia: capa declarativa y overrides versionados

Noctalia arma la configuración efectiva en dos capas, y **la segunda siempre
gana**:

| Capa | Archivo | Quién escribe |
| --- | --- | --- |
| Base declarativa | `~/.config/noctalia/config.toml` → symlink al Nix store | Home Manager, desde `modules/home/desktop.nix` |
| Overrides | `~/.local/state/noctalia/settings.toml` → symlink a `configs/noctalia/settings.toml` | La UI de Settings y ediciones a mano |

Noctalia lee primero todos los `*.toml` del config dir y después superpone el
`settings.toml` del state dir. Ese archivo queda fuera del Nix store a propósito,
porque la UI necesita poder escribirlo, y está linkeado a un archivo del repo
para que todo lo que toques en la UI quede versionado.

Noctalia escribe el override resolviendo el symlink, y además vigila con inotify
el directorio destino, así que:

- lo que guardás en la UI se aplica sin rebuild y aparece en `git diff`;
- lo que editás a mano en el repo se recarga en vivo.

## Flujo normal

1. Cambiás algo en la UI de Noctalia (`Win+,` o `noctalia msg settings-open`).
2. Noctalia escribe el override en `configs/noctalia/settings.toml`.
3. `git diff configs/noctalia/settings.toml` te muestra exactamente qué cambió.
4. `git commit`.

Para volver atrás no hace falta rollback del sistema: alcanza con
`git checkout configs/noctalia/settings.toml`. Noctalia recarga solo.

**Regla de oro:** si una clave está en `configs/noctalia/settings.toml`, esa
manda. No la repitas en `programs.noctalia.settings`, porque el valor declarativo
queda muerto y un rebuild parecería no hacer nada.

## Qué vive en la capa declarativa

Todo lo que la UI no toca, porque necesita cálculo en Nix o simplemente no se
ajusta desde la interfaz:

- datos de la shell: fuente, escala, telemetría, agente polkit, apps como
  servicios systemd;
- idle, bloqueo y umbral de batería;
- keybinds de la UI;
- `theme.templates.user.niri`, que necesita el store path de `niri` en el
  `post_hook`;
- `wallpaper.directory`, clima y ubicación;
- plugins.

El resto —dock, layout del lockscreen, wallpaper concreto, y cualquier cosa que
toques desde la UI— vive en `configs/noctalia/settings.toml`.

## Promover un cambio a la capa declarativa

A veces conviene que un valor quede en Nix (por ejemplo, para que se valide en el
build o para parametrizarlo). El pasaje es directo:

```toml
[bar.main]
thickness = 40
padding = 8
start = ["launcher", "workspaces"]
```

se vuelve:

```nix
programs.noctalia.settings.bar.main = {
  thickness = 40;
  padding = 8;
  start = [
    "launcher"
    "workspaces"
  ];
};
```

Reglas:

- tabla TOML `[a.b.c]` → atributo Nix `a.b.c = { ... };`
- strings, booleanos, números y listas se traducen uno a uno;
- las claves con `_` se mantienen igual.

Después de promover, **borrá la clave del TOML**, o vas a crear un valor muerto.

## Migración (una sola vez)

El `settings.toml` del state dir tiene que dejar de ser un archivo real para
pasar a ser el symlink. Home Manager no reemplaza archivos existentes que no
gestiona, así que el orden importa:

```bash
systemctl --user stop noctalia
rm ~/.local/state/noctalia/settings.toml
just switch
systemctl --user start noctalia
```

## Ver y validar la configuración activa

```bash
# Config efectiva, con los overrides ya mezclados
noctalia config export merged

# Config completa, incluyendo defaults de fábrica
noctalia config export full

# Valida la config tal como la carga la shell y reporta claves obsoletas
noctalia config validate

# Solo un archivo
noctalia config validate configs/noctalia/settings.toml

# Recargar, o reiniciar el servicio de usuario
noctalia msg config-reload
systemctl --user restart noctalia
```

`noctalia config validate` sin argumentos avisa cuando una clave quedó obsoleta
o no existe. Corrélo después de tocar la capa declarativa: el módulo de Home
Manager también valida en tiempo de build, pero solo si el paquete está
disponible.

## Clima y ubicación

Noctalia usa una única configuración de ubicación para clima, night light y modo
de tema automático. En este repo vive en la capa declarativa.

Para una PC personal, lo más privado y reproducible es usar una ciudad amplia o
coordenadas aproximadas:

```nix
programs.noctalia.settings = {
  weather = {
    enabled = true;
    refresh_minutes = 30;
    unit = "celsius";
    effects = true;
  };
  location = {
    auto_locate = false;
    address = "Ciudad, País";
  };
};
```

Con `auto_locate = true` Noctalia consulta geolocalización por IP a su propio
servicio. Es lo que está configurado hoy; conviene solo si esa comodidad vale la
pena.

## Notas y límites

- **Nada de comentarios en `configs/noctalia/settings.toml`.** Noctalia reescribe
  el archivo completo al guardar y los pierde. La documentación va acá.
- El TOML versionado incluye estado de máquina: el path absoluto del wallpaper y
  las posiciones de los widgets del lockscreen. Es esperable que cambie seguido.
- `state.toml`, plugins, templates de la comunidad e historial de notificaciones
  siguen siendo estado local en `~/.local/state/noctalia` y no se versionan.
- Los valores de `accessibility.ui_scale` y otros que se ajustan en la UI se
  pueden mover entre capas, pero nunca tienen que estar en las dos.

## Revisión pendiente para Noctalia v5 estable

Cuando Noctalia v5 salga estable, revisar si ya soporta de forma nativa cosas que
hoy resolvemos a mano:

- integración de secretos/launcher, para reemplazar o simplificar `rofi-rbw` +
  `wofi`;
- acciones custom del launcher para buscar secretos, copiar usuario/password,
  autotype con confirmación y abrir URLs asociadas al item;
- un plugin propio de Noctalia para consultar `rbw` sin depender de un launcher
  externo, si la API de plugins lo vuelve cómodo;
- keybinds estilo Vim en launcher y paneles;
- generación de tema desde wallpaper y compatibilidad con Stylix;
- nombres de opciones que hayan cambiado entre la versión actual y v5 estable.
