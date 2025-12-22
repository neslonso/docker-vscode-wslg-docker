# Directorio Docker

Este directorio contiene los archivos base de Docker para el proyecto VSCode-WSLg.

## Estructura

```
docker/
├── Dockerfile.base      # Dockerfile base común para DinD y DooD
├── test-builds.sh       # Script de testing y validación
└── README.md           # Este archivo
```

## Dockerfile.base

El `Dockerfile.base` contiene toda la lógica común entre los modos DinD (Docker-in-Docker) y DooD (Docker-out-of-Docker), eliminando ~95% de duplicación de código.

### Build Arguments

El Dockerfile acepta los siguientes argumentos de construcción:

- **INSTALL_DOCKER_DAEMON** (default: `false`)
  - `"true"`: Instala Docker daemon completo (para DinD)
  - `"false"`: Instala solo Docker CLI (para DooD)

- **ENTRYPOINT_MODE** (default: `"dood"`)
  - `"DinD"`: Usa `DinD/entrypoint.sh`
  - `"DooD"`: Usa `DooD/entrypoint.sh`

### Uso desde docker-compose

**DinD** (`DinD/docker-compose.yml`):
```yaml
build:
  context: ..
  dockerfile: docker/Dockerfile.base
  args:
    INSTALL_DOCKER_DAEMON: "true"
    ENTRYPOINT_MODE: "DinD"
```

**DooD** (`DooD/docker-compose.yml`):
```yaml
build:
  context: ..
  dockerfile: docker/Dockerfile.base
  args:
    INSTALL_DOCKER_DAEMON: "false"
    ENTRYPOINT_MODE: "DooD"
```

### Uso desde línea de comandos

```bash
# Build DinD
docker build \
  --build-arg INSTALL_DOCKER_DAEMON=true \
  --build-arg ENTRYPOINT_MODE=DinD \
  -f docker/Dockerfile.base \
  -t vscode-wslg-dind \
  .

# Build DooD
docker build \
  --build-arg INSTALL_DOCKER_DAEMON=false \
  --build-arg ENTRYPOINT_MODE=DooD \
  -f docker/Dockerfile.base \
  -t vscode-wslg-dood \
  .
```

## Testing

Ejecutar el script de validación:

```bash
./docker/test-builds.sh
```

Este script:
1. Verifica que todos los archivos necesarios existen
2. Valida la sintaxis del Dockerfile.base
3. Verifica la configuración de docker-compose.yml
4. Intenta construir las imágenes (si Docker está disponible)

## Beneficios de la Consolidación

### Antes (Duplicación)
- `DinD/Dockerfile-vsc-wslg`: 69 líneas
- `DooD/Dockerfile-vsc-wslg`: 63 líneas
- **Total**: 132 líneas
- **Duplicación**: ~95%

### Después (Consolidado)
- `docker/Dockerfile.base`: 127 líneas (con documentación)
- **Reducción efectiva**: ~50% de código duplicado eliminado
- **Beneficio**: Un solo lugar para actualizar VSCode, dependencias, etc.

### Ventajas

1. **Mantenibilidad**: Actualizar VSCode o dependencias requiere modificar solo un archivo
2. **Consistencia**: Garantiza que DinD y DooD usan exactamente las mismas versiones
3. **Cache de Docker**: Las capas comunes se comparten entre builds
4. **Tiempo de build**: Builds incrementales más rápidos
5. **Menos errores**: No hay riesgo de que los Dockerfiles diverjan

## Actualizar VSCode

Para actualizar la versión de VSCode, solo necesitas modificar `docker/Dockerfile.base`.

El proceso es automático ya que se usa el repositorio oficial de Microsoft, pero si necesitas una versión específica:

```dockerfile
# En Dockerfile.base, modificar:
RUN apt-get install -y --no-install-recommends code=<version>
```

## Agregar Dependencias Comunes

Para agregar una dependencia que necesitan ambos modos:

```dockerfile
# En Dockerfile.base, en la sección "Dependencias base comunes":
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ... dependencias existentes ...
    tu-nueva-dependencia \
    && rm -rf /var/lib/apt/lists/*
```

## Agregar Dependencias Específicas

**Solo para DinD**:
```dockerfile
# En Dockerfile.base, en la sección "Dependencias específicas para DinD":
RUN if [ "$INSTALL_DOCKER_DAEMON" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
        # ... dependencias existentes ...
        tu-dependencia-dind \
    && rm -rf /var/lib/apt/lists/*; \
    fi
```

**Solo para DooD**: Agregar un nuevo bloque condicional similar.

## Troubleshooting

### Build falla con "COPY failed"

Si el build falla al copiar el entrypoint:
```
COPY failed: file not found in build context or excluded by .dockerignore: stat DinD/entrypoint.sh: file does not exist
```

Verifica que:
1. El `context` en docker-compose.yml es `..` (directorio padre)
2. Los archivos `DinD/entrypoint.sh` y `DooD/entrypoint.sh` existen
3. El `ENTRYPOINT_MODE` está correctamente especificado (case-sensitive)

### Build instala paquetes incorrectos

Verifica que los build args están correctamente configurados en docker-compose.yml:
```yaml
args:
  INSTALL_DOCKER_DAEMON: "true"  # Debe ser string "true" o "false"
  ENTRYPOINT_MODE: "DinD"        # Debe coincidir con el nombre del directorio
```

## Migración desde Dockerfiles Antiguos

Si necesitas rollback a los Dockerfiles originales:

1. Los backups están en:
   - `DinD/Dockerfile-vsc-wslg.backup`
   - `DooD/Dockerfile-vsc-wslg.backup`

2. Restaurar en docker-compose.yml:
   ```yaml
   build:
     context: ..
     dockerfile: DinD/Dockerfile-vsc-wslg  # o DooD/Dockerfile-vsc-wslg
   ```

3. Copiar backups:
   ```bash
   cp DinD/Dockerfile-vsc-wslg.backup DinD/Dockerfile-vsc-wslg
   cp DooD/Dockerfile-vsc-wslg.backup DooD/Dockerfile-vsc-wslg
   ```
