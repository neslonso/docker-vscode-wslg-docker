#!/bin/bash
set -e

# Asegurar permisos correctos en los volúmenes
sudo chown -R dev:dev /home/dev/.vscode 2>/dev/null || true
sudo chown -R dev:dev /home/dev/.config/Code 2>/dev/null || true

# Permisos para Docker socket
if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    sudo groupadd -g "$DOCKER_GID" docker 2>/dev/null || true
    sudo usermod -aG "$DOCKER_GID" dev 2>/dev/null || true
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

# Abrir README en background si es necesario (antes de lanzar VSCode principal)
if [ -n "$README_TO_OPEN" ]; then
    (
        sleep 5
        echo "👋 Abriendo README: $README_TO_OPEN"
        code "$README_TO_OPEN" 2>/dev/null || true
    ) &
fi

# Lanzar VSCode con --wait (foreground)
# Compartimos user-data-dir entre contenedores para permitir múltiples ventanas
# como en Windows donde todas las ventanas comparten %APPDATA%\Code
# --wait mantiene el contenedor vivo hasta que se cierre esta ventana específica
if [ -S /var/run/docker.sock ]; then
    exec sg docker -c "$*"
else
    exec "$@"
fi
