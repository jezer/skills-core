param(
    [string]$Usuario,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_planos-comum.ps1")

if (-not $Usuario) { $Usuario = Get-CurrentUser }

$all = @(Find-AllPlanFolders)
$emAndamento = @($all | Where-Object { $_.Status -eq "em-andamento" })
$maxNum = if ($all.Count -gt 0) { [int]((($all | ForEach-Object { [int]$_.Numero }) | Measure-Object -Maximum).Maximum) } else { 0 }

$planos = @()
foreach ($p in $emAndamento | Sort-Object { [int]$_.Numero }) {
    $planoMd = Join-Path $p.Caminho "plano.md"
    $meta = Read-PlanoFrontmatter -PlanoPath $planoMd
    $dono = Resolve-DonoFromPath -PlanDirPath $p.PlanDir
    $empresa = $null; $projeto = $null; $skill = $null
    if ($dono -ne "root") {
        $parts = $dono.Split('/')
        if ($parts[0] -eq "skills") {
            $skill = if ($parts.Count -gt 1) { $parts[1] } else { "" }
        } elseif ($parts[0] -eq "tools") {
            $empresa = "tools"
            $projeto = if ($parts.Count -gt 1) { $parts[1] } else { $null }
        } else {
            $empresa = $parts[0]
            $projeto = if ($parts.Count -gt 1) { ($parts[1..($parts.Count-1)] -join '/') } else { $null }
        }
    }
    $planos += [pscustomobject]@{
        numero               = $p.Numero
        titulo               = if ($meta.Titulo) { $meta.Titulo } else { ($p.Slug -replace '-', ' ') }
        caminho              = ($p.Caminho -replace '\\','/')
        dono                 = $dono
        empresa              = $empresa
        projeto              = $projeto
        skill                = $skill
        prioridade           = if ($meta.Prioridade) { [int]$meta.Prioridade } else { 999 }
        status               = $p.Status
        criado_em            = $meta["Criado em"]
        atualizado_em        = $meta["Atualizado em"]
        chamado              = $meta.Chamado
        skills_relacionadas  = if ($meta["Skills relacionadas"]) { ($meta["Skills relacionadas"] -split ',') | ForEach-Object { $_.Trim() } } else { @() }
    }
}

$indice = [pscustomobject]@{
    generated_at        = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    workspace_root      = ($script:WorkspaceRoot -replace '\\','/')
    usuario             = $Usuario
    em_andamento_total  = $planos.Count
    proximo_numero      = ($maxNum + 1)
    planos              = $planos
}

$jsonPath = Join-Path $script:RootPlanDir "indice-planos-$Usuario.json"
$mdPath   = Join-Path $script:RootPlanDir "indice-planos-$Usuario.md"

$json = $indice | ConvertTo-Json -Depth 6

$mdLines = @()
$mdLines += "# Indice de planos - usuario $Usuario"
$mdLines += ""
$mdLines += "- Gerado em: $($indice.generated_at)"
$mdLines += "- Em andamento: $($indice.em_andamento_total)"
$mdLines += "- Proximo numero: $($indice.proximo_numero)"
$mdLines += ""
if ($planos.Count -gt 0) {
    $mdLines += "| Numero | Titulo | Dono | Prioridade | Chamado | Caminho |"
    $mdLines += "|---|---|---|---:|---|---|"
    foreach ($p in ($planos | Sort-Object prioridade, numero)) {
        $mdLines += "| $($p.numero) | $($p.titulo) | $($p.dono) | $($p.prioridade) | $($p.chamado) | $($p.caminho) |"
    }
} else {
    $mdLines += "Nenhum plano em andamento."
}

if ($DryRun) {
    Write-Host "[DryRun] em_andamento_total=$($indice.em_andamento_total) proximo_numero=$($indice.proximo_numero)"
    Write-Host $json
    return
}

Set-Content -LiteralPath $jsonPath -Value $json -Encoding UTF8
Set-Content -LiteralPath $mdPath   -Value ($mdLines -join "`n") -Encoding UTF8

Write-Host "Indice salvo: $jsonPath"
Write-Host "Markdown:     $mdPath"
Write-Host "em_andamento_total=$($indice.em_andamento_total) proximo_numero=$($indice.proximo_numero)"
