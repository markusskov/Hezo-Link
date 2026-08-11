# ADR 0004: Pin the Public Suffix List for offline domain classification

| Field | Value |
|---|---|
| Status | Accepted |
| Decision date | 2026-08-11 |
| Accountable role | Founder / technical owner |
| Required reviewers | Security, privacy, and source-rights reviewers |
| Scope | Offline registrable-domain classification in the bounded Swift product core |
| Related decisions and risks | D-009, D-010, D-021, P-001, O-019 |
| Supersedes | None |
| Superseded by | None |
| Evidence references | `packages/public-suffix-list/`; `Sources/HezoLinkCore/Resources/PublicSuffix/` |

## Context

The accepted local foundation permits offline URL-policy interfaces and tests, but the URL parser intentionally does not infer a registrable domain. A versioned Public Suffix List (PSL) is needed to distinguish a public suffix from the next registrable label without treating shared hosting as one organization.

This is a source and runtime-data dependency. The choice of snapshot, ICANN versus PRIVATE coverage, license handling, update policy, and failure behavior must be explicit before the classifier governs implementation. The classifier remains a local representation helper; it does not authorize the destination-preview UI, a completed check response, network access, or any safety or enforcement decision.

## Decision drivers

- Preserve D-009 by distinguishing mutually untrusted tenants on shared private-domain platforms.
- Use the upstream algorithm and data without creating a second, silently divergent domain policy.
- Keep behavior deterministic, offline, versioned, reviewable, and removable.
- Retain exact source and license bytes so source-rights review is reproducible.
- Fail without accepting a corrupt or ambiguous ruleset.
- Avoid turning a static suffix snapshot into domain-validity, ownership, reachability, trust, or safety evidence.
- Introduce no network, DNS, persistence, telemetry, identifier, or retention behavior.

## Options considered

### Option A: Verbatim full ICANN and PRIVATE snapshot

Pin an immutable official PSL snapshot and its MPL-2.0 license verbatim. Use both the ICANN and PRIVATE sections with no runtime policy switch. Parse and validate the snapshot locally, expose its revision and matched section, update it only through a reviewed repository change, and fail the classifier closed if the bundled asset is missing or invalid.

This preserves upstream source bytes and recognizes private-domain boundaries used by mutually untrusted hosted tenants. The verbatim file also retains upstream public comments, including submitter names and email addresses. Those comments are source provenance, not Hezo user data; their inclusion still requires an explicit public-source and privacy review.

### Option B: ICANN section only

Pin only ICANN rules. This reduces data size but can collapse separate tenants below private hosting boundaries into one registrable domain. That is a poor default for D-009 and would require every consumer to compensate consistently.

### Option C: Generated rules-only derivative

Generate a compact rules table without upstream comments. This can reduce bundle size and public personal information, but creates a modified MPL-covered artifact, requires a reproducible generator and source-availability treatment, and adds another byte-level representation that can drift. It should not be selected without a separate source-rights review.

### Keep the current state

Continue exposing only syntax-validated host forms and leave registrable-domain classification unavailable. This is the conservative no-change option, but it blocks the versioned representation needed by later target presentation and policy work.

## Decision

The decision is **Option A: Verbatim full ICANN and PRIVATE snapshot**.

The bounded Swift core will:

- pin official PSL commit `e1b8015c3b2f0f4f8c18659c2480fc1a22c07b20` and snapshot version `2026-07-25_14-20-03_UTC`;
- retain the official snapshot and MPL-2.0 license bytes verbatim;
- use both ICANN and PRIVATE rules, including the default `*`, longest-match, wildcard, and exception behavior;
- accept only a host already classified and normalized by the existing URL syntax profile;
- return the public suffix, optional registrable domain, matched section, and pinned revision;
- update the snapshot only through an explicit reviewed repository change; and
- make a missing, corrupt, or structurally inconsistent asset an unavailable classifier, without changing whether the original URL passes syntax validation.

The PSL is classification data only. It is not a domain-validity registry and provides no reachability, ownership, organizational identity, reputation, safety, navigation, provider-canonicalization, or enforcement authority.

The accountable owner accepted this decision on 2026-08-11. This acceptance authorizes the bounded offline dependency and classifier described here; all explicit nonclaims and separate product gates remain in force.

