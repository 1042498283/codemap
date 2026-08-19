#!/usr/bin/env pwsh
# where.ps1 — Windows PowerShell equivalent of where.sh.
# Resolve the CURRENT line number(s) of a symbol's definition in a file.
#
# CODEMAP stores only "file + symbol name" — stable, never goes stale. When you want a
# line number to jump to, compute it FRESH with this script rather than trusting any
# stored number. The line number becomes a query result, not cached (decayable) data.
#
# Usage:
#   powershell -File scripts/where.ps1 <file> <symbol>
#   e.g. powershell -File scripts/where.ps1 proxy/service/billing_service.go PostConsume
#
# Prints "<line>:<source>" for each definition-style match (Go/TS/JS/Python/Vue/Java-ish).
# If no definition is found, falls back to listing every occurrence of the symbol.

param(
    [Parameter(Mandatory = $true, Position = 0)][string]$File,
    [Parameter(Mandatory = $true, Position = 1)][string]$Sym
)

if (-not (Test-Path -Path $File -PathType Leaf)) {
    Write-Error "no such file: $File"
    exit 1
}

# Read as UTF-8 (source files are UTF-8 in Go/Python/TS); avoids mojibake for Chinese comments.
$lines = Get-Content -Path $File -Encoding UTF8
$esc = [regex]::Escape($Sym)
# Identifier boundary (matches where.sh's B='[^A-Za-z0-9_]').
$b = '[^A-Za-z0-9_]'

# Definition-style patterns (same intent as where.sh):
#   func [(recv)] Name( | function/def/class/type/interface Name | const/let/var Name = | Name(...) { (method)
$defPattern = "(func|function|def|class|type|interface)\s+(\([^)]*\)\s*)?$esc($b|$)|(const|let|var)\s+$esc\s*=|(^|$b)$esc\s*\([^)]*\)\s*\{"

$defs = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    # -cmatch is case-sensitive, matching grep's default behaviour.
    if ($lines[$i] -cmatch $defPattern) {
        $defs += ("{0}:{1}" -f ($i + 1), $lines[$i])
    }
}

if ($defs.Count -gt 0) {
    $defs
}
else {
    Write-Host "(no definition match for '$Sym' - all occurrences:)"
    $allPattern = "(^|$b)$esc($b|$)"
    $all = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -cmatch $allPattern) {
            $all += ("{0}:{1}" -f ($i + 1), $lines[$i])
        }
    }
    if ($all.Count -gt 0) {
        $all
    }
    else {
        Write-Host "  symbol not found in $File"
    }
}
