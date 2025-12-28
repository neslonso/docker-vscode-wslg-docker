#!/bin/bash
# ============================================================================
# Symfony Profile - System Setup Script
# ============================================================================
# This script installs Composer and Symfony CLI.
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

echo "📦 Installing PHP development tools..."

# Install required PHP extensions for Symfony
echo "  → Installing PHP extensions..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    php-cli \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip \
    php-intl \
    unzip

# Install Composer globally
if ! command -v composer &> /dev/null; then
    echo "  → Installing Composer..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo "ERROR: Invalid Composer installer checksum"
        rm composer-setup.php
        exit 1
    fi

    sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
else
    echo "  ℹ Composer already installed, skipping..."
fi

# Install Symfony CLI
if ! command -v symfony &> /dev/null; then
    echo "  → Installing Symfony CLI..."
    curl -sS https://get.symfony.com/cli/installer | bash
    sudo mv ~/.symfony*/bin/symfony /usr/local/bin/symfony
else
    echo "  ℹ Symfony CLI already installed, skipping..."
fi

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✅ PHP/Symfony environment set up successfully!"
echo ""
echo "Installed tools:"
php --version | head -1
composer --version
symfony version
echo ""
echo "Available commands:"
echo "  • composer - PHP dependency manager"
echo "  • symfony  - Symfony CLI (new, serve, console, etc.)"
