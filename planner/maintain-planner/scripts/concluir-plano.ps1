param(
    [Parameter(Mandatory=$true)][string]$Numero
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

$Numero = $Numero.PadLeft(6, '0')

# Plano 000134 do all_IA (casos 1-A/6-A): BANCO e a fonte - a API conclui e
# gera os espelhos; OFFLINE = fila local (sem mexer nos arquivos por fora).
if (-not $env:ALLIA_FROM_API) {
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$(Get-AllIAApiBase)/plans/$Numero/concluir" -TimeoutSec 150
        Write-Host "Via API all_IA: plano $($resp.numero) -> $($resp.status)"
        return
    } catch {
        $arquivo = Add-FilaOffline -Op "concluir-plano" -Payload @{ numero = $Numero }
        Write-Host "API all_IA indisponivel - conclusao ENFILEIRADA (fila: $arquivo)."
        return
    }
}
$all = Find-AllPlanFolders
$alvo = $all | Where-Object { $_.Numero -eq $Numero -and $_.Status -eq "em-andamento" } | Select-Object -First 1
if (-not $alvo) {
    throw "Plano $Numero nao encontrado em andamento."
}

$destinoBase = Join-Path $alvo.PlanDir "concluido"
if (-not (Test-Path -LiteralPath $destinoBase)) {
    New-Item -ItemType Directory -Path $destinoBase -Force | Out-Null
}
$destino = Join-Path $destinoBase (Split-Path $alvo.Caminho -Leaf)

if (Test-Path -LiteralPath $destino) {
    throw "Destino ja existe: $destino"
}

Move-Item -LiteralPath $alvo.Caminho -Destination $destino

# Atualizar status no plano.md
$planoMd = Join-Path $destino "plano.md"
if (Test-Path -LiteralPath $planoMd) {
    $hoje = (Get-Date).ToString("yyyy-MM-dd")
    $content = Get-Content -LiteralPath $planoMd
    $content = $content -replace "^- Status:.*$", "- Status: concluido"
    $content = $content -replace "^- Atualizado em:.*$", "- Atualizado em: $hoje"
    Write-Utf8NoBom -Path $planoMd -Content (($content -join "`n"))
}

Write-Host "Plano $Numero concluido: $destino"

$user = Get-CurrentUser
& (Join-Path $PSScriptRoot "atualizar-indice-planos.ps1") -Usuario $user
