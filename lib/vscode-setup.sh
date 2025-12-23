#!/bin/bash
# ============================================================================
# VSCode Setup Library
# ============================================================================
# Funciones para configurar y lanzar VSCode dentro del contenedor

##
# Configura permisos en directorios de VSCode
#
# Asegura que el usuario 'dev' tenga acceso completo a los directorios
# de configuración y extensiones de VSCode.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None (errores son silenciados)
# Returns:
#   0 siempre
##
setup_vscode_permissions() {
    sudo chown -R dev:dev /home/dev/.vscode 2>/dev/null || true
    sudo chown -R dev:dev /home/dev/.config/Code 2>/dev/null || true
}

##
# Configura settings.json base de VSCode
#
# Crea o actualiza el archivo settings.json con configuración base.
# Si ya existe un settings.json del usuario, hace un merge donde
# las configuraciones del usuario tienen prioridad.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 si éxito, 1 si error
##
setup_vscode_settings() {
    local settings_dir="/home/dev/.config/Code/User"
    local settings_file="$settings_dir/settings.json"

    mkdir -p "$settings_dir"

    # Settings base que garantizamos
    local default_settings=$(cat <<'EOF'
{
  "window.titleBarStyle": "native"
}
EOF
)

    if [ ! -f "$settings_file" ]; then
        echo "$default_settings" > "$settings_file"
    else
        # Merge: default_settings como base, settings del usuario tienen prioridad
        jq -s '.[0] * .[1]' <(echo "$default_settings") "$settings_file" > "${settings_file}.tmp" || return 1
        mv "${settings_file}.tmp" "$settings_file"
    fi
}

##
# Procesa el perfil de extensiones si está especificado
#
# Si la variable VSCODE_EXTENSIONS_PROFILE está definida, carga el perfil
# correspondiente usando profile-loader.sh. Esto incluye configuración
# y extensiones específicas del perfil.
#
# Globals:
#   VSCODE_EXTENSIONS_PROFILE - Nombre del perfil a cargar
# Arguments:
#   None
# Outputs:
#   Mensajes de progreso a stdout
# Returns:
#   0 si éxito o no hay perfil, 1 si error
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
        echo "⚠ Librería de perfiles no encontrada"
        return 1
    fi
}

##
# Aplica workaround para bug de WSLg
#
# WSLg tiene un bug donde las ventanas maximizadas guardan coordenadas
# inválidas que al restaurar quedan fuera de pantalla.
#
# Este workaround:
# 1. Espera a que VSCode abra
# 2. Desmapea la ventana temporalmente
# 3. La redimensiona a un tamaño seguro (1024x768)
# 4. La vuelve a mapear
#
# Corre en background para no bloquear el arranque.
#
# Ver: https://github.com/microsoft/wslg/issues/529
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None (corre en background)
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
# Instala extensiones de VSCode desde lista
#
# Lee el archivo temporal /tmp/vscode_extensions_to_install y instala
# cada extensión que aún no esté instalada. Muestra un resumen al final.
#
# El archivo temporal es creado por profile-loader.sh.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progreso de instalación a stdout
# Returns:
#   0 siempre
##
install_vscode_extensions() {
    if [ ! -f /tmp/vscode_extensions_to_install ]; then
        return 0
    fi

    echo "📦 Verificando extensiones de VSCode..."

    # Obtener lista de extensiones ya instaladas
    local installed_extensions=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    local installed_count=0
    local new_count=0

    while IFS= read -r extension; do
        # Convertir a minúsculas para comparar
        local ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        if echo "$installed_extensions" | grep -q "^${ext_lower}$"; then
            echo "  ✓ Ya instalada: $extension"
            installed_count=$((installed_count + 1))
        else
            echo "  → Instalando: $extension"
            code --install-extension "$extension" --force 2>&1 | grep -v "Installing extensions..." | grep -v "^$" || true
            new_count=$((new_count + 1))
        fi
    done < /tmp/vscode_extensions_to_install

    rm /tmp/vscode_extensions_to_install
    echo "✓ Extensiones: $installed_count ya instaladas, $new_count nuevas"
    echo ""
}

##
# Lee el path del README a abrir desde archivo temporal
#
# Si el archivo /tmp/vscode_open_readme existe, lee su contenido
# y lo guarda en la variable global README_TO_OPEN.
#
# Este archivo es creado por profile-loader.sh en la primera ejecución.
#
# Globals:
#   README_TO_OPEN - Se setea con el path del README
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 siempre
##
prepare_readme_open() {
    README_TO_OPEN=""
    if [ -f /tmp/vscode_open_readme ]; then
        README_TO_OPEN=$(cat /tmp/vscode_open_readme)
        rm /tmp/vscode_open_readme
    fi
}

##
# Lanza VSCode con configuración aislada
#
# Lanza VSCode en background con:
# - IPC socket único basado en hostname
# - User data dir y extensions dir específicos
# - El workspace montado en /workspace
#
# Después de lanzar, espera 3 segundos y abre el README si es necesario.
# Usa run_with_docker_perms de docker-setup.sh para manejar permisos.
#
# Globals:
#   README_TO_OPEN - Path del README a abrir (opcional)
# Arguments:
#   $@ - Argumentos adicionales para code (CMD del Dockerfile)
# Outputs:
#   Mensajes de progreso a stdout
# Returns:
#   0 siempre
##
launch_vscode() {
    echo "🚀 Iniciando VSCode GUI..."

    # Aislar IPC de VSCode para evitar conflictos entre contenedores
    export VSCODE_IPC_HOOK_CLI="/tmp/vscode-ipc-$(hostname).sock"

    local user_data_dir="/home/dev/.config/Code"
    local extensions_dir="/home/dev/.vscode/extensions"

    echo "🔧 Socket IPC: $VSCODE_IPC_HOOK_CLI"
    echo "🔧 User Data Dir: $user_data_dir"
    echo "🔧 Extensions Dir: $extensions_dir"
    echo "🔍 DEBUG: Comando original: $*"

    # Construir comando con IPC aislado
    local vscode_cmd="code --new-window --no-sandbox --user-data-dir=$user_data_dir --extensions-dir=$extensions_dir /workspace"
    echo "🔍 DEBUG: Comando modificado: $vscode_cmd"

    # Cargar funciones de Docker y lanzar con permisos apropiados
    source /usr/local/lib/docker-setup.sh
    run_with_docker_perms $vscode_cmd &

    # Esperar a que VSCode arranque
    sleep 3

    # Abrir README si es necesario
    if [ -n "$README_TO_OPEN" ]; then
        echo "👋 Abriendo README: $README_TO_OPEN"
        VSCODE_IPC_HOOK_CLI="$VSCODE_IPC_HOOK_CLI" \
            code --user-data-dir="$user_data_dir" --extensions-dir="$extensions_dir" \
            "$README_TO_OPEN" 2>/dev/null || true
    fi
}

##
# Monitorea el proceso de VSCode para mantener contenedor vivo
#
# Busca cada 5 segundos procesos de VSCode corriendo como usuario 'dev'.
# Cuando no encuentra ninguno, termina el loop (y por tanto el contenedor).
#
# Este es el proceso principal que mantiene el contenedor corriendo.
#
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Mensaje cuando VSCode se cierra
# Returns:
#   0 cuando VSCode termina
##
monitor_vscode_process() {
    echo "🔍 Monitoreando proceso VSCode..."
    while true; do
        if ! pgrep -u dev -f "/usr/share/code" > /dev/null 2>&1; then
            echo "✓ VSCode cerrado, terminando contenedor..."
            break
        fi
        sleep 5
    done
}
