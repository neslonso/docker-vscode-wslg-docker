#!/bin/bash
# ============================================================================
# Rust Profile - System Setup Script
# ============================================================================
# This script installs Rust toolchain and common development tools.
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

echo "📦 Installing Rust toolchain and tools..."

# Install Rust via rustup (as dev user, not root)
if ! command -v rustc &> /dev/null; then
    echo "  → Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo env for this script
    source "$HOME/.cargo/env"
else
    echo "  ℹ Rust already installed, skipping..."
    source "$HOME/.cargo/env"
fi

# Install build tools required for compiling Rust crates
if ! command -v gcc &> /dev/null; then
    echo "  → Installing build tools (gcc, g++, make)..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq build-essential
else
    echo "  ℹ Build tools already installed, skipping..."
fi

# Install common Rust development tools
echo "  → Installing cargo tools..."

# cargo-watch - Auto-rebuild on file changes
if ! cargo install --list | grep -q "cargo-watch"; then
    cargo install cargo-watch --quiet
fi

# cargo-edit - Add/remove/upgrade dependencies from command line
if ! cargo install --list | grep -q "cargo-edit"; then
    cargo install cargo-edit --quiet
fi

# cargo-audit - Security vulnerability scanner
if ! cargo install --list | grep -q "cargo-audit"; then
    cargo install cargo-audit --quiet
fi

echo "✅ Rust environment set up successfully!"
echo ""
echo "Installed toolchain:"
rustc --version
cargo --version
echo ""
echo "Available cargo tools:"
echo "  • cargo-watch - Auto-rebuild on file changes"
echo "  • cargo-edit  - Add/remove dependencies (cargo add/rm/upgrade)"
echo "  • cargo-audit - Security vulnerability scanner"
echo ""
echo "Note: Restart your terminal or run 'source \$HOME/.cargo/env' to use Rust"
