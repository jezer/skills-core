param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$Validator = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
    throw "SkillsRoot nao encontrado: $SkillsRoot"
}

if ([string]::IsNullOrWhiteSpace($Validator)) {
    $candidates = @(
        (Join-Path $env:USERPROFILE ".codex\skills\.system\skill-creator\scripts\quick_validate.py"),
        "C:\Users\jefte\.codex\skills\.system\skill-creator\scripts\quick_validate.py",
        "C:\Users\jezer.santos_nowvert\.codex\skills\.system\skill-creator\scripts\quick_validate.py"
    )
    $Validator = ($candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
}

if ([string]::IsNullOrWhiteSpace($Validator) -or -not (Test-Path -LiteralPath $Validator)) {
    throw "Validador nao encontrado: $Validator"
}

$pythonCandidates = @(
    "python",
    (Join-Path $env:USERPROFILE "AppData\Local\Programs\Python\Python311\python.exe"),
    (Join-Path $env:USERPROFILE "AppData\Local\Python\bin\python.exe"),
    (Join-Path $env:USERPROFILE "AppData\Local\Python\pythoncore-3.14-64\python.exe")
)
$pythonExe = ""
foreach ($candidate in $pythonCandidates) {
    if ($candidate -eq "python") {
        if (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonExe = "python"
            break
        }
    } elseif (Test-Path -LiteralPath $candidate) {
        $pythonExe = $candidate
        break
    }
}
if ([string]::IsNullOrWhiteSpace($pythonExe)) {
    throw "Python nao encontrado para executar o validador de skills."
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
    & $pythonExe $Validator $skill.FullName
    if ($LASTEXITCODE -ne 0) {
        $failed += $skill.Name
    }
}

if ($failed.Count -gt 0) {
    throw "Skills invalidas: $($failed -join ', ')"
}

Write-Host "Skills validas: $($skills.Count)"
