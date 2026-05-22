# Config Fedora Workstation

Configuracoes e scripts pessoais para preparar um Fedora Workstation com Niri, Noctalia e ferramentas de desenvolvimento.

Este repositorio inclui:

- Configuracao do Niri em `niri-config/`
- Configuracao do Noctalia em `noctalia-config/`
- Instalador principal em `install.sh`
- Scripts modulares de apps e ferramentas em `scripts/`
- Instalador modular de apps em `install_apps.sh`

## Requisitos

- Fedora Workstation
- Usuario com permissao de `sudo`
- Conexao com a internet

## Instalar Niri e Noctalia

Execute:

```bash
./install.sh
```

Esse script faz:

- Habilita o COPR do Niri
- Habilita o repositorio Terra para Noctalia
- Instala Niri, Noctalia e dependencias principais
- Copia `niri-config/` para `~/.config/niri`
- Copia `noctalia-config/` para `~/.config/noctalia`
- Define Niri como sessao padrao no GDM
- Configura permissao para brilho de monitores externos via DDC/CI

Depois de executar, saia da sessao e entre novamente pelo GDM.

## Instalar Apps

Para rodar todos os scripts de apps:

```bash
./install_apps.sh
```

Para rodar apenas um script especifico:

```bash
./scripts/starship.sh
./scripts/node.sh
./scripts/flatpak.sh
```

Antes de executar scripts individuais, se necessario:

```bash
chmod +x scripts/*.sh
```

## Scripts Disponiveis

- `scripts/dev_tools.sh`: ferramentas de desenvolvimento do Fedora
- `scripts/rust.sh`: Rust
- `scripts/uv.sh`: uv para Python
- `scripts/node.sh`: Node via NVM
- `scripts/flatpak.sh`: Flatpak
- `scripts/fonts.sh`: fontes
- `scripts/starship.sh`: Starship e autocomplete Bash
- `scripts/alacritty.sh`: Alacritty
- `scripts/zed.sh`: Zed
- `scripts/podman.sh`: Podman e Lazydocker
- `scripts/datagrip.sh`: DataGrip
- `scripts/postman.sh`: Postman
- `scripts/brave.sh`: Brave Browser
- `scripts/chrome.sh`: Google Chrome
- `scripts/opencode.sh`: OpenCode CLI
- `scripts/discord.sh`: Discord
- `scripts/git_gh.sh`: GitHub CLI e configuracao basica do Git
- `scripts/config.sh`: ajustes extras de configuracao

## Backup

O `install.sh` cria backup automatico antes de substituir configuracoes existentes:

- `~/.config/niri.backup.DATA-HORA`
- `~/.config/noctalia.backup.DATA-HORA`

## Observacoes

- O instalador foi feito para Fedora Workstation.
- Algumas mudancas, como grupo `i2c` para brilho de monitor externo, so entram em vigor depois de sair e entrar novamente na sessao.
- O repositorio guarda configuracoes pessoais; revise os arquivos antes de usar em outra maquina.
