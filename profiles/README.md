# Perfiles de VSCode

## Concepto

Un **perfil** es simplemente una configuración de VSCode: extensiones y settings específicos para un tipo de desarrollo.

**Los perfiles NO incluyen:**
- ❌ Scripts de orquestación
- ❌ Docker compose de servicios
- ❌ Comandos de gestión
- ❌ Configuración de infraestructura

**Los perfiles SÍ incluyen:**
- ✅ Lista de extensiones de VSCode
- ✅ Settings.json específicos
- ✅ Documentación de uso

## Estructura de un Perfil

```
profiles/nombre-perfil/
├── README.md              # Documentación del perfil
└── vscode/
    ├── extensions.list    # Lista de extensiones a instalar
    └── settings.json      # Configuración de VSCode
```

## Crear un Nuevo Perfil

### 1. Crear la estructura

```bash
cd profiles
mkdir mi-perfil
mkdir mi-perfil/vscode
```

### 2. Crear `vscode/extensions.list`

Lista de extensiones, una por línea:

```
# mi-perfil/vscode/extensions.list
ms-python.python
ms-python.vscode-pylance
ms-python.black-formatter
```

**Cómo encontrar IDs de extensiones:**
1. Abre VSCode
2. Ve a extensiones
3. Click derecho en una extensión → "Copy Extension ID"

### 3. Crear `vscode/settings.json`

Configuración específica para este perfil:

```json
{
  "python.linting.enabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

**Nota:** Estos settings se **mergean** con los settings del usuario. Los del perfil tienen prioridad.

### 4. Crear `README.md`

Documenta:
- Para qué es el perfil
- Qué extensiones incluye y por qué
- Tips de uso
- Enlaces a recursos útiles

## Usar un Perfil

```bash
cd ~/mi-proyecto
./vsc-wslg dood up mi-perfil
```

El perfil:
1. Se monta en `/home/dev/vsc-wslg-mi-perfil-profile/` (read-only)
2. VSCode lee `vscode/extensions.list` e instala las extensiones
3. VSCode mergea `vscode/settings.json` con tu configuración
4. El README se abre automáticamente en la primera ejecución

## Filosofía: Separación de Responsabilidades

### Perfil = Configuración de Editor

El perfil configura tu **entorno de desarrollo en VSCode**:
- Syntax highlighting
- Linters
- Formatters
- Snippets
- Temas

### Proyecto = Infraestructura

Si necesitas servicios (bases de datos, caches, etc.), ponlos en el **docker-compose.yml de tu proyecto**:

```
~/mi-proyecto/
├── docker-compose.yml    # ← MySQL, Redis, etc.
├── src/
└── ...

# Usar:
./vsc-wslg dood up symfony  # VSCode con perfil symfony
cd ~/mi-proyecto
docker compose up -d        # Servicios del proyecto
```

**Ventajas:**
- ✅ Reutilizas el mismo perfil para múltiples proyectos
- ✅ Cada proyecto define su propia infraestructura
- ✅ No mezclas configuración de editor con orquestación de servicios
- ✅ Simplicidad: un perfil es solo 2 archivos

## Perfiles Incluidos

### symfony
**Para:** Desarrollo PHP/Symfony
**Extensiones:** PHP Intelephense, Symfony Support, Twig, Composer, etc.
**Settings:** PHP formatting, debug configuration

### rust
**Para:** Desarrollo Rust
**Extensiones:** rust-analyzer, CodeLLDB, Dependi, TOML
**Settings:** Rust analyzer configuration, formatting

### devops
**Para:** DevOps, IaC, Scripts
**Extensiones:** Docker, Kubernetes, Terraform, Ansible, YAML, etc.
**Settings:** YAML indentation, shellcheck

## Tips

### Testing de un Perfil

Antes de usarlo en producción, prueba tu perfil:

```bash
mkdir ~/test-profile
cd ~/test-profile
./vsc-wslg dood up mi-perfil
```

Verifica que:
- ✓ Extensiones se instalen correctamente
- ✓ Settings se apliquen
- ✓ No hay conflictos

### Compartir Perfiles

Los perfiles son portables. Comparte el directorio completo:

```bash
tar czf mi-perfil.tar.gz profiles/mi-perfil/
# Compartir mi-perfil.tar.gz
```

Otro usuario:
```bash
cd vscode-wslg-docker
tar xzf mi-perfil.tar.gz -C profiles/
```

### Evolucionar un Perfil

Los perfiles evolucionan. Cuando descubras nuevas extensiones útiles:

1. Edita `vscode/extensions.list`
2. Rebuild del contenedor: `./vsc-wslg dood build`
3. Lanza de nuevo: `./vsc-wslg dood up mi-perfil`

Las nuevas extensiones se instalarán automáticamente.

## Troubleshooting

### Las extensiones no se instalan

**Causa:** Formato incorrecto en `extensions.list`

**Solución:**
- Una extensión por línea
- No espacios antes/después
- IDs exactos (case-sensitive)
- Sin comentarios inline (usa líneas separadas para comentarios con #)

### Settings no se aplican

**Causa:** JSON inválido

**Solución:**
```bash
# Validar JSON
jq . profiles/mi-perfil/vscode/settings.json
```

### El perfil no se monta

**Causa:** Variable de entorno no seteada

**Solución:** Asegúrate de especificar el perfil:
```bash
./vsc-wslg dood up mi-perfil  # ← necesario
```
