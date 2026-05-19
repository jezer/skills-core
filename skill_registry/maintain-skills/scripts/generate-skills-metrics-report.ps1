param(
  [string]$ReportDir='C:\codes\skills\reports'
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$syncPath='C:\codes\skills\dist\sync-report.json'
$healthPath='C:\codes\skills\indices\health-report.json'
$sync = if(Test-Path $syncPath){ Get-Content -LiteralPath $syncPath -Raw | ConvertFrom-Json } else { $null }
$health = if(Test-Path $healthPath){ Get-Content -LiteralPath $healthPath -Raw | ConvertFrom-Json } else { $null }
$metrics=[pscustomobject]@{
  generated_at=(Get-Date).ToString('s')
  sync_apply= if($sync){ $sync.apply } else { $null }
  skills_oficiais= if($sync){ $sync.skills_oficiais } else { $null }
  gemini_missing= if($sync){ @($sync.gemini.missing).Count } else { $null }
  copilot_missing= if($sync){ @($sync.copilot.missing).Count } else { $null }
  claude_missing= if($sync){ @($sync.claude.missing).Count } else { $null }
  codex_bridge_ok= if($sync){ $sync.codex_bridge_ok } else { $null }
  health_critical_ok= if($health){ $health.critical_ok } else { $null }
}
$daily = Join-Path $ReportDir ("skills-metrics-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
$metrics | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $daily -Encoding utf8
$metrics
