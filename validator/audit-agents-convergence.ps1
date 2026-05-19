param(
  [string]$SkillsRoot='C:\codes\skills',
  [string]$TemplatePath='C:\codes\skills\core\validator\agents-template.md'
)

$ErrorActionPreference='Stop'
$template = Get-Content -LiteralPath $TemplatePath -Raw
$targets = Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter AGENTS.md | Where-Object { $_.FullName -notmatch '\\dist\\|\\gemini\\' }

$nonCompliant = @()
foreach($t in $targets){
  $txt = Get-Content -LiteralPath $t.FullName -Raw
  if ($txt -notmatch 'route-skills-by-context') { $nonCompliant += $t.FullName }
}

[pscustomobject]@{
  Total = $targets.Count
  NonCompliant = $nonCompliant
  Compliant = ($nonCompliant.Count -eq 0)
}
if ($nonCompliant.Count -gt 0) { throw ('AGENTS nao aderentes: ' + ($nonCompliant -join '; ')) }
