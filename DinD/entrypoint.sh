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

# === Instalar extensiones según el perfil ===
if [ -n "$VSCODE_EXTENSIONS_PROFILE" ] && [ -f "/profiles/${VSCODE_EXTENSIONS_PROFILE}.extensions" ]; then
    echo "📦 Comprobando extensiones del perfil: $VSCODE_EXTENSIONS_PROFILE"
    
    # Obtener extensiones ya instaladas (en minúsculas para comparación)
    INSTALLED=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    
    while IFS= read -r extension || [ -n "$extension" ]; do
        extension="${extension%$'\r'}"  # Limpiar CRLF
        [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue
        
        # Comparar en minúsculas (los IDs pueden variar en capitalización)
        ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        
        if echo "$INSTALLED" | grep -q "^${ext_lower}$"; then
            echo "  ✓ Ya instalada: $extension"
        else
            echo "  → Instalando: $extension"
            code --install-extension "$extension" --force || echo "  ✗ Error instalando $extension"
        fi
    done < "/profiles/${VSCODE_EXTENSIONS_PROFILE}.extensions"
    
    echo "✓ Extensiones listas"
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

exec "$@"
