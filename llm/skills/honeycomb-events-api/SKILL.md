---
name: honeycomb-events-api
description: >
  Use when the user wants to send a single, targeted event to Honeycomb without
  OpenTelemetry — via the raw HTTP Events API. This is for one-off events
  (audit log entries, business events, Lambda completion records, scheduled
  job outcomes, "I ran this script" markers), not bulk telemetry. For bulk
  telemetry, use OpenTelemetry. Trigger phrases: "send an event to Honeycomb",
  "Honeycomb Events API", "POST to /1/events", "send a Honeycomb event from
  curl/lambda/script", "Honeycomb without OTel", "synchronous event to
  Honeycomb", "send a single event to a specific dataset", "X-Honeycomb-Team
  header", "Honeycomb ingest key", "Honeycomb event from AWS Lambda",
  "skip OpenTelemetry but still send to Honeycomb". For OTel SDK setup use
  `otel-instrumentation`; for migrating an OTel app use `otel-migration`.
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

## Why this instead of OpenTelemetry

- **Pick the dataset by name.** OTel routes by `service.name` to a same-named dataset. The Events API accepts the dataset as a URL parameter, so you can drop one event into any dataset (e.g. `audit-log`, `daily-jobs`, `business-events`) without spinning up a service identity.
- **Synchronous delivery.** No SDK buffer. The HTTP response means Honeycomb has the event. Critical in Lambdas and other short-lived processes that may exit before an OTel exporter flushes.
- **Zero dependencies.** HTTP + JSON. No SDK, no exporter, no resource detection. Works from anywhere a curl-equivalent works.

## Endpoint

```
POST https://api.honeycomb.io/1/events/{dataset}
```

EU customers: `https://api.eu1.honeycomb.io/1/events/{dataset}`.

`{dataset}` is the dataset slug (case-insensitive). Honeycomb auto-creates the dataset on first write if you're using an Ingest Key.

> Honeycomb's docs note that this single-event endpoint is "highly discouraged for anything more than testing." That guidance is about **throughput** — for bulk telemetry, use the batch endpoint or OTel. For individual targeted events, this endpoint is exactly what you want, and the throughput concern doesn't apply.

## Authentication

Send the key in the `X-Honeycomb-Team` header.

- **Use an Ingest Key** (prefix `hcaik_`). Create one in Honeycomb under *Environment Settings → API Keys*. Scoped to a single environment, can only send events.
- Configuration keys also work if they have "Send Events", but they can do dangerous things (modify SLOs, triggers, etc.) — don't put them in Lambda env vars or scripts.
- Read the key from an environment variable or secret store. Never commit it.

## Minimal request

```bash
curl -fsS -X POST "https://api.honeycomb.io/1/events/$DATASET" \
  -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"event":"deploy_finished","service":"api","duration_ms":42,"exit_code":0}'
```

The body is a **flat JSON object**. Each top-level key becomes a column in the dataset.

A successful response is `HTTP 200` with an empty body. Any 4xx is a hard rejection.

## Headers

| Header | Required | Notes |
|---|---|---|
| `X-Honeycomb-Team` | yes | Your ingest key |
| `Content-Type: application/json` | yes | Some clients default to form-encoding — set this explicitly |
| `X-Honeycomb-Event-Time` | no | Event timestamp as **Unix epoch seconds** (integer). Defaults to API receipt time |
| `X-Honeycomb-Samplerate` | no | Integer sample rate, default `1`. Only set if you're actually sampling — see below |

## Body shape: keep it flat

Top-level keys become columns. **Nested objects are not flattened — they are stored as a stringified JSON blob in a single column.** Verified against the live API:

Sending this:
```json
{"flat":"top","nested":{"inner_a":1,"inner_b":"hi"}}
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

Set `X-Honeycomb-Event-Time` only when you're back-filling, recording the start of an operation that ran for a while, or processing a queue. The format is **Unix epoch seconds (integer)**.

> **Footgun:** if you accidentally send milliseconds (e.g. `1777825788000`), the API does not return an error. In testing, Honeycomb appears to coerce the value to seconds (or fall back to receipt time) — but don't rely on that, send seconds. If your event isn't appearing in the expected time window, suspect this header.

Honeycomb only retains events within roughly the last 60 days; older timestamps may be ingested with the receipt time or rejected.

## Sample rate

`samplerate: N` tells Honeycomb "this event represents N similar events; I dropped N-1 of them." Honeycomb multiplies COUNT, SUM, etc. by N.

For individual targeted events, leave it at the default of 1. Setting it without doing client-side sampling will inflate your dashboards by that factor.

## Response codes

| Code | Meaning | What to do |
|---|---|---|
| 200 | Accepted | Done |
| 400 | Empty body, malformed JSON, oversized, too many columns | Fix the payload |
| 401 | Bad/missing key | Check `X-Honeycomb-Team` |
| 403 | Throttled administratively | Contact Honeycomb support |
| 404 | Dataset not found | Usually a config-key permission issue; ingest keys auto-create datasets |
| 429 | Rate limited | Back off and retry |

Retry only on `429`, `5xx`, and network errors. Never retry on other `4xx` — the request is malformed and will fail again.

## Lambda / short-lived process pattern

The whole point of using this API in a Lambda is **synchronous delivery**. Don't fire-and-forget:

1. Build the event.
2. `await` / block on the HTTP response.
3. Check the status code.
4. Only then `return` from the handler.

If you queue events to send later in a background thread, you've reinvented the OTel exporter problem you were trying to avoid.

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

## Common mistakes

- **Sending nested JSON expecting it to be flattened.** It isn't. The whole nested value lands as one string column. Flatten yourself.
- **Putting milliseconds in `X-Honeycomb-Event-Time`.** It's seconds. The API accepts ms-sized values without an error; the resulting timestamp may be coerced or fall back to receipt time. Send seconds.
- **Forgetting `Content-Type: application/json`.** Some clients default to form-encoding.
- **Using a configuration key in production code.** Use Ingest Keys.
- **Setting `X-Honeycomb-Samplerate` without doing client-side sampling.** Inflates your numbers.
- **Trailing commas in the JSON.** JSON is strict; the API returns 400.

## If you ever do need batching

For sending many events in one request, the batch endpoint is `POST /1/batch/{dataset}` with a JSON array of `{time, samplerate, data}` envelopes. The batch response is a JSON array of per-event statuses — `HTTP 200` does not mean every event succeeded. But this skill is for individual events; reach for OpenTelemetry before you reach for the batch endpoint.
