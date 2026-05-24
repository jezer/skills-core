param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$Validator = "C:\Users\jezer.santos_nowvert\.codex\skills\.system\skill-creator\scripts\quick_validate.py",
    [switch]$AutoFixBom,
    [switch]$ContinueOnError,
    [string]$ReportPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
    throw "SkillsRoot nao encontrado: $SkillsRoot"
}
if (-not (Test-Path -LiteralPath $Validator)) {
    throw "Validador nao encontrado: $Validator"
}

function Remove-BomIfPresent {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $stripped = New-Object byte[] ($bytes.Length - 3)
        [System.Array]::Copy($bytes, 3, $stripped, 0, $bytes.Length - 3)
        [System.IO.File]::WriteAllBytes($Path, $stripped)
        return $true
    }
    return $false
}

function Classify-Error {
    param([string]$Message)
    if (-not $Message) { return "ok" }
    switch -Regex ($Message) {
        "missing YAML frontmatter|No YAML frontmatter|Invalid frontmatter format" { return "frontmatter-missing" }
        "Invalid YAML in frontmatter|mapping values are not allowed" { return "yaml-invalid" }
        "angle brackets" { return "description-angle-brackets" }
        "Description is too long" { return "description-too-long" }
        "Name '.*' should be hyphen-case|cannot start/end with hyphen|consecutive hyphens" { return "name-format" }
        "Name is too long" { return "name-too-long" }
        "Missing 'name'|Missing 'description'" { return "field-missing" }
        "Unexpected key" { return "unexpected-key" }
        default { return "outro" }
    }
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

$results = @()
$bomFixed = @()

foreach ($skill in $skills) {
    $skillMd = Join-Path $skill.FullName "SKILL.md"
    $bomRemoved = $false

    if ($AutoFixBom -and (Test-Path -LiteralPath $skillMd)) {
        $bomRemoved = Remove-BomIfPresent -Path $skillMd
        if ($bomRemoved) { $bomFixed += $skill.Name }
    }

    $output = & python $Validator $skill.FullName 2>&1
    $message = ($output | Out-String).Trim()
    $valid = $LASTEXITCODE -eq 0
    $category = if ($valid) { "ok" } else { Classify-Error -Message $message }

    $results += [pscustomobject]@{
        Name      = $skill.Name
        Path      = $skill.FullName
        Valid     = $valid
        Category  = $category
        Message   = $message
        BomFixed  = $bomRemoved
    }
}

$failed = @($results | Where-Object { -not $_.Valid })
$passed = @($results | Where-Object { $_.Valid })

Write-Host ""
Write-Host "=== Resumo da validacao de skills ==="
Write-Host "Total:    $($results.Count)"
Write-Host "Validas:  $($passed.Count)"
Write-Host "Invalidas:$($failed.Count)"
if ($bomFixed.Count -gt 0) {
    Write-Host "BOM removido em: $($bomFixed -join ', ')"
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Skills invalidas (por categoria):"
    $failed | Group-Object Category | ForEach-Object {
        Write-Host "  [$($_.Name)] $($_.Count):"
        foreach ($r in $_.Group) {
            $first = ($r.Message -split "`n")[0]
            Write-Host "    - $($r.Name): $first"
        }
    }
}

if ($ReportPath) {
    $report = [pscustomobject]@{
        generated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        skills_root  = $SkillsRoot
        total        = $results.Count
        validas      = $passed.Count
        invalidas    = $failed.Count
        bom_removido = $bomFixed
        resultados   = $results
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "Relatorio salvo em: $ReportPath"
}

if ($failed.Count -gt 0 -and -not $ContinueOnError) {
    throw "Skills invalidas: $($failed.Name -join ', ')"
}

Write-Host ""
Write-Host "Skills validas: $($passed.Count)"
