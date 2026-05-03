---
name: honeycomb-events-api
description: >
  Use when the user wants to send a single, targeted event to Honeycomb without
  OpenTelemetry — via the raw HTTP Events API. This is for one-off events, not bulk telemetry. 
  Trigger phrases: "send an event directly to Honeycomb",
  "Honeycomb Events API", "POST to /events", "send a Honeycomb event from
  curl/lambda/script", "synchronous event to
  Honeycomb",
  "skip OpenTelemetry but still send to Honeycomb".
metadata:
  version: "1.0.0"
---

# Honeycomb Events API: send a single event without OpenTelemetry

This skill is for sending **individual, targeted events** to Honeycomb over plain HTTP. Examples of the right fit:

- A Lambda function recording its outcome before exiting.
- A shell script logging "deploy started", "deploy finished", "backup ran".
- A business event ("user upgraded", "invoice settled") that doesn't belong with general request telemetry.
- An audit log entry written to its own dataset.
- A one-shot event from a tool, CLI, or scheduled job.

For bulk service telemetry (every HTTP request, every span), use OpenTelemetry instead. This API is intentionally simple and synchronous — those properties are great for individual events and bad for high volume.

## Endpoint

```
POST https://api.honeycomb.io/1/events/{dataset}
```

EU customers: `https://api.eu1.honeycomb.io/1/events/{dataset}`. Or if the team is in Dogfood, `https://api-dogfood.honeycomb.io/1/events/{dataset}`.

`{dataset}` is the dataset slug (case-insensitive). Honeycomb auto-creates the dataset on first write.

> Honeycomb's docs note that this single-event endpoint is "highly discouraged for anything more than testing." That guidance is about **throughput** — for bulk telemetry, use OTel. For individual targeted events, this endpoint is exactly what you want.

## Authentication

Send the key in the `X-Honeycomb-Team` header.

- **Use an Ingest Key** (prefix `hcaik_`). Create one in Honeycomb under _Environment Settings → API Keys_. Scoped to a single environment, can only send events.
- Configuration keys also work if they have "Send Events" but they're more dangerous.
- On backend, read the key from an environment variable or secret store. Ingest keys are low-security and can be exposed in code if needed, such as in client-side web apps.

## Minimal request

Use any HTTP library to send these. Examples are given in curl for generic application.

```bash
curl -fsS -X POST "https://api.honeycomb.io/1/events/$DATASET" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"event":"deploy_finished","service":"api","duration_ms":42,"exit_code":0}'
```

The body is a **flat JSON object**. Each top-level key becomes a column in the dataset.

A successful response is `HTTP 200` with an empty body. Any 4xx is a hard rejection.

## Always include an event ID

**Generate a unique ID for every event, log it, and include it as a field** (e.g. `event_id`). Use a UUID, or any unique-enough string (`$(date +%s%N)`, a ULID, a hash of relevant inputs).

The pattern has three steps, all important:

1. Generate the ID into a variable.
2. Log/print the ID before the request — so the caller, the test command's stdout, the Lambda's CloudWatch log, etc. records what ID went out.
3. Send the event with the ID as a field.

```bash
# 1. generate
EVENT_ID=$(uuidgen)

# 2. log it FIRST, so you have a record even if the request fails or hangs
echo "Sending event with event_id=$EVENT_ID"

# 3. send
curl -fsS -X POST "https://api.honeycomb.io/1/events/$DATASET" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc --arg id "$EVENT_ID" '{event_id:$id, event:"deploy_finished", exit_code:0}')"
```

Step 2 is the part that's easy to forget. **An ID generated in a transient place — a variable that goes out of scope, a UUID inlined into the JSON body — is unverifiable.** If you don't preserve the ID somewhere durable (logs, test stdout, a return value), you have no way to look up the event later. Always emit the ID before or alongside the request.

It costs almost nothing and pays off later:

