# VSCode Profiles

## Concept

A **profile** is simply a VSCode configuration: extensions and specific settings for a type of development.

**Profiles do NOT include:**
- ❌ Orchestration scripts
- ❌ Docker compose for services
- ❌ Management commands
- ❌ Infrastructure configuration

**Profiles DO include:**
- ✅ VSCode extensions list
- ✅ Specific settings.json
- ✅ Usage documentation

## Profile Structure

```
profiles/profile-name/
├── README.md              # Profile documentation
└── vscode/
    ├── extensions.list    # List of extensions to install
    └── settings.json      # VSCode configuration
```

## Creating a New Profile

### 1. Create the structure

```bash
cd profiles
mkdir my-profile
mkdir my-profile/vscode
```

### 2. Create `vscode/extensions.list`

List of extensions, one per line:

```
# my-profile/vscode/extensions.list
ms-python.python
ms-python.vscode-pylance
ms-python.black-formatter
```

**How to find extension IDs:**
1. Open VSCode
2. Go to extensions
3. Right-click on an extension → "Copy Extension ID"

### 3. Create `vscode/settings.json`

Specific configuration for this profile:

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

**Note:** These settings are **merged** with user settings. Profile settings take priority.

### 4. Create `README.md`

Document:
- What the profile is for
- Which extensions it includes and why
- Usage tips
- Links to useful resources

## Using a Profile

```bash
cd ~/my-project
./vsc-wslg dood up my-profile
```

The profile:
1. Mounts at `/home/dev/vsc-wslg-my-profile-profile/` (read-only)
2. VSCode reads `vscode/extensions.list` and installs extensions
3. VSCode merges `vscode/settings.json` with your configuration
4. The README opens automatically on first execution

## Philosophy: Separation of Responsibilities

### Profile = Editor Configuration

The profile configures your **development environment in VSCode**:
- Syntax highlighting
- Linters
- Formatters
- Snippets
- Themes

### Project = Infrastructure

If you need services (databases, caches, etc.), put them in your **project's docker-compose.yml**:

```
~/my-project/
├── docker-compose.yml    # ← MySQL, Redis, etc.
├── src/
└── ...

# Usage:
./vsc-wslg dood up symfony  # VSCode with symfony profile
cd ~/my-project
docker compose up -d        # Project services
```

**Advantages:**
- ✅ Reuse the same profile for multiple projects
- ✅ Each project defines its own infrastructure
- ✅ Don't mix editor configuration with service orchestration
- ✅ Simplicity: a profile is just 2 files

## Included Profiles

### symfony
**For:** PHP/Symfony development
**Extensions:** PHP Intelephense, Symfony Support, Twig, Composer, etc.
**Settings:** PHP formatting, debug configuration

### rust
**For:** Rust development
**Extensions:** rust-analyzer, CodeLLDB, Dependi, TOML
**Settings:** Rust analyzer configuration, formatting

### devops
**For:** DevOps, IaC, Scripts
**Extensions:** Docker, Kubernetes, Terraform, Ansible, YAML, etc.
**Settings:** YAML indentation, shellcheck

## Tips

### Testing a Profile

Before using it in production, test your profile:

```bash
mkdir ~/test-profile
cd ~/test-profile
./vsc-wslg dood up my-profile
```

Verify that:
- ✓ Extensions install correctly
- ✓ Settings are applied
- ✓ No conflicts

### Sharing Profiles

Profiles are portable. Share the complete directory:

```bash
tar czf my-profile.tar.gz profiles/my-profile/
# Share my-profile.tar.gz
```

Another user:
```bash
cd vscode-wslg-docker
tar xzf my-profile.tar.gz -C profiles/
```

### Evolving a Profile

Profiles evolve. When you discover new useful extensions:

1. Edit `vscode/extensions.list`
2. Rebuild the container: `./vsc-wslg dood build`
3. Launch again: `./vsc-wslg dood up my-profile`

New extensions will be installed automatically.

## Troubleshooting

### Extensions don't install

**Cause:** Incorrect format in `extensions.list`

**Solution:**
- One extension per line
- No spaces before/after
- Exact IDs (case-sensitive)
- No inline comments (use separate lines for comments with #)

### Settings don't apply

**Cause:** Invalid JSON

**Solution:**
```bash
# Validate JSON
jq . profiles/my-profile/vscode/settings.json
```

### Profile doesn't mount

**Cause:** Environment variable not set

**Solution:** Make sure to specify the profile:
```bash
./vsc-wslg dood up my-profile  # ← required
```
