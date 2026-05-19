param(
  [Parameter(Mandatory=$true)][string]$SessaoPath,
  [Parameter(Mandatory=$true)][string]$ChamadoId,
  [Parameter(Mandatory=$true)][string]$SkillsCandidatas,
  [Parameter(Mandatory=$true)][string]$SkillExecutora,
  [Parameter(Mandatory=$true)][string]$SkillsApoio,
  [Parameter(Mandatory=$true)][string]$Motivo
)

$ErrorActionPreference='Stop'

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
  param([Parameter(Mandatory=$true)][string]$ChamadoMdPath)

  if (-not (Test-Path -LiteralPath $ChamadoMdPath)) {
    throw "Chamado nao encontrado para sessao ativa: $ChamadoMdPath"
  }

  $raw = Get-Content -LiteralPath $ChamadoMdPath -Raw
  $m = [regex]::Match($raw, '(?im)^\s*-\s*Status:\s*(?<status>.+?)\s*$')
  if (-not $m.Success) {
    throw "Campo 'Status' ausente em chamado: $ChamadoMdPath"
  }

  return $m.Groups['status'].Value.Trim().ToLowerInvariant()
}

if (-not (Test-Path -LiteralPath $SessaoPath)) {
  throw "Sessao nao encontrada: $SessaoPath"
}

$required = @($ChamadoId,$SkillsCandidatas,$SkillExecutora,$SkillsApoio,$Motivo)
if ($required | Where-Object { [string]::IsNullOrWhiteSpace($_) }) {
  throw 'Campos obrigatorios ausentes no bootstrap.'
}

$chamadoPath = Resolve-ChamadoPathFromId -Id $ChamadoId
$chamadoStatus = Get-ChamadoStatus -ChamadoMdPath $chamadoPath
if ($chamadoStatus -notin @('aberto','em andamento')) {
  throw "Chamado sem status ativo para execucao persistente: '$ChamadoStatus'. Use chamado com status 'aberto' ou 'em andamento'."
}

if ($SkillsCandidatas -notmatch 'route-skills-by-context' -and $SkillExecutora -ne 'route-skills-by-context' -and $SkillsApoio -notmatch 'route-skills-by-context') {
  throw 'route-skills-by-context deve constar como candidata, executora ou apoio.'
}

$txt = Get-Content -LiteralPath $SessaoPath -Raw
$linesToEnsure = @(
  "- Chamado: $ChamadoId",
  "- Skills candidatas: $SkillsCandidatas",
  "- Skill executora: $SkillExecutora",
  "- Skills de apoio: $SkillsApoio",
  "- Motivo da escolha: $Motivo"
)

foreach($l in $linesToEnsure){
  $field = ($l -split ':')[0]
  $pattern = '(?im)^' + [regex]::Escape($field) + ':.*$'
  if ([regex]::IsMatch($txt,$pattern)) {
    $txt = [regex]::Replace($txt,$pattern,$l)
  } else {
    $txt += "`r`n$l"
  }
}

Set-Content -LiteralPath $SessaoPath -Value $txt -Encoding utf8

[pscustomobject]@{
  SessaoPath=$SessaoPath
  ChamadoId=$ChamadoId
  ChamadoPath=$chamadoPath
  ChamadoStatus=$chamadoStatus
  SkillExecutora=$SkillExecutora
  BootstrapValido=$true
}
