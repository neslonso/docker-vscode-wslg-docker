# Perfil DevOps

Entorno completo para desarrollo de infraestructura, scripting y DevOps.

## Características

### Herramientas instaladas (en contenedor separado)

#### Shell/Bash
- **ShellCheck** (v0.10.0) - Linter para scripts bash
- **shfmt** (v3.8.0) - Formateo automático de scripts bash
- **bats** - Framework de testing para bash
  - bats-support - Helpers para tests
  - bats-assert - Aserciones para tests

#### Docker
- **hadolint** (v2.12.0) - Linter para Dockerfiles
- **dive** (v0.12.0) - Análisis de capas de imágenes Docker

#### YAML/JSON
- **yamllint** - Validador y linter YAML
- **yq** (v4.40.5) - Procesador YAML (como jq pero para YAML)
- **jq** - Procesador JSON

#### Otras herramientas
- Git, vim, nano, curl, wget
- Build essentials (make, gcc, etc.)
- Python 3 con pip

### Extensiones de VSCode

#### Docker
- **Docker** (ms-azuretools.vscode-docker) - Gestión de contenedores
- **Remote Containers** (ms-vscode-remote.remote-containers) - Desarrollo en contenedores

#### Shell/Bash
- **ShellCheck** (timonwong.shellcheck) - Linter integrado
- **Bash Debug** (rogalmic.bash-debug) - Debugger para bash
- **shell-format** (foxundermoon.shell-format) - Formateo automático

#### YAML
- **YAML** (redhat.vscode-yaml) - Soporte completo YAML con schemas

#### Markdown
- **Markdown All in One** (yzhang.markdown-all-in-one) - Edición Markdown
- **Markdown Preview GitHub Styles** (bierner.markdown-preview-github-styles) - Preview estilo GitHub

#### Git
- **Git Graph** (mhutchie.git-graph) - Visualización de historial

#### Utilidades
- **EditorConfig** (editorconfig.editorconfig) - Configuración consistente
- **Todo Tree** (gruntfuggly.todo-tree) - Gestión de TODOs
- **Code Spell Checker** (streetsidesoftware.code-spell-checker) - Corrector ortográfico

### Configuraciones VSCode

- ShellCheck habilitado y ejecutado en save
- Formateo automático de bash con shfmt (indent 2 espacios)
- Validación YAML con schemas de docker-compose
- Format on save activado
- Asociaciones de archivos (vsc-wslg, manage → shellscript)
- Rulers a 80 y 120 columnas
- Git autofetch habilitado

## Uso

### 1. Levantar VSCode con perfil DevOps

```bash
./vsc-wslg dood up devops
```

### 2. Levantar infraestructura de herramientas

Desde el terminal integrado de VSCode:

```bash
~/vsc-wslg-devops-profile/manage start
```

### 3. Trabajar con las herramientas

#### Opción A: Ejecutar comandos directamente

```bash
# Validar script bash
docker compose exec shell-tools shellcheck mi-script.sh

# Formatear script bash
docker compose exec shell-tools shfmt -w mi-script.sh

# Validar Dockerfile
docker compose exec shell-tools hadolint Dockerfile

# Validar YAML
docker compose exec shell-tools yamllint docker-compose.yml

# Procesar YAML
docker compose exec shell-tools yq '.services.*.image' docker-compose.yml

# Analizar imagen Docker
docker compose exec shell-tools dive mi-imagen:latest
```

#### Opción B: Shell interactiva

```bash
# Abrir shell en el contenedor de herramientas
~/vsc-wslg-devops-profile/manage shell

# Ahora estás dentro del contenedor, ejecuta lo que necesites:
shellcheck *.sh
shfmt -w scripts/*.sh
hadolint Dockerfile
yamllint *.yml
```

## Gestión de infraestructura

El script `manage` proporciona comandos para gestionar el contenedor de herramientas:

```bash
# Levantar contenedor
~/vsc-wslg-devops-profile/manage start

# Detener contenedor
~/vsc-wslg-devops-profile/manage stop

# Reiniciar contenedor
~/vsc-wslg-devops-profile/manage restart

# Ver logs
~/vsc-wslg-devops-profile/manage logs

# Abrir shell interactiva
~/vsc-wslg-devops-profile/manage shell

# Ver estado
~/vsc-wslg-devops-profile/manage status
```

## Testing de scripts Bash con bats

### Estructura recomendada

```
proyecto/
├── scripts/
│   └── mi-script.sh
└── tests/
    └── mi-script.bats
```

### Ejemplo de test

```bash
# tests/mi-script.bats
#!/usr/bin/env bats

load '/opt/bats/bats-support/load'
load '/opt/bats/bats-assert/load'

@test "mi-script debe retornar 0 en caso de éxito" {
  run ./scripts/mi-script.sh
  assert_success
}

@test "mi-script debe imprimir mensaje de ayuda con --help" {
  run ./scripts/mi-script.sh --help
  assert_output --partial "Uso:"
}
```

### Ejecutar tests

```bash
# Desde shell del contenedor
~/vsc-wslg-devops-profile/manage shell
bats tests/

# O directamente
docker compose exec shell-tools bats /workspace/tests/
```

## Comandos útiles

### ShellCheck (validación de scripts)

```bash
# Validar un script
shellcheck script.sh

# Validar todos los scripts
shellcheck **/*.sh

# Validar con severidad específica
shellcheck -S warning script.sh

# Excluir reglas específicas
shellcheck -e SC2034 script.sh
```

