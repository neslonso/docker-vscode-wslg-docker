# Plan de Refactorización - docker-vscode-wslg

## Resumen Ejecutivo

Este documento presenta un plan exhaustivo de refactorización para mejorar la organización, limpieza y mantenibilidad del código del proyecto docker-vscode-wslg-docker.

**Objetivo**: Eliminar duplicación de código, mejorar la modularización, establecer patrones consistentes y facilitar el mantenimiento y extensibilidad del proyecto.

**Estado actual**:
- ✅ **Fase 1 completada**: Dockerfiles consolidados (0% duplicación)
- ✅ **Mejoras extra**: Manejo elegante de instancia única
- 🔄 **En progreso**: Análisis de entrypoints para Fase 2
- ⏳ **Pendiente**: Fases 2-8

**Próximo objetivo recomendado**: **Fase 2 - Unificación de Entrypoints** (alta prioridad, elimina ~120 líneas duplicadas)

---

## 1. Problemas Identificados

### 1.1 Duplicación de Código Crítica

#### Dockerfiles (DinD/DooD)
- **Ubicación**: `DinD/Dockerfile-vsc-wslg` vs `DooD/Dockerfile-vsc-wslg`
- **Problema**: 95% del código es idéntico, solo difieren en:
  - 3-4 líneas para instalar/omitir Docker daemon
  - Referencia al entrypoint (DinD vs DooD)
- **Impacto**: Cualquier cambio (actualización de VSCode, dependencias, etc.) debe replicarse manualmente
- **Líneas duplicadas**: ~60 de 69 líneas

#### Entrypoints
- **Ubicación**: `DinD/entrypoint.sh` vs `DooD/entrypoint.sh`
- **Problema**:
  - Lógica común duplicada: configuración VSCode, instalación de extensiones, workaround WSLg, procesamiento de perfiles
  - Solo difieren en: inicio de Docker daemon (DinD) y manejo de permisos del socket (DooD)
- **Impacto**: Mejoras o fixes deben aplicarse en ambos lugares
- **Código común**: ~120 de 137 líneas

#### Scripts de Perfiles
- **Ubicación**: `profiles/*/scripts/*.sh`
- **Problema**: Scripts idénticos con solo cambios en nombres/emojis
  - `stop.sh`: 10 líneas, 90% idénticas entre perfiles
  - `logs.sh`: 8 líneas, 90% idénticas
  - `shell.sh`: 8 líneas, 100% idénticas
  - `start.sh`: Estructura idéntica, solo difiere en mensajes y validaciones
- **Impacto**: 12 archivos que podrían ser 3-4 con parámetros

#### Scripts `manage`
- **Ubicación**: `profiles/*/manage`
- **Problema**: Lógica casi idéntica de routing de comandos
  - 48 líneas por perfil
  - Solo difieren en comandos disponibles y nombres
- **Impacto**: Cualquier nuevo comando requiere actualización manual de 3+ archivos

### 1.2 Problemas de Organización

#### Falta de Separación de Responsabilidades
- **vsc-wslg**: Mezcla parsing de argumentos, validación, y ejecución de docker-compose
- **entrypoints**: Mezclan configuración base, perfiles, instalación de extensiones, workarounds

#### Ausencia de Biblioteca Común
- No hay funciones compartidas para:
  - Logging con formato consistente
  - Validación de precondiciones
  - Manejo de errores
  - Operaciones Docker comunes

#### Estructura de Directorios Poco Clara
```
lib/
  └── profile-loader.sh    # ¿Por qué solo este script está en lib/?
```
- No hay convención clara de dónde van las bibliotecas compartidas
- No hay separación entre scripts de usuario y scripts internos

### 1.3 Código Hardcodeado vs Configurable

#### Valores Hardcodeados
- Tamaño de ventana WSLg: `1024 768` (línea 73 en entrypoints)
- Timeouts: `sleep 2`, `sleep 3` dispersos por el código
- Rutas: `/home/dev/.config/Code/User` repetida múltiples veces
- Nombres de contenedores: patrón `${COMPOSE_PROJECT_NAME:-nombre}` inconsistente

#### Configuración Dispersa
- Variables de entorno definidas en múltiples lugares
- No hay un único punto de configuración
- Dificulta personalización por usuario

### 1.4 Manejo de Errores Inconsistente

- Algunos scripts usan `set -e`, otros no
- Validación de precondiciones inconsistente
- Mensajes de error con formatos diferentes
- No hay rollback en operaciones que fallan parcialmente

