#!/bin/bash
# ============================================================================
# VSCode Setup Library
# ============================================================================
# Functions to configure and launch VSCode inside the container
# Includes profile loading and processing functionality

# Color constants for output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

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

# ============================================================================
# Profile Functions (consolidated from profile-loader.sh)
# ============================================================================

##
# Checks if a profile directory exists
#
# Globals:
#   None
# Arguments:
#   $1 - Profile directory path
# Outputs:
#   None
# Returns:
#   0 if profile exists, 1 otherwise
##
profile_exists() {
    local profile_dir=$1

    if [ -d "$profile_dir" ]; then
        return 0
    else
        return 1
    fi
}

##
# Applies VSCode settings from profile
#
# Merges profile-specific settings.json with existing user settings.
# User settings take priority. Also applies keybindings if present.
#
# Globals:
#   COLOR_* - Color constants for output
# Arguments:
#   $1 - Profile directory path
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 if success, 1 if error
##
apply_profile_vscode_settings() {
    local profile_dir=$1
    local settings_dir="/home/dev/.config/Code/User"

    mkdir -p "$settings_dir"

    # Apply settings.json if exists
    if [ -f "$profile_dir/vscode/settings.json" ]; then
        echo -e "${COLOR_BLUE}⚙️  Applying VSCode configuration...${COLOR_RESET}"
        echo -e "${COLOR_BLUE}   DEBUG: Settings file: $profile_dir/vscode/settings.json${COLOR_RESET}"

        # Validate JSON before continuing
        if ! jq empty "$profile_dir/vscode/settings.json" 2>/dev/null; then
            echo -e "${COLOR_RED}   ✗ ERROR: settings.json contains invalid JSON${COLOR_RESET}"
            echo -e "${COLOR_RED}   Verify it doesn't have comments (//) or incorrect syntax${COLOR_RESET}"
            return 1
        fi
        echo -e "${COLOR_GREEN}   ✓ Valid JSON${COLOR_RESET}"

        # If user settings.json exists, merge
        if [ -f "$settings_dir/settings.json" ]; then
            echo -e "${COLOR_BLUE}   DEBUG: User settings found, merging...${COLOR_RESET}"
            # Backup original settings
            cp "$settings_dir/settings.json" "$settings_dir/settings.json.backup"

            # Merge using jq (profile doesn't override user configuration)
            # Priority: PROFILE < USER (user has final say)
            if command -v jq &>/dev/null; then
                jq -s '.[0] * .[1]' \
                    "$profile_dir/vscode/settings.json" \
                    "$settings_dir/settings.json.backup" \
                    > "$settings_dir/settings.json.tmp" 2>&1

                if [ $? -eq 0 ]; then
                    mv "$settings_dir/settings.json.tmp" "$settings_dir/settings.json"
					echo -e "${COLOR_GREEN}  ✓ Settings merged successfully${COLOR_RESET}"
                else
                    # If merge fails, use only profile settings
                    echo -e "${COLOR_YELLOW}  ⚠ Merge error, using profile settings${COLOR_RESET}"
                    cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
                fi
            else
                # If jq not available, simply copy profile settings
                cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
				echo -e "${COLOR_YELLOW}  ⚠ jq not available, using profile settings only${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_BLUE}   DEBUG: No previous settings, applying from profile${COLOR_RESET}"
            # No previous settings, use profile settings
            cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
            echo -e "${COLOR_GREEN}  ✓ Settings applied${COLOR_RESET}"
        fi
    fi

    # Copy keybindings if they exist (these do override)
    if [ -f "$profile_dir/vscode/keybindings.json" ]; then
        cp "$profile_dir/vscode/keybindings.json" "$settings_dir/keybindings.json"
        echo -e "${COLOR_GREEN}  ✓ Keybindings applied${COLOR_RESET}"
    fi
}

