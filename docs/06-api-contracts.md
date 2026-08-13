# API and message contracts

## Purpose

This document defines the V1 wire semantics between the iPhone app, public boundaries, internal services, and workers. OpenAPI 3.1, JSON Schema, generated models, and contract fixtures become the executable source of truth in Stage 1; this document defines what those artifacts must express.

The contracts preserve three separations:

- a consumer verdict is not an HTTP transport result;
- a `dangerous` verdict is not an automatic-block authorization;
- anti-abuse authorization is not an account or a cross-plane identity.

Read this with [document 02](02-privacy-and-measurement.md), [document 03](03-trust-graph-and-verdicts.md), [document 04](04-system-architecture.md), [document 05](05-data-model.md), and [document 07](07-apple-platform.md).

## API principles

- V1 has no login, account token, user profile, cloud-history endpoint, or account deletion endpoint.
- Public request and response schemas default to rejecting unknown fields. Additive response fields remain possible through generated tolerant readers where explicitly allowed. The Swift product-core response reader is one such reader: it ignores additive unknown object members while still enforcing closed enums, field grammars, and size limits. It is not a server request validator.
- Use HTTPS, JSON encoded as UTF-8, snake-case field names, explicit schema versions, and the shared `CanonicalInstantV1` wire semantics below for canonical UTC whole-second instant fields.
- Public breaking changes require a new path major such as `/v2`. Additive optional fields, new stable reason codes, and new internal policy versions do not require a major change.
- A raw submitted URL appears only in the deliberate check or report request that needs it. It is never returned unredacted.
- Check, report, integrity, MPD, and analytics responses use `Cache-Control: no-store`.
- Filter manifests and content-addressed artifacts use explicit immutable cache semantics, signed digests, and ETags.
- Request, idempotency, check, report, capability, MPD, analytics, and App Attest identifiers never cross purposes.
- Server-generated request IDs are random, plane local, short lived in logs, and unsuitable for product correlation.
- `RequestIDV1`, where explicitly assigned below, is opaque, plane and purpose local, and unsuitable for product correlation.
- Error detail is bounded, non-sensitive, and never echoes request bodies, URLs, page text, tokens, assertions, or provider payloads.

Forward-compatible reason, problem, confidence, scope, family, severity, and freshness values use one grammar: 1 through 128 UTF-8 bytes of lower-snake-case ASCII, beginning with `a` through `z`, with no doubled or trailing underscore. Localization keys contain dot-separated segments using that grammar and are at most 256 UTF-8 bytes. These constraints are part of the V1 wire contract and must be reproduced by OpenAPI, JSON Schema, Swift, and Go.

### Shared `RequestIDV1`

`RequestIDV1` is the shared wire contract for exactly `PendingCheckResponseV1.request_id` and `ProblemV1.request_id`, the RFC 9457 problem field defined below. Reusing this value type shares validation only; it does not create a shared namespace. This slice does not define or approve a request ID for the proposed completed-check envelope, the report response, or any other contract or runtime behavior.

After JSON string decoding, a value is valid if and only if the complete byte string matches `[A-Za-z0-9_-]{1,128}`. Because the alphabet is ASCII, the character and byte counts are identical. Invalid values fail decoding without their contents being echoed.

Each value is opaque and scoped to its producing plane and immediate response purpose. A producer must not derive it from or embed a URL, domain, request-body content, token, assertion, credential, raw IP address, stable person/account/device identifier, or other sensitive or personal data. A consumer must not parse meaning from it or use it as an account, person, device, or check identity; an authorization or capability; an idempotency key; or a cross-plane or cross-purpose correlation handle.

Wire conformance alone proves only that grammar. It does not itself prove entropy, randomness, uniqueness, authenticity, or which producer minted a value, and it grants no lifetime, retention, or logging permission. Equal byte strings establish no identity, continuity, or other relationship across planes or purposes. This contract does not authorize an endpoint, network I/O, or persistence.

### Standalone `CheckTokenV1`

`CheckTokenV1` is currently assigned only to `PendingCheckResponseV1.check_token`. This extraction shares its syntax without approving the proposed completed-check or report envelopes as additional consumers and without defining an endpoint or runtime behavior.

After JSON string decoding, a value is valid if and only if it is the canonical unpadded base64url encoding of exactly 32 bytes. The wire text is exactly 43 ASCII characters: positions one through 42 contain an ASCII letter, digit, `_`, or `-`, and the final position is one of `AEIMQUYcgkosw048` so the unused base64 bits are zero. A semantic decoder must decode exactly 32 bytes and re-encode to the identical text. The valid public fixtures deliberately use visibly low-entropy controls and are forbidden for operational use.

This is a syntax contract and a purpose boundary, not proof of producer behavior. Conformance proves no entropy, randomness, uniqueness, secrecy, issuance, authenticity, ownership, authority, lifetime, expiry, retention or logging permission, digesting, storage, replay resistance, report linkage, polling behavior, authentication, or network behavior. It does not authorize accepting a token at any endpoint.

A `CheckTokenV1` is not interchangeable with an MPD presence or withdrawal token, request ID, idempotency key, report receipt, deletion capability, integrity capability, or any other token or identifier. Matching bytes establish no identity, continuity, linkage, or authority across purposes.

