param(
  [string]$LockDir='C:\codes\skills\indices\locks',
  [string]$SkillName='global'
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
$lockFile=Join-Path $LockDir ($SkillName + '.lock')
if (Test-Path -LiteralPath $lockFile) { throw "Lock ja existe para $SkillName" }
Set-Content -LiteralPath $lockFile -Value ((Get-Date).ToString('s')) -Encoding ascii
[pscustomobject]@{ skill=$SkillName; lock=$lockFile; locked=$true }
