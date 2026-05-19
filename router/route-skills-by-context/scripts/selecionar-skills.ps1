param(
    [ValidateSet("planejamento", "execucao-tecnica", "estrutura-contexto", "git-publicacao", "chamados-rastreabilidade")]
    [string]$TipoAtividade,
    [ValidateSet("pv", "syg", "cnu", "theo", "elohim", "skills", "tools", "root")]
    [string]$Empresa = "root",
    [string]$Projeto = ""
)

$ErrorActionPreference = "Stop"

$basicas = @("route-skills-by-context")
$apoio = @("maintain-planner")
$empresaSkills = @()
$projetoSkills = @()

switch ($TipoAtividade) {
    "planejamento" {
        $apoio += @("maintain-activities")
    }
    "execucao-tecnica" {
        $apoio += @("maintain-activities")
    }
    "estrutura-contexto" {
        $apoio += @("maintain-agents", "maintain-filesystem", "maintain-activities")
    }
    "git-publicacao" {
        $apoio += @("maintain-git", "maintain-activities")
    }
    "chamados-rastreabilidade" {
        $apoio += @("maintain-tickets", "register-ticket-session")
    }
}

if ($Empresa -ne "root") {
    $empresaSkills += @("maintain-activities")
}

if (-not [string]::IsNullOrWhiteSpace($Projeto)) {
    $projetoSkills += @("maintain-activities")
}

$projetoNorm = $Projeto.ToLowerInvariant()
$eventoInventario = (
    $projetoNorm -match 'nova-empresa|novo-projeto|indice-repositorios|inventario|sincronizacao-indice|sincronizar-indice'
)
if ($eventoInventario) {
    $apoio += @("sync-repositories-index")
}

$skills = @($basicas + $empresaSkills + $projetoSkills + $apoio | Select-Object -Unique)

[pscustomobject]@{
    TipoAtividade = $TipoAtividade
    Empresa = $Empresa
    Projeto = $Projeto
    SkillsBasicas = $basicas
    SkillsEmpresa = $empresaSkills
    SkillsProjeto = $projetoSkills
    SkillsApoio = $apoio
    SkillsEleitas = $skills
}

