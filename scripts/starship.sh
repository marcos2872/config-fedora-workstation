#!/usr/bin/env bash
set -euo pipefail

curl -sS https://starship.rs/install.sh | sh -s -- -y

sudo dnf install -y git make gawk

mkdir -p ~/.local/share/bash-completion/completions
starship completions bash > ~/.local/share/bash-completion/completions/starship

if [[ ! -d ~/.local/share/blesh/.git ]]; then
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh
else
    git -C ~/.local/share/blesh pull --ff-only
fi

make -C ~/.local/share/blesh install PREFIX=~/.local

touch ~/.blerc
if ! grep -Fq '# ble.sh autosuggestion style' ~/.blerc; then
    cat >> ~/.blerc <<'EOF'

# ble.sh autosuggestion style
ble-face auto_complete='fg=250'
bleopt complete_auto_complete_opts='syntax-disabled'
bleopt complete_auto_menu=
EOF
fi

if ! grep -Fq 'eval "$(starship init bash)"' ~/.bashrc; then
    printf '\n# Starship prompt\neval "$(starship init bash)"\n' >> ~/.bashrc
fi

if ! grep -Fq 'bash-completion/completions' ~/.bashrc; then
    cat >> ~/.bashrc <<'EOF'

# User bash completions
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
    for completion in "$HOME"/.local/share/bash-completion/completions/*; do
        [ -r "$completion" ] && source "$completion"
    done
fi
EOF
fi

if ! grep -Fq 'ble.sh' ~/.bashrc; then
    cat >> ~/.bashrc <<'EOF'

# Bash line editor with autosuggestions
[[ $- == *i* ]] && source "$HOME/.local/share/blesh/ble.sh"
EOF
fi

printf 'Starship e autosuggestions instalados. Abra um novo terminal para carregar tudo.\n'
