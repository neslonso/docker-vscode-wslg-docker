# Perfil Symfony

Entorno completo para desarrollo PHP con Symfony Framework.

## Características

### Herramientas instaladas
- PHP 8.x con extensiones necesarias (xml, mbstring, curl, zip, intl, etc.)
- Composer (gestor de dependencias PHP)
- Symfony CLI (herramienta oficial de Symfony)

### Extensiones de VSCode
- **PHP IntelliSense** (bmewburn.vscode-intelephense-client)
- **PHP Debug** (xdebug.php-debug)
- **PHP DocBlocker** (neilbrayfield.php-docblocker)
- **Symfony Support** (TheNouillet.symfony-vscode)
- **Twig Language** (mblode.twig-language-2)
- **YAML Support** (redhat.vscode-yaml)
- **PHPUnit** (recca0120.vscode-phpunit)
- **PHP CS Fixer** (junstyle.php-cs-fixer)
- **GitLens** (eamodio.gitlens)
- **Docker** (ms-azuretools.vscode-docker)

### Configuraciones
- Format on save activado con PHP CS Fixer (@Symfony rules)
- IntelliSense optimizado para PHP 8.2
- Asociaciones de archivos para Twig
- PHPUnit integrado

## Uso

```bash
./vsc-wslg dood up symfony
```

## Crear un proyecto nuevo

Una vez dentro del contenedor:

```bash
# Crear nuevo proyecto Symfony
symfony new mi-proyecto --webapp

# O con Composer
composer create-project symfony/skeleton:"6.4.*" mi-proyecto
cd mi-proyecto
composer require webapp
```

## Comandos útiles

```bash
# Servidor de desarrollo
symfony serve

# Instalar dependencias
composer install

# Ejecutar tests
php bin/phpunit
```
