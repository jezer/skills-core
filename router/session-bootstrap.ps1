param(
  [Parameter(Mandatory=$true)][string]$SessaoPath,
  [Parameter(Mandatory=$true)][string]$ChamadoId,
  [Parameter(Mandatory=$true)][string]$SkillsCandidatas,
  [Parameter(Mandatory=$true)][string]$SkillExecutora,
  [Parameter(Mandatory=$true)][string]$SkillsApoio,
  [Parameter(Mandatory=$true)][string]$Motivo
)

# Plano 000134 do all_IA (caso 3-A): chamados/sessoes vivem no BANCO.
# - `SessaoPath` aceita um arquivo legado (somente leitura/ajuste local) OU o
#   formato virtual `banco:<numero>` (sessao N do chamado no banco, via API).
# - O status do chamado e resolvido API-first com fallback na arvore legada.
# Plano skills 000133 (SK-09): o inicio da sessao dispara o CHECK DE FRESCOR
# das skills (sync banco -> dist/ quando defasado; nao bloqueia em falha).

$ErrorActionPreference='Stop'

$apiBase = if ($env:ALLIA_API_URL) { $env:ALLIA_API_URL } else { "http://localhost:8000" }

# ── 000133 SK-09: check de frescor (nao bloqueante) ──────────────────────────
$frescorScript = Join-Path $PSScriptRoot "route-skills-by-context\scripts\verificar-frescor-skills.ps1"
if (Test-Path -LiteralPath $frescorScript) {
  try { & $frescorScript | Out-Null } catch { }
}

function Resolve-ChamadoPathFromId {
  param([Parameter(Mandatory=$true)][string]$Id)

  $m = [regex]::Match($Id, '^(?<empresa>[A-Z0-9]+)-(?<usuario>[A-Z0-9]+)-CH-(?<ano>\d{4})-(?<seq>\d{5})$')
  if (-not $m.Success) {
    throw "ChamadoId invalido: $Id. Formato esperado: EMPRESA-USUARIO-CH-AAAA-NNNNN"
  }

  $empresa = $m.Groups['empresa'].Value.ToLowerInvariant()
  $usuario = $m.Groups['usuario'].Value.ToLowerInvariant()
  $ano = $m.Groups['ano'].Value
  $seq = $m.Groups['seq'].Value

  return "C:\codes\tools\chamados\chamados\$empresa\$usuario\$ano\$seq\chamado.md"
}

function Get-ChamadoStatus {
  param([Parameter(Mandatory=$true)][string]$Id)

  # 000134: banco primeiro; arvore fisica e LEGADO somente leitura
  try {
    $resp = Invoke-RestMethod -Method Get -Uri "$apiBase/chamados/$Id" -TimeoutSec 5
    if ($resp.status) { return @{ status = $resp.status.ToLowerInvariant(); origem = "banco" } }
  } catch { }

  $chamadoMdPath = Resolve-ChamadoPathFromId -Id $Id
  if (-not (Test-Path -LiteralPath $chamadoMdPath)) {
    throw "Chamado nao encontrado no banco nem no legado: $Id"
  }
  $raw = Get-Content -LiteralPath $chamadoMdPath -Raw
  $m = [regex]::Match($raw, '(?im)^\s*-\s*Status:\s*(?<status>.+?)\s*$')
  if (-not $m.Success) {
    throw "Campo 'Status' ausente em chamado legado: $chamadoMdPath"
  }
  return @{ status = $m.Groups['status'].Value.Trim().ToLowerInvariant(); origem = "legado"; caminho = $chamadoMdPath }
}

$required = @($ChamadoId,$SkillsCandidatas,$SkillExecutora,$SkillsApoio,$Motivo)
if ($required | Where-Object { [string]::IsNullOrWhiteSpace($_) }) {
  throw 'Campos obrigatorios ausentes no bootstrap.'
}

$info = Get-ChamadoStatus -Id $ChamadoId
if ($info.status -notin @('aberto','em andamento')) {
  throw "Chamado sem status ativo para execucao persistente: '$($info.status)'. Use chamado com status 'aberto' ou 'em andamento'."
}

if ($SkillsCandidatas -notmatch 'route-skills-by-context' -and $SkillExecutora -ne 'route-skills-by-context' -and $SkillsApoio -notmatch 'route-skills-by-context') {
  throw 'route-skills-by-context deve constar como candidata, executora ou apoio.'
}

$linesToEnsure = @(
  "- Chamado: $ChamadoId",
  "- Skills candidatas: $SkillsCandidatas",
  "- Skill executora: $SkillExecutora",
  "- Skills de apoio: $SkillsApoio",
  "- Motivo da escolha: $Motivo"
)

function Update-TextoSessao {
  param([string]$Texto)
  foreach($l in $linesToEnsure){
    $field = ($l -split ':')[0]
    $pattern = '(?im)^' + [regex]::Escape($field) + ':.*$'
    if ([regex]::IsMatch($Texto,$pattern)) {
      $Texto = [regex]::Replace($Texto,$pattern,$l)
    } else {
      $Texto += "`r`n$l"
    }
  }
  return $Texto
}

if ($SessaoPath -match '^banco:(?<num>\d+)$') {
  # 000134: sessao no BANCO - le, garante as linhas e grava via API
  $numSessao = [int]$Matches.num
  $det = Invoke-RestMethod -Method Get -Uri "$apiBase/chamados/$ChamadoId" -TimeoutSec 10
  $sessao = @($det.sessoes | Where-Object { $_.numero -eq $numSessao }) | Select-Object -First 1
  if (-not $sessao) { throw "Sessao $numSessao nao encontrada no chamado $ChamadoId (banco)." }
  $novo = Update-TextoSessao -Texto ([string]$sessao.conteudo)
  $body = (@{ conteudo = $novo } | ConvertTo-Json -Depth 4)
  Invoke-RestMethod -Method Patch -Uri "$apiBase/chamados/$ChamadoId/sessoes/$numSessao" `
    -ContentType "application/json; charset=utf-8" `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 10 | Out-Null
} else {
  if (-not (Test-Path -LiteralPath $SessaoPath)) {
    throw "Sessao nao encontrada: $SessaoPath"
  }
  $txt = Get-Content -LiteralPath $SessaoPath -Raw
  $txt = Update-TextoSessao -Texto $txt
  Set-Content -LiteralPath $SessaoPath -Value $txt -Encoding utf8
}

[pscustomobject]@{
  SessaoPath=$SessaoPath
  ChamadoId=$ChamadoId
  ChamadoStatus=$info.status
  ChamadoOrigem=$info.origem
  SkillExecutora=$SkillExecutora
  BootstrapValido=$true
}
