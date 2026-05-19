# Gera C:\codes\skills\skills.json com metadados de cada skill
$skillsRoot = 'C:\codes\skills'
$out = Join-Path $skillsRoot 'skills.json'
$skills = @()
Get-ChildItem -Path $skillsRoot -Directory | ForEach-Object {
    $name = $_.Name
    $path = $_.FullName
    $lastFile = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $last = if ($lastFile) { $lastFile.LastWriteTime } else { $_.LastWriteTime }
    $fileHashes = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { try { (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash } catch { '' } }
    $combined = ($fileHashes | Sort-Object) -join ''
    if ($combined -ne '') {
        $shaBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combined))
        $signature = ($shaBytes | ForEach-Object { $_.ToString('x2') }) -join ''
    } else { $signature = '' }
    $skills += [PSCustomObject]@{
        id = $name
        name = $name
        path = $path
        last_updated = $last
        signature = $signature
    }
}
$skills | ConvertTo-Json -Depth 4 | Set-Content -Path $out -Encoding UTF8
Write-Host "Wrote $out"