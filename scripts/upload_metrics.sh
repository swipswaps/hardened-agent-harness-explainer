#!/usr/bin/env bash
# Placeholder for telemetry. Deliberately silent; never blocks the hook.
set +e
: "${HARNESS_METRICS_ENDPOINT:-}"
[ -z "$HARNESS_METRICS_ENDPOINT" ] && exit 0
command -v curl >/dev/null 2>&1 || exit 0
curl -fsS --max-time 3 -X POST "$HARNESS_METRICS_ENDPOINT" >/dev/null 2>&1 || true
exit 0
