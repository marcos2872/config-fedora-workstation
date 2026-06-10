#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/marcos2872/agents-config"
BASE_DIR="${HOME}/Config"
REPO_DIR="${BASE_DIR}/agents-config"
CONFIG_MODE="${1:-all}"

log() {
  echo "[agents-config] $*"
}

die() {
  echo "[agents-config] ERRO: $*" >&2
  exit 1
}

ensure_command() {
  local command_name="$1"
  local package_name="${2:-$1}"

  if command -v "$command_name" >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    die "'$command_name' nao encontrado e 'pacman' nao esta disponivel para instalar '$package_name'."
  fi

  log "Instalando dependencia: ${package_name}"
  sudo pacman -S --needed --noconfirm "$package_name"
}

prepare_repo() {
  ensure_command git git
  ensure_command curl curl

  mkdir -p "$BASE_DIR"

  if [ -d "${REPO_DIR}/.git" ]; then
    log "Atualizando repositorio em ${REPO_DIR}"
    git -C "$REPO_DIR" pull --ff-only
    return 0
  fi

  if [ -e "$REPO_DIR" ]; then
    die "${REPO_DIR} ja existe, mas nao e um repositorio git. Remova ou mova esse diretorio antes de continuar."
  fi

  log "Clonando ${REPO_URL} em ${REPO_DIR}"
  git clone "$REPO_URL" "$REPO_DIR"
}

copy_config() {
  local source_path="$1"
  local target_path="$2"
  local backup_path
  local target_dir

  [ -e "$source_path" ] || die "Origem nao encontrada: ${source_path}"

  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_path="${target_path}.backup.$(date +%Y%m%d-%H%M%S)"
    log "Criando backup de ${target_path} em ${backup_path}"
    mv "$target_path" "$backup_path"
  fi

  log "Copiando: ${source_path} -> ${target_path}"
  cp -r "$source_path" "$target_path"
}

apply_zed_config() {
  log "Aplicando configuracao do Zed"
  copy_config "${REPO_DIR}/zed/settings.json" "${HOME}/.config/zed/settings.json"
  copy_config "${REPO_DIR}/zed/themes" "${HOME}/.config/zed/themes"
}

apply_zed_skills() {
  log "Aplicando skills globais do Zed Agent"
  copy_config "${REPO_DIR}/opencode/skills/code-conventions" "${HOME}/.agents/skills/code-conventions"
  copy_config "${REPO_DIR}/opencode/skills/doc" "${HOME}/.agents/skills/doc"
  copy_config "${REPO_DIR}/opencode/skills/excalidraw" "${HOME}/.agents/skills/excalidraw"
  copy_config "${REPO_DIR}/opencode/skills/git-commit-push" "${HOME}/.agents/skills/git-commit-push"
}

apply_zed_agents() {
  log "Aplicando agents globais do Zed Agent"
  copy_config "${REPO_DIR}/opencode/agents/ask.md" "${HOME}/.agents/agents/ask.md"
  copy_config "${REPO_DIR}/opencode/agents/geral.md" "${HOME}/.agents/agents/geral.md"
  copy_config "${REPO_DIR}/opencode/agents/qa.md" "${HOME}/.agents/agents/qa.md"
  copy_config "${REPO_DIR}/opencode/agents/quality.md" "${HOME}/.agents/agents/quality.md"
  copy_config "${REPO_DIR}/opencode/agents/test.md" "${HOME}/.agents/agents/test.md"
}

main() {
  case "$CONFIG_MODE" in
    all|zed) ;;
    *) die "Modo invalido: ${CONFIG_MODE}. Use: all ou zed." ;;
  esac

  prepare_repo

  apply_zed_config
  apply_zed_skills
  apply_zed_agents

  log "Configuracao aplicada com sucesso."
}

main "$@"
