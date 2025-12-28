#!/bin/bash
# ============================================================================
# Python Profile - System Setup Script
# ============================================================================
# This script installs Python development tools including Poetry, linters,
# testing frameworks, and GUI support (Tkinter).
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

echo "📦 Installing Python development environment..."

# Update package lists
sudo apt-get update -qq

# ============================================================================
# Python base packages and GUI support
# ============================================================================

echo "  → Installing Python packages and Tkinter (GUI support)..."
sudo apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-tk \
    tk-dev \
    build-essential

# ============================================================================
# Poetry - Modern dependency management
# ============================================================================

if ! command -v poetry &> /dev/null; then
    echo "  → Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -

    # Add Poetry to PATH for current session
    export PATH="/home/dev/.local/bin:$PATH"
else
    echo "  ℹ Poetry already installed, skipping..."
fi

# ============================================================================
# Development tools and linters
# ============================================================================

echo "  → Installing Python development tools..."
# Use --break-system-packages since this is an isolated Docker container
sudo pip3 install --break-system-packages -q \
    black \
    flake8 \
    mypy \
    isort \
    pylint \
    pytest \
    pytest-mock \
    pytest-cov \
    autopep8 \
    pydocstyle

# ============================================================================
# Additional useful tools
# ============================================================================

echo "  → Installing additional Python tools..."
sudo pip3 install --break-system-packages -q \
    ipython \
    virtualenv \
    pipenv

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✅ Python environment set up successfully!"
echo ""
echo "Installed tools:"
python3 --version
poetry --version 2>/dev/null || echo "Poetry: installed (restart shell to use)"
echo ""
echo "Available tools:"
echo "  • poetry      - Modern Python dependency management"
echo "  • black       - Code formatter"
echo "  • flake8      - Style guide enforcement"
echo "  • mypy        - Static type checker"
echo "  • isort       - Import statement organizer"
echo "  • pylint      - Code analysis"
echo "  • pytest      - Testing framework"
echo "  • ipython     - Enhanced interactive Python shell"
echo "  • tk/tkinter  - GUI development support"
echo ""
echo "GUI Support:"
echo "  • Tkinter/tk-dev installed for GUI applications"
echo "  • Compatible with PySimpleGUI, matplotlib, etc."
echo ""
