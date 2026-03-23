#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-valfenda}"

echo "[*] Criando estrutura em: $BASE_DIR"

# Diretórios principais
mkdir -p "$BASE_DIR"/{setup,bookmarks/exports,bookmarks/scripts,dotfiles/{bash,tmux,nano,git,common,cinnamon,kde,gnome,server},docs,assets/wallpapers}

# Arquivos raiz
touch "$BASE_DIR"/README.md
touch "$BASE_DIR"/.gitignore

# Setup
touch "$BASE_DIR"/setup/{setup.sh,common.sh,desktop-cinnamon.sh,desktop-kde.sh,desktop-gnome.sh,server.sh,proxmox.sh}

# Bookmarks
touch "$BASE_DIR"/bookmarks/{README.md,favoritos.md,trabalho.md,estudo.md,ferramentas.md,financeiro.md,tolkien.md}
touch "$BASE_DIR"/bookmarks/exports/brave-bookmarks.html
touch "$BASE_DIR"/bookmarks/scripts/gerar_html.sh

# Dotfiles
touch "$BASE_DIR"/dotfiles/bash/{.bashrc,.profile,aliases.sh}
touch "$BASE_DIR"/dotfiles/tmux/.tmux.conf
touch "$BASE_DIR"/dotfiles/nano/.nanorc
touch "$BASE_DIR"/dotfiles/git/.gitconfig
touch "$BASE_DIR"/dotfiles/common/{environment.sh,functions.sh}

touch "$BASE_DIR"/dotfiles/cinnamon/README.md
touch "$BASE_DIR"/dotfiles/kde/README.md
touch "$BASE_DIR"/dotfiles/gnome/README.md
touch "$BASE_DIR"/dotfiles/server/README.md

# Docs
touch "$BASE_DIR"/docs/{onboarding.md,padrao-de-nomes.md,maquinas.md,rotina-de-sync.md}

# Permissões úteis
chmod +x "$BASE_DIR"/setup/*.sh
chmod +x "$BASE_DIR"/bookmarks/scripts/*.sh

# Conteúdo inicial útil

cat > "$BASE_DIR/README.md" <<EOF
# Valfenda

Base pessoal para padronizar ambiente, favoritos e produtividade.

## Uso

\`\`\`bash
git clone <repo>
cd valfenda
bash setup/setup.sh
\`\`\`
EOF

cat > "$BASE_DIR/.gitignore" <<EOF
*.swp
*.swo
*~
.DS_Store
Thumbs.db
EOF

cat > "$BASE_DIR/bookmarks/README.md" <<EOF
# Bookmarks

Fonte da verdade dos favoritos.

- Editar arquivos .md
- Gerar HTML
- Importar no Brave
EOF

cat > "$BASE_DIR/bookmarks/favoritos.md" <<EOF
# Favoritos principais

## Infra
- [Proxmox](https://192.168.0.10:8006)
- [Gitea](https://gitea.local)

## Linux
- [Debian Wiki](https://wiki.debian.org)
- [GitHub](https://github.com)
EOF

cat > "$BASE_DIR/bookmarks/scripts/gerar_html.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$BASE_DIR/exports/brave-bookmarks.html"

mkdir -p "$BASE_DIR/exports"

cat > "$OUT" <<'HTML'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
HTML

for file in "$BASE_DIR"/*.md; do
    current_folder=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ (.*) ]]; then
            folder="${BASH_REMATCH[1]}"
            echo "  <DT><H3>${folder}</H3>" >> "$OUT"
            echo "  <DL><p>" >> "$OUT"
            current_folder="$folder"
        elif [[ "$line" =~ ^-\ \[(.*)\]\((.*)\) ]]; then
            name="${BASH_REMATCH[1]}"
            url="${BASH_REMATCH[2]}"
            echo "    <DT><A HREF=\"${url}\">${name}</A>" >> "$OUT"
        fi
    done < "$file"

    if [[ -n "$current_folder" ]]; then
        echo "  </DL><p>" >> "$OUT"
    fi
done

echo "</DL><p>" >> "$OUT"
echo "Gerado: $OUT"
EOF

cat > "$BASE_DIR/dotfiles/bash/.bashrc" <<EOF
# Valfenda Bash

export EDITOR=nano
export VISUAL=nano

alias ll='ls -lah'
alias gs='git status -sb'
alias v='nano'
alias tm='tmux'
EOF

cat > "$BASE_DIR/dotfiles/tmux/.tmux.conf" <<EOF
set -g mouse on
set -g prefix C-a
unbind C-b
bind C-a send-prefix
EOF

cat > "$BASE_DIR/dotfiles/nano/.nanorc" <<EOF
set linenumbers
set mouse
set autoindent
EOF

cat > "$BASE_DIR/setup/setup.sh" <<EOF
#!/usr/bin/env bash
echo "[*] Setup básico Valfenda"
EOF

echo "[OK] Estrutura criada com sucesso!"
echo
echo "Próximo passo:"
echo "cd $BASE_DIR"
echo "git init"
