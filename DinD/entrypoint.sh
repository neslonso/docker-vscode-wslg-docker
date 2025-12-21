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

# === Reorganizar argumentos para extensiones ===
# Necesitamos: code --no-sandbox --wait --install-extension ext1 ext2 ... /workspace README.md
# Pero CMD da: code --no-sandbox --wait /workspace
# Extraer el último argumento (workspace), agregar extensiones, luego readdir todo

echo "🔍 DEBUG: Argumentos originales: $@"
echo "🔍 DEBUG: Número de argumentos: $#"

# Guardar el último argumento (el workspace)
WORKSPACE_ARG="${@: -1}"
echo "🔍 DEBUG: Workspace extraído: $WORKSPACE_ARG"

# Eliminar el último argumento de $@
set -- "${@:1:$(($#-1))}"
echo "🔍 DEBUG: Argumentos sin workspace: $@"

# === Instalar extensiones ===
if [ -f /tmp/vscode_extensions_to_install ]; then
    echo "🔍 DEBUG: Archivo de extensiones encontrado"
    while IFS= read -r extension; do
        set -- "$@" "--install-extension" "$extension"
    done < /tmp/vscode_extensions_to_install
    rm /tmp/vscode_extensions_to_install
    echo "🔍 DEBUG: Argumentos con extensiones: $@"
fi

# === Abrir README en primera vez ===
if [ -f /tmp/vscode_open_readme ]; then
    README_PATH=$(cat /tmp/vscode_open_readme)
    rm /tmp/vscode_open_readme
    echo "🔍 DEBUG: README a abrir: $README_PATH"
    # Añadir README
    set -- "$@" "$README_PATH"
    echo "🔍 DEBUG: Argumentos con README: $@"
fi

# Añadir workspace al final
set -- "$@" "$WORKSPACE_ARG"

echo "🔍 DEBUG: Comando final completo: $@"
echo "🔍 DEBUG: Ejecutando VSCode..."

exec "$@"