- **Find this exact event again.** Without an ID, you'd be searching by time + content and hoping it's unique. With one, `event_id = <value>` finds it instantly.
- **Correlate with logs and traces.** If your application also logs the ID (or sets it as a span attribute), you can pivot between the Honeycomb event, your logs, and any related trace.
- **Detect accidental duplicates.** Honeycomb does not dedupe — if you retry on a network error and the first one actually succeeded, you'll have two rows. Same `event_id` on two rows tells you what happened.
- **Deterministic test verification.** When an agent runs the test, it reads the ID off stdout and queries Honeycomb with `event_id = <that value>`. No risk of matching an unrelated event, no race with prior runs, no time-window guessing. See "Verifying events arrived" below for the query.

## Headers

| Header                           | Required | Notes                                                                             |
| -------------------------------- | -------- | --------------------------------------------------------------------------------- |
| `X-Honeycomb-Team`               | yes      | Your ingest key                                                                   |
| `Content-Type: application/json` | yes      | Some clients default to form-encoding — set this explicitly                       |
| `X-Honeycomb-Event-Time`         | no       | Event timestamp as **Unix epoch seconds** (integer). Defaults to API receipt time |
| `X-Honeycomb-Samplerate`         | no       | Integer sample rate, default `1`. Do not set.                                     |

## Body shape: keep it flat

Top-level keys become columns. **Nested objects are not flattened — they are stored as a stringified JSON blob in a single column.** There is a setting in Honeycomb UI to change this, but it's flaky, so it's better to flatten before sending.

Sending this:

```json
{ "flat": "top", "nested": { "inner_a": 1, "inner_b": "hi" } }
```

Produces two columns:

- `flat` (string) = `"top"`
- `nested` (string) = `'{"inner_a":1,"inner_b":"hi"}'`

The inner fields are not queryable as columns. You cannot `GROUP BY nested.inner_a`. **Flatten before sending** — pick the column names you want and put them at the top level (`inner_a`, `inner_b`, or `nested.inner_a`, `nested.inner_b` if you want dotted names).

Other body rules:

- Numbers are 64-bit ints or floats. Booleans are fine. Arrays — same as nested objects, stringified to one column.
- 1 MB max uncompressed body.
- 2,000 distinct columns max per event.
- 64 KB max per string field.

## Timestamps

For "this just happened" events, omit the timestamp and let Honeycomb stamp on receipt. That's almost always right.

Set `X-Honeycomb-Event-Time` when you want to start the event at a specific time. The format is **Unix epoch seconds (integer)**.

> **Footgun:** if you accidentally send milliseconds (e.g. `1777825788000`), the API does not return an error. In testing, Honeycomb appears to coerce the value to seconds (or fall back to receipt time) — but don't rely on that, send seconds. If your event isn't appearing in the expected time window, suspect this header.

Honeycomb retains events for 60 days since receipt, independent of timestamp. But it's hard to see any event that falls in the future or the distant past, so avoid sending timestamps outside the recent 60-day window or the next few minutes.

## Response codes

| Code | Meaning                                                 | What to do                                                              |
| ---- | ------------------------------------------------------- | ----------------------------------------------------------------------- |
| 200  | Accepted                                                | Done                                                                    |
| 400  | Empty body, malformed JSON, oversized, too many columns | Fix the payload                                                         |
| 401  | Bad/missing key                                         | Check `X-Honeycomb-Team`                                                |
| 403  | Throttled administratively                              | Warn the user                                                           |
| 404  | Dataset not found                                       | Tell the user: the key doesn't have create-dataset permission           |
| 429  | Rate limited                                            | Back off and retry                                                      |
| 500  | Server error                                            | Interesting!! Tell the user how to reproduce this, so she can report it |

Retry only on `429`, `5xx`, and network errors. Never retry on other `4xx` — the request is malformed and will fail again.

## Lambda / short-lived process pattern

The whole point of using this API in a Lambda is **synchronous delivery**. Don't fire-and-forget:

1. Build the event.
2. `await` / block on the HTTP response.
3. Check the status code.
4. Only then `return` from the handler.

If you queue events to send later in a background thread, you've reinvented the OTel exporter problem.

## Recipes

**One-liner from a script:**

