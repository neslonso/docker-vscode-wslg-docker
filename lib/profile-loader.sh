#!/bin/bash
# Biblioteca simplificada de funciones para cargar y procesar perfiles

# Colores para output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

# Función para verificar si un perfil existe (path directo)
profile_exists() {
    local profile_dir=$1

    if [ -d "$profile_dir" ]; then
        return 0
    else
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
        echo -e "${COLOR_BLUE}   DEBUG: Archivo settings: $profile_dir/vscode/settings.json${COLOR_RESET}"

        # Validar que el JSON es válido antes de continuar
        if ! jq empty "$profile_dir/vscode/settings.json" 2>/dev/null; then
            echo -e "${COLOR_RED}   ✗ ERROR: settings.json contiene JSON inválido${COLOR_RESET}"
            echo -e "${COLOR_RED}   Verifica que no tenga comentarios (//) o sintaxis incorrecta${COLOR_RESET}"
            return 1
        fi
        echo -e "${COLOR_GREEN}   ✓ JSON válido${COLOR_RESET}"

        # Si existe un settings.json del usuario, hacer merge
        if [ -f "$settings_dir/settings.json" ]; then
            echo -e "${COLOR_BLUE}   DEBUG: Settings de usuario encontrado, haciendo merge...${COLOR_RESET}"
            # Backup del settings original
            cp "$settings_dir/settings.json" "$settings_dir/settings.json.backup"

            # Merge usando jq (perfil no sobreescribe configuraciones del usuario)
            # Prioridad: PROFILE < USER (el usuario tiene la última palabra)
            if command -v jq &>/dev/null; then
                jq -s '.[0] * .[1]' \
                    "$profile_dir/vscode/settings.json" \
                    "$settings_dir/settings.json.backup" \
                    > "$settings_dir/settings.json.tmp" 2>&1

                if [ $? -eq 0 ]; then
                    mv "$settings_dir/settings.json.tmp" "$settings_dir/settings.json"
					echo -e "${COLOR_GREEN}  ✓ Settings mergeados correctamente${COLOR_RESET}"
                else
                    # Si falla el merge, usar solo el del perfil
                    echo -e "${COLOR_YELLOW}  ⚠ Error en merge, usando settings del perfil${COLOR_RESET}"
                    cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
                fi
            else
                # Si no hay jq, simplemente copiar el del perfil
                cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
				echo -e "${COLOR_YELLOW}  ⚠ jq no disponible, usando solo settings del perfil${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_BLUE}   DEBUG: No hay settings previos, aplicando del perfil${COLOR_RESET}"
            # No hay settings previos, usar los del perfil
            cp "$profile_dir/vscode/settings.json" "$settings_dir/settings.json"
            echo -e "${COLOR_GREEN}  ✓ Settings aplicados${COLOR_RESET}"
        fi
    fi

    # Copiar keybindings si existen (estos sí sobreescriben)
    if [ -f "$profile_dir/vscode/keybindings.json" ]; then
        cp "$profile_dir/vscode/keybindings.json" "$settings_dir/keybindings.json"
        echo -e "${COLOR_GREEN}  ✓ Keybindings aplicados${COLOR_RESET}"
    fi
}

# Función para preparar extensiones de VSCode
prepare_vscode_extensions() {
    local extensions_file=$1

    if [ ! -f "$extensions_file" ]; then
        return 0
    fi

    echo -e "${COLOR_BLUE}📦 Preparando extensiones de VSCode...${COLOR_RESET}"

    # Escribir lista de extensiones a un archivo temporal
    # El entrypoint leerá este archivo y pasará las extensiones como argumentos a VSCode
    local temp_file="/tmp/vscode_extensions_to_install"
    rm -f "$temp_file"

    local ext_count=0

    while IFS= read -r extension || [ -n "$extension" ]; do
        # Limpiar la línea
        extension="${extension%$'\r'}"
        extension="$(echo "$extension" | xargs)"

        # Saltar líneas vacías y comentarios
        [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

        echo "$extension" >> "$temp_file"
        ext_count=$((ext_count + 1))
    done < "$extensions_file"

    if [ $ext_count -gt 0 ]; then
        echo -e "${COLOR_GREEN}  ✓ $ext_count extensiones programadas para instalación${COLOR_RESET}"
    fi
}

# Función principal para procesar un perfil completo
process_profile() {
    local profile_dir=$1
    local profile_name=$(basename "$profile_dir" | sed 's/vsc-wslg-//; s/-profile//')

    # Verificar que el perfil existe
    if ! profile_exists "$profile_dir"; then
        echo -e "${COLOR_RED}⚠ Perfil no encontrado en: $profile_dir${COLOR_RESET}"
        return 1
    fi

    # Mensaje simple
    echo ""
    echo -e "${COLOR_BLUE}📦 Perfil: ${COLOR_GREEN}${profile_name}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}📖 Documentación: ${profile_dir}/README.md${COLOR_RESET}"
    echo ""

    # Aplicar configuraciones de VSCode
    if [ -d "$profile_dir/vscode" ]; then
        apply_vscode_settings "$profile_dir"
    fi

    # Instalar extensiones de VSCode
    local extensions_file="$profile_dir/vscode/extensions.list"
    # Fallback a extensions.list en la raíz para retrocompatibilidad
    if [ ! -f "$extensions_file" ] && [ -f "$profile_dir/extensions.list" ]; then
        extensions_file="$profile_dir/extensions.list"
    fi

    if [ -f "$extensions_file" ]; then
        prepare_vscode_extensions "$extensions_file"
    fi

    echo ""

    # Detectar primera vez (flag file por perfil)
    local flag_file="/home/dev/.config/Code/User/.profile_${profile_name}_opened"

    if [ ! -f "$flag_file" ]; then
        # Primera vez: guardar path del README para abrirlo
        echo "${profile_dir}/README.md" > /tmp/vscode_open_readme
        mkdir -p "$(dirname "$flag_file")"
        touch "$flag_file"
        echo -e "${COLOR_GREEN}👋 Primera vez con este perfil, se abrirá el README${COLOR_RESET}"
        echo ""
    fi

    return 0
}
