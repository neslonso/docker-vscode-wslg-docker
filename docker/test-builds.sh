#!/bin/bash
# Script de testing para validar los builds de las imágenes refactorizadas
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================================================"
echo "Testing Fase 1: Consolidación de Dockerfiles"
echo "======================================================================"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_passed=0
test_failed=0

# Función para reportar tests
report_test() {
    local test_name=$1
    local result=$2

    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        test_passed=$((test_passed + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        test_failed=$((test_failed + 1))
    fi
}

echo "1. Verificando que archivos necesarios existen..."
echo "---"

# Test 1: Dockerfile.base existe
if [ -f "$PROJECT_ROOT/docker/Dockerfile.base" ]; then
    report_test "Dockerfile.base existe" 0
else
    report_test "Dockerfile.base existe" 1
fi

# Test 2: docker-compose.yml actualizados
if grep -q "docker/Dockerfile.base" "$PROJECT_ROOT/DinD/docker-compose.yml"; then
    report_test "DinD/docker-compose.yml usa Dockerfile.base" 0
else
    report_test "DinD/docker-compose.yml usa Dockerfile.base" 1
fi

if grep -q "docker/Dockerfile.base" "$PROJECT_ROOT/DooD/docker-compose.yml"; then
    report_test "DooD/docker-compose.yml usa Dockerfile.base" 0
else
    report_test "DooD/docker-compose.yml usa Dockerfile.base" 1
fi

# Test 3: Build args configurados correctamente
if grep -q 'INSTALL_DOCKER_DAEMON: "true"' "$PROJECT_ROOT/DinD/docker-compose.yml"; then
    report_test "DinD tiene INSTALL_DOCKER_DAEMON=true" 0
else
    report_test "DinD tiene INSTALL_DOCKER_DAEMON=true" 1
fi

if grep -q 'INSTALL_DOCKER_DAEMON: "false"' "$PROJECT_ROOT/DooD/docker-compose.yml"; then
    report_test "DooD tiene INSTALL_DOCKER_DAEMON=false" 0
else
    report_test "DooD tiene INSTALL_DOCKER_DAEMON=false" 1
fi

echo ""
echo "2. Verificando sintaxis de Dockerfile.base..."
echo "---"

# Test 4: FROM statement válido
if grep -q "^FROM debian:bookworm-slim" "$PROJECT_ROOT/docker/Dockerfile.base"; then
    report_test "FROM statement correcto" 0
else
    report_test "FROM statement correcto" 1
fi

# Test 5: ARG statements presentes
if grep -q "^ARG INSTALL_DOCKER_DAEMON" "$PROJECT_ROOT/docker/Dockerfile.base"; then
    report_test "ARG INSTALL_DOCKER_DAEMON definido" 0
else
    report_test "ARG INSTALL_DOCKER_DAEMON definido" 1
fi

if grep -q "^ARG ENTRYPOINT_MODE" "$PROJECT_ROOT/docker/Dockerfile.base"; then
    report_test "ARG ENTRYPOINT_MODE definido" 0
else
    report_test "ARG ENTRYPOINT_MODE definido" 1
fi

# Test 6: Lógica condicional para Docker daemon
if grep -q 'if \[ "\$INSTALL_DOCKER_DAEMON" = "true" \]' "$PROJECT_ROOT/docker/Dockerfile.base"; then
    report_test "Lógica condicional para Docker daemon presente" 0
else
    report_test "Lógica condicional para Docker daemon presente" 1
fi

# Test 7: COPY de entrypoint con variable
if grep -q 'COPY.*\${ENTRYPOINT_MODE}.*entrypoint.sh' "$PROJECT_ROOT/docker/Dockerfile.base"; then
    report_test "COPY dinámico de entrypoint configurado" 0
else
    report_test "COPY dinámico de entrypoint configurado" 1
fi

echo ""
echo "3. Intentando builds (requiere Docker)..."
echo "---"

# Test 8: Build DinD
if command -v docker &> /dev/null; then
    echo "Construyendo imagen DinD..."
    cd "$PROJECT_ROOT"
    if docker compose -f DinD/docker-compose.yml build 2>&1 | tee /tmp/dind-build.log; then
        report_test "Build DinD exitoso" 0
    else
        report_test "Build DinD exitoso" 1
        echo -e "${YELLOW}Ver log en /tmp/dind-build.log${NC}"
    fi

    # Test 9: Build DooD
    echo "Construyendo imagen DooD..."
    if docker compose -f DooD/docker-compose.yml build 2>&1 | tee /tmp/dood-build.log; then
        report_test "Build DooD exitoso" 0
    else
        report_test "Build DooD exitoso" 1
        echo -e "${YELLOW}Ver log en /tmp/dood-build.log${NC}"
    fi

    # Test 10: Verificar que las imágenes tienen los tamaños esperados
    echo ""
    echo "Tamaños de imágenes:"
    docker images | grep vscode-wslg

else
    echo -e "${YELLOW}⚠ Docker no disponible, omitiendo builds${NC}"
    echo "  Ejecuta este script en un entorno con Docker para validar los builds"
fi

echo ""
echo "======================================================================"
echo "Resumen de Tests"
echo "======================================================================"
echo -e "${GREEN}Passed:${NC} $test_passed"
echo -e "${RED}Failed:${NC} $test_failed"
echo ""

if [ $test_failed -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los tests pasaron!${NC}"
    exit 0
else
    echo -e "${RED}✗ Algunos tests fallaron${NC}"
    exit 1
fi