## Consequences

### Benefits

- Later consumers receive one versioned registrable-domain interpretation instead of reparsing host strings.
- PRIVATE boundaries reduce unsafe tenant collapse on shared hosting.
- Exact upstream bytes, provenance, and license remain independently reviewable.
- Offline behavior is deterministic and creates no external state or cost.

### Costs and limitations

- The application bundle gains a periodically reviewed data asset.
- Snapshot age is observable but cannot prove that the list is current at runtime.
- Upstream public comments, including submitter names and email addresses, remain in the verbatim source file.
- Conservative classification can differ after a future reviewed snapshot update.
- The classifier does not decide whether an input is a valid registrable domain or safe destination.

## Safety and rights impact

### Security

The full PRIVATE section is fixed rather than caller-selectable so consumers cannot accidentally widen a shared-host scope. Input remains the already-validated lowercase ASCII host representation; IP literals are not PSL inputs. Asset validation fails closed and ordinary errors, descriptions, debugging, and reflection must not expose the submitted host. No result authorizes a domain-wide verdict or block.

There is no runtime download, DNS request, updater, provider call, navigation, or other network path. The classifier does not change the accepted URL syntax profile or the fail-open product policy.

### Privacy and retention

No submitted host, registrable domain, or classification result is persisted, logged, measured, or sent anywhere by this decision. Existing raw-URL and four-plane rules remain unchanged. The upstream comments are public third-party source material, not product input; the source review must explicitly confirm that verbatim retention is acceptable.

### Sources, licensing, and dependencies

Purpose: offline suffix and registrable-domain classification. Data access: bundled read-only public source bytes only. License: MPL-2.0 for the list; the pinned upstream conformance test file carries its stated public-domain/CC0 treatment. Update policy: a manual reviewed change pins a new immutable revision, refreshes hashes and counts, reruns all conformance tests, and records any semantic delta. Failure behavior: the classifier is unavailable and returns no classification; URL syntax acceptance does not change. Removal policy: remove the classifier and bundled assets, retain only historical version-control records required by the repository, and perform no data migration because this scope creates no stored product data.

Official upstream sources are the [Public Suffix List](https://publicsuffix.org/list/) and its [format and algorithm specification](https://github.com/publicsuffix/list/wiki/Format).

## Migration and compatibility

The URL parser gains a typed host-kind handoff while retaining the existing ASCII-host accessor for source compatibility. The classifier is additive. No wire schema, persisted model, UI, endpoint, or provider contract changes. Future consumers must explicitly adopt the classifier revision and remain able to suppress classification when the asset is unavailable.

## Rollback

The technical owner may remove the classifier and assets if source-rights review fails, upstream semantics become unsuitable, or conformance cannot be maintained. Rollback restores the prior host-only core, removes bundle-resource membership, and reruns SwiftPM and Xcode tests. Because the decision creates no persistence or network state, rollback requires no data deletion or external teardown.

## Verification

- Verify the exact snapshot revision, version marker, byte length, SHA-256 digest, line ending, final newline, section markers, and rule counts.
- Verify the exact MPL-2.0 license and official conformance-test bytes.
- Execute the official conformance corpus plus reserved project cases for exact, longest, wildcard, exception, ICANN, PRIVATE, implicit-default, and IDNA behavior.
- Prove public-suffix inputs have no registrable domain and IP literals are not applicable.
- Reject missing, corrupt, malformed, truncated, duplicate, or mismatched assets without changing URL syntax acceptance.
- Prove deterministic concurrent results and constant, host-free diagnostics and reflection.
- Pass SwiftPM Debug and Release tests, the shared unsigned Xcode scheme, strict formatting, static analysis, source/license review, and repository safety checks.

Acceptance of this ADR approves the dependency choice only. It does not assert that implementation, Stage 0, Stage 1, product, or release gates passed.

## Follow-up and review

- Security, privacy, and source-rights reviewers must review the exact pinned bytes and public-comment treatment.
- Each snapshot update requires the same digest, license, semantic-delta, and conformance review.
- A new ADR is required before automatic updates, transformed/generated distribution, a different source or license posture, ICANN-only behavior, or any use for validity, safety, ownership, trust, or enforcement.
- Destination preview and completed-response integration remain separately gated and are not follow-up work authorized by this record.
