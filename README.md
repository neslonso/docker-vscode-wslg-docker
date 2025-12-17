# VSCode Containerizado con WSLg

Entorno de desarrollo completamente aislado para ejecutar VSCode dentro de un contenedor Docker, renderizando la interfaz gráfica a través de WSLg (Windows Subsystem for Linux GUI).

## Motivación

Cuando se trabaja en múltiples proyectos con diferentes stacks tecnológicos, mantener un entorno de desarrollo limpio y reproducible se convierte en un desafío. Esta solución aborda el problema ejecutando VSCode dentro de contenedores Docker, lo que proporciona:

- **Aislamiento completo**: cada proyecto tiene su propio entorno sin contaminar el sistema host.
- **Reproducibilidad**: el mismo entorno funciona de manera idéntica en cualquier máquina con WSL2.
- **Perfiles de extensiones**: conjuntos predefinidos de extensiones según el tipo de proyecto.
- **Integración con Docker**: capacidad de ejecutar contenedores dentro del entorno de desarrollo.

## Requisitos previos

- Windows 10/11 con WSL2
- Una distribución Linux instalada en WSL (por ejemplo, Ubuntu 22.04)
- Docker instalado en WSL
- WSLg habilitado (incluido por defecto en Windows 11 y actualizaciones recientes de Windows 10)

## Estructura del proyecto

```
.
├── vsc-wslg                 # Script principal de control
├── DinD/                    # Configuración Docker-in-Docker
│   ├── Dockerfile-vsc-wslg
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── DooD/                    # Configuración Docker-out-of-Docker
│   ├── Dockerfile-vsc-wslg
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── lib/                     # Bibliotecas auxiliares
│   └── profile-loader.sh    # Carga perfiles y muestra info
└── profiles/                # Perfiles de desarrollo
    ├── symfony/             # Perfil para Symfony/PHP
    │   ├── profile.yml      # Metadata + info de infraestructura
    │   ├── docker-compose.yml  # Servicios (PHP, MySQL, Redis)
    │   ├── manage           # Script de gestión
    │   ├── scripts/         # Scripts individuales
    │   │   ├── start.sh
    │   │   ├── stop.sh
    │   │   └── logs.sh
    │   ├── services/        # Dockerfiles de servicios
    │   │   └── php/
    │   │       └── Dockerfile
    │   ├── vscode/          # Config de VSCode
    │   │   ├── extensions.list
    │   │   └── settings.json
    │   └── README.md
    └── rust/                # Perfil para Rust
        ├── profile.yml
        ├── docker-compose.yml  # Contenedor Rust toolchain
        ├── manage
        ├── scripts/
        ├── services/
        │   └── rust/
        │       └── Dockerfile
        ├── vscode/
        │   ├── extensions.list
        │   └── settings.json
        └── README.md
```

## Modos de operación

### DooD (Docker-out-of-Docker)

El contenedor utiliza el daemon Docker del host mediante el montaje de `/var/run/docker.sock`. Los contenedores creados desde VSCode aparecen en el Docker del host.

**Ventajas**: imagen más ligera, arranque más rápido, recursos compartidos.

**Consideraciones**: los contenedores creados son visibles desde el host y comparten el mismo espacio de nombres de redes e imágenes.

### DinD (Docker-in-Docker)

El contenedor ejecuta su propio daemon Docker de forma independiente. Requiere modo privilegiado.

**Ventajas**: aislamiento completo, el entorno Docker es efímero y específico del proyecto.

**Consideraciones**: mayor consumo de recursos, requiere `privileged: true`.

## Instalación

1. Clonar el repositorio en una ubicación accesible desde WSL:

```bash
git clone https://github.com/tu-usuario/vscode-wslg-docker.git
cd vscode-wslg-docker
```

2. Hacer ejecutable el script principal:

```bash
chmod +x vsc-wslg
```

3. Opcionalmente, añadir al PATH o crear un alias:

```bash
# En ~/.bashrc o ~/.zshrc
alias vsc='/ruta/al/repositorio/vsc-wslg'
```

## Uso

El script se ejecuta desde el directorio del proyecto que se desea abrir y :

```bash
cd /ruta/a/mi/proyecto
/ruta/al/repositorio/vsc-wslg <modo> <acción> [perfil]
```

IMPORTANTE:
Solo el nombre del directorio desde donde se ejecuta el script es utilizado para los volumenes de docker.
Esto siginifica que si lanzas el scripts desde dos directorios con el mismo nombre (aunque rutas distintas) utilizaran los mismos volumnes de docker.

