# Limitación de Instancia Única

## ¿Por Qué Solo Una Instancia?

Este proyecto utiliza **entornos Docker aislados** para cada proyecto, donde cada contenedor tiene:
- Sus propias extensiones de VSCode
- Su propia configuración
- Sus propias herramientas y dependencias

Sin embargo, todos los contenedores comparten el mismo **display de WSLg** (`:0`). VSCode detecta otras instancias corriendo en el mismo display e intenta comunicarse con ellas, lo que causa conflictos.

**Soluciones descartadas:**
- ✗ Compartir configuración entre contenedores → Pierde el aislamiento (extensiones mezcladas)
- ✗ Displays virtuales separados → Muy complejo, pierde integración con WSLg

**Solución adoptada:**
- ✅ Mono-instancia con manejo elegante de conflictos

## Comportamiento

### Escenario 1: Primera Instancia

```bash
$ cd ~/proyecto-rust
$ ./vsc-wslg dood up

🚀 Iniciando VSCode...
# VSCode se abre normalmente
```

### Escenario 2: Intentar Segunda Instancia

```bash
$ cd ~/proyecto-symfony
$ ./vsc-wslg dood up

⚠️  Ya hay una instancia de vsc-wslg corriendo:

   Proyecto:   vsc_proyecto-rust (DooD)
   Contenedor: vsc_proyecto-rust_vscode_1
   Workspace:  /home/user/proyecto-rust

¿Qué quieres hacer?
  1) Cancelar (mantener la instancia existente)
  2) Cerrar la instancia existente y abrir esta

Opción [1-2]:
```

**Opción 1**: Cancela la operación, deja el VSCode actual corriendo.

**Opción 2**: Cierra automáticamente la instancia existente y abre la nueva:
```bash
🛑 Cerrando instancia(s) existente(s)...
   Bajando vsc_proyecto-rust...
✓ Listo, procediendo a abrir nueva instancia...

🚀 Iniciando VSCode...
# VSCode de proyecto-symfony se abre
```

## Workflow Recomendado

### Cambio Rápido de Proyecto

```bash
# Estás trabajando en proyecto A
cd ~/proyecto-a
./vsc-wslg dood up

# Quieres cambiar a proyecto B
# Opción A: Manual
./vsc-wslg dood down
cd ~/proyecto-b
./vsc-wslg dood up

# Opción B: Automático (usa opción 2 del prompt)
cd ~/proyecto-b
./vsc-wslg dood up
# → Selecciona opción 2
```

### Alias Útiles

Agrega a tu `~/.bashrc` o `~/.zshrc`:

```bash
# Cambio rápido con confirmación
alias vsc-switch='cd "$1" && /ruta/a/vsc-wslg dood up'

# Cerrar instancia actual desde cualquier lugar
alias vsc-down='docker ps --filter "name=vsc_" --format "{{.Names}}" | head -1 | xargs -I {} docker stop {}'
```

## Casos Especiales

### Múltiples Proyectos Simultáneos (No Soportado)

Si necesitas trabajar en múltiples proyectos **al mismo tiempo**, considera:

1. **VSCode Remoto**: Usa VSCode de Windows + Remote-Containers
2. **Displays Virtuales**: Implementación compleja con Xvfb/VNC (ver documentación extendida)
3. **Editor Secundario**: Usa `vim`/`nano` en un contenedor para ediciones rápidas mientras VSCode está en otro

### Detectar Instancia Corriendo

```bash
# Ver qué instancia está activa
docker ps --filter "name=vsc_" --format "Proyecto: {{.Names}}\nImagen: {{.Image}}"

# Bajar todas las instancias
docker ps --filter "name=vsc_" -q | xargs docker stop
```

## Arquitectura Técnica

```
┌─────────────────────────────────────┐
│  WSLg Display Server (:0)           │
│  - Gestiona todas las ventanas GUI  │
│  - Permite detección entre apps     │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
   Container A      Container B
   (Rust env)       (PHP env)
       │                │
       └────────────────┘
       Solo UNO puede
       usar el display
       a la vez
```

## Trade-offs

| Aspecto | Evaluación |
|---------|------------|
| **Aislamiento de entornos** | ✅ Completo |
| **Reproducibilidad** | ✅ Total |
| **Facilidad de uso** | ✅ Simple |
| **Instancias concurrentes** | ❌ No soportado |
| **Cambio entre proyectos** | ⚠️ Requiere cerrar/abrir (~5-10 seg) |

Esta limitación es un **compromiso consciente** entre simplicidad, aislamiento y la realidad técnica de WSLg.
