#!/bin/bash
set -euo pipefail

if command -v yay >/dev/null 2>&1; then
    echo "[yay] yay ja esta instalado."
    exit 0
fi

# CachyOS disponibiliza o yay em seus repositorios.
if sudo pacman -S --needed --noconfirm yay 2>/dev/null; then
    echo "[yay] Instalado via pacman."
    exit 0
fi

echo "[yay] Nao encontrado nos repositorios; compilando a partir do AUR..."
sudo pacman -S --needed --noconfirm git base-devel

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
( cd "$build_dir/yay" && makepkg -si --noconfirm )

echo "[yay] Instalado com sucesso a partir do AUR."
