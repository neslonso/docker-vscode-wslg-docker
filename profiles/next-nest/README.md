# Next-Nest Development Profile

Complete TypeScript full-stack development environment with Next.js, NestJS, and Turborepo monorepo support.

## Overview

This profile provides a comprehensive TypeScript development setup for modern full-stack applications combining:

- **Next.js** - React framework for frontend development
- **NestJS** - Progressive Node.js framework for backend APIs
- **Turborepo** - High-performance build system for monorepos
- **Prisma** - Next-generation ORM for database management
- **PostgreSQL & Redis** - Database and caching solutions

Perfect for web applications, APIs, SaaS platforms, and microservices architectures.

## Features

### Development Tools

- **Node.js 20.x LTS** - Latest long-term support version
- **pnpm** - Fast, disk-efficient package manager (ideal for monorepos)
- **Turborepo** - High-performance build system for monorepos
- **TypeScript** - Static type checking and compilation
- **ts-node / tsx** - TypeScript execution engines

### Framework & Runtime

- **Next.js 14+** - Frontend framework with App Router
- **NestJS** - Backend framework with CQRS + Event Sourcing support
- **Prisma** - Next-generation ORM
- **PostgreSQL client** - Database management tools
- **Redis tools** - Cache management

### Code Quality & Formatting

- **ESLint** - Linting and code quality enforcement
- **Prettier** - Code formatter (configured with tabs, same-line braces)
- **TypeScript strict mode** - Type safety guarantees

### Testing Framework

- **Jest** - Testing framework with coverage
- **Testing Library** - Component testing utilities
- **Supertest** - HTTP assertion library

### VSCode Extensions

**TypeScript/JavaScript Core:**
- ESLint
- Prettier
- TypeScript language features
- IntelliCode (AI completions)

**Frontend Development:**
- Next.js snippets
- Tailwind CSS IntelliSense
- Auto rename tag
- Auto close tag

**Backend Development:**
- NestJS snippets and tooling
- REST client
- Postman integration

**Database & ORM:**
- Prisma extension
- SQLTools with PostgreSQL driver
- PostgreSQL client support

**Testing:**
- Jest extension
- Jest runner

**Utilities:**
- Git Graph & GitLens
- Docker support
- Path IntelliSense
- NPM IntelliSense
- Import Cost
- Error Lens
- TODO Tree
- Better Comments

## Quick Start

### Launch the Environment

```bash
# From your project directory
vsc-wslg up next-nest

# Or with DooD mode (share host Docker)
vsc-wslg up next-nest dood
```

### Typical Project Structure - Turborepo Monorepo

```
my-project/
├── apps/
│   ├── web/          # Next.js frontend
│   └── api/          # NestJS backend
├── packages/
│   ├── ui/           # Shared UI components
│   ├── database/     # Prisma schema and client
│   ├── config/       # Shared configuration
│   └── tsconfig/     # Shared TypeScript configs
├── turbo.json
├── package.json
└── pnpm-workspace.yaml
```

## Usage Examples

### Initial Setup

```bash
# Inside VSCode container terminal

# Install all dependencies (monorepo-aware)
pnpm install

# Run development servers for all apps
pnpm dev

# Build all packages and apps
pnpm build

# Run all tests
pnpm test
```

### Working with Specific Apps/Packages

```bash
# Run Next.js frontend only
pnpm --filter web dev

# Run NestJS backend only
pnpm --filter api dev

# Build specific package
pnpm --filter @myorg/database build

# Test specific package
pnpm --filter @myorg/ui test
```

### Database Management (Prisma)

```bash
# Generate Prisma client
pnpm --filter api prisma generate

# Create migration
pnpm --filter api prisma migrate dev --name init

# Apply migrations
pnpm --filter api prisma migrate deploy

# Open Prisma Studio (database GUI)
pnpm --filter api prisma studio

# Seed database
pnpm --filter api prisma db seed
```

### Development Workflow

```bash
# Start PostgreSQL and Redis (via Docker Compose)
docker-compose up -d postgres redis

# Run dev servers with hot reload
pnpm dev

# Run tests in watch mode
pnpm test:watch

# Type checking
pnpm typecheck

# Linting
pnpm lint

# Format code
pnpm format
```

## Configuration

### Prettier Settings (Pre-configured)

The profile uses the following code style:

- **Tabs:** Enabled (not spaces)
- **Tab width:** 2
- **Braces:** Same line (`{ }`)
- **Semicolons:** Required
- **Quotes:** Single quotes
- **Trailing commas:** ES5 style
- **Print width:** 100 characters
- **Line endings:** LF (Unix-style)

### ESLint Configuration

Auto-fix on save is enabled for:
- ESLint rule violations
- Import organization
- TypeScript formatting

### TypeScript Configuration

Inlay hints enabled for:
- Parameter names and types
- Variable types
- Return types
- Property declarations
- Enum member values

### Workspace Settings

The profile is pre-configured with:
- **Format on save:** Enabled
- **Organize imports on save:** Enabled
- **ESLint auto-fix on save:** Enabled
- **Default package manager:** pnpm
- **Excluded from search:** node_modules, .next, dist, build, .turbo

## Common Workflows

### Creating a New Package

