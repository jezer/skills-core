param(
  [string]$RegistryPath = 'C:\codes\skills\core\skill_registry\skill-registry.json',
  [string]$DependencyPath = 'C:\codes\skills\core\dependency_graph\dependency-graph.json',
  [string]$SkillsRoot = 'C:\codes\skills'
)

$ErrorActionPreference='Stop'

if (-not (Test-Path -LiteralPath $RegistryPath)) { throw "Registry nao encontrado: $RegistryPath" }
if (-not (Test-Path -LiteralPath $DependencyPath)) { throw "Dependency graph nao encontrado: $DependencyPath" }

$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$deps = Get-Content -LiteralPath $DependencyPath -Raw | ConvertFrom-Json

$skills = Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter SKILL.md |
  Where-Object { $_.FullName -notmatch '\\dist\\|\\plan\\|\\indices\\|\\gemini\\' } |
  ForEach-Object { Split-Path -Leaf (Split-Path -Parent $_.FullName) } |
  Sort-Object -Unique

$regNames = @($registry.items | ForEach-Object { $_.name })
$depNames = @($deps.graph | ForEach-Object { $_.skill })

$errors = @()

foreach($s in $skills){
  if ($regNames -notcontains $s) { $errors += "Skill sem registry: $s" }
  if ($depNames -notcontains $s) { $errors += "Skill sem dependency graph: $s" }
}

# regra simples anti-conflito: nomes repetidos no registry
$dup = $regNames | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
foreach($d in $dup){ $errors += "Skill duplicada no registry: $d" }

if ($errors.Count -gt 0) {
  throw ($errors -join [Environment]::NewLine)
}

[pscustomobject]@{
  Skills = $skills.Count
  RegistryEntries = $regNames.Count
  DependencyEntries = $depNames.Count
  GovernanceValid = $true
}
