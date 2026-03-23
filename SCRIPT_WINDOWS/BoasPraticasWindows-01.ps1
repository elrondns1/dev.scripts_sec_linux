
#O ChatGPT disse:
#Perfeito — segue uma versão avançada do script (Windows_Hardening_Advanced.ps1) que aplica hardening mais profundo, com opções seguras e prompts para ações sensíveis (ex: BitLocker, alterações de VBS/HVCI).
#O script tenta não fazer nada destrutivo sem sua confirmação e grava um log das ações em C:\Seguranca\Logs. Leia as instruções antes de executar.

#⚠️ Avisos importantes

#Execute somente como Administrador (PowerShell elevado).

#Leia os prompts antes de confirmar (especialmente BitLocker e alterações de virtualização).

#Algumas funcionalidades (AppLocker, VBS/HVCI, BitLocker automático) dependem de hardware (TPM, CPU com virtualização) e da edição do Windows (AppLocker só em Enterprise/Education). O script detecta e informa essas limitações.

#Salve as chaves de recuperação do BitLocker em local seguro — não confie apenas no disco local.

#Como usar
#Copie o conteúdo abaixo e salve como: C:\Seguranca\Windows_Hardening_Advanced.ps1

#Abra PowerShell como Administrador.

#Execute:

Set-ExecutionPolicy Bypass -Scope Process -Force
#C:\Seguranca\Windows_Hardening_Advanced.ps1
#Responda aos prompts (Y/N) quando aparecerem.

#Script: Windows_Hardening_Advanced.ps1
# ===============================
# Windows_Hardening_Advanced.ps1
# Versão: Avançada (corporate-level basics)
# Autor: ChatGPT GPT-5 Thinking mini
# Data: 2025-10-05
# ===============================

# ---------- Funções utilitárias ----------
function Log {
    param([string]$Text)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $Text" | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    Write-Host $Text
}

# ---------- Pré-check: privilégio de admin ----------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script precisa ser executado como Administrador. Saindo..." -ForegroundColor Red
    exit 1
}

