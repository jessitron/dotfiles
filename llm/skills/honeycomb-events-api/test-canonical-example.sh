#!/usr/bin/env bash
# Run the canonical example from SKILL.md against the live API,
# exactly as written. Then print the event_id so I can verify
# arrival via the Honeycomb MCP using the same event_id filter
# the skill recommends.
#
# Usage:
#   ./test-canonical-example.sh

set -u
set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
# shellcheck disable=SC1090
source "$REPO_ROOT/.be"

DATASET="skill-test-events-api"
export DATASET

# This block is copy-pasted from SKILL.md "Always include an event ID"
EVENT_ID=$(uuidgen)
echo "Sending event with event_id=$EVENT_ID"
curl -fsS -i -X POST "https://api.honeycomb.io/1/events/$DATASET" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc --arg id "$EVENT_ID" '{event_id:$id, event:"deploy_finished", exit_code:0}')"

echo
echo "EVENT_ID for verification: $EVENT_ID"