```bash
curl -fsS -X POST "https://api.honeycomb.io/1/events/$DATASET" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc \
        --arg event "deploy_finished" \
        --arg service "api" \
        --argjson exit_code 0 \
        --argjson duration_ms 42 \
        '{event:$event, service:$service, exit_code:$exit_code, duration_ms:$duration_ms}')"
```

`-fsS` makes curl fail loudly on non-2xx, stay silent on success, and still show errors. Good for scripts.

**Verify a key + dataset round-trip:**

```bash
curl -i -X POST "https://api.honeycomb.io/1/events/skill-test" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"hello":"world"}'
```

`HTTP/2 200` with `content-length: 0` means the event landed. Look for the `skill-test` dataset in Honeycomb.

**From any language:** any HTTP client + JSON serializer is enough. There is no SDK to install. Just `POST` the URL above with the right header and a flat-object JSON body.

## Verifying events arrived (Honeycomb MCP)

After testing, confirm the event actually landed. A `200` from the API only means Honeycomb enqueued the event — there's a small ingest pipeline before it shows up in queries (usually <1s, but worth verifying when you're debugging a new integration).

Use the **local Honeycomb MCP** (tools prefixed `mcp__honeycomb__`). Workspace-specific tools like `mcp__claude_ai_Honeycomb_Dogfood__` are different MCP installs and may point at a different team than your ingest key.

**Step 1: figure out which team and environment the ingest key actually belongs to.** Use the `honeycomb-whoami` skill — it calls `/1/auth` and returns the team slug, environment slug, and Honeycomb deployment (production / dogfood / EU) for the key.

**Step 2: confirm the MCP is pointing at that same team.**

```
mcp__honeycomb__get_workspace_context  (no args)
```

Compare `Team: <name>` in the response against what `honeycomb-whoami` returned. They must match. If they don't, stop — verifying via this MCP won't work; either reconfigure the MCP, use a different MCP install for that team, or check the Honeycomb UI directly. The `honeycomb-whoami` output also includes a UI URL you can hand to the user.

The workspace-context response lists environments under the team. The environment slug should match the one `honeycomb-whoami` returned.

**Step 3: confirm the dataset exists and has been written to recently.** This is the cheapest check — no query, just metadata.

```
mcp__honeycomb__get_dataset_columns
  environment_slug: <env-slug>
  dataset_slug:    <dataset-slug>
```

If the dataset doesn't exist, this returns an error — meaning either (a) writes haven't reached Honeycomb at all, or (b) you're looking at the wrong environment. If it does exist, the columns table includes a `LastWritten` timestamp per column. A recent timestamp on the columns you just sent confirms the event landed.

**Step 4: query for the specific event by ID.** Assuming the event was sent with an `event_id` field (see "Always include an event ID" above) and the test command printed it to stdout, pick up the ID from the test output and:

```
mcp__honeycomb__run_query
  environment_slug: <env-slug>
  dataset_slug:    <dataset-slug>
  include_samples: true
  query_spec: {
    "calculations": [{"op": "COUNT"}],
    "filters":      [{"column": "event_id", "op": "=", "value": "<the-id-from-stdout>"}],
    "time_range":   "10m"
  }
```

A `COUNT` of `1` and a sample row containing your event = success. `0` = the event didn't arrive (or you're in the wrong dataset/environment). The samples section also lets you confirm the field values landed correctly (including that nested fields flattened how you intended).

If the event has an explicit `X-Honeycomb-Event-Time` in the past, widen `time_range` accordingly. The ID filter still works regardless of timestamp.

If the event was sent without an ID, drop the filter and use field values + `time_range` to find the event — but the ID approach is the only way to be certain you're looking at *your* event and not a similar one.

## Common mistakes

- **Sending nested JSON expecting it to be flattened.** It isn't. The whole nested value lands as one string column. Flatten yourself.
- **Putting milliseconds in `X-Honeycomb-Event-Time`.** It's seconds. The API accepts ms-sized values without an error; the resulting timestamp may be coerced or fall back to receipt time. Send seconds.
- **Forgetting `Content-Type: application/json`.** Some clients default to form-encoding.
- **Setting `X-Honeycomb-Samplerate`** Inflates your numbers.
- **Trailing commas in the JSON.** JSON is strict; the API returns 400.
