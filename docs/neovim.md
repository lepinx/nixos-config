# Neovim

Esta configuración usa LazyVim como base y módulos propios en
`configs/nvim/lua/plugins`. La idea es que `nixos-config` tenga el editor base y
que cada repo declare lo específico del proyecto con `devShell`, `direnv` y, si
hace falta, `.nvim.lua`.

## Tema

LazyVim usa **Onedark Pro** (`onedark_dark`) vía
`configs/nvim/lua/plugins/theme.lua`, elegido y mantenido a mano. La paleta del
editor no se deriva del wallpaper: Noctalia gobierna los colores del escritorio
y de la terminal, no los del editor. La capa base16/Matugen se eliminó, así que
`:colorscheme` lista solo los schemes de los plugins realmente instalados.

Para comprobar el tema activo: `:lua print(vim.g.colors_name)` debe mostrar
`onedark_dark`.

## Fuente

Neovim no define tipografía: hereda la del emulador de terminal. El default es
Ghostty con **Fantasque Sans Mono Nerd Font** (`FantasqueSansM Nerd Font Mono`
es la familia real; el sufijo `Mono` mantiene los iconos en una sola celda) y
JetBrains Mono como fallback
(`configs/ghostty/config`); Alacritty y
`fonts.fontconfig.defaultFonts.monospace` usan la misma preferencia, así que
`fc-match monospace` tampoco cae en DejaVu. Los paquetes se declaran en
`modules/home/desktop.nix`: cambiar de fuente es un rebuild, no un update de
`lazy.nvim`.

## Búsqueda

Atajos principales de LazyVim:

- `<leader><space>`: buscar archivos.
- `<leader>/`: buscar texto en el proyecto.
- `<leader>,`: buffers abiertos.
- `<leader>:`: historial de comandos.
- `<leader>fb`: buffers.
- `<leader>fg`: archivos git.
- `<leader>fr`: archivos recientes.
- `gr`: referencias del símbolo con LSP.
- `gd`: definición con LSP.

Comandos útiles:

```vim
:Telescope
:Lazy
:Mason
:checkhealth
:messages
:LspLog
```

## Ventanas y Buffers

- `<C-w>v`: split vertical.
- `<C-w>s`: split horizontal.
- `<C-w>h/j/k/l`: moverse entre ventanas.
- `<C-w>=`: igualar tamaños.
- `:bd`: cerrar buffer.
- `:q`: cerrar ventana.
- `<leader>[`: cerrar fold.
- `<leader>]`: abrir fold.

## Git

Flujo recomendado:

- `lazygit`: staging, commits, push/pull.
- `<leader>gg`: abrir lazygit en la raíz git del proyecto.
- `<leader>gG`: abrir lazygit en el cwd actual.
- `<leader>gd`: hunks del working tree en el picker de Snacks (el de todos los días).
- `<leader>gD`: hunks contra `origin`, agrupados por archivo.
- `<leader>gv`: abrir Diffview (working tree o branch completo).
- `<leader>gV`: cerrar Diffview.
- `<leader>gf`: historial del archivo actual en Diffview.
- `<leader>gF`: historial del repo en Diffview.
- `<leader>gs` / `<leader>gS`: status y stash.
- `<leader>gi`, `<leader>gI`, `<leader>gp`, `<leader>gP`: issues y PRs de GitHub
  (requieren `gh` autenticado; son el picker de Snacks, sin plugins extra).
- `]h` y `[h`: saltar entre hunks del archivo actual.
- `<leader>ghp`, `<leader>ghs`, `<leader>ghr`, `<leader>ghb`, `<leader>ghB`: grupo
  `gh` de gitsigns (preview inline, stage, reset, blame de línea y de buffer).
- `<leader>hp`, `<leader>hs`, `<leader>hr`, `<leader>hb`: alias cortos de los
  anteriores.

`lazygit` usa `delta` como pager para tener diffs con mejor color y syntax.

Recursos:

- https://github.com/jesseduffield/lazygit
- https://github.com/dandavison/delta
- https://github.com/sindrets/diffview.nvim
- https://github.com/lewis6991/gitsigns.nvim

## Diagnósticos y LSP

- `<leader>cd`: diagnóstico de la línea.
- `]d` y `[d`: siguiente/anterior diagnóstico.
- `K`: hover.
- `<leader>ca`: code action.
- `<leader>cr`: rename.
- `<leader>cf`: format.

Para errores completos:

```vim
:messages
:LspLog
:lua vim.diagnostic.open_float()
```

## Configuración Por Proyecto

`vim.opt.exrc = true` permite que Neovim cargue `.nvim.lua` desde el proyecto.
Esto encaja con repos que ya usan `.envrc`: `direnv` prepara herramientas y
variables de entorno; `.nvim.lua` prepara comportamiento local del editor.

Por seguridad, confiá solo archivos de repos propios:

```vim
:trust .nvim.lua
```

Usar `.nvim.lua` para cosas específicas del repo:

- comandos locales.
- runtime local de syntax.
- integración con herramientas del `devShell`.

No usar `.nvim.lua` para editor base, temas o keymaps globales.

## Recursos

- https://www.lazyvim.org/
- https://neovim.io/doc/user/usr_toc.html
