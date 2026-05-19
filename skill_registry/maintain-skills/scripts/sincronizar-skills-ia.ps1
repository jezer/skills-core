param(
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$GeminiRoot = "C:\codes\skills\dist\gemini",
    [string]$CopilotRoot = "C:\codes\skills\dist\copilot",
    [string]$ClaudeRoot = "C:\codes\skills\dist\claude",
    [string]$CodexRoot = "C:\codes\skills\dist\codex",
    [string]$CodexGlobalSkillsRoot = "C:\Users\jezer.santos_nowvert\.codex\skills",
    [string]$CodexBridgeRoot = "C:\Users\jezer.santos_nowvert\.codex\skills\usar-codes-agents",
    [string]$SyncReportPath = "C:\codes\skills\dist\sync-report.json",
    [string]$CheckpointPath = "C:\codes\skills\dist\sync-checkpoint.json",
    [int]$BatchSize = 50,
    [switch]$FailOnGeminiMismatch,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

function Assert-Path { param([string]$Path,[string]$Label) if (-not (Test-Path -LiteralPath $Path)) { throw "$Label nao encontrado: $Path" } }
function Get-SkillDirs {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    Get-ChildItem -LiteralPath $Root -Recurse -File -Filter SKILL.md |
      Where-Object { $_.FullName -notmatch "\\plan\\|\\indices\\|\\dist\\" } |
      ForEach-Object { Get-Item -LiteralPath $_.DirectoryName } |
      Sort-Object FullName -Unique
}
function Get-SkillNamesFromRoot {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
      Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
      Sort-Object Name | ForEach-Object { $_.Name })
}
function Sync-SkillContent {
    param([string]$SourceSkillPath,[string]$TargetSkillPath)
    New-Item -ItemType Directory -Path $TargetSkillPath -Force | Out-Null
    foreach ($name in @("SKILL.md","agents","scripts")) {
        $source = Join-Path $SourceSkillPath $name
        if (-not (Test-Path -LiteralPath $source)) { continue }
        $target = Join-Path $TargetSkillPath $name
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
    }
}
function Compare-Set {
    param([string[]]$Source,[string[]]$Target,[string[]]$AllowedExtras = @())
    [pscustomobject]@{
      missing = @($Source | Where-Object { $_ -ne 'configure-machine-default-skill' -and $_ -notin $Target })
      extras  = @($Target | Where-Object { $_ -notin $Source -and $_ -notin $AllowedExtras })
    }
}

Assert-Path -Path $SkillsRoot -Label "SkillsRoot"
$skillsOficiais = @(Get-SkillDirs -Root $SkillsRoot)
$oficiaisNames = @($skillsOficiais | ForEach-Object { $_.Name })