### Shared `CanonicalInstantV1`

`CanonicalInstantV1` is the shared wire contract for exactly `PendingCheckResponseV1.expires_at` and `VerdictReasonV1.observed_at`. This extraction consolidates their UTC grammar and closes prior schema drift around the lower year boundary; it does not approve another consumer or any enclosing runtime behavior.

After JSON string decoding, a value is valid if and only if it is exactly 20 ASCII bytes in `YYYY-MM-DDTHH:mm:ssZ` form and denotes a real proleptic-Gregorian calendar instant in years `0001` through `9999`, at UTC whole-second precision. The month-specific day and leap-year rules apply uniformly across the full range, and seconds run from `00` through `59`. Fractional seconds, offsets, lowercase `t` or `z`, year `0000`, impossible calendar dates, and every other shape are invalid.

Implementations apply the proleptic-Gregorian rules uniformly and do not insert a historical calendar-reform gap or switch to Julian leap-year rules for earlier dates.

The Swift core's shared `Date` strategy adopts this mapping as a contract-conformance correction. It intentionally does not preserve Foundation formatter behavior that applied a historical calendar cutover before 1582; modern dates and all pre-existing contract fixture bytes remain unchanged.

This standalone primitive validates wire syntax and calendar reality only. It does not read or authorize use of a clock, compare instants, define a TTL, decide freshness or retention, authorize network I/O or persistence, or approve a completed-check or report contract or behavior. The names `expires_at` and `observed_at` add no such authority.

### Standalone `CheckResponseStatusV1`

`CheckResponseStatusV1` is the closed check-response status vocabulary with exactly two wire values, in order: `complete` and `pending`. The Swift core exposes that versioned type as canonical and retains `CheckResponseStatus` as a source-compatible alias; the alias does not create a second vocabulary or widen either value's meaning.

This scalar validates only one discriminator value. In particular, `complete` does not approve or define the still-paused completed-check envelope, and `pending` does not authorize an endpoint, HTTP mapping, polling loop, retry scheduler, token behavior, clock or lifetime policy, network request, persistence, or state transition.

## Origins and routing boundaries

The exact hostnames require the infrastructure ADR, but production must expose independently controlled origins for these purposes:

| Origin class | Purpose | Store/credential boundary |
|---|---|---|
| Check and reports | Deliberate security-intelligence requests | Intelligence plane |
| Client integrity | App Attest registration, assertions, capabilities, rate controls | Anti-abuse plane |
| Protection measurement | Consented MPD presence and withdrawal | MPD plane |
| Product analytics | Separately consented, URL-free allowlisted events | Analytics plane |
| Filter distribution | Signed app manifests/artifacts and Apple URL Filter services | Projection/distribution boundary |

Do not terminate these origins into one application that has credentials for all stores. A shared DDoS/CDN edge may route opaque bytes only if its log, header, IP, trace, and data-retention configuration meets each destination's strictest policy.

Apple's production URL Filter service origins have additional subdomain-origin, OHTTP, Privacy Pass, PIR, and CloudKit constraints. [Document 07](07-apple-platform.md) is authoritative; do not force Apple's service interfaces into ordinary REST paths when its protocol specifies otherwise.

## Common headers and request limits

Public JSON requests use:

~~~text
Content-Type: application/json
Accept: application/json
Idempotency-Key: <random base64url value where required>
Hezo-Integrity: <opaque subjectless capability where required or available>
~~~

Suggested baseline limits, finalized in the OpenAPI and edge configuration:

- JSON body: 16 KiB for check/integrity/measurement and 32 KiB for an explicit report with bounded comment;
- submitted URL: 8 KiB encoded UTF-8;
- optional report comment: 500 Unicode scalar values after normalization;
- idempotency key: 16 through 64 random bytes, base64url encoded;
- reason items returned: at most five;
- unavailable collector items: bounded by the active analysis profile;
- batch analytics events: at most 20, if analytics is approved.

Requests exceeding a limit are rejected before semantic parsing and never copied into logs or error bodies.

## Canonical request digest

App Attest assertions and subjectless capabilities bind to one canonical request digest. Client and server contract tests must share exact vectors.

Recommended V1 input is the UTF-8 encoding of:

~~~text
METHOD + "\n" +
ORIGIN_FORM_PATH + "\n" +
LOWERCASE_MEDIA_TYPE + "\n" +
BASE64URL(SHA256(EXACT_HTTP_BODY_BYTES))
~~~

The canonical request digest is `SHA256` of those bytes. Do not include headers that a proxy may rewrite. For a bodyless request, hash the empty body. The anti-abuse service stores only the short-lived digest and binding metadata; it does not parse the submitted URL, MPD token, analytics event, or report text.

The App Attest `clientDataHash` construction and nonce validation remain exactly as Apple specifies in [document 07](07-apple-platform.md). This request digest is the Hezo client-data payload bound by that process, not a replacement for Apple's hash steps.

## Check API

### Create a check

`POST /v1/checks`

