#!/bin/bash

echo "Iniciando limpeza de aplicativos desnecessários..."

apt update

echo "Removendo jogos e apps de entretenimento..."
apt purge -y \
aisleriot \
gnome-mahjongg \
gnome-mines \
gnome-sudoku \
quadrapassel \
five-or-more \
four-in-a-row \
hitori \
iagno \
lightsoff \
swell-foop \
tali

echo "Removendo apps de escritório e extras não essenciais..."
apt purge -y \
gnome-contacts \
gnome-maps \
gnome-music \
gnome-weather \
cheese \
simple-scan \
shotwell

echo "Removendo visualizadores e utilitários pouco usados..."
apt purge -y \
yelp \
seahorse \
gnome-clocks \
gnome-characters \
gnome-logs \
gnome-calendar

echo "Removendo indexadores e telemetria..."
apt purge -y \
tracker \
tracker-miner-fs \
tracker-extract \
tracker3 \
tracker3-miners

echo "Removendo suporte a impressão (caso não use)..."
apt purge -y \
cups \
cups-daemon \
printer-driver*

echo "Removendo bluetooth (caso não use)..."
#apt purge -y bluetooth bluez

apt purge -y \
aisleriot gnome-mahjongg gnome-mines gnome-sudoku quadrapassel \
five-or-more four-in-a-row hitori iagno lightsoff swell-foop tali \
gnome-music gnome-weather gnome-contacts gnome-maps \
cheese simple-scan shotwell \
gnome-clocks gnome-characters

echo "Removendo dependências órfãs..."
apt autoremove --purge -y

echo "Limpando cache..."
apt autoclean
apt clean

echo "Removendo arquivos de configuração restantes..."
dpkg -l | grep '^rc' | awk '{print $2}' | xargs dpkg --purge

echo "Limpeza finalizada."
