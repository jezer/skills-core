param(
    [Parameter(Mandatory=$true)][string]$Titulo,
    [Parameter(Mandatory=$true)][string]$Dono,
    [int]$Prioridade = 999,
    [string]$Chamado,
    [string[]]$SkillsRelacionadas
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

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
$skillsLine = if ($SkillsRelacionadas) { ($SkillsRelacionadas -join ", ") } else { "" }

$template = @"
# $numStr - $Titulo

- Numero: $numStr
- Titulo: $Titulo
- Dono: $Dono
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

Set-Content -LiteralPath (Join-Path $planoFolder "plano.md") -Value $template -Encoding UTF8

Write-Host "Plano criado: $planoFolder"

# Regenera indice do usuario corrente
$user = Get-CurrentUser
& (Join-Path $PSScriptRoot "atualizar-indice-planos.ps1") -Usuario $user
