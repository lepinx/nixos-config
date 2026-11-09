# Teclado

Layout inglés único, sin switch. Los acentos y la ñ se escriben con un segundo
modificador en vez de cambiar de layout.

## Configuración

Todo vive en `configs/umbriel/config.toml`, sección `[input.keyboard]`:

```toml
[input.keyboard]
layout = "us"
variant = "altgr-intl"
options = "lv3:caps_switch"
numlock_toggle = true
```

- `layout = "us"` con `variant = "altgr-intl"` (nombre XKB: *English (intl., with
  AltGr dead keys*). Es una sola disposición, sin grupo secundario.
- `options` pone `Caps` como `ISO_Level3_Shift`. `Alt` derecha también es nivel
  3, porque el variant incluye `level3(ralt_switch)`.
- Es copia del store: un cambio acá necesita `just switch` (o `just test`). No
  recarga en caliente.

## Por qué un solo layout

La capa base de `us(altgr-intl)` es US idéntica: `'`, `"`, `` ` ``, `~`, `^`,
`;`, `[`, `]`, `{`, `}` y la fila de números no se mueven. Todo lo internacional
está en el nivel 3, fuera del camino normal.

Un segundo layout `es`/`latam` no solo agrega la ñ: mueve los brackets y la
puntuación, así que escribir código en el layout equivocado aparece donde no se
espera. Por eso se eliminó el segundo grupo y con él `grp:alt_space_toggle` y el
widget `keyboard_layout` del bar (`configs/noctalia/settings.toml`).

## Cómo se escribe

`Caps` + tecla = nivel 3. `Caps` + `Shift` + tecla = nivel 4.

### Letras

| Tecla | Nivel 3 | Nivel 4 | | Tecla | Nivel 3 | Nivel 4 |
| --- | --- | --- | --- | --- | --- | --- |
| `a` | á | Á | | `n` | **ñ** | **Ñ** |
| `e` | é | É | | `y` | ü | Ü |
| `i` | í | Í | | `j` | ï | Ï |
| `o` | ó | Ó | | `p` | ö | Ö |
| `u` | ú | Ú | | `q` | ä | Ä |
| `s` | ß | § | | `w` | å | Å |
| `d` | ð | Ð | | `r` | ë | Ë |
| `l` | ø | Ø | | `t` | þ | Þ |
| `z` | æ | Æ | | `x` / `k` | œ | Œ |
| `c` | © | ¢ | | `m` | µ | ± |
| `,` | ç | Ç | | `b` | · | *(dead_stroke)* |
| `v` | ® | ™ | | | | |

### Signos

| Tecla | Nivel 3 | Nivel 4 | | Tecla | Nivel 3 | Nivel 4 |
| --- | --- | --- | --- | --- | --- | --- |
| `1` | ¹ | **¡** | | `5` | € | *(dead_cedilla)* |
| `2` | ² | *(dead_doubleacute)* | | `6` | *(dead_circumflex)* | ¼ |
| `3` | ³ | *(dead_macron)* | | `7` | *(dead_horn)* | ½ |
| `4` | ¤ | £ | | `8` | *(dead_ogonek)* | ¾ |
| `9` | ‘ | *(dead_breve)* | | `0` | ’ | *(dead_abovering)* |
| `-` | ¥ | *(dead_belowdot)* | | `=` | × | ÷ |
| `[` | « | “ | | `]` | » | ” |
| `\` | ¬ | ¦ | | `/` | **¿** | *(dead_hook)* |
| `.` | *(dead_abovedot)* | *(dead_caron)* | | | | |

### Dead keys

No se usan en el día a día; quedan disponibles si algún día hacen falta. Se
aprieta la combinación y después la letra base: `Caps+6` y después `a` da `â`.

| Combinación | Dead key | Ejemplo |
| --- | --- | --- |
| `Caps` + `` ` `` | grave | à è ì ò ù |
| `Caps+Shift` + `` ` `` | tilde | ã õ |
| `Caps` + `'` | agudo | á é í ó ú |
| `Caps+Shift` + `'` | diéresis | ë ï ü |
| `Caps+6` | circunflejo | â ê î ô û |

## Verificación

```bash
umbriel keyboard-layouts     # debe listar un solo layout, sin el "es"
umbriel subscribe keyboard_layout
```

Para ver el keymap resuelto que tiene el compositor (vía Xwayland):

```bash
xkbcomp :0 - 2>/dev/null | grep -A3 'key <AB06>'   # n:  n, N, ntilde, Ntilde
xkbcomp :0 - 2>/dev/null | grep -A3 'key <CAPS>'   # ISO_Level3_Shift, Caps_Lock
```

Y para saber qué combinación produce un carácter en el layout configurado:

```bash
xkbcli how-to-type --layout us --variant altgr-intl 241   # 241 = ñ
```

## Notas

- `Caps` no bloquea mayúsculas: es solo el modificador de nivel 3. Si alguna
  vez hace falta el bloqueo, se cambia la opción a
  `lv3:caps_switch_capslock_with_ctrl` (`Caps+Ctrl`) o a `caps:numlock`/
  `caps:none` según convenga.
- Si una tecla del nivel 3 no produce lo esperado, el sospechoso suele ser el
  keycode y no el layout. Un teclado físico español/latinoamericano manda la ñ
  como `AC10` (la posición de `;` en US), y ahí el nivel 3 es `¶`, no `ñ`. En un
  teclado US ANSI la ñ está en `AB06`, la letra `n`.
- `[input.keyboard]` acepta `layout`, `variant`, `options`, `model`,
  `repeat_rate`, `repeat_delay`, `numlock_toggle` y `track_layout`. No hay forma
  de cargar un archivo de símbolos propio; para un remapeo por tecla hace falta
  `keyd`.
