#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Debian 13 portátil - otimização para pendrive/SSD externo
# Foco: reduzir escrita, melhorar resposta e padronizar
# Autor: TARS
# =========================================================

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute como root: sudo bash $0"
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/root/debian13-usb-tuning-backup-${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"

log() {
  echo
  echo "==> $1"
}

backup_file() {
  local file="$1"
  if [[ -e "$file" ]]; then
    mkdir -p "${BACKUP_DIR}$(dirname "$file")"
    cp -a "$file" "${BACKUP_DIR}${file}"
  fi
}

append_if_missing() {
  local line="$1"
  local file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

replace_or_append_kv() {
  local key="$1"
  local value="$2"
  local file="$3"
  if grep -qE "^\s*#?\s*${key}=" "$file"; then
    sed -i "s|^\s*#\?\s*${key}=.*|${key}=${value}|g" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

replace_or_append_space_kv() {
  local key="$1"
  local value="$2"
  local file="$3"
  if grep -qE "^\s*#?\s*${key}\s+" "$file"; then
    sed -i "s|^\s*#\?\s*${key}\s\+.*|${key} ${value}|g" "$file"
  else
    echo "${key} ${value}" >> "$file"
  fi
}

log "Criando backup dos arquivos principais"
for f in \
  /etc/fstab \
  /etc/systemd/journald.conf \
  /etc/sysctl.conf \
  /etc/systemd/logind.conf \
  /etc/login.defs \
  /etc/profile \
  /etc/bash.bashrc
do
  backup_file "$f"
done

backup_file /etc/profile.d/timeout.sh
backup_file /etc/profile.d/umask.sh
backup_file /etc/profile.d/99-portable-aliases.sh
backup_file /etc/sysctl.d/99-portable-tuning.conf
backup_file /etc/systemd/zram-generator.conf
backup_file /etc/modprobe.d/blacklist-portable.conf

log "Atualizando índice de pacotes"
apt update

log "Instalando pacotes úteis"
DEBIAN_FRONTEND=noninteractive apt install -y \
  zram-tools \
  needrestart \
  debsums \
  apt-listbugs \
  curl \
  wget \
  rsync

log "Habilitando e iniciando zram-tools"
systemctl enable zramswap.service >/dev/null 2>&1 || true
systemctl restart zramswap.service >/dev/null 2>&1 || true

log "Ajustando journald para usar armazenamento volátil em RAM"
JOURNALD_CONF="/etc/systemd/journald.conf"
touch "$JOURNALD_CONF"
replace_or_append_kv "Storage" "volatile" "$JOURNALD_CONF"
replace_or_append_kv "RuntimeMaxUse" "100M" "$JOURNALD_CONF"
replace_or_append_kv "SystemMaxUse" "0" "$JOURNALD_CONF"

log "Criando arquivo de sysctl para reduzir escrita e melhorar resposta"
SYSCTL_TUNING="/etc/sysctl.d/99-portable-tuning.conf"
cat > "$SYSCTL_TUNING" <<'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=15
fs.inotify.max_user_watches=524288
EOF

sysctl --system >/dev/null 2>&1 || true

log "Configurando timeout de shell"
#mkdir -p /etc/profile.d
#cat > /etc/profile.d/timeout.sh <<'EOF'
#export TMOUT=900
#readonly TMOUT
#export TMOUT
#EOF
#chmod 644 /etc/profile.d/timeout.sh

log "Configurando umask 027"
cat > /etc/profile.d/umask.sh <<'EOF'
umask 027
EOF
chmod 644 /etc/profile.d/umask.sh
replace_or_append_space_kv "UMASK" "027" /etc/login.defs

log "Criando aliases úteis para ambiente portátil"
#cat > /etc/profile.d/99-portable-aliases.sh <<'EOF'
#alias ll='ls -lah --color=auto'
#alias la='ls -A'
#alias l='ls -CF'
#alias dfh='df -hT'
#alias duh='du -h --max-depth=1'
#alias ports='ss -tulpn'
#alias myip='hostname -I'
#EOF
#chmod 644 /etc/profile.d/99-portable-aliases.sh

log "Ajustando /etc/fstab para reduzir escrita com noatime e commit=60"
FSTAB="/etc/fstab"
cp -a "$FSTAB" "${FSTAB}.pre-portable-${TIMESTAMP}"

python3 - <<'PY'
from pathlib import Path
fstab = Path("/etc/fstab")
lines = fstab.read_text().splitlines()
new_lines = []

def tune_opts(opts: str) -> str:
    parts = [p.strip() for p in opts.split(",") if p.strip()]
    parts = [p for p in parts if p not in ("relatime", "strictatime", "atime")]
    wanted = ["noatime", "commit=60"]
    for w in wanted:
        if w not in parts:
            parts.append(w)
    return ",".join(parts)

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        new_lines.append(line)
        continue

    cols = line.split()
    if len(cols) < 4:
        new_lines.append(line)
        continue

    fs_spec, mountpoint, fstype, options = cols[:4]

    if mountpoint == "/" and fstype in ("ext4", "ext3", "ext2", "btrfs", "xfs"):
        cols[3] = tune_opts(options)
        new_lines.append("\t".join(cols))
    else:
        new_lines.append(line)

fstab.write_text("\n".join(new_lines) + "\n")
PY

log "Garantindo tmpfs para /tmp e /var/tmp"
append_if_missing "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,mode=1777 0 0" /etc/fstab
append_if_missing "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,nodev,mode=1777 0 0" /etc/fstab

log "Opcional: /var/log em RAM fica DESATIVADO por padrão"
VARLOG_SNIPPET="/root/EXEMPLO_var_log_tmpfs.txt"
cat > "$VARLOG_SNIPPET" <<'EOF'
# Se você quiser colocar /var/log em RAM também, avalie antes:
# tmpfs /var/log tmpfs defaults,noatime,nosuid,nodev,mode=0755,size=100M 0 0
#
# Isso reduz escrita, mas logs somem ao reiniciar.
EOF

log "Desativando serviços comuns desnecessários, se existirem"
SERVICES_TO_DISABLE=(
  #bluetooth.service
  cups.service
  cups-browsed.service
  avahi-daemon.service
  #ModemManager.service
  speech-dispatcher.service
  whoopsie.service
)

for svc in "${SERVICES_TO_DISABLE[@]}"; do
  if systemctl list-unit-files | grep -q "^${svc}"; then
    systemctl disable --now "$svc" >/dev/null 2>&1 || true
    echo "Desativado: $svc"
  fi
done

log "Ajustando readahead do dispositivo raiz, se detectável"
ROOT_DEV="$(findmnt -n -o SOURCE / || true)"
if [[ -n "${ROOT_DEV}" ]]; then
  BASE_DEV="$(lsblk -no pkname "$ROOT_DEV" 2>/dev/null || true)"
  if [[ -n "${BASE_DEV}" && -b "/dev/${BASE_DEV}" ]]; then
    blockdev --setra 4096 "/dev/${BASE_DEV}" || true
    echo "Readahead ajustado para /dev/${BASE_DEV}"
  fi
fi

log "Configurando systemd-tmpfiles para limpeza de temporários"
mkdir -p /etc/tmpfiles.d
cat > /etc/tmpfiles.d/portable-cleanup.conf <<'EOF'
D /tmp 1777 root root 12h
D /var/tmp 1777 root root 7d
EOF

log "Criando blacklist opcional de módulos raramente usados"
cat > /etc/modprobe.d/blacklist-portable.conf <<'EOF'
# Opcional para reduzir superfície de ataque em máquinas portáteis
blacklist firewire-ohci
EOF

log "Recarregando journald"
systemctl restart systemd-journald

log "Resumo final"
cat <<EOF

Backup salvo em:
  ${BACKUP_DIR}

Arquivo com exemplo opcional para /var/log em RAM:
  ${VARLOG_SNIPPET}

Ajustes aplicados:
  - zram habilitado
  - journald volátil em RAM
  - /tmp e /var/tmp em tmpfs
  - / com noatime,commit=60
  - swappiness e cache ajustados
  - timeout de shell
  - umask 027
  - serviços comuns desativados se presentes

IMPORTANTE:
  1. Revise /etc/fstab antes de reiniciar.
  2. Reinicie o sistema para aplicar tudo corretamente.
  3. Em ambiente com pouca RAM, monitore uso antes de ativar /var/log em tmpfs.

Comandos úteis pós-reboot:
  mount | egrep ' / |/tmp|/var/tmp'
  swapon --show
  journalctl --disk-usage
  systemctl --failed

EOF

log "Concluído"
