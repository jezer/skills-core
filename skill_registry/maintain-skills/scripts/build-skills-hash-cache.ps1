param(
  [string]$SkillsRoot='C:\codes\skills',
  [string]$CachePath='C:\codes\skills\indices\skills-hash-cache.json'
)
$ErrorActionPreference='Stop'
$items=@()
$files = Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter SKILL.md | Where-Object { $_.FullName -notmatch '\\dist\\|\\gemini\\|\\plan\\|\\indices\\' }
$sha=[System.Security.Cryptography.SHA256]::Create()
foreach($f in $files){
  $bytes=[Text.Encoding]::UTF8.GetBytes((Get-Content -LiteralPath $f.FullName -Raw))
  $hash= -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
  $items += [pscustomobject]@{ skill=(Split-Path -Leaf (Split-Path -Parent $f.FullName)); file=$f.FullName; hash=$hash }
}
$result=[pscustomobject]@{ generated_at=(Get-Date).ToString('s'); total=$items.Count; items=$items }
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $CachePath -Encoding utf8
$result
