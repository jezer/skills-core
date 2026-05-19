param(
    [Parameter(Mandatory = $true)][string]$Plano
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Plano)) {
    throw "Plano nao encontrado: $Plano"
}

$conteudo = Get-Content -Raw -LiteralPath $Plano
$requisitos = @(
    "## Objetivo",
    "## Atividades planejadas",
    "## Checklist",
    "Criterio de aceite",
    "Skills recomendadas atuais"
)

$faltantes = @()
foreach ($item in $requisitos) {
    if ($conteudo -notlike "*$item*") {
        $faltantes += $item
    }
}

[pscustomobject]@{
    Plano = $Plano
    Valido = ($faltantes.Count -eq 0)
    Faltantes = ($faltantes -join ", ")
}

if ($faltantes.Count -gt 0) {
    exit 1
}