### Acciones disponibles

| Acción     | Descripción                                           |
|------------|-------------------------------------------------------|
| `build`    | Reconstruye la imagen Docker                          |
| `up`       | Lanza VSCode en primer plano (se detiene al cerrar)   |
| `upd`      | Lanza VSCode en segundo plano                         |
| `upd-logs` | Lanza en segundo plano mostrando logs                 |
| `down`     | Detiene el contenedor                                 |
| `clean`    | Detiene el contenedor y elimina volúmenes asociados   |

### Ejemplos

```bash
# Lanzar VSCode con modo DooD y perfil Symfony
./vsc-wslg dood up symfony

# Lanzar en segundo plano con DinD
./vsc-wslg dind upd symfony

# Detener el contenedor
./vsc-wslg dood down

# Limpiar completamente (elimina extensiones y configuración del proyecto)
./vsc-wslg dood clean
```

## Perfiles de desarrollo

Los perfiles permiten configurar entornos completos según el tipo de proyecto. Cada perfil incluye:

- **VSCode**: Extensiones y configuraciones personalizadas
- **Infraestructura**: Servicios separados (bases de datos, toolchains, etc.) gestionados con docker-compose
- **Scripts de gestión**: Comandos para iniciar/detener/gestionar los servicios
- **Metadatos**: Descripción, versión, información para el usuario

### Arquitectura de perfiles

```
┌─────────────────────────────────────────────────┐
│  VSCode Container (GUI)                         │
│  - Solo VSCode + extensiones                    │
│  - No contiene toolchains ni servicios          │
│  - Monta: ~/vsc-wslg-{perfil}-profile (RO)     │
└────────────────┬────────────────────────────────┘
                 │
                 │ Acceso via docker-compose
                 ↓
┌─────────────────────────────────────────────────┐
│  Infraestructura del Perfil                     │
│  - PHP, MySQL, Redis (Symfony)                  │
│  - Rust toolchain (Rust)                        │
│  - Servicios específicos del proyecto           │
└─────────────────────────────────────────────────┘
```

### Estructura de un perfil

```
profiles/
└── nombre-perfil/
    ├── profile.yml           # Metadata + info de infraestructura
    ├── docker-compose.yml    # Servicios de infraestructura
    ├── manage                # Script único de gestión
    ├── scripts/              # Scripts individuales
    │   ├── start.sh
    │   ├── stop.sh
    │   └── logs.sh
    ├── services/             # Dockerfiles de servicios
    │   └── servicio/
    │       └── Dockerfile
    ├── vscode/               # Configuraciones VSCode
    │   ├── extensions.list
    │   └── settings.json
    └── README.md             # Documentación del perfil
```

### Perfiles incluidos

#### Symfony (PHP)

Stack completo para desarrollo PHP con Symfony Framework.

**Infraestructura (servicios separados):**
- PHP 8.2-fpm con Composer y Symfony CLI
- MySQL 8.0
- Redis 7

**Extensiones VSCode:**
- PHP IntelliSense, Xdebug, DocBlocker
- Soporte para Symfony y Twig
- YAML, XML, archivos de entorno
- PHPUnit y PHP CS Fixer
- GitLens, Docker

**Uso:**
```bash
# 1. Levantar VSCode
./vsc-wslg dood up symfony

# 2. Desde el terminal de VSCode, levantar infraestructura
~/vsc-wslg-symfony-profile/manage start

# 3. Trabajar normalmente
composer install
bin/console doctrine:migrations:migrate
```

**Gestión:**
```bash
~/vsc-wslg-symfony-profile/manage {start|stop|restart|logs|status}
```

#### Rust

Entorno para desarrollo Rust con soporte para compilación cruzada a Windows.

**Infraestructura (servicio separado):**
- Contenedor Rust con toolchain completo
- Targets: Linux y Windows (x86_64-pc-windows-gnu)
- MinGW-w64 para cross-compilation
- Componentes: clippy, rustfmt, rust-src
- Cargo tools: watch, edit, expand, tree

**Extensiones VSCode:**
- rust-analyzer (LSP)
- CodeLLDB (debugger)
- crates (gestor de dependencias)
- Even Better TOML

**Uso:**
```bash
# 1. Levantar VSCode
./vsc-wslg dood up rust

# 2. Desde el terminal de VSCode, levantar contenedor Rust
~/vsc-wslg-rust-profile/manage start

# 3. Compilar
cargo build --release                                # Linux
cargo build --target x86_64-pc-windows-gnu --release # Windows
```