The same contract supports paste, share, and QR. Do not transmit which source application shared a URL, clipboard metadata, QR image, referrer, page title, contact, account, MPD token, or analytics identifier.

Request:

~~~json
{
  "schema_version": 1,
  "url": "https://example.test/path?opaque=value#route",
  "analysis_profile": "standard",
  "wait_budget_ms": 1200,
  "reason_schema_version": 1
}
~~~

Contract rules:

- `url` is the exact deliberate submission. Query and fragment are not stripped before analysis.
- Only syntactically valid HTTP and HTTPS URLs are accepted. User information, control characters, ambiguous host syntax, prohibited local names, and other validation failures follow [document 08](08-sandbox-and-security.md).
- The proposed V1 network port policy is 80/443. A syntactically valid other port returns a completed `unknown` result with operational code `unsupported_port`; it is not silently rewritten.
- `analysis_profile` is allowlisted. The app cannot request hidden collectors or broaden egress. `standard` is the normal manual profile; a future fast profile requires policy support.
- `wait_budget_ms` is a hint clamped to a server maximum. It is not a promise and is not persisted as analytics.
- `Idempotency-Key` is required because the request may schedule work. It is retained only for the short check window.
- `Hezo-Integrity` is accepted when available. Core manual checks must retain a documented reduced-trust/rate-limited path when App Attest is unsupported or temporarily unavailable; lack of attestation is not proof of abuse.

### Completed check

The completed envelope below remains a design target, not part of the bounded offline `PendingCheckResponseV1` contract decision. That decision approves no completed-response schema, decoder, status transition, or runtime behavior; completed-response implementation remains blocked.

Return `200 OK`:

~~~json
{
  "schema_version": 1,
  "status": "complete",
  "check_token": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "verdict": {
    "label": "caution",
    "recommended_action": "warn",
    "confidence": "high",
    "evaluated_scope": "exact_url",
    "reasons": [
      {
        "code": "brand_impersonation_unrelated_domain",
        "family": "identity_impersonation",
        "severity": "high",
        "summary_key": "verdict.reason.brand_impersonation_unrelated_domain",
        "observed_at": "2026-08-11T10:15:00Z",
        "freshness": "current"
      }
    ]
  },
  "target": {
    "display_url": "https://example.test/path?…",
    "registrable_domain": "example.test"
  },
  "analysis": {
    "profile": "standard",
    "completeness": "complete",
    "unavailable_collectors": []
  },
  "source_notices": [],
  "versions": {
    "canonicalizer": "1",
    "verdict_policy": "2026-08-01.1",
    "reason_schema": 1,
    "intelligence_watermark": "opaque-version"
  },
  "evaluated_at": "2026-08-11T10:15:03Z",
  "valid_until": "2026-08-11T11:15:03Z",
  "request_id": "plane-local-random-id"
}
~~~

Public `verdict.label` has exactly four allowed values:

| Value | Meaning |
|---|---|
| `unknown` | Hezo lacks sufficient current evidence or required analysis did not complete |
| `no_known_danger` | The minimum selected profile completed and found no meaningful current danger under policy; not a safety guarantee |
| `caution` | Suspicious, contradictory, or incomplete corroborated evidence justifies caution |
| `dangerous` | Current evidence satisfies the Dangerous policy |

The Swift core exposes `VerdictLabelV1` as the canonical type and retains `VerdictLabel` as a source-compatible alias. The alias does not create a second vocabulary or change the four wire values.

No aliases such as `safe`, `likely_safe`, `allow`, `warn`, `block`, `malicious`, or `suspicious` may appear in the public verdict-label field. Internal diagnostic labels must map to one canonical value at the contract boundary.

`recommended_action` is separate and may be `allow`, `warn`, `avoid`, or `retry`. The Swift core exposes `RecommendedActionV1` as the canonical type and retains `RecommendedAction` as a source-compatible alias; the alias does not create a second vocabulary or change the four wire values. `allow` means proceed with ordinary care after `no_known_danger`; it never promises safety. The check response does not expose automatic block eligibility. That is a separately versioned internal decision.

V1 admits only these label/action pairs:

| `label` | Allowed `recommended_action` | Rule |
|---|---|---|
| `unknown` | `warn`, `retry` | Use `warn` for terminal uncertainty; use `retry` only when surrounding operational state says another attempt may help. |
| `no_known_danger` | `allow` | Proceed with ordinary care; never a safety promise. |
| `caution` | `warn` | Present the bounded warning without upgrading the result to Dangerous. |
| `dangerous` | `avoid` | Recommend avoiding the target; this is not automatic-block authority. |

Every other label/action pair is invalid. The standalone Verdict object enforces this admission matrix but cannot choose `warn` versus `retry` for Unknown without the surrounding operational/completeness state.

`confidence` is a bounded category such as `low`, `medium`, or `high`, not an internal score or consumer probability. The Swift core exposes `EvaluatedScopeV1` as the canonical evaluated-scope type and retains `EvaluatedScope` as a source-compatible alias; both names preserve the same forward-compatible grammar, and `exact_url` remains the only published V1 scope meaning. Reasons use stable codes and localization keys, the grammar above, and a maximum of five items. `VerdictReasonV1.observed_at` is a `CanonicalInstantV1`; the timestamp alone does not decide evidence freshness. Server fallback copy is bounded and derived only from approved reason data.

