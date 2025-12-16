# Perfil Rust con Cross-Compilation a Windows

Entorno completo para desarrollo Rust con soporte nativo para compilación cruzada a Windows.

## Características

### Herramientas instaladas
- **Rust toolchain** (stable) vía rustup
- **Targets**:
  - `x86_64-unknown-linux-gnu` (Linux, por defecto)
  - `x86_64-pc-windows-gnu` (Windows 64-bit)
- **MinGW-w64** (compilador cruzado para Windows)
- **Componentes Rust**:
  - clippy (linter)
  - rustfmt (formateador)
  - rust-src (código fuente para autocompletado)
  - rust-analysis (análisis estático)
- **Herramientas Cargo**:
  - cargo-watch (recompilación automática)
  - cargo-edit (gestión de dependencias)
  - cargo-expand (expansión de macros)
  - cargo-tree (árbol de dependencias)

### Extensiones de VSCode
- **rust-analyzer** (rust-lang.rust-analyzer) - LSP para Rust
- **CodeLLDB** (vadimcn.vscode-lldb) - Debugger
- **crates** (serayuzgur.crates) - Gestor de dependencias
- **Even Better TOML** (tamasfe.even-better-toml) - Soporte para Cargo.toml
- **GitLens** (eamodio.gitlens)
- **Docker** (ms-azuretools.vscode-docker)

### Configuraciones
- Clippy habilitado en save
- Inlay hints activados (tipos, parámetros, chaining)
- Format on save con rustfmt
- Exclusión de carpeta `target` en búsquedas y watchers
- Ruler a 100 columnas (estándar Rust)
- Linker configurado para cross-compilation

## Uso

```bash
./vsc-wslg dood up rust
```

## Compilación

### Compilar para Linux (por defecto)
```bash
cargo build --release
```

### Compilar para Windows
```bash
cargo build --target x86_64-pc-windows-gnu --release
```

El ejecutable de Windows estará en:
```
target/x86_64-pc-windows-gnu/release/tu-proyecto.exe
```

### Compilar para ambas plataformas
```bash
# Linux
cargo build --release

# Windows
cargo build --target x86_64-pc-windows-gnu --release
```

## Comandos útiles

```bash
# Crear nuevo proyecto
cargo new mi-proyecto
cd mi-proyecto

# Compilar y ejecutar (Linux)
cargo run

# Compilar para Windows
cargo build --target x86_64-pc-windows-gnu

# Watch mode (recompila automáticamente)
cargo watch -x run

# Ejecutar tests
cargo test

# Ejecutar clippy
cargo clippy

# Formatear código
cargo fmt

# Ver árbol de dependencias
cargo tree

# Agregar dependencia
cargo add serde

# Expandir macros (útil para debugging)
cargo expand
```

## Estructura recomendada para cross-platform

```toml
# Cargo.toml
[package]
name = "mi-proyecto"
version = "0.1.0"
edition = "2021"

[dependencies]
# Dependencias comunes

[target.'cfg(windows)'.dependencies]
# Dependencias solo para Windows
winapi = "0.3"

[target.'cfg(unix)'.dependencies]
# Dependencias solo para Unix/Linux
```

## Debugging

VSCode viene configurado con CodeLLDB para debugging:
1. Coloca breakpoints en el código
2. Presiona F5 o usa "Run > Start Debugging"
3. El debugger arrancará automáticamente

## Notas

- La primera compilación para Windows puede tardar, ya que descarga las dependencias necesarias
- Los ejecutables de Windows generados son completamente portables
- Para compilar bibliotecas dinámicas (.dll), usa `--crate-type=cdylib` en lib.rs
- Para optimización máxima, usa `--release` con `lto = true` en Cargo.toml
