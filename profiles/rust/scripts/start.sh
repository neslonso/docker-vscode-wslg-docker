#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="/workspace"

export WORKSPACE_DIR
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-rust}"

echo "🦀 Levantando contenedor Rust..."
echo ""

# Levantar contenedor
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo ""
echo "✓ Contenedor Rust levantado correctamente"
echo ""
echo "📋 Toolchain disponible:"
echo "  • Rust stable ($(docker-compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T rust rustc --version 2>/dev/null || echo 'verificar con: rustc --version'))"
echo "  • Cargo ($(docker-compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T rust cargo --version 2>/dev/null || echo 'verificar con: cargo --version'))"
echo "  • Targets: x86_64-unknown-linux-gnu, x86_64-pc-windows-gnu"
echo ""
echo "💡 Comandos útiles:"
echo "  cargo new mi-proyecto         - Crear nuevo proyecto"
echo "  cargo build --release         - Compilar para Linux"
echo "  cargo build --target x86_64-pc-windows-gnu --release"
echo "                                - Compilar para Windows"
echo "  cargo test                    - Ejecutar tests"
echo "  cargo clippy                  - Linter"
echo ""
echo "🐚 Abrir shell en el contenedor:"
echo "  ~/vsc-wslg-rust-profile/manage shell"
echo ""