### shfmt (formateo de scripts)

```bash
# Formatear un script (salida a stdout)
shfmt script.sh

# Formatear y sobrescribir
shfmt -w script.sh

# Formatear todos los scripts
shfmt -w **/*.sh

# Usar indent de 2 espacios
shfmt -i 2 -w script.sh
```

### hadolint (validación de Dockerfiles)

```bash
# Validar Dockerfile
hadolint Dockerfile

# Validar con formato específico
hadolint --format json Dockerfile

# Ignorar reglas específicas
hadolint --ignore DL3008 Dockerfile
```

### yamllint (validación YAML)

```bash
# Validar archivo YAML
yamllint docker-compose.yml

# Validar todos los YAML
yamllint *.yml

# Formato parseable
yamllint -f parsable docker-compose.yml
```

### yq (procesamiento YAML)

```bash
# Leer valor
yq '.services.web.image' docker-compose.yml

# Modificar valor
yq '.services.web.image = "nginx:latest"' -i docker-compose.yml

# Convertir YAML a JSON
yq -o json docker-compose.yml

# Merge de archivos YAML
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' file1.yml file2.yml
```

### dive (análisis de imágenes)

```bash
# Analizar imagen (modo interactivo)
dive mi-imagen:latest

# Análisis no interactivo con CI
CI=true dive mi-imagen:latest
```

## Integración con VSCode

### ShellCheck integrado

VSCode mostrará warnings y errors de ShellCheck directamente en el editor mientras escribes scripts bash.

### Formateo automático

Los scripts bash se formatearán automáticamente al guardar gracias a shell-format.

### YAML Schemas

Los archivos docker-compose.yml tendrán autocompletado y validación gracias al schema configurado.

### Debugging de Bash

Puedes debuggear scripts bash directamente desde VSCode:

1. Coloca breakpoints en tu script
2. Presiona F5 o usa "Run > Start Debugging"
3. Selecciona "Bash Debug" si se solicita

## Casos de uso

### Desarrollo de este proyecto (docker-vscode-wslg-docker)

Este perfil es ideal para trabajar sobre el propio proyecto:

```bash
# 1. Levantar VSCode con el perfil
cd /ruta/a/docker-vscode-wslg-docker
./vsc-wslg dood up devops

# 2. Levantar herramientas
~/vsc-wslg-devops-profile/manage start

# 3. Validar scripts
~/vsc-wslg-devops-profile/manage shell
shellcheck vsc-wslg
shellcheck lib/*.sh
shellcheck profiles/*/scripts/*.sh

# 4. Formatear scripts
shfmt -w -i 2 profiles/devops/scripts/*.sh

# 5. Validar Dockerfiles
hadolint DooD/Dockerfile-vsc-wslg
hadolint DinD/Dockerfile-vsc-wslg
hadolint profiles/*/services/*/Dockerfile

# 6. Validar docker-compose
yamllint DooD/docker-compose.yml
yamllint profiles/*/docker-compose.yml
```

### Desarrollo de scripts de automatización

```bash
# Crear nuevo script
vim scripts/deploy.sh

# Validar mientras desarrollas (VSCode hace esto automáticamente)
shellcheck scripts/deploy.sh

# Formatear
shfmt -w scripts/deploy.sh

# Crear tests
vim tests/deploy.bats

# Ejecutar tests
bats tests/deploy.bats
```

### Mantenimiento de infraestructura Docker

```bash
# Validar Dockerfiles antes de build
hadolint Dockerfile

# Analizar imagen construida
dive mi-imagen:latest

# Validar docker-compose
yamllint docker-compose.yml

# Procesar configuraciones YAML
yq '.services.*.ports' docker-compose.yml
```

## Tips y mejores prácticas

### Scripts Bash

1. **Siempre usa shebang**: `#!/bin/bash` o `#!/usr/bin/env bash`
2. **Habilita modo estricto**: `set -euo pipefail`
3. **Valida con ShellCheck** antes de commit
4. **Escribe tests** con bats para scripts críticos

### Dockerfiles

1. **Ordena comandos** de menos a más cambiante (cache)
2. **Usa .dockerignore** para excluir archivos innecesarios
3. **Multi-stage builds** para imágenes de producción
4. **Valida con hadolint** antes de commit

### docker-compose

1. **Usa versión 3.8+** del formato
2. **Nombra contenedores** explícitamente
3. **Define networks** personalizadas
4. **Valida con yamllint** antes de commit

### Git

1. **Commits pequeños y atómicos**
2. **Mensajes descriptivos**
3. **Usa Git Graph** para explorar historial y visualizar ramas

## Solución de problemas

### ShellCheck no funciona en VSCode

Verifica que la extensión esté instalada:
```bash
code --list-extensions | grep shellcheck
```

### Herramientas no disponibles

Reconstruye el contenedor:
```bash
cd ~/vsc-wslg-devops-profile
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Permisos de Docker socket

El contenedor debe tener acceso a `/var/run/docker.sock`. Esto se configura automáticamente en el docker-compose.yml.

## Referencias

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [shfmt](https://github.com/mvdan/sh)
- [bats-core](https://github.com/bats-core/bats-core)
- [hadolint](https://github.com/hadolint/hadolint)
- [dive](https://github.com/wagoodman/dive)
- [yq](https://github.com/mikefarah/yq)
