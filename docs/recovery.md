# Recuperación local

Esta máquina se recupera principalmente con generaciones de NixOS y rollback.

## Antes de aplicar cambios

Para evaluar sin activar:

```bash
just check
just build
```

Para activar hasta el próximo arranque:

```bash
just test
```

Para activar y dejar como generación de arranque:

```bash
just switch
```

Para preparar el próximo arranque sin tocar la sesión actual:

```bash
just boot
```

`just boot` es útil para cambios sensibles como greeter, kernel, gráficos o
servicios de login.

## Rollback desde la sesión actual

Si el sistema arranca pero algo quedó mal:

```bash
just rollback
```

Esto activa la generación anterior.

## Rollback desde TTY

Si Umbriel o Noctalia fallan:

1. Cambiar a TTY con `Ctrl+Alt+F2`.
2. Iniciar sesión.
3. Ir al repo:

   ```bash
   cd ~/nixos-config
   ```

4. Ejecutar:

   ```bash
   just rollback
   ```

## Rollback desde systemd-boot

Si el sistema no llega a una sesión usable:

1. Reiniciar.
2. En el menú de systemd-boot, elegir una generación anterior de NixOS.
3. Si esa generación funciona, entrar al repo y decidir si hacer rollback
   permanente o corregir la configuración actual.

## Limpieza de generaciones

Ver historial:

```bash
just history
```

Conservar sólo las últimas 5 generaciones del sistema y correr GC:

```bash
just prune-generations 5
```

Mientras el escritorio todavía está cambiando bastante, conviene conservar al
menos 3 generaciones.
