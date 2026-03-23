#!/bin/bash

echo "==============================="
echo " DIAGNOSTICO DO SISTEMA LINUX "
echo "==============================="

echo ""
echo "---- Informações do Sistema ----"
uname -a
cat /etc/os-release

echo ""
echo "---- Uptime ----"
uptime

echo ""
echo "---- CPU ----"
lscpu

echo ""
echo "---- Memória ----"
free -h

echo ""
echo "---- Disco ----"
df -h

echo ""
echo "---- Dispositivos de bloco ----"
lsblk

echo ""
echo "---- Hardware resumido ----"
sudo lshw -short

echo ""
echo "---- Interfaces de Rede ----"
ip a

echo ""
echo "---- Rotas de Rede ----"
ip route

echo ""
echo "---- Conexões de Rede ----"
ss -tulnp

echo ""
echo "---- Processos mais pesados ----"
ps aux --sort=-%mem | head

echo ""
echo "---- Usuários do sistema ----"
cut -d: -f1 /etc/passwd

echo ""
echo "---- Usuários logados ----"
who

echo ""
echo "---- Últimos logins ----"
last | head

echo ""
echo "---- Serviços ativos ----"
systemctl list-units --type=service --state=running | head -20

echo ""
echo "---- Espaço em /var/log ----"
du -sh /var/log

echo ""
echo "---- FIM DO DIAGNÓSTICO ----"

