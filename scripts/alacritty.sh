#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Configurando Alacritty                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Função para pausar em caso de erro
pause_on_error() {
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERRO ENCONTRADO! Pressione ENTER para continuar..."
    read
  fi
}

# 1. Instalar dependências (git e fonte Fira Code como substituta da Menlo)
echo "📦 Instalando dependências..."
sudo dnf install -y alacritty 2>&1
pause_on_error
echo "✅ Dependências instaladas!"
echo ""

# 2. Criar pasta de configuração do Alacritty
echo "📁 Preparando ~/.config/alacritty..."
mkdir -p ~/.config/alacritty
pause_on_error

# 3. Clonar repositório de temas do Alacritty
if [ -d ~/.config/alacritty/themes ]; then
  echo "🗑️ Removendo temas antigos em ~/.config/alacritty/themes..."
  rm -rf ~/.config/alacritty/themes
fi

echo "🎨 Baixando temas para o Alacritty..."
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes 2>&1
pause_on_error
echo "✅ Temas baixados!"
echo ""

# 4. Criar/atualizar o arquivo alacritty.toml com visual estilo vscode
ALACRITTY_CONF=~/.config/alacritty/alacritty.toml

echo "📝 Escrevendo configuração em $ALACRITTY_CONF ..."
cat > "$ALACRITTY_CONF" << 'EOF'
[general]
# Importa o tema terminal_app (cores parecidas com o Terminal.app)
import = ["~/.config/alacritty/themes/themes/vscode.toml"]

[env]
TERM = "xterm-256color"

[window]
padding = { x = 2, y = 2 }
decorations = "full"
opacity = 0.95
# Se o Alacritty suportar, você pode testar:
# blur = true

[scrolling]
history = 10000

[cursor]
style = { shape = "Block", blinking = "On" }

[keyboard]
# Atalhos semelhantes ao macOS (Command = Meta/Alt no KDE)
bindings = [
  { key = "C", mods = "Alt", action = "Copy" },
  { key = "V", mods = "Alt", action = "Paste" },
  { key = "N", mods = "Alt", action = "CreateNewWindow" },
  { key = "W", mods = "Alt", action = "Quit" }
]
EOF
pause_on_error

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ CONFIGURAÇÃO DO ALACRITTY CONCLUÍDA!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Feche e abra o Alacritty."
echo "2. Se tiver a fonte Menlo instalada, ela será usada; senão, use o Fira Code nas configs gráficas do sistema."
echo "3. Ajuste tamanho da fonte, padding ou opacidade editando ~/.config/alacritty/alacritty.toml."
echo ""
echo "Pressione ENTER para fechar..."