### 1.5 Inconsistencias entre Perfiles

| Aspecto | symfony | rust | devops |
|---------|---------|------|--------|
| Comando `shell` | ✗ | ✓ | ✓ |
| Comando `status` | ✓ (inline) | ✓ (inline) | ✓ (script) |
| Script `status.sh` | ✗ | ✗ | ✓ |
| Formato mensajes | Variado | Variado | Variado |

### 1.6 Documentación en Código

- Comentarios escasos en scripts complejos
- No hay docstrings en funciones
- Lógica compleja sin explicación (ej: workaround WSLg)
- No se documenta por qué se hacen ciertas cosas

---

## 2. Plan de Refactorización Propuesto

### Fase 1: Consolidación de Dockerfiles ✅ COMPLETADA

**Prioridad**: ALTA
**Impacto**: Alto - Reduce duplicación del 95%
**Riesgo**: Bajo - Cambio bien acotado
**Estado**: ✅ Implementado y probado

**Cambios realizados**:
- ✅ Creado `docker/Dockerfile.base` con lógica común
- ✅ Usa build args para personalización (INSTALL_DOCKER_DAEMON, ENTRYPOINT_MODE)
- ✅ DinD y DooD ahora referencian el Dockerfile base
- ✅ Reducción de ~132 líneas duplicadas a 0% duplicación

**Archivos modificados**:
- Creado: `docker/Dockerfile.base`
- Creado: `docker/README.md`
- Creado: `docker/test-builds.sh`
- Modificado: `DinD/docker-compose.yml`
- Modificado: `DooD/docker-compose.yml`
- Creado: `CHANGELOG.md`

**Mejoras adicionales implementadas (fuera del plan original)**:
- ✅ Manejo elegante de instancia única
  - Función `check_running_instances()` en `vsc-wslg`
  - Detección automática de instancias corriendo
  - Prompt interactivo con opciones claras
  - Auto-cierre de instancia anterior si el usuario elige
  - Documentado en `SINGLE_INSTANCE.md`
- ✅ Script de diagnóstico `debug-display.sh` para entender comunicación WSLg
- ✅ Documentación de limitación arquitectural (mono-instancia)

#### 2.1.1 Crear Dockerfile Base Común

**Archivo nuevo**: `docker/Dockerfile.base`

```dockerfile
# Contiene toda la lógica común:
# - Imagen base
# - Dependencias comunes
# - Instalación VSCode
# - Usuario dev
# - Librería profile-loader
# - ARG para personalización
```

**Beneficios**:
- Un solo lugar para actualizar VSCode, dependencias, etc.
- Reduces tiempo de build con cache compartida
- Facilita testing de cambios

#### 2.1.2 Crear Dockerfiles Específicos Minimalistas

**DinD**: `DinD/Dockerfile-vsc-wslg`
```dockerfile
FROM ../docker/Dockerfile.base
# Solo instalar Docker daemon + dependencias DinD
# Copiar entrypoint específico
```

**DooD**: `DooD/Dockerfile-vsc-wslg`
```dockerfile
FROM ../docker/Dockerfile.base
# Solo instalar Docker CLI
# Copiar entrypoint específico
```

**Reducción**: De 69 líneas x2 → 50 líneas base + 10 líneas x2

### Fase 2: Unificación de Entrypoints

**Prioridad**: ALTA
**Impacto**: Alto - Elimina duplicación, facilita mantenimiento
**Riesgo**: Medio - Requiere testing cuidadoso

#### 2.2.1 Crear Biblioteca de Funciones Compartidas

**Archivo nuevo**: `lib/vscode-setup.sh`

Contendrá funciones:
```bash
setup_vscode_permissions()    # Permisos en volúmenes
setup_vscode_settings()        # Merge de settings.json
install_vscode_extensions()    # Instalación de extensiones
apply_wslg_workaround()       # Fix ventana WSLg
open_profile_readme()         # Abrir README primera vez
```

**Archivo nuevo**: `lib/docker-setup.sh`

```bash
start_docker_daemon()         # Para DinD
setup_docker_socket_perms()   # Para DooD
wait_for_docker()            # Esperar a que Docker esté listo
```

**Beneficios**:
- Código testeable de forma unitaria
- Reutilizable en futuros modos
- Fácil de mantener y documentar

#### 2.2.2 Refactorizar Entrypoints

