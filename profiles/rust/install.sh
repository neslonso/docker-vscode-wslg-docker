#!/bin/bash
set -e

echo "🦀 Instalando Rust toolchain con soporte para Windows..."

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" &>/dev/null
}

# Actualizar repositorios
echo "→ Actualizando repositorios..."
sudo apt-get update -qq

# Instalar dependencias necesarias para compilar Rust y cross-compilation
echo "→ Instalando dependencias de build..."
BUILD_DEPS=(
    "build-essential"
    "curl"
    "pkg-config"
    "libssl-dev"
    "mingw-w64"
    "git"
)

for pkg in "${BUILD_DEPS[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        echo "  → Instalando $pkg"
        sudo apt-get install -y "$pkg" >/dev/null 2>&1
    else
        echo "  ✓ Ya instalado: $pkg"
    fi
done

# Instalar rustup (gestor de versiones de Rust)
if ! command_exists rustup; then
    echo "→ Instalando rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default
    source "$HOME/.cargo/env"
    echo "  ✓ rustup instalado"
else
    echo "  ✓ rustup ya instalado"
    source "$HOME/.cargo/env"
fi

# Asegurar que tenemos la toolchain estable más reciente
echo "→ Configurando Rust stable..."
rustup default stable
rustup update stable >/dev/null 2>&1

# Agregar target para compilación cruzada a Windows
echo "→ Agregando target para Windows (x86_64-pc-windows-gnu)..."
if ! rustup target list --installed | grep -q "x86_64-pc-windows-gnu"; then
    rustup target add x86_64-pc-windows-gnu
    echo "  ✓ Target Windows agregado"
else
    echo "  ✓ Target Windows ya instalado"
fi

# Instalar componentes útiles
echo "→ Instalando componentes de Rust..."
COMPONENTS=("clippy" "rustfmt" "rust-src" "rust-analysis")
for comp in "${COMPONENTS[@]}"; do
    if ! rustup component list --installed | grep -q "^$comp"; then
        echo "  → Instalando $comp"
        rustup component add "$comp" >/dev/null 2>&1
    else
        echo "  ✓ Ya instalado: $comp"
    fi
done

# Instalar herramientas adicionales de cargo
echo "→ Instalando herramientas de cargo..."
CARGO_TOOLS=(
    "cargo-watch"
    "cargo-edit"
    "cargo-expand"
    "cargo-tree"
)

for tool in "${CARGO_TOOLS[@]}"; do
    if ! command_exists "$tool"; then
        echo "  → Instalando $tool"
        cargo install "$tool" >/dev/null 2>&1 || echo "  ⚠ No se pudo instalar $tool (continuando...)"
    else
        echo "  ✓ Ya instalado: $tool"
    fi
done

# Configurar el linker para cross-compilation a Windows
CARGO_CONFIG_DIR="$HOME/.cargo"
CARGO_CONFIG_FILE="$CARGO_CONFIG_DIR/config.toml"

echo "→ Configurando linker para Windows..."
mkdir -p "$CARGO_CONFIG_DIR"

if ! grep -q "x86_64-pc-windows-gnu" "$CARGO_CONFIG_FILE" 2>/dev/null; then
    cat >> "$CARGO_CONFIG_FILE" <<'EOF'

# Configuración para cross-compilation a Windows
[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"
ar = "x86_64-w64-mingw32-ar"
EOF
    echo "  ✓ Linker configurado"
else
    echo "  ✓ Linker ya configurado"
fi

echo ""
echo "✓ Entorno Rust configurado correctamente"
echo "  Rust version: $(rustc --version)"
echo "  Cargo version: $(cargo --version)"
echo "  Targets instalados:"
rustup target list --installed | grep -E "(x86_64-unknown-linux-gnu|x86_64-pc-windows-gnu)" | sed 's/^/    - /'
echo ""
echo "📝 Para compilar para Windows usa:"
echo "   cargo build --target x86_64-pc-windows-gnu --release"