The primitive label, action, and reason models do not by themselves authorize a complete verdict. The completed-check envelope must validate label/action coherence and may serialize `no_known_danger` only when the selected profile's completeness and freshness requirements are satisfied. A standalone primitive must never be treated as that evidence-bearing authorization.

Provider-specific attribution or advisory requirements appear in `source_notices` with stable template/link fields. Raw source records and license-forbidden provider identity are not returned.

### Pending check

`PendingCheckResponseV1` is a bounded offline data contract only. It contains exactly these six required fields:

~~~json
{
  "schema_version": 1,
  "status": "pending",
  "check_token": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "retry_after_ms": 750,
  "expires_at": "2026-08-11T10:30:00Z",
  "request_id": "pending-example"
}
~~~

- `schema_version` is the integer `1`.
- `status` is the string `pending`.
- `check_token` is a `CheckTokenV1`. A future producer must generate exactly 32 cryptographically random bytes and encode those bytes canonically, but accepting the standalone syntax does not prove that behavior.
- `retry_after_ms` is an integer from `1` through `900000`, inclusive.
- `expires_at` is a `CanonicalInstantV1`. It is the envelope's absolute expiry field, but wire conformance alone applies no clock or TTL policy.
- `request_id` is a `RequestIDV1`.

The token shown above is deliberately zero-entropy public fixture text for wire-shape illustration and is forbidden for operational use.

The strict public schema rejects unknown fields. The specifically designated Swift response reader may discard genuinely additive unknown top-level keys for forward compatibility, but it must reject a hybrid pending envelope containing any of these completed-response or enforcement keys: `verdict`, `target`, `analysis`, `source_notices`, `versions`, `evaluated_at`, `valid_until`, or `block_eligible`.

A future consumer runtime must make its effective delay at least the maximum of `retry_after_ms`, its local minimum retry floor, and its current backoff. It must never schedule an attempt at or after `expires_at`; if the resulting allowed attempt time reaches that instant, it schedules nothing. This is a constraint on any future consumer, not approval to implement one here.

This offline contract decision does not approve or implement issuance TTL, retention and deletion, token digesting or storage, replay handling, report linkage, endpoint and path, HTTP behavior, authentication, polling, network I/O, persistence, App Attest, deployment, or completion. The `900000` maximum is only a value cap for `retry_after_ms`; it is not a token lifetime, TTL, or expiry promise. No completed-response contract is approved by this slice, and completed-response work remains blocked.

The existing future runtime sketch remains Proposed, not authorized by this offline contract: a server would store only a token digest, scope the token to status retrieval and report linkage, and use a short lifetime in the proposed 10–15 minute range. Status retrieval would use one fixed path with the token in its authorization header rather than its URL, return pending only while work is genuinely active, avoid an existence oracle for expired or unknown tokens, and terminate insufficient analysis as a completed `unknown` result rather than polling indefinitely. These runtime choices still require their own reviewed implementation authority and exact lifecycle, retention, replay, authentication, and endpoint contracts.

### Unknown versus transport failure

Examples that normally return `200` with `verdict.label = unknown`:

- supported URL on a policy-disallowed port;
- critical collector unavailable after bounded attempts;
- evidence materially stale;
- parser disagreement discovered after initial acceptance;
- analysis timeout or sandbox rejection;
- insufficient evidence for a new URL.

Examples that return an HTTP problem instead:

- malformed JSON;
- syntactically invalid or non-HTTP(S) input;
- body too large;
- invalid content type;
- invalid/expired required capability;
- service cannot accept or represent a check at all.

This distinction lets the UI say “we do not know” without presenting a successful uncertainty outcome as an app crash.

## Scam and incorrect-verdict reports

`POST /v1/reports`

Request with a fresh check token:

~~~json
{
  "schema_version": 1,
  "report_type": "incorrect_verdict",
  "check_token": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "category": "legitimate_site",
  "comment": "Optional short explanation",
  "deletion_capability_digest": "base64url-sha256"
}
~~~

If the token is unavailable, the user may explicitly submit a URL instead:

~~~json
{
  "schema_version": 1,
  "report_type": "scam",
  "url": "https://example.test/path?opaque=value",
  "category": "credential_theft",
  "deletion_capability_digest": "base64url-sha256"
}
~~~

Contract rules:

- Exactly one of `check_token` and `url` is present.
- `report_type` is `scam` or `incorrect_verdict`.
- Category is allowlisted by report type.
- Comment is optional, normalized, length-limited, encrypted at rest, never a direct verdict reason, and never reflected into an error.
- The app generates a random deletion capability, sends only its SHA-256 digest, and stores the secret locally with the report receipt while identifiable report content remains.
- `Idempotency-Key` and a report-purpose integrity capability are required in production. Unsupported App Attest behavior follows the reviewed reduced-trust policy; unattested reports cannot influence scoring.
- Until O-017 approves the final policy, restricted report content follows document 02's proposed delete-after-triage/30-day maximum and the body-free idempotency digest follows its proposed 24-hour maximum. The contract cannot silently lengthen either window.
- Explicit report acceptance is not confirmation that the target is malicious or legitimate.

