# Desarrollo con devShells

La idea en NixOS no es instalar todos los lenguajes y herramientas globalmente
para siempre. Lo global debe ser lo que usás todos los días en cualquier repo:
Git, editor, `direnv`, `just`, utilidades CLI y, temporalmente, algún runtime
mientras migrás.

Lo reproducible de verdad vive por proyecto.

## Global vs por proyecto

Regla práctica:

- Global: herramientas que usás en cualquier directorio y que no dependen del
  proyecto: `git`, editor, `just`, `direnv`, `nix`, `ripgrep`, `fd`, `eza`,
  `bat`, `zoxide`.
- Global temporal: lenguajes que todavía usás en muchos proyectos sin shell
  propio. La meta es que esta lista tienda a cero.
- Por proyecto: runtimes, compiladores, bases de datos, linters, formatters y
  CLIs atados a una versión concreta del proyecto.

Ejemplos de cosas que normalmente conviene mover a `devShell`:

- Node/Bun/PNPM/Yarn de un frontend.
- Go + `gopls` + `golangci-lint` de una API.
- Rust + `rust-analyzer` + `pkg-config` + librerías nativas.
- Python + `uv` + `ruff` + `sqlfluff` + dependencias del proyecto.
- PostgreSQL/Redis/SQLite tooling para una app puntual.
- Terraform, kubectl, cloud CLIs o herramientas de infraestructura de un repo
  específico.

Así evitás que tu sistema global se convierta en una mochila infinita de cosas
que “alguna vez usaste”.

## Flujo recomendado

En cada proyecto:

1. Crear un `flake.nix` del proyecto.
2. Crear un `.envrc` con:

   ```bash
   use flake
   ```

3. Ejecutar una sola vez:

   ```bash
   direnv allow
   ```

4. Entrar al directorio del proyecto. `direnv` carga automáticamente las
   herramientas declaradas.

También podés entrar manualmente sin `direnv`:

```bash
nix develop
```

Y salir con:

```bash
exit
```

Con `direnv`, el flujo es más cómodo: al entrar al directorio se carga el shell,
y al salir se descarga.

## Runtime de agentes

Pi, Codex y OpenCode son los agentes de código soportados por esta
configuración. Sus **ejecutables** los provee `pkgsUnstable` mediante el perfil
de usuario de Nix; la revisión queda fijada por `flake.lock`. No instalar ni
actualizar esos binarios con npm, instaladores upstream, `pi update self` ni los
mecanismos de autoactualización upstream de Codex y OpenCode: esos flujos no
deben reemplazar los binarios administrados por Nix. Para actualizarlos, revisar y actualizar el
input bloqueado y luego aplicar la generación de Home Manager.

Node y el prefijo npm aislado continúan siendo dependencias de host declaradas
por Nix/Home Manager. Home Manager expone `NPM_CONFIG_PREFIX` y
`NPM_CONFIG_CACHE`, mantiene disponibles `~/.local/bin` y el directorio `bin`
del prefijo, y Nix provee Node. El perfil Nix tiene prioridad: `pi` y `codex`
resuelven allí antes que los binarios heredados en esas rutas mutables. Abrí una
terminal host nueva —o ejecutá `exec fish -l`— después de activar cambios de
Home Manager y verificá el orden con:

```bash
type -a pi codex
```

`just health` también reporta si falta algún componente mutable fuera de Nix
(`gentle-ai`, `engram`, la extensión `gentle-pi`) y muestra el comando de
instalación correspondiente. Es un chequeo manual: no corre con `just switch`.

El prefijo y su caché permanecen deliberadamente mutables y fuera del store:

```text
~/.local/share/agent-runtime/npm/  # prefijo npm para CodeGraph y otras herramientas
~/.cache/agent-runtime/npm/        # caché npm correspondiente
```

Los binarios heredados y el estado de Pi, Codex, CodeGraph, Gentle AI y Engram
se conservan sin que Nix/Home Manager los borre ni sobrescriba. No se escribe
nunca dentro de `/nix/store`.

