#!/usr/bin/env pwsh
# count_sources.ps1 — Windows PowerShell equivalent of count_sources.sh.
# Count non-generated source files to drive the Step 2 layering decision.
#
# Usage:
#   powershell -File scripts/count_sources.ps1 [ROOT]                 # ROOT defaults to "."
#   $env:CODEMAP_EXCLUDE='regex'; powershell -File scripts/count_sources.ps1 [ROOT]
#
# Prints the non-generated source-file count, a per-extension breakdown, and a
# layering hint (<=50 -> single-layer, >50 -> two-layer). The exclude lists below
# are best-effort defaults across common stacks, not exhaustive — override per project
# with CODEMAP_EXCLUDE when a generated path slips through.

param(
    [string]$Root = "."
)

# Dependency / build-output / VCS dirs — never hand-written source. [\\/] matches both separators.
$excludeDirs = '[\\/](\.git|node_modules|vendor|dist|build|out|target|coverage|__pycache__|\.venv|venv|\.next|\.nuxt|\.idea|\.vscode|bin|obj)[\\/]'
# Generated / lock / minified files.
$excludeFiles = '(\.gen\.go|\.pb\.go|_pb2\.py|\.min\.(js|css)|-lock\.(json|ya?ml)|\.lock|\.map)$|[\\/]migrations?[\\/]'
# Source extensions worth counting.
$ext = '\.(go|py|js|jsx|ts|tsx|vue|java|kt|rb|rs|php|c|h|cc|cpp|hpp|cs|swift|scala|m|sh|sql)$'
# Optional project-specific extra exclude pattern.
$extra = $env:CODEMAP_EXCLUDE

$files = @(Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -cmatch $ext -and $_.FullName -cnotmatch $excludeDirs -and $_.FullName -cnotmatch $excludeFiles })

if ($extra) {
    $files = @($files | Where-Object { $_.FullName -cnotmatch $extra })
}

$count = $files.Count
Write-Host "Non-generated source files under '$Root': $count"
Write-Host ""
Write-Host "By extension:"
$files | ForEach-Object { $_.Extension } | Group-Object | Sort-Object Count -Descending |
    ForEach-Object { ("{0,6} {1}" -f $_.Count, $_.Name) }
Write-Host ""
if ($count -le 50) {
    Write-Host "Layering hint: <=50 -> single-layer mode (one CODEMAP.md)"
}
else {
    Write-Host "Layering hint: >50 -> two-layer mode (top-level + per-module CODEMAP-<module>.md)"
}
