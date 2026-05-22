#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NIRI_CONFIG_SOURCE="$PROJECT_DIR/niri-config"
NIRI_CONFIG_TARGET="$HOME/.config/niri"
NOCTALIA_CONFIG_SOURCE="$PROJECT_DIR/noctalia-config"
NOCTALIA_CONFIG_TARGET="$HOME/.config/noctalia"

log() {
    printf '\n==> %s\n' "$1"
}

die() {
    printf 'Erro: %s\n' "$1" >&2
    exit 1
}

require_fedora() {
    [[ -r /etc/fedora-release ]] || die "este instalador foi feito para Fedora Workstation."
    command -v dnf >/dev/null 2>&1 || die "dnf nao encontrado."
}

enable_repositories() {
    log "Instalando suporte a repositorios extras"
    sudo dnf install -y dnf-plugins-core curl gnupg2

    log "Habilitando COPR do Niri"
    sudo dnf copr enable -y yalter/niri

    if rpm -q terra-release >/dev/null 2>&1 || sudo test -f /etc/yum.repos.d/terra.repo; then
        log "Repositorio Terra ja esta habilitado"
    else
        log "Habilitando repositorio Terra para Noctalia"
        sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
    fi
}

install_packages() {
    log "Instalando Niri, Noctalia e dependencias"
    sudo dnf install -y \
        niri \
        xwayland-satellite \
        xdg-desktop-portal \
        xdg-desktop-portal-gnome \
        xdg-desktop-portal-gtk \
        noctalia-shell \
        brightnessctl \
        ImageMagick \
        python3 \
        git \
        cliphist \
        wlsunset \
        ddcutil \
        i2c-tools \
        NetworkManager \
        upower \
        bluez \
        alacritty \
        fuzzel
}

install_niri_config() {
    [[ -d "$NIRI_CONFIG_SOURCE" ]] || die "configuracao local nao encontrada em $NIRI_CONFIG_SOURCE."

    mkdir -p "$HOME/.config"

    if [[ -e "$NIRI_CONFIG_TARGET" ]]; then
        local backup_path
        backup_path="$NIRI_CONFIG_TARGET.backup.$(date +%Y%m%d-%H%M%S)"
        log "Criando backup da configuracao atual em $backup_path"
        cp -a "$NIRI_CONFIG_TARGET" "$backup_path"
    fi

    log "Copiando configuracao do Niri deste projeto"
    mkdir -p "$NIRI_CONFIG_TARGET"
    cp -a "$NIRI_CONFIG_SOURCE/." "$NIRI_CONFIG_TARGET/"
}

install_noctalia_config() {
    [[ -d "$NOCTALIA_CONFIG_SOURCE" ]] || return 0

    mkdir -p "$HOME/.config"

    if [[ -e "$NOCTALIA_CONFIG_TARGET" ]]; then
        local backup_path
        backup_path="$NOCTALIA_CONFIG_TARGET.backup.$(date +%Y%m%d-%H%M%S)"
        log "Criando backup da configuracao atual do Noctalia em $backup_path"
        cp -a "$NOCTALIA_CONFIG_TARGET" "$backup_path"
    fi

    log "Copiando configuracao do Noctalia deste projeto"
    mkdir -p "$NOCTALIA_CONFIG_TARGET"
    cp -a "$NOCTALIA_CONFIG_SOURCE/." "$NOCTALIA_CONFIG_TARGET/"
}

configure_external_monitor_brightness() {
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

set_gdm_default_session() {
    local session_name="niri"
    local accounts_file="/var/lib/AccountsService/users/$USER"

    if [[ ! -f "/usr/share/wayland-sessions/${session_name}.desktop" ]]; then
        die "sessao ${session_name}.desktop nao encontrada em /usr/share/wayland-sessions."
    fi

    log "Definindo Niri como sessao padrao no GDM para $USER"
    sudo mkdir -p /var/lib/AccountsService/users

    if [[ -f "$accounts_file" ]]; then
        sudo cp -a "$accounts_file" "$accounts_file.backup.$(date +%Y%m%d-%H%M%S)"
        if sudo grep -q '^Session=' "$accounts_file"; then
            sudo sed -i "s/^Session=.*/Session=${session_name}/" "$accounts_file"
        else
            printf 'Session=%s\n' "$session_name" | sudo tee -a "$accounts_file" >/dev/null
        fi

        if sudo grep -q '^XSession=' "$accounts_file"; then
            sudo sed -i "s/^XSession=.*/XSession=${session_name}/" "$accounts_file"
        else
            printf 'XSession=%s\n' "$session_name" | sudo tee -a "$accounts_file" >/dev/null
        fi
    else
        printf '[User]\nSession=%s\nXSession=%s\n' "$session_name" "$session_name" | sudo tee "$accounts_file" >/dev/null
    fi

    sudo chown root:root "$accounts_file"
    sudo chmod 0600 "$accounts_file"
}

main() {
    require_fedora
    enable_repositories
    install_packages
    install_niri_config
    install_noctalia_config
    configure_external_monitor_brightness
    set_gdm_default_session

    log "Instalacao concluida"
    printf 'Reinicie a sessao; o GDM deve entrar em Niri por padrao para este usuario.\n'
    printf 'Para brilho de monitor externo, saia e entre novamente para aplicar o grupo i2c.\n'
    printf 'Se estiver em TTY, inicie com: niri-session\n'
}

main "$@"
