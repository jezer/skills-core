$script:WorkspaceRoot = "C:\codes"
$script:RootPlanDir   = Join-Path $script:WorkspaceRoot "plan"

function Get-CurrentUser {
    $personalizado = Join-Path $script:WorkspaceRoot "personalizado.md"
    if (Test-Path -LiteralPath $personalizado) {
        $line = (Get-Content -LiteralPath $personalizado) | Where-Object { $_ -match "Usuario atual:" } | Select-Object -First 1
        if ($line) {
            $m = [regex]::Match($line, "Usuario atual:\s*(\S+)")
            if ($m.Success) { return $m.Groups[1].Value.Trim().ToLower() }
        }
    }
    return $env:USERNAME.ToLower()
}

function To-KebabCase {
    param([string]$Text)
    $t = $Text.ToLower()
    $t = [Text.RegularExpressions.Regex]::Replace($t, "[^a-z0-9\s\-]", "")
    $t = [Text.RegularExpressions.Regex]::Replace($t, "\s+", "-")
    $t = [Text.RegularExpressions.Regex]::Replace($t, "-+", "-")
    return $t.Trim("-")
}

function Resolve-PlanDirByDono {
    param([Parameter(Mandatory=$true)][string]$Dono)
    # Dono e um de: root | <empresa> | <empresa>/<projeto> | skill | tools/<tool> | skill/<skill_name>
    $d = $Dono.Trim('/').Trim('\').Replace('\','/')
    if ($d -ieq "root") {
        return $script:RootPlanDir
    }
    $segments = $d.Split('/')
    $contextPath = Join-Path $script:WorkspaceRoot ($segments -join '\')
    return (Join-Path $contextPath "plan")
}

function Find-AllPlanDirs {
    $result = @()
    Get-ChildItem -LiteralPath $script:WorkspaceRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "plan" -and $_.FullName -notmatch "\\node_modules\\" -and $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\__pycache__\\" } |
        ForEach-Object { $result += $_.FullName }
    return $result
}

function Find-AllPlanFolders {
    # Retorna pastas no formato NNNNNN-titulo em qualquer plan/ (raiz, concluido/, descartado/)
    $found = @()
    $rx = [regex]"^(?<num>\d{6})-(?<slug>.+)$"
    foreach ($planDir in Find-AllPlanDirs) {
        foreach ($sub in @("", "concluido", "descartado")) {
            $target = if ($sub) { Join-Path $planDir $sub } else { $planDir }
            if (-not (Test-Path -LiteralPath $target)) { continue }
            Get-ChildItem -LiteralPath $target -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $rx } |
                ForEach-Object {
                    $m = $rx.Match($_.Name)
                    $status = if ($sub -eq "concluido") { "concluido" }
                              elseif ($sub -eq "descartado") { "descartado" }
                              else { "em-andamento" }
                    $found += [pscustomobject]@{
                        Numero      = $m.Groups["num"].Value
                        Slug        = $m.Groups["slug"].Value
                        Status      = $status
                        Caminho     = $_.FullName
                        PlanDir     = $planDir
                    }
                }
        }
    }
    return $found
}

function Get-NextPlanNumber {
    $all = Find-AllPlanFolders
    if (-not $all -or $all.Count -eq 0) { return 1 }
    $max = ($all | ForEach-Object { [int]$_.Numero } | Measure-Object -Maximum).Maximum
    return ($max + 1)
}

function Format-PlanNumber {
    param([int]$Number)
    return ("{0:D6}" -f $Number)
}

function Resolve-DonoFromPath {
    param([string]$PlanDirPath)
    $rel = [System.IO.Path]::GetRelativePath($script:WorkspaceRoot, $PlanDirPath)
    $rel = $rel.Replace('\','/')
    if ($rel -ieq "plan") { return "root" }
    # remover trailing /plan
    $rel = $rel -replace "/plan$", ""
    return $rel
}

function Read-PlanoFrontmatter {
    param([string]$PlanoPath)
    if (-not (Test-Path -LiteralPath $PlanoPath)) { return $null }
    $lines = Get-Content -LiteralPath $PlanoPath
    $meta = @{}
    foreach ($l in $lines) {
        $m = [regex]::Match($l, "^- (?<k>[^:]+):\s*(?<v>.*)$")
        if ($m.Success) {
            $meta[$m.Groups["k"].Value.Trim()] = $m.Groups["v"].Value.Trim()
        }
    }
    return $meta
}
