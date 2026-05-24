param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$IndicesPath = "C:\codes\skills\indices",
    [switch]$ApplyGeminiSync,
    [string]$SessaoPath,
    [string]$ChamadoId
)

$ErrorActionPreference = "Stop"

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$validateScript = Join-Path $basePath "validate-skills.ps1"
$indicesScript = Join-Path $basePath "atualizar-indices-skills.ps1"
$syncScript = Join-Path $basePath "sincronizar-skills-ia.ps1"
$bootstrapScript = "C:\codes\skills\core\router\session-bootstrap.ps1"

foreach ($script in @($validateScript, $indicesScript, $syncScript)) {
    if (-not (Test-Path -LiteralPath $script)) {
        throw "Script obrigatorio nao encontrado: $script"
    }
}

if (-not [string]::IsNullOrWhiteSpace($SessaoPath) -and -not [string]::IsNullOrWhiteSpace($ChamadoId)) {
    if (-not (Test-Path -LiteralPath $bootstrapScript)) {
        throw "Bootstrap script nao encontrado: $bootstrapScript"
    }
    $bootstrapOut = & powershell -ExecutionPolicy Bypass -File $bootstrapScript `
        -SessaoPath $SessaoPath `
        -ChamadoId $ChamadoId `
        -SkillsCandidatas "maintain-skills,maintain-planner,maintain-activities,route-skills-by-context" `
        -SkillExecutora "maintain-skills" `
        -SkillsApoio "maintain-planner,maintain-activities,maintain-git,route-skills-by-context" `
        -Motivo "Fechamento padrao de manutencao com gate de inicio de sessao validado." 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("Falha no session bootstrap." + [Environment]::NewLine + ($bootstrapOut -join [Environment]::NewLine))
    }
}

$validateOut = & powershell -ExecutionPolicy Bypass -File $validateScript -SkillsRoot $SkillsRoot 2>&1
if ($LASTEXITCODE -ne 0) {
    throw ("Falha na validacao de skills." + [Environment]::NewLine + ($validateOut -join [Environment]::NewLine))
}

$indicesOut = & powershell -ExecutionPolicy Bypass -File $indicesScript -Mode Validate -SkillsRoot $SkillsRoot -IndicesPath $IndicesPath 2>&1
if ($LASTEXITCODE -ne 0) {
    throw ("Falha na validacao de indices." + [Environment]::NewLine + ($indicesOut -join [Environment]::NewLine))
}

# Gate: run-skill-tests (Pester + pytest) antes da sincronizacao IA
$runTestsScript = Join-Path $basePath "run-skill-tests.ps1"
if (Test-Path -LiteralPath $runTestsScript) {
    $testsOut = & powershell -ExecutionPolicy Bypass -File $runTestsScript -SkillsRoot $SkillsRoot -NoPython 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("Falha em run-skill-tests." + [Environment]::NewLine + ($testsOut -join [Environment]::NewLine))
    }
}

$syncArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $syncScript,
    "-SkillsRoot", $SkillsRoot
)
if ($ApplyGeminiSync) {
    $syncArgs += @("-Apply")
}

$syncOut = & powershell @syncArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    throw ("Falha na sincronizacao IA." + [Environment]::NewLine + ($syncOut -join [Environment]::NewLine))
}

$syncObj = $null
try {
    $syncObj = ($syncOut | Out-String) | ConvertFrom-StringData -ErrorAction SilentlyContinue
} catch {}

[pscustomobject]@{
    ValidacaoSkills = "ok"
    ValidacaoIndices = "ok"
    RunSkillTests = if (Test-Path -LiteralPath $runTestsScript) { "ok" } else { "skip" }
    SincronizacaoIA = "ok"
    ApplyGeminiSync = [bool]$ApplyGeminiSync
}
