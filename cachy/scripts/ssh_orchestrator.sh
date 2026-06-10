#!/bin/bash

# ==============================================================================
# SSH Orchestrator Installation Script (CachyOS / Arch)
# Nao ha pacote nativo Arch nem .rpm utilizavel: o projeto publica apenas
# .rpm e .deb. Aqui baixamos o .deb da ultima release e extraimos os arquivos
# para o sistema com bsdtar (libarchive).
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

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo "curl is required but not installed. Please install curl first."
    exit 1
fi

if ! command -v bsdtar &> /dev/null; then
    echo "bsdtar (libarchive) is required. Installing..."
    sudo pacman -S --needed --noconfirm libarchive
fi

# Fetch the latest release .deb URL from GitHub API
echo "Fetching latest release info from GitHub..."
DEB_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.deb"' \
    | head -1 \
    | cut -d'"' -f4)

if [[ -z "${DEB_URL}" ]]; then
    echo "Could not find a .deb asset in the latest release."
    exit 1
fi

DEB_FILE=$(basename "${DEB_URL}")
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"; handle_error' ERR

echo "Downloading ${DEB_FILE}..."
curl -fSL -o "${TMPDIR}/${DEB_FILE}" "${DEB_URL}"

echo "Extracting package payload..."
# O .deb e um arquivo 'ar' contendo data.tar.{gz,xz,zst}; bsdtar le ambos.
bsdtar -xf "${TMPDIR}/${DEB_FILE}" -C "${TMPDIR}"

DATA_ARCHIVE=$(find "${TMPDIR}" -maxdepth 1 -name 'data.tar.*' | head -1)
if [[ -z "${DATA_ARCHIVE}" ]]; then
    echo "Could not find data archive inside the .deb."
    exit 1
fi

echo "Installing files into / (requer sudo)..."
sudo bsdtar -xpf "${DATA_ARCHIVE}" -C /

rm -rf "${TMPDIR}"

echo ""
echo "========================================================"
echo " SSH Orchestrator Installation Complete"
echo "========================================================"
echo "Observacao: instalado fora do gerenciador de pacotes (pacman)."
echo "Para atualizar, rode este script novamente."
