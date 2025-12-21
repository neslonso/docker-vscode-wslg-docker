#!/bin/bash
set -e

cd "$SCRIPT_DIR"

echo "🚀 Iniciando contenedor shell-tools..."
docker compose up -d

echo ""
echo "✓ Contenedor iniciado"
echo ""
echo "Para abrir una shell interactiva:"
echo "  $SCRIPT_DIR/manage shell"
echo ""
echo "Herramientas disponibles:"
echo "  - shellcheck (linter bash)"
echo "  - shfmt (formateo bash)"
echo "  - hadolint (linter Dockerfiles)"
echo "  - yamllint (validación YAML)"
echo "  - yq (procesador YAML)"
echo "  - bats (testing bash)"
echo "  - dive (análisis imágenes Docker)"
echo "  - docker, docker compose"
