#!/bin/bash
# ============================================================================
# Docker Setup Library
# ============================================================================
# Funciones para configurar Docker en modos DinD (Docker-in-Docker) y
# DooD (Docker-out-of-Docker)

##
# Inicia el Docker daemon (usado en modo DinD)
#
# Este proceso corre en background y puede tardar unos segundos en estar listo.
# La función espera hasta 30 segundos a que el daemon responda.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Mensajes de progreso a stdout
# Returns:
#   0 si el daemon arranca correctamente
#   1 si el daemon no arranca después del timeout
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
# Configura permisos del socket Docker (usado en modo DooD)
#
# En DooD, el socket de Docker viene del host. Esta función:
# 1. Detecta el GID del socket
# 2. Crea un grupo con ese GID si no existe
# 3. Agrega el usuario 'dev' al grupo
#
# Esto permite que el usuario 'dev' dentro del contenedor pueda
# usar el Docker daemon del host sin necesidad de sudo.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None (operaciones silenciosas)
# Returns:
#   0 siempre (errores son silenciados)
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
#
# En DooD, algunos comandos necesitan ejecutarse con el grupo 'docker'.
# Esta función detecta si el socket existe y ejecuta el comando
# con 'sg docker' (switch group) o directamente.
#
# Uso:
#   run_with_docker_perms code --new-window /workspace
#
# Globals:
#   None
# Arguments:
#   $@ - Comando completo a ejecutar
# Outputs:
#   Output del comando ejecutado
# Returns:
#   Exit code del comando ejecutado
##
run_with_docker_perms() {
    if [ -S /var/run/docker.sock ]; then
        sg docker -c "$*"
    else
        "$@"
    fi
}
