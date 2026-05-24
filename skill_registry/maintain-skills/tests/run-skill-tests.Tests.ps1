BeforeAll {
    $script:Runner = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\run-skill-tests.ps1"
}

Describe "run-skill-tests.ps1" {
    It "existe e tem param() declarado" {
        Test-Path $script:Runner | Should -BeTrue
        (Get-Content -LiteralPath $script:Runner -Raw) | Should -Match "(?ms)^\s*param\s*\("
    }
    It "tem ErrorActionPreference Stop" {
        (Get-Content -LiteralPath $script:Runner -Raw) | Should -Match "ErrorActionPreference\s*=\s*[`"']Stop[`"']"
    }
    It "documenta parametros -Skill -Path -NoPython" {
        $c = Get-Content -LiteralPath $script:Runner -Raw
        $c | Should -Match "\[string\]\`$Skill"
        $c | Should -Match "\[string\]\`$Path"
        $c | Should -Match "\[switch\]\`$NoPython"
    }
}
