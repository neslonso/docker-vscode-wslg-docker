#!/bin/bash
# ============================================================================
# VSCode Setup Library
# ============================================================================
# Functions to configure and launch VSCode inside the container

##
# Configures permissions on VSCode directories
#
# Ensures that the 'dev' user has full access to VSCode
# configuration and extensions directories.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None (errors are silenced)
# Returns:
#   0 always
##
setup_vscode_permissions() {
    sudo chown -R dev:dev /home/dev/.vscode 2>/dev/null || true
    sudo chown -R dev:dev /home/dev/.config/Code 2>/dev/null || true
}

##
# Configures VSCode base settings.json
#
# Creates or updates settings.json with base configuration.
# If a user settings.json already exists, performs a merge where
# user settings take priority.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if success, 1 if error
##
setup_vscode_settings() {
    local settings_dir="/home/dev/.config/Code/User"
    local settings_file="$settings_dir/settings.json"

    mkdir -p "$settings_dir"

    # Base settings we guarantee
    local default_settings=$(cat <<'EOF'
{
  "window.titleBarStyle": "native"
}
EOF
)

    if [ ! -f "$settings_file" ]; then
        echo "$default_settings" > "$settings_file"
    else
        # Merge: default_settings as base, user settings take priority
        jq -s '.[0] * .[1]' <(echo "$default_settings") "$settings_file" > "${settings_file}.tmp" || return 1
        mv "${settings_file}.tmp" "$settings_file"
    fi
}

##
# Processes the extensions profile if specified
#
# If VSCODE_EXTENSIONS_PROFILE variable is defined, loads the
# corresponding profile using profile-loader.sh. This includes
# profile-specific configuration and extensions.
#
# Globals:
#   VSCODE_EXTENSIONS_PROFILE - Profile name to load
# Arguments:
#   None
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 if success or no profile, 1 if error
##
process_vscode_profile() {
    if [ -z "$VSCODE_EXTENSIONS_PROFILE" ]; then
        return 0
    fi

    if [ -f /usr/local/lib/profile-loader.sh ]; then
        source /usr/local/lib/profile-loader.sh

        local profile_path="/home/dev/vsc-wslg-${VSCODE_EXTENSIONS_PROFILE}-profile"
        process_profile "$profile_path"
    else
        echo "⚠ Profile library not found"
        return 1
    fi
}

##
# Applies workaround for WSLg bug
#
# WSLg has a bug where maximized windows save invalid coordinates
# that when restored end up off-screen.
#
# This workaround:
# 1. Waits for VSCode to open
# 2. Temporarily unmaps the window
# 3. Resizes it to a safe size (1024x768)
# 4. Maps it back
#
# Runs in background to not block startup.
#
# See: https://github.com/microsoft/wslg/issues/529
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None (runs in background)
##
apply_wslg_workaround() {
    (
        sleep 2
        for i in {1..15}; do
            local wid=$(xdotool search --name "Visual Studio Code" 2>/dev/null | head -1)
            if [ -n "$wid" ]; then
                xdotool windowunmap "$wid"
                sleep 0.2
                xdotool windowsize "$wid" 1024 768
                sleep 0.2
                xdotool windowmap "$wid"
                break
            fi
            sleep 1
        done
    ) &
}

##
# Installs VSCode extensions from list
#
# Reads the temporary file /tmp/vscode_extensions_to_install and installs
# each extension that isn't already installed. Shows a summary at the end.
#
# The temporary file is created by profile-loader.sh.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Installation progress to stdout
# Returns:
#   0 always
##
install_vscode_extensions() {
    if [ ! -f /tmp/vscode_extensions_to_install ]; then
        return 0
    fi

    echo "📦 Verifying VSCode extensions..."

    # Get list of already installed extensions
    local installed_extensions=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    local installed_count=0
    local new_count=0

    while IFS= read -r extension; do
        # Convert to lowercase for comparison
        local ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        if echo "$installed_extensions" | grep -q "^${ext_lower}$"; then
            echo "  ✓ Already installed: $extension"
            installed_count=$((installed_count + 1))
        else
            echo "  → Installing: $extension"
            code --install-extension "$extension" --force 2>&1 | grep -v "Installing extensions..." | grep -v "^$" || true
            new_count=$((new_count + 1))
        fi
    done < /tmp/vscode_extensions_to_install

    rm /tmp/vscode_extensions_to_install
    echo "✓ Extensions: $installed_count already installed, $new_count new"
    echo ""
}

##
# Reads the README path to open from temporary file
#
# If the file /tmp/vscode_open_readme exists, reads its content
# and saves it in the global variable README_TO_OPEN.
#
# This file is created by profile-loader.sh on first execution.
#
# Globals:
#   README_TO_OPEN - Set with the README path
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 always
##
prepare_readme_open() {
    README_TO_OPEN=""
    if [ -f /tmp/vscode_open_readme ]; then
        README_TO_OPEN=$(cat /tmp/vscode_open_readme)
        rm /tmp/vscode_open_readme
    fi
}

##
# Launches VSCode with isolated configuration
#
# Launches VSCode in background with:
# - Unique IPC socket based on hostname
# - Specific user data dir and extensions dir
# - Workspace mounted at /workspace
#
# After launching, waits 3 seconds and opens README if necessary.
# Uses run_with_docker_perms from docker-setup.sh to handle permissions.
#
# Globals:
#   README_TO_OPEN - Path of README to open (optional)
# Arguments:
#   $@ - Additional arguments for code (CMD from Dockerfile)
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 always
##
launch_vscode() {
    echo "🚀 Starting VSCode GUI..."

    # Isolate VSCode IPC to avoid conflicts between containers
    export VSCODE_IPC_HOOK_CLI="/tmp/vscode-ipc-$(hostname).sock"

    local user_data_dir="/home/dev/.config/Code"
    local extensions_dir="/home/dev/.vscode/extensions"

    echo "🔧 IPC Socket: $VSCODE_IPC_HOOK_CLI"
    echo "🔧 User Data Dir: $user_data_dir"
    echo "🔧 Extensions Dir: $extensions_dir"
    echo "🔍 DEBUG: Original command: $*"

    # Build command with isolated IPC
    local vscode_cmd="code --new-window --no-sandbox --user-data-dir=$user_data_dir --extensions-dir=$extensions_dir /workspace"
    echo "🔍 DEBUG: Modified command: $vscode_cmd"

    # Load Docker functions and launch with appropriate permissions
    source /usr/local/lib/docker-setup.sh
    run_with_docker_perms $vscode_cmd &

    # Wait for VSCode to start
    sleep 3

    # Open README if necessary
    if [ -n "$README_TO_OPEN" ]; then
        echo "👋 Opening README: $README_TO_OPEN"
        VSCODE_IPC_HOOK_CLI="$VSCODE_IPC_HOOK_CLI" \
            code --user-data-dir="$user_data_dir" --extensions-dir="$extensions_dir" \
            "$README_TO_OPEN" 2>/dev/null || true
    fi
}

##
# Monitors VSCode process to keep container alive
#
# Searches every 5 seconds for VSCode processes running as 'dev' user.
# When none are found, ends the loop (and therefore the container).
#
# This is the main process that keeps the container running.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Message when VSCode closes
# Returns:
#   0 when VSCode terminates
##
monitor_vscode_process() {
    echo "🔍 Monitoring VSCode process..."
    while true; do
        if ! pgrep -u dev -f "/usr/share/code" > /dev/null 2>&1; then
            echo "✓ VSCode closed, terminating container..."
            break
        fi
        sleep 5
    done
}
