#!/bin/bash
set -e

# Asegurar permisos correctos en los volúmenes
sudo chown -R dev:dev /home/dev/.vscode 2>/dev/null || true
sudo chown -R dev:dev /home/dev/.config/Code 2>/dev/null || true

# === Arrancar Docker daemon (DinD) ===
echo "🐳 Iniciando Docker daemon..."
sudo dockerd --host=unix:///var/run/docker.sock &

# Esperar a que Docker esté listo
for i in {1..30}; do
    if docker info &>/dev/null; then
        echo "✓ Docker daemon listo"
        break
    fi
    sleep 1
done

if ! docker info &>/dev/null; then
    echo "✗ Error: Docker daemon no arrancó"
    exit 1
fi

# === Configuración base de VSCode ===
SETTINGS_DIR="/home/dev/.config/Code/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

# Settings que queremos garantizar (el usuario puede sobreescribirlos después)
DEFAULT_SETTINGS=$(cat <<'EOF'
{
  "window.titleBarStyle": "native"
}
EOF
)

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "$DEFAULT_SETTINGS" > "$SETTINGS_FILE"
else
    # Merge: DEFAULT_SETTINGS como base, settings del usuario tienen prioridad
    jq -s '.[0] * .[1]' <(echo "$DEFAULT_SETTINGS") "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
fi

# === Procesar perfil si está especificado ===
if [ -n "$VSCODE_EXTENSIONS_PROFILE" ]; then
    # Cargar librería de funciones de perfiles
    if [ -f /usr/local/lib/profile-loader.sh ]; then
        source /usr/local/lib/profile-loader.sh

        # Path del perfil montado
        PROFILE_PATH="/home/dev/vsc-wslg-${VSCODE_EXTENSIONS_PROFILE}-profile"

        # Procesar el perfil completo (configuraciones, extensiones)
        process_profile "$PROFILE_PATH"
    else
        echo "⚠ Librería de perfiles no encontrada"
    fi
fi

# Workaround para bug de WSLg: las ventanas maximizadas guardan coordenadas
# que al restaurar quedan fuera de pantalla o en posiciones inválidas.
# Ver: https://github.com/microsoft/wslg/issues/529
(
    sleep 2
    for i in {1..15}; do
        WID=$(xdotool search --name "Visual Studio Code" 2>/dev/null | head -1)
        if [ -n "$WID" ]; then
            xdotool windowunmap "$WID"
            sleep 0.2
            xdotool windowsize "$WID" 1024 768
            sleep 0.2
            xdotool windowmap "$WID"
            #xdotool windowmove "$WID" 50 50
            #xdotool windowactivate "$WID"
            break
        fi
        sleep 1
    done
) &

# === Instalar extensiones ANTES de abrir VSCode ===
if [ -f /tmp/vscode_extensions_to_install ]; then
    echo "📦 Verificando extensiones de VSCode..."

    # Obtener lista de extensiones ya instaladas
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    installed_count=0
    new_count=0

    while IFS= read -r extension; do
        # Convertir a minúsculas para comparar
        ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        if echo "$INSTALLED_EXTENSIONS" | grep -q "^${ext_lower}$"; then
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
fi

# === Guardar README para abrirlo después ===
README_TO_OPEN=""
if [ -f /tmp/vscode_open_readme ]; then
    README_TO_OPEN=$(cat /tmp/vscode_open_readme)
    rm /tmp/vscode_open_readme
fi

echo "🚀 Iniciando VSCode GUI..."

# Aislar IPC de VSCode para evitar conflictos entre contenedores
# que comparten el mismo display de WSLg
# Generar un socket IPC único basado en el hostname del contenedor
export VSCODE_IPC_HOOK_CLI="/tmp/vscode-ipc-$(hostname).sock"

# CRÍTICO: Aislar completamente la instancia de VSCode
# No usar symlinks - copiar la configuración real para persistencia
USER_DATA_DIR="/home/dev/.config/Code"
EXTENSIONS_DIR="/home/dev/.vscode/extensions"

echo "🔧 Socket IPC: $VSCODE_IPC_HOOK_CLI"
echo "🔧 User Data Dir: $USER_DATA_DIR"
echo "🔧 Extensions Dir: $EXTENSIONS_DIR"
echo "🔍 DEBUG: Comando original: $@"

# Construir comando con IPC aislado
NEW_CMD="code --new-window --no-sandbox --user-data-dir=$USER_DATA_DIR --extensions-dir=$EXTENSIONS_DIR /workspace"
echo "🔍 DEBUG: Comando modificado: $NEW_CMD"

# Lanzar VSCode en background
$NEW_CMD &

# Esperar a que VSCode (proceso Electron) realmente arranque
sleep 3

# Abrir README si es necesario
if [ -n "$README_TO_OPEN" ]; then
    echo "👋 Abriendo README: $README_TO_OPEN"
    VSCODE_IPC_HOOK_CLI="$VSCODE_IPC_HOOK_CLI" code --user-data-dir="$USER_DATA_DIR" --extensions-dir="$EXTENSIONS_DIR" "$README_TO_OPEN" 2>/dev/null || true
fi

# Monitorear proceso VSCode real para mantener contenedor vivo
echo "🔍 Monitoreando proceso VSCode..."
while true; do
    # Buscar procesos de VSCode de este contenedor
    if ! pgrep -u dev -f "/usr/share/code" > /dev/null 2>&1; then
        echo "✓ VSCode cerrado, terminando contenedor..."
        break
    fi
    sleep 5
done