if ($Apply) {
    New-Item -ItemType Directory -Path $GeminiRoot,$CopilotRoot,$ClaudeRoot,$CodexRoot,$CodexGlobalSkillsRoot -Force | Out-Null

    $processed = @()
    $batchCount = 0
    foreach ($skill in $skillsOficiais) {
      if ($skill.Name -eq 'configure-machine-default-skill') { continue }
      $name = $skill.Name
      Sync-SkillContent -SourceSkillPath $skill.FullName -TargetSkillPath (Join-Path $GeminiRoot $name)
      Sync-SkillContent -SourceSkillPath $skill.FullName -TargetSkillPath (Join-Path $CopilotRoot $name)
      Sync-SkillContent -SourceSkillPath $skill.FullName -TargetSkillPath (Join-Path $ClaudeRoot $name)
      Sync-SkillContent -SourceSkillPath $skill.FullName -TargetSkillPath (Join-Path $CodexRoot $name)
      Sync-SkillContent -SourceSkillPath $skill.FullName -TargetSkillPath (Join-Path $CodexGlobalSkillsRoot $name)
      $processed += $name
      $batchCount++
      if ($batchCount -ge $BatchSize) {
        [pscustomobject]@{
          generated_at = (Get-Date).ToString('s')
          mode = 'apply'
          processed = $processed
          total_processed = $processed.Count
          completed = $false
        } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CheckpointPath -Encoding utf8
        $batchCount = 0
      }
    }

    [pscustomobject]@{
      generated_at = (Get-Date).ToString('s')
      mode = 'apply'
      processed = $processed
      total_processed = $processed.Count
      completed = $true
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CheckpointPath -Encoding utf8
}

$geminiNames = Get-SkillNamesFromRoot -Root $GeminiRoot
$copilotNames = Get-SkillNamesFromRoot -Root $CopilotRoot
$claudeNames = Get-SkillNamesFromRoot -Root $ClaudeRoot
$codexNames = Get-SkillNamesFromRoot -Root $CodexRoot
$codexGlobalNames = Get-SkillNamesFromRoot -Root $CodexGlobalSkillsRoot

$cmpGemini = Compare-Set -Source $oficiaisNames -Target $geminiNames
$cmpCopilot = Compare-Set -Source $oficiaisNames -Target $copilotNames
$cmpClaude = Compare-Set -Source $oficiaisNames -Target $claudeNames
$cmpCodex = Compare-Set -Source $oficiaisNames -Target $codexNames
$cmpCodexGlobal = Compare-Set -Source $oficiaisNames -Target $codexGlobalNames -AllowedExtras @('usar-codes-agents')

$bridgeSkillMd = Join-Path $CodexBridgeRoot "SKILL.md"
$bridgeYaml = Join-Path $CodexBridgeRoot "agents\openai.yaml"
$bridgeOk = $false
$bridgeDetails = @()
if ((Test-Path -LiteralPath $bridgeSkillMd) -and (Test-Path -LiteralPath $bridgeYaml)) {
  $skillText = Get-Content -LiteralPath $bridgeSkillMd -Raw
  $yamlText = Get-Content -LiteralPath $bridgeYaml -Raw
  $skillNorm = $skillText -replace "\\\\", "\"
  $yamlNorm = $yamlText -replace "\\\\", "\"
  $hasRootRef = ($skillNorm -like "*C:\codes\AGENTS.md*") -and ($yamlNorm -like "*C:\codes\AGENTS.md*")
  if ($hasRootRef) { $bridgeOk = $true } else { $bridgeDetails += "Ponte global sem referencia root em ambos arquivos." }
} else { $bridgeDetails += "Ponte global minima do Codex incompleta." }

if ($FailOnGeminiMismatch -and $cmpGemini.missing.Count -gt 0) {
  throw ("Skills oficiais sem equivalente em gemini: " + ($cmpGemini.missing -join ", "))
}

$result = [pscustomobject]@{
  generated_at = (Get-Date).ToString('s')
  apply = [bool]$Apply
  skills_oficiais = $oficiaisNames.Count
  gemini = [pscustomobject]@{ total=$geminiNames.Count; missing=$cmpGemini.missing; extras=$cmpGemini.extras }
  copilot = [pscustomobject]@{ total=$copilotNames.Count; missing=$cmpCopilot.missing; extras=$cmpCopilot.extras }
  claude = [pscustomobject]@{ total=$claudeNames.Count; missing=$cmpClaude.missing; extras=$cmpClaude.extras }
  codex = [pscustomobject]@{ total=$codexNames.Count; missing=$cmpCodex.missing; extras=$cmpCodex.extras }
  codex_global = [pscustomobject]@{ total=$codexGlobalNames.Count; missing=$cmpCodexGlobal.missing; extras=$cmpCodexGlobal.extras }
  codex_bridge_ok = $bridgeOk
  codex_bridge_observacoes = $bridgeDetails
  checkpoint_path = $CheckpointPath
}

New-Item -ItemType Directory -Path (Split-Path -Parent $SyncReportPath) -Force | Out-Null
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SyncReportPath -Encoding utf8

[pscustomobject]@{
  SkillsOficiais = $oficiaisNames.Count
  SkillsGemini = $geminiNames.Count
  SkillsCopilot = $copilotNames.Count
  SkillsClaude = $claudeNames.Count
  SkillsCodex = $codexNames.Count
  SkillsCodexGlobal = $codexGlobalNames.Count
  FaltandoNoGemini = $cmpGemini.missing
  ExtrasNoGemini = $cmpGemini.extras
  FaltandoNoCopilot = $cmpCopilot.missing
  ExtrasNoCopilot = $cmpCopilot.extras
  FaltandoNoClaude = $cmpClaude.missing
  ExtrasNoClaude = $cmpClaude.extras
  FaltandoNoCodex = $cmpCodex.missing
  ExtrasNoCodex = $cmpCodex.extras
  FaltandoNoCodexGlobal = $cmpCodexGlobal.missing
  ExtrasNoCodexGlobal = $cmpCodexGlobal.extras
  CodexBridgeOk = $bridgeOk
  CodexBridgeObservacoes = $bridgeDetails
  Apply = [bool]$Apply
  SyncReportPath = $SyncReportPath
  CheckpointPath = $CheckpointPath
}
