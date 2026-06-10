#!/usr/bin/env bash
#
# Instalador idempotente para uv (Fedora)
#
# O script:
#  - Verifica se uv já está instalado.
#  - Instala uv via instalador oficial (standalone installer da Astral).
#  - Adiciona shell completion para bash em ~/.bashrc (somente se ainda não existir).
#
# uv substitui pyenv, pip, pip-tools, pipx, poetry, virtualenv e mais,
# sendo extremamente rápido (escrito em Rust).
#
# Comportamento:
#  - Idempotente: pode ser executado múltiplas vezes sem efeito colateral.
#  - Retorna 0 em sucesso.
#
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" 1>&2; }

is_installed() {
  if command -v uv >/dev/null 2>&1; then
    echo "$(command -v uv) ($(uv --version 2>/dev/null || echo 'versão desconhecida'))"
    return 0
  fi

  # O instalador padrão coloca o binário em ~/.local/bin
  if [ -x "$HOME/.local/bin/uv" ]; then
    echo "$HOME/.local/bin/uv"
    return 0
  fi

  return 1
}

append_if_missing() {
  local file="$1"
  local marker="$2"
  local content="$3"

  if [ ! -f "$file" ]; then
    touch "$file"
  fi

  if grep -Fq "$marker" "$file"; then
    info "Arquivo $file já contém a configuração do uv (marcador detectado). Pulando."
    return 0
  fi

  {
    echo ""
    echo "# >>> uv init ($marker) >>>"
    echo "$content"
    echo "# <<< uv init ($marker) <<<"
  } >> "$file"

  info "Adicionado bloco de inicialização do uv em $file"
}

main() {
  echo -e "\n${GREEN}=== Instalador: uv (Python package & project manager) ===${NC}"

  if installed_loc="$(is_installed)"; then
    info "uv já instalado: $installed_loc"
    info "Atualizando para a versão mais recente..."
    uv self update || warn "Falha ao atualizar uv. Continuando com a versão atual."
    return 0
  fi

  # Verificar se curl ou wget estão disponíveis
  if command -v curl >/dev/null 2>&1; then
    info "Instalando uv via instalador oficial (curl)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh || {
      err "Falha ao instalar uv via curl."
      return 1
    }
  elif command -v wget >/dev/null 2>&1; then
    info "Instalando uv via instalador oficial (wget)..."
    wget -qO- https://astral.sh/uv/install.sh | sh || {
      err "Falha ao instalar uv via wget."
      return 1
    }
  else
    err "Nem curl nem wget foram encontrados. Instale um deles e execute o script novamente."
    return 1
  fi

  # Garantir que ~/.local/bin esteja no PATH para os comandos seguintes
  export PATH="$HOME/.local/bin:$PATH"

  # Verificar se a instalação foi bem-sucedida
  if ! command -v uv >/dev/null 2>&1; then
    err "uv não encontrado após instalação. Verifique se ~/.local/bin está no PATH."
    return 1
  fi

  info "uv instalado com sucesso: $(uv --version)"

  # Adicionar shell completion para bash
  read -r -d '' BASH_SNIPPET <<'EOF' || true
# uv shell completion
eval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"
EOF

  append_if_missing "$HOME/.bashrc" "uv-completion-bashrc" "$BASH_SNIPPET"

  info "uv instalado e configurado."
  info "Para completar: abra um novo terminal ou execute 'source ~/.bashrc'."
  info ""
  info "Comandos úteis:"
  info "  uv python install 3.12    - Instalar uma versão do Python"
  info "  uv python pin 3.12        - Fixar versão do Python no diretório atual"
  info "  uv init meu-projeto       - Criar um novo projeto Python"
  info "  uv add requests           - Adicionar dependência ao projeto"
  info "  uv run script.py          - Executar script com dependências gerenciadas"
  info "  uvx ruff check .          - Executar ferramenta Python sem instalar globalmente"
  return 0
}

main "$@"
