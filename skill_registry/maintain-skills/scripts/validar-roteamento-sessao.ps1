param(
    [Parameter(Mandatory = $true)][string]$SessaoArquivo,
    [switch]$FailOnPlaceholder
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SessaoArquivo)) {
    throw "Arquivo de sessao nao encontrado: $SessaoArquivo"
}

$texto = Get-Content -LiteralPath $SessaoArquivo -Raw

$campos = @(
    "Skills candidatas",
    "Skill executora",
    "Skills de apoio",
    "Motivo da escolha"
)

$faltando = @()
$placeholders = @()

foreach ($campo in $campos) {
    $pattern = "(?m)^- $([regex]::Escape($campo)):\s*(.*)$"
    $match = [regex]::Match($texto, $pattern)
    if (-not $match.Success) {
        $faltando += $campo
        continue
    }

    $valor = $match.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($valor) -or $valor -eq "PREENCHER") {
        $placeholders += $campo
    }
}

if ($faltando.Count -gt 0) {
    throw ("Campos obrigatorios ausentes na sessao: " + ($faltando -join ", "))
}

if ($FailOnPlaceholder -and $placeholders.Count -gt 0) {
    throw ("Campos com placeholder na sessao: " + ($placeholders -join ", "))
}

[pscustomobject]@{
    SessaoArquivo = (Resolve-Path -LiteralPath $SessaoArquivo).Path
    CamposObrigatorios = $campos.Count
    CamposPlaceholder = $placeholders
    Valido = ($faltando.Count -eq 0 -and ($FailOnPlaceholder -eq $false -or $placeholders.Count -eq 0))
}
