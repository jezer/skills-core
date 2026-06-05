param(
    [Parameter(Mandatory=$true)][string]$Titulo,
    [Parameter(Mandatory=$true)][string]$Dono,
    [int]$Prioridade = 999,
    [string]$Chamado,
    [string[]]$SkillsRelacionadas
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

# Plano 000134 do all_IA (casos 1-A/2-A/6-A): o BANCO e a fonte - a API cria
# o plano (numeracao do banco) e GERA os espelhos (pasta + plano.md + indice).
# OFFLINE = somente leitura + FILA: a criacao vai para a fila local com numero
# PROVISORIO e e aplicada na drenagem quando o backend voltar (caso 6-A).
# ALLIA_FROM_API=1 = execucao disparada pela propria API (anti-recursao).
if (-not $env:ALLIA_FROM_API) {
    $body = @{ titulo = $Titulo; dono = $Dono; prioridade = $Prioridade; usuario = (Get-CurrentUser) }
    if ($Chamado) { $body.chamado = $Chamado }
    if ($SkillsRelacionadas) { $body.skills_relacionadas = @($SkillsRelacionadas) }
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$(Get-AllIAApiBase)/plans/workspace/criar" `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Depth 4))) -TimeoutSec 150
        Write-Host "Via API all_IA: $($resp.saida_script)"
        return
    } catch {
        $provisorio = "PROV-" + ("{0:D6}" -f (Get-NextPlanNumber))
        $body.numero_provisorio = $provisorio
        $arquivo = Add-FilaOffline -Op "criar-plano" -Payload $body
        Write-Host "API all_IA indisponivel - criacao ENFILEIRADA (numero provisorio $provisorio)."
        Write-Host "Fila: $arquivo (drenada automaticamente quando o backend voltar, ou via POST /plans/fila/drenar)."
        return
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