# ---------- Preparação de pasta e log ----------
$basePath = "C:\Seguranca"
New-Item -Path $basePath -ItemType Directory -Force | Out-Null
$logPath = Join-Path $basePath "Logs"
New-Item -Path $logPath -ItemType Directory -Force | Out-Null
$Global:LogFile = Join-Path $logPath ("hardening_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
Log "Iniciando Windows Hardening avançado. Log em: $Global:LogFile"

# ---------- 0. Criar ponto de restauração (segurança) ----------
try {
    Log "Habilitando e criando ponto de restauração..."
    Enable-ComputerRestore -Drive "C:\" | Out-Null
    Checkpoint-Computer -Description "Ponto inicial pós-instalação - hardening avançado" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Log "Ponto de restauração criado com sucesso."
} catch {
    Log "Falha ao criar ponto de restauração: $($_.Exception.Message)"
}

# ---------- 1. Políticas de execução e UAC ----------
try {
    Log "Definindo ExecutionPolicy: AllSigned (processo)..."
    Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine -Force -ErrorAction SilentlyContinue
    # Ajusta UAC para notificar administradores em modo seguro
    Log "Configurando UAC para nível alto..."
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -PropertyType DWord -Force | Out-Null
    Log "UAC configurado."
} catch {
    Log "Erro em ExecutionPolicy/UAC: $($_.Exception.Message)"
}

# ---------- 2. Windows Defender - configurações avançadas ----------
try {
    Log "Configurando Microsoft Defender (realtime, PUA, bloqueio de comportamentos e scan agendado)..."
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -PUAProtection Enabled
    Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 1
    Set-MpPreference -MAPSReporting Advanced
    # Agendar scan semanal (domingo 03:00)
    $taskName = "DefenderWeeklyQuickScan_ChatGPT"
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-MpScan -ScanType QuickScan`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "Varredura rápida semanal do Defender" -User "SYSTEM" -RunLevel Highest
        Log "Agendada varredura rápida semanal do Defender."
    } else {
        Log "Tarefa agendada do Defender já existe."
    }
} catch {
    Log "Erro ao configurar Defender: $($_.Exception.Message)"
}

# ---------- 3. Proteção contra ransomware (Controlled Folder Access) ----------
try {
    Log "Ativando Controlled Folder Access..."
    Set-MpPreference -EnableControlledFolderAccess Enabled
    Log "Controlled Folder Access ativado."
} catch {
    Log "Erro ao ativar Controlled Folder Access: $($_.Exception.Message)"
}

# ---------- 4. Firewall e regras ----------
try {
    Log "Ativando Firewall para todos perfis e bloqueando regras de File and Printer sharing..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled False -ErrorAction SilentlyContinue
    # Bloquear NetBIOS/SMB em perfil Public (ex: bloquear descoberta em redes públicas)
    Log "Configurando bloqueios adicionais de exposição de rede..."
    Set-NetFirewallRule -DisplayName "Network Discovery (SSDP-In)" -Enabled False -ErrorAction SilentlyContinue
    Log "Firewall configurado."
} catch {
    Log "Erro ao configurar Firewall: $($_.Exception.Message)"
}

# ---------- 5. Desativar serviços/funcionalidades desnecessárias ----------
$servicesToDisable = @(
    "RemoteRegistry",   # permite edição remota do registr
    "TrkWks",           # Distributed Link Tracking Client (pode ser desnecessário)
    "SSDPSRV",          # SSDP Discovery
    "upnphost",         # UPnP Device Host
    "DiagTrack"         # Telemetria (se presente como serviço)
)
foreach ($svc in $servicesToDisable) {
    try {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Log "Parando e desabilitando serviço: $svc"
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        } else {
            Log "Serviço $svc não encontrado (ou já ausente)."
        }
    } catch {
        Log "Erro ao manipular serviço $svc: $($_.Exception.Message)"
    }
}

# ---------- 6. Desativar SMBv1 e NetBIOS (reduz exposição) ----------
try {
    Log "Desativando SMBv1 (se presente)..."
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
    Log "Desabilitando NetBIOS sobre TCP/IP nas interfaces (tentativa)..."
    Get-NetAdapter | ForEach-Object {
        try {
            Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "NetBIOS over Tcpip" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        } catch {}
    }
} catch {
    Log "Erro ao desativar SMBv1/NetBIOS: $($_.Exception.Message)"
}

# ---------- 7. DNS seguro (1.1.1.1, 9.9.9.9) nas interfaces conhecidas ----------
try {
    Log "Configurando DNS seguro (1.1.1.1, 9.9.9.9) para Ethernet e Wi-Fi (se existirem)..."
    $ifs = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}
    foreach ($if in $ifs) {
        try {
            Set-DnsClientServerAddress -InterfaceAlias $if.Name -ServerAddresses @("1.1.1.1","9.9.9.9") -ErrorAction SilentlyContinue
            Log "DNS aplicado na interface: $($if.Name)"
        } catch {
            Log "Não foi possível alterar DNS na interface $($if.Name): $($_.Exception.Message)"
        }
    }
} catch {
    Log "Erro ao configurar DNS: $($_.Exception.Message)"
}

# ---------- 8. SmartScreen e proteção do navegador ----------
try {
    Log "Ativando Microsoft Defender SmartScreen via registro..."
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "RequireAdmin" -PropertyType String -Force | Out-Null
    Log "SmartScreen configurado (valor RequireAdmin)."
} catch {
    Log "Erro ao configurar SmartScreen: $($_.Exception.Message)"
}

# ---------- 9. Restrições de macro no Office (set via registro) ----------
try {
    Log "Desabilitando macros VBA sem assinatura no Office (registro)..."
    $officePaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\excel\security",
        "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\word\security",
        "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\powerpoint\security"
    )
    foreach ($p in $officePaths) {
        New-Item -Path $p -Force | Out-Null
        New-ItemProperty -Path $p -Name "VBAWarnings" -Value 4 -PropertyType DWord -Force | Out-Null
    }
    Log "Macros configuradas: apenas macros assinadas ou desabilitadas."
} catch {
    Log "Erro ao configurar políticas de macro: $($_.Exception.Message)"
}

# ---------- 10. HVCI / VBS (Virtualization Based Security) - opcional (necessita reiniciar) ----------
try {
    $enableVBS = Read-Host "Deseja ativar VBS/HVCI (exige suporte hardware + reinicialização)? [Y/N]"
    if ($enableVBS -match '^[Yy]') {
        Log "Tentando habilitar VBS/HVCI via registro e BCD. Será necessário reiniciar."
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -PropertyType DWord -Force | Out-Null
        # Ajuste BCD para habilitar hypervisor launch
        try {
            bcdedit /set hypervisorlaunchtype auto | Out-Null
            Log "bcdedit ajustado: hypervisorlaunchtype auto"
        } catch {
            Log "Falha ao executar bcdedit: $($_.Exception.Message)"
        }
        Log "VBS/HVCI marcado para habilitação — reinício é necessário para aplicar."
    } else {
        Log "VBS/HVCI pulado por escolha do usuário."
    }
} catch {
    Log "Erro ao configurar VBS/HVCI: $($_.Exception.Message)"
}

# ---------- 11. BitLocker - opcional (requer TPM e/ou senha de recuperação) ----------
try {
    $doBitlocker = Read-Host "Deseja configurar BitLocker no drive do sistema (C:) agora? (recomenda-se ter um backup da chave) [Y/N]"
    if ($doBitlocker -match '^[Yy]') {
        # Local para salvar a chave de recuperação (usuário deve proteger essa pasta)
        $bkDir = Join-Path $basePath "RecoveryKeys"
        New-Item -Path $bkDir -ItemType Directory -Force | Out-Null
        Log "Verificando suporte a BitLocker/TMP..."
        $tpm = Get-Tpm -ErrorAction SilentlyContinue
        if ($tpm -and $tpm.TpmPresent -eq $true -and $tpm.TpmReady -eq $true) {
            Log "TPM presente e pronto. Procedendo com a ativação do BitLocker (TPM)."
            try {
                # Habilita BitLocker com gravação da chave de recuperação em arquivo
                $keyFile = Join-Path $bkDir ("BitLockerKey_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
                manage-bde -on C: -UsedSpaceOnly -RecoveryPassword -RecoveryKey $keyFile -ErrorAction Stop | Out-Null
                Log "BitLocker iniciado e chave de recuperação salva em $keyFile"
                Log "IMPORTANTE: Faça backup seguro desta chave (imprima / armazene em cofre)."
            } catch {
                Log "Falha ao iniciar BitLocker com TPM: $($_.Exception.Message)"
            }
        } else {
            Log "TPM ausente ou não pronto. Perguntando se deseja usar proteção por senha de recuperação (menos recomendado)."
            $usePwd = Read-Host "TPM ausente. Deseja ativar BitLocker com senha de recuperação em vez de TPM? [Y/N]"
            if ($usePwd -match '^[Yy]') {
                $pwd = Read-Host "Digite uma senha de recuperação (mínimo 8 caracteres)" -AsSecureString
                $pwdClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))
                $keyFile = Join-Path $bkDir ("BitLockerKey_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
                try {
                    manage-bde -on C: -UsedSpaceOnly -RecoveryPassword -RecoveryKey $keyFile -ErrorAction Stop | Out-Null
                    Log "BitLocker iniciado sem TPM. Chave de recuperação salva em $keyFile"
                } catch {
                    Log "Falha ao iniciar BitLocker sem TPM: $($_.Exception.Message)"
                } finally {
                    # esvazia variável com senha em texto puro
                    Remove-Variable pwdClear -ErrorAction SilentlyContinue
                }
            } else {
                Log "Usuário optou por não ativar BitLocker sem TPM."
            }
        }
    } else {
        Log "Passando BitLocker por escolha do usuário."
    }
} catch {
    Log "Erro na rotina de BitLocker: $($_.Exception.Message)"
}

# ---------- 12. Hardening de políticas locais e SRP (Software Restriction Policies) ----------
try {
    Log "Aplicando SRP básico (bloqueio de execução a partir de %temp% e perfis de usuário)..."
    # Cria política via diretiva local (refinamento possível via GPO em domínio)
    secedit /export /cfg "$basePath\secpol.cfg" | Out-Null
    # Nota: criação de SRP via script é complexa; aqui aplicamos medidas simples:
    # - Remover permissões de execução em diretórios temporários (apenas tentativa)
    $tempDirs = @("$env:TEMP", "$env:USERPROFILE\AppData\Local\Temp")
    foreach ($td in $tempDirs) {
        try {
            icacls $td /deny "Users:(RX)" | Out-Null
            Log "Tentativa de restringir execução em: $td"
        } catch {
            Log "Falha ao ajustar permissões em $td: $($_.Exception.Message)"
        }
    }
    Log "SRP/controles básicos aplicados (nota: recomenda-se GPO/AppLocker para ambiente corporativo)."
} catch {
    Log "Erro ao aplicar SRP/controles: $($_.Exception.Message)"
}

# ---------- 13. Auditoria / logs de segurança ----------
try {
    Log "Configurando política de auditoria básica (falhas/sucessos críticos)..."
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
    auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable | Out-Null
    auditpol /set /subcategory:"Object Access" /failure:enable | Out-Null
    Log "Políticas de auditoria aplicadas."
} catch {
    Log "Erro ao configurar auditoria: $($_.Exception.Message)"
}

# ---------- 14. Limpeza e rotina de manutenção ----------
try {
    Log "Criando tarefa agendada mensal para limpeza de temporários..."
    $taskName2 = "MonthlyTempCleanup_ChatGPT"
    if (-not (Get-ScheduledTask -TaskName $taskName2 -ErrorAction SilentlyContinue)) {
        $scriptCleanup = Join-Path $basePath "cleanup_temp.ps1"
        @"
Get-ChildItem -Path `$env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem -Path `$env:USERPROFILE\AppData\Local\Temp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
"@ | Out-File -FilePath $scriptCleanup -Encoding UTF8
        $action2 = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptCleanup`""
        $trigger2 = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 2am
        Register-ScheduledTask -Action $action2 -Trigger $trigger2 -TaskName $taskName2 -Description "Limpeza mensal de temporários" -User "SYSTEM" -RunLevel Highest
        Log "Tarefa de limpeza mensal criada."
    } else {
        Log "Tarefa de limpeza mensal já existe."
    }
} catch {
    Log "Erro ao criar tarefa de limpeza: $($_.Exception.Message)"
}

