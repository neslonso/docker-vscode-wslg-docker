#!/bin/bash
# ============================================================================
# Unified Entrypoint for DinD and DooD modes
# ============================================================================
# This entrypoint handles both Docker-in-Docker and Docker-out-of-Docker modes
# based on the ENTRYPOINT_MODE environment variable.
#
# DinD: Starts Docker daemon inside container
# DooD: Configures permissions for host Docker socket
#
# Common flow:
# 1. Docker setup (mode-specific)
# 2. VSCode configuration
# 3. Launch VSCode
# 4. Monitor process

set -e

# Load shared libraries
source /usr/local/lib/docker-setup.sh
source /usr/local/lib/vscode-setup.sh

# ============================================================================
# Signal handling for clean shutdown
# ============================================================================
# When container receives SIGTERM (docker stop / docker compose stop), ensure
# Docker daemon is shut down cleanly before exiting (DinD mode only).

cleanup_and_exit() {
    echo ""
    echo "⚡ Signal received, shutting down..."
    if [ "${ENTRYPOINT_MODE}" = "dind" ]; then
        shutdown_docker_daemon
    fi
    exit 0
}

trap cleanup_and_exit SIGTERM SIGINT

# ============================================================================
# Shell persistence
# ============================================================================
# Persist shell config files across container recreations
# by symlinking to ~/.shell_persist/ (volume-backed).
# On first run, seeds persistent storage from image defaults.

setup_shell_persistence() {
    local persist_dir="/home/dev/.shell_persist"
    sudo chown dev:dev "$persist_dir" 2>/dev/null || true
    mkdir -p "$persist_dir"

    # Home-level dotfiles
    for f in .bash_history .bashrc .bash_aliases .bashrc_profile; do
        if [ ! -f "$persist_dir/$f" ] && [ -f "/home/dev/$f" ] && [ ! -L "/home/dev/$f" ]; then
            cp "/home/dev/$f" "$persist_dir/$f"
        fi
        ln -sf "$persist_dir/$f" "/home/dev/$f"
    done

    # Starship config (~/.config/starship.toml)
    local starship_cfg="/home/dev/.config/starship.toml"
    if [ ! -f "$persist_dir/starship.toml" ] && [ -f "$starship_cfg" ] && [ ! -L "$starship_cfg" ]; then
        cp "$starship_cfg" "$persist_dir/starship.toml"
    fi
    ln -sf "$persist_dir/starship.toml" "$starship_cfg"
}

setup_shell_persistence

# ============================================================================
# Initial setup
# ============================================================================

# Configure permissions on VSCode volumes
setup_vscode_permissions

# Docker setup based on mode
case "${ENTRYPOINT_MODE}" in
    dind)
        echo "🐳 Mode: Docker-in-Docker"
        start_docker_daemon || exit 1
        ;;
    dood)
        echo "🐳 Mode: Docker-out-of-Docker"
        setup_docker_socket_permissions
        ;;
    *)
        echo "❌ Error: Unknown ENTRYPOINT_MODE: ${ENTRYPOINT_MODE}"
        echo "   Expected: 'dind' or 'dood'"
        exit 1
        ;;
esac

# ============================================================================
# VSCode configuration (common for both modes)
# ============================================================================

# VSCode base settings
setup_vscode_settings

# Process profile if specified
process_vscode_profile

# Workaround for WSLg bug (in background)
apply_wslg_workaround

# Install profile extensions
install_vscode_extensions

# Prepare README to open if first time
prepare_readme_open

# ============================================================================
# Launch VSCode
# ============================================================================

launch_vscode "$@"

# ============================================================================
# Monitoring
# ============================================================================

# Keep container alive while VSCode runs
monitor_vscode_process

# ============================================================================
# Cleanup on exit
# ============================================================================

# Gracefully shutdown Docker daemon if in DinD mode
if [ "${ENTRYPOINT_MODE}" = "dind" ]; then
    shutdown_docker_daemon
fi
