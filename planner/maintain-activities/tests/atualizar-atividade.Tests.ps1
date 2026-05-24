BeforeAll {
    $script:Script = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\atualizar-atividade.ps1"
}

Describe "atualizar-atividade.ps1" {
    It "existe" {
        Test-Path $script:Script | Should -BeTrue
    }
    It "tem param() declarado" {
        (Get-Content -LiteralPath $script:Script -Raw) | Should -Match "(?ms)^\s*param\s*\("
    }
    It "tem ErrorActionPreference = Stop" {
        (Get-Content -LiteralPath $script:Script -Raw) | Should -Match "ErrorActionPreference\s*=\s*[`"']Stop[`"']"
    }
}
