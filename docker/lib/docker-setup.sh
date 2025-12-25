#!/bin/bash
# ============================================================================
# Docker Setup Library
# ============================================================================
# Functions to configure Docker in DinD (Docker-in-Docker) and
# DooD (Docker-out-of-Docker) modes

##
# Starts the Docker daemon (used in DinD mode)
#
# This process runs in background and may take a few seconds to be ready.
# The function waits up to 30 seconds for the daemon to respond.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 if daemon starts correctly
#   1 if daemon doesn't start after timeout
##
start_docker_daemon() {
    echo "🐳 Starting Docker daemon..."
    sudo dockerd --host=unix:///var/run/docker.sock &

    # Wait for Docker to be ready
    local timeout=30
    for i in $(seq 1 $timeout); do
        if docker info &>/dev/null; then
            echo "✓ Docker daemon ready"
            return 0
        fi
        sleep 1
    done

    echo "✗ Error: Docker daemon didn't start after ${timeout}s"
    return 1
}

##
# Configures Docker socket permissions (used in DooD mode)
#
# In DooD, the Docker socket comes from the host. This function:
# 1. Detects the socket's GID
# 2. Creates a group with that GID if it doesn't exist
# 3. Adds the 'dev' user to the group
#
# This allows the 'dev' user inside the container to use
# the host's Docker daemon without needing sudo.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None (silent operations)
# Returns:
#   0 always (errors are silenced)
##
setup_docker_socket_permissions() {
    if [ -S /var/run/docker.sock ]; then
        local docker_gid=$(stat -c '%g' /var/run/docker.sock)
        sudo groupadd -g "$docker_gid" docker 2>/dev/null || true
        sudo usermod -aG "$docker_gid" dev 2>/dev/null || true
    fi
}

##
# Executes a command with Docker permissions if necessary
#
# In DooD, some commands need to run with the 'docker' group.
# This function detects if the socket exists and executes the command
# with 'sg docker' (switch group) or directly.
#
# Usage:
#   run_with_docker_perms code --new-window /workspace
#
# Globals:
#   None
# Arguments:
#   $@ - Complete command to execute
# Outputs:
#   Output of the executed command
# Returns:
#   Exit code of the executed command
##
run_with_docker_perms() {
    if [ -S /var/run/docker.sock ]; then
        sg docker -c "$*"
    else
        "$@"
    fi
}
