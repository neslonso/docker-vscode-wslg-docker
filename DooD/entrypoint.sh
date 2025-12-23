#!/bin/bash
set -e

# ============================================================================
# Entrypoint para modo DooD (Docker-out-of-Docker)
# ============================================================================
# Este entrypoint:
# 1. Configura permisos del socket Docker del host
# 2. Configura VSCode y extensiones
# 3. Lanza VSCode
# 4. Monitorea el proceso

# Cargar bibliotecas compartidas
source /usr/local/lib/docker-setup.sh
source /usr/local/lib/vscode-setup.sh

# ============================================================================
# Setup inicial
# ============================================================================

# Configurar permisos en volúmenes de VSCode
setup_vscode_permissions

# DooD: Configurar permisos del socket Docker
setup_docker_socket_permissions

# ============================================================================
# Configuración de VSCode
# ============================================================================

# Settings base de VSCode
setup_vscode_settings

# Procesar perfil si está especificado
process_vscode_profile

# Workaround para bug de WSLg (en background)
apply_wslg_workaround

# Instalar extensiones del perfil
install_vscode_extensions

# Preparar README para abrir si es primera vez
prepare_readme_open

# ============================================================================
# Lanzar VSCode
# ============================================================================

launch_vscode "$@"

# ============================================================================
# Monitoreo
# ============================================================================

# Mantener contenedor vivo mientras VSCode corre
monitor_vscode_process
