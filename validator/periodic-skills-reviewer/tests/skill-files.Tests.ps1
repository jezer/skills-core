BeforeAll {
    $script:SkillDir = Split-Path -Parent $PSScriptRoot
}

Describe "periodic-skills-reviewer structure" {
    It "tem SKILL.md" {
        Test-Path (Join-Path $script:SkillDir "SKILL.md") | Should -BeTrue
    }
    It "SKILL.md valido (sem BOM, frontmatter ok)" {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $script:SkillDir "SKILL.md"))
        $bytes[0] | Should -Not -Be 0xEF
        $head = [Text.Encoding]::UTF8.GetString($bytes[0..3])
        $head | Should -Match "^---"
    }
}
