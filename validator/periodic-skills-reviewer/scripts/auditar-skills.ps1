param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$Output = "C:\codes\skills\plan\relatorio-revisao-skills.md"
)

$ErrorActionPreference = "Stop"

$dirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") } |
    Sort-Object Name

$lines = @()
$lines += "# Relatorio de revisao de skills"
$lines += ""
$lines += "- Data: $(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")"
$lines += "- Skills analisadas: $($dirs.Count)"
$lines += ""
$lines += "## Checklist"
$lines += ""

foreach ($d in $dirs) {
    $skillFile = Join-Path $d.FullName "SKILL.md"
    $content = Get-Content -LiteralPath $skillFile -Raw
    $hasObj = $content -match "## Objetivo"
    $hasLim = $content -match "## Limites"
    $hasDep = $content -match "## Dependencias operacionais"
    $lines += "- $($d.Name): objetivo=$hasObj, limites=$hasLim, dependencias=$hasDep"
}

Set-Content -LiteralPath $Output -Value $lines -Encoding UTF8
[pscustomobject]@{ Output = $Output; Skills = $dirs.Count }
