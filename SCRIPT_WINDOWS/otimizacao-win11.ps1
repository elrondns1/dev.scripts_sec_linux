# otimizacao-win11.ps1
# Execute como Administrador

Write-Host "== OTIMIZACAO E SAUDE ==" -ForegroundColor Cyan

# Integridade do sistema
Write-Host "Rodando SFC (pode demorar)..."
sfc /scannow

Write-Host "Rodando DISM RestoreHealth (pode demorar)..."
DISM /Online /Cleanup-Image /RestoreHealth

# TRIM (SSD)
Write-Host "Otimizando SSD (TRIM)..."
Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue

# Ajuste de energia (equilibrado -> melhor responsividade sem fritar)
Write-Host "Definindo plano de energia Equilibrado..."
powercfg /setactive SCHEME_BALANCED

# Mostrar status de TRIM
Write-Host "Verificando TRIM..."
fsutil behavior query DisableDeleteNotify

# Checagem rapida do disco
Write-Host "Checando disco (scan sem reiniciar)..."
chkdsk C: /scan

Write-Host "Concluido." -ForegroundColor Green
