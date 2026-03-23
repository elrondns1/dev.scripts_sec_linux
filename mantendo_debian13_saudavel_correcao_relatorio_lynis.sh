
apt purge -y \
aisleriot gnome-mahjongg gnome-mines gnome-sudoku quadrapassel \
five-or-more four-in-a-row hitori iagno lightsoff swell-foop tali \
gnome-music gnome-weather gnome-contacts gnome-maps \
cheese simple-scan shotwell \
gnome-clocks gnome-characters

apt purge cups cups-daemon

apt purge tracker tracker-miner-fs tracker-extract tracker3 tracker3-miners

apt install -y \
ufw \
fail2ban \
rkhunter \
chkrootkit \
lynis
keepassxc

apt install unattended-upgrades

# O Fail2Ban está instalado corretamente. Mas o Lynis alerta que você está usando o arquivo padrão.
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

systemctl restart fail2ban

# Esse módulo do PAM cria um diretório /tmp isolado para cada usuário.
apt install libpam-tmpdir

# O apt-listbugs verifica bugs críticos antes de instalar pacotes.
apt install apt-listbugs

# O needrestart detecta quando serviços precisam ser reiniciados após atualização.
apt install needrestart

ufw default deny incoming
ufw default allow outgoing
ufw enable

# Relacionado ao ModemManager. Se você não usa modem celular
#apt purge modemmanager

# Se seu computador não usa Thunderbolt
systemctl disable bolt.service
systemctl stop bolt.service

# Na maioria dos desktops não é necessário. Pode abrir portas SMTP.
apt purge exim4 exim4-base exim4-config exim4-daemon-light

# Controla troca entre GPU integrada e dedicada. Se seu computador tem apenas uma GPU
#apt purge switcheroo-control

#Se você não usa IPv6, pode desativar no Debian:
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

#adduser financeiro

#lynis audit system


#🔐 Pequena melhoria opcional
#Se quiser reforçar a proteção contra vazamento de memória, pode adicionar ao kernel:

#Editar:
#sudo nano /etc/sysctl.conf

#Adicionar:
#fs.suid_dumpable = 0
#kernel.kptr_restrict = 2
#kernel.dmesg_restrict = 1

#Aplicar:

#sudo sysctl -p

#Isso:
#✔ reduz vazamento de informações do kernel
#✔ protege contra exploração local
