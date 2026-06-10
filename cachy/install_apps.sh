#!/bin/bash

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$0")/scripts"

# Garantir que scripts são executáveis
chmod +x "$SCRIPT_DIR"/*.sh

run_script() {
    local script_name=$1
    local description=$2

    echo -e "\n${GREEN}=== $description ===${NC}"
    "$SCRIPT_DIR/$script_name"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao executar $script_name. Pressione ENTER para continuar ou Ctrl+C para abortar.${NC}"
        read
    fi
}

echo -e "${GREEN}Iniciando instalação modular (CachyOS)...${NC}"

run_script "dev_tools.sh" "Instalando Development Tools"
run_script "rust.sh" "Instalando Rust"
run_script "uv.sh" "Instalando uv (Python package & project manager)"
run_script "node.sh" "Instalando Node (NVM)"
run_script "flatpak.sh" "Instalando Flatpak"
run_script "fonts.sh" "Instalando Fonts"
run_script "zed.sh" "Instalando Zed"
run_script "docker.sh" "Instalando Docker e Lazydocker"
run_script "brave.sh" "Instalando Brave Browser"
run_script "chrome.sh" "Instalando Google Chrome"
run_script "git_gh.sh" "Configurando Git e GH"
run_script "copilot.sh" "Instalando GitHub Copilot"

echo -e "\n${GREEN}=== Instalação Completa! ===${NC}"
echo "Por favor, reinicie sua sessão."