**DinD/entrypoint.sh** (reducido a ~40 líneas):
```bash
#!/bin/bash
set -e

source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

setup_vscode_permissions
start_docker_daemon
wait_for_docker
setup_vscode_settings
process_profile_if_set
apply_wslg_workaround
install_vscode_extensions
open_profile_readme
launch_vscode "$@"
```

**DooD/entrypoint.sh** (similar):
```bash
#!/bin/bash
set -e

source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

setup_vscode_permissions
setup_docker_socket_perms
setup_vscode_settings
process_profile_if_set
apply_wslg_workaround
install_vscode_extensions
open_profile_readme
launch_vscode "$@"
```

**Reducción**: De 137 líneas x2 → ~120 líneas compartidas + ~40 líneas x2

### Fase 2.5: Simplificación Radical de Perfiles ✅ COMPLETADA

**Prioridad**: ALTA
**Impacto**: Alto - Elimina complejidad innecesaria
**Riesgo**: Bajo - Simplifica arquitectura
**Estado**: ✅ Implementado

**Filosofía nueva**: Los perfiles son **solo configuración de VSCode**, no orquestación de servicios.

#### Cambios realizados:

**Eliminado** (innecesario):
- ❌ `profiles/*/scripts/` - Scripts de orquestación
- ❌ `profiles/*/manage` - Comandos de gestión
- ❌ `profiles/*/docker-compose.yml` - Servicios (van en el proyecto, no en el perfil)
- ❌ `profiles/*/services/` - Configuración de servicios

**Estructura simplificada**:
```
profiles/nombre-perfil/
├── README.md              # Documentación
└── vscode/
    ├── extensions.list    # Extensiones a instalar
    └── settings.json      # Configuración de VSCode
```

**Beneficios**:
- ✅ Perfiles son portables y autocontenidos
- ✅ Separación clara: perfil = editor, proyecto = infraestructura
- ✅ Más fácil crear nuevos perfiles (solo 2 archivos)
- ✅ Sin código duplicado (no hay scripts que duplicar)
- ✅ Menor superficie de mantenimiento

**Documentación**:
- Creado `profiles/README.md` con guía completa de perfiles
- Explica filosofía de separación de responsabilidades
- Incluye ejemplos de cómo crear perfiles
- Tips de uso y troubleshooting

**Decisión arquitectural**:
Si un proyecto necesita servicios (MySQL, Redis, etc.), debe usar su propio `docker-compose.yml` en el workspace del proyecto, no mezclarlo con la configuración del perfil de VSCode.

### Fase 4: Mejora del Script Principal

**Prioridad**: MEDIA
**Impacto**: Medio - Mejora legibilidad y mantenibilidad
**Riesgo**: Bajo

#### 2.4.1 Separar Responsabilidades

**Archivo nuevo**: `lib/vsc-wslg-core.sh`

Funciones:
```bash
parse_arguments()         # Parseo de CLI args
validate_mode()          # Validación de modo
validate_action()        # Validación de acción
validate_profile()       # Validación de perfil
get_compose_file()       # Obtener archivo compose
set_environment_vars()   # Configurar variables
execute_action()         # Ejecutar acción docker-compose
```

**vsc-wslg refactorizado**:
```bash
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/lib/vsc-wslg-core.sh"

parse_arguments "$@"
validate_inputs
set_environment_vars
execute_action
```

**Reducción**: De 137 líneas monolíticas → ~80 líneas lib + ~20 líneas main

#### 2.4.2 Mejorar Validaciones

```bash
# Validar que Docker está instalado
# Validar que el perfil existe (si se especifica)
# Validar que el modo es compatible con el sistema
# Mostrar warnings útiles
```

### Fase 5: Configuración Centralizada

**Prioridad**: BAJA
**Impacto**: Medio - Facilita personalización
**Riesgo**: Bajo

#### 2.5.1 Crear Archivo de Configuración

**Archivo nuevo**: `config/defaults.conf`

```bash
# Configuración global del proyecto
DEFAULT_WINDOW_WIDTH=1024
DEFAULT_WINDOW_HEIGHT=768
VSCODE_CONFIG_DIR="/home/dev/.config/Code/User"
DOCKER_WAIT_TIMEOUT=30
WSLG_WORKAROUND_ENABLED=true
PROFILE_MOUNT_PATH_PATTERN="/home/dev/vsc-wslg-{profile}-profile"
```

**Archivo opcional**: `.vsc-wslg.conf` (en el proyecto del usuario)

