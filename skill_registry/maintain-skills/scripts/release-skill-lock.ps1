param(
  [string]$LockDir='C:\codes\skills\indices\locks',
  [string]$SkillName='global'
)
$lockFile=Join-Path $LockDir ($SkillName + '.lock')
if (Test-Path -LiteralPath $lockFile) { Remove-Item -LiteralPath $lockFile -Force }
[pscustomobject]@{ skill=$SkillName; lock=$lockFile; locked=$false }
