param(
  [string]$SkillsRoot='C:\codes\skills',
  [string]$RegistryPath='C:\codes\skills\core\skill_registry\skill-registry.json',
  [string]$ReportPath='C:\codes\skills\indices\health-report.json'
)

$ErrorActionPreference='Stop'
$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$regNames = @($registry.items | ForEach-Object { $_.name })
$skills = Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter SKILL.md |
  Where-Object { $_.FullName -notmatch '\\dist\\|\\gemini\\|\\plan\\|\\indices\\' }

$missingAgents=@();$missingCorrelation=@();$missingRegistry=@()
foreach($s in $skills){
  $dir=Split-Path -Parent $s.FullName
  $name=Split-Path -Leaf $dir
  if(-not (Test-Path -LiteralPath (Join-Path $dir 'agents\openai.yaml'))){ $missingAgents += $dir }
  $txt = Get-Content -LiteralPath $s.FullName -Raw
  if($txt -notmatch 'Correlacao Obrigatoria de Skills'){ $missingCorrelation += $dir }
  if($regNames -notcontains $name){ $missingRegistry += $name }
}

$report=[pscustomobject]@{
  generated_at=(Get-Date).ToString('s')
  total_skills=$skills.Count
  missing_agents=$missingAgents
  missing_correlation_block=$missingCorrelation
  missing_registry_entries=($missingRegistry | Sort-Object -Unique)
  critical_ok=($missingCorrelation.Count -eq 0 -and $missingRegistry.Count -eq 0)
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding utf8
$report
if (-not $report.critical_ok) { throw 'Health report com erros criticos.' }
