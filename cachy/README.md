# Config CachyOS (Niri + Noctalia)

Versao das configuracoes pessoais para **CachyOS**, que ja vem com Niri e Noctalia
instalados por padrao. Aqui o objetivo nao e instalar pacotes, e sim **aplicar a
minha config** por cima do que o CachyOS ja oferece.

Inclui:

- Configuracao do Niri em `niri-config/`
- Configuracao do Noctalia em `noctalia-config/`
- Instalador de config em `install.sh`
- Instalador modular de apps em `install_apps.sh` e scripts em `scripts/`

## Diferenca para o instalador do Fedora

O `install.sh` da raiz do repositorio e feito para Fedora Workstation: habilita COPR,
repositorio Terra e instala Niri/Noctalia via `dnf`. No CachyOS isso nao e necessario,
entao `cachy/install.sh` **nao instala pacotes nem mexe em repositorios** — apenas:

- Copia `niri-config/` para `~/.config/niri` (com backup)
- Copia `noctalia-config/` para `~/.config/noctalia` (com backup)
- Instala o plugin Polkit Agent do Noctalia (se `git` existir)
- Configura brilho de monitor externo via DDC/CI (se `ddcutil` existir)

## Uso

```bash
cd cachy
./install.sh
```

Se necessario, torne o script executavel antes:

```bash
chmod +x install.sh
```

Depois de aplicar, recarregue a config do Niri:

```bash
niri msg action load-config-file
```

Ou simplesmente saia e entre novamente na sessao.

## Backup

Antes de substituir configs existentes, o script cria:

- `~/.config/niri.backup.DATA-HORA`
- `~/.config/noctalia.backup.DATA-HORA`

## Observacoes

- Pacotes (niri, noctalia-shell, ddcutil, i2c-tools, etc.) sao responsabilidade do
  CachyOS; instale-os via `pacman`/AUR se algum estiver faltando.
- O ajuste de grupo `i2c` para brilho de monitor externo so entra em vigor depois de
  sair e entrar novamente na sessao.

## Instalar Apps

Versao do `install_apps.sh` adaptada para CachyOS (Arch). Diferente do Fedora, usa
`pacman` para pacotes dos repositorios oficiais e o helper AUR (`paru`, que ja vem no
CachyOS) para pacotes do AUR. Tambem usa **Docker** no lugar do Podman.

```bash
cd cachy
./install_apps.sh
```

Ou rode um script especifico:

```bash
./scripts/docker.sh
./scripts/chrome.sh
```

### Mapeamento de origem dos pacotes

| Script | Origem no CachyOS |
| --- | --- |
| `dev_tools.sh` | `pacman`: `base-devel`, `git` |
| `rust.sh` | instalador oficial (rustup) |
| `uv.sh` | instalador oficial (Astral) |
| `node.sh` | NVM (instalador oficial) |
| `flatpak.sh` | `pacman`: `flatpak` + Flathub |
| `fonts.sh` | Nerd Fonts (download) |
| `starship.sh` | instalador oficial + `pacman`: `git make gawk` |
| `alacritty.sh` | `pacman`: `alacritty` |
| `zed.sh` | instalador oficial |
| `docker.sh` | `pacman`: `docker`, `docker-compose`, `lazydocker` |
| `datagrip.sh` | AUR: `datagrip` |
| `postman.sh` | AUR: `postman-bin` |
| `brave.sh` | AUR: `brave-bin` |
| `chrome.sh` | AUR: `google-chrome` |
| `opencode.sh` | instalador oficial |
| `discord.sh` | `pacman`: `discord` |
| `ssh_orchestrator.sh` | extrai `.deb` da release (sem pacote Arch nativo) |
| `git_gh.sh` | `pacman`: `github-cli` |

### Principais diferencas para o Fedora

- **Docker no lugar de Podman**: `scripts/docker.sh` instala Docker + `docker-compose`
  + `lazydocker`, habilita o servico e adiciona o usuario ao grupo `docker`.
- Pacotes que no Fedora vinham de Flatpak/COPR/repos extras passam a vir do
  `pacman` (oficiais) ou do AUR via `paru`/`yay`.
- `ssh_orchestrator.sh` nao tem pacote Arch nativo, entao baixa o `.deb` da release
  e extrai os arquivos com `bsdtar`. Nao e gerenciado pelo `pacman`.

## Solucao de problemas

### Copilot CLI: `api.github.com` da timeout / token nao valida

Sintoma (erros do `copilot`):

```
Error auto updating: Failed to fetch latest release: HttpError: ...
  error sending request for url (https://api.github.com/repos/github/copilot-cli/releases/latest):
  client error (Connect): tcp connect error: deadline has elapsed

Authentication token found but could not be validated:
  Failed to fetch OAuth user login: TypeError: fetch failed
```

**Causa:** nao e problema do Copilot nem das configs. O DNS resolve `api.github.com`
para um IP da infra Azure do GitHub (ex.: `4.228.31.149`) que esta **inalcancavel a
partir da rede** (ping com 100% de perda e TCP/443 em timeout = buraco de roteamento,
geralmente no ISP). Curiosamente o `github.com` (IP vizinho) costuma funcionar, entao
so a API quebra.

**Diagnostico rapido:**

```bash
# Mostra o IP resolvido
getent hosts api.github.com

# Testa a conexao (se der timeout, o IP esta inalcancavel)
curl -4 -sS -o /dev/null -w "http=%{http_code} t=%{time_total}s\n" --max-time 10 https://api.github.com/zen

# Confirma que um IP classico do GitHub funciona
curl -4 -sS --resolve api.github.com:443:140.82.112.6 https://api.github.com/zen
```

**Workaround:** fixar `api.github.com` em um IP classico e alcancavel do GitHub no
`/etc/hosts`:

```bash
echo "140.82.112.6 api.github.com" | sudo tee -a /etc/hosts
```

Valide:

```bash
curl -sS https://api.github.com/zen   # deve responder uma frase (HTTP 200)
```

**Para reverter** (ex.: se o GitHub rotacionar IPs e a entrada ficar obsoleta):

```bash
sudo sed -i '/140.82.112.6 api.github.com/d' /etc/hosts
```

> Observacao: e um workaround. A correcao definitiva e o ISP arrumar a rota ate o IP
> Azure do GitHub, ou rotear o trafego via VPN (ex.: um *exit node* do Tailscale).
