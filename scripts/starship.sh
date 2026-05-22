#!/usr/bin/env bash
set -euo pipefail

curl -sS https://starship.rs/install.sh | sh -s -- -y

mkdir -p ~/.local/share/bash-completion/completions
starship completions bash > ~/.local/share/bash-completion/completions/starship

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

printf 'Starship instalado. Abra um novo terminal para carregar o prompt e autocomplete.\n'
