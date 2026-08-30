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

## Entorno FHS para agentes

Las herramientas de agentes no usan un `devShell` ni instalan Node, npm, PNPM o
Go globalmente. Nix provee un entorno FHS llamado `gentle-agent`, expuesto por
el comando `agent`. Dentro existen rutas Linux convencionales como
`/usr/bin/tar`, necesarias para extensiones como `gentle-pi`.

El entorno es una capa de compatibilidad, no una sandbox de seguridad: los
procesos conservan tus permisos de usuario y pueden modificar tu directorio
personal. Al cerrarlo, Node, npm, PNPM y Go dejan de estar en el `PATH` normal.

Los comandos cotidianos `pi`, `gentle-ai`, `engram` y `gga` son
wrappers que entran al entorno automáticamente. Para abrir una terminal con
todas las herramientas disponibles:

```bash
agent
```

También podés ejecutar un comando puntual:

```bash
agent pi
agent gentle-ai doctor
```

### Instalación de Gentle AI

Después de aplicar la configuración, abrir el entorno FHS:

```bash
agent
```

Y ejecutar el instalador oficial, sin fijar una versión en esta configuración:

```bash
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
```

El instalador oficial elige y mantiene su canal estable. Cuando termine, salir
del shell (`exit`) e iniciar el configurador normalmente:

```bash
gentle-ai
```

Elegir Codex, OpenCode y Pi, y los componentes que quieras. El instalador y
`gentle-ai sync` son los dueños de sus skills, prompts, configuraciones MCP y
perfiles: no mezclar esos archivos con `home.file` de Home Manager.

Pi usa npm internamente incluso si PNPM es el gestor preferido para proyectos.
Su prefijo mutable queda aislado en:

```text
~/.local/share/gentle-agent/npm/
```

No se escribe nunca dentro de `/nix/store` y no se instala Node/npm/Go en el
perfil global. El estado normal de Gentle AI también es mutable y vive en:

```text
~/.gentle-ai/    # selección de agentes, backups y configuración gestionada
~/.pi/           # paquetes y configuración de Pi
~/.engram/       # memoria SQLite local
~/.local/bin/    # gentle-ai, engram y gga instalados por upstream
```

### Engram

Engram aporta memoria persistente de agentes. El instalador de Gentle AI lo
instala en `~/.local/bin`; los datos viven fuera del store:

```text
~/.engram/engram.db
```

La base SQLite local es la fuente de verdad. Sus archivos `-wal` y `-shm` son
parte normal de SQLite y nunca se borran por separado. Para explorarla:

```bash
engram tui
engram search "texto a buscar"
```

La sincronización de memoria por proyecto es opcional y crea `.engram/` dentro
del repositorio. Antes de versionarla, revisar su contenido: puede contener
decisiones, contexto o referencias que no querés compartir.

### GGA

GGA (Gentleman Guardian Angel) es una revisión de código mediante IA ejecutada
como hook de Git. Es opt-in por repositorio; instalar el binario no activa nada
ni modifica commits.

En un proyecto donde quieras probarlo:

```bash
gga init
gga install
```

Después configurar `PROVIDER="codex"` en el `.gga` de ese proyecto. El hook
revisa los cambios staged antes de cada commit. Para omitirlo de forma puntual:

```bash
git commit --no-verify
```

No habilitar GGA por defecto en todos los repositorios: usa un agente/modelo y
agrega tiempo y costo a cada commit.

### Pi y las extensiones Gentle

Usar `pi` normalmente. El wrapper lo ejecuta dentro del entorno FHS, con el
prefijo npm aislado y con `tar` en una ruta FHS. Por eso `gentle-ai install` y
las posteriores instalaciones con `pi install` pueden usar el flujo soportado
por Gentle AI sin intentar escribir en el store de Nix.

Para actualizar el ecosistema, seguir el flujo de upstream dentro del wrapper:

```bash
gentle-ai upgrade
gentle-ai sync
```

Revisar los cambios y los backups que Gentle AI crea antes de aceptar una
actualización. Las extensiones de Pi ejecutan código con tus permisos de
usuario; instalarlas sólo desde fuentes que revisaste o en las que confiás.

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
`gentle-agent` es la excepción deliberada: un entorno FHS invocado mediante
wrappers para compatibilidad con el ecosistema mutable de Gentle AI, sin volver
globales Node, npm, PNPM o Go.

La virtualización local queda disponible en el perfil diario para poder aislar
proyectos o probar sistemas sin cambiar de configuración. Paquetes ocasionales
como Herdr o RustDesk quedan fuera y se usan sólo cuando hacen falta.
