#!/usr/bin/env bash
# Wrapper that demonstrates the Claude Code hooks contract:
#   - run the policy check and propagate its exit code with `|| exit $?`
#   - start any background metrics upload with stdout/stderr redirected so it
#     cannot keep the hook's pipe open and turn an allow into a block
#   - never use `set -e` here: the wrapper's job is to propagate, not abort
set +e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$DIR/hook_runner.py" --json || exit $?
# Background work: redirect both streams so the hook's stdout is closed.
"$DIR/upload_metrics.sh" >/dev/null 2>&1 &
exit 0
