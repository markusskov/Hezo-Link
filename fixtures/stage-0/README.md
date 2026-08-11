# Stage 0 offline fixtures

This directory contains public, deterministic inputs for Stage 0 risk proofs. It is not a threat feed, benchmark corpus, production blockset, or place to preserve raw proof output.

Every fixture must be safe to inspect without network access. A checked-in fixture may use only project-generated synthetic data, IANA-reserved names, loopback services, a public standard vector whose redistribution terms permit inclusion, or a separately approved sanitized and non-executable snapshot. Approval for one snapshot does not authorize a new one.

## Required properties

Tracked Stage 0 fixtures must be:

- encoded as UTF-8, with LF line endings and a final newline;
- deterministic across locale, time zone, architecture, and repeated generation;
- ordered bytewise where the format is record based;
- identified by a stable fixture ID and versioned construction method;
- accompanied by a manifest conforming to an applicable, reviewed, type-specific schema;
- covered by an exact byte count and SHA-256 digest, plus record and uniqueness counts when the format is record based;
- safe under the [repository boundary](../../docs/stage-0/repository-safety.md); and
- usable without a live Internet route unless an approved isolated-security proof explicitly declares a different fixture mode.

Do not generate timestamps from the current clock, use nondeterministic random values, depend on local user or machine state, or silently regenerate a fixture with a different tool or algorithm. A material fixture change requires a new manifest version or fixture ID and review of every expected result that depends on it.

## Prohibited contents

Never commit:

- a live or previously submitted URL, domain, address, DNS answer, redirect, page, screenshot, HAR, capture, archive, or payload;
- a copied threat-feed row, provider response, terms snapshot, contract, private source label, or captured production observation;
- a credential, token, signing item, attestation object, receipt, device/account identifier, analytics identifier, MPD token, or canary endpoint;
- executable hostile content or content that needs to contact a third party to behave as expected;
- a hash of a raw or restricted URL presented as sanitization; unkeyed URL hashes remain guessable and linkable; or
- a generated result, log, evidence bundle, or deletion receipt that belongs in restricted proof storage.

Use the reserved .test, .example, .invalid, or .localhost namespaces as appropriate. Reserved naming is not, by itself, proof of no egress: the eventual harness must technically deny undeclared network access under an Accepted repository/execution ADR.

## Manifest contracts

The checked-in [manifest schema](manifest.schema.json) is intentionally narrow: it accepts only the project-generated, line-oriented, offline URL Filter key set described below. It must not be reused for an Apple-published vector, canary specification, structured document, or sanitized snapshot by filling those artifacts with irrelevant domain or ordering claims.

Before a different fixture class is committed, add and review a separate strict schema that represents its actual format. A public standard vector needs source provenance, original and repository-byte digests, transformation history, license/redistribution authority, and an explicit handling mode. An approved sanitized snapshot additionally needs an opaque rights/review reference, sanitization method and review, expiry or removal rule, and proof that it is non-executable. A canary specification must contain only deterministic local/isolated fixture identities, never a deployed endpoint or private route.

The manifest describes the bytes that are actually committed. Its digest.hex value is SHA-256 over the fixture file exactly as stored, including LF separators and the final newline. It is not a digest of a parsed or normalized representation.

The JSON Schema deliberately constrains:

- the file path and format;
- the deterministic construction method;
- record, uniqueness, blank-line, and ordering claims;
- the permitted reserved-domain suffixes;
- byte length and digest;
- affirmative public/synthetic safety declarations; and
- the validations completed before publication.

Schema validation cannot prove that the declarations are true. Before merge, a separate verifier must check the referenced file, count records and bytes, reject CRLF, NUL, and invalid UTF-8, enforce the declared grammar and reserved names, compare bytewise order and uniqueness, and recompute the digest. The verifier itself is part of the later S0-A harness and requires the repository and isolated-execution ADR; this governance batch does not select or implement it.

## URL Filter synthetic 1,000-entry seed

[synthetic-1000.txt](url-filter/synthetic-1000.txt) is the deterministic reserved-domain key set required by the Stage 0 URL Filter proof. Its checked-in [manifest](url-filter/synthetic-1000.manifest.json) records the exact bytes and construction.

Each line is one ASCII key:

~~~text
blocked-NNNN.example.test/path/NNNN
~~~

NNNN runs from 0001 through 1000, zero padded. The key has no scheme, user information, port, query, or fragment. The set is a canonical proof input only; it is not directly claimed to be a complete Apple Bloom or PIR artifact. The later approved proof compiler must assign integer value 1, derive Bloom and PIR inputs from the same manifest, and record the Apple tool, canonicalizer, compiler, parameter, and output digests.

The fixture intentionally contains no allow-list member or Bloom false-positive construction. Those are separate expected cases and artifacts for S0-B, created only under its approved plan.

## Change checklist

When adding or changing a fixture:

1. Confirm that its origin and intended public use are permitted.
2. Choose a stable ID, construction method, grammar, and exact safety classification.
3. Produce deterministic UTF-8/LF bytes without consulting a live service.
4. Recompute count, uniqueness, ordering, byte length, and SHA-256.
5. Update or add the applicable strict manifest schema without weakening a safety constant or borrowing fields from another fixture class.
6. Review all cases, snapshots, and evidence that reference the previous digest.
7. Run the repository public/private review before staging the change.

Never update a manifest digest merely to make an unexplained byte change pass.
