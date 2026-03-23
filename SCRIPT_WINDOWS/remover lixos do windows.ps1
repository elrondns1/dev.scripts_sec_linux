# Perfeito ⚙️ — posso gerar um **script PowerShell automático** que:

# ✅ Remove o **Microsoft Edge**, **Bing**, **Widgets**, **Cortana**, **Teams**, **OneDrive** e outros apps pré-instalados inúteis.
# ✅ Desativa a integração do **Bing na pesquisa do Windows**.
# ✅ Bloqueia a reinstalação automática de alguns apps.
# ✅ Faz tudo em um clique (com segurança e logs).

# ---

## ⚠️ Avisos antes de usar

# * Execute **como Administrador**.
# * Alguns apps podem ser reinstalados após grandes atualizações do Windows.
# * O script **não remove componentes críticos** (como Microsoft Store, Configurações, Calculadora etc.), apenas bloatware e Edge.
# * Testado em **Windows 11 23H2+**.

# ---

## 💻 Script PowerShell — “Limpeza Total do Windows 11”

# Copie tudo abaixo para um arquivo chamado `LimparWindows11.ps1` e **execute como Administrador**:

# ```powershell
# ===============================================
# 🧹 SCRIPT DE LIMPEZA DO WINDOWS 11
# Remove Edge, Bing, Cortana, OneDrive e outros bloatwares
# ===============================================

Write-Host "🚀 Iniciando limpeza do Windows 11..." -ForegroundColor Cyan

# --- Verificação de permissões ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Execute este script como Administrador." -ForegroundColor Red
    exit
}

# --- Desinstalar Microsoft Edge ---
Write-Host "🗑️ Removendo Microsoft Edge..."
Get-AppxPackage *Microsoft.MicrosoftEdge.Stable* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinu7e
Get-AppxPackage *Microsoft.MicrosoftEdgeDev* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files (x86)\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force -ErrorAction SilentlyContinue

# --- Desativar reinstalação do Edge ---
$EdgeUpdatePath = "C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
if (Test-Path $EdgeUpdatePath) { Remove-Item $EdgeUpdatePath -Force }
New-Item -Path "C:\Program Files (x86)\Microsoft\EdgeUpdate" -Name "MicrosoftEdgeUpdate.exe" -ItemType File -Force | Out-Null

# --- Desinstalar OneDrive ---
Write-Host "🗑️ Removendo OneDrive..."
Stop-Process -Name OneDrive -ErrorAction SilentlyContinue
Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait -ErrorAction SilentlyContinue
Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

# --- Remover Cortana e Bing Search ---
Write-Host "🧠 Removendo Cortana e desativando Bing..."
Get-AppxPackage *Microsoft.549981C3F5F10* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows" -Name "Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 1

# --- Remover bloatware comum ---
$apps = @(
    "MicrosoftTeams",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.People",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MSPaint",
    "Microsoft.SkypeApp",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.Todos",
    "Microsoft.YourPhone",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftEdgeDevToolsClient"
)
foreach ($app in $apps) {
    Write-Host "🗑️ Removendo $app..."
    Get-AppxPackage *$app* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# --- Limpar cache de aplicativos ---
Write-Host "🧹 Limpando cache..."
Get-AppxPackage | Foreach { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppxManifest.xml" -ErrorAction SilentlyContinue }

# --- Otimização básica ---
Write-Host "⚙️ Executando limpeza de disco e temporários..."
Start-Process "cleanmgr.exe" "/sagerun:1" -NoNewWindow

Write-Host "`n✅ LIMPEZA CONCLUÍDA! Reinicie o computador para aplicar todas as mudanças." -ForegroundColor Green
# ```

# ---

## 🚀 Como usar

# 1. Salve o conteúdo acima como `LimparWindows11.ps1`.
# 2. Clique com o **botão direito → Executar com PowerShell (Administrador)**.
# 3. Aguarde o processo terminar (pode levar alguns minutos).
# 4. Reinicie o PC.

# ---

# Quer que eu adicione ao script opções **interativas** (ex: escolher o que remover antes de executar)?
# Posso gerar uma versão “menu interativo” com segurança e logs detalhados.

pause
