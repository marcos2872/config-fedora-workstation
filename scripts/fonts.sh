#!/bin/bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
echo "Baixando FiraCode..."
curl -fLo "FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip -o FiraCode.zip
rm FiraCode.zip
fc-cache -fv
cd - > /dev/null
