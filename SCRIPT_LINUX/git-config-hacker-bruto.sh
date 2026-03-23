# setup-git-hacker-raw.ps1
# Script bruto: configurações Git com temática "hacker" usando comandos diretos (sem variáveis).

# Verifica se git está disponível
#if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
#    Write-Host "ERRO: 'git' não encontrado no PATH. Instale o Git antes de rodar este script." -ForegroundColor Red
#    exit 1
#}

#Write-Host "→ Aplicando configurações Git (tema: hacker)..." -ForegroundColor Cyan

# Informações do usuário (edite manualmente se quiser)
git config --global user.name "Elrond Peredhel"
git config --global user.email "dev.gh.ns1@outlook.com"

# Aparência e comportamento
git config --global core.editor "gnome-text-editor"
git config --global color.ui true
git config --global init.defaultBranch main
git config --global credential.helper manager-core

# Recomendações de fluxo / segurança
git config --global pull.rebase true
git config --global fetch.prune true
git config --global core.autocrlf true

# Aliases padrão úteis
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.ci "commit -v"
git config --global alias.br "branch"
git config --global alias.un "reset --"
git config --global alias.last "log -1 HEAD"
git config --global alias.lg "log --color --graph --pretty=format:'%C(yellow)%h%Creset %C(cyan)%ad%Creset %Cgreen%an%Creset %s' --date=short --all"
git config --global alias.hist "log --pretty=format:'%C(green)%h%Creset %C(white)%ad%Creset %C(bold blue)%an%Creset %n%C(dim white)%s%Creset' --date=short --max-count=30"
git config --global alias.unstage "reset HEAD --"

# Aliases com temática "hacker" (nomes alternativos)
git config --global alias.ghost "checkout"
git config --global alias.shadow "checkout -"
git config --global alias.sneak "stash"
git config --global alias.recon "status -s"
git config --global alias.breach "push"
git config --global alias.exfil "pull --rebase"
git config --global alias.phantom "rebase"
git config --global alias.hacklog "lg"

# Aliases potencialmente destrutivos — CUIDADO!
#git config --global alias.nuke "reset --hard HEAD"      # perigoso: descarta alterações locais
#git config --global alias.burn "!git clean -fd"         # perigoso: remove arquivos não rastreados

# Shortcuts compostos / utilitários
# Nota: git alias com '&&' ou múltiplos comandos requer '!' para invocar shell; aqui deixamos um exemplo prático
#git config --global alias.sync "/!git fetch --all && git pull --rebase"
#git config --global alias.save "/!f() { git add -A && git commit -m \"$1\"; }; f"
# uso: git save "mensagem"
