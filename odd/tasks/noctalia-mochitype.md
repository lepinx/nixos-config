# Noctalia MochiType plugin

A Noctalia Shell v5 plugin that reproduces the Mochi Type (macOS) experience:
open a floating panel with a keybind or the launcher, practice typing random
words interactively, and see WPM/accuracy results.

## Specs

- S1: Plugin has a floating panel entry (centered) with `keyboard_focus = "exclusive"` that runs a typing test. Open/close via keybind running `noctalia msg panel-toggle <plugin>:test`.
- S2: Launcher provider with prefix `type` (`/type` in the launcher) that opens the panel.
- S3: Bar widget entry showing today's typing stats (best/last WPM) in the Noctalia bar.
- S4: Wordlists in Spanish and English; a quick selector in the panel switches language.
- S5: Two session modes, selectable in the panel: time mode (15s/30s/60s) and words mode (15/25/50 words).
- S6: During the test: show the words as flowing multi-line text (monkeytype-style, three visible lines that shift up as the user advances), with a blinking caret, per-char coloring (typed/incorrect/untyped), live WPM and accuracy, and the remaining time/word count. Note: ui.* has no transitions, so line shifts are instant, not animated.
- S7: On finish: results screen with WPM, accuracy, and best WPM persisted across restarts; Enter restarts, Escape closes.
- S8: Stats persist in `noctalia.pluginDataDir()` as JSON; the bar widget reads them via `noctalia.state`.

## Tasks

- T1 (S1,S5) Scaffold `plugin.toml` + wordlist data files (es/en).
- T2 (S1,S4,S5,S6,S7) Implement typing panel engine (`panel.luau`).
- T3 (S2) Launcher provider (`launcher.luau`). DONE — commit `feat(noctalia): add MochiType launcher provider and WPM bar widget`.
- T4 (S3,S8) Bar WPM widget (`bar.luau`) reading persisted stats. DONE — same commit. Runtime UI check pending: user must add the widget to the bar manually.
- T5 (S1-S8) Local install, enable, verify via IPC; README. DONE — plugin enabled from local path source (`configs/noctalia/settings.toml`), panel opens clean; global keybind remains a user step.

## Log

- L1 (user): "existe algun plugin en noctalia para typear? practicar typeo hay una en mac, sabes cual te digo?" — then clarified via links: Mochi Type (https://orsolabs.dev/mochi-type/), "algo que abras con un comando para practicar interactivamente palabras random que te van saliendo".
- L2 (user, design decisions via questionnaire): entradas = panel flotante + tecla, launcher /type, widget de barra (WPM); palabras = ambos idiomas con selector; modos = ambos (tiempo y palabras).
- L3 (evidence): smoke test 43/43 (LuaJIT, stubs de noctalia/ui/panel) detectó un bug real: el loader de wordlists partía por líneas (`[^\r\n]+`) y los archivos son de una sola línea — corregido a `%S+`. En runtime, Noctalia logueó `unknown color 'outline_variant'` — reemplazado por `on_surface_variant` (rol válido confirmado contra los plugins oficiales). Tras reexportar el plugin: panel abre con cero warnings en el journal.
- L4 (user bug report): "escribo la primer letra y no sigue con las siguientes". Causa: render() incrementaba inputKey en cada re-render; el input es uncontrolled, así que cada tecla recreaba el control enfocado. Fix: la clave cambia solo en advance()/resetSession/double-space (input nuevo por palabra). Regression check en el smoke test (clave estable entre letras, cambia al submit) — 44/44.
- L5 (user decision): renombre `lucho/mochitype` → `lepinx/typing-test` — namespace = usuario de GitHub (lepinx), nombre genérico descriptivo según convención del catálogo; candidato a publicarse en noctalia-dev/community-plugins. Feature doc y commits: d25a3fc, a2735a4, de674db en branch feature/mochitype.
- L6 (user, verbatim): "no quiero que ponga palabra por palabra sino varias palabras en la pantalla" / "Me gusta mas la visual que tiene el video tipo monkeytype.. con esa animacion que tiene esta buena" (https://www.youtube.com/watch?v=Vhv_SkzuQK8, age-restricted, no visible; se toma monkeytype.com como referencia). Reabre T2: reescribir la visual a estilo monkeytype — texto fluido en 3 líneas, caret parpadeante (frame ticks), color por carácter, líneas que suben al avanzar. ui.* no tiene transiciones: el shift de líneas es instantáneo (limitación declarada en S6).
- L7 (evidence, v0.2.0): visual monkeytype implementada y verificada (smoke test 47/47, journal limpio). Aprendizaje crítico de runtime: Noctalia 5.2.1 rechaza plugin_api 43 como "incompatible" (máximo verificado corriendo: 28, umbriel-companion); con api < 43 el host exige los nombres de rol pre-rename (surface_variant/outline) — surface_container/outline_variant dan "unknown color". Commits: 5a4acd2, dba8ff5, a5a58f9.
- L8 (user, verbatim): "me gustaria dar el espacio.. como monkeytype" — quitado el auto-avance: la palabra se envía solo con espacio; espacio con input vacío es no-op. Test-first (RED 20/49 → GREEN 49/49).
- L9 (user): llevar el plugin al repo de contribución y seguir las convenciones. El clone que señaló (~/open-source/noctalia-official-plugins) es fork de official-plugins, que "does not accept third-party plugins" — se preparó el workspace correcto: fork lepinx/community-plugins en ~/open-source/noctalia-community-plugins, branch feat/typing-test desde upstream/main. Plugin adaptado a las reglas del repo: settings (language/mode) + translations/en.json (exigidos por CI), README según plantilla, thumbnail 960×540 (placeholder ffmpeg; la checklist pide generarlo con el generador oficial), validador CI local: 290 manifests OK. Branch de nixos-config renombrada feature/typing-test. Push y PR: pendientes de aprobación explícita del usuario.
- L10 (user, verbatim): "No me gusta que tenga doble input.. el de abajo capaz lo sacamos nomas.. me gusta igualmente el label que tiene como indicacion" — input inferior ahora invisible (ui.input frameVisible=false + fontSize 8, sigue enfocado y captura teclas); hint conservado. Panel 360px.
- L11 (user decisión): renombre a lepinx/noctatype (v0.3.0) — el usuario lo eligió pese a la recomendación del README de community contra prefijos noct* (hay precedentes en el catálogo: noctes, noctwhspr, noctaproton-vpn).
- L12 (entorno): el usuario volvió nixos-config a main (branch feature/typing-test conserva la historia; commits 5a4acd2..7939113). El desarrollo ahora vive SOLO en ~/open-source/noctalia-community-plugins. El path source de Noctalia NO descubre plugins en un checkout git de community (usa catalog.toml generado por CI) — para desarrollo runtime hay un stage dir plano ~/open-source/noctalia-dev-plugins/noctatype; copiar ahí antes de probar. Source "dev" apunta al stage dir.
- L13 (publicación, con aprobación explícita del usuario): push de feat/noctatype al fork lepinx/community-plugins y draft PR noctalia-dev/community-plugins#1178 (https://github.com/noctalia-dev/community-plugins/pull/1178), título "feat: add noctatype plugin", descripción con el template oficial (marker noctalia-pr-template:v1). Ajuste post-creación: el bot enforce exige el texto EXACTO del ítem del checklist del thumbnail — corregido, los 3 checks (enforce, notify-plugin-authors, validate) en verde. Pendiente: usuario pega las capturas en la descripción y el plugin queda en draft hasta review de maintainers.
