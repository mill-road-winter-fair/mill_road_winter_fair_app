$path = Join-Path $PSScriptRoot '..\coverage\lcov.info'
if (-not (Test-Path $path)) { Write-Output "lcov.info not found at $path"; exit 1 }
$lines = Get-Content $path -ErrorAction Stop
$lf = ($lines | Where-Object { $_ -match '^LF:' } | ForEach-Object { [int]($_ -replace '^LF:', '') } | Measure-Object -Sum).Sum
$lh = ($lines | Where-Object { $_ -match '^LH:' } | ForEach-Object { [int]($_ -replace '^LH:', '') } | Measure-Object -Sum).Sum
Write-Output "LF=$lf LH=$lh"
if ($lf -and $lf -ne 0) { $pct = [math]::Round(($lh / $lf * 100), 2); Write-Output "Pct=${pct}%" } else { Write-Output 'No lines found' }

