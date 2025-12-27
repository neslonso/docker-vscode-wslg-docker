# Fase 2: Unificación de Entrypoints - Plan Detallado

## Estado Actual

**Archivos**:
- `DinD/entrypoint.sh`: 162 líneas
- `DooD/entrypoint.sh`: 155 líneas
- **Total**: 317 líneas
- **Duplicación estimada**: ~140 líneas (88%)

## Análisis de Diferencias

### Sección 1: Configuración Inicial (COMÚN 100%)
```bash
# Permisos en volúmenes
sudo chown -R dev:dev /home/dev/.vscode
sudo chown -R dev:dev /home/dev/.config/Code
```

### Sección 2: Setup Docker (ESPECÍFICO)

**DinD** (~15 líneas):
```bash
echo "🐳 Iniciando Docker daemon..."
sudo dockerd --host=unix:///var/run/docker.sock &
# Esperar a que Docker esté listo
for i in {1..30}; do
    if docker info &>/dev/null; then
        echo "✓ Docker daemon listo"
        break
    fi
    sleep 1
done
```

**DooD** (~5 líneas):
```bash
if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    sudo groupadd -g "$DOCKER_GID" docker 2>/dev/null || true
    sudo usermod -aG "$DOCKER_GID" dev 2>/dev/null || true
fi
```

### Sección 3: Configuración VSCode (COMÚN ~90%)
```bash
# Settings.json
# Perfiles
# Extensiones
# Workaround WSLg
# Etc.
```

### Sección 4: Lanzamiento VSCode (PEQUEÑA DIFERENCIA)

**DinD**:
```bash
$NEW_CMD &
```

**DooD**:
```bash
if [ -S /var/run/docker.sock ]; then
    sg docker -c "$NEW_CMD" &
else
    $NEW_CMD &
fi
```

## Estrategia de Refactorización

### Paso 1: Crear Bibliotecas Compartidas

#### A) `lib/docker-setup.sh` (NUEVO)

```bash
#!/bin/bash

##
# Inicia el Docker daemon (DinD)
# Espera hasta 30 segundos a que esté listo
# Returns: 0 si éxito, 1 si fallo
##
start_docker_daemon() {
    echo "🐳 Iniciando Docker daemon..."
    sudo dockerd --host=unix:///var/run/docker.sock &

    # Esperar a que Docker esté listo
    local timeout=30
    for i in $(seq 1 $timeout); do
        if docker info &>/dev/null; then
            echo "✓ Docker daemon listo"
            return 0
        fi
        sleep 1
    done

    echo "✗ Error: Docker daemon no arrancó después de ${timeout}s"
    return 1
}

##
# Configura permisos del socket Docker (DooD)
# Agrega el usuario 'dev' al grupo del socket
##
setup_docker_socket_permissions() {
    if [ -S /var/run/docker.sock ]; then
        local docker_gid=$(stat -c '%g' /var/run/docker.sock)
        sudo groupadd -g "$docker_gid" docker 2>/dev/null || true
        sudo usermod -aG "$docker_gid" dev 2>/dev/null || true
    fi
}

##
# Ejecuta un comando con permisos de Docker si es necesario
# Arguments:
#   $@ - Comando a ejecutar
##
run_with_docker_perms() {
    if [ -S /var/run/docker.sock ]; then
        sg docker -c "$*"
    else
        "$@"
    fi
}
```

#### B) `lib/vscode-setup.sh` (NUEVO)

Mover TODA la lógica común de VSCode aquí:

