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

link_config() {
  local source_path="$1"
  local target_path="$2"
  local backup_path
  local target_dir
  local current_target

  [ -e "$source_path" ] || die "Origem nao encontrada: ${source_path}"

  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path")"
    if [ "$current_target" = "$source_path" ]; then
      log "Symlink ja esta correto: ${target_path}"
      return 0
    fi

    log "Removendo symlink antigo: ${target_path} -> ${current_target}"
    rm "$target_path"
  elif [ -e "$target_path" ]; then
    backup_path="${target_path}.backup.$(date +%Y%m%d-%H%M%S)"
    log "Criando backup de ${target_path} em ${backup_path}"
    mv "$target_path" "$backup_path"
  fi

  log "Criando symlink: ${target_path} -> ${source_path}"
  ln -s "$source_path" "$target_path"
}

apply_zed_config() {
  log "Aplicando configuracao do Zed"
  link_config "${REPO_DIR}/zed/settings.json" "${HOME}/.config/zed/settings.json"
  link_config "${REPO_DIR}/zed/themes" "${HOME}/.config/zed/themes"
}

install_rtk() {
  local rtk_bin=""

  if command -v rtk >/dev/null 2>&1; then
    rtk_bin="$(command -v rtk)"
  elif [ -x "${HOME}/.local/bin/rtk" ]; then
    rtk_bin="${HOME}/.local/bin/rtk"
  else
    log "Instalando RTK"
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

    if command -v rtk >/dev/null 2>&1; then
      rtk_bin="$(command -v rtk)"
    elif [ -x "${HOME}/.local/bin/rtk" ]; then
      rtk_bin="${HOME}/.local/bin/rtk"
    else
      log "AVISO: RTK foi instalado, mas o binario nao foi encontrado. Verifique se ~/.local/bin esta no PATH."
      return 0
    fi
  fi

  log "Inicializando RTK para OpenCode"
  "$rtk_bin" init -g --opencode

  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) log "AVISO: ~/.local/bin nao esta no PATH atual. Adicione para usar rtk diretamente no terminal." ;;
  esac
}

fix_opencode_mem() {
  local log_file="${HOME}/.opencode-mem/opencode-mem.log"
  local package_dir="${HOME}/.cache/opencode/packages/opencode-mem@latest"

  if [ ! -f "$log_file" ]; then
    log "Log do opencode-mem ainda nao existe; nenhum fix aplicado."
    return 0
  fi

  if ! grep -Eq "Failed to initialize embedding model|sharp|Plugin warmup failed|Cannot find module '../build/Release/sharp-linux-x64.node'" "$log_file"; then
    log "Nenhum erro conhecido do opencode-mem detectado."
    return 0
  fi

  if [ ! -d "$package_dir" ]; then
    log "AVISO: pacote opencode-mem ainda nao esta em cache (${package_dir}); rode OpenCode uma vez e execute este script novamente."
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    log "AVISO: npm nao encontrado; fix do opencode-mem foi pulado. Execute scripts/node.sh e rode este script novamente."
    return 0
  fi

  log "Aplicando fix do opencode-mem para sharp"
  npm --prefix "$package_dir" install --ignore-scripts=false --foreground-scripts --platform=linux --arch=x64 sharp
}

apply_opencode_config() {
  log "Aplicando configuracao do OpenCode"
  link_config "${REPO_DIR}/opencode/agents" "${HOME}/.config/opencode/agents"
  link_config "${REPO_DIR}/opencode/skills" "${HOME}/.config/opencode/skills"
  link_config "${REPO_DIR}/opencode/plugins" "${HOME}/.config/opencode/plugins"
  link_config "${REPO_DIR}/opencode/opencode.json" "${HOME}/.config/opencode/opencode.json"
  link_config "${REPO_DIR}/opencode/opencode-mem.jsonc" "${HOME}/.config/opencode/opencode-mem.jsonc"

  install_rtk
  fix_opencode_mem
}

main() {
  case "$CONFIG_MODE" in
    all|zed|opencode) ;;
    *) die "Modo invalido: ${CONFIG_MODE}. Use: all, zed ou opencode." ;;
  esac

  prepare_repo

  case "$CONFIG_MODE" in
    all)
      apply_zed_config
      apply_opencode_config
      ;;
    zed)
      apply_zed_config
      ;;
    opencode)
      apply_opencode_config
      ;;
  esac

  log "Configuracao aplicada com sucesso."
}

main "$@"
