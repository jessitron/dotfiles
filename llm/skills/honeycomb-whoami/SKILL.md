---
name: honeycomb-whoami
description: >
  Use when you have a Honeycomb API key (or ingest key) and need to find out
  which Honeycomb endpoint, team, and environment it belongs to. Probes each
  Honeycomb deployment (production, dogfood, kibble; US and EU) by calling
  /1/auth and reports the matching team slug, environment slug, and a UI URL
  for that environment. Trigger phrases: "what team does this Honeycomb key
  belong to", "which environment is this key for", "is this key for dogfood
  or production", "honeycomb whoami", "identify a Honeycomb API key", "where
  do my events go", "which Honeycomb endpoint should I use", "look up a
  Honeycomb key".
metadata:
  version: "1.0.0"
---

# Honeycomb whoami: identify the team + environment behind a key

Given a Honeycomb API key (configuration key or ingest key), this skill tells you:

- which Honeycomb deployment the key belongs to (production, dogfood, kibble; US or EU),
- the **team slug** and **environment slug**,
- a UI URL for that environment, useful for "where will my traces show up".

Use this before sending events when you only know the key — so you point at the right `api.*` host and verify in the right UI.

## How it works

The script tries each known Honeycomb endpoint in turn:

| Deployment   | API host                          | UI host                          |
| ------------ | --------------------------------- | -------------------------------- |
| production   | `api.honeycomb.io`                | `ui.honeycomb.io`                |
| dogfood      | `api-dogfood.honeycomb.io`        | `ui-dogfood.honeycomb.io`        |
| kibble       | `api-kibble.honeycomb.io`         | `ui-kibble.honeycomb.io`         |
| production EU| `api.eu1.honeycomb.io`            | `ui.eu1.honeycomb.io`            |
| dogfood EU   | `api.dogfood-eu1.honeycomb.io`    | `ui.dogfood-eu1.honeycomb.io`    |
| kibble EU    | `api.kibble-eu1.honeycomb.io`     | `ui.kibble-eu1.honeycomb.io`     |

For each one, it calls:

```
GET https://${api_host}/1/auth
  X-Honeycomb-Team: <api-key>
```

The first endpoint that returns a non-null `team.slug` wins — that's the deployment the key belongs to. The response also includes `environment.slug`. The script prints a UI URL of the form `https://${ui_host}/${team_slug}/environments/${env_slug}/` and exits.

If no endpoint accepts the key, it prints "Key not recognized by any Honeycomb endpoint."

## Running the script

The script is bundled with this skill at `./honeycomb-whoami.sh`. Two ways to invoke it:

**With key as argument:**

```bash
./honeycomb-whoami.sh <api-key>
```

**Via env var:**

```bash
HONEYCOMB_API_KEY=<api-key> ./honeycomb-whoami.sh
```

A successful run looks like:

```
  ✗ production (api.honeycomb.io)
  ✓ dogfood (api-dogfood.honeycomb.io)
Look for traces in: https://ui-dogfood.honeycomb.io/my-team/environments/my-env/
```

The leading `✗` lines are normal — they're endpoints the key isn't valid for. The `✓` line is the answer.

## When you need the script vs. when you can call /1/auth directly

If you already know which deployment the key is for, skip the script and just call `/1/auth` on that one host:

```bash
curl -s -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
     https://api.honeycomb.io/1/auth | jq
```

Use the script when you **don't** know which deployment (US vs EU, prod vs dogfood vs kibble). It's the fastest way to tell.

## What `/1/auth` returns

Useful fields on the response (the script only uses `team.slug` and `environment.slug`, but you may want more):

- `team.slug`, `team.name`
- `environment.slug`, `environment.name` (only present for ingest keys / env-scoped keys)
- `api_key_access` — booleans for `events`, `markers`, `triggers`, `boards`, `queries`, etc. Tells you what the key is allowed to do. Useful for diagnosing 403s before you hit them.

## Things to watch for

- **Classic keys** (legacy, no environment) return a `team` but no `environment`. The script will print `null` as the env slug and the UI URL will be malformed. If you see that, the key is a classic key — events go straight to the team's datasets without an environment layer.
- **Network failures vs auth failures** look the same in the script's output (a `✗`). If every endpoint shows `✗`, sanity-check connectivity before concluding the key is bad.
- The script depends on `curl` and `jq`. If `jq` isn't installed, parsing the team slug will fail silently and every endpoint will look invalid.
- Keys are sensitive even when they're ingest-only. Don't paste them into shared channels or commit them. Pass via env var when possible.
