param(
    [Parameter(Mandatory = $true)][string]$Plano,
    [Parameter(Mandatory = $true)][string]$Atividade,
    [ValidateSet("pendente", "em andamento", "bloqueado", "feito", "cancelado")][string]$Status,
    [string]$Data = "pendente",
    [string]$Observacao,
    [switch]$ArquivarQuandoConcluir
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Plano)) {
    throw "Plano nao encontrado: $Plano"
}

$linhas = Get-Content -LiteralPath $Plano
$inicio = -1
for ($i = 0; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match "^###\s+$([regex]::Escape($Atividade))\b") {
        $inicio = $i
        break
    }
}

if ($inicio -lt 0) {
    throw "Atividade nao encontrada: $Atividade"
}

$fim = $linhas.Count
for ($i = $inicio + 1; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match "^###\s+\S+") {
        $fim = $i
        break
    }
}

for ($i = $inicio; $i -lt $fim; $i++) {
    if ($Status -and $linhas[$i] -match "^- Status:") {
        $linhas[$i] = "- Status: $Status"
    }
    if ($Data -and $linhas[$i] -match "^- Data de implementacao:") {
        $linhas[$i] = "- Data de implementacao: $Data"
    }
    if ($Observacao -and $linhas[$i] -match "^- Observacoes:") {
        $linhas[$i] = "- Observacoes: $Observacao"
    }
}

Set-Content -LiteralPath $Plano -Value $linhas -Encoding UTF8

$arquivado = $false
if ($ArquivarQuandoConcluir) {
    $statusLines = $linhas | Where-Object { $_ -match "^- Status:\s*(.+)$" } | ForEach-Object {
        if ($_ -match "^- Status:\s*(.+)$") { $matches[1].Trim().ToLowerInvariant() }
    }
    if ($statusLines.Count -gt 0 -and (($statusLines | Where-Object { $_ -notin @("feito","cancelado") }).Count -eq 0)) {
        $scriptArchive = Join-Path $PSScriptRoot "arquivar-plano-concluido.ps1"
        if (Test-Path -LiteralPath $scriptArchive) {
            & $scriptArchive -Plano $Plano | Out-Null
            $arquivado = $true
        }
    }
}

[pscustomobject]@{
    Plano = $Plano
    Atividade = $Atividade
    Status = $Status
    Data = $Data
    Arquivado = $arquivado
}