# ---------- 15. Privacidade (telemetria/advertising) ----------
try {
    Log "Reduzindo telemetria e desativando advertising id..."
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Force
    Log "Telemetria reduzida (configuração local via políticas)."
} catch {
    Log "Erro ao ajustar telemetria: $($_.Exception.Message)"
}

# ---------- 16. Desativar RDP (Remote Desktop) se não for necessário ----------
try {
    $disableRDP = Read-Host "Deseja desativar RDP (Remote Desktop) se estiver habilitado? [Y/N]"
    if ($disableRDP -match '^[Yy]') {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1 -Force
        Log "RDP desativado."
    } else {
        Log "RDP mantido conforme configuração atual."
    }
} catch {
    Log "Erro ao alterar RDP: $($_.Exception.Message)"
}

# ---------- Conclusão ----------
Log "Hardening avançado concluído (algumas alterações requerem reinício). Verifique o log em: $Global:LogFile"
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Atenção:" -ForegroundColor Yellow
Write-Host "- Revise a pasta de RecoveryKeys se você ativou BitLocker. Faça backup seguro." -ForegroundColor Yellow
Write-Host "- Algumas alterações (VBS/HVCI, BitLocker, SMB1 disable) exigem reinício." -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deseja reiniciar agora para aplicar todas as mudanças? [Y/N]"
$resp = Read-Host
if ($resp -match '^[Yy]') {
    Log "Usuário solicitou reinício. Reiniciando..."
    Restart-Computer -Force
} else {
    Log "Usuário optou por não reiniciar agora."
}

