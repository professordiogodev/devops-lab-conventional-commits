#!/usr/bin/env bash
rc=0
for f in hooks/commit-msg changelog.sh next-version.sh; do
  if [ -f "$f" ] && bash -n "$f" 2>/dev/null; then echo "- ✅ $f exists and is valid bash"
  else echo "- ❌ $f is missing or has a syntax error"; rc=1; fi
done
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
