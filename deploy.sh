#!/usr/bin/env bash
# Republish ILP Studio: copy the vault copy of index.html into this repo,
# commit if it changed, and push. GitHub Pages redeploys in ~30-60s.
#
#   bash /c/Users/dripr/code/ilp-studio/deploy.sh
#
# Source of truth: the vault file. Edit there, run this, done.
set -euo pipefail

SRC="/c/Users/dripr/hermes/Obsidian Vault/Raw/Code/ilp-calculator/index.html"
REPO="/c/Users/dripr/code/ilp-studio"
SLUG="Lurkeyteg/ilp-studio"
LIVE="https://lurkeyteg.github.io/ilp-studio/"

[ -f "$SRC" ] || { echo "missing source: $SRC"; exit 1; }
cd "$REPO"

cp "$SRC" ./index.html

if git diff --quiet -- index.html; then
  echo "No changes since the last publish — $LIVE is already current."
  exit 0
fi

git add index.html
git commit -q -m "Update ILP Studio ($(date +%Y-%m-%d\ %H:%M))"

# Push without leaving credentials in .git/config, and without a GUI prompt.
export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never
TOK=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')
[ -n "$TOK" ] || { echo "no GitHub credential available — run 'git push' once by hand to sign in"; exit 1; }

git -c credential.helper= push -q "https://Lurkeyteg:${TOK}@github.com/${SLUG}.git" HEAD:main
unset TOK

echo "Pushed. Waiting for Pages to rebuild…"
for i in $(seq 1 15); do
  sleep 8
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Cache-Control: no-cache" "$LIVE")
  if [ "$CODE" = "200" ]; then
    if curl -s "$LIVE" | grep -q "$(grep -o 'sheet parity' "$SRC" | head -1)"; then
      echo "Live and serving the new copy: $LIVE"
      exit 0
    fi
    echo "  …200 but still the old copy (CDN cache); give it another minute."
  else
    echo "  …HTTP $CODE"
  fi
done
echo "Pushed, but the CDN has not refreshed yet. Check $LIVE in a minute."
