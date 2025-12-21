#!/bin/bash
set -e

cd "$SCRIPT_DIR"

echo "📊 Estado de los contenedores:"
echo ""
docker compose ps
