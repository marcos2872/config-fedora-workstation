#!/bin/bash

# Função para pausar e mostrar erros (mantém o comportamento do script original)
pause_on_error() {
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERRO ENCONTRADO! Pressione ENTER para continuar..."
    read
  fi
}

# 1) Configurar posição do KRunner (centralizado e flutuante)
echo ""
echo "🧭 Configurando posição do KRunner (centralizado)..."
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file krunnerrc --group General --key Position Center
    kwriteconfig6 --file krunnerrc --group General --key FreeFloating true
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file krunnerrc --group General --key Position Center
    kwriteconfig5 --file krunnerrc --group General --key FreeFloating true
else
    # Fallback manual
    mkdir -p ~/.config
    if ! grep -q "\[General\]" ~/.config/krunnerrc 2>/dev/null; then
        echo "[General]" >> ~/.config/krunnerrc
    fi
    sed -i '/^Position=/d' ~/.config/krunnerrc 2>/dev/null
    sed -i '/^FreeFloating=/d' ~/.config/krunnerrc 2>/dev/null
    printf "Position=Center\nFreeFloating=true\n" >> ~/.config/krunnerrc
fi
pause_on_error
echo "🔄 Reiniciando KRunner para aplicar configurações..."
pkill krunner >/dev/null 2>&1 && krunner &>/dev/null &
echo "✅ KRunner configurado para posição central e modo flutuante!"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ CONFIGURAÇÃO CONCLUÍDA                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
