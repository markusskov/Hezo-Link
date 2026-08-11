# Hezo Link contract components

This directory is the public, offline source of truth for the first check-input and problem wire contracts described in [API and message contracts](../../docs/06-api-contracts.md). It contains only data contracts and synthetic examples. It does not define a deployed service.

## Artifacts

- `openapi-components.json` is an OpenAPI 3.1 components document. Its `paths` object is deliberately empty and it declares no server or security scheme.
- `schemas/check-request-v1.schema.json` is the strict Draft 2020-12 request schema.
- `fixtures/check-request-v1/manifest.json` lists deterministic, reserved-domain valid and invalid examples and their expected schema result.
- `schemas/problem-v1.schema.json` is the strict Draft 2020-12 RFC 9457-style problem schema.
- `fixtures/problem-v1/manifest.json` lists deterministic problem examples and the schema keyword or keyword set each invalid example exercises.

The OpenAPI components reference the standalone JSON Schemas so there is one definition of each public shape to keep current.

`CheckRequestContractAssetTests` and `ProblemContractAssetTests` run in both SwiftPM and the shared Xcode scheme. They pin the exact V1 schema surfaces, resolve the OpenAPI and manifest references, check complete unique fixture coverage, and independently evaluate every declared fixture result and failure keyword set. These tests are deliberately limited to the frozen contract subsets; they are not a general JSON Schema implementation. Expanding the schema vocabulary requires a versioned contract change and selected strict Draft 2020-12 validation tooling rather than silently widening the local evaluators.

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

## Problem V1

Every problem is a JSON object with these required fields:

- `type`: a nonempty ASCII RFC 3986 URI reference of at most 256 bytes.
- `title`: nonempty approved copy of at most 128 UTF-8 bytes, without Unicode control or format characters.
- `status`: an integer from `400` through `599`.
- `code`: a forward-compatible lower-snake-case ASCII value of at most 128 bytes. It begins with a lowercase letter and has no doubled or trailing underscore.
- `detail`: nonempty, non-sensitive copy of at most 512 UTF-8 bytes, without Unicode control or format characters.
- `request_id`: a nonempty plane-local identifier of at most 128 ASCII bytes using letters, digits, `_`, or `-`.
- `retryable`: a Boolean.

`retry_after_seconds` is optional. When present, it is an integer from `0` through `86400`, and `retryable` must be `true`. Unknown fields are rejected by the public server schema. A specifically designated response reader may tolerate additive unknown response members while continuing to enforce all known-field invariants.

### Problem validation boundary

Draft 2020-12 `minLength` and `maxLength` count Unicode code points, not UTF-8 bytes. The ASCII patterns make the `type`, `code`, and `request_id` byte limits exact in the schema. A semantic validator must separately enforce the 128-byte `title` and 512-byte `detail` limits after decoding. It must reject invalid values without echoing attacker-controlled content.

The schema uses the standard `uri-reference` format for `type`. Strict validation of the fixture manifest therefore requires a Draft 2020-12 validator configured to assert formats, not one that treats `format` as annotation only. The accompanying ASCII pattern is an independent allowed-character constraint; it does not replace RFC 3986 syntax validation.

## Explicit exclusions

These artifacts contain only request and problem shapes with reserved-domain examples. They define no endpoint, deployment, I/O behavior, identity material, or unrelated product data. All fixture hosts use the reserved `.test` namespace and are intended for offline validation only.
