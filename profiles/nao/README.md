# Perfil nao

Entorno completo para el monorepo nao.info: API PHP/Symfony + frontends TypeScript/React/Next.js con Turborepo y pnpm.

## Arquitectura del proyecto

```
nao.info/
├── apps/
│   ├── api/           # PHP/Symfony - Backend API + Laboratory UI (Twig)
│   ├── web/           # React + TypeScript + Vite - SPA principal
│   └── showcase/      # Next.js + TypeScript - App Router
├── packages/
│   ├── types/         # Tipos TypeScript compartidos
│   ├── api-client/    # Cliente API TypeScript
│   └── ui/            # Componentes React compartidos
├── infra/
│   ├── docker/        # Dockerfiles (api, web, showcase)
│   └── nginx/         # Configuración Nginx
├── turbo.json
├── pnpm-workspace.yaml
└── Makefile
```

## Herramientas instaladas

El script de setup instala automáticamente:

### PHP (para apps/api)
- **PHP 8.2 CLI** con extensiones: xml, mbstring, curl, zip, intl
- **Composer** - Gestor de dependencias PHP
- **Symfony CLI** - Herramienta oficial de Symfony

### Node.js (para apps/web, apps/showcase, packages/*)
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
- **IntelliCode** (VisualStudioExptTeam.vscodeintellicode)
- **Next.js Snippets** (PulkitGangwar.nextjs-snippets)
- **Auto Rename Tag** (formulahendry.auto-rename-tag)
- **Auto Close Tag** (formulahendry.auto-close-tag)

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
./vsc-wslg up nao
```

### 2. Instalar dependencias
```bash
# Dependencias Node.js (monorepo completo)
pnpm install

# Dependencias PHP (apps/api)
cd apps/api && composer install
```

### 3. Desarrollo
```bash
# Arrancar todos los servicios con Turborepo
pnpm dev

# O arrancar apps individuales
pnpm --filter web dev         # React + Vite SPA
pnpm --filter showcase dev    # Next.js
cd apps/api && symfony serve   # Symfony API

# Build completo
pnpm build

# Infraestructura Docker (producción)
make up
```

## Comandos útiles

```bash
# === Monorepo (pnpm + turbo) ===
pnpm install                   # Instalar todas las dependencias
pnpm dev                       # Dev servers (todas las apps)
pnpm build                     # Build completo
pnpm --filter <app> dev        # Dev server de una app concreta

# === PHP / Symfony (apps/api) ===
cd apps/api
composer install               # Instalar dependencias PHP
symfony serve                  # Servidor de desarrollo
bin/console cache:clear        # Limpiar caché Symfony

# === Makefile (infra) ===
make up                        # Docker compose up
make down                      # Docker compose down
make build                     # Build imágenes Docker
```
