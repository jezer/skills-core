param(
    [Parameter(Mandatory=$true)][string]$Titulo,
    [Parameter(Mandatory=$true)][string]$Dono,
    [int]$Prioridade = 999,
    [string]$Chamado,
    [string[]]$SkillsRelacionadas
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

# Plano 000130 do all_IA (casos 7-A/8-A): a API do banco de planos e o caminho
# PRINCIPAL; com o backend fora do ar a skill segue no fluxo local de arquivos
# (fallback) e o proximo sync reconcilia. ALLIA_FROM_API=1 indica que esta
# execucao veio da propria API (anti-recursao: vai direto ao fluxo local).
if (-not $env:ALLIA_FROM_API) {
    $apiBase = if ($env:ALLIA_API_URL) { $env:ALLIA_API_URL } else { "http://localhost:8000" }
    $body = @{ titulo = $Titulo; dono = $Dono; prioridade = $Prioridade }
    if ($Chamado) { $body.chamado = $Chamado }
    if ($SkillsRelacionadas) { $body.skills_relacionadas = @($SkillsRelacionadas) }
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$apiBase/plans/workspace/criar" `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 4))) -TimeoutSec 150
        Write-Host "Via API all_IA: $($resp.saida_script)"
        return
    } catch {
        Write-Host "API all_IA indisponivel - seguindo no fluxo local de arquivos. ($($_.Exception.Message))"
    }
}

$slug = To-KebabCase -Text $Titulo
if (-not $slug) { throw "Titulo gera slug vazio: $Titulo" }

$num = Get-NextPlanNumber
$numStr = Format-PlanNumber -Number $num

$planDir = Resolve-PlanDirByDono -Dono $Dono
if (-not (Test-Path -LiteralPath $planDir)) {
    New-Item -ItemType Directory -Path $planDir -Force | Out-Null
}

$planoFolder = Join-Path $planDir "$numStr-$slug"
if (Test-Path -LiteralPath $planoFolder) {
    throw "Pasta ja existe: $planoFolder"
}
New-Item -ItemType Directory -Path $planoFolder -Force | Out-Null

$hoje = (Get-Date).ToString("yyyy-MM-dd")
$usuarioAtual = Get-CurrentUser
$skillsLine = if ($SkillsRelacionadas) { ($SkillsRelacionadas -join ", ") } else { "" }

$template = @"
# $numStr - $Titulo

- Numero: $numStr
- Titulo: $Titulo
- Dono: $Dono
- Usuario atual: $usuarioAtual
- Prioridade: $Prioridade
- Status: em-andamento
- Criado em: $hoje
- Atualizado em: $hoje
- Chamado: $Chamado
- Skills relacionadas: $skillsLine

## Objetivo

(descrever o objetivo)

## Escopo

(escopo)

## Atividades

| # | Atividade | Status | Skill executora | Saida |
|---|---|---|---|---|
| A1 | ... | pendente | ... | ... |

## Criterios de aceite

1. ...

## Skills recomendadas atuais

- ...

## Riscos

- ...
"@

Write-Utf8NoBom -Path (Join-Path $planoFolder "plano.md") -Content $template

Write-Host "Plano criado: $planoFolder"

# Regenera indice do usuario corrente
& (Join-Path $PSScriptRoot "atualizar-indice-planos.ps1") -Usuario $usuarioAtual
