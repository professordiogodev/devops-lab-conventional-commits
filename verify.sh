#!/usr/bin/env bash
# Checks your hook and scripts. Run with: ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"
ROOT=$(pwd); SB="$ROOT/sandbox/clipstr"
[ -d "$SB/.git" ] || { echo "Run ./setup.sh first"; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
msgok() { local f; f=$(mktemp); printf '%s\n' "$1" > "$f"; "$ROOT/hooks/commit-msg" "$f" >/dev/null 2>&1; local r=$?; rm -f "$f"; return $r; }
accepts() { msgok "$1"; }
rejects() { ! msgok "$1"; }
tmprepo() { local d; d=$(mktemp -d); git -C "$d" init -q -b main; git -C "$d" config user.name t; git -C "$d" config user.email t@t; git -C "$d" config commit.gpgsign false
  echo 1 > "$d/f"; git -C "$d" add -A; git -C "$d" commit -q -m "feat: start"; git -C "$d" tag -a v1.0.0 -m x; echo "$d"; }
bump() { local d; d=$(tmprepo); local n=0; for m in "$@"; do n=$((n+1)); echo $n >> "$d/f"; git -C "$d" add -A; git -C "$d" commit -q -m "$m"; done; "$ROOT/next-version.sh" "$d" 2>/dev/null | tail -1 | tr -d '[:space:]'; rm -rf "$d"; }

echo "== The hook =="
check "hooks/commit-msg exists and is executable"        test -x hooks/commit-msg
for m in "feat: add qr codes" "fix(api): handle empty body" "docs: update readme" "chore(deps): bump fastapi" "feat(stats)!: rename fields" "refactor: split router" "ci: add lint job"; do
  check "accepts: $m"                                     accepts "$m"; done
for m in "fixed stuff" "wip" "Feat: Capital type" "feat:no space" "feat: " "update" "feature: wrong type" "fix(): empty scope"; do
  check "rejects: $m"                                     rejects "$m"; done
check "the hook is switched on in the sandbox repository" bash -c "[ -x \"\$(git -C '$SB' config core.hooksPath)/commit-msg\" ]"

echo "== changelog.sh =="
out=$(./changelog.sh 2>/dev/null)
check "lists the new features"                           bash -c "grep -q 'add custom aliases' <<< \"$out\""
check "lists the bug fixes"                              bash -c "grep -q 'handle empty url' <<< \"$out\" && grep -q 'return 404 for unknown code' <<< \"$out\""
check "has a BREAKING section with the renamed fields"   bash -c "grep -qi 'breaking' <<< \"$out\" && grep -q 'rename fields' <<< \"$out\""
check "leaves out chore, wip and unstructured commits"   bash -c "! grep -qE 'bump fastapi|^.*wip|fix stuff' <<< \"$out\""
check "only contains commits since the last tag (not v1.0.0 era)" bash -c "! grep -q 'reject urls without scheme' <<< \"$out\""

echo "== next-version.sh =="
check "seeded history (breaking change) gives 2.0.0"     test "$(./next-version.sh 2>/dev/null | tail -1 | tr -d '[:space:]')" = 2.0.0
check "one fix gives 1.0.1"                              test "$(bump 'fix: x')" = 1.0.1
check "a feature and a fix give 1.1.0"                   test "$(bump 'fix: x' 'feat: y')" = 1.1.0
check "a BREAKING CHANGE footer gives 2.0.0"             test "$(bump $'feat: y\n\nBREAKING CHANGE: removes /v1')" = 2.0.0
check "only docs and chore commits give 1.0.0 (no release needed)" test "$(bump 'docs: x' 'chore: y')" = 1.0.0

echo "== Cleaning up the history =="
check "branch 'cleaned' exists in the sandbox"           git -C "$SB" rev-parse --verify -q cleaned
check "every commit on cleaned since v1.2.0 passes your hook" bash -c "cd '$SB' && for h in \$(git rev-list v1.2.0..cleaned); do f=\$(mktemp); git log -1 --format=%B \$h > \$f; '$ROOT/hooks/commit-msg' \$f || exit 1; done"
check "cleaned has the same number of commits as main (you reworded, not dropped)" bash -c "[ \"\$(git -C '$SB' rev-list --count v1.2.0..cleaned)\" = \"\$(git -C '$SB' rev-list --count v1.2.0..main)\" ]"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
