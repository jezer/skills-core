BeforeAll {
    $script:Common = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\_planos-comum.ps1"
    . $script:Common
}

Describe "_planos-comum helpers" {
    Context "To-KebabCase" {
        It "remove acentos e mantem hifens" {
            $entrada = "Migra" + [char]0x00E7 + [char]0x00E3 + "o de Cabe" + [char]0x00E7 + "alho"
            To-KebabCase $entrada | Should -Be "migracao-de-cabecalho"
        }
        It "trata underscore como separador" {
            To-KebabCase "skill_conectar_github_gitlab" | Should -Be "skill-conectar-github-gitlab"
        }
        It "trata camelCase como separador" {
            To-KebabCase "IAsSemTravas" | Should -Be "ias-sem-travas"
        }
        It "remove .md no fim" {
            To-KebabCase "exemplo.md" | Should -Be "exemplomd"
        }
        It "retorna string vazia para entrada so com simbolos" {
            To-KebabCase "@@!!" | Should -Be ""
        }
    }

    Context "Format-PlanNumber" {
        It "pad com 6 digitos" {
            Format-PlanNumber -Number 1   | Should -Be "000001"
            Format-PlanNumber -Number 42  | Should -Be "000042"
            Format-PlanNumber -Number 999999 | Should -Be "999999"
        }
    }

    Context "Write-Utf8NoBom" {
        It "escreve arquivo sem BOM UTF-8" {
            $tmp = New-TemporaryFile
            try {
                Write-Utf8NoBom -Path $tmp.FullName -Content "ola mundo"
                $bytes = [System.IO.File]::ReadAllBytes($tmp.FullName)
                $bytes[0] | Should -Not -Be 0xEF
                ([Text.Encoding]::UTF8.GetString($bytes)) | Should -Be "ola mundo"
            } finally { Remove-Item $tmp.FullName -Force }
        }
    }

    Context "Resolve-DonoFromPath" {
        It "retorna root para C:\codes\plan" {
            Resolve-DonoFromPath -PlanDirPath "C:\codes\plan" | Should -Be "root"
        }
        It "retorna empresa para C:\codes\pv\plan" {
            Resolve-DonoFromPath -PlanDirPath "C:\codes\pv\plan" | Should -Be "pv"
        }
        It "retorna empresa/projeto para C:\codes\pv\semaforo\plan" {
            Resolve-DonoFromPath -PlanDirPath "C:\codes\pv\semaforo\plan" | Should -Be "pv/semaforo"
        }
    }
}
