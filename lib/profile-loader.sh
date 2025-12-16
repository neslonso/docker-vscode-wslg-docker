#!/bin/bash
# Biblioteca de funciones para cargar y procesar perfiles

# Colores para output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

# Función para verificar si un perfil existe y retornar su tipo
# Retorna: "directory" si es un perfil nuevo, "" si no existe
profile_exists() {
    local profile_name=$1
    local profile_dir="/profiles/${profile_name}"

    if [ -d "$profile_dir" ]; then
        echo "directory"
        return 0
    else
        return 1
    fi
}

# Función para validar que el script install.sh no contenga comandos peligrosos
validate_install_script() {
    local script_path=$1

    # Patrones peligrosos a detectar
    local dangerous_patterns=(
        "rm -rf /"
        "rm -rf /\s"
        "mkfs"
        "dd if=.*of=/dev/"
        "> /dev/sd"
        "format"
        "fdisk"
        "parted"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if grep -qE "$pattern" "$script_path" 2>/dev/null; then
            echo -e "${COLOR_RED}⚠️  ADVERTENCIA: Patrón peligroso detectado en install.sh: $pattern${COLOR_RESET}"
            echo -e "${COLOR_RED}   El script no se ejecutará por seguridad.${COLOR_RESET}"
            return 1
        fi
    done

    return 0
}

# Función para obtener el hash de un archivo
get_file_hash() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        sha256sum "$file_path" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Función para verificar si un script ya fue ejecutado (cache)
is_script_cached() {
    local script_path=$1
    local cache_file=$2

    if [ ! -f "$cache_file" ]; then
        return 1
    fi

    local current_hash=$(get_file_hash "$script_path")
    local cached_hash=$(cat "$cache_file" 2>/dev/null)

    if [ "$current_hash" = "$cached_hash" ] && [ -n "$current_hash" ]; then
        return 0
    else
        return 1
    fi
}

# Función para guardar el hash del script en cache
cache_script() {
    local script_path=$1
    local cache_file=$2

    local script_hash=$(get_file_hash "$script_path")
    echo "$script_hash" > "$cache_file"
}

# Función para ejecutar el script de instalación del SO
run_install_script() {
    local profile_dir=$1
    local profile_name=$2
    local install_script="$profile_dir/install.sh"
    local cache_file="/home/dev/.profile_cache_${profile_name}"

    if [ ! -f "$install_script" ]; then
        return 0
    fi

    # Verificar cache
    if is_script_cached "$install_script" "$cache_file"; then
        echo -e "${COLOR_GREEN}  ✓ Paquetes ya instalados (cache hit)${COLOR_RESET}"
        return 0
    fi

    # Validar script antes de ejecutar
    if ! validate_install_script "$install_script"; then
        echo -e "${COLOR_RED}✗ Script de instalación no pasó la validación de seguridad${COLOR_RESET}"
        return 1
    fi

    # Ejecutar script
    echo -e "${COLOR_BLUE}🔧 Ejecutando instalación de paquetes del SO...${COLOR_RESET}"
    if bash "$install_script"; then
        cache_script "$install_script" "$cache_file"
        return 0
    else
        echo -e "${COLOR_YELLOW}⚠ Error ejecutando install.sh (continuando...)${COLOR_RESET}"
        return 1
    fi
}

# Función para aplicar configuraciones de VSCode
apply_vscode_settings() {
    local profile_dir=$1
    local settings_dir="/home/dev/.config/Code/User"

    mkdir -p "$settings_dir"

    # Aplicar settings.json si existe
    if [ -f "$profile_dir/vscode/settings.json" ]; then
        echo -e "${COLOR_BLUE}⚙️  Aplicando configuraciones de VSCode...${COLOR_RESET}"

        # Si existe un settings.json del usuario, hacer merge
        if [ -f "$settings_dir/settings.json" ]; then
            # Backup del settings original
            cp "$settings_dir/settings.json" "$settings_dir/settings.json.backup"

            # Merge usando jq (perfil no sobreescribe configuraciones del usuario)
            # Prioridad: PROFILE < USER (el usuario tiene la última palabra)
            if command -v jq &>/dev/null; then
                jq -s '.[0] * .[1]' \
                    "$profile_dir/vscode/settings.json" \
                    "$settings_dir/settings.json.backup" \
                    > "$settings_dir/settings.json.tmp" 2>/dev/null

                if [ $? -eq 0 ]; then
                    mv "$settings_dir/settings.json.tmp" "$settings_dir/settings.json"
                    echo -e "${COLOR_GREEN}  ✓ Settings mergeados correctamente${COLOR_RESET}"
                else
                    # Si falla el merge, usar solo el del perfil
                    cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
                    echo -e "${COLOR_YELLOW}  ⚠ No se pudo hacer merge, usando settings del perfil${COLOR_RESET}"
                fi
            else
                # Si no hay jq, simplemente copiar el del perfil
                cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
                echo -e "${COLOR_YELLOW}  ⚠ jq no disponible, usando solo settings del perfil${COLOR_RESET}"
            fi
        else
            # No hay settings previos, usar los del perfil
            cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
            echo -e "${COLOR_GREEN}  ✓ Settings del perfil aplicados${COLOR_RESET}"
        fi
    fi

    # Copiar keybindings si existen (estos sí sobreescriben)
    if [ -f "$profile_dir/vscode/keybindings.json" ]; then
        cp "$profile_dir/vscode/keybindings.json" "$settings_dir/keybindings.json"
        echo -e "${COLOR_GREEN}  ✓ Keybindings aplicados${COLOR_RESET}"
    fi
}

# Función para instalar extensiones de VSCode
install_vscode_extensions() {
    local extensions_file=$1

    if [ ! -f "$extensions_file" ]; then
        return 0
    fi

    echo -e "${COLOR_BLUE}📦 Instalando extensiones de VSCode...${COLOR_RESET}"

    # Obtener lista de extensiones ya instaladas
    INSTALLED=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    local installed_count=0
    local new_count=0

    while IFS= read -r extension || [ -n "$extension" ]; do
        # Limpiar la línea
        extension="${extension%$'\r'}"
        extension="$(echo "$extension" | xargs)"

        # Saltar líneas vacías y comentarios
        [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

        # Convertir a minúsculas para comparar
        ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        if echo "$INSTALLED" | grep -q "^${ext_lower}$"; then
            echo -e "${COLOR_GREEN}  ✓ Ya instalada: $extension${COLOR_RESET}"
            ((installed_count++))
        else
            echo -e "  → Instalando: $extension"
            if code --install-extension "$extension" --force >/dev/null 2>&1; then
                ((new_count++))
            else
                echo -e "${COLOR_YELLOW}  ✗ Error instalando $extension${COLOR_RESET}"
            fi
        fi
    done < "$extensions_file"

    echo -e "${COLOR_GREEN}✓ Extensiones listas: $installed_count ya instaladas, $new_count nuevas${COLOR_RESET}"
}

# Función principal para procesar un perfil completo
process_profile() {
    local profile_name=$1
    local profile_dir="/profiles/${profile_name}"

    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BLUE}📦 Cargando perfil: ${COLOR_GREEN}${profile_name}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"

    # Verificar que el perfil existe
    if ! profile_exists "$profile_name" >/dev/null; then
        echo -e "${COLOR_RED}⚠ Perfil '$profile_name' no encontrado${COLOR_RESET}"
        return 1
    fi

    # Mostrar información del perfil si existe profile.yml
    if [ -f "$profile_dir/profile.yml" ]; then
        local description=$(grep "^description:" "$profile_dir/profile.yml" 2>/dev/null | cut -d'"' -f2)
        if [ -n "$description" ]; then
            echo -e "${COLOR_BLUE}ℹ️  $description${COLOR_RESET}"
        fi
    fi

    echo ""

    # 1. Ejecutar script de instalación del SO
    run_install_script "$profile_dir" "$profile_name"

    echo ""

    # 2. Aplicar configuraciones de VSCode
    if [ -d "$profile_dir/vscode" ]; then
        apply_vscode_settings "$profile_dir"
        echo ""
    fi

    # 3. Instalar extensiones de VSCode
    local extensions_file="$profile_dir/extensions.list"
    install_vscode_extensions "$extensions_file"

    echo ""
    echo -e "${COLOR_GREEN}✓ Perfil '$profile_name' cargado correctamente${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""

    return 0
}
