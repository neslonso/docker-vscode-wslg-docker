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
│   └── profile-loader.sh
└── profiles/                # Perfiles de desarrollo
    ├── symfony/             # Perfil para Symfony/PHP
    │   ├── profile.yml
    │   ├── extensions.list
    │   ├── install.sh
    │   ├── vscode/
    │   │   └── settings.json
    │   └── README.md
    └── rust/                # Perfil para Rust
        ├── profile.yml
        ├── extensions.list
        ├── install.sh
        ├── vscode/
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

Los perfiles permiten configurar entornos completos según el tipo de proyecto. Cada perfil es un directorio que puede incluir:

- **Extensiones de VSCode**: lista de extensiones a instalar
- **Paquetes del sistema**: herramientas y dependencias del SO
- **Configuraciones de VSCode**: settings personalizados por perfil
- **Metadatos**: descripción, versión, tags

### Estructura de un perfil

```
profiles/
└── nombre-perfil/
    ├── profile.yml           # Metadatos (nombre, descripción, versión)
    ├── extensions.list       # Lista de extensiones VSCode
    ├── install.sh            # Script para instalar paquetes del SO
    ├── vscode/               # Configuraciones VSCode específicas
    │   ├── settings.json     # Settings personalizados
    │   └── keybindings.json  # (opcional) Atajos de teclado
    └── README.md             # (opcional) Documentación
```

### Perfiles incluidos

#### Symfony (PHP)

Entorno completo para desarrollo PHP con Symfony Framework.

**Herramientas instaladas:**
- PHP 8.x con extensiones (xml, mbstring, curl, zip, intl, etc.)
- Composer (gestor de dependencias PHP)
- Symfony CLI

**Extensiones VSCode:**
- PHP IntelliSense, Xdebug, DocBlocker
- Soporte para Symfony y Twig
- YAML, XML y archivos de entorno
- PHPUnit y PHP CS Fixer
- GitLens, Docker

**Uso:**
```bash
./vsc-wslg dood up symfony
```

#### Rust

Entorno completo para desarrollo Rust con soporte para compilación cruzada a Windows.

**Herramientas instaladas:**
- Rust toolchain (stable) vía rustup
- Target Linux: `x86_64-unknown-linux-gnu`
- Target Windows: `x86_64-pc-windows-gnu`
- MinGW-w64 para cross-compilation
- Componentes: clippy, rustfmt, rust-src
- Cargo tools: cargo-watch, cargo-edit, cargo-expand, cargo-tree

**Extensiones VSCode:**
- rust-analyzer (LSP)
- CodeLLDB (debugger)
- crates (gestor de dependencias)
- Even Better TOML

**Uso:**
```bash
./vsc-wslg dood up rust

# Compilar para Linux (por defecto)
cargo build --release

# Compilar para Windows
cargo build --target x86_64-pc-windows-gnu --release
```

### Crear un perfil personalizado

1. Crear el directorio del perfil:

```bash
mkdir -p profiles/mi-perfil/vscode
cd profiles/mi-perfil
```

2. Crear `profile.yml` con metadatos:

```yaml
name: "Mi Perfil"
description: "Descripción del perfil"
version: "1.0.0"
tags:
  - tag1
  - tag2
```

3. Crear `extensions.list` con extensiones VSCode:

```
# Comentarios con almohadilla
publisher.extension-name
otro-publisher.otra-extension
```

4. Crear `install.sh` para instalar herramientas del SO:

```bash
#!/bin/bash
set -e

echo "🔧 Instalando herramientas..."

# Actualizar repositorios
sudo apt-get update -qq

# Instalar paquetes necesarios
PACKAGES=("git" "curl" "build-essential")

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        echo "  → Instalando $pkg"
        sudo apt-get install -y "$pkg" >/dev/null 2>&1
    else
        echo "  ✓ Ya instalado: $pkg"
    fi
done

echo "✓ Herramientas instaladas"
```

5. (Opcional) Crear `vscode/settings.json` con configuraciones:

```json
{
  "editor.formatOnSave": true,
  "editor.tabSize": 2
}
```

6. Utilizarlo al lanzar:

```bash
./vsc-wslg dood up mi-perfil
```

### Funcionamiento de los perfiles

Al arrancar un contenedor con un perfil:

1. **Instalación del SO**: Ejecuta `install.sh` si existe (con cache basado en hash)
2. **Configuraciones VSCode**: Aplica settings con merge inteligente (el usuario tiene prioridad)
3. **Extensiones**: Instala las extensiones listadas en `extensions.list`

El sistema incluye:
- **Cache de instalaciones**: Solo reinstala si `install.sh` cambia
- **Validación de seguridad**: Detecta comandos peligrosos en scripts
- **Merge de settings**: Las configuraciones del perfil no sobreescriben las del usuario

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
