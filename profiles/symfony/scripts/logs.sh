#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "📋 Logs de servicios Symfony (Ctrl+C para salir)..."
echo ""

docker-compose -f "$SCRIPT_DIR/docker-compose.yml" logs -f
