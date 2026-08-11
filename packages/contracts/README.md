# Hezo Link contract components

This directory is the public, offline source of truth for the first check-input, request-ID, problem, check-response-status, pending-check-response, verdict, verdict-reason, and standalone verdict-supporting wire contracts described in [API and message contracts](../../docs/06-api-contracts.md). It contains only data contracts and synthetic examples. It does not define a deployed service.

## Artifacts

- `openapi-components.json` is an OpenAPI 3.1 components document. Its `paths` object is deliberately empty and it declares no server or security scheme.
- `schemas/check-request-v1.schema.json` is the strict Draft 2020-12 request schema.
- `fixtures/check-request-v1/manifest.json` lists deterministic, reserved-domain valid and invalid examples and their expected schema result.
- `schemas/request-id-v1.schema.json` is the strict Draft 2020-12 standalone request-ID scalar schema.
- `fixtures/request-id-v1/manifest.json` lists the exact length and alphabet boundaries plus deterministic invalid punctuation, whitespace, control, non-ASCII, null, and type examples with their exact schema failure keyword sets.
- `schemas/check-response-status-v1.schema.json` is the strict Draft 2020-12 standalone check-response-status enum schema.
- `fixtures/check-response-status-v1/manifest.json` lists both valid statuses and deterministic invalid aliases, cross-vocabulary values, types, and spellings with their exact schema failure keyword sets.
- `schemas/pending-check-response-v1.schema.json` is the strict Draft 2020-12 Pending Check Response V1 object schema.
- `fixtures/pending-check-response-v1/manifest.json` lists deterministic boundary, canonical-token, missing-member, known-forbidden-member, type, format, and grammar examples with their exact schema failure keyword sets.
- `schemas/verdict-v1.schema.json` is the strict Draft 2020-12 public Verdict V1 object schema.
- `fixtures/verdict-v1/manifest.json` lists every allowed and disallowed label/action pair plus deterministic structural and referenced-value failures with their exact schema failure keyword sets.
- `schemas/problem-v1.schema.json` is the strict Draft 2020-12 RFC 9457-style problem schema.
- `fixtures/problem-v1/manifest.json` lists deterministic problem examples and the schema keyword or keyword set each invalid example exercises.
- `schemas/verdict-reason-v1.schema.json` is the strict Draft 2020-12 public verdict-reason schema.
- `fixtures/verdict-reason-v1/manifest.json` lists deterministic verdict-reason boundary examples and the exact schema keyword or keyword set each invalid example exercises.
- `schemas/verdict-label-v1.schema.json` and `schemas/recommended-action-v1.schema.json` are strict Draft 2020-12 standalone enum schemas.
- `fixtures/verdict-label-v1/manifest.json` and `fixtures/recommended-action-v1/manifest.json` list every valid primitive and deterministic invalid aliases, types, and spellings with their exact schema failure keyword sets.
- `schemas/confidence-category-v1.schema.json` and `schemas/evaluated-scope-v1.schema.json` are strict Draft 2020-12 forward-compatible stable-value schemas.
- `fixtures/confidence-category-v1/manifest.json` and `fixtures/evaluated-scope-v1/manifest.json` cover documented examples, additive values, exact bounds, and invalid grammar cases.
- `schemas/verdict-reasons-v1.schema.json` is the strict ordered zero-through-five Verdict Reason V1 collection schema.
- `fixtures/verdict-reasons-v1/manifest.json` covers every allowed count, preserved order, permitted duplicate items, collection limits, and invalid nested reasons.

The OpenAPI components reference the standalone JSON Schemas so there is one definition of each public shape to keep current.

Contract asset tests run in both SwiftPM and the shared Xcode scheme. They pin the exact V1 schema surfaces, resolve the OpenAPI and manifest references, check complete unique fixture coverage, and independently evaluate every declared fixture result and failure keyword set. These tests are deliberately limited to the frozen contract subsets; they are not a general JSON Schema implementation. Expanding the schema vocabulary requires a versioned contract change and selected strict Draft 2020-12 validation tooling rather than silently widening the local evaluators.

## Check request V1

Every request is a JSON object with exactly these required fields:

- `schema_version`: integer constant `1`.
- `url`: the exact, deliberate URL string submitted by the user. Producers must not remove its query or fragment, normalize it, or add source-app metadata before encoding the request. Only syntactically valid HTTP and HTTPS URLs proceed to analysis.
- `analysis_profile`: string constant `standard`.
- `wait_budget_ms`: nonnegative integer hint from `0` through the signed 32-bit maximum, `2147483647`. It is not a completion promise.
- `reason_schema_version`: integer constant `1`.

Unknown fields are rejected.

### URL validation boundary

