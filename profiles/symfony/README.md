# Perfil Symfony

Entorno completo para desarrollo PHP con Symfony Framework.

## Herramientas instaladas

El script de setup instala automáticamente:

- **PHP 8.2 CLI** con extensiones: xml, mbstring, curl, zip, intl
- **Composer** - Gestor de dependencias PHP
- **Symfony CLI** - Herramienta oficial de línea de comandos de Symfony

## Extensiones de VSCode

### PHP
- **PHP IntelliSense** (bmewburn.vscode-intelephense-client)
- **PHP Debug** (xdebug.php-debug)
- **PHP DocBlocker** (neilbrayfield.php-docblocker)
- **PHP CS Fixer** (junstyle.php-cs-fixer)
- **PHPUnit** (recca0120.vscode-phpunit)

### Symfony / Twig
- **Symfony Support** (TheNouillet.symfony-vscode)
- **Twig Language** (mblode.twig-language-2)

### Configuración y utilidades
- **YAML Support** (redhat.vscode-yaml)
- **DotENV** (mikestead.dotenv)
- **XML Tools** (DotJoshJohnson.xml)
- **Git Graph** (mhutchie.git-graph) - Visualización de historial
- **Docker** (ms-azuretools.vscode-docker)
- **Remote Containers** (ms-vscode-remote.remote-containers)

### Configuraciones VSCode
- Format on save activado con PHP CS Fixer (@Symfony rules)
- IntelliSense optimizado para PHP 8.2
- Asociaciones de archivos para Twig
- PHPUnit integrado (`vendor/bin/phpunit`)

## Uso

### 1. Levantar VSCode
```bash
./vsc-wslg up symfony
```

### 2. Crear un proyecto nuevo
```bash
# Con Symfony CLI
symfony new mi-proyecto --webapp

# O con Composer
composer create-project symfony/skeleton:"7.2.*" mi-proyecto
cd mi-proyecto
composer require webapp
```

### 3. Servidor de desarrollo
```bash
# Desde el directorio del proyecto
symfony serve
```

## Comandos útiles

```bash
# Comandos de Composer
composer install
composer require <paquete>
composer update

# Comandos de Symfony
bin/console doctrine:database:create
bin/console doctrine:migrations:migrate
bin/console cache:clear
bin/console make:controller

# Servidor de desarrollo
symfony serve

# Tests
php bin/phpunit
```
