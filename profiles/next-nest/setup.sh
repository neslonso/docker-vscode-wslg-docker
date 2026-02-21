#!/bin/bash
# ============================================================================
# Next-Nest Profile - System Setup Script
# ============================================================================
# This script installs Node.js development tools for modern TypeScript
# full-stack development: Next.js, NestJS, pnpm, PostgreSQL/Redis clients,
# and essential tooling for monorepo development.
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

echo "📦 Installing Next-Nest development environment..."

# Update package lists
sudo apt-get update -qq

# ============================================================================
# Node.js 20.x LTS
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
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    # Remove the block that pnpm installer appends to .bashrc
    # (PATH is already configured in .bashrc before zoxide)
    sed -i '/# pnpm$/,/# pnpm end$/d' ~/.bashrc
    # Add pnpm to PATH for current session
    export PNPM_HOME="/home/dev/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
else
    echo "  ℹ pnpm already installed, skipping..."
fi

# ============================================================================
# PostgreSQL and Redis clients
# ============================================================================

echo "  → Installing PostgreSQL and Redis client tools..."
sudo apt-get install -y -qq \
    postgresql-client \
    redis-tools

# ============================================================================
# Build essentials and development tools
# ============================================================================

echo "  → Installing build essentials..."
sudo apt-get install -y -qq \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg

# ============================================================================
# Global Node.js tools
# ============================================================================

echo "  → Installing global Node.js development tools..."
sudo npm install -g --silent \
    typescript \
    ts-node \
    tsx \
    turbo \
    @nestjs/cli \
    prisma

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✅ Next-Nest environment set up successfully!"
echo ""
echo "Installed tools:"
node --version
npm --version
pnpm --version 2>/dev/null || echo "pnpm: installed (restart shell to use)"
echo ""
echo "Available tools:"
echo "  • node/npm    - JavaScript runtime and package manager"
echo "  • pnpm        - Fast, disk-efficient package manager"
echo "  • turbo       - High-performance build system for monorepos"
echo "  • typescript  - TypeScript compiler (tsc)"
echo "  • ts-node     - TypeScript execution engine"
echo "  • tsx         - TypeScript execute (faster alternative)"
echo "  • nest        - NestJS CLI"
echo "  • prisma      - Next-generation ORM CLI"
echo ""
echo "Database clients:"
echo "  • psql        - PostgreSQL interactive terminal"
echo "  • redis-cli   - Redis command line interface"
echo ""
echo "Ready for Next.js + NestJS development! 🚀"
echo ""
