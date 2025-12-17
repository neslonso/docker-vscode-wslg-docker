#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_DIR="/workspace"

export WORKSPACE_DIR
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-symfony}"

echo "🚀 Levantando infraestructura Symfony..."
echo ""

# Levantar servicios
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo ""
echo "✓ Servicios levantados correctamente"
echo ""
echo "📋 Servicios disponibles:"
echo "  • PHP 8.2-fpm    http://localhost (via php container)"
echo "  • MySQL 8.0      localhost:3306"
echo "  • Redis 7        localhost:6379"
echo ""
echo "🔗 Conexión a base de datos:"
echo "  DATABASE_URL=mysql://symfony:secret@mysql:3306/symfony_db"
echo ""
echo "💡 Comandos útiles:"
echo "  composer install              - Instalar dependencias"
echo "  bin/console doctrine:...      - Comandos de Doctrine"
echo "  symfony serve                 - Servidor de desarrollo (alternativo)"
echo ""
