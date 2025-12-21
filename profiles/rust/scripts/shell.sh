#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐚 Abriendo shell en contenedor Rust..."
echo ""

docker-compose -f "$SCRIPT_DIR/../docker-compose.yml" exec rust bash
