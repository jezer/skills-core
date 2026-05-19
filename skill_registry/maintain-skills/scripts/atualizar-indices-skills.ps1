param(
    [ValidateSet("Update", "Validate")]
    [string]$Mode = "Validate",
    [string]$SkillsRoot = "C:\codes\skills",
    [string]$IndicesPath = "C:\codes\skills\indices"
)

$ErrorActionPreference = "Stop"

function Read-SkillMetadata {
    param([string]$SkillPath)

    $skillFile = Join-Path $SkillPath "SKILL.md"
    $lines = Get-Content -LiteralPath $skillFile
    if ($lines.Count -lt 3 -or $lines[0] -ne "---") {
        throw "Frontmatter ausente em $skillFile"
    }

    $end = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "---") {
            $end = $i
            break
        }
    }

    if ($end -lt 0) {
        throw "Frontmatter nao fechado em $skillFile"
    }

    $metadata = @{}
    for ($i = 1; $i -lt $end; $i++) {
        if ($lines[$i] -match "^([^:]+):\s*(.*)$") {
            $metadata[$matches[1].Trim()] = $matches[2].Trim()
        }
    }

    if (-not $metadata.ContainsKey("name") -or [string]::IsNullOrWhiteSpace($metadata["name"])) {
        throw "Campo name ausente em $skillFile"
    }

    if (-not $metadata.ContainsKey("description") -or [string]::IsNullOrWhiteSpace($metadata["description"])) {
        throw "Campo description ausente em $skillFile"
    }

    [pscustomobject]@{
        Name = $metadata["name"]
        Description = $metadata["description"]
        Path = $SkillPath
        SkillFile = $skillFile
    }
}

function Get-ContextosForSkill {
    param([string]$Name)

    $map = @{
        "configure-machine-default-skill" = @("root", "skills")
        "maintain-agents" = @("root", "agents")
        "maintain-activities" = @("planejamento")
        "maintain-automations" = @("skills", "automacoes")
        "maintain-tickets" = @("ctrl_chamados", "chamados")
        "maintain-filesystem" = @("root", "file_system")
        "maintain-git" = @("git")
        "maintain-planner" = @("planejamento")
        "maintain-skills" = @("skills")
        "powershell-specialist" = @("skills", "automacoes")
        "python-specialist" = @("skills", "automacoes")
        "technical-writer" = @("skills")
        "visual-storytelling" = @("skills")
        "presentation-designer" = @("skills")
        "architecture-diagrammer" = @("skills")
        "ui-infographic-generator" = @("skills")
        "periodic-skills-reviewer" = @("skills", "planejamento")
        "register-ticket-session" = @("ctrl_chamados", "chamados")
        "route-skills-by-context" = @("root", "skills", "planejamento")
    }

    if ($map.ContainsKey($Name)) {
        return $map[$Name]
    }

    @("skills")
}

function Get-SkillEntries {
    param([string]$SkillsRoot)

    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        throw "SkillsRoot nao encontrado: $SkillsRoot"
    }

    Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter SKILL.md |
        Where-Object {
            $_.FullName -notmatch "\\gemini\\" -and
            $_.FullName -notmatch "\\dist\\" -and
            $_.FullName -notmatch "\\plan\\" -and
            $_.FullName -notmatch "\\indices\\"
        } |
        ForEach-Object { Get-Item -LiteralPath $_.DirectoryName } |
        Sort-Object FullName -Unique |
        ForEach-Object {
            $metadata = Read-SkillMetadata -SkillPath $_.FullName
            [pscustomobject]@{
                name = $metadata.Name
                description = $metadata.Description
                path = $metadata.Path
                skill_file = $metadata.SkillFile
                contextos = @(Get-ContextosForSkill -Name $metadata.Name)
            }
        }
}

function Get-AliasMap {
    @{
        "root" = @("maintain-agents", "maintain-filesystem")
        "ctrl_chamados" = @("maintain-tickets", "register-ticket-session")
        "chamados" = @("maintain-tickets", "register-ticket-session")
        "file_system" = @("maintain-filesystem")
        "regras_file_system" = @("maintain-filesystem")
        "planejamento" = @("maintain-planner", "maintain-activities")
        "planos" = @("maintain-planner")
        "atividades" = @("maintain-activities")
        "skills" = @("maintain-skills")
        "automacoes" = @("maintain-automations")
        "git" = @("maintain-git")
        "agents" = @("maintain-agents")
        "roteamento_skills" = @("route-skills-by-context")
    }
}

