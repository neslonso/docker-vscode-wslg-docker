# VSCode WSLg Container

Containerized VSCode with GUI support via WSLg, designed for isolated development environments with Docker support.

## Features

- **GUI via WSLg** - Full graphical VSCode running in Docker on WSL2
- **Two Docker modes** - Docker-in-Docker (DinD) or Docker-out-of-Docker (DooD)
- **Profile system** - Pre-configured development environments with customizable tools and extensions
- **Dynamic workspace mounting** - Project directory mounted at `/<directory-name>`
- **Persistent containers** - Installed tools and state preserved between sessions for fast startup
- **Single-instance handling** - Automatically detects and manages running instances

## Requirements

- Windows 11 with WSL2 and WSLg enabled
- Docker installed in WSL2
- At least 4GB RAM available

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-vscode-wslg-docker.git
cd docker-vscode-wslg-docker

# See available profiles
./vsc-wslg info

# Navigate to your project directory
cd ~/my-project

# Launch VSCode with a profile (DinD mode by default)
/path/to/vsc-wslg up <profile>

# Or with DooD mode
/path/to/vsc-wslg up <profile> dood
```

## Docker Modes

### DinD (Docker-in-Docker) - Default
- Runs Docker daemon inside the container
- Fully isolated from host Docker
- Requires `privileged` mode
- Persistent storage for Docker data

### DooD (Docker-out-of-Docker)
- Uses host's Docker daemon via socket mount
- Shares Docker images/containers with host
- No `privileged` mode needed
- Container commands affect host Docker

## Usage

```bash
vsc-wslg <action> [profile] [mode]
vsc-wslg build [mode]
```

### Actions
- `info` - List available profiles or show profile details
- `up` - Launch VSCode (foreground, stops on close - preserves installed tools)
- `upd` - Launch VSCode (background daemon)
- `upd-logs` - Launch VSCode (background + follow logs)
- `build` - Rebuild Docker image for specified mode (dind/dood)
- `down` - Remove container (destroys state - use to reset/update)
- `clean` - Remove container and volumes (full cleanup)

### Examples

```bash
# List available profiles
vsc-wslg info

# Show details about a specific profile
vsc-wslg info python

# Launch a profile in DinD (default)
vsc-wslg up python

# Launch a profile in DooD mode
vsc-wslg up rust dood

# Launch without profile (just workspace + Docker)
vsc-wslg up

# Rebuild DinD image (default)
vsc-wslg build

# Rebuild DooD image
vsc-wslg build dood

# Stop running container
vsc-wslg down

# Clean up (removes volumes)
vsc-wslg clean
```

## Project Structure

```
.
├── vsc-wslg              # Main launcher script
├── docker/               # Docker configuration
│   ├── Dockerfile.base   # Unified Dockerfile
│   ├── entrypoint.sh     # Unified entrypoint
│   ├── docker-compose.yml       # Base compose config
│   ├── docker-compose.dind.yml  # DinD overrides
│   ├── docker-compose.dood.yml  # DooD overrides
│   └── lib/
│       ├── docker-setup.sh      # Docker daemon functions
│       └── vscode-setup.sh      # VSCode setup functions
└── profiles/             # VSCode profiles
    ├── devops/
    ├── rust/
    └── symfony/
        ├── setup.sh              # System packages installation
        ├── README.md             # Profile documentation
        └── vscode/
            ├── extensions.list   # VSCode extensions
            └── settings.json     # VSCode settings
```

## How It Works

1. **Workspace Mounting** - Your current directory is mounted at `/<directory-name>` inside the container
2. **Profile Loading** - Selected profile's extensions and settings are applied
3. **System Setup** - Profile's `setup.sh` runs once to install system tools (shellcheck, hadolint, etc.)
4. **VSCode Launch** - VSCode GUI appears via WSLg
5. **Monitoring** - Container stays alive while VSCode is running
6. **Cleanup** - Container stops when VSCode closes (in `up` mode)

## Creating Custom Profiles

1. Create a new directory in `profiles/`
2. Add `vscode/extensions.list` with extension IDs
3. Add `vscode/settings.json` with VSCode settings
4. Optionally add `setup.sh` for system package installation
5. Add `README.md` documenting the profile

Example `setup.sh`:
```bash
#!/bin/bash
set -e

echo "📦 Installing tools..."
sudo apt-get update -qq
sudo apt-get install -y -qq your-package
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
```

## Advanced Configuration

### Multiple Instances
The script detects running instances and prompts you to:
1. Cancel and keep existing instance
2. Close existing and launch new one

### Persistent Volumes
- `vscode-extensions` - VSCode extensions
- `vscode-config` - VSCode settings and state
- `dind-data` - Docker data (DinD mode only)

### Container Persistence

When you use `up`, the container stops but is **not removed**:
- ✅ **First launch**: Profile setup installs tools (Rust, Python, etc.) - may take 5-15 minutes
- ✅ **Subsequent launches**: Container reuses installed tools - starts in ~5-10 seconds
- ✅ **Preserved**: All installed tools, bash history, terminal state
- ✅ **Volumes**: Extensions and settings always persist

To **reset/update** the container (removes installed tools):
```bash
vsc-wslg down       # Removes container, preserves volumes (extensions/settings)
vsc-wslg clean      # Removes container + volumes (full reset)
```

This means:
- **Daily workflow**: Use `up` repeatedly - fast startup with all tools intact
- **After updates**: Use `down` then `up` to rebuild container with new image
- **Fresh start**: Use `clean` to completely reset everything

### Environment Variables
- `WORKSPACE_PATH` - Workspace mount point inside container
- `VSCODE_EXTENSIONS_PROFILE` - Active profile name
- `PROJECT_DIR` - Host project directory
- `WORKSPACE_NAME` - Directory name (for mount path)

## Troubleshooting

### VSCode doesn't appear
- Check WSLg is enabled: `wslg.exe`
- Verify DISPLAY variable: `echo $DISPLAY`
- Check container logs: `docker logs <container-name>`

### Profile setup fails
- Network issues: Check internet connectivity
- Permission errors: Verify `setup.sh` is executable

### Docker-in-Docker issues
- Requires privileged mode (security consideration)
- May conflict with host Docker socket

### Extensions don't install
- Clear extension cache: `vsc-wslg clean`
- Check profile's `extensions.list` syntax

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please ensure:
- Code follows existing patterns
- Scripts are shellcheck-compliant
- Documentation is updated