```bash
# Permite al usuario sobreescribir defaults
WINDOW_WIDTH=1920
WINDOW_HEIGHT=1080
```

#### 2.5.2 Actualizar Scripts para Usar Configuración

```bash
source /usr/local/etc/vsc-wslg/defaults.conf
[ -f ~/.vsc-wslg.conf ] && source ~/.vsc-wslg.conf

# Usar variables en lugar de valores hardcodeados
xdotool windowsize "$WID" $WINDOW_WIDTH $WINDOW_HEIGHT
```

### Fase 6: Mejoras en Manejo de Errores

**Prioridad**: MEDIA
**Impacto**: Alto - Mejora robustez y debugging
**Riesgo**: Bajo

#### 2.6.1 Biblioteca de Logging

**Archivo nuevo**: `lib/logger.sh`

```bash
log_info()     # Mensajes informativos con timestamp
log_success()  # Mensajes de éxito
log_warning()  # Advertencias
log_error()    # Errores (no fatal)
log_fatal()    # Errores fatales (exit 1)
log_debug()    # Solo si DEBUG=1
```

**Uso**:
```bash
source /usr/local/lib/logger.sh

log_info "Iniciando Docker daemon..."
docker daemon &>/dev/null || log_fatal "No se pudo iniciar Docker daemon"
log_success "Docker daemon iniciado correctamente"
```

#### 2.6.2 Validaciones Robustas

```bash
# Validar precondiciones antes de ejecutar
check_docker_installed() {
  command -v docker &>/dev/null || log_fatal "Docker no está instalado"
}

check_compose_file_exists() {
  [ -f "$1" ] || log_fatal "Archivo compose no encontrado: $1"
}

check_wslg_available() {
  [ -d /tmp/.X11-unix ] || log_warning "WSLg podría no estar disponible"
}
```

#### 2.6.3 Modo Dry-run

```bash
# Agregar flag --dry-run al script principal
# Muestra qué haría sin ejecutar

./vsc-wslg dood up symfony --dry-run
# Salida:
# Would execute: docker-compose -f .../DooD/docker-compose.yml up
# Environment variables:
#   COMPOSE_PROJECT_NAME=vsc_miproyecto
#   PROJECT_DIR=/home/user/miproyecto
#   VSCODE_EXTENSIONS_PROFILE=symfony
```

### Fase 7: Estandarización de Perfiles

**Prioridad**: BAJA
**Impacto**: Medio - Mejora consistencia
**Riesgo**: Bajo

#### 2.7.1 Definir Comandos Estándar

Todos los perfiles deben soportar:
- `start` - Levantar servicios
- `stop` - Detener servicios
- `restart` - Reiniciar servicios
- `status` - Ver estado
- `logs` - Ver logs
- `shell` - Abrir shell (si aplica)

#### 2.7.2 Template de Perfil

**Archivo nuevo**: `profiles/TEMPLATE/`

Estructura completa con:
- `README.md` template
- `docker-compose.yml` ejemplo
- `manage` pre-configurado
- `scripts/` con todos los comandos estándar
- `vscode/` con estructura recomendada

#### 2.7.3 Documentación de Creación de Perfiles

Actualizar `README.md` con:
- Guía paso a paso usando el template
- Buenas prácticas
- Ejemplos de casos de uso comunes

### Fase 8: Testing y Calidad

**Prioridad**: BAJA
**Impacto**: Alto a largo plazo
**Riesgo**: Bajo

#### 2.8.1 Scripts de Testing

**Archivo nuevo**: `tests/test-profiles.sh`

```bash
# Prueba que cada perfil:
# - Se puede construir (build)
# - Se puede iniciar (up)
# - Los comandos manage funcionan
# - Se detiene correctamente (down)
```

#### 2.8.2 Linting de Shell Scripts

```bash
# Usar shellcheck en CI/CD
find . -name "*.sh" -exec shellcheck {} \;
```

#### 2.8.3 Documentación de API

Documentar las funciones de las bibliotecas:
```bash
# lib/profile-manager.sh

##
# Inicia los servicios de un perfil
#
# Globals:
#   PROFILE_NAME - Nombre del perfil
#   SCRIPT_DIR - Directorio del perfil
# Arguments:
#   None
# Outputs:
#   Mensajes de progreso a stdout
# Returns:
#   0 si éxito, 1 si error
##
profile_start() {
  ...
}
```

---

## 3. Nueva Estructura de Directorios Propuesta

