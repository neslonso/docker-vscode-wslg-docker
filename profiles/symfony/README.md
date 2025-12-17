# Perfil Symfony

Entorno completo para desarrollo PHP con Symfony Framework.

## Características

### Infraestructura (servicios separados)
- **PHP 8.2-fpm**: PHP con Composer, Symfony CLI y extensiones necesarias
- **MySQL 8.0**: Base de datos principal
- **Redis 7**: Cache y gestor de sesiones

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

### Configuraciones VSCode
- Format on save activado con PHP CS Fixer (@Symfony rules)
- IntelliSense optimizado para PHP 8.2
- Asociaciones de archivos para Twig
- PHPUnit integrado

## Uso

### 1. Levantar VSCode
```bash
./vsc-wslg dood up symfony
```

### 2. Levantar infraestructura (desde VSCode)
```bash
# Desde el terminal integrado de VSCode
~/vsc-wslg-symfony-profile/manage start
```

### 3. Configurar proyecto Symfony
```bash
# Instalar dependencias
composer install

# Configurar .env
DATABASE_URL=mysql://symfony:secret@mysql:3306/symfony_db
REDIS_URL=redis://redis:6379

# Ejecutar migraciones
bin/console doctrine:migrations:migrate
```

## Gestión de infraestructura

```bash
# Levantar servicios
~/vsc-wslg-symfony-profile/manage start

# Detener servicios
~/vsc-wslg-symfony-profile/manage stop

# Reiniciar servicios
~/vsc-wslg-symfony-profile/manage restart

# Ver logs
~/vsc-wslg-symfony-profile/manage logs

# Ver estado
~/vsc-wslg-symfony-profile/manage status
```

## Crear un proyecto nuevo

```bash
# Con Symfony CLI
symfony new mi-proyecto --webapp

# O con Composer
composer create-project symfony/skeleton:"6.4.*" mi-proyecto
cd mi-proyecto
composer require webapp
```

## Conexión a servicios

### MySQL
```
Host: mysql (o localhost desde el host)
Port: 3306
Database: symfony_db
User: symfony
Password: secret
Root password: root
```

### Redis
```
Host: redis (o localhost desde el host)
Port: 6379
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

# Servidor de desarrollo (alternativo)
symfony serve

# Tests
php bin/phpunit
```