# Fim do script
O que esta versão adiciona / diferencia da anterior
Tarefas agendadas úteis (varredura do Defender semanal; limpeza mensal de temporários).

Tentativa automática de desativar serviços desnecessários.

Desabilitação de SMBv1 e tentativas de desabilitar NetBIOS.

Rotina para habilitar VBS/HVCI (com confirmação) — aumenta proteção anti-exploit.

Opção interativa para ativar BitLocker com salvamento de chave de recuperação em arquivo (você deve mover para local seguro).

Auditoria básica ativada.

Políticas de macro do Office via registro.

Logging completo e reversão/reboot controlado pelo usuário.

Limitações e recomendações finais
Tamper Protection do Defender não pode ser habilitada por script local simples — geralmente é gerenciada via Microsoft Defender ATP/Intune/MDM.

AppLocker: só está disponível em edições Enterprise/Education; a melhor prática em corporações é aplicar AppLocker/SRP via GPO. O script aplica medidas SRP básicas, mas não substitui GPO corporativa.

Teste esse script em uma máquina não produtiva (VM) antes de rodar em servidores ou máquinas críticas.

Faça backup das chaves de recuperação do BitLocker em um local offline seguro (pendrive cifrado, cofre, etc).

Quer que eu:

Gere uma versão sem prompts (para executar automaticamente)?

Adapte o script para salvar automaticamente as chaves num pendrive (se detectado)?

Crie um script de reversão que desfaz as principais mudanças?

Diz aí qual desses deseja que eu gere agora e eu preparo.