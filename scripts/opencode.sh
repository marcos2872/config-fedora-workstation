#!/bin/bash

# ==============================================================================
# OpenCode CLI Installation Script
# This script installs OpenCode CLI using the official installer.
# Reference: https://opencode.ai/docs/pt-br/#instala%C3%A7%C3%A3o
# ==============================================================================

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Installing OpenCode CLI                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to handle errors
handle_error() {
    echo "❌ Error occurred during installation. Exiting."
    exit 1
}

# Trap errors
trap handle_error ERR

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed. Please install curl first."
    exit 1
fi

# Check if gh CLI is already installed with opencode extension
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "opencode"; then
    echo "✅ OpenCode CLI extension is already installed."
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ ✅ OpenCode CLI Installation Complete                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "You can use it with: gh opencode"
    exit 0
fi

# Run the official OpenCode installer
echo "📦 Running the official OpenCode CLI installer..."
curl -fsSL https://opencode.ai/install | bash

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ OpenCode CLI Installation Complete                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "You can use OpenCode CLI with: opencode"
