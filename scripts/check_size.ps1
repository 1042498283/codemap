#!/usr/bin/env pwsh
# check_size.ps1 — Windows PowerShell equivalent of check_size.sh.
# Report which CODEMAP files exceed the line threshold, so the skill knows what
# to split / offload to keep the top index lean.
#
# Usage:
#   powershell -File scripts/check_size.ps1 [DIR] [THRESHOLD]
#     DIR        project root holding CODEMAP.md and .codemap/ (default: .)
#     THRESHOLD  line limit before a file should be split (default: 200)
#
# It scans the top-level CODEMAP*.md plus every .md under .codemap/ (recursive).
# It only REPORTS sizes. Deciding what content moves where is a judgment call
# the skill makes from this report; a shell script can't understand the business content.

param(
    [string]$Dir = ".",
    [int]$Threshold = 200
)

$files = @(Get-ChildItem -Path $Dir -Filter "CODEMAP*.md" -File -ErrorAction SilentlyContinue)
$codemapDir = Join-Path $Dir ".codemap"
if (Test-Path -Path $codemapDir -PathType Container) {
    $files += @(Get-ChildItem -Path $codemapDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue)
}

if ($files.Count -eq 0) {
    Write-Host "No CODEMAP files found under '$Dir' (checked CODEMAP*.md and .codemap/**/*.md)."
    exit 0
}

$over = 0
"{0,-52} {1,7}  {2}" -f "FILE", "LINES", "STATUS"
"{0,-52} {1,7}  {2}" -f "----", "-----", "------"
foreach ($f in $files) {
    $n = @(Get-Content -Path $f.FullName).Count
    if ($n -gt $Threshold) {
        "{0,-52} {1,7}  OVER (> {2})" -f $f.FullName, $n, $Threshold
        $over++
    }
    else {
        "{0,-52} {1,7}  ok" -f $f.FullName, $n
    }
}

Write-Host ""
if ($over -gt 0) {
    Write-Host "$over file(s) over the ${Threshold}-line threshold. Offload, keeping <!-- manual --> blocks verbatim:"
    Write-Host "  - top CODEMAP.md over threshold -> move detail into .codemap/domains/<domain>/"
    Write-Host "  - domain flows.md over threshold -> split call chains into sub-docs"
    Write-Host "  - Change Log entries            -> CODEMAP-changelog.md (single-layer)"
    Write-Host "                                     or the owning domain flows.md (two-layer), <=20 entries each"
}
else {
    Write-Host "All within threshold - no split needed."
}
