# nix-ld: correr binarios precompilados

`modules/nixos/core.nix` habilita `programs.nix-ld`. Esta nota explica qué
resuelve, cómo usarlo y cómo diagnosticar cuando un binario no arranca.

## El problema

Un binario dinámico compilado fuera de Nix (release de GitHub, instalador que
baja un binario, etc.) espera dos cosas que en NixOS no existen:

- el cargador dinámico en `/lib64/ld-linux-x86-64.so.2`;
- librerías compartidas en `/usr/lib`, `/lib/x86_64-linux-gnu`, etc.

Síntomas típicos:

```text
bash: ./binario: No such file or directory
# el archivo existe: es el loader que el binario pide lo que falta

error while loading shared libraries: libfoo.so.1: cannot open shared object file
# loader ok, falta una librería
```

## Qué hace nix-ld

- Crea `/lib64/ld-linux-x86-64.so.2` apuntando al loader de glibc del store.
- Expone un `LD_LIBRARY_PATH` fijo con las librerías declaradas en
  `programs.nix-ld.libraries`.

Es una solución global y declarativa: cualquier binario random "simplemente
corre", sin ensuciar nada y con rollback incluido.

## Cómo agregar librerías

Cuando un binario tire `libfoo.so.N: cannot open shared object file`,
averiguar qué paquete la provee y sumarlo a la lista:

```nix
# modules/nixos/core.nix
programs.nix-ld.libraries = with pkgs; [
  icu
  # openssl zlib curl stdenv.cc.cc.lib ...
];
```

Para saber qué le falta a un binario:

```bash
ldd ./binario | grep "not found"
readelf -l ./binario | grep interpreter   # confirmar el loader que pide
```

Para buscar qué paquete de nixpkgs provee una lib, `nix-locate` (de
`nix-index`) sobre la ruta exacta, por ejemplo `libssl.so.3`.

## Cuándo usar cada vía

No compiten; cada una tiene su caso:

- `nix-ld` (global): binarios que corréis directo sin empaquetar, herramientas
  que se auto-instalan, pruebas rápidas.
- `autoPatchelfHook` (en el derivation): cuando empaquetás el binario en el
  flake y querés que quede cerrado y autónomo. Es la vía preferida si el
  binario es parte del config (ver Helium en `packages.nix` como ejemplo de
  envoltura de AppImage).
- `steam-run` / FHS env: programas que esperan un filesystem completo
  (rutas absolutas, `dlopen` exótico, juegos).

## Relación con `curl | sh`

Los instaladores `curl | sh` no corren directo en NixOS: escriben en `/usr`
y ahí no existe (o peor, contaminan). Si el script solo baja un binario,
bajar ese binario a mano y correrlo con nix-ld; si tiene lógica propia que
vale la pena, empaquetarla.