##
# Prepares VSCode extensions from profile
#
# Reads extensions.list and writes them to a temporary file
# that will be processed later by install_vscode_extensions().
#
# Globals:
#   COLOR_* - Color constants for output
# Arguments:
#   $1 - Path to extensions.list file
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 always
##
prepare_vscode_extensions() {
    local extensions_file=$1

    if [ ! -f "$extensions_file" ]; then
        return 0
    fi

    echo -e "${COLOR_BLUE}📦 Preparing VSCode extensions...${COLOR_RESET}"

    # Write extension list to temporary file
    # The entrypoint will read this file and pass extensions as arguments to VSCode
    local temp_file="/tmp/vscode_extensions_to_install"
    rm -f "$temp_file"

    local ext_count=0

    while IFS= read -r extension || [ -n "$extension" ]; do
        # Clean the line
        extension="${extension%$'\r'}"
        extension="$(echo "$extension" | xargs)"

        # Skip empty lines and comments
        [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

        echo "$extension" >> "$temp_file"
        ext_count=$((ext_count + 1))
    done < "$extensions_file"

    if [ $ext_count -gt 0 ]; then
        echo -e "${COLOR_GREEN}  ✓ $ext_count extensions scheduled for installation${COLOR_RESET}"
    fi
}

##
# Processes a complete profile
#
# Main function that orchestrates profile loading:
# 1. Verifies profile exists
# 2. Applies VSCode settings
# 3. Prepares extensions for installation
# 4. Marks README to be opened on first execution
#
# Globals:
#   COLOR_* - Color constants for output
# Arguments:
#   $1 - Profile directory path
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 if success, 1 if profile not found
##
process_profile() {
    local profile_dir=$1
    local profile_name=$(basename "$profile_dir" | sed 's/vsc-wslg-//; s/-profile//')

    # Verify profile exists
    if ! profile_exists "$profile_dir"; then
        echo -e "${COLOR_RED}⚠ Profile not found at: $profile_dir${COLOR_RESET}"
        return 1
    fi

    # Simple message
    echo ""
    echo -e "${COLOR_BLUE}📦 Profile: ${COLOR_GREEN}${profile_name}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}📖 Documentation: ${profile_dir}/README.md${COLOR_RESET}"
    echo ""

    # Run profile setup script if exists (system packages installation)
    if [ -f "$profile_dir/setup.sh" ]; then
        echo -e "${COLOR_BLUE}🔧 Running profile setup script...${COLOR_RESET}"

        # Check if already executed
        local setup_flag="/home/dev/.config/Code/User/.profile_${profile_name}_setup_done"

        if [ -f "$setup_flag" ]; then
            echo -e "${COLOR_YELLOW}   ⚠ Setup already executed for this profile${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}   To re-run: rm $setup_flag and restart container${COLOR_RESET}"
        else
            # Execute setup script with sudo
            if bash "$profile_dir/setup.sh"; then
                echo -e "${COLOR_GREEN}   ✓ Setup completed successfully${COLOR_RESET}"
                mkdir -p "$(dirname "$setup_flag")"
                touch "$setup_flag"
            else
                echo -e "${COLOR_RED}   ✗ Setup script failed${COLOR_RESET}"
                return 1
            fi
        fi
        echo ""
    fi

    # Apply VSCode settings
    if [ -d "$profile_dir/vscode" ]; then
        apply_profile_vscode_settings "$profile_dir"
    fi

    # Install VSCode extensions
    local extensions_file="$profile_dir/vscode/extensions.list"
    # Fallback to extensions.list in root for backwards compatibility
    if [ ! -f "$extensions_file" ] && [ -f "$profile_dir/extensions.list" ]; then
        extensions_file="$profile_dir/extensions.list"
    fi

    if [ -f "$extensions_file" ]; then
        prepare_vscode_extensions "$extensions_file"
    fi

    echo ""

    # Detect first time (flag file per profile)
    local flag_file="/home/dev/.config/Code/User/.profile_${profile_name}_opened"

    if [ ! -f "$flag_file" ]; then
        # First time: save README path to open it
        echo "${profile_dir}/README.md" > /tmp/vscode_open_readme
        mkdir -p "$(dirname "$flag_file")"
        touch "$flag_file"
        echo -e "${COLOR_GREEN}👋 First time with this profile, README will be opened${COLOR_RESET}"
        echo ""
    fi

    return 0
}

##
# Processes the extensions profile if specified
#
# If VSCODE_EXTENSIONS_PROFILE variable is defined, loads the
# corresponding profile. This includes profile-specific
# configuration and extensions.
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

    local profile_path="/home/dev/vsc-wslg-${VSCODE_EXTENSIONS_PROFILE}-profile"
    process_profile "$profile_path"
}

# ============================================================================
# VSCode Execution Functions
# ============================================================================

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
# The temporary file is created by prepare_vscode_extensions().
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
# This file is created by process_profile() on first execution.
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
# - Workspace mounted at path specified by WORKSPACE_PATH env var
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
    # Use WORKSPACE_PATH if set, otherwise default to /workspace for backward compatibility
    local workspace_path="${WORKSPACE_PATH:-/workspace}"
    local vscode_cmd="code --new-window --no-sandbox --user-data-dir=$user_data_dir --extensions-dir=$extensions_dir $workspace_path"
    echo "🔍 DEBUG: Modified command: $vscode_cmd"
    echo "🔍 DEBUG: Workspace path: $workspace_path"

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