```
.
├── vsc-wslg                      # Script principal (simplificado)
├── config/
│   └── defaults.conf             # Configuración por defecto
├── lib/                          # Bibliotecas compartidas
│   ├── vsc-wslg-core.sh         # Lógica core del script principal
│   ├── vscode-setup.sh          # Setup de VSCode
│   ├── docker-setup.sh          # Setup de Docker (DinD/DooD)
│   ├── profile-loader.sh        # Carga de perfiles (existente, mejorado)
│   ├── profile-manager.sh       # Gestión de perfiles
│   ├── profile-manage-base.sh   # Base para scripts manage
│   └── logger.sh                # Logging estandarizado
├── docker/
│   ├── Dockerfile.base          # Dockerfile base común
│   └── scripts/                 # Scripts auxiliares de build
├── DinD/
│   ├── Dockerfile-vsc-wslg     # Extiende base, específico DinD
│   ├── docker-compose.yml      # Sin cambios
│   └── entrypoint.sh           # Simplificado
├── DooD/
│   ├── Dockerfile-vsc-wslg     # Extiende base, específico DooD
│   ├── docker-compose.yml      # Sin cambios
│   └── entrypoint.sh           # Simplificado
├── profiles/
│   ├── TEMPLATE/               # Template para nuevos perfiles
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   ├── manage
│   │   ├── scripts/
│   │   ├── services/
│   │   └── vscode/
│   ├── symfony/                # Simplificado
│   ├── rust/                   # Simplificado
│   └── devops/                 # Simplificado
├── tests/
│   ├── test-profiles.sh        # Tests de perfiles
│   └── test-core.sh            # Tests de funcionalidad core
├── docs/
│   ├── architecture.md         # Arquitectura del proyecto
│   ├── creating-profiles.md    # Guía de creación de perfiles
│   └── troubleshooting.md      # Resolución de problemas
└── README.md                    # Actualizado
```

**Mejoras**:
- Separación clara entre config, código, tests, docs
- `lib/` contiene TODAS las bibliotecas
- `docker/` agrupa todo lo relacionado con Docker builds
- `tests/` para mantener calidad
- `docs/` para documentación extendida

---

## 4. Estrategia de Implementación

### 4.1 Orden Recomendado

1. **Fase 6 (parcial)**: Implementar `lib/logger.sh` primero
   - Permite usar logging consistente en todas las fases siguientes
   - Bajo riesgo, alto beneficio

2. **Fase 3**: Biblioteca común para scripts de perfiles
   - Alta reducción de duplicación
   - Bajo riesgo
   - No afecta funcionalidad principal (solo perfiles)

3. **Fase 1**: Consolidación de Dockerfiles
   - Alto impacto
   - Requiere testing pero es acotado
   - Facilita fases posteriores

4. **Fase 2**: Unificación de entrypoints
   - Requiere las bibliotecas de Fase 3
   - Riesgo medio, requiere testing exhaustivo

5. **Fase 4**: Mejora del script principal
   - Beneficia de bibliotecas anteriores
   - Mejora UX

6. **Fase 7**: Estandarización de perfiles
   - Beneficia de toda la infraestructura previa

7. **Fase 5**: Configuración centralizada
   - Nice to have, se puede hacer en paralelo

8. **Fase 8**: Testing y calidad
   - Continuo durante todas las fases

### 4.2 Enfoque Incremental

**Rama de desarrollo**: `refactor/code-organization`

**Por cada fase**:
1. Crear nueva funcionalidad (sin romper la existente)
2. Migrar un componente como prueba
3. Testing exhaustivo
4. Migrar resto de componentes
5. Deprecar código antiguo (comentar, no eliminar aún)
6. Commit y documentar

**Rollback seguro**: Mantener código antiguo comentado hasta que todo funcione

### 4.3 Testing

**Por cada cambio**:
- [ ] Build exitoso de imágenes DinD y DooD
- [ ] `up` funciona con perfil symfony
- [ ] `up` funciona con perfil rust
- [ ] `up` funciona con perfil devops
- [ ] `up` funciona sin perfil
- [ ] Extensiones se instalan correctamente
- [ ] Settings se aplican correctamente
- [ ] Comandos `manage` funcionan en cada perfil
- [ ] Workaround WSLg funciona
- [ ] Modo DinD: Docker daemon arranca
- [ ] Modo DooD: Docker socket accesible

---

## 5. Métricas de Éxito

### 5.1 Reducción de Duplicación

