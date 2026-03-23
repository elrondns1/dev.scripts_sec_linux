Perfeito — vou te passar um **conjunto prático de ferramentas e comandos** (PowerShell + utilitários grátis) e **um script PowerShell** pronto que identifica tarefas agendadas com características suspeitas usando heurísticas comuns (execução a partir de `%temp%`/perfil do usuário, uso de `-EncodedCommand`, caminhos estranhos, itens ocultos, execução com privilégios elevados, triggers de logon, nomes “enganosos”, etc.).

> Observação: não preciso de acesso remoto nem a arquivos — você executa os comandos aí e cola resultados se quiser ajuda interpretando.

---

# Ferramentas recomendadas

1. **PowerShell (nativo)** — já instalado e suficiente para inventariar e detectar suspeitas.
2. **Autoruns (Sysinternals)** — mostra Scheduled Tasks e outros autostarts com interface: [https://learn.microsoft.com/sysinternals/downloads/autoruns](https://learn.microsoft.com/sysinternals/downloads/autoruns)
3. **TaskSchedulerView (NirSoft)** — lista e exporta tarefas com facilidade (pequeno utilitário GUI).
4. **Windows Defender / antivírus** — para escanear artefatos encontrados (`Start-MpScan` / `MpCmdRun`).
5. (Opcional) **sigcheck / Sysinternals** para validar assinaturas de executáveis identificados.

---

# Comandos rápidos (para começar)

Abra **PowerShell como Administrador**.

1. Listar todas as tarefas com informações básicas:

```powershell
Get-ScheduledTask | Select-Object TaskName, TaskPath, State, Principal, Actions | Format-Table -AutoSize
```

2. Listar tarefas com detalhes (triggers / ações / principal):

```powershell
Get-ScheduledTask | ForEach-Object {
    [PSCustomObject]@{
        TaskName  = $_.TaskName
        TaskPath  = $_.TaskPath
        State     = (Get-ScheduledTaskInfo -TaskName $_.TaskName -TaskPath $_.TaskPath).State
        Actions   = ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " ; "
        Triggers  = ($_.Triggers | ForEach-Object { "$($_.TriggerType): $($_.StartBoundary)" }) -join " ; "
        Principal = $_.Principal | Select-Object -Property UserId, RunLevel
        Hidden    = $_.Settings.Hidden
    }
} | Format-List
```

3. Ver tarefas que rodam a partir de `%TEMP%` ou do profile do usuário (alto sinal de alerta):

```powershell
Get-ScheduledTask | Where-Object {
    ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" } -join " ") -match "(?i)\\temp\\|AppData\\|%temp%|Users\\.*\\AppData"
} | Select-Object TaskName, TaskPath, @{N='Actions';E={ ($_.Actions | ForEach-Object {"$($_.Execute) $($_.Arguments)"}) -join "; "}} | Format-Table -AutoSize
```

4. Ver tarefas que executam `powershell.exe` com `-EncodedCommand` (comum em malware):

```powershell
Get-ScheduledTask | Where-Object {
    ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" } -join " ") -match "(?i)powershell\.exe.*-EncodedCommand|-e\b"
} | Select-Object TaskName, TaskPath, @{N='Actions';E={ ($_.Actions | ForEach-Object {"$($_.Execute) $($_.Arguments)"}) -join "; "}} | Format-Table -AutoSize
```

5. Exportar uma tarefa suspeita para análise (XML) — usando schtasks:

```powershell
$s = "NomeDaTarefa"   # substitua pelo nome real
schtasks /query /TN $s /XML > "C:\Temp\$($s -replace '[\\/:*?""<>|]','_').xml"
```

*(Se o comando acima falhar devido a espaço no nome, coloque o nome entre aspas: `schtasks /query /TN "Nome Completo" /XML > ...`)*

---

# Script PowerShell automatizado (heurísticas)

Cole e rode tudo no PowerShell (Admin). Ele lista tarefas com um campo `Suspicious` = True quando alguma heurística acendeu.

```powershell
# Script de detecção rápida de tarefas agendadas suspeitas
$badPathPatterns = @("(?i)\\AppData\\", "(?i)\\Temp\\", "(?i)%temp%", "(?i)\\Downloads\\")
$badNamePatterns = "(?i)update|updater|svchost|security|windowsupdate|upgrade|installer|audiodriver|taskhost" 
$out = @()

Get-ScheduledTask | ForEach-Object {
    $task = $_
    $actions = ($task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " ; "
    $triggers = ($task.Triggers | ForEach-Object { $_.TriggerType }) -join ","
    $runLevel = $task.Principal.RunLevel
    $hidden = $task.Settings.Hidden
    $suspicious = $false
    $reasons = @()

    # Heurísticas
    if ($actions -match $badPathPatterns -or $actions -match "(?i)\\Users\\.*\\AppData") {
        $suspicious = $true; $reasons += "Executes from user/temp path"
    }
    if ($actions -match "(?i)-EncodedCommand|-e\b") {
        $suspicious = $true; $reasons += "Encoded PowerShell command"
    }
    if ($actions -match "(?i)bitsadmin|rundll32|wscript|cscript|mshta|regsvr32") {
        $suspicious = $true; $reasons += "Uso de utilitários frequentemente abusados"
    }
    if ($runLevel -eq "Highest") {
        $suspicious = $true; $reasons += "Executa com privilégios elevados"
    }
    if ($hidden) {
        $suspicious = $true; $reasons += "Task oculta"
    }
    if ($task.TaskName -match $badNamePatterns -and $task.TaskPath -notmatch "Microsoft") {
        $suspicious = $true; $reasons += "Nome parecido com sistema mas não é Microsoft"
    }
    if ($triggers -match "Logon|OnStartup") {
        # logon/startup por si só não é mal, mas é um indicador quando combinado com outros
        if ($suspicious) { $reasons += "Dispara em logon/startup" }
    }

    $out += [PSCustomObject]@{
        TaskName   = $task.TaskName
        TaskPath   = $task.TaskPath
        Actions    = $actions
        Triggers   = $triggers
        RunLevel   = $runLevel
        Hidden     = $hidden
        Suspicious = $suspicious
        Reasons    = ($reasons -join "; ")
    }
}

$out | Where-Object { $_.Suspicious -eq $true } | Sort-Object TaskPath, TaskName | Format-Table -AutoSize
```

Esse script fornece uma **lista inicial** de tarefas que merecem investigação. Se quiser, cole aqui a saída (ou exporte para CSV com `| Export-Csv C:\Temp\tasks_sus.csv -NoTypeInformation`) para eu te ajudar a analisar cada item.

---

# O que fazer quando encontrar uma tarefa suspeita

1. **Não delete** imediatamente. Primeiro: **exporte** a definição (XML) e **documente** o binário alvo.

   * Export XML: `schtasks /query /TN "NomeDaTarefa" /XML > C:\Temp\NomeDaTarefa.xml`
2. **Identifique o executável** na ação e verifique o caminho completo.

   * Se for `%TEMP%` ou `AppData` → suspeita alta.
3. **Calcule hash** do executável:

```powershell
Get-FileHash "C:\caminho\para\arquivo.exe" -Algorithm SHA256
```

4. **Verifique assinatura**:

```powershell
Get-AuthenticodeSignature "C:\caminho\para\arquivo.exe"
```

5. **Faça scan** com Windows Defender:

```powershell
Start-MpScan -ScanType FullScan       # full scan
# ou para um arquivo
Start-MpScan -ScanPath "C:\caminho\para\arquivo.exe"
```

6. **Isolar** a máquina da rede se o comportamento for claramente malicioso (exfiltração, conexões desconhecidas).
7. Se for malicioso: **desative** a tarefa e remova/limpe o artefato após confirmação:

```powershell
Disable-ScheduledTask -TaskName "NomeDaTarefa" -TaskPath "\Path\"
# para remover:
Unregister-ScheduledTask -TaskName "NomeDaTarefa" -Confirm:$false -TaskPath "\Path\"
```

8. Procure por persistência adicional (services, Run keys, autoruns, startup folders).

---

# Logs úteis

* Visualizador de Eventos → `Applications and Services Logs -> Microsoft -> Windows -> TaskScheduler -> Operational` (registros de criação/execution/falhas).
* Procure por eventos de criação/alteração de tarefas.

---

Se quiser, eu faço o seguinte agora (você executa e cola o resultado):

1. Rode o script heurístico acima e cole a saída aqui — eu analiso cada tarefa marcada como suspeita.
2. Se preferir, exporta todo o inventário:

```powershell
# Exporta inventário completo
Get-ScheduledTask | ForEach-Object {
    [PSCustomObject]@{
        TaskName = $_.TaskName
        TaskPath = $_.TaskPath
        Actions  = ($_.Actions | ForEach-Object {"$($_.Execute) $($_.Arguments)"}) -join "; "
        Triggers = ($_.Triggers | ForEach-Object { $_.TriggerType }) -join ","
        RunLevel = $_.Principal.RunLevel
        Hidden   = $_.Settings.Hidden
    }
} | Export-Csv C:\Temp\scheduled_tasks_inventory.csv -NoTypeInformation -Encoding UTF8
```

e depois cola as linhas relevantes.

Quer que eu gere um comando já pronto para exportar todas as tarefas suspeitas para um CSV? Ou você prefere rodar o script acima e colar a saída?