### Pi, CodeGraph y extensiones

CodeGraph y otras herramientas npm siguen instalándose y actualizándose mediante
sus flujos upstream en el prefijo npm mutable. Las extensiones de Pi también son
mutables: `pi install` y `pi update --extensions` las gestionan fuera del store,
sin modificar el ejecutable Nix de Pi. Las extensiones ejecutan código con tus
permisos de usuario; instalalas sólo desde fuentes revisadas o confiables.

Después de cambios upstream en extensiones de Pi, Gentle AI o Engram, ejecutá:

```bash
gentle-ai sync
```

Eso sincroniza los artefactos administrados por Gentle AI; no instala ni
actualiza automáticamente los ejecutables Nix de Pi o Codex.

#### Limitación de gentle-pi

El instalador package-local de `gentle-pi` 3.7.0 sólo confía en `/usr/bin/tar`
o `/bin/tar`; esas rutas no existen en una instalación NixOS vanilla. Por eso
puede fallar una instalación nueva o la autoreparación, aunque un binario ya
instalado puede seguir funcionando.

### Gentle AI y Engram

El CLI independiente de Gentle AI se instala desde un shell host normal, sin
fijar una versión en esta configuración. Este comando no soluciona la
instalación package-local de `gentle-pi` descrita arriba:

```bash
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
```

El instalador oficial elige y mantiene su canal estable. Al terminar, iniciá
`gentle-ai` y configurá únicamente Pi. El instalador y `gentle-ai sync` son los
dueños de sus skills, prompts, configuraciones MCP y perfiles; no mezclar esos
archivos con `home.file` de Home Manager. Para actualizar Gentle AI y sus
configuraciones gestionadas, seguí el flujo upstream desde un shell host:

```bash
gentle-ai upgrade
gentle-ai sync
```

El estado gestionado de Gentle AI y la memoria local de Engram permanecen fuera
del store:

```text
~/.gentle-ai/    # configuración y backups gestionados
~/.pi/           # paquetes y configuración de Pi
~/.engram/       # memoria SQLite local de Engram
~/.local/bin/    # gentle-ai y engram instalados por upstream
```

La excepción deliberada es el store de perfiles de agentes
(`~/.pi/gentle-ai/profiles.json`): es una decisión autoral, no estado, y se
versiona como copia manual en `configs/pi/gentle-ai/profiles.json`. Nunca como
`home.file`, porque el panel `/gentle:profiles` reescribe el marcador de perfil
activo y el snapshot no debe pelear con esa escritura. Después de un cambio de
routing a propósito, refrescar la copia desde la raíz del repositorio:

```bash
cp ~/.pi/gentle-ai/profiles.json configs/pi/gentle-ai/profiles.json
```

Tras una reinstalación, restaurar con la copia inversa:

```bash
cp configs/pi/gentle-ai/profiles.json ~/.pi/gentle-ai/profiles.json
```

La base `~/.engram/engram.db` es la fuente de verdad de Engram. Sus archivos
`-wal` y `-shm` son parte normal de SQLite y nunca se borran por separado. Para
explorarla:

```bash
engram tui
engram search "texto a buscar"
```

La sincronización de memoria por proyecto es opcional y crea `.engram/` dentro
del repositorio. Antes de versionarla, revisá su contenido: puede incluir
decisiones, contexto o referencias que no querés compartir.

## Abbreviations, aliases y funciones Fish

En Fish, las abbreviations son expansores de texto. Por ejemplo, `gs` se expande
a `git status --short --branch` antes de ejecutar el comando. Eso tiene una
ventaja grande sobre un alias opaco: ves exactamente qué vas a correr antes de
apretar Enter.

Uso recomendado:

- `abbr`: comandos cortos y transparentes que querés ver expandidos:
  `gs`, `gcm`, `nix develop`, `docker compose up -d`.
- `alias`: compatibilidad simple cuando querés reemplazar un comando por otro.
  En este repo preferimos `abbr` salvo casos muy concretos.
