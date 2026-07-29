# Neovim

Esta configuración usa LazyVim como base y módulos propios en
`configs/nvim/lua/plugins`. La idea es que `nixos-config` tenga el editor base y
que cada repo declare lo específico del proyecto con `devShell`, `direnv` y, si
hace falta, `.nvim.lua`.

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
- `<leader>gd`: abrir Diffview para revisar cambios visualmente.
- `<leader>gD`: cerrar Diffview.
- `<leader>gF`: historial del archivo actual en Diffview.
- `<leader>gR`: historial del repo en Diffview.
- `]h` y `[h`: saltar entre hunks del archivo actual.
- `<leader>ghp`: preview inline del hunk.
- `<leader>ghs`: stage del hunk.
- `<leader>ghr`: reset del hunk.
- `<leader>ghb`: blame de la línea.
- `<leader>ghB`: blame del buffer.

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
