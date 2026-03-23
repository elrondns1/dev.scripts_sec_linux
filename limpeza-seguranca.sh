#!/bin/bash

echo "Atualizando sistema..."
apt update && apt full-upgrade -y

echo "Removendo pacotes desnecessários..."
apt purge -y \
    popularity-contest \
    apport \
    cups \
    avahi-daemon \
    modemmanager \
    whoopsie \
    geoclue-2.0 \
    tracker \
    tracker-miner-fs \
    tracker-extract \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome

echo "Removendo pacotes órfãos..."
apt autoremove --purge -y
apt autoclean

echo "Desativando serviços potencialmente inseguros..."
systemctl disable avahi-daemon 2>/dev/null
systemctl disable cups 2>/dev/null
#systemctl disable ModemManager 2>/dev/null

echo "Limpando logs antigos..."
journalctl --vacuum-time=3d

echo "Limpando cache do sistema..."
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "Limpando histórico do usuário..."
history -c

echo "Protegendo permissões importantes..."
chmod 700 /root
chmod 700 /home/* 2>/dev/null

echo "Desativando core dumps..."
echo "* hard core 0" >> /etc/security/limits.conf

echo "Ativando firewall..."
apt install -y 
ufw default deny incoming
ufw default allow outgoing
ufw enable

echo "Configurando proteção básica sysctl..."

cat <<EOF >> /etc/sysctl.conf

# Proteção rede
net.ipv4.conf.all.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.accept_source_route=0

# Proteção kernel
kernel.randomize_va_space=2
kernel.kptr_restrict=2
EOF

sysctl -p

echo "Removendo arquivos temporários de usuário..."
find /home -name ".cache" -type d -exec rm -rf {} + 2>/dev/null

echo "Sistema limpo e com segurança básica aplicada."