The schema's `maxLength: 8192` is a useful coarse upper bound, but Draft 2020-12 defines `maxLength` in Unicode code points rather than encoded bytes. A semantic validator must also reject a decoded `url` whose UTF-8 representation exceeds 8192 bytes. It must apply the URL target rules in [Sandboxing and security](../../docs/08-sandbox-and-security.md), including scheme, user-information, host, control-character, and ambiguity checks. Schema validation never rewrites the submitted value.

## Check response status V1

`CheckResponseStatusV1` is a standalone string enum with exactly two values: `complete` and `pending`. It rejects the conceptual state `analyzing`, the verdict label `unknown`, the report-response status `accepted`, HTTP status numbers, aliases, and alternate spellings.

This primitive validates one check-response status value only. It defines no endpoint, response branch, HTTP status, token or capability, retry or polling behavior, completion guarantee, or check-response envelope.

## Request ID V1

`RequestIDV1` is a string containing one through 128 ASCII letters, digits, `_`, or `-`. Its ASCII grammar makes the schema's code-point bounds equal its UTF-8 byte bounds. Problem V1 and Pending Check Response V1 use the same absolute standalone schema reference for their `request_id` member without widening this accepted language.

`RequestIDV1` is a strict standalone bounded ASCII shape only. Acceptance proves no entropy, uniqueness, authority, lifetime, retention or logging permission, or cross-plane identity.

## Pending check response V1

Every pending check response is a JSON object with exactly these required fields:

- `schema_version`: integer constant `1`.
- `status`: the absolute `CheckResponseStatusV1` reference further constrained to the string constant `pending`.
- `check_token`: exactly 43 ASCII characters matching canonical unpadded base64url for 32 bytes. The first 42 characters use letters, digits, `_`, or `-`; the last character is one of `AEIMQUYcgkosw048` so unused base64 bits are zero. A producer must start with exactly 32 random bytes and emit their canonical unpadded base64url encoding.
- `retry_after_ms`: an integer from `1` through `900000` inclusive. The upper bound is a wire-value cap only, not a polling schedule or duration policy.
- `expires_at`: a real UTC whole-second instant in the exact `YYYY-MM-DDTHH:mm:ssZ` wire shape, with a year from `0001` through `9999`.
- `request_id`: the absolute `RequestIDV1` reference, accepting one through 128 ASCII letters, digits, `_`, or `-`.

Unknown fields are rejected by the strict published schema. A specifically designated Swift Pending Check Response V1 reader may discard genuinely additive unknown response members for forward compatibility, but it must continue to require and validate every known member exactly. It must reject any payload containing the known hybrid-envelope keys `verdict`, `target`, `analysis`, `source_notices`, `versions`, `evaluated_at`, `valid_until`, or `block_eligible`; those members cannot be treated as harmless future additions. This tolerant client boundary does not widen the public schema or make an unknown member meaningful.

The `check_token` rule validates only canonical encoded shape; neither the schema nor decoding proves issuance, randomness, entropy, secrecy, ownership, purpose, digesting, replay resistance, report linkage, authentication, or server-side handling. The timestamp and retry value likewise prove no relationship, schedule, completion behavior, or lifetime policy. This contract defines wire structure only. It defines no endpoint, HTTP behavior or status, polling behavior, token issuance or entropy proof, authentication or transport, App Attest behavior, completion guarantee, TTL, deletion, retention, persistence, storage, network behavior, or deployment.

The `expires_at` pattern rejects fractions, offsets, lowercase `z`, and year `0000`; asserted `date-time` format validation also rejects impossible calendar instants. All bounded string grammars are ASCII, so their schema code-point limits equal their UTF-8 byte limits.

## Problem V1

Every problem is a JSON object with these required fields:

- `type`: a nonempty ASCII RFC 3986 URI reference of at most 256 bytes.
- `title`: nonempty approved copy of at most 128 UTF-8 bytes, without Unicode control or format characters.
- `status`: an integer from `400` through `599`.
- `code`: a forward-compatible lower-snake-case ASCII value of at most 128 bytes. It begins with a lowercase letter and has no doubled or trailing underscore.
- `detail`: nonempty, non-sensitive copy of at most 512 UTF-8 bytes, without Unicode control or format characters.
- `request_id`: the absolute `RequestIDV1` reference, accepting one through 128 ASCII letters, digits, `_`, or `-`.
- `retryable`: a Boolean.

`retry_after_seconds` is optional. When present, it is an integer from `0` through `86400`, and `retryable` must be `true`. Unknown fields are rejected by the public server schema. A specifically designated response reader may tolerate additive unknown response members while continuing to enforce all known-field invariants.

### Problem validation boundary