**Gestión:**
```bash
~/vsc-wslg-rust-profile/manage {start|stop|restart|logs|shell|status}
```

### Crear un perfil personalizado

1. **Crear estructura base:**

```bash
mkdir -p profiles/mi-perfil/{vscode,services,scripts}
cd profiles/mi-perfil
```

2. **Crear `profile.yml`** con metadata e información:

```yaml
name: "Mi Perfil"
version: "1.0.0"
description: "Descripción del perfil"
tags:
  - tag1
  - tag2

infrastructure:
  description: "Descripción de la infraestructura"

  services:
    - name: "Servicio1"
      version: "1.0"
      description: "Descripción del servicio"

  next_steps:
    - "Levantar infraestructura: ~/vsc-wslg-mi-perfil-profile/manage start"
    - "Otros pasos necesarios"

  manage_script: "~/vsc-wslg-mi-perfil-profile/manage"
  commands:
    - name: "start"
      description: "Levantar servicios"
    - name: "stop"
      description: "Detener servicios"
```

3. **Crear `docker-compose.yml`** para la infraestructura:

```yaml
version: '3.8'

services:
  mi-servicio:
    build: ./services/mi-servicio
    container_name: ${COMPOSE_PROJECT_NAME:-miperfil}_servicio
    volumes:
      - ${WORKSPACE_DIR:-/workspace}:/workspace:cached
    working_dir: /workspace
    restart: unless-stopped
```

4. **Crear Dockerfile del servicio** en `services/mi-servicio/Dockerfile`

5. **Crear script `manage`**:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="/workspace"
export WORKSPACE_DIR COMPOSE_PROJECT_NAME

case "$1" in
    start) bash "$SCRIPT_DIR/scripts/start.sh" ;;
    stop) bash "$SCRIPT_DIR/scripts/stop.sh" ;;
    *) echo "Uso: $0 {start|stop}"; exit 1 ;;
esac
```

6. **Crear scripts** en `scripts/`:
   - `start.sh`: docker-compose up
   - `stop.sh`: docker-compose down

7. **Configurar VSCode** en `vscode/`:
   - `extensions.list`: extensiones a instalar
   - `settings.json`: configuraciones personalizadas

8. **Utilizarlo:**

```bash
./vsc-wslg dood up mi-perfil
```

### Funcionamiento de los perfiles

Al arrancar VSCode con un perfil:

1. **Muestra información**: Lee `profile.yml` y muestra servicios, pasos siguientes, comandos disponibles
2. **Monta perfil**: El perfil se monta en `~/vsc-wslg-{perfil}-profile` (read-only)
3. **Aplica configuraciones**: Merge inteligente de `settings.json` (usuario tiene prioridad)
4. **Instala extensiones**: Lee `vscode/extensions.list` e instala las necesarias

La infraestructura es **independiente** y se gestiona **manualmente** desde el terminal de VSCode usando los scripts del perfil

## Persistencia

El sistema mantiene persistencia entre sesiones mediante volúmenes Docker nombrados según el proyecto:

- `{proyecto}_vscode-extensions`: extensiones instaladas
- `{proyecto}_vscode-config`: configuración de VSCode
- `{proyecto}_dind-data`: datos de Docker (solo en modo DinD)

Esto permite que cada proyecto mantenga su propia configuración de forma independiente.

## Notas

- El entrypoint ajusta automáticamente los permisos del socket. Si hay problemas, verificar que el usuario de WSL pertenece al grupo `docker`:

```bash
groups $USER
```

## Arquitectura técnica

El sistema utiliza las siguientes tecnologías:

- **Debian Bookworm**: imagen base ligera y estable
- **WSLg**: permite renderizar aplicaciones GUI de Linux en Windows mediante X11/Wayland
- **xdotool**: gestión de ventanas para el workaround de posicionamiento
- **jq**: manipulación de configuración JSON

La interfaz gráfica se transmite al host Windows mediante los volúmenes de WSLg:
- `/tmp/.X11-unix`: socket X11
- `/mnt/wslg`: runtime de Wayland y PulseAudio

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Abrir un issue describiendo el cambio propuesto
2. Crear un fork del repositorio
3. Desarrollar en una rama con nombre descriptivo
4. Enviar un pull request

## Licencia

Este proyecto está licenciado bajo la [MIT License](LICENSE).
