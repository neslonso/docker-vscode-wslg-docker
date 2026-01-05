# Perfil Rust - Desarrollo multiplataforma

Entorno de desarrollo Rust con herramientas esenciales y soporte para cross-compilation a Windows.

## ¿Qué proporciona este perfil?

### Herramientas del sistema (pre-instaladas)

- **Rust toolchain** (stable) vía rustup
  - rustc, cargo, clippy, rustfmt
- **Build tools**
  - build-essential (gcc, g++, make)
  - MinGW-w64 (compilador cruzado para Windows)
- **Herramientas cargo**
  - cargo-watch - Recompilación automática en cambios
  - cargo-edit - Gestión de dependencias (add/rm/upgrade)
  - cargo-audit - Escáner de vulnerabilidades

### Extensiones VSCode

- **rust-analyzer** - LSP oficial de Rust
- **CodeLLDB** - Debugger
- **Dependi** - Gestor visual de dependencias
- **Even Better TOML** - Soporte para Cargo.toml
- **Git Graph** - Visualización de historial
- **Docker** - Gestión de contenedores

### Configuraciones VSCode

- Clippy en save (linting automático)
- Format on save con rustfmt
- Inlay hints (tipos, parámetros, chaining)
- Exclusión de `target/` en búsquedas y watchers
- Ruler a 100 columnas (estándar Rust)

## Inicio rápido

```bash
./vsc-wslg dood up rust
```

Una vez dentro del contenedor:

```bash
# Crear nuevo proyecto
cargo new mi-proyecto
cd mi-proyecto

# Desarrollar
cargo run

# Tests
cargo test

# Watch mode (recompila automáticamente)
cargo watch -x run
```

## Cross-compilation a Windows

El perfil incluye **MinGW-w64**, que permite compilar ejecutables de Windows desde Linux.

### Configuración por proyecto

Cada proyecto que necesite cross-compilation debe configurarse:

1. **Agregar el target de Windows:**
   ```bash
   rustup target add x86_64-pc-windows-gnu
   ```

2. **Configurar el linker** - Crear `.cargo/config.toml`:
   ```toml
   [target.x86_64-pc-windows-gnu]
   linker = "x86_64-w64-mingw32-gcc"
   ```

3. **Compilar para Windows:**
   ```bash
   cargo build --target x86_64-pc-windows-gnu --release
   ```

   El ejecutable estará en:
   ```
   target/x86_64-pc-windows-gnu/release/mi-proyecto.exe
   ```

### Multi-target build

```bash
# Linux (nativo)
cargo build --release

# Windows
cargo build --target x86_64-pc-windows-gnu --release
```

### Dependencias específicas por plataforma

```toml
# Cargo.toml
[dependencies]
# Dependencias comunes para todas las plataformas
serde = "1.0"

[target.'cfg(windows)'.dependencies]
# Solo para Windows
winapi = { version = "0.3", features = ["winuser"] }

[target.'cfg(unix)'.dependencies]
# Solo para Linux/Unix
libc = "0.2"
```

## Comandos útiles

### Desarrollo
```bash
cargo run              # Compilar y ejecutar
cargo build            # Solo compilar
cargo check            # Verificar sin generar binario (más rápido)
cargo watch -x run     # Auto-recompilación en cambios
```

### Calidad de código
```bash
cargo fmt              # Formatear código
cargo clippy           # Linter (más estricto que rustc)
cargo test             # Ejecutar tests
cargo doc --open       # Generar y abrir documentación
```

### Gestión de dependencias
```bash
cargo add serde        # Agregar dependencia
cargo rm serde         # Eliminar dependencia
cargo upgrade          # Actualizar dependencias
cargo tree             # Ver árbol de dependencias
cargo audit            # Escanear vulnerabilidades
```

## Debugging

VSCode está configurado con CodeLLDB:

1. Coloca breakpoints (click en el margen izquierdo)
2. Presiona **F5** o usa menú "Run > Start Debugging"
3. El debugger se adjunta automáticamente

## Estructura de proyecto recomendada

```
mi-proyecto/
├── .cargo/
│   └── config.toml          # Configuración de linkers (si usas cross-compilation)
├── src/
│   ├── main.rs              # Punto de entrada
│   └── lib.rs               # Biblioteca (opcional)
├── tests/                   # Tests de integración
├── benches/                 # Benchmarks
├── Cargo.toml               # Manifest del proyecto
└── README.md
```

## Notas importantes

### Sobre cross-compilation

- ✅ **MinGW-w64 está pre-instalado** - No necesitas instalarlo
- 📋 **Targets son por proyecto** - Cada proyecto debe agregar los targets que necesite
- 🔧 **Configuración de linker es por proyecto** - Usa `.cargo/config.toml`
- 📦 **Los .exe generados son portables** - Funcionan en Windows sin dependencias

### Optimización

Para builds de producción, edita `Cargo.toml`:

```toml
[profile.release]
opt-level = 3          # Optimización máxima
lto = true             # Link-time optimization
codegen-units = 1      # Mejor optimización, compilación más lenta
strip = true           # Eliminar símbolos de debug
```

### Primera compilación

La primera compilación para Windows puede tardar varios minutos:
- Descarga librerías estándar de Rust para Windows
- Compila todas las dependencias desde cero
- Compilaciones subsecuentes usan caché

## Recursos

- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [rust-analyzer manual](https://rust-analyzer.github.io/manual.html)
