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
# product welcome-bonus tables shown in the app
for f in "$(dirname "$SRC")"/wb-*.png; do [ -f "$f" ] && cp "$f" ./; done

CHANGED=0
if ! git diff --quiet -- index.html wb-*.png; then CHANGED=1; fi

if [ "$CHANGED" = "1" ]; then
  git add index.html wb-*.png 2>/dev/null || git add index.html
  git commit -q -m "Update ILP Studio ($(date +%Y-%m-%d\ %H:%M))"
else
  echo "No file changes — checking whether the repo still needs pushing."
fi

# Push without leaving credentials in .git/config, and without a GUI prompt.
export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never
# `git credential fill` can come back empty on this machine (GCM helper-selector);
# reading GCM directly is the reliable path.
# GCM direct first: `git credential fill` can BLOCK on this machine, so it is
# tried second and always under a timeout.
TOK=""
if command -v git-credential-manager >/dev/null 2>&1; then
  TOK=$(printf 'protocol=https\nhost=github.com\n\n' | timeout 20 git-credential-manager get 2>/dev/null | sed -n 's/^password=//p')
fi
if [ -z "$TOK" ]; then
  TOK=$(printf 'protocol=https\nhost=github.com\n\n' | timeout 20 git credential fill 2>/dev/null | sed -n 's/^password=//p')
fi
[ -n "$TOK" ] || { echo "no GitHub credential available — run 'git push' once by hand to sign in"; exit 1; }

git -c credential.helper= push -q "https://Lurkeyteg:${TOK}@github.com/${SLUG}.git" HEAD:main

# The repo is PRIVATE: GitHub Pages only serves public repos on a free plan, so
# there is no live site to verify. If it is ever made public again, check for a
# published Pages site and wait for the rebuild.
PAGES=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${TOK}" "https://api.github.com/repos/${SLUG}/pages")
if [ "$PAGES" != "200" ]; then
  echo "Pushed. Repo is private — no public site (Pages needs a public repo)."
  exit 0
fi

echo "Pushed. Waiting for Pages to rebuild…"
for i in $(seq 1 15); do
  sleep 8
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Cache-Control: no-cache" "$LIVE")
  if [ "$CODE" = "200" ]; then
    echo "Live: $LIVE"
    exit 0
  fi
  echo "  …HTTP $CODE"
done
echo "Pushed, but the CDN has not refreshed yet. Check $LIVE in a minute."
