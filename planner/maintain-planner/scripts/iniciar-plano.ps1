param(
    [Parameter(Mandatory=$true)][string]$Numero
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

$Numero = $Numero.PadLeft(6, '0')

# Plano 000134 do all_IA (casos 1-A/6-A): BANCO e a fonte - a API inicia e
# gera os espelhos; OFFLINE = fila local (sem mexer nos arquivos por fora).
if (-not $env:ALLIA_FROM_API) {
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$(Get-AllIAApiBase)/plans/$Numero/iniciar" -TimeoutSec 150
        Write-Host "Via API all_IA: plano $($resp.numero) -> $($resp.status)"
        return
    } catch {
        $arquivo = Add-FilaOffline -Op "iniciar-plano" -Payload @{ numero = $Numero }
        Write-Host "API all_IA indisponivel - inicio ENFILEIRADO (fila: $arquivo)."
        return
    }
}
$all = Find-AllPlanFolders
$alvo = $all | Where-Object { $_.Numero -eq $Numero } | Select-Object -First 1
if (-not $alvo) {
    throw "Plano $Numero nao encontrado."
}

if ($alvo.Status -eq "em-andamento") {
    Write-Host "Plano $Numero ja esta em andamento: $($alvo.Caminho)"
    return
}

# mover de concluido/descartado de volta para raiz do plan/
$destino = Join-Path $alvo.PlanDir (Split-Path $alvo.Caminho -Leaf)
if (Test-Path -LiteralPath $destino) {
    throw "Destino ja existe: $destino"
}

Move-Item -LiteralPath $alvo.Caminho -Destination $destino

$planoMd = Join-Path $destino "plano.md"
if (Test-Path -LiteralPath $planoMd) {
    $hoje = (Get-Date).ToString("yyyy-MM-dd")
    $content = Get-Content -LiteralPath $planoMd
    $content = $content -replace "^- Status:.*$", "- Status: em-andamento"
    $content = $content -replace "^- Atualizado em:.*$", "- Atualizado em: $hoje"
    Write-Utf8NoBom -Path $planoMd -Content (($content -join "`n"))
}

Write-Host "Plano $Numero iniciado: $destino"

$user = Get-CurrentUser
& (Join-Path $PSScriptRoot "atualizar-indice-planos.ps1") -Usuario $user
