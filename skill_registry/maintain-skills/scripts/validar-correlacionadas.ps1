param(
    [switch]$Json
)

# Plano 000135 do all_IA (AL-09, espelho no contexto skills): valida as
# skills CORRELACIONADAS do lote de manutencao aberto - grafo de
# dependencias, triggers sobrepostos e pasta raiz completa - via
# POST /skills/maintenance/validar. O resultado fica registrado no lote
# e e PRE-REQUISITO do checkin (gate).

$ErrorActionPreference = "Stop"

$apiBase = if ($env:ALLIA_API_URL) { $env:ALLIA_API_URL } else { "http://127.0.0.1:8000" }

try {
    $resp = Invoke-RestMethod -Method Post -Uri "$apiBase/skills/maintenance/validar" -TimeoutSec 300
} catch {
    $detalhe = $_.ErrorDetails.Message
    throw "Validacao de correlacionadas falhou: $($_.Exception.Message) $detalhe"
}

if ($Json) {
    $resp | ConvertTo-Json -Depth 6 -Compress
    return
}

Write-Host "Valido: $($resp.valido) | pedidos no lote: $($resp.pedidos_no_lote)"
foreach ($e in @($resp.erros)) { Write-Host "ERRO: $e" }
foreach ($a in @($resp.avisos)) { Write-Host "aviso: $a" }
if (-not $resp.valido) { exit 1 }