| Componente | Antes | Después | Reducción |
|------------|-------|---------|-----------|
| Dockerfiles | 138 líneas (69x2) | 70 líneas (50+10x2) | ~49% |
| Entrypoints | 274 líneas (137x2) | 200 líneas (120+40x2) | ~27% |
| Scripts perfiles | ~162 líneas | ~50 líneas | ~69% |
| Scripts manage | ~144 líneas (48x3) | ~36 líneas (12x3) | ~75% |
| **TOTAL** | **~718 líneas** | **~356 líneas** | **~50%** |

### 5.2 Mantenibilidad

**Antes**:
- Actualizar VSCode: modificar 2 Dockerfiles
- Añadir logging: modificar 10+ archivos
- Nuevo comando perfil: modificar 3+ archivos
- Fix en extensiones: modificar 2 entrypoints

**Después**:
- Actualizar VSCode: modificar 1 Dockerfile base
- Añadir logging: usar `lib/logger.sh` existente
- Nuevo comando perfil: modificar 1 archivo lib
- Fix en extensiones: modificar 1 función en 1 archivo

### 5.3 Extensibilidad

**Tiempo para crear nuevo perfil**:
- Antes: ~30-45 min (copiar/pegar, adaptar scripts)
- Después: ~10-15 min (usar template, configurar)

### 5.4 Calidad de Código

- [ ] 0 duplicación de lógica de negocio
- [ ] 100% de scripts con `set -e`
- [ ] 100% de funciones principales documentadas
- [ ] Logging consistente en todos los scripts
- [ ] Todas las precondiciones validadas

---

## 6. Riesgos y Mitigaciones

### Riesgo 1: Romper funcionalidad existente
**Mitigación**:
- Testing exhaustivo después de cada fase
- Mantener código antiguo hasta validar nuevo
- Commits atómicos con posibilidad de rollback

### Riesgo 2: Complejidad añadida
**Mitigación**:
- Documentar cada función y biblioteca
- Ejemplos claros de uso
- No sobre-ingenierizar (YAGNI principle)

### Riesgo 3: Tiempo de implementación
**Mitigación**:
- Priorizar fases por ROI
- Implementación incremental
- Se puede pausar entre fases

### Riesgo 4: Compatibilidad con proyectos existentes
**Mitigación**:
- No cambiar nombres de comandos públicos
- Variables de entorno mantienen compatibilidad
- Documentar cualquier breaking change

---

## 7. Estimación de Esfuerzo

| Fase | Tiempo Estimado | Prioridad |
|------|----------------|-----------|
| Fase 1: Dockerfiles | 2-3 horas | ALTA |
| Fase 2: Entrypoints | 4-5 horas | ALTA |
| Fase 3: Scripts perfiles | 3-4 horas | MEDIA |
| Fase 4: Script principal | 2-3 horas | MEDIA |
| Fase 5: Configuración | 1-2 horas | BAJA |
| Fase 6: Errores/logging | 2-3 horas | MEDIA |
| Fase 7: Estandarización | 2-3 horas | BAJA |
| Fase 8: Testing/docs | 3-4 horas | BAJA |
| **TOTAL** | **19-27 horas** | |

**Enfoque recomendado**:
- Sprint 1 (1 semana): Fases 6 (parcial), 3, 1
- Sprint 2 (1 semana): Fases 2, 4
- Sprint 3 (1 semana): Fases 7, 5, 8

---

## 8. Beneficios a Largo Plazo

1. **Mantenibilidad**: Cambios centralizados, fáciles de aplicar
2. **Extensibilidad**: Nuevos perfiles en minutos, no horas
3. **Calidad**: Código testeable, menos bugs
4. **Onboarding**: Más fácil para nuevos contribuidores entender el proyecto
5. **Documentación**: Código auto-documentado con funciones bien nombradas
6. **Performance**: Posibilidad de optimizar funciones compartidas
7. **Evolución**: Base sólida para futuras features (ej: otros modos además de DinD/DooD)

---

## 9. Conclusión

Este plan de refactorización aborda de manera sistemática los problemas de organización y duplicación de código identificados en el proyecto. La implementación incremental minimiza riesgos mientras maximiza beneficios.

**Recomendación**: Comenzar con las fases de alta prioridad (1, 2, 3, 6) que dan el mayor ROI en términos de reducción de duplicación y mejora de mantenibilidad.

El resultado será un codebase más limpio, mantenible y extensible, facilitando tanto el desarrollo futuro como la incorporación de nuevos contribuidores.
