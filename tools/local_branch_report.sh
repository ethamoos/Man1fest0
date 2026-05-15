#!/usr/bin/env bash
set -euo pipefail

cd '/Users/adeane/Git/ethamoos/Jamf Projects/Man1fest0/'
printf "Analyzing local branches vs main in %s\n" "$(pwd)"

# determine main ref
MAIN=""
if git rev-parse --verify origin/main >/dev/null 2>&1; then MAIN=origin/main
elif git rev-parse --verify origin/master >/dev/null 2>&1; then MAIN=origin/master
elif git rev-parse --verify main >/dev/null 2>&1; then MAIN=main
elif git rev-parse --verify master >/dev/null 2>&1; then MAIN=master
else
  echo "Could not determine a main branch to compare against."; exit 2
fi
printf "Using main ref: %s\n" "$MAIN"
OUT=~/Desktop/Man1fest0_local_branch_report_$(date +%Y%m%d_%H%M%S).txt
printf "Man1fest0 local branch report\nGenerated: %s\nRepository: %s\nMain: %s\n\n" "$(date -u +"%Y-%m-%d %H:%M:%S UTC")" "$(pwd)" "$MAIN" > "$OUT"

printf "Local branches with commits ahead of main (>=1)\n\n" >> "$OUT"

for ref in $(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads); do
  branch="$ref"
  # skip main branch equivalent
  if [ "$branch" = "$(echo $MAIN | sed 's@origin/@@')" ]; then continue; fi
  last=$(git log -1 --pretty=format:'%ci | %cn | %h | %s' "$branch" 2>/dev/null || echo "<no commits>")
  ahead=$(git rev-list --count "$MAIN".."$branch" 2>/dev/null || echo 0)
  behind=$(git rev-list --count "$branch".."$MAIN" 2>/dev/null || echo 0)
  shortstat=$(git diff --shortstat "$MAIN"..."$branch" 2>/dev/null || true)
  files_changed=0; insertions=0; deletions=0
  if [ -n "$shortstat" ]; then
    files_changed=$(echo "$shortstat" | sed -n 's/.*, \([0-9]\+\) file.*/\1/p')
    files_changed=${files_changed:-0}
    insertions=$(echo "$shortstat" | sed -n 's/.*, \([0-9]\+\) insertion.*/\1/p')
    insertions=${insertions:-0}
    deletions=$(echo "$shortstat" | sed -n 's/.*, \([0-9]\+\) deletion.*/\1/p')
    deletions=${deletions:-0}
  fi
  if [ "$ahead" -ge 1 ] || [ "$files_changed" -ge 1 ] || [ $((insertions + deletions)) -ge 1 ]; then
    printf "Branch: %s\nLast commit: %s\nCommits ahead of main: %s\nCommits behind main: %s\nFiles changed: %s | +%s -%s\n---\n\n" "$branch" "$last" "$ahead" "$behind" "$files_changed" "$insertions" "$deletions" >> "$OUT"
  fi
done

if [ ! -s "$OUT" ]; then printf "No local branches appear to be ahead of %s\n" "$MAIN" >> "$OUT"; fi

cat "$OUT"
