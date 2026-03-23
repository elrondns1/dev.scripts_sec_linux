#!/usr/bin/env bash
set -e

BASE="$HOME/.portable"
XDG_CONFIG="$HOME/.config"
XDG_CACHE="$HOME/.cache"
XDG_BIN="$HOME/.local/bin"

# Detecta distro
source /etc/os-release
DISTRO_ID="${ID,,}"

echo "📦 Distro detectada: $DISTRO_ID"

# Estrutura base
mkdir -p \
  "$BASE"/{bin,aliases,env,history,logs,cache} \
  "$BASE"/config/{shell,git,editor,tools} \
  "$BASE"/distros/"$DISTRO_ID" \
  "$BASE"/bootstrap

# XDG dirs
mkdir -p "$XDG_CONFIG" "$XDG_CACHE" "$XDG_BIN"

# Arquivos base
touch \
  "$BASE/aliases/common.aliases" \
  "$BASE/aliases/distro.aliases" \
  "$BASE/env/common.env" \
  "$BASE/env/distro.env"

# Detect distro script
cat << 'EOF' > "$BASE/bootstrap/detect_distro.sh"
#!/usr/bin/env bash
source /etc/os-release
echo "${ID,,}"
EOF

chmod +x "$BASE/bootstrap/detect_distro.sh"

# Loader geral
cat <<'EOF'>>"$BASE/bootstrap/load_all.sh"
#!/usr/bin/env bash

BASE="$HOME/.portable"
DISTRO="$("$BASE/bootstrap/detect_distro.sh")"

# PATH
export PATH="$BASE/bin:$HOME/.local/bin:$PATH"

# ENV
[ -f "$BASE/env/common.env" ] && source "$BASE/env/common.env"
[ -f "$BASE/env/distro.env" ] && source "$BASE/env/distro.env"

# Aliases
[ -f "$BASE/aliases/common.aliases" ] && source "$BASE/aliases/common.aliases"
[ -f "$BASE/aliases/$DISTRO.aliases" ] && source "$BASE/aliases/$DISTRO.aliases"

# Configs específicas da distro
if [ -d "$BASE/distros/$DISTRO" ]; then
  for f in "$BASE/distros/$DISTRO"/*.sh; do
    [ -f "$f" ] && source "$f"
  done
fi
EOF

chmod +x "$BASE/bootstrap/load_all.sh"

# Integração com shell
for SHELL_RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$SHELL_RC" ] && ! grep -q portable/load_all "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Portable environment" >> "$SHELL_RC"
    echo "source \$HOME/.portable/bootstrap/load_all.sh" >> "$SHELL_RC"
  fi
done

echo "✅ Ambiente portátil criado com sucesso!"

