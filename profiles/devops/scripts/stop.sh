#!/bin/bash
set -e

cd "$SCRIPT_DIR"

echo "🛑 Deteniendo contenedor shell-tools..."
docker compose down

echo "✓ Contenedor detenido"