Return `202 Accepted`:

~~~json
{
  "schema_version": 1,
  "status": "accepted",
  "report_receipt": "opaque-local-display-value",
  "request_id": "plane-local-random-id"
}
~~~

V1 has no reporter-status account or public analyst notes endpoint. The receipt supports local confirmation and idempotent retry, not cross-device tracking.

Delete still-identifiable report content with `POST /v1/reports/delete` and a body containing the report receipt plus the locally stored deletion capability. Return `204` whether a matching deletable record existed. A successful match destroys the restricted record's data key, removes readable content and the capability digest, and applies the approved O-017 rule to report-only derived support and backups. The deletion endpoint does not accept an account, App Attest key, MPD token, analytics identifier, email, or identity document.

## Client-integrity API

These endpoints use the anti-abuse origin and store only anti-abuse data. Exact cryptographic verification, environments, Apple roots, AAGUID handling, counters, receipts, and iOS 27 extensions are specified in [document 07](07-apple-platform.md).

### Attestation eligibility

`POST /v1/integrity/eligibility`

Allows Hezo to throttle or pause new attestations below Apple's published limits. Request contains only environment/build facts required by policy and no security URL or telemetry identifier. Response is one of `eligible`, `defer`, or `unsupported`, with bounded retry time and policy version.

### Challenge

`POST /v1/integrity/challenges`

~~~json
{
  "schema_version": 1,
  "purpose": "check",
  "environment": "production",
  "key_id": "sensitive-app-attest-key-id",
  "request_digest": "base64url-sha256"
}
~~~

For initial attestation, `key_id` and request binding follow the registration state machine rather than an asserted operation. For operation assertions, the challenge binds environment, key, purpose, HTTP method/route class, and canonical request digest.

Return `201 Created` with random challenge bytes containing at least 16 bytes of entropy, recommended 32, an opaque challenge ID, and a short expiry. Key IDs and challenge values are excluded from logs.

### Register a key

`POST /v1/integrity/registrations`

Carries the challenge ID, App Attest key ID, environment, attestation object, and exact registration client-data binding required by Apple. Apply strict base64, CBOR, ASN.1, certificate, and size limits before verification.

Return a bounded `active`, `retry_same_transaction`, or `rotate_key` state. A lost successful acknowledgement must be distinguishable from a terminal rejection so the client does not attempt to attest the same key twice.

### Exchange an assertion for a capability

`POST /v1/integrity/capabilities`

Carries challenge ID, key ID, assertion, purpose, and request digest. On success, return an opaque or signed capability with:

- audience;
- purpose;
- body/request digest;
- integrity level;
- random JTI;
- issue and expiry times, normally around 60 seconds;
- no App Attest key ID, installation ID, IP-derived value, analytics ID, MPD token, or reusable user subject.

Capabilities for `check`, `report`, `filter_download`, `mpd_presence`, `mpd_withdrawal`, and any analytics purpose are not interchangeable. Operation capabilities are single use; the downstream service verifies audience, purpose, expiry, request digest, signature, and atomic replay consumption. Raw capabilities/JTIs are never logged. Anti-abuse and the destination use different domain-separated keyed replay digests and delete them at expiry, avoiding a directly joinable replay identifier.

### Integrity failure semantics

Public codes are deliberately coarse:

- `integrity_challenge_expired`;
- `integrity_verification_failed`;
- `integrity_replay_rejected`;
- `integrity_environment_mismatch`;
- `integrity_key_rotation_required`;
- `integrity_temporarily_unavailable`.

Do not reveal which certificate, nonce, counter, receipt, category, bundle, risk, or rate rule failed. Detailed codes remain in the isolated anti-abuse audit system without request payloads.

## MPD measurement API

This API uses the measurement origin and exists only after separate consent. The exact metric wording and token derivation in [document 02](02-privacy-and-measurement.md) are authoritative.

### Monthly presence

`POST /v1/measurement/mpd`

When the gated anonymous credential design is enabled:

~~~text
Authorization: PrivateToken <month-bound one-use credential>
~~~

~~~json
{
  "schema": 1,
  "month": "2026-08",
  "token": "base64url-32-byte-token"
}
~~~

Rules:

- The client generates the full 32-byte token from the HKDF/HMAC construction in document 02 using a measurement-only 256-bit secret in its app/App Group container. It is never an App Attest key, IDFV, analytics ID, account ID, or Keychain continuity mechanism.
- The body contains no URL/domain, check/verdict/report/campaign ID, block count, source app, locale, device model, carrier, raw IP, or User-Agent.
- The service accepts only the current UTC month under the published methodology. A retry crossing a month boundary creates the new month token rather than backdating activity.
- Consent, production-install status, and URL Filter enabled/healthy state are checked before the client prepares the receipt. The counter stores no per-row health, build, consent, or precise-time profile.
- A simple subjectless `mpd_presence` capability can separate stored planes but does not make issuance and redemption cryptographically unlinkable. A publicly described manipulation-resistant count requires the blinded, month-bound credential gate in document 02; otherwise the observed count remains internal or is labeled an estimate.
- The service HMACs the client token again with a measurement-plane key before storage and discards the request value.
- Duplicate accepted requests are idempotent.

