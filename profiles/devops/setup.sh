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

# hadolint - Dockerfile linter (via wget since it's a binary)
echo "  → Installing hadolint..."
HADOLINT_VERSION="2.12.0"
sudo wget -qO /usr/local/bin/hadolint \
    "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64"
sudo chmod +x /usr/local/bin/hadolint

# yamllint - YAML linter
echo "  → Installing yamllint..."
sudo apt-get install -y -qq yamllint

# ansible-lint - Ansible playbook linter (via pip)
echo "  → Installing ansible-lint..."
sudo apt-get install -y -qq python3-pip
sudo pip3 install -q ansible-lint

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
