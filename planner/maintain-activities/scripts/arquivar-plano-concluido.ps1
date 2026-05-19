param(
    [Parameter(Mandatory = $true)][string]$Plano
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Plano)) {
    throw "Plano nao encontrado: $Plano"
}

$dir = Split-Path -Parent $Plano
$name = Split-Path -Leaf $Plano
$dirName = Split-Path -Leaf $dir
if ($dirName -eq "concluido") {
    [pscustomobject]@{
        PlanoOriginal = $Plano
        PlanoConcluido = $Plano
    }
    return
}
$concluidoDir = Join-Path $dir "concluido"
New-Item -ItemType Directory -Path $concluidoDir -Force | Out-Null

$dest = Join-Path $concluidoDir $name
if (Test-Path -LiteralPath $dest) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $dest = Join-Path $concluidoDir ("{0}.{1}.md" -f ([IO.Path]::GetFileNameWithoutExtension($name)), $stamp)
}

Move-Item -LiteralPath $Plano -Destination $dest

[pscustomobject]@{
    PlanoOriginal = $Plano
    PlanoConcluido = $dest
}