- `function`: cuando hay lógica, validación de argumentos o cambio de
  directorio. Ejemplo: `mkcd`.

No conviene crear abbreviations globales para herramientas que sólo existen
dentro de un `devShell`. Si un proyecto necesita `pnpm`, `bun`, `terraform` o
una versión específica de `node`, declaralo en el shell del proyecto. Las
completions y binarios deben aparecer al entrar al proyecto, no vivir siempre en
tu sesión global.

## Comandos del repo NixOS desde cualquier lugar

El repo define una función Fish:

```fish
nixcfg <recipe>
```

Internamente ejecuta el `justfile` de `~/nixos-config` usando
`--justfile` y `--working-directory`, por lo que funciona desde cualquier
directorio.

Atajos disponibles:

```fish
nj   # nixcfg
njc  # nixcfg check
njb  # nixcfg build
njt  # nixcfg test
njs  # nixcfg switch
nju  # nixcfg update
```

Los atajos `j`, `jc`, `jb`, `jt`, `js` quedan para el `justfile` del directorio
actual. Así no rompemos proyectos que tengan su propio `justfile`.

## Función mkcd

`mkcd` crea un directorio y entra en él:

```fish
mkcd ~/workspace/nuevo-proyecto
```

Esto sí debe ser función y no abbreviation, porque necesita ejecutar dos pasos:
`mkdir -p` y luego `cd`.

## Go

Ejemplo mínimo:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
          golangci-lint
        ];
      };
    };
}
```

Después:

```bash
go run .
go test ./...
```

`go run` funciona normal porque `go` existe dentro del shell del proyecto.

## Python

Para proyectos personales simples, usar `uv` dentro del shell:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python3
          uv
          sqlfluff
        ];
      };
    };
}
```

Después:

```bash
uv run python main.py
sqlfluff lint .
```

## Rust

Ejemplo:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          cargo
          rustc
          rust-analyzer
          rustfmt
          clippy
          pkg-config
          openssl
        ];
      };
    };
}
```

Después:

```bash
cargo run
cargo test
```

## Pruebas rápidas sin tocar el sistema

Para probar una herramienta una vez:

```bash
nix shell nixpkgs#go -c go version
nix shell nixpkgs#python3 -c python --version
nix run nixpkgs#clock-rs
```

Esto no agrega el paquete al perfil global.

## Pruebas técnicas y código ajeno

Para pruebas técnicas, challenges o repos que no controlás, Nix ayuda pero no es
una sandbox de seguridad completa.

Flujo razonable:

1. Clonar en un directorio separado.
2. Revisar archivos obvios antes de ejecutar nada:

   ```bash
   ls
   rg -n "curl|wget|bash|sh|sudo|rm -rf|ssh|token|password|postinstall|prepare" .
   ```

3. Si trae `flake.nix`, leerlo antes de `direnv allow`.
4. Preferir entrar manualmente primero:

   ```bash
   nix develop
   ```

5. Ejecutar tests/comandos específicos, no scripts enormes a ciegas.

6. Si el repo es sospechoso, usar aislamiento más fuerte: VM, contenedor,
   usuario separado o una máquina descartable.

Importante: `nix develop` controla dependencias, pero el código que ejecutás
adentro sigue teniendo acceso a tus archivos de usuario si lo corrés como tu
usuario normal. No reemplaza una VM/sandbox cuando hay desconfianza real.

## Política actual de este repo

Los runtimes y versiones específicas viven en los `devShell` de cada proyecto.
`agent-runtime` es la excepción deliberada: un entorno FHS invocado mediante
wrappers para compatibilidad con el ecosistema mutable de Gentle AI, sin volver
globales Node, npm, PNPM o Go.

La virtualización local queda disponible en el perfil diario para poder aislar
proyectos o probar sistemas sin cambiar de configuración. Paquetes ocasionales
como Herdr o RustDesk quedan fuera y se usan sólo cuando hacen falta.