Return `204 No Content` for both first acceptance and duplicate acceptance. This avoids exposing whether a token was already counted.

### Open/provisional-month withdrawal

`POST /v1/measurement/mpd/delete`

The body contains `schema`, one open or provisional `month`, and that month's 32-byte token. Never send multiple months in one request because doing so directly links the rotating tokens. Use a deletion-purpose private credential or body-bound capability that does not expose an App Attest identity to measurement. Return `204` whether or not the presence existed. The app submits one request for every locally derivable still-deletable month, stops future submissions, and deletes its measurement secret after successful deletion or retry expiry as described in document 02.

Do not create a public token lookup, count-by-token, device-history, or cross-month status endpoint.

## Product analytics API

This origin and contract do not exist unless P-012 is approved. If approved, separate consent is required and OpenAPI is generated from an event allowlist.

`POST /v1/analytics/batches`

~~~json
{
  "schema": 1,
  "batch": "one-time-random-value",
  "deletion_capability_digest": "base64url-sha256",
  "period": "2026-08-11",
  "events": [
    {
      "code": "protection_setup_completed",
      "count": 1
    }
  ]
}
~~~

The example is illustrative, not an approved event. Each event/property must have an owner, product question, consent copy, cardinality, retention, and schema. Unknown events and properties are rejected. The batch value is random, one-time, never reused, and exists only for accidental replay prevention; it is not an installation or product identity. The app separately generates and retains the deletion-capability secret while the raw batch is deletable and sends only its digest.

The API and SDK deny URLs, URL components, domains, verdicts, check/report/campaign/entity IDs, QR or clipboard values, source applications, MPD tokens, App Attest keys, IDFV, IDFA, passive URL Filter queries, block events, persistent installation identifiers, and cross-month contributor identifiers. Do not implement a generic arbitrary event-name/property endpoint or a third-party session-replay SDK.

Return `204` on accepted bounded batches. A separate non-disclosing batch-deletion operation accepts the locally retained capability and returns `204` whether a still-raw batch existed. Analytics delivery is best effort; an outage never delays or changes protection or MPD.

## Filter manifest and artifact contract

The containing app may retrieve a signed current manifest through a filter-distribution endpoint compatible with the Apple design:

`GET /v1/filter/manifests/current`

~~~json
{
  "schema_version": 1,
  "channel": "production",
  "generation": "2026-08-11.42",
  "created_at": "2026-08-11T10:00:00Z",
  "expires_at": "2026-08-11T16:00:00Z",
  "canonicalizer_version": "apple-url-filter-1",
  "policy_version": "route-a-1",
  "predecessor_generation": "2026-08-11.41",
  "minimum_app_version": "1.0.0",
  "minimum_os_version": "26.0",
  "bloom": {
    "artifact_url": "https://content.example.invalid/immutable-object",
    "compressed_bytes": 1234,
    "sha256": "..."
  },
  "pir": {
    "generation": "2026-08-11.42",
    "parameter_set": "...",
    "sha256": "..."
  },
  "signing_key_id": "filter-signing-1",
  "signature": "base64url-signature"
}
~~~

The app verifies the signature, digest, expiry, compatibility, and predecessor relationship before atomic activation. Support `ETag`/`If-None-Match`; content-addressed artifacts use long immutable caching. A manifest or artifact response never carries a per-device analytics or MPD value.

Bloom, PIR, Privacy Pass, OHTTP gateway, and Apple relay messages follow Apple's protocol and official sample/vector formats. They are not replaced with invented JSON. The compiler and service tests prove the Apple wire contract, version skew, Bloom false-positive/PIR confirmation, and publication order. Publish PIR generation `N` before Bloom `N` and retain compatible `N-1`.

Apple's `/key` and `/queries` flow uses a pseudorandom `User-Identifier` header to associate an uploaded evaluation key with later encrypted PIR requests. The PIR service may persist only a filter-keyed digest of that value plus the opaque evaluation key, compatible parameter/generation version, and strict expiry state in the separate filter-runtime store defined in [document 05](05-data-model.md). It must suppress the raw header and digest from access logs, traces, metrics, support, and exports and must not forward either value to another data plane.

This protocol value can correlate only its own evaluation-key/query lifecycle until expiry. It is not an app-generated stable product identity. In the normal production path, Apple's OHTTP relay prevents Hezo from receiving the originating client IP, while PIR prevents Hezo from learning the queried URL/membership key or the returned membership result. Do not add a custom identifier, cookie, decoded-query log, bearer-token identity, App Attest key, MPD token, analytics value, or cross-plane trace to the protocol.

The URL Filter data path does not report browsing, query, allow, or block events to these APIs. Consumer V1 is fail open according to [document 07](07-apple-platform.md).

## Internal service and job contracts

Internal endpoints are not public Internet APIs. Use workload identity/mTLS, network policy, audience-specific authorization, strict schemas, and no multi-plane credential.

### Common event envelope

