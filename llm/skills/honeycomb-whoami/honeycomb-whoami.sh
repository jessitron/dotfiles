#!/bin/bash

# Each entry is "name|api_host|ui_host"
ENDPOINTS=(
  "production|api.honeycomb.io|ui.honeycomb.io"
  "dogfood|api-dogfood.honeycomb.io|ui-dogfood.honeycomb.io"
  "kibble|api-kibble.honeycomb.io|ui-kibble.honeycomb.io"
  "production EU|api.eu1.honeycomb.io|ui.eu1.honeycomb.io"
  "dogfood EU|api.dogfood-eu1.honeycomb.io|ui.dogfood-eu1.honeycomb.io"
  "kibble EU|api.kibble-eu1.honeycomb.io|ui.kibble-eu1.honeycomb.io"
)

honeycomb-whoami() {
  local api_key="$1"
  if [ -z "$api_key" ]; then
    if [ -n "$HONEYCOMB_API_KEY" ]; then
      api_key="$HONEYCOMB_API_KEY"
      echo "No argument provided, using HONEYCOMB_API_KEY env var (${api_key:0:4}...)"
    else
      echo "Usage: $0 <api-key>"
      echo "  or set HONEYCOMB_API_KEY environment variable"
      return 1
    fi
  fi

  for entry in "${ENDPOINTS[@]}"; do
    IFS='|' read -r name api_host ui_host <<< "$entry"

    # The Key Line
    response=$(curl -s -f -H "X-Honeycomb-Team: $api_key" \
                     "https://${api_host}/1/auth" 2>/dev/null)

    if [ $? -ne 0 ]; then
      echo "  ✗ ${name} (${api_host})"
      continue
    fi

    team_slug=$(echo "$response" | jq -r '.team.slug')
    env_slug=$(echo "$response" | jq -r '.environment.slug')

    if [ "$team_slug" = "null" ] || [ -z "$team_slug" ]; then
      echo "  ✗ ${name} (${api_host})"
      continue
    fi

    echo "  ✓ ${name} (${api_host})"
    env_url="https://${ui_host}/${team_slug}/environments/${env_slug}/"
    echo "Look for traces in: $env_url"
    return 0
  done

  echo "Key not recognized by any Honeycomb endpoint."
  return 1
}

honeycomb-whoami "$@"
