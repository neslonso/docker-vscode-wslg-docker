# Directorio Docker

Este directorio contiene los archivos base de Docker para el proyecto VSCode-WSLg.

## Estructura

```
docker/
├── Dockerfile.base           # Dockerfile base común para DinD y DooD
├── entrypoint.sh             # Entrypoint unificado (soporta ambos modos)
├── docker-compose.yml        # Configuración base de compose
├── docker-compose.dind.yml   # Override para modo DinD
├── docker-compose.dood.yml   # Override para modo DooD
├── lib/                      # Librerías compartidas
│   ├── docker-setup.sh       # Funciones de configuración Docker
│   └── vscode-setup.sh       # Funciones de configuración VSCode
├── test-builds.sh            # Script de testing y validación
└── README.md                 # Este archivo
```

## Dockerfile.base

El `Dockerfile.base` contiene toda la lógica común entre los modos DinD (Docker-in-Docker) y DooD (Docker-out-of-Docker), eliminando ~95% de duplicación de código.

### Build Arguments

El Dockerfile acepta los siguientes argumentos de construcción:

- **INSTALL_DOCKER_DAEMON** (default: `false`)
  - `"true"`: Instala Docker daemon completo (para DinD)
  - `"false"`: Instala solo Docker CLI (para DooD)

- **ENTRYPOINT_MODE** (default: `"dood"`)
  - `"dind"`: Modo Docker-in-Docker
  - `"dood"`: Modo Docker-out-of-Docker

## Docker Compose

El proyecto usa un patrón de **compose base + overrides** para eliminar duplicación:

- **docker-compose.yml**: Configuración común (volúmenes, variables de entorno, etc.)
- **docker-compose.dind.yml**: Específico para DinD (privileged, volumen dind-data)
- **docker-compose.dood.yml**: Específico para DooD (socket de Docker del host)

### Uso desde docker-compose

**DinD**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.dind.yml up
```

**DooD**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.dood.yml up
```

El script `vsc-wslg` maneja esto automáticamente.

### Uso desde línea de comandos

```bash
# Build DinD
docker build \
  --build-arg INSTALL_DOCKER_DAEMON=true \
  --build-arg ENTRYPOINT_MODE=dind \
  -f docker/Dockerfile.base \
  -t vscode-wslg-dind \
  .

# Build DooD
docker build \
  --build-arg INSTALL_DOCKER_DAEMON=false \
  --build-arg ENTRYPOINT_MODE=dood \
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

El proyecto ha eliminado duplicación en tres niveles:

### 1. Dockerfiles (Fase 1)
**Antes**: 2 archivos duplicados (69 + 63 líneas = 132 líneas, ~95% duplicación)
**Después**: 1 archivo base (127 líneas con documentación)
**Reducción**: ~50% código duplicado eliminado

### 2. Entrypoints (Fase 2)
**Antes**: 2 archivos casi idénticos (58 + 58 líneas = 116 líneas, ~98% duplicación)
**Después**: 1 entrypoint unificado (76 líneas)
**Reducción**: 34% código eliminado

### 3. Docker Compose (Fase 3)
**Antes**: 2 archivos completos (docker/modes/dind/ + docker/modes/dood/)
**Después**: 1 base + 2 overrides pequeños
**Reducción**: ~70% código duplicado eliminado

### Ventajas

1. **Mantenibilidad**: Un solo lugar para actualizar configuración común
2. **Consistencia**: DinD y DooD usan exactamente las mismas versiones y configuración
3. **Cache de Docker**: Las capas comunes se comparten entre builds
4. **Claridad**: Las diferencias entre modos están claramente separadas en archivos pequeños
5. **Menos errores**: No hay riesgo de que los archivos diverjan

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
COPY failed: file not found in build context or excluded by .dockerignore
```

Verifica que:
1. El `context` en docker-compose.yml apunta correctamente al directorio padre (`..`)
2. El archivo `docker/entrypoint.sh` existe
3. Los build args están correctamente especificados

### Build instala paquetes incorrectos

Verifica que los build args están correctamente configurados en los archivos de override:
```yaml
# En docker-compose.dind.yml o docker-compose.dood.yml
args:
  INSTALL_DOCKER_DAEMON: "true"  # Debe ser string "true" o "false"
  ENTRYPOINT_MODE: "dind"        # Debe ser "dind" o "dood" (lowercase)
```

### Compose no encuentra los archivos

Si `docker compose` no encuentra los archivos de configuración, verifica que estás usando:
```bash
# Desde el directorio del proyecto
docker compose -f docker/docker-compose.yml -f docker/docker-compose.dind.yml up

# O usa el script vsc-wslg que lo hace automáticamente
./vsc-wslg dind up
```
