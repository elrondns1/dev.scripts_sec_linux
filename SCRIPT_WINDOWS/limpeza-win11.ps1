# limpeza-win11.ps1
# Execute como Administrador

Write-Host "== LIMPEZA WINDOWS 11 ==" -ForegroundColor Cyan

# Pastas temporarias do usuario
Write-Host "Limpando TEMP do usuario..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Temp do Windows
Write-Host "Limpando TEMP do Windows..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Cache do Windows Update (opcional mas util quando incha)
Write-Host "Parando servicos do Windows Update..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service bits -Force -ErrorAction SilentlyContinue

Write-Host "Limpando SoftwareDistribution (cache Windows Update)..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando servicos do Windows Update..."
Start-Service bits -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Relatorios de erro do Windows (WER)
Write-Host "Limpando relatorios de erro (WER)..."
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue

# CrashDumps do usuario
$crash = "$env:LOCALAPPDATA\CrashDumps"
if (Test-Path $crash) {
  Write-Host "Limpando CrashDumps..."
  Remove-Item -Path "$crash\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Logs CBS/DISM (podem crescer)
Write-Host "Limpando logs CBS/DISM..."
Remove-Item -Path "C:\Windows\Logs\CBS\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Logs\DISM\*" -Recurse -Force -ErrorAction SilentlyContinue

# Lixeira
Write-Host "Esvaziando lixeira..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host "Concluido." -ForegroundColor Green

del C:\Windows\System32\LogFiles\kernel.etl
del C:\Windows\System32\LogFiles\user.etl
