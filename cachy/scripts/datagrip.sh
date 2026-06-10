#!/bin/bash
set -euo pipefail

# Helper para instalar pacotes do AUR usando paru ou yay (CachyOS ja traz paru).
aur_install() {
    local helper=""
    if command -v paru >/dev/null 2>&1; then
        helper="paru"
    elif command -v yay >/dev/null 2>&1; then
        helper="yay"
    else
        echo "Nenhum helper AUR encontrado (paru/yay). Instale um deles e tente novamente." >&2
        exit 1
    fi
    "$helper" -S --needed --noconfirm "$@"
}

echo "Instalando DataGrip (AUR: datagrip)..."
aur_install datagrip
