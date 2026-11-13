#!/usr/bin/env bash
# Publish ILP Studio to GitHub Pages (public link) or take it back private.
#
#   bash publish.sh            # make the repo public, enable Pages, push, verify the link
#   bash publish.sh retract    # make it private again and kill the link
#
# GitHub Pages only serves public repos on a free plan, so a shareable link and a
# private repo are mutually exclusive here. Anyone with the link can also read the
# page source — that is true of any static host.
set -uo pipefail

REPO="/c/Users/dripr/code/ilp-studio"
SRC="/c/Users/dripr/hermes/Obsidian Vault/Raw/Code/ilp-calculator"
SLUG="Lurkeyteg/ilp-studio"
LIVE="https://lurkeyteg.github.io/ilp-studio/"
API="https://api.github.com/repos/${SLUG}"

export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never

get_token(){
  # GCM direct first: `git credential fill` can BLOCK on this machine while the
  # helper-selector decides whether to prompt. Always bound it.
  local t
  if command -v git-credential-manager >/dev/null 2>&1; then
    t=$(printf 'protocol=https\nhost=github.com\n\n' | timeout 20 git-credential-manager get 2>/dev/null | sed -n 's/^password=//p')
  fi
  if [ -z "$t" ]; then
    t=$(printf 'protocol=https\nhost=github.com\n\n' | timeout 20 git credential fill 2>/dev/null | sed -n 's/^password=//p')
  fi
  printf '%s' "$t"
}
TOK=$(get_token)
[ -n "$TOK" ] || { echo "no GitHub credential found"; exit 1; }

auth(){ curl -s -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" "$@"; }

if [ "${1:-}" = "retract" ]; then
  auth -X PATCH "$API" -d '{"private":true}' | grep -q '"private": true' \
    && echo "Repo is private again."
  sleep 3
  echo "link now: $(curl -s -o /dev/null -w '%{http_code}' "$LIVE")   (404 = off the internet)"
  exit 0
fi

cd "$REPO" || exit 1

# ---- 1. publish the current copy ----
for f in "$SRC"/wb-*.png; do [ -f "$f" ] && cp "$f" ./; done
cp "$SRC/index.html" ./index.html
if ! git diff --quiet -- index.html wb-*.png; then
  git add index.html wb-*.png 2>/dev/null || git add index.html
  git commit -q -m "Publish ILP Studio ($(date +%Y-%m-%d\ %H:%M))"
fi

# ---- 2. public + pages ----
auth -X PATCH "$API" -d '{"private":false}' | grep -q '"private": false' \
  || { echo "could not make the repo public"; exit 1; }
echo "Repo is public."

CODE=$(auth -o /dev/null -w '%{http_code}' "$API/pages")
if [ "$CODE" = "404" ]; then
  auth -X POST "$API/pages" -d '{"source":{"branch":"main","path":"/"}}' >/dev/null
  echo "Pages enabled."
else
  echo "Pages already enabled."
fi

# ---- 3. push ----
git -c credential.helper= push -q "https://Lurkeyteg:${TOK}@github.com/${SLUG}.git" HEAD:main \
  && echo "Pushed." || { echo "push failed"; exit 1; }

# ---- 4. wait for the link, then prove it serves the latest copy ----
echo "Waiting for Pages to build…"
for i in $(seq 1 20); do
  sleep 10
  C=$(curl -s -o /dev/null -w '%{http_code}' -H 'Cache-Control: no-cache' "$LIVE")
  if [ "$C" = "200" ]; then
    curl -s "$LIVE" -o "$LOCALAPPDATA/Temp/live.html"
    if cmp -s <(tr -d '\r' < "$LOCALAPPDATA/Temp/live.html") <(tr -d '\r' < "$SRC/index.html"); then
      echo "LIVE and matching the local copy: $LIVE"
      rm -f "$LOCALAPPDATA/Temp/live.html"; exit 0
    fi
    echo "  …200, but still serving the previous copy (CDN); waiting."
  else
    echo "  …HTTP $C"
  fi
done
echo "Built, but the CDN has not caught up. Check $LIVE shortly."
