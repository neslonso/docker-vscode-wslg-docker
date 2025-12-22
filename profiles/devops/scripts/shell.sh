#!/bin/bash
set -e

cd "$SCRIPT_DIR"

echo "🐚 Abriendo shell en contenedor shell-tools..."
echo ""
docker compose exec shell-tools /bin/bash
