#!/usr/bin/env bash
set -euo pipefail

# Instalador de configuracoes para CachyOS.
# O CachyOS ja traz Niri e Noctalia; este script aplica a config pessoal deste
# repositorio em ~/.config (com backup) e faz ajustes opcionais (brilho DDC/CI e
# tema do SDDM no estilo Noctalia, que instala a dependencia Qt6 necessaria).
# A config do Noctalia ja inclui o plugin Polkit Agent (noctalia-config/plugins).

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIRI_CONFIG_SOURCE="$PROJECT_DIR/niri-config"
NIRI_CONFIG_TARGET="$HOME/.config/niri"
NOCTALIA_CONFIG_SOURCE="$PROJECT_DIR/noctalia-config"
NOCTALIA_CONFIG_TARGET="$HOME/.config/noctalia"
WALLPAPER_SOURCE="$PROJECT_DIR/wallpapers"
WALLPAPER_TARGET="$HOME/Pictures/Wallpapers"
# Wallpaper a ser definido por padrao (arquivo dentro de wallpapers/).
DEFAULT_WALLPAPER="peakpx.jpg"
# Tema do SDDM no estilo Noctalia (Qt6).
SDDM_THEME_REPO="https://github.com/mahaveergurjar/sddm"
SDDM_THEME_BRANCH="noctalia"
SDDM_THEME_NAME="noctalia"
SDDM_THEME_DIR="/usr/share/sddm/themes/$SDDM_THEME_NAME"

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

install_sddm_theme() {
    command -v sddm >/dev/null 2>&1 || command -v sddm-greeter-qt6 >/dev/null 2>&1 \
        || { log "SDDM nao encontrado; pulando tema do SDDM"; return 0; }
    command -v git >/dev/null 2>&1 || { log "git nao encontrado; pulando tema do SDDM"; return 0; }

    log "Instalando tema Noctalia para o SDDM"

    # Dependencia Qt6 exigida pelo tema (QtGraphicalEffects via qt6-5compat).
    if command -v pacman >/dev/null 2>&1 && ! pacman -Qq qt6-5compat >/dev/null 2>&1; then
        log "Instalando dependencia do tema: qt6-5compat"
        sudo pacman -S --needed --noconfirm qt6-5compat
    fi

    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN

    GIT_TERMINAL_PROMPT=0 git clone -b "$SDDM_THEME_BRANCH" --depth 1 --quiet "$SDDM_THEME_REPO" "$temp_dir/theme"
    rm -rf "$temp_dir/theme/.git"

    sudo rm -rf "$SDDM_THEME_DIR"
    sudo mkdir -p /usr/share/sddm/themes
    sudo cp -r "$temp_dir/theme" "$SDDM_THEME_DIR"

    # Usa o wallpaper padrao como fundo do login, casando com a tela de bloqueio.
    local wallpaper="$WALLPAPER_TARGET/$DEFAULT_WALLPAPER"
    if [[ -f "$wallpaper" ]]; then
        sudo cp "$wallpaper" "$SDDM_THEME_DIR/Assets/background.jpg"
        sudo sed -i 's|^background=.*|background=Assets/background.jpg|' "$SDDM_THEME_DIR/theme.conf"
    fi

    # Ativa o tema sem alterar o /etc/sddm.conf existente.
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "$SDDM_THEME_NAME" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
}

main() {
    install_niri_config
    install_noctalia_config
    install_wallpapers
    set_default_wallpaper
    install_sddm_theme
    configure_external_monitor_brightness

    log "Configuracao aplicada"
    printf 'Reinicie a sessao Niri (ou rode: niri msg action load-config-file) para aplicar.\n'
    printf 'O tema do SDDM entra em vigor no proximo login (ou: sudo systemctl restart sddm).\n'
    printf 'Para brilho de monitor externo, saia e entre novamente para aplicar o grupo i2c.\n'
}

main "$@"
