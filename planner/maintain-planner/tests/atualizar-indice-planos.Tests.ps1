BeforeAll {
    $script:Script = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\atualizar-indice-planos.ps1"
}

Describe "atualizar-indice-planos.ps1" {
    It "rodando -DryRun nao falha e mostra proximo_numero" {
        $out = (& powershell -NoProfile -File $script:Script -Usuario jz -DryRun 2>&1) -join "`n"
        $out | Should -Match "em_andamento_total"
        $out | Should -Match "proximo_numero"
    }
}
