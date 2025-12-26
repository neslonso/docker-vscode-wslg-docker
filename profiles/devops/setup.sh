#!/bin/bash
# ============================================================================
# DevOps Profile - System Setup Script
# ============================================================================
# This script installs system-level tools needed for DevOps work.
# It runs once per profile (tracked by flag file).
#
# To re-run: docker compose down -v (removes volumes with flag)

set -e

echo "📦 Installing DevOps tools..."

# Update package lists
sudo apt-get update -qq

# ShellCheck - Shell script static analysis
echo "  → Installing ShellCheck..."
sudo apt-get install -y -qq shellcheck

# hadolint - Dockerfile linter (download binary)
# Made optional in case of network issues
echo "  → Installing hadolint..."
HADOLINT_VERSION="2.12.0"
if sudo curl -fsSL -o /usr/local/bin/hadolint \
    "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" 2>/dev/null; then
    sudo chmod +x /usr/local/bin/hadolint
    echo "     ✓ hadolint installed successfully"
else
    echo "     ⚠️  Could not download hadolint (network error), skipping..."
fi

# yamllint - YAML linter
echo "  → Installing yamllint..."
sudo apt-get install -y -qq yamllint

# ansible-lint - Ansible playbook linter (via pip)
echo "  → Installing ansible-lint..."
sudo apt-get install -y -qq python3-pip
# Use --break-system-packages since this is an isolated Docker container
sudo pip3 install --break-system-packages -q ansible-lint

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✅ DevOps tools installed successfully!"
echo ""
echo "Available tools:"
echo "  • shellcheck  - Shell script linter"
echo "  • hadolint    - Dockerfile linter"
echo "  • yamllint    - YAML linter"
echo "  • ansible-lint - Ansible playbook linter"
