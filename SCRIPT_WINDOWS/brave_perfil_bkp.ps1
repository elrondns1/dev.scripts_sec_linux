param(
  [ValidateSet("export","import","list")]
  [string]$Action = "list",

  # Pasta onde salvar/ler os backups .zip
  [string]$BackupDir = "$env:USERPROFILE\Backups\Brave",

  # Caminho do arquivo .zip no modo import (opcional)
  [string]$ZipPath = "",

  # Nome da pasta do perfil: Default | Profile 1 | Profile 2...
  [string]$ProfileFolder = ""
)

$ErrorActionPreference = "Stop"

$UserData = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data"

function Ensure-Dir($p) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

function List-Profiles {
  if (!(Test-Path $UserData)) { throw "Pasta do Brave não encontrada: $UserData" }
  Get-ChildItem $UserData -Directory |
    Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile *" } |
    Select-Object Name, FullName
}

function Pick-Profile {
  $profiles = List-Profiles
  if (!$profiles) { throw "Nenhum perfil encontrado em: $UserData" }

  Write-Host "`nPerfis encontrados:" -ForegroundColor Cyan
  $i=0
  $profiles | ForEach-Object {
    Write-Host ("[{0}] {1}" -f $i, $_.Name)
    $i++
  }
  $idx = Read-Host "Digite o número do perfil"
  if ($idx -notmatch '^\d+$' -or [int]$idx -ge $profiles.Count) { throw "Índice inválido." }
  return $profiles[[int]$idx].Name
}

function Require-Brave-Closed {
  $p = Get-Process -Name "brave" -ErrorAction SilentlyContinue
  if ($p) {
    throw "Feche o Brave antes (encontrei processo 'brave' rodando)."
  }
}

Ensure-Dir $BackupDir

switch ($Action) {
  "list" {
    List-Profiles | Format-Table -AutoSize
  }

  "export" {
    Require-Brave-Closed

    if ([string]::IsNullOrWhiteSpace($ProfileFolder)) {
      $ProfileFolder = Pick-Profile
    }

    $src = Join-Path $UserData $ProfileFolder
    if (!(Test-Path $src)) { throw "Perfil não existe: $src" }

    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $zip = Join-Path $BackupDir ("Brave_{0}_{1}.zip" -f $ProfileFolder.Replace(" ",""), $stamp)

    Write-Host "`nExportando $ProfileFolder -> $zip" -ForegroundColor Green
    Compress-Archive -Path $src -DestinationPath $zip -Force
    Write-Host "OK." -ForegroundColor Green
  }

  "import" {
    Require-Brave-Closed

    if ([string]::IsNullOrWhiteSpace($ZipPath)) {
      $ZipPath = Read-Host "Cole o caminho do .zip (ex: C:\Backups\Brave_...zip)"
    }
    if (!(Test-Path $ZipPath)) { throw "Arquivo .zip não encontrado: $ZipPath" }

    # Extrai pra pasta temporária
    $tmp = Join-Path $env:TEMP ("brave_restore_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $tmp -Force

    # Descobre qual pasta veio dentro do zip (Default/Profile X)
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
    if (!$inner) { throw "Zip inválido: não encontrei pasta de perfil dentro dele." }

    $dest = Join-Path $UserData $inner.Name

    Write-Host "`nImportando -> $dest" -ForegroundColor Yellow

    if (Test-Path $dest) {
      $bak = $dest + ".bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
      Write-Host "Perfil já existe. Fazendo backup: $bak"
      Move-Item $dest $bak
    }

    Move-Item $inner.FullName $dest
    Remove-Item $tmp -Recurse -Force

    Write-Host "OK. Abra o Brave e selecione o perfil ($($inner.Name))." -ForegroundColor Green
  }
}
