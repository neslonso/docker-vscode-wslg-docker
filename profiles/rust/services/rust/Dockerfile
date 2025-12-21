FROM rust:latest

# Instalar dependencias para compilación y cross-compilation
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    pkg-config \
    libssl-dev \
    mingw-w64 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Agregar target para compilación cruzada a Windows
RUN rustup target add x86_64-pc-windows-gnu

# Instalar componentes útiles
RUN rustup component add \
    clippy \
    rustfmt \
    rust-src \
    rust-analysis

# Instalar herramientas adicionales de cargo
RUN cargo install cargo-watch cargo-edit cargo-expand cargo-tree || true

# Configurar linker para cross-compilation a Windows
RUN mkdir -p /usr/local/cargo && \
    echo "[target.x86_64-pc-windows-gnu]" >> /usr/local/cargo/config.toml && \
    echo "linker = \"x86_64-w64-mingw32-gcc\"" >> /usr/local/cargo/config.toml && \
    echo "ar = \"x86_64-w64-mingw32-ar\"" >> /usr/local/cargo/config.toml

WORKDIR /workspace

# Mantener el contenedor en ejecución
CMD ["tail", "-f", "/dev/null"]
