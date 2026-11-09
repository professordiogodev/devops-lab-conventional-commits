#!/usr/bin/env bash
# Creates the Clippy repository with its messy history in ./sandbox/clippy (safe to re-run: starts over).
set -euo pipefail
cd "$(dirname "$0")"
rm -rf sandbox; mkdir -p sandbox/clippy; cd sandbox/clippy
git init -q -b main; git config user.name "Clippy Team"; git config user.email team@clippy.dev; git config commit.gpgsign false
n=0
c() { n=$((n+1)); echo "$n: $1" >> history.txt; git add -A; git commit -q -m "$1"; }
echo "1.0.0" > VERSION
c "Initial commit"
c "feat: add /shorten endpoint"
c "fix: reject urls without scheme"
git tag -a v1.0.0 -m "1.0.0"
c "feat(redirect): add /r/{code}"
c "feat(stats): add /stats"
git tag -a v1.2.0 -m "1.2.0"
c "feat(api): add custom aliases"
c "fix: handle empty url"
c "fix(redirect): return 404 for unknown code"
c "docs: update README"
c "wip"
c "chore(deps): bump fastapi"
c "feat(stats)!: rename fields in /stats response"
c "fix stuff"
echo
echo "Done. Repository: $(pwd)"
echo "Tag v1.2.0 is the last release; commits after it are unreleased."
git log --oneline v1.2.0..HEAD
