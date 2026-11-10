# Secretos

Este repo no debe contener secretos en texto plano.

## Hash no es lo mismo que cifrado

Un hash de contraseña no es la contraseña original, pero tampoco es un secreto
seguro para publicar. Si alguien obtiene el hash, puede intentar romperlo
offline probando muchas contraseñas hasta encontrar una coincidencia.

Un secreto cifrado con `sops-nix` o `agenix` es distinto: el repo guarda
ciphertext y sólo las claves privadas autorizadas pueden descifrarlo.

Regla práctica:

- no versionar contraseñas en texto plano;
- no publicar hashes de contraseñas en repos públicos;
- sí se pueden versionar secretos cifrados si están bien gestionados;
- las claves privadas que descifran secretos nunca van al repo.

## Política adoptada

Decisión: adoptar dos capas complementarias en lugar de una sola herramienta.

1. **Servicios de sistema NixOS → `sops-nix`.** Para secretos que un servicio
   de NixOS consume en la activación o en runtime: `EnvironmentFile =
   "/run/secrets/<svc>.env"`, `LoadCredential`,
   `services.restic.backups.<name>.passwordFile`,
   `services.pangolin.environmentFile`, etc.

2. **Secretos a nivel de aplicación → `SecretSpec`.** Para apps y contenedores
   que resuelven sus propios secretos en runtime (por ejemplo, el futuro ERP),
   y para desarrollo y CI. `SecretSpec` ya se usa en el proyecto `palmares-sql`.

3. **Los secretos personales nunca entran al repo, cifrados o no.** Esta parte
   de la política no cambia: contraseña del usuario, passphrase de LUKS, PIN de
   TPM2, password manager, claves SSH privadas personales.

4. **`sops-nix` y `SecretSpec` son capas, no rivales.** SecretSpec puede
   consumir SOPS como uno de sus proveedores, así que el almacenamiento cifrado
   de sops-nix y la resolución a nivel de aplicación se complementan.

## El reparto SecretSpec / sops-nix

`SecretSpec` es una herramienta de Cachix (los autores de devenv), licencia
Apache 2.0. Un archivo `secretspec.toml` declara secretos abstractos:

- **profiles** eligen *cuándo* se usan (dev, CI, producción);
- **providers** eligen *dónde* se guardan (keyring del OS, 1Password,
  Bitwarden, Vault/OpenBao, Azure Key Vault, dotenv, entorno);
- **scopes** eligen *qué consumidor* recibe cada secreto.

La inyección en runtime es `secretspec run --profile X --scope Y -- <cmd>`;
`as_path` materializa un valor como archivo temporal; `secretspec export`
emite los secretos para `eval` o como JSON.

Para qué **no** sirve en este repo:

- **No reemplaza a sops-nix para servicios de sistema NixOS.** La única
  integración con Nix documentada en secretspec.dev es con **devenv** (shells
  de desarrollo), no con servicios de sistema.
- **En un servidor headless el proveedor keyring no es usable** (no hay
  keyring del OS ni sesión D-Bus). Un SecretSpec del lado del servidor tendría
  que usar un proveedor tipo archivo/age/dotenv.
- **Los scopes no son un límite de autorización** cuando el proceso hijo puede
  acceder a las credenciales del proveedor; lo advierte la propia documentación
  de SecretSpec.

En resumen: SecretSpec es una capa de resolución sobre el almacenamiento, no
un reemplazo del cifrado y despliegue que hace sops-nix.

Nota sin confirmar: hay reportes (sólo fragmentos de búsqueda, sin poder
verificar la fuente) de un issue abierto de "integración NixOS" en el tracker
de SecretSpec, un pedido de proveedor systemd-credentials y un PR de Nix que
agrega soporte de SecretSpec. **Sin confirmar**: hay que verificarlo antes de
contar con esas mejoras.

## Guardrails

- **`gitleaks` como hook de pre-commit.** En un repo público el riesgo real es
  commitear un `.env` en texto plano; el hook es la red de seguridad.
- **Preferir la propia clave host SSH como identidad age**, así no hay que
  proteger un archivo de clave extra. (*Verificar la opción exacta al
  implementar.*)
- **Si no lo podés rotar, no va al repo.** Un secreto que no se puede rotar
  tras una fuga no debería estar en un repositorio.
- **La clave privada `age` nunca entra al repositorio.**

## Contraseña de usuario declarativa

Con sops-nix adoptado, esto ya es posible; por ahora no está hecho.

No usar:

```nix
users.users.lucho.hashedPassword = "...";
```

en un repo público.

Preferir un archivo externo:

```nix
users.users.lucho.hashedPasswordFile = config.sops.secrets.lucho-password.path;
```

Con `sops-nix`, ese secreto debe estar disponible antes de crear usuarios:

```nix
sops.secrets.lucho-password.neededForUsers = true;
```

## Qué cosas sí cifrar

Candidatos razonables:

- hashes de contraseñas de usuarios si se quieren declarar;
- credenciales de servicios;
- tokens de APIs;
- claves privadas generadas para servicios automáticos;
- archivos `.env` que sean necesarios para servicios declarativos.

## Qué cosas no cifrar en este repo por ahora

- claves SSH privadas personales existentes;
- passphrase larga de LUKS;
- PIN de TPM2;
- password manager;
- sesiones de navegador.

Para claves SSH personales, suele ser mejor generar claves nuevas por propósito
y guardar sólo las claves públicas o la configuración no sensible.

## Referencias

- NixOS Wiki: User management
- NixOS Wiki: Comparison of secret managing schemes
- sops-nix
- agenix
- SecretSpec (secretspec.dev)

---

El trabajo del homelab vive en `odd/tasks/homelab-proxmox.md`.
