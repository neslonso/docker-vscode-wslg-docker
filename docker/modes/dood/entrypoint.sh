#!/bin/bash
set -e

# ============================================================================
# Entrypoint for DooD (Docker-out-of-Docker) mode
# ============================================================================
# This entrypoint:
# 1. Configures Docker socket permissions from host
# 2. Configures VSCode and extensions
# 3. Launches VSCode
# 4. Monitors the process

# Load shared libraries
source /usr/local/lib/docker-setup.sh
source /usr/local/lib/vscode-setup.sh

# ============================================================================
# Initial setup
# ============================================================================

# Configure permissions on VSCode volumes
setup_vscode_permissions

# DooD: Configure Docker socket permissions
setup_docker_socket_permissions

# ============================================================================
# VSCode configuration
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
