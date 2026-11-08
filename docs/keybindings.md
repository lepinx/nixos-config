# Atajos

La fuente principal para los atajos globales es la cheatsheet de Umbriel:

```bash
just hotkeys
```

o desde cualquier directorio:

```bash
nixcfg hotkeys
```

También se puede abrir directamente con `Mod+Shift+/`.

## Fuentes vivas

- Sistema y ventanas: `configs/umbriel/config.toml`
- Terminal Ghostty: `configs/ghostty/config`
- Multiplexer Herdr: `~/.config/herdr/config.toml`
- Neovim: `configs/nvim/lua/config/keymaps.lua`
- Shell Fish: `modules/home/shell.nix`

## Criterio

Umbriel cubre los atajos globales del escritorio: lanzar apps, mover ventanas,
cambiar workspaces, screenshots, media y brillo. Los atajos internos de cada
aplicación viven en su propia config para evitar duplicación.

`Mod+Enter` abre Ghostty con la sesión persistente default de Herdr.
`Mod+Shift+Enter` abre una sesión persistente separada,
`alternative-workspace`, para trabajo paralelo que no debe quedar atado al
workspace principal.

Para mantener esta documentación fresca, no se duplica toda la tabla de binds
acá. El resumen vivo es el overlay de Umbriel y los archivos anteriores son la
referencia versionada.

## Salidas de emergencia

Cuando la ventana activa deja de responder a sus propios atajos, estos binds
siguen funcionando porque actúan sobre Umbriel y no sobre la aplicación:

| Atajo | Acción | Cuándo usarlo |
|---|---|---|
| `Mod+Shift+F` | `window-toggle-fullscreen` | La ventana quedó en fullscreen y no sale con `Escape` ni `F11` |
| `Mod+Q` | `window-close` | La aplicación quedó inutilizable y hay que terminarla |
| `Mod+Escape` | `shortcuts-inhibit-toggle` | Una app retuvo el teclado y los atajos del compositor no llegan |
| `Mod+Backspace` | `window-toggle-maximize` | La ventana quedó maximizada de forma incorrecta |

### Fullscreen pegado en un navegador

En Wayland el fullscreen tiene dos capas: el pedido del documento (Fullscreen
API) y el estado que posee el compositor. Si un link externo abre una pestaña
nueva en una ventana que ya estaba en fullscreen de video, las capas se
desincronizan. `Escape` y `F11` actúan sobre el documento visible, que nunca
pidió fullscreen, así que no hacen nada, y Umbriel mantiene la ventana en
pantalla completa.

`Mod+Shift+F` lo resuelve porque habla con la capa que sí tiene autoridad. No
hace falta cerrar el navegador: la pestaña del video sigue viva y el estado se
conserva.

No es exclusivo de Firefox. Los navegadores basados en Chromium muestran el
mismo desfase en Wayland, con el mismo disparador.