~~~json
{
  "event_id": "uuidv7",
  "event_type": "signals.evaluate_subject",
  "schema_version": 1,
  "producer": "graph-worker",
  "producer_version": "...",
  "plane_correlation_id": "random-plane-local-id",
  "idempotency_digest": "base64url-digest",
  "subject_ref": "opaque-intelligence-public-id",
  "evidence_watermark": "opaque-version",
  "created_at": "2026-08-11T10:00:00Z",
  "available_at": "2026-08-11T10:00:00Z",
  "delete_after": "2026-08-25T10:00:00Z",
  "payload": {}
}
~~~

Payloads contain typed identifiers/versions or opaque object references, never raw URLs, URL components, page content, report comments, MPD/analytics tokens, App Attest material, IPs, credentials, or arbitrary error text.

Consumers support overlapping event schema versions during deployment. Unknown versions go to a redacted quarantine with alerting; they are not silently dropped or interpreted.

### Observation candidate

Collectors and the sandbox promotion service submit bounded facts, not verdicts:

~~~json
{
  "schema_version": 1,
  "observation_type": "url_redirected_to",
  "subject_ref": "...",
  "related_entities": [
    {"role": "redirect_target", "entity_ref": "..."}
  ],
  "source_ref": "...",
  "source_terms_snapshot_ref": "...",
  "import_or_run_ref": "...",
  "collector": {"name": "redirect_collector", "version": "..."},
  "observed_at": "...",
  "valid_until": "...",
  "confidence_basis_points": 10000,
  "content_fingerprint": "...",
  "value": {"redirect_index": 1}
}
~~~

Evidence ingest verifies source rights, entity types, schema version, limits, expiry, and idempotency before committing the immutable observation and outbox event. It cannot accept a collector-supplied consumer verdict or block flag.

### Sandbox task and result

The broker sends the isolated analysis zone only:

- opaque job and lease IDs;
- job-scoped transient object capability;
- expected encrypted object digest;
- parser, egress, navigation, artifact, and resource policy versions;
- deadline and output capability.

The result envelope contains:

- job/attempt and runner image IDs;
- terminal bounded result code;
- navigation and policy version;
- artifact manifest with content digests, sizes, media types, and quarantine references;
- bounded typed finding candidates;
- resource-use totals;
- signature/attestation from the trusted runner boundary.

It contains no production credential. A retry creates a new attempt and result envelope. Trusted promotion re-parses and schema-validates results before creating observations.

### Derivation jobs

Graph, signal, verdict, and block jobs always include the subject, algorithm/policy version, and evidence watermark. Storage uniqueness uses the same semantic identity. A worker may write historical output from an older watermark, but compare-and-swap head/publish operations reject it as current.

### Outbox and inbox semantics

- The source mutation and outbox insert commit together.
- Delivery is at least once.
- A consumer records `(consumer, event_id)` before acknowledgement.
- Reprocessing an idempotency digest returns the existing semantic result.
- Reusing an HTTP idempotency key with the same body returns the original status/body while retained; a different body returns `409`.
- External calls occur outside database transactions after a bounded lease is committed.
- Retry uses exponential backoff with jitter and a maximum attempt/age.
- Dead-letter records contain only stable codes, versions, and opaque references and have a deletion deadline.

## Problem response and error catalog

Use `application/problem+json` based on RFC 9457:

~~~json
{
  "type": "https://errors.hezo.example/invalid-url",
  "title": "Invalid URL",
  "status": 422,
  "code": "invalid_url",
  "detail": "The submitted value is not a supported HTTP or HTTPS URL.",
  "request_id": "problem-example",
  "retryable": false
}
~~~

The final error origin is selected by ADR. `type`, `title`, `status`, and `code` are stable contract fields. `detail` is bounded copy, not an exception string. Optional `retry_after_seconds` appears only when `retryable` is true.

V1 problem limits are: `type` is a nonempty, syntactically valid ASCII RFC 3986 URI reference of at most 256 bytes; `title` is 128 UTF-8 bytes; `detail` is 512; and `request_id` is a `RequestIDV1`. Status is `400...599`; `retry_after_seconds` is `0...86400`. Required text is nonempty and contains no Unicode control characters. Invalid problem values fail decoding without echoing their content.

| Status | Use |
|---:|---|
| `400` | Malformed JSON or invalid envelope |
| `401` | Missing, expired, or invalid required capability |
| `403` | Valid credential but environment/purpose is not permitted |
| `404` | Unknown/expired opaque status resource without existence disclosure |
| `409` | Idempotency body mismatch, replay, or atomic state conflict |
| `413` | Request exceeds size limits |
| `415` | Unsupported media type |
| `422` | Syntactically valid envelope with invalid URL/field semantics |
| `429` | Rate limit or provider budget gate; include `Retry-After` when appropriate |
| `503` | Temporary inability to accept or represent the operation |

Stable initial codes include:

- `invalid_request`, `invalid_url`, `unsupported_scheme`, `url_too_long`;
- `idempotency_conflict`;
- `capability_required`, `capability_invalid`, `capability_expired`, `capability_replayed`;
- integrity codes listed above;
- `rate_limited`;
- `temporarily_unavailable`, `analysis_capacity_unavailable`;
- `measurement_schema_unsupported`, `measurement_month_invalid`;
- `event_not_allowed`, `event_property_not_allowed`.

