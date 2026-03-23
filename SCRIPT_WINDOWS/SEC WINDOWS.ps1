SEC WINDOWS

# ===============================
# 🛡️ Windows Hardening Script
# Data: 2025-10
# ===============================

Write-Host "Iniciando configuração de segurança..." -ForegroundColor Cyan

# --- 1. Criar ponto de restauração ---
Write-Host "Criando ponto de restauração..." -ForegroundColor Yellow
Enable-ComputerRestore -Drive "C:\" | Out-Null
Checkpoint-Computer -Description "Ponto inicial pós-instalação" -RestorePointType "MODIFY_SETTINGS"

# --- 2. Configurar política de execução segura ---
Write-Host "Aplicando política de execução segura..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Force

# --- 3. Ativar e configurar o Windows Defender ---
Write-Host "Configurando Microsoft Defender..." -ForegroundColor Yellow
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting 2
Set-MpPreference -SubmitSamplesConsent 1
Set-MpPreference -PUAProtection 1
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -ScanScheduleDay 0
Set-MpPreference -ScanScheduleTime 02:00:00

# --- 4. Ativar proteção contra ransomware ---
Write-Host "Ativando proteção contra ransomware..." -ForegroundColor Yellow
Set-MpPreference -EnableControlledFolderAccess Enabled

# --- 5. Ativar firewall em todos os perfis ---
Write-Host "Ativando Firewall do Windows..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# --- 6. Desativar RDP (Área de Trabalho Remota) ---
Write-Host "Desativando área de trabalho remota..." -ForegroundColor Yellow
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1

# --- 7. Configurar DNS seguro (Cloudflare + Quad9) ---
Write-Host "Configurando DNS seguro..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("1.1.1.1","9.9.9.9") -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("1.1.1.1","9.9.9.9") -ErrorAction SilentlyContinue

# --- 8. Ajustes de privacidade ---
Write-Host "Ajustando privacidade e telemetria..." -ForegroundColor Yellow
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 1
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

# --- 9. Desativar Cortana ---
Write-Host "Desativando Cortana..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null

# --- 10. Desativar compartilhamento de arquivos ---
Write-Host "Desativando compartilhamento de rede..." -ForegroundColor Yellow
Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled False -ErrorAction SilentlyContinue

# --- 11. Criar usuário padrão limitado (opcional) ---
Write-Host "Criando usuário padrão (sem privilégios administrativos)..." -ForegroundColor Yellow
$User = "elrond"
$Password = Read-Host "SenhaUsuarioPadrao@123456" -AsSecureString
New-LocalUser "elrond" -Password "SenhaUsuarioPadrao@123456" -AsSecureString -FullName "Usuário Padrão" -Description "Conta padrão para uso diário"
Add-LocalGroupMember -Group "Users" -Member $User
Write-Host "Usuário padrão criado com sucesso!" -ForegroundColor Green

# --- 12. Limpeza temporária ---
Write-Host "Limpando arquivos temporários..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# --- 13. Conclusão ---
Write-Host "✅ Configuração de segurança concluída com sucesso!" -ForegroundColor Green
Write-Host "Reinicie o computador para aplicar todas as alterações."

# ---------- 1. Políticas de execução e UAC ----------

Log "Definindo ExecutionPolicy: AllSigned (processo)..."
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine -Force -ErrorAction SilentlyContinue
# Ajusta UAC para notificar administradores em modo seguro
Log "Configurando UAC para nível alto..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -PropertyType DWord -Force | Out-Null
Log "UAC configurado."
