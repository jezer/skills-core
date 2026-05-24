BeforeAll {
    $script:Script = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\selecionar-skills.ps1"
}

Describe "selecionar-skills.ps1" {
    It "existe e e .ps1" {
        Test-Path $script:Script | Should -BeTrue
        $script:Script | Should -Match "\.ps1$"
    }

    It "tem bloco param() declarado" {
        $conteudo = Get-Content -LiteralPath $script:Script -Raw
        $conteudo | Should -Match "(?ms)^\s*param\s*\("
    }
}
