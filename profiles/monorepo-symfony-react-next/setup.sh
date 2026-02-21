#!/bin/bash
# ============================================================================
# Monorepo Symfony + React + Next.js - System Setup Script
# ============================================================================
# Full-stack monorepo environment: PHP/Symfony (API) + TypeScript/React/Next.js
# (frontends) with pnpm workspaces + Turborepo orchestration.
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

# Ensure noninteractive frontend for apt (sudo resets environment)
export DEBIAN_FRONTEND=noninteractive

echo "📦 Installing monorepo Symfony + React + Next.js environment..."

# Update package lists
sudo apt-get update -qq

# ============================================================================
# PHP + Extensions (Symfony backend)
# ============================================================================

echo "  → Installing PHP and extensions..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    php-cli \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip \
    php-intl \
    unzip

# ============================================================================
# Composer - PHP dependency manager
# ============================================================================

if ! command -v composer &> /dev/null; then
    echo "  → Installing Composer..."
    cd /tmp
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo "ERROR: Invalid Composer installer checksum"
        rm -f composer-setup.php
        exit 1
    fi

    sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
else
    echo "  ℹ Composer already installed, skipping..."
fi

# ============================================================================
# Symfony CLI
# ============================================================================

if ! command -v symfony &> /dev/null; then
    echo "  → Installing Symfony CLI..."
    curl -sS https://get.symfony.com/cli/installer | bash
    sudo mv ~/.symfony*/bin/symfony /usr/local/bin/symfony
else
    echo "  ℹ Symfony CLI already installed, skipping..."
fi

# ============================================================================
# Node.js 20.x LTS (React/Next.js frontends + shared packages)
# ============================================================================

if ! command -v node &> /dev/null; then
    echo "  → Installing Node.js 20.x LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
else
    echo "  ℹ Node.js already installed, skipping..."
fi

# ============================================================================
# pnpm - Fast, disk space efficient package manager
# ============================================================================

if ! command -v pnpm &> /dev/null; then
    echo "  → Installing pnpm..."
    export SHELL=/bin/bash
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    # Remove the block that pnpm installer appends to .bashrc
    # (PATH is already configured in .bashrc before zoxide)
    sed -i '/# pnpm$/,/# pnpm end$/d' ~/.bashrc
    export PNPM_HOME="/home/dev/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
else
    echo "  ℹ pnpm already installed, skipping..."
fi

# ============================================================================
# Global Node.js tools
# ============================================================================

echo "  → Installing global Node.js development tools..."
sudo npm install -g --silent \
    typescript \
    turbo

# ============================================================================
# Build essentials
# ============================================================================

echo "  → Installing build essentials..."
sudo apt-get install -y -qq \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✅ Monorepo Symfony + React + Next.js environment set up successfully!"
echo ""
echo "Installed tools:"
php --version | head -1
composer --version
symfony version
node --version
npm --version
pnpm --version 2>/dev/null || echo "pnpm: installed (restart shell to use)"
echo ""
echo "Available tools:"
echo "  • php/composer  - PHP runtime and dependency manager"
echo "  • symfony       - Symfony CLI (serve, console, etc.)"
echo "  • node/npm      - JavaScript runtime and package manager"
echo "  • pnpm          - Fast, disk-efficient package manager"
echo "  • turbo         - Turborepo CLI for monorepo orchestration"
echo "  • typescript    - TypeScript compiler (tsc)"
echo ""
echo "Quick start:"
echo "  pnpm install    - Install all workspace dependencies"
echo "  pnpm dev        - Start all apps in development mode"
echo "  pnpm build      - Build all apps and packages"
echo ""
