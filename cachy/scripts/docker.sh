#!/bin/bash
set -euo pipefail

echo "Instalando Docker, docker-compose e Lazydocker..."
sudo pacman -S --needed --noconfirm docker docker-compose lazydocker

echo "Habilitando e iniciando o serviço do Docker..."
sudo systemctl enable --now docker.service

echo "Adicionando $USER ao grupo docker..."
sudo usermod -aG docker "$USER"

# Alias util para o lazydocker
if ! grep -q "alias lazy=" ~/.bashrc; then
    echo "alias lazy='lazydocker'" >> ~/.bashrc
fi

echo ""
echo "Docker instalado. Saia e entre novamente na sessão (ou rode 'newgrp docker')"
echo "para usar o Docker sem sudo."
