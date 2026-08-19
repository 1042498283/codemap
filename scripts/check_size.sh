#!/usr/bin/env bash
# check_size.sh — report which CODEMAP files exceed the line threshold,
# so the skill knows what to split / offload to keep the top index lean.
#
# Usage:
#   scripts/check_size.sh [DIR] [THRESHOLD]
#     DIR        project root holding CODEMAP.md and .codemap/ (default: .)
#     THRESHOLD  line limit before a file should be split (default: 200)
#
# It scans the top-level CODEMAP*.md plus every .md under .codemap/ (recursive).
# It only REPORTS sizes. Deciding what content moves where — detail into
# .codemap/domains/<domain>/, Change Log entries into CODEMAP-changelog.md
# (single-layer) or each domain's flows.md (two-layer) — is a judgment call
# the skill (Claude) makes from this report; a shell script can't understand
# the business content.

set -uo pipefail

DIR="${1:-.}"
THRESHOLD="${2:-200}"

shopt -s nullglob
files=()
for f in "$DIR"/CODEMAP*.md; do
  files+=("$f")
done
if [ -d "$DIR/.codemap" ]; then
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$DIR/.codemap" -type f -name '*.md' 2>/dev/null)
fi

if [ ${#files[@]} -eq 0 ]; then
  echo "No CODEMAP files found under '$DIR' (checked CODEMAP*.md and .codemap/**/*.md)."
  exit 0
fi

over=0
printf '%-52s %7s  %s\n' "FILE" "LINES" "STATUS"
printf '%-52s %7s  %s\n' "----" "-----" "------"
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  n="$(wc -l < "$f" | tr -d ' ')"
  if [ "$n" -gt "$THRESHOLD" ]; then
    printf '%-52s %7s  OVER (> %s)\n' "$f" "$n" "$THRESHOLD"
    over=$((over + 1))
  else
    printf '%-52s %7s  ok\n' "$f" "$n"
  fi
done

echo
if [ "$over" -gt 0 ]; then
  echo "$over file(s) over the ${THRESHOLD}-line threshold. Offload, keeping <!-- manual --> blocks verbatim:"
  echo "  - top CODEMAP.md over threshold -> move detail into .codemap/domains/<domain>/"
  echo "  - domain flows.md over threshold -> split call chains into sub-docs"
  echo "  - Change Log entries            -> CODEMAP-changelog.md (single-layer)"
  echo "                                     or the owning domain flows.md (two-layer), <=20 entries each"
else
  echo "All within threshold — no split needed."
fi