function Get-ContextoMap {
    @{
        "root" = @{
            regra = "C:\codes\AGENTS.md"
            skills = @("maintain-agents", "maintain-filesystem")
        }
        "skills" = @{
            regra = "C:\codes\skills\AGENTS.md"
            skills = @("maintain-skills", "maintain-automations")
        }
        "ctrl_chamados" = @{
            regra = "C:\codes\tools\chamados\AGENTS.md"
            skills = @("maintain-tickets", "register-ticket-session")
        }
        "planejamento" = @{
            regra = "C:\codes\tools\planejador\AGENTS.md"
            skills = @("maintain-planner", "maintain-activities")
        }
        "git" = @{
            regra = "C:\codes\tools\git\AGENTS.md"
            skills = @("maintain-git")
        }
        "file_system" = @{
            regra = "C:\codes\pv\regras_file_system"
            skills = @("maintain-filesystem")
        }
        "automacoes" = @{
            regra = "C:\codes\skills\AGENTS.md"
            skills = @("maintain-automations")
        }
        "agents" = @{
            regra = "C:\codes\AGENTS.md"
            skills = @("maintain-agents")
        }
        "roteamento" = @{
            regra = "C:\codes\plan\root-hierarquia-contextos-responsabilidades-skills\README.md"
            skills = @("route-skills-by-context")
        }
    }
}

function Write-JsonFile {
    param(
        [string]$Path,
        [object]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Assert-JsonFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Indice nao encontrado: $Path"
    }

    $null = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Test-References {
    param(
        [array]$SkillEntries,
        [hashtable]$AliasMap,
        [hashtable]$ContextoMap
    )

    $skillNames = @($SkillEntries | ForEach-Object { $_.name })
    $errors = @()

    foreach ($entry in $SkillEntries) {
        if (-not (Test-Path -LiteralPath $entry.skill_file)) {
            $errors += "SKILL.md inexistente para $($entry.name): $($entry.skill_file)"
        }
        if (-not ($entry.skill_file -like "C:\codes\*")) {
            $errors += "Caminho fora de C:\codes para $($entry.name): $($entry.skill_file)"
        }
    }

    foreach ($alias in $AliasMap.Keys) {
        foreach ($skill in $AliasMap[$alias]) {
            if ($skillNames -notcontains $skill) {
                $errors += "Alias $alias aponta para skill inexistente: $skill"
            }
        }
    }

    foreach ($contexto in $ContextoMap.Keys) {
        foreach ($skill in $ContextoMap[$contexto]["skills"]) {
            if ($skillNames -notcontains $skill) {
                $errors += "Contexto $contexto aponta para skill inexistente: $skill"
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw ($errors -join [Environment]::NewLine)
    }
}

$entries = @(Get-SkillEntries -SkillsRoot $SkillsRoot)
$aliases = Get-AliasMap
$contextos = Get-ContextoMap

if ($Mode -eq "Update") {
    New-Item -ItemType Directory -Path $IndicesPath -Force | Out-Null
    $generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

    Write-JsonFile -Path (Join-Path $IndicesPath "skills-index.json") -Value ([pscustomobject]@{
        generated_at = $generatedAt
        source = "C:\codes\skills"
        regra = "Auxiliar de descoberta; SKILL.md continua fonte principal."
        skills = $entries
    })

    Write-JsonFile -Path (Join-Path $IndicesPath "aliases.json") -Value ([pscustomobject]@{
        generated_at = $generatedAt
        regra = "Aliases auxiliares para descoberta; nao substituem AGENTS.md."
        aliases = $aliases
    })

    Write-JsonFile -Path (Join-Path $IndicesPath "contexto-map.json") -Value ([pscustomobject]@{
        generated_at = $generatedAt
        regra = "Mapa auxiliar de contexto para skills; consultar regras especificas antes de agir."
        contextos = $contextos
    })
}

Assert-JsonFile -Path (Join-Path $IndicesPath "skills-index.json")
Assert-JsonFile -Path (Join-Path $IndicesPath "aliases.json")
Assert-JsonFile -Path (Join-Path $IndicesPath "contexto-map.json")
Test-References -SkillEntries $entries -AliasMap $aliases -ContextoMap $contextos

[pscustomobject]@{
    Mode = $Mode
    Skills = $entries.Count
    IndicesPath = $IndicesPath
    Valid = $true
}

