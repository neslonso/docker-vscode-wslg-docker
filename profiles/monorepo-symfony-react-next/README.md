# Perfil monorepo-symfony-react-next

Entorno completo para monorepos full-stack que combinan un backend PHP/Symfony con frontends TypeScript/React y Next.js, orquestados con pnpm workspaces y Turborepo.

## Stack soportado

Este perfil está pensado para proyectos con una estructura tipo:

```
mi-proyecto/
├── apps/
│   ├── api/           # PHP/Symfony - Backend API (Twig, Doctrine, etc.)
│   ├── web/           # React + TypeScript - SPA (Vite, CRA, etc.)
│   └── landing/       # Next.js + TypeScript - SSR/SSG (App Router)
├── packages/
│   ├── types/         # Tipos TypeScript compartidos
│   ├── ui/            # Componentes React compartidos
│   └── ...            # Otros paquetes compartidos
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

La estructura exacta de directorios puede variar. Lo relevante es el combo de tecnologías.

## Herramientas instaladas

El script de setup instala automáticamente:

### PHP (backend Symfony)
- **PHP 8.2 CLI** con extensiones: xml, mbstring, curl, zip, intl
- **Composer** - Gestor de dependencias PHP
- **Symfony CLI** - Herramienta oficial de Symfony

### Node.js (frontends + paquetes compartidos)
- **Node.js 20.x LTS** - Runtime JavaScript
- **pnpm** - Gestor de paquetes (optimizado para monorepos)
- **Turborepo** - Sistema de build para monorepos
- **TypeScript** - Compilador TypeScript

## Extensiones de VSCode

### PHP / Symfony
- **PHP IntelliSense** (bmewburn.vscode-intelephense-client)
- **PHP Debug** (xdebug.php-debug)
- **PHP DocBlocker** (neilbrayfield.php-docblocker)
- **PHP CS Fixer** (junstyle.php-cs-fixer) - Formato @Symfony
- **PHPUnit** (recca0120.vscode-phpunit)
- **Symfony Support** (TheNouillet.symfony-vscode)
- **Twig Language** (mblode.twig-language-2)

### TypeScript / React / Next.js
- **ESLint** (dbaeumer.vscode-eslint)
- **Prettier** (esbenp.prettier-vscode)
- **TypeScript Next** (ms-vscode.vscode-typescript-next)
- **Next.js Snippets** (PulkitGangwar.nextjs-snippets)
- **Auto Rename Tag** (formulahendry.auto-rename-tag)

### Configuración y utilidades
- **YAML** (redhat.vscode-yaml)
- **DotENV** (mikestead.dotenv)
- **JSON** (ZainChen.json)
- **REST Client** (humao.rest-client)
- **Docker** (ms-azuretools.vscode-docker)
- **Git Graph** (mhutchie.git-graph) + **GitLens** (eamodio.gitlens)
- **Error Lens** (usernamehw.errorlens)
- **Path IntelliSense** (christian-kohler.path-intellisense)
- **NPM IntelliSense** (christian-kohler.npm-intellisense)
- **Import Cost** (wix.vscode-import-cost)
- **TODO Tree** (gruntfuggly.todo-tree)

### Configuraciones VSCode
- PHP: Format on save con PHP CS Fixer (@Symfony rules), IntelliSense PHP 8.2
- TypeScript/React: Format on save con Prettier, ESLint auto-fix, organize imports
- Twig: Asociación de archivos `.twig` y `.html.twig`
- Exclusiones de búsqueda: node_modules, vendor, .next, .turbo, lock files

## Uso

### 1. Levantar VSCode
```bash
# Desde el directorio de tu proyecto
./vsc-wslg up monorepo-symfony-react-next

# Con modo Docker-out-of-Docker (usa el Docker del host)
./vsc-wslg up monorepo-symfony-react-next dood
```

El modo por defecto es `dind` (Docker-in-Docker, Docker aislado dentro del contenedor).

### 2. Instalar dependencias
```bash
# Dependencias Node.js (monorepo completo)
pnpm install

# Dependencias PHP (app Symfony)
cd apps/api && composer install
```

### 3. Desarrollo
```bash
# Arrancar todos los servicios con Turborepo
pnpm dev

# O arrancar apps individuales
pnpm --filter web dev        # React SPA
pnpm --filter landing dev    # Next.js
cd apps/api && symfony serve  # Symfony API

# Build completo
pnpm build
```

## Gestión del contenedor

```bash
# === Ciclo de vida ===
./vsc-wslg up monorepo-symfony-react-next       # Levantar (foreground, se para al cerrar VSCode)
./vsc-wslg upd monorepo-symfony-react-next      # Levantar en background
./vsc-wslg upd-logs monorepo-symfony-react-next # Levantar en background + ver logs
./vsc-wslg down                                  # Parar y eliminar contenedor (mantiene volúmenes)
./vsc-wslg clean                                 # Parar, eliminar contenedor Y volúmenes (reset completo)

# === Reconstruir imagen ===
./vsc-wslg build                                 # Rebuild imagen (modo dind por defecto)
./vsc-wslg build dood                            # Rebuild imagen modo dood

# === Información ===
./vsc-wslg info                                  # Listar perfiles disponibles
./vsc-wslg info monorepo-symfony-react-next      # Ver este README
```

### Persistencia de datos

El contenedor usa dos volúmenes Docker para persistir datos entre reinicios:
- **vscode-extensions** - Extensiones instaladas (`~/.vscode`)
- **vscode-config** - Configuración de VSCode (`~/.config/Code`)

Al usar `down`, los volúmenes se mantienen (las extensiones y configuración sobreviven).
Al usar `clean`, los volúmenes se eliminan y el setup se ejecutará de nuevo al levantar.

### Re-ejecutar el setup

Si necesitas forzar la re-ejecución del script de setup (por ejemplo, tras actualizar el perfil):
```bash
./vsc-wslg clean
./vsc-wslg up monorepo-symfony-react-next
```

## Comandos útiles

```bash
# === Monorepo (pnpm + turbo) ===
pnpm install                   # Instalar todas las dependencias
pnpm dev                       # Dev servers (todas las apps)
pnpm build                     # Build completo
pnpm --filter <app> dev        # Dev server de una app concreta
turbo run build --force         # Build sin caché

# === PHP / Symfony ===
composer install               # Instalar dependencias PHP
symfony serve                  # Servidor de desarrollo
bin/console cache:clear        # Limpiar caché Symfony
bin/console make:controller    # Generar controlador
php bin/phpunit                # Tests

# === Paquetes compartidos ===
pnpm --filter @myorg/ui dev    # Desarrollo de un paquete
pnpm --filter @myorg/types build
```
