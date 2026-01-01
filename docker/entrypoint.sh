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
