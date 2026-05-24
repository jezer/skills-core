BeforeAll {
    $script:ValidateScript = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\validate-skills.ps1"
}

Describe "validate-skills.ps1" {
    It "existe e tem param() declarado" {
        Test-Path $script:ValidateScript | Should -BeTrue
        (Get-Content -LiteralPath $script:ValidateScript -Raw) | Should -Match "(?ms)^\s*param\s*\("
    }

    It "executa em uma sandbox temporaria sem erro" {
        $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) "validate-skills-sandbox-$([guid]::NewGuid())"
        $skillDir = Join-Path $sandbox "skill-falsa"
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        $valid = "---`nname: skill-falsa`ndescription: skill apenas para teste, sem proposito real e com texto suficientemente longo.`n---`n# falsa`n"
        [System.IO.File]::WriteAllText((Join-Path $skillDir "SKILL.md"), $valid, (New-Object System.Text.UTF8Encoding($false)))
        try {
            $out = (& powershell -NoProfile -File $script:ValidateScript -SkillsRoot $sandbox -ContinueOnError 2>&1) -join "`n"
            $out | Should -Match "Resumo da validacao"
            $out | Should -Match "Validas:\s+1"
        } finally {
            Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
