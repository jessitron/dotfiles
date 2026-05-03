#!/usr/bin/env bash
# Verify the assumptions documented in SKILL.md against the live Honeycomb API.
# Reads HONEYCOMB_API_KEY from the .be file at the repo root.
#
# Usage:
#   ./verify.sh

set -u
set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
# shellcheck disable=SC1090
source "$REPO_ROOT/.be"

DATASET="skill-test-events-api"
URL="https://api.honeycomb.io/1/events/$DATASET"

run() {
  local label="$1"
  shift
  echo "=== $label ==="
  "$@"
  echo
  echo
}

basic_send() {
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"source":"verify.sh","case":"basic","value":1}' | head -10
}

with_event_time() {
  local ts
  ts=$(date -u -v-5M +%s)
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    -H "X-Honeycomb-Event-Time: $ts" \
    -H "X-Honeycomb-Samplerate: 1" \
    -H "Content-Type: application/json" \
    -d '{"source":"verify.sh","case":"with-event-time","note":"5 min ago"}' | head -10
}

empty_body() {
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    -H "Content-Type: application/json" \
    -d '' | head -10
}

nested_json() {
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"flat":"top","nested":{"inner_a":1,"inner_b":"hi"}}' | head -10
}

bad_key() {
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: not-a-real-key" \
    -H "Content-Type: application/json" \
    -d '{"x":1}' | head -10
}

ms_in_event_time_header() {
  # SKILL.md claims X-Honeycomb-Event-Time wants seconds, not ms.
  # Send a millisecond value and see whether Honeycomb complains.
  local ts_ms
  ts_ms=$(($(date +%s) * 1000))
  curl -sS -i -X POST "$URL" \
    -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
    -H "X-Honeycomb-Event-Time: $ts_ms" \
    -H "Content-Type: application/json" \
    -d '{"source":"verify.sh","case":"ms-in-header"}' | head -10
}

run "basic single event" basic_send
run "with X-Honeycomb-Event-Time + Samplerate" with_event_time
run "empty body (expect 400)" empty_body
run "nested JSON (does Honeycomb flatten?)" nested_json
run "bad key (expect 401)" bad_key
run "milliseconds in X-Honeycomb-Event-Time (expect: silently treated as future epoch?)" ms_in_event_time_header
