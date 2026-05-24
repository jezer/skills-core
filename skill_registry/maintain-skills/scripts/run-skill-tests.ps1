<#
.SYNOPSIS
    Runner unico de testes de skills (Pester + pytest).

.DESCRIPTION
    Procura por `tests/*.Tests.ps1` (Pester) e `tests/test_*.py` (pytest)
    em todas as skills oficiais (ou em uma especifica) e executa.

.PARAMETER Skill
    Nome da skill (folder) para executar apenas ela.

.PARAMETER Path
    Caminho absoluto da skill, alternativo a -Skill.

.PARAMETER SkillsRoot
    Raiz das skills oficiais. Default C:\codes\skills.

.PARAMETER FailFast
    Se presente, aborta no primeiro fail.

.PARAMETER NoPython
    Pula pytest (se Python nao instalado ou nao desejado).
#>
param(
    [string]$Skill,
    [string]$Path,
    [string]$SkillsRoot = "C:\codes\skills",
    [switch]$FailFast,
    [switch]$NoPython
)

$ErrorActionPreference = "Stop"

function Get-SkillDirs {
    param([string]$Root)
    Get-ChildItem -LiteralPath $Root -Recurse -File -Filter SKILL.md -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch "\\dist\\" -and
            $_.FullName -notmatch "\\plan\\" -and
            $_.FullName -notmatch "\\indices\\"
        } |
        ForEach-Object { Split-Path -Parent $_.FullName } |
        Sort-Object -Unique
}

if ($Path) {
    $alvos = @($Path)
} elseif ($Skill) {
    $alvos = @(Get-SkillDirs -Root $SkillsRoot | Where-Object { (Split-Path $_ -Leaf) -eq $Skill })
    if (-not $alvos -or $alvos.Count -eq 0) { throw "Skill '$Skill' nao encontrada em $SkillsRoot." }
} else {
    $alvos = @(Get-SkillDirs -Root $SkillsRoot)
}

# Garantir Pester disponivel
$hasPester = $null -ne (Get-Module -ListAvailable -Name Pester | Select-Object -First 1)
if (-not $hasPester) {
    Write-Warning "Pester nao instalado. Instale com: Install-Module Pester -Scope CurrentUser -Force"
}

$resultados = @()
foreach ($skillDir in $alvos) {
    $testsDir = Join-Path $skillDir "tests"
    if (-not (Test-Path -LiteralPath $testsDir)) { continue }

    $skillName = Split-Path $skillDir -Leaf

    # Pester (.Tests.ps1)
    $pesterFiles = @(Get-ChildItem -LiteralPath $testsDir -Filter "*.Tests.ps1" -ErrorAction SilentlyContinue)
    if ($pesterFiles.Count -gt 0 -and $hasPester) {
        Write-Host ""
        Write-Host "=== Pester :: $skillName ==="
        $res = Invoke-Pester -Path $pesterFiles.FullName -PassThru -Output Detailed
        $ok = ($res.FailedCount -eq 0)
        $resultados += [pscustomobject]@{
            Skill   = $skillName
            Tipo    = "Pester"
            Total   = $res.TotalCount
            Passed  = $res.PassedCount
            Failed  = $res.FailedCount
            Ok      = $ok
        }
        if (-not $ok -and $FailFast) {
            $resultados | Format-Table -AutoSize
            throw "Pester falhou em $skillName (FailFast)."
        }
    }

    # pytest (test_*.py)
    if (-not $NoPython) {
        $pyFiles = @(Get-ChildItem -LiteralPath $testsDir -Filter "test_*.py" -ErrorAction SilentlyContinue)
        if ($pyFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "=== pytest :: $skillName ==="
            & python -m pytest $testsDir 2>&1 | Out-Host
            $okPy = ($LASTEXITCODE -eq 0)
            $resultados += [pscustomobject]@{
                Skill   = $skillName
                Tipo    = "pytest"
                Total   = $pyFiles.Count
                Passed  = if ($okPy) { $pyFiles.Count } else { 0 }
                Failed  = if ($okPy) { 0 } else { $pyFiles.Count }
                Ok      = $okPy
            }
            if (-not $okPy -and $FailFast) {
                $resultados | Format-Table -AutoSize
                throw "pytest falhou em $skillName (FailFast)."
            }
        }
    }
}

Write-Host ""
Write-Host "=== Resumo run-skill-tests ==="
if ($resultados.Count -eq 0) {
    Write-Host "Nenhum teste encontrado."
    return
}
$resultados | Format-Table -AutoSize
$failTotal = ($resultados | Where-Object { -not $_.Ok }).Count
if ($failTotal -gt 0) {
    throw "$failTotal grupo(s) de teste falharam."
}
