# Hezo Link contract components

This directory is the public, offline source of truth for the first check-input wire contract described in [API and message contracts](../../docs/06-api-contracts.md). It contains only data contracts and synthetic examples. It does not define a deployed service.

## Artifacts

- `openapi-components.json` is an OpenAPI 3.1 components document. Its `paths` object is deliberately empty and it declares no server or security scheme.
- `schemas/check-request-v1.schema.json` is the strict Draft 2020-12 request schema.
- `fixtures/check-request-v1/manifest.json` lists deterministic, reserved-domain valid and invalid examples and their expected schema result.

The OpenAPI component references the standalone JSON Schema so there is one request-shape definition to keep current.

`CheckRequestContractAssetTests` runs in both SwiftPM and the shared Xcode scheme. It pins the exact V1 schema surface, resolves the OpenAPI and manifest references, checks complete unique fixture coverage, and independently evaluates every declared fixture result and failure keyword. That test is deliberately limited to this frozen contract subset; it is not a general JSON Schema implementation. Expanding the schema vocabulary requires a versioned contract change and selected strict Draft 2020-12 validation tooling rather than silently widening the local evaluator.

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

## Explicit exclusions

These artifacts contain only a request shape and reserved-domain examples. They define no deployment, I/O behavior, identity material, or unrelated product data. All fixture hosts use the reserved `.test` namespace and are intended for offline validation only.
