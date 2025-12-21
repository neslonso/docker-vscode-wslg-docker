#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🛑 Deteniendo infraestructura Symfony..."

docker-compose -f "$SCRIPT_DIR/docker-compose.yml" down

echo "✓ Servicios detenidos"
