# Profiles

Each subdirectory is a self-contained profile that adds language/framework
tooling on top of the base image.

## Directory structure

```
profiles/<name>/
├── setup.sh               # System packages and CLI tools (runs once)
├── vscode/
│   ├── extensions.list    # One extension ID per line
│   └── settings.json      # VSCode settings (merged with base)
└── README.md              # User-facing documentation
```

## Shell environment convention

The base `.bashrc` has this load order:

```
aliases / options
  ↓
fzf
  ↓
starship
  ↓
source ~/.bashrc_profile      ← profile additions go here
  ↓
zoxide init  (MUST be last)
```

### Rules for setup scripts

1. **NEVER append to `~/.bashrc` directly.**
   Many installers (pnpm, nvm, rustup, conda, sdkman …) automatically add
   PATH/env lines to `~/.bashrc`. If they do, **remove** those lines and
   write them to `~/.bashrc_profile` instead.

2. **`~/.bashrc_profile`** is the right place for any PATH exports,
   environment variables, or `eval "$(tool init bash)"` lines that a profile
   needs to add at shell startup.

3. **Why:** `zoxide init bash` must be the last thing evaluated in `.bashrc`
   (see [zoxide docs](https://github.com/ajeetdsouza/zoxide#installation)).
   Anything appended after it breaks zoxide's `cd` override.

### Example: installer that modifies .bashrc

```bash
# Install the tool (it will append to .bashrc)
curl -fsSL https://get.example.io/install.sh | sh -

# Clean up what the installer added to .bashrc
sed -i '/# example-start$/,/# example-end$/d' ~/.bashrc

# Write the config to .bashrc_profile instead
cat >> ~/.bashrc_profile << 'EOF'
export EXAMPLE_HOME="$HOME/.example"
export PATH="$EXAMPLE_HOME/bin:$PATH"
EOF
```

### Example: manual PATH addition

```bash
# No cleanup needed — just write directly
cat >> ~/.bashrc_profile << 'EOF'
export PATH="/opt/my-tool/bin:$PATH"
EOF
```

### Persistence

Both `~/.bashrc` and `~/.bashrc_profile` are symlinked to the
`~/.shell_persist/` volume by the entrypoint, so changes survive container
recreations (`docker compose down && docker compose up`).
To reset everything: `docker compose down -v` (removes volumes).
