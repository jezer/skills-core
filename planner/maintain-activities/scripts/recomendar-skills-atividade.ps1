param(
    [string]$Plano,
    [string]$AtividadeId,
    [string]$Texto,
    [string]$Contexto = "planejamento",
    [string]$IndicesPath = "C:\codes\skills\indices",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $IndicesPath)) {
    throw "Diretorio de indices nao encontrado: $IndicesPath"
}

$skillsIndexFile = Join-Path $IndicesPath "skills-index.json"
$contextoMapFile = Join-Path $IndicesPath "contexto-map.json"
$aliasesFile = Join-Path $IndicesPath "aliases.json"

foreach ($f in @($skillsIndexFile, $contextoMapFile, $aliasesFile)) {
    if (-not (Test-Path -LiteralPath $f)) {
        throw "Indice obrigatorio ausente: $f"
    }
}

$skillsIndex = Get-Content -LiteralPath $skillsIndexFile -Raw | ConvertFrom-Json
$contextoMap = Get-Content -LiteralPath $contextoMapFile -Raw | ConvertFrom-Json
$aliases = Get-Content -LiteralPath $aliasesFile -Raw | ConvertFrom-Json

$contextosValidos = @($contextoMap.contextos.PSObject.Properties.Name)
if ($contextosValidos -notcontains $Contexto) {
    throw "Contexto invalido para recomendacao: $Contexto. Contextos validos: $($contextosValidos -join ', ')"
}

$baseText = ""
if (-not [string]::IsNullOrWhiteSpace($Texto)) {
    $baseText = $Texto
} elseif (-not [string]::IsNullOrWhiteSpace($Plano) -and -not [string]::IsNullOrWhiteSpace($AtividadeId)) {
    if (-not (Test-Path -LiteralPath $Plano)) {
        throw "Plano nao encontrado: $Plano"
    }
    $lines = Get-Content -LiteralPath $Plano
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^###\s+$([regex]::Escape($AtividadeId))\b") {
            $start = $i
            break
        }
    }
    if ($start -lt 0) {
        throw "Atividade nao encontrada no plano: $AtividadeId"
    }
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^###\s+\S+") {
            $end = $i
            break
        }
    }
    $baseText = ($lines[$start..($end - 1)] -join " ")
} else {
    throw "Informe Texto ou Plano + AtividadeId."
}

$text = $baseText.ToLowerInvariant()
$tokens = ($text -split '[^a-z0-9_-]+' | Where-Object { $_ -and $_.Length -ge 3 })

$score = @{}
function Add-Score([string]$name, [int]$points) {
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    if (-not $score.ContainsKey($name)) { $score[$name] = 0 }
    $score[$name] += $points
}

# 1) contexto-map como base
if ($contextoMap.contextos.PSObject.Properties.Name -contains $Contexto) {
    foreach ($s in $contextoMap.contextos.$Contexto.skills) {
        Add-Score $s 30
    }
}

# 2) aliases por termo encontrado no texto
foreach ($prop in $aliases.aliases.PSObject.Properties) {
    $aliasName = $prop.Name.ToLowerInvariant()
    if ($text -match [regex]::Escape($aliasName)) {
        foreach ($s in $prop.Value) {
            Add-Score $s 20
        }
    }
}

# 3) match por nome/descricao/contexto do skills-index
foreach ($s in $skillsIndex.skills) {
    $name = [string]$s.name
    $desc = ([string]$s.description).ToLowerInvariant()
    $nameLow = $name.ToLowerInvariant()

    foreach ($t in $tokens) {
        if ($nameLow -like "*$t*") {
            Add-Score $name 8
        }
        if ($desc -like "*$t*") {
            Add-Score $name 3
        }
    }

    if ($s.contextos -contains $Contexto) {
        Add-Score $name 10
    }
}

$ordered = $score.GetEnumerator() | Sort-Object -Property @{Expression='Value';Descending=$true}, @{Expression='Key';Descending=$false}
$top = @($ordered | Select-Object -First 6)

$out = [pscustomobject]@{
    Contexto = $Contexto
    Atividade = if ($AtividadeId) { $AtividadeId } else { "" }
    Recomendas = @($top | ForEach-Object { [pscustomobject]@{ skill = $_.Key; score = $_.Value } })
    TextoBase = $baseText
}

if ($Json) {
    $out | ConvertTo-Json -Depth 8
} else {
    $out
}