```bash
#!/bin/bash

##
# Configura permisos en directorios de VSCode
##
setup_vscode_permissions() {
    sudo chown -R dev:dev /home/dev/.vscode 2>/dev/null || true
    sudo chown -R dev:dev /home/dev/.config/Code 2>/dev/null || true
}

##
# Mergea settings.json del perfil con el del usuario
##
setup_vscode_settings() {
    # ... toda la lógica actual de settings ...
}

##
# Instala extensiones desde el perfil
##
install_vscode_extensions() {
    # ... toda la lógica actual de extensiones ...
}

##
# Aplica workaround de WSLg para redimensionar ventana
##
apply_wslg_workaround() {
    # ... lógica de xdotool ...
}

##
# Abre el README del perfil si es primera vez
##
open_profile_readme() {
    # ... lógica de README ...
}

##
# Lanza VSCode con los argumentos especificados
# Arguments:
#   $@ - Argumentos para code
##
launch_vscode() {
    source /usr/local/lib/docker-setup.sh

    run_with_docker_perms "$@" &

    # Esperar a que VSCode arranque
    sleep 3

    # Abrir README si es necesario
    if [ -n "$README_TO_OPEN" ]; then
        echo "👋 Abriendo README: $README_TO_OPEN"
        # Aquí también usar run_with_docker_perms si es necesario
        code "$README_TO_OPEN" 2>/dev/null || true
    fi
}
```

### Paso 2: Simplificar Entrypoints

#### `DinD/entrypoint.sh` (NUEVO - ~25 líneas)

```bash
#!/bin/bash
set -e

# Cargar bibliotecas
source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

# Setup inicial
setup_vscode_permissions

# DinD: Iniciar Docker daemon
start_docker_daemon || exit 1

# Configuración de VSCode
setup_vscode_settings
install_vscode_extensions
apply_wslg_workaround

# Lanzar VSCode
launch_vscode "$@"

# Monitoreo de proceso
echo "🔍 Monitoreando proceso VSCode..."
while true; do
    if ! pgrep -u dev -f "/usr/share/code" > /dev/null 2>&1; then
        echo "✓ VSCode cerrado, terminando contenedor..."
        break
    fi
    sleep 5
done
```

#### `DooD/entrypoint.sh` (NUEVO - ~25 líneas)

```bash
#!/bin/bash
set -e

# Cargar bibliotecas
source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

# Setup inicial
setup_vscode_permissions

# DooD: Configurar permisos de socket
setup_docker_socket_permissions

# Configuración de VSCode
setup_vscode_settings
install_vscode_extensions
apply_wslg_workaround

# Lanzar VSCode
launch_vscode "$@"

# Monitoreo de proceso
echo "🔍 Monitoreando proceso VSCode..."
while true; do
    if ! pgrep -u dev -f "/usr/share/code" > /dev/null 2>&1; then
        echo "✓ VSCode cerrado, terminando contenedor..."
        break
    fi
    sleep 5
done
```

## Reducción Esperada

| Componente | Antes | Después | Reducción |
|------------|-------|---------|-----------|
| DinD entrypoint | 162 líneas | 25 líneas | -84% |
| DooD entrypoint | 155 líneas | 25 líneas | -84% |
| Código compartido | 0 | ~200 líneas (lib) | - |
| **TOTAL** | 317 líneas | 250 líneas | **-21%** |

Además, el código compartido ahora es:
- ✅ Testeable unitariamente
- ✅ Documentado
- ✅ Reutilizable
- ✅ Más fácil de mantener

## Pasos de Implementación

1. ✅ Analizar diferencias entre entrypoints
2. ⏳ Crear `lib/docker-setup.sh`
3. ⏳ Crear `lib/vscode-setup.sh`
4. ⏳ Modificar `docker/Dockerfile.base` para copiar las libs
5. ⏳ Refactorizar `DinD/entrypoint.sh`
6. ⏳ Refactorizar `DooD/entrypoint.sh`
7. ⏳ Testing exhaustivo
8. ⏳ Actualizar documentación

## Testing

- [ ] Build de imágenes DinD y DooD
- [ ] `up` con perfil symfony (DinD y DooD)
- [ ] `up` con perfil rust (DinD y DooD)
- [ ] `up` sin perfil (DinD y DooD)
- [ ] Extensiones se instalan correctamente
- [ ] Settings se aplican
- [ ] Workaround WSLg funciona
- [ ] README se abre en primera ejecución
- [ ] Monitoreo de proceso funciona
- [ ] Contenedor termina al cerrar VSCode