Sandbox failures such as `blocked_destination` are generally represented inside a completed `unknown` analysis result, not exposed as detailed public infrastructure errors.
Provider quota, circuit-breaker, and budget-exhaustion codes are internal bounded diagnostics. Publicly they become collector unavailability in a completed `unknown` result or the generic `temporarily_unavailable` problem when the service cannot accept a check.

## API security and privacy controls

- Redact body, URL, authorization, token, assertion, receipt, and attacker-controlled fields before logging at every hop.
- Disable query/body logging at CDN, load balancer, WAF, framework, APM, crash, and support layers.
- Do not put sensitive capabilities or tokens in URL paths or query strings.
- Apply schema and byte limits before CBOR/ASN.1/JSON/decompression work.
- Return generic anti-abuse outcomes and use constant-shape responses where token-existence disclosure matters.
- Sign service-to-service events or rely on authenticated managed transport plus content digests; validate producer audience and schema either way.
- Use bounded-cardinality metrics only. Never use URL, entity, request, report, token, key, IP, or arbitrary code as a metric label.
- Keep development/staging and App Attest sandbox/production credentials, data, capabilities, and origins separate.
- Generate contract canaries containing URL-like, token-like, and PII-like values; fail tests if they reach the wrong plane, logs, traces, crash reports, queue envelopes, or error bodies.

## Contract build order

1. Define shared problem, version, reason, completeness, and canonical verdict schemas.
2. Define check create/status and idempotency fixtures, including exact raw-byte digest vectors.
3. Define internal observation, outbox, job, sandbox, derivation, and stale-watermark schemas.
4. Generate iOS/backend models and round-trip/differential tests.
5. Add integrity eligibility/challenge/registration/assertion/capability contracts with Apple conformance fixtures.
6. Add report contracts and anti-abuse stripping tests.
7. Add signed filter manifest and Apple protocol conformance fixtures.
8. Add MPD presence/withdrawal only after methodology and consent approval.
9. Add analytics contracts only if an event allowlist is approved.

## Contract acceptance criteria

- Generated iOS and backend models round-trip every golden request, response, problem, event, and manifest fixture.
- Unknown request fields, oversized bodies, invalid UTF-8, control characters, malformed URLs, and invalid base64/CBOR/ASN.1 fail before sensitive logging or expensive work.
- Public check responses use only `unknown`, `no_known_danger`, `caution`, or `dangerous`.
- `no_known_danger` cannot be serialized unless the active profile's completeness and freshness contract is satisfied.
- `dangerous` response serialization has no implicit block-eligible field or behavior.
- A provider outage and an empty provider match are distinguishable; neither silently creates a clean result.
- Query parameters and fragments reach the transient security analysis input exactly and never appear in response display, problem detail, logs, traces, jobs, or normal durable records.
- Duplicate same-body idempotent requests return the same effect; different-body reuse returns `409`.
- Pending tokens are random, bounded, non-identifying, absent from paths/logs, and expire on schedule.
- Replayed, body-swapped, expired, wrong-audience, and wrong-purpose integrity capabilities fail.
- The anti-abuse service cannot decode a semantic URL/MPD/analytics/report body from its contract and forwards no stable subject.
- Report volume alone cannot set a verdict or block field through any public/internal schema.
- Report deletion, expiry, per-record key destruction, idempotency expiry, backup unreadability, and report-only-support handling pass O-017 contract fixtures.
- MPD duplicates and unknown-token withdrawals both return non-disclosing `204`; no measurement schema accepts a security or analytics identifier.
- Analytics contracts do not exist until approval, and then reject every non-allowlisted event/property and all prohibited fields.
- Apple filter fixtures prove signatures, digest mismatch rejection, generation skew, `N`/`N-1` rollback, Bloom/PIR agreement, and fail-open behavior.
- PIR protocol tests prove `User-Identifier`/evaluation-key association and expiry without logging or exporting the identifier and without exposing a URL, query result, bearer-token identity, or app-generated stable product identity.
- Every event supports overlapping schema versions, semantic idempotency, bounded retries, redacted dead letters, and a deletion deadline.

## Decisions that contracts must not guess

- Backend language/framework and generated-code tooling;
- final public origins and cloud edge;
- exact reduced-trust policy when App Attest is unsupported or unavailable;
- subjectless-capability transport; operation capabilities remain single-use;
- exact raw-URL/check-token retention and O-017 report live/idempotency/derived-support/backup retention;
- accountless Apple PIR bearer-token implementation;
- O-018 Apple PIR `User-Identifier`/evaluation-key inactivity and absolute retention;
- whether the URL Filter extension receives any containing-app-provisioned backend credential beyond Apple's required design;
- exact MPD public wording, finalization, withdrawal, and correction behavior;
- whether product analytics exists and its event allowlist;
- ports beyond 80/443.

These are tracked in [document 12](12-risks-decisions-and-open-questions.md) and require ADRs or owner decisions at the listed stage.
