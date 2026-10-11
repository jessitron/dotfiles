---
name: honeycomb-whoami
description: >
  Use when you have a Honeycomb API key (or ingest key) and need to find out
  which Honeycomb endpoint, team, and environment it belongs to. Trigger phrases: "what team does this Honeycomb key
  belong to", "check that the MCP is connected to the right team", "which environment is this key for", 
  "honeycomb whoami", "identify a Honeycomb API key", "where
  do my events go"
metadata:
  version: "1.0.0"
---

# Honeycomb whoami: identify the team + environment behind a key

Given a Honeycomb API key (configuration key or ingest key), this skill tells you:

- which Honeycomb deployment the key belongs to (production, dogfood, kibble; US or EU),
- the **team slug** and **environment slug**,
- the permissions on that key
- a UI URL for that environment, useful for "where will my traces show up".

## TL;DR

```bash
curl -s -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
     https://api.honeycomb.io/1/auth | jq
```

Useful fields on the response (the script only uses `team.slug` and `environment.slug`, but you may want more):

- `team.slug`, `team.name`
- `environment.slug`, `environment.name` (only present for ingest keys / env-scoped keys)
- `api_key_access` — booleans for `events`, `markers`, `triggers`, `boards`, `queries`, etc. Tells you what the key is allowed to do. Useful for diagnosing 403s before you hit them.

Give the user a link to the environment: `https://${ui_host}/${team_slug}/environments/${env_slug}/`

## For more details

See the script `honeycomb-whoami.sh` in this directory. It loops through all known Honeycomb API hosts, calls /1/auth with the provided key, and looks for a non-null `team.slug` in the response to identify which deployment the key belongs to.

The first endpoint that returns a non-null `team.slug` wins — that's the deployment the key belongs to. The response also includes `environment.slug`. The script prints a UI URL of the form `https://${ui_host}/${team_slug}/environments/${env_slug}/` and exits.

If no endpoint accepts the key, it prints "Key not recognized by any Honeycomb endpoint."

## Things to watch for

- **Classic keys** (legacy, no environment) return a `team` but no `environment`. The script will print `null` as the env slug and the UI URL will be malformed. If you see that, the key is a classic key — events go straight to the team's datasets without an environment layer.
- This auth endpoint works for ingest keys and configuration keys, but NOT management keys. Management keys can be distinguished by a : between the ID and Secret portions of the key, and by an 'm' in the 5-letter key prefix. There is no way to find out what team a management key belongs to.
- The script depends on `curl` and `jq`. If `jq` isn't installed, parsing the team slug will fail silently and every endpoint will look invalid.
- Keys are sensitive. Don't paste them into shared channels or commit them. Pass via env var when possible.