```bash
# Inside packages/ directory
mkdir my-new-package
cd my-new-package

# Initialize package.json
pnpm init

# Add to workspace (pnpm-workspace.yaml handles this)
# Start coding!
```

### Adding Dependencies

```bash
# Add dependency to specific package
pnpm --filter @myorg/api add axios

# Add dev dependency
pnpm --filter @myorg/web add -D @types/node

# Add dependency to all packages
pnpm add -w typescript
```

### Running Commands Across All Packages

```bash
# Turbo runs commands in dependency order with caching
turbo run build
turbo run test
turbo run lint

# Force rebuild (bypass cache)
turbo run build --force

# Run with concurrency
turbo run dev --parallel
```

### Debugging

**Next.js (Frontend):**
1. Set breakpoints in VSCode
2. Press F5 or use "Run and Debug"
3. Select "Next.js: debug full stack"

**NestJS (Backend):**
1. Add debug script to package.json:
   ```json
   "start:debug": "nest start --debug --watch"
   ```
2. Set breakpoints in VSCode
3. Use "Attach to Node" debug configuration

## Installed Development Tools

### System Packages
- `nodejs` (20.x LTS) - JavaScript runtime
- `npm` - Node package manager (comes with Node)
- `pnpm` - Fast package manager
- `postgresql-client` - PostgreSQL CLI tools
- `redis-tools` - Redis CLI tools
- `build-essential` - C/C++ compilation tools
- `git` - Version control
- `curl / wget` - HTTP clients

### Global NPM Packages
- `typescript` - TypeScript compiler
- `ts-node` - TypeScript execution engine
- `tsx` - Fast TypeScript runner
- `turbo` - Turborepo CLI
- `@nestjs/cli` - NestJS project generator and CLI
- `prisma` - Prisma CLI for database management

## Tips & Best Practices

### Monorepo Management

**Use workspace protocol for internal dependencies:**
```json
{
  "dependencies": {
    "@myorg/database": "workspace:*"
  }
}
```

**Leverage Turborepo caching:**
```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["build"]
    }
  }
}
```

### Code Quality

**Pre-commit checks:**
```json
// package.json
{
  "scripts": {
    "precommit": "turbo run lint test"
  }
}
```

**Run formatter before committing:**
```bash
pnpm format
git add .
git commit -m "feat: add new feature"
```

### Performance

**For faster development:**
- Use `tsx` for quick TypeScript execution
- Enable Turborepo cache for builds
- Use `pnpm --filter` to work on specific packages
- Leverage VSCode's TypeScript server instead of running `tsc --watch`

**Optimize Docker builds:**
```dockerfile
# Use .dockerignore to exclude:
node_modules
.next
.turbo
dist
```

### Database Workflow

**Development cycle:**
1. Modify Prisma schema (`schema.prisma`)
2. Create migration: `prisma migrate dev`
3. Prisma generates TypeScript types automatically
4. Use types in your NestJS services

**Production:**
```bash
prisma migrate deploy  # Apply migrations
prisma generate        # Generate client
```

## Troubleshooting

### pnpm Command Not Found

**Restart the shell or update PATH:**
```bash
export PNPM_HOME="/home/dev/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
source ~/.bashrc
```

### Extensions Not Installing

**Manually install:**
```bash
# Inside container
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
```

### Prisma Client Not Generated

**Regenerate client:**
```bash
pnpm --filter api prisma generate
```

**Ensure postinstall script exists:**
```json
// apps/api/package.json
{
  "scripts": {
    "postinstall": "prisma generate"
  }
}
```

### TypeScript Errors in VSCode

**Select workspace TypeScript version:**
1. Open any `.ts` file
2. Press `Ctrl+Shift+P`
3. Type "TypeScript: Select TypeScript Version"
4. Choose "Use Workspace Version"

### Turborepo Cache Issues

**Clear cache:**
```bash
turbo run build --force
# Or delete cache manually
rm -rf .turbo
```

### Hot Reload Not Working

**Check configuration:**
- Next.js: Verify `next.config.js` has `reactStrictMode: true`
- NestJS: Ensure using `nest start --watch`
- Verify volumes are mounted correctly in docker-compose

## PostgreSQL & Redis Connection

### Default Connection Strings

**PostgreSQL:**
```env
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
```

**Redis:**
```env
REDIS_URL="redis://localhost:6379"
```

### Connect from Container

```bash
# PostgreSQL
psql -h postgres -U myuser -d mydb

# Redis
redis-cli -h redis
```

## Version Information

- **Node.js:** 20.x LTS
- **pnpm:** Latest stable
- **TypeScript:** Latest stable
- **Next.js:** 14+ (with App Router)
- **NestJS:** Latest stable
- **Prisma:** Latest stable
- **Turborepo:** Latest stable

## Related Profiles

- **python** - Python development with Poetry and testing
- **devops** - Shell scripting, Docker, YAML tools
- **rust** - Rust development with cargo

## Resources

- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [Next.js Documentation](https://nextjs.org/docs)
- [NestJS Documentation](https://docs.nestjs.com/)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Turborepo Documentation](https://turbo.build/repo/docs)
- [pnpm Documentation](https://pnpm.io/)

## Contributing

To enhance this profile:
1. Add new extensions to `vscode/extensions.list`
2. Update settings in `vscode/settings.json`
3. Add system packages to `setup.sh`
4. Update this README with new features
