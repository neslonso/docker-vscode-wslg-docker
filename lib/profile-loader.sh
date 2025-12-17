#!/bin/bash
# Biblioteca simplificada de funciones para cargar y procesar perfiles

# Colores para output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

# Función para verificar si un perfil existe
profile_exists() {
    local profile_name=$1
    local profile_dir="/profiles/${profile_name}"

    if [ -d "$profile_dir" ]; then
        return 0
    else
        return 1
    fi
}

# Función para leer información del perfil y mostrarla
show_profile_info() {
    local profile_dir=$1
    local profile_yml="$profile_dir/profile.yml"

    if [ ! -f "$profile_yml" ]; then
        return
    fi

    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"

    # Leer y mostrar información básica
    local name=$(grep "^name:" "$profile_yml" 2>/dev/null | sed 's/name: *//; s/"//g')
    local version=$(grep "^version:" "$profile_yml" 2>/dev/null | sed 's/version: *//; s/"//g')
    local description=$(grep "^description:" "$profile_yml" 2>/dev/null | sed 's/description: *//; s/"//g')

    if [ -n "$name" ]; then
        echo -e "${COLOR_BLUE}📦 Perfil: ${COLOR_GREEN}${name}${COLOR_RESET}${COLOR_BLUE} v${version}${COLOR_RESET}"
    fi

    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"

    if [ -n "$description" ]; then
        echo -e ""
        echo -e "${COLOR_BLUE}📋 Descripción:${COLOR_RESET}"
        echo -e "  $description"
    fi

    # Mostrar información de infraestructura si existe
    if grep -q "^infrastructure:" "$profile_yml" 2>/dev/null; then
        echo -e ""
        local infra_desc=$(sed -n '/^infrastructure:/,/^  description:/ { /description:/ { s/.*description: *//; s/"//g; p } }' "$profile_yml")
        if [ -n "$infra_desc" ]; then
            echo -e "${COLOR_BLUE}🐳 Infraestructura:${COLOR_RESET}"
            echo -e "  $infra_desc"
        fi

        # Mostrar servicios
        echo -e ""
        echo -e "${COLOR_BLUE}📦 Servicios:${COLOR_RESET}"
        sed -n '/^  services:/,/^  [a-z]/ { /- name:/ { s/.*name: *//; s/"//g; p } }' "$profile_yml" | while read -r service; do
            echo -e "${COLOR_GREEN}  ✓${COLOR_RESET} $service"
        done

        # Mostrar pasos siguientes
        echo -e ""
        echo -e "${COLOR_BLUE}📝 Pasos siguientes:${COLOR_RESET}"
        local step_num=1
        sed -n '/^  next_steps:/,/^  [a-z]/ { /- "/ { s/.*- "//; s/".*//; p } }' "$profile_yml" | while read -r step; do
            echo -e "  ${step_num}. $step"
            step_num=$((step_num + 1))
        done

        # Mostrar comandos disponibles
        echo -e ""
        echo -e "${COLOR_BLUE}🛠️  Gestión de infraestructura:${COLOR_RESET}"
        local manage_script=$(grep "^  manage_script:" "$profile_yml" 2>/dev/null | sed 's/.*manage_script: *//; s/"//g')

        # Leer comandos y sus descripciones
        sed -n '/^  commands:/,/^[a-z]/ p' "$profile_yml" | grep -A 1 "- name:" | while read -r line; do
            if echo "$line" | grep -q "- name:"; then
                cmd_name=$(echo "$line" | sed 's/.*name: *//; s/"//g')
                read -r desc_line
                cmd_desc=$(echo "$desc_line" | sed 's/.*description: *//; s/"//g')
                if [ -n "$manage_script" ] && [ -n "$cmd_name" ]; then
                    echo -e "  ${COLOR_GREEN}${manage_script} ${cmd_name}${COLOR_RESET} - $cmd_desc"
                fi
            fi
        done
    fi

    echo -e ""
    echo -e "${COLOR_BLUE}⚡ Lanzando VSCode...${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e ""
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

    # Verificar que el perfil existe
    if ! profile_exists "$profile_name"; then
        echo -e "${COLOR_RED}⚠ Perfil '$profile_name' no encontrado${COLOR_RESET}"
        return 1
    fi

    # Mostrar información del perfil
    show_profile_info "$profile_dir"

    # Aplicar configuraciones de VSCode
    if [ -d "$profile_dir/vscode" ]; then
        apply_vscode_settings "$profile_dir"
        echo ""
    fi

    # Instalar extensiones de VSCode
    local extensions_file="$profile_dir/vscode/extensions.list"
    # Fallback a extensions.list en la raíz para retrocompatibilidad
    if [ ! -f "$extensions_file" ] && [ -f "$profile_dir/extensions.list" ]; then
        extensions_file="$profile_dir/extensions.list"
    fi

    if [ -f "$extensions_file" ]; then
        install_vscode_extensions "$extensions_file"
        echo ""
    fi

    echo -e "${COLOR_GREEN}✓ Perfil '$profile_name' cargado correctamente${COLOR_RESET}"
    echo ""

    return 0
}
