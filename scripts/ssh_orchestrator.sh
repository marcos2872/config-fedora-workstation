#!/bin/bash

# ==============================================================================
# SSH Orchestrator Installation Script
# Downloads and installs the latest RPM from GitHub Releases.
# Reference: https://github.com/marcos2872/SSH_Orchestrator/releases
# ==============================================================================

set -euo pipefail

REPO="marcos2872/SSH_Orchestrator"

echo "========================================================"
echo " Installing SSH Orchestrator"
echo "========================================================"
echo ""

# Function to handle errors
handle_error() {
    echo "Error occurred during installation. Exiting."
    exit 1
}

# Trap errors
trap handle_error ERR

# Check if already installed
if rpm -q ssh-orchestrator &> /dev/null; then
    INSTALLED_VER=$(rpm -q --qf '%{VERSION}' ssh-orchestrator)
    echo "SSH Orchestrator ${INSTALLED_VER} is already installed."
    echo "Checking for updates..."
fi

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo "curl is required but not installed. Please install curl first."
    exit 1
fi

# Fetch the latest release RPM URL from GitHub API
echo "Fetching latest release info from GitHub..."
RPM_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.rpm"' \
    | head -1 \
    | cut -d'"' -f4)

if [[ -z "${RPM_URL}" ]]; then
    echo "Could not find an RPM asset in the latest release."
    exit 1
fi

RPM_FILE=$(basename "${RPM_URL}")
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"; handle_error' ERR

echo "Downloading ${RPM_FILE}..."
curl -fSL -o "${TMPDIR}/${RPM_FILE}" "${RPM_URL}"

echo "Installing ${RPM_FILE}..."
sudo dnf install -y "${TMPDIR}/${RPM_FILE}"

rm -rf "${TMPDIR}"

echo ""
echo "========================================================"
echo " SSH Orchestrator Installation Complete"
echo "========================================================"
