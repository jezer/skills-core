param(
    [string]$SessaoPath,
    [switch]$AutoResolve,
    [string]$ChamadosRoot = 'C:\codes\tools\chamados\chamados'
)

$ErrorActionPreference = 'Stop'

if ($AutoResolve -and [string]::IsNullOrWhiteSpace($SessaoPath)) {
    $files = Get-ChildItem -LiteralPath $ChamadosRoot -Recurse -File -Filter *.md |
      Where-Object { $_.FullName -match '\\sessoes\\(pendentes|feitas)\\' } |
      Sort-Object LastWriteTime -Descending
    if ($files.Count -eq 0) { throw 'Nenhuma sessao encontrada para AutoResolve.' }
    $SessaoPath = $files[0].FullName
}

if ([string]::IsNullOrWhiteSpace($SessaoPath)) {
    throw 'Informe SessaoPath ou use -AutoResolve.'
}

if (-not (Test-Path -LiteralPath $SessaoPath)) {
    throw "Sessao nao encontrada: $SessaoPath"
}

$txt = Get-Content -LiteralPath $SessaoPath -Raw

function Get-FieldValue {
    param([string]$Content,[string]$FieldName)
    $pattern = "(?im)^\-\s*" + [regex]::Escape($FieldName) + "\s*:\s*(.+?)\s*$"
    $m = [regex]::Match($Content, $pattern)
    if (-not $m.Success) { return '' }
    return $m.Groups[1].Value.Trim()
}

$candidatas = Get-FieldValue -Content $txt -FieldName 'Skills candidatas'
$executora = Get-FieldValue -Content $txt -FieldName 'Skill executora'
$apoio = Get-FieldValue -Content $txt -FieldName 'Skills de apoio'
$motivo = Get-FieldValue -Content $txt -FieldName 'Motivo da escolha'

$faltando = @()
if ([string]::IsNullOrWhiteSpace($candidatas) -or $candidatas -eq 'PREENCHER') { $faltando += 'Skills candidatas' }
if ([string]::IsNullOrWhiteSpace($executora) -or $executora -eq 'PREENCHER') { $faltando += 'Skill executora' }
if ([string]::IsNullOrWhiteSpace($apoio) -or $apoio -eq 'PREENCHER') { $faltando += 'Skills de apoio' }
if ([string]::IsNullOrWhiteSpace($motivo) -or $motivo -eq 'PREENCHER') { $faltando += 'Motivo da escolha' }

if ($faltando.Count -gt 0) {
    throw ('Sessao sem roteamento completo. Campos pendentes: ' + ($faltando -join ', '))
}

$temRoteador = ($candidatas -match '(^|,|\s)route-skills-by-context($|,|\s)') -or ($executora -eq 'route-skills-by-context') -or ($apoio -match '(^|,|\s)route-skills-by-context($|,|\s)')
if (-not $temRoteador) {
    throw 'Sessao invalida para atividade persistente: route-skills-by-context nao foi registrado como candidato/executora/apoio.'
}

[pscustomobject]@{
    Sessao = $SessaoPath
    RoteamentoValido = $true
    SkillsCandidatas = $candidatas
    SkillExecutora = $executora
    SkillsApoio = $apoio
}
