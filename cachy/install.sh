#!/usr/bin/env bash
set -euo pipefail

# Instalador de configuracoes para CachyOS.
# O CachyOS ja traz Niri e Noctalia; este script apenas aplica a config pessoal
# deste repositorio em ~/.config (com backup) e ajustes opcionais.

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIRI_CONFIG_SOURCE="$PROJECT_DIR/niri-config"
NIRI_CONFIG_TARGET="$HOME/.config/niri"
NOCTALIA_CONFIG_SOURCE="$PROJECT_DIR/noctalia-config"
NOCTALIA_CONFIG_TARGET="$HOME/.config/noctalia"
WALLPAPER_SOURCE="$PROJECT_DIR/wallpapers"
WALLPAPER_TARGET="$HOME/Pictures/Wallpapers"
# Wallpaper a ser definido por padrao (arquivo dentro de wallpapers/).
DEFAULT_WALLPAPER="peakpx.jpg"

log() {
    printf '\n==> %s\n' "$1"
}

die() {
    printf 'Erro: %s\n' "$1" >&2
    exit 1
}

backup_existing() {
    local target="$1"
    if [[ -e "$target" ]]; then
        local backup_path
        backup_path="$target.backup.$(date +%Y%m%d-%H%M%S)"
        log "Criando backup da configuracao atual em $backup_path"
        cp -a "$target" "$backup_path"
    fi
}

install_niri_config() {
    [[ -d "$NIRI_CONFIG_SOURCE" ]] || die "configuracao local nao encontrada em $NIRI_CONFIG_SOURCE."

    mkdir -p "$HOME/.config"
    backup_existing "$NIRI_CONFIG_TARGET"

    log "Copiando configuracao do Niri deste projeto"
    mkdir -p "$NIRI_CONFIG_TARGET"
    cp -a "$NIRI_CONFIG_SOURCE/." "$NIRI_CONFIG_TARGET/"
}

install_noctalia_config() {
    [[ -d "$NOCTALIA_CONFIG_SOURCE" ]] || return 0

    mkdir -p "$HOME/.config"
    backup_existing "$NOCTALIA_CONFIG_TARGET"

    log "Copiando configuracao do Noctalia deste projeto"
    mkdir -p "$NOCTALIA_CONFIG_TARGET"
    cp -a "$NOCTALIA_CONFIG_SOURCE/." "$NOCTALIA_CONFIG_TARGET/"
}

install_noctalia_polkit_plugin() {
    command -v git >/dev/null 2>&1 || { log "git nao encontrado; pulando plugin Polkit do Noctalia"; return 0; }

    local plugin_id="polkit-agent"
    local plugin_repo="https://github.com/noctalia-dev/noctalia-plugins"
    local plugin_target="$NOCTALIA_CONFIG_TARGET/plugins/$plugin_id"
    local temp_dir

    log "Instalando plugin Polkit Agent do Noctalia"
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    GIT_TERMINAL_PROMPT=0 git clone --filter=blob:none --sparse --depth=1 --quiet "$plugin_repo" "$temp_dir"
    git -C "$temp_dir" sparse-checkout set "$plugin_id" >/dev/null

    rm -rf "$plugin_target"
    mkdir -p "$plugin_target"
    cp -a "$temp_dir/$plugin_id/." "$plugin_target/"
    rm -f "$plugin_target/settings.json"
}

install_wallpapers() {
    [[ -d "$WALLPAPER_SOURCE" ]] || return 0
    if ! find "$WALLPAPER_SOURCE" -type f ! -name 'README*' ! -name '.gitkeep' | grep -q .; then
        return 0
    fi

    log "Copiando wallpapers para $WALLPAPER_TARGET"
    mkdir -p "$WALLPAPER_TARGET"
    find "$WALLPAPER_SOURCE" -type f ! -name 'README*' ! -name '.gitkeep' -exec cp -a {} "$WALLPAPER_TARGET/" ';'
}

set_default_wallpaper() {
    local wallpaper="$WALLPAPER_TARGET/$DEFAULT_WALLPAPER"
    [[ -f "$wallpaper" ]] || { log "Wallpaper padrao nao encontrado ($wallpaper); pulando"; return 0; }
    command -v qs >/dev/null 2>&1 || { log "Quickshell (qs) nao encontrado; pulando definicao do wallpaper"; return 0; }

    log "Definindo wallpaper padrao: $DEFAULT_WALLPAPER"
    qs -c noctalia-shell ipc call wallpaper set "$wallpaper" >/dev/null 2>&1 \
        || log "Noctalia nao esta em execucao agora; o wallpaper sera usado a partir do diretorio configurado."
}

configure_external_monitor_brightness() {
    command -v ddcutil >/dev/null 2>&1 || { log "ddcutil nao encontrado; pulando ajuste de brilho via DDC/CI"; return 0; }

    log "Configurando controle de brilho para monitores externos via DDC/CI"

    sudo modprobe i2c-dev
    printf 'i2c-dev\n' | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null

    if ! getent group i2c >/dev/null 2>&1; then
        sudo groupadd --system i2c
    fi

    sudo usermod -aG i2c "$USER"

    sudo tee /etc/udev/rules.d/45-i2c-tools.rules >/dev/null <<'EOF'
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
EOF

    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=i2c-dev || true
}

main() {
    install_niri_config
    install_noctalia_config
    install_noctalia_polkit_plugin
    install_wallpapers
    set_default_wallpaper
    configure_external_monitor_brightness

    log "Configuracao aplicada"
    printf 'Reinicie a sessao Niri (ou rode: niri msg action load-config-file) para aplicar.\n'
    printf 'Para brilho de monitor externo, saia e entre novamente para aplicar o grupo i2c.\n'
}

main "$@"
