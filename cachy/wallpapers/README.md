# Wallpapers

Coloque aqui as imagens de wallpaper que o `install.sh` deve copiar para
`~/Pictures/Wallpapers` e (opcionalmente) definir como padrao no Noctalia.

## Wallpaper padrao

O `install.sh` tenta definir como padrao o arquivo apontado pela variavel
`DEFAULT_WALLPAPER` (atualmente `peakpx.jpg`).

Para trocar o wallpaper padrao:

1. Salve a imagem neste diretorio (ex.: `peakpx.jpg`).
2. Ajuste `DEFAULT_WALLPAPER` em `cachy/install.sh` se usar outro nome.
3. Rode `./install.sh` (em `cachy/`).

O script copia os arquivos para `~/Pictures/Wallpapers` e, se o Noctalia estiver
rodando, aplica o wallpaper via IPC:

```bash
qs -c noctalia-shell ipc call wallpaper set ~/Pictures/Wallpapers/peakpx.jpg
```

Se o Noctalia nao estiver rodando no momento, o wallpaper sera escolhido a partir
do diretorio configurado em `noctalia-config/settings.json` (`wallpaper.directory`).
