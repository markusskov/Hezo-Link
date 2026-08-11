# S0-F public synthetic source-rights vectors

This directory freezes the data-only contract for Stage 0 work package S0-F. It
contains strict JSON Schemas, one fictional source-rights registry,
deterministic policy-decision vectors, and a type-specific manifest. It
contains no connector, executable validator, provider call, or production
configuration.

The current published contract is fixture and construction version 2. Version
2 supersedes the first published byte contract by requiring UTC-month resource
resets at the exact month boundary. Git history retains version 1 for audit,
but the two fixture identities are not interchangeable.

Every provider and product identity ends in the IANA-reserved `.invalid`
top-level domain. All instants are permanently historical values in January
or February 2000. Thresholds use the ISO testing currency code `XTS` and
fictional units. Opaque references are project-generated fixture labels, not
URLs, file paths, contract identifiers, secret references, or provider account
identifiers.

The package contains none of the following:

- provider responses, feed rows, raw indicators, captured observations, or
  benchmark results;
- terms text, a terms-page URL, a terms snapshot, a contract, or legal advice;
- provider endpoints, credentials, secret-manager paths, account IDs, or real
  quota and price information; or
- an actual source selection, rights approval, provider proof, production
  enablement, or S0-F pass.

`selected`, `approved`, `passed`, and `production` values inside the payload
are fictional inputs needed to test the positive branch of the policy
contract. They do not describe a real provider or Hezo operational state.

## Files

- `source-rights-registry.schema.json` defines the strict registry contract:
  independent selection, proof, legal, and runtime states; immutable terms
  decisions; complete rights matrices; structured obligations; and executable
  operational policies.
- `provider-policy-vectors.schema.json` defines deterministic decision cases
  and references the registry schema by its `$id`.
- `provider-policy-vectors.json` is the public synthetic vector payload.
- `manifest.schema.json` defines the type-specific manifest contract.
- `provider-policy-vectors.manifest.json` identifies the exact payload and
  schema bytes after validation.

## Required semantic validator

JSON Schema validates structure and local contradictions. The later S0-A runner
must additionally implement the requirements listed in
`semantic_validator_requirements` in the registry. In particular, it must
resolve and isolate references, compare instants, enforce policy as an
intersection rather than a union, evaluate thresholds with projected usage,
propagate freshness and notices, and execute withdrawal/replay idempotently.

The runner must treat `[effective_at, expires_at)` as half-open. Equality with
`expires_at`, `review_expires_at`, or a computed hard-expiry instant is
expired. Missing state, missing usage, unresolved references, source
unavailability, timeout, and no match must never be interpreted as evidence
that a URL is clean.

No generator or runner is included because runnable proof work remains gated
by the accepted repository and isolated-execution decisions. Schema-valid
bytes are an expected contract, not implementation proof.
