#!/bin/bash
set -e

echo "🐘 Instalando PHP y herramientas para Symfony..."

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" &>/dev/null
}

# Actualizar repositorios
sudo apt-get update -qq

# Instalar PHP y extensiones necesarias para Symfony
echo "→ Instalando PHP y extensiones..."
PACKAGES=(
    "php"
    "php-cli"
    "php-fpm"
    "php-xml"
    "php-mbstring"
    "php-curl"
    "php-zip"
    "php-intl"
    "php-sqlite3"
    "php-mysql"
    "php-pgsql"
    "php-gd"
    "unzip"
    "git"
)

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        echo "  → Instalando $pkg"
        sudo apt-get install -y "$pkg" >/dev/null 2>&1
    else
        echo "  ✓ Ya instalado: $pkg"
    fi
done

# Instalar Composer si no existe
if ! command_exists composer; then
    echo "→ Instalando Composer..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
        php composer-setup.php --quiet
        sudo mv composer.phar /usr/local/bin/composer
        rm composer-setup.php
        echo "  ✓ Composer instalado"
    else
        rm composer-setup.php
        echo "  ✗ Error: Checksum de Composer inválido"
        exit 1
    fi
else
    echo "  ✓ Composer ya instalado"
fi

# Instalar Symfony CLI si no existe
if ! command_exists symfony; then
    echo "→ Instalando Symfony CLI..."
    curl -sS https://get.symfony.com/cli/installer | bash >/dev/null 2>&1
    sudo mv ~/.symfony*/bin/symfony /usr/local/bin/symfony
    echo "  ✓ Symfony CLI instalado"
else
    echo "  ✓ Symfony CLI ya instalado"
fi

echo ""
echo "✓ Entorno Symfony configurado correctamente"
echo "  PHP version: $(php --version | head -n 1)"
echo "  Composer version: $(composer --version 2>/dev/null | head -n 1)"
echo "  Symfony CLI version: $(symfony version 2>/dev/null | head -n 1)"
