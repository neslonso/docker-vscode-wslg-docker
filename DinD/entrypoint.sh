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
    echo "📦 Instalando extensiones..."
    while IFS= read -r extension; do
        echo "  → Instalando: $extension"
        code --install-extension "$extension" --force 2>&1 | grep -v "Installing extensions..."
    done < /tmp/vscode_extensions_to_install
    rm /tmp/vscode_extensions_to_install
    echo "✓ Extensiones instaladas"
    echo ""
fi

# === Preparar argumentos para abrir VSCode en modo GUI ===
# Añadir README si es primera vez
if [ -f /tmp/vscode_open_readme ]; then
    README_PATH=$(cat /tmp/vscode_open_readme)
    rm /tmp/vscode_open_readme
    echo "👋 Abriendo README: $README_PATH"
    set -- "$@" "$README_PATH"
fi

echo "🚀 Iniciando VSCode GUI..."
echo "🔍 DEBUG: Comando: $@"

exec "$@"
