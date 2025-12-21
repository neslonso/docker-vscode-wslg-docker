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

# === Reorganizar argumentos para extensiones ===
# Necesitamos: code --no-sandbox --wait --install-extension ext1 ext2 ... /workspace README.md
# Pero CMD da: code --no-sandbox --wait /workspace
# Extraer el último argumento (workspace), agregar extensiones, luego reagregar todo

# Guardar el último argumento (el workspace)
WORKSPACE_ARG="${@: -1}"

# Eliminar el último argumento de $@
set -- "${@:1:$(($#-1))}"

# === Instalar extensiones ===
if [ -f /tmp/vscode_extensions_to_install ]; then
    while IFS= read -r extension; do
        set -- "$@" "--install-extension" "$extension"
    done < /tmp/vscode_extensions_to_install
    rm /tmp/vscode_extensions_to_install
fi

# === Abrir README en primera vez ===
if [ -f /tmp/vscode_open_readme ]; then
    README_PATH=$(cat /tmp/vscode_open_readme)
    rm /tmp/vscode_open_readme
    # Añadir README
    set -- "$@" "$README_PATH"
fi

# Añadir workspace al final
set -- "$@" "$WORKSPACE_ARG"

# Al final, ejecutar con el grupo docker activo
if [ -S /var/run/docker.sock ]; then
    exec sg docker -c "$*"
    #exec sg docker -c "exec $*"
else
    exec "$@"
fi
