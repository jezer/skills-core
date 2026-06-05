param(
    [int]$TimeoutMs = 500,
    [switch]$Json
)

# Plano skills 000133 (SK-09, caso 3-A): CHECK DE FRESCOR no inicio do prompt.
# Uma chamada HTTP local com timeout curto (~500ms) a GET /skills/sync/status;
# se houver skill alterada DEPOIS da ultima sincronizacao banco -> dist/, o
# sincronizador e invocado automaticamente (POST /skills/sync/run, delta).
# OFFLINE/timeout = fallback: usa o dist/ local como esta e registra a
# pendencia em skills/indices/.sync-pendente (criterio 5 do plano).

$ErrorActionPreference = "Stop"

# 127.0.0.1 (nao "localhost"): a resolucao IPv6 do localhost custa ~2s por
# processo no Windows e estouraria o timeout curto.
$apiBase = if ($env:ALLIA_API_URL) { $env:ALLIA_API_URL } else { "http://127.0.0.1:8000" }
$pendenciaPath = "C:\codes\skills\indices\.sync-pendente"

function Write-Pendencia {
    param([string]$Motivo)
    try {
        $dir = Split-Path -Parent $pendenciaPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($pendenciaPath,
            ("{0} | {1}" -f (Get-Date -Format "o"), $Motivo),
            (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

# Windows PowerShell 5.1: carrega System.Net.Http antes de usar HttpClient.
# UseProxy=false evita a deteccao de proxy do Windows (~2s por processo),
# que estouraria o timeout curto em chamadas localhost.
Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.UseProxy = $false
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromMilliseconds($TimeoutMs)
$status = $null
try {
    $resp = $client.GetStringAsync("$apiBase/skills/sync/status").GetAwaiter().GetResult()
    $status = $resp | ConvertFrom-Json
} catch {
    Write-Pendencia -Motivo "backend indisponivel no check de frescor"
    $out = [pscustomobject]@{ Frescor = "offline-fallback"; Sync = "pendente"; Detalhe = "usando dist/ local como esta" }
    if ($Json) { $out | ConvertTo-Json -Compress } else { $out }
    return
} finally {
    $client.Dispose()
}

if (-not $status.defasado) {
    if (Test-Path -LiteralPath $pendenciaPath) { Remove-Item -LiteralPath $pendenciaPath -Force -ErrorAction SilentlyContinue }
    $out = [pscustomobject]@{ Frescor = "em-dia"; Sync = "nao-necessaria"; MaxAlteradoEm = $status.max_alterado_em }
    if ($Json) { $out | ConvertTo-Json -Compress } else { $out }
    return
}

# defasado: invoca o sincronizador banco -> dist/ (delta por hash, caso 2-A)
try {
    $run = Invoke-RestMethod -Method Post -Uri "$apiBase/skills/sync/run" `
        -ContentType "application/json; charset=utf-8" `
        -Body '{"delta": true}' -TimeoutSec 300
    if (Test-Path -LiteralPath $pendenciaPath) { Remove-Item -LiteralPath $pendenciaPath -Force -ErrorAction SilentlyContinue }
    $out = [pscustomobject]@{ Frescor = "estava-defasado"; Sync = "executada"; Snapshot = $run.snapshot }
} catch {
    Write-Pendencia -Motivo "sync/run falhou: $($_.Exception.Message)"
    $out = [pscustomobject]@{ Frescor = "defasado"; Sync = "falhou-pendente"; Detalhe = $_.Exception.Message }
}

if ($Json) { $out | ConvertTo-Json -Compress } else { $out }
