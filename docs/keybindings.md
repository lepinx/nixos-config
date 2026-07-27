# Atajos

La fuente principal para los atajos globales es el overlay de Niri:

```bash
just hotkeys
```

o desde cualquier directorio:

```bash
nixcfg hotkeys
```

También se puede abrir directamente con `Mod+Shift+/`.

## Fuentes vivas

- Sistema y ventanas: `configs/niri/config.kdl.in`
- Terminal Ghostty: `configs/ghostty/config`
- Multiplexer Herdr: `~/.config/herdr/config.toml`
- Neovim: `configs/nvim/lua/config/keymaps.lua`
- Zed: `configs/zed/keymap.json`
- VS Code: `configs/vscode/keybindings.json`
- Shell Fish: `modules/home/shell.nix`

## Criterio

Niri cubre los atajos globales del escritorio: lanzar apps, mover ventanas,
cambiar workspaces, screenshots, media y brillo. Los atajos internos de cada
aplicación viven en su propia config para evitar duplicación.

Para mantener esta documentación fresca, no se duplica toda la tabla de binds
acá. El resumen vivo es el overlay de Niri y los archivos anteriores son la
referencia versionada.
