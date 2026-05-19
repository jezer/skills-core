param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$Validator = "C:\Users\jezer.santos_nowvert\.codex\skills\.system\skill-creator\scripts\quick_validate.py"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
    throw "SkillsRoot nao encontrado: $SkillsRoot"
}

if (-not (Test-Path -LiteralPath $Validator)) {
    throw "Validador nao encontrado: $Validator"
}

$skills = Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter SKILL.md |
    Where-Object {
        $_.FullName -notmatch "\\gemini\\" -and
        $_.FullName -notmatch "\\dist\\" -and
        $_.FullName -notmatch "\\plan\\" -and
        $_.FullName -notmatch "\\indices\\"
    } |
    ForEach-Object { Get-Item -LiteralPath $_.DirectoryName } |
    Sort-Object FullName -Unique

$failed = @()

foreach ($skill in $skills) {
    Write-Host "Validando $($skill.Name)..."
    & python $Validator $skill.FullName
    if ($LASTEXITCODE -ne 0) {
        $failed += $skill.Name
    }
}

if ($failed.Count -gt 0) {
    throw "Skills invalidas: $($failed -join ', ')"
}

Write-Host "Skills validas: $($skills.Count)"
