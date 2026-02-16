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

    # Clean stale PID files from previous runs (when container was stopped, not removed)
    if [ -f /var/run/docker.pid ]; then
        local pid=$(cat /var/run/docker.pid 2>/dev/null)
        # Check if process actually exists
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "  → Cleaning stale Docker PID file (process $pid not running)..."
            sudo rm -f /var/run/docker.pid
        elif [ -n "$pid" ]; then
            echo "  ⚠ Warning: Docker daemon may already be running (PID $pid)"
        fi
    fi

    # Clean other stale PID files (containerd, etc.)
    if [ -d /var/run/docker ]; then
        sudo find /var/run/docker -name "*.pid" -type f | while read pidfile; do
            local pid=$(cat "$pidfile" 2>/dev/null)
            if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
                sudo rm -f "$pidfile"
            fi
        done
    fi

    # Clean stale socket files from previous unclean shutdown
    if [ -S /var/run/docker.sock ] && ! docker info &>/dev/null 2>&1; then
        echo "  → Cleaning stale Docker socket..."
        sudo rm -f /var/run/docker.sock
    fi

    # Clean stale containerd state
    if [ -f /var/run/containerd/containerd.pid ]; then
        local pid=$(cat /var/run/containerd/containerd.pid 2>/dev/null)
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "  → Cleaning stale containerd PID file..."
            sudo rm -f /var/run/containerd/containerd.pid
        fi
    fi
    # Clean stale containerd sockets
    if [ -S /var/run/containerd/containerd.sock ] && [ ! -f /var/run/containerd/containerd.pid ]; then
        echo "  → Cleaning stale containerd socket..."
        sudo rm -f /var/run/containerd/containerd.sock
    fi

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

##
# Gracefully shuts down Docker daemon and its containers (DinD mode)
#
# This function ensures clean shutdown of the Docker daemon and all
# containers running inside it. Prevents stale PID files and data
# corruption when the container is stopped (not removed).
#
# Steps:
# 1. Stop all running containers inside DinD
# 2. Wait for them to stop
# 3. Allow dockerd to shutdown cleanly
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 always
##
shutdown_docker_daemon() {
    echo "🐳 Shutting down Docker daemon..."

    # Check if Docker daemon is running
    if ! docker info &>/dev/null; then
        echo "  ℹ Docker daemon not running, skipping cleanup"
        return 0
    fi

    # Get list of running containers
    local containers=$(docker ps -q 2>/dev/null)

    if [ -n "$containers" ]; then
        echo "  → Stopping $(echo "$containers" | wc -l) running container(s)..."
        docker stop $containers --time 10 2>/dev/null || true
    fi

    # Gracefully stop dockerd by sending SIGTERM
    local dockerd_pid=$(cat /var/run/docker.pid 2>/dev/null)

    if [ -n "$dockerd_pid" ] && kill -0 "$dockerd_pid" 2>/dev/null; then
        echo "  → Sending SIGTERM to dockerd (PID $dockerd_pid)..."
        sudo kill -TERM "$dockerd_pid" 2>/dev/null || true

        # Wait for dockerd to exit cleanly (up to 15 seconds)
        local timeout=15
        for i in $(seq 1 $timeout); do
            if ! kill -0 "$dockerd_pid" 2>/dev/null; then
                echo "  ✓ dockerd stopped cleanly after ${i}s"
                break
            fi
            if [ "$i" -eq "$timeout" ]; then
                echo "  ⚠ dockerd didn't stop after ${timeout}s, sending SIGKILL..."
                sudo kill -KILL "$dockerd_pid" 2>/dev/null || true
                sleep 1
            fi
            sleep 1
        done
    else
        echo "  ℹ dockerd PID not found or not running"
    fi

    # Clean up residual runtime files to prevent issues on restart
    sudo rm -f /var/run/docker.pid
    sudo rm -f /var/run/docker.sock
    sudo rm -rf /var/run/docker/containerd
    sudo rm -f /var/run/containerd/containerd.pid

    echo "✓ Docker daemon shutdown complete"
    return 0
}