Draft 2020-12 `minLength` and `maxLength` count Unicode code points, not UTF-8 bytes. The ASCII patterns make the `type`, `code`, and `request_id` byte limits exact in the schema. A semantic validator must separately enforce the 128-byte `title` and 512-byte `detail` limits after decoding. It must reject invalid values without echoing attacker-controlled content.

The schema uses the standard `uri-reference` format for `type`. Strict validation of the fixture manifest therefore requires a Draft 2020-12 validator configured to assert formats, not one that treats `format` as annotation only. The accompanying ASCII pattern is an independent allowed-character constraint; it does not replace RFC 3986 syntax validation.

## Verdict primitives V1

`VerdictLabelV1` is a standalone string enum with exactly four values: `unknown`, `no_known_danger`, `caution`, and `dangerous`. It accepts no aliases, including internal or action vocabulary.

`RecommendedActionV1` is a separate standalone string enum with exactly four values: `allow`, `warn`, `avoid`, and `retry`. It accepts no automatic-block alias or verdict-label value.

These standalone primitives validate individual wire values only. They neither define label/action pair coherence nor authorize a complete verdict or check-response envelope.

## Verdict V1

`VerdictV1` is a strict object with exactly five required members: `label`, `recommended_action`, `confidence`, `evaluated_scope`, and `reasons`. It accepts exactly these label/action pairs: `unknown` with `warn` or `retry`, `no_known_danger` with `allow`, `caution` with `warn`, and `dangerous` with `avoid`. The schema does not decide which cause of an `unknown` result selects `warn` rather than `retry`.

This object validates bounded structure and label/action coherence only. It defines or authorizes no endpoint, HTTP behavior, check-response envelope, check token, target or display value, analysis-completeness or freshness decision, unavailable-collector state, source notice, version set, response lifetime, automatic block eligibility, or other enforcement decision. In particular, a structurally valid `no_known_danger`/`allow` value cannot authorize completed-response serialization without the selected profile's completeness and freshness requirements, and `dangerous`/`avoid` never implies block eligibility.

## Verdict-supporting primitives V1

`ConfidenceCategoryV1` and `EvaluatedScopeV1` are standalone strings using the shared stable-value grammar: one through 128 ASCII bytes, beginning with a lowercase letter, with no doubled or trailing underscore. They are deliberately not enums, so new valid stable values remain additive. Confidence is a bounded category rather than an internal score or consumer probability; an evaluated scope value alone makes no coverage claim. `exact_url` is the only documented public V1 scope here. Other grammar-valid synthetic fixtures prove additive parsing behavior without publishing another scope meaning.

`VerdictReasonsV1` is an ordered array containing zero through five strict `VerdictReasonV1` items. Array order is preserved. Duplicate items remain structurally valid because this primitive has no `uniqueItems` rule; semantic reason selection or deduplication belongs to a later verdict policy.

These supporting primitives validate bounded wire values and an ordered reason collection only. They do not define verdict label/action coherence, a canonical Verdict object, or an evidence-bearing complete check-response envelope.

## Verdict reason V1

Every verdict reason is a JSON object with exactly these required fields:

- `code`: a forward-compatible stable reason code.
- `family`: a forward-compatible reason family.
- `severity`: a forward-compatible reason severity.
- `summary_key`: a dot-separated localization key for approved copy.
- `observed_at`: the canonical UTC whole-second instant when the supporting fact was observed.
- `freshness`: a forward-compatible evidence-freshness category.

`code`, `family`, `severity`, and `freshness` use the lower-snake-case ASCII grammar: one through 128 bytes, beginning with a lowercase letter, with no doubled or trailing underscore. They are deliberately not enums so new valid stable values remain additive. Each `summary_key` segment uses the same grammar and one-through-128-byte bound; the complete dot-separated key is at most 256 bytes. Unknown fields are rejected by the public server schema.

`observed_at` has the exact `YYYY-MM-DDTHH:mm:ssZ` wire shape. Strict validation must assert the standard `date-time` format as well as the exact pattern: the pattern rejects fractions, offsets, and lowercase `z`, while format validation rejects impossible calendar instants. All bounded string grammars are ASCII, so the schema's code-point limits equal their UTF-8 byte limits.

This standalone reason primitive does not define or authorize a complete verdict or check-response envelope.

## Explicit exclusions

These artifacts contain only request, request-ID, problem, check-response-status, pending-check-response, verdict, verdict-reason, and standalone verdict-supporting shapes with reserved or synthetic examples. They define no endpoint, deployment, HTTP or polling behavior, token or request-ID issuance or entropy proof, authority, lifetime, retention or logging permission, storage, network or other I/O behavior, cross-plane identity, complete check-response envelope, automatic block eligibility, or unrelated product data. All fixture hosts use the reserved `.test` namespace and are intended for offline validation only.
