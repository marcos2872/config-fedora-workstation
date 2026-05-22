#!/bin/bash
sudo dnf install -y gh
read -p "Digite seu nome para o Git (Enter para pular): " git_name
if [ -n "$git_name" ]; then
    read -p "Digite seu email para o Git: " git_email
    if [ -n "$git_email" ]; then
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        echo "Git configurado."
    fi
fi
