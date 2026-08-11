# ADR 0005: Pinned IANA address-classification profile

| Field | Value |
|---|---|
| Status | Accepted |
| Decision date | 2026-08-11 |
| Accountable role | Founder/technical owner |
| Required reviewers | Security, infrastructure, iOS, and legal/source-rights roles |
| Scope | Deterministic offline IPv4 and IPv6 registry classification for the local URL-policy core; no destination authorization or network enforcement |
| Related decisions and risks | D-009, D-012, D-021, P-013, O-006, O-020, R-005, R-010, and R-014 from [document 12](../12-risks-decisions-and-open-questions.md) |
| Supersedes | None |
| Superseded by | None |
| Evidence references | [Sandbox and security requirements](../08-sandbox-and-security.md), [repository rules](../../AGENTS.md), the exact source table below, and the [dependency review package](../../packages/iana-address-registries/README.md), projection, and tests prepared under this decision |

## Context

[Document 08](../08-sandbox-and-security.md) requires every destination address to be checked against pinned IANA special-purpose data before a future egress connection. A two-registry special-purpose list alone is not a complete classification profile: the special-purpose registries do not provide an exhaustive partition of IPv4 and IPv6 space, and ordinary multicast space requires explicit treatment. A broader, deterministic profile is needed to distinguish a registry-space candidate from special-purpose, multicast, reserved, or otherwise unallocated space without using a live lookup.

The local core now has a validated host representation that distinguishes domain names, IPv4 literals, and IPv6 literals and retains canonical packed address bytes. That is sufficient to prepare a pure offline classifier. It is not authority to resolve a domain, contact an address, or decide that a destination is safe or permitted.

The founder/technical owner accepted the data dependency and update policy on 2026-08-11. Dependency-bearing classifier code, bundled registry snapshots, generated projections, manifests, and related public implementation claims **were not permitted to merge until the accountable owner accepted this ADR**. That authority prerequisite is now satisfied, but acceptance approves the choice only: it does not assert that an implementation exists, has passed review, or may merge without its ordinary build, test, source-rights, security, and diff gates.

## Decision drivers

- Cover the full IPv4 and IPv6 address space deterministically rather than infer ordinary space from the absence of a special-purpose match.
- Ensure every IANA special-purpose match remains special-purpose even when its registry row says it is globally reachable.
- Cover IPv4 and IPv6 multicast explicitly instead of assuming the special-purpose registries contain it.
- Keep classification reproducible, offline, fail-unavailable, and independent of runtime registry changes.
- Preserve source provenance, exact bytes, licensing evidence, and a manual review path for every update.
- Keep this primitive narrower than DNS, reachability, egress, SSRF, or consumer-verdict policy.

## Options considered

### Option A: Four pinned IANA registries and a validated offline projection

Pin exact XML snapshots of the IPv4 and IPv6 special-purpose registries and the IPv4 and IPv6 address-space registries. Preserve their provenance and rights evidence, derive one deterministic bundled projection, validate that projection before use, and classify packed address bytes using longest-prefix matching with special-purpose precedence.

This adds a reviewed data dependency and update burden, but gives one reproducible source profile for both narrow exceptions and broader registry-space categories.

### Option B: Special-purpose registries plus hard-coded broad ranges

Pin only the two special-purpose registries and encode the remaining IPv4, IPv6 global-unicast, multicast, and reserved ranges directly in source. This is smaller, but splits provenance between data and code and makes future registry changes easier to miss or misclassify.

### Option C: Fetch current registries at runtime

Download and parse current IANA data when the classifier starts or refreshes. This appears fresher, but creates a network dependency, makes results non-replayable, and allows an upstream change or parser failure to alter destination classification without a reviewed release.

### Keep the current state

Retain the validated host value but provide no complete address classifier. This avoids a dependency decision, but leaves the documented special-address boundary unimplemented and cannot support later destination-policy work.

## Decision

Select **Option A: four pinned IANA registries and a validated offline projection**.

The accepted profile pins these exact upstream files byte for byte:

| Registry snapshot | Upstream revision | SHA-256 |
|---|---|---|
| [IPv4 Special-Purpose Address Space XML](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xml) | 2025-10-09 | `cf24e11f41b7d42c68debe2d18b97cac815084ec413ebb3b244f704028a16f20` |
| [IPv6 Special-Purpose Address Space XML](https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xml) | 2025-10-09 | `c17f4380ba84fb2160dae82ebfd8bd155a5853cfab624ed3a9fd251638a8be02` |
| [IPv4 Address Space XML](https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml) | 2025-10-10 | `8ca3774374c81e4a673bb12d0eb415e7ac9970c6f5a6ceb14106de64b2cb3dcd` |
| [IPv6 Address Space XML](https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml) | 2025-10-23 | `15481d1e549b481f3bd0321c5cd2c0327a00cbd3d5a6fc35fc7b53b51e70b1cb` |

The accepted rights evidence is also pinned byte for byte:

| Rights evidence | Revision/version | SHA-256 |
|---|---|---|
| [Joint IANA/IETF protocol-registry licensing statement](https://www.iana.org/help/licensing-terms) | 2021-11-10 | `9e9694eb818bcd620f153c208f431e9a0212c7202d35951f5cc3fcfe3720754b` |
| [Creative Commons CC0 1.0 legal code text](https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt) | 1.0 | `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499` |

A reviewed project overlay supplies IPv4 `224.0.0.0/4` from [RFC 1112, Section 4](https://www.rfc-editor.org/rfc/rfc1112.html#section-4) and IPv6 `ff00::/8` from [RFC 4291, Section 2.7](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.7). The projection retains those public citations and factual prefixes without importing either RFC's text.

A conforming dependency package must preserve the exact source snapshots and source-rights evidence for review. A deterministically generated offline projection may be bundled for runtime use, but it must identify all four source revisions and hashes and must not replace the original review artifacts. A conforming runtime classifier performs no network request and does not parse attacker-selected registry content.

The result vocabulary is closed to these IP categories:

- `specialPurpose`: the address matches a prefix in either pinned special-purpose registry. This category wins over every broader address-space category, including when the matched row says `Globally Reachable` is true.
- `allocatedOrLegacyIPv4`: after special-purpose and multicast checks, the pinned IPv4 address-space registry identifies the containing `/8` as `ALLOCATED` or `LEGACY`.
- `globalUnicastIPv6`: after special-purpose and multicast checks, the pinned IPv6 address-space registry identifies the containing prefix as Global Unicast.
- `multicast`: the address matches the explicit IPv4 `224.0.0.0/4` or IPv6 `ff00::/8` overlay and no special-purpose registry entry has higher precedence.
- `reserved`: after higher-precedence checks, the pinned broad address-space registry identifies the containing space as reserved or as a non-global IPv6 allocation.
- `unallocated`: an explicit no-match/default category for a valid profile. The accepted four snapshots cover both address families completely, so this exact profile is not expected to emit it. Missing, corrupt, incomplete, or unsupported dependency data is an unavailable profile, never an `unallocated` result.

Matching is longest-prefix first within the applicable registry data. Any special-purpose match takes precedence over the multicast overlays and broad address-space registry, then multicast takes precedence over the broad registry. A domain-name host is not an IP classification and returns a distinct not-applicable result.

Every IP result must record the address family and `sourceRevision` exactly as `iana-address-profile-v1`; separate verified integrity constants identify the exact projection bytes. A matched registry entry may additionally expose only bounded public provenance: canonical prefix, registered name, and a verified source value containing its identifier, pinned update revision or normative RFC section, and public URL. The source representation must cover all four IANA registries and two RFC multicast overlays without treating an unknown source as trusted. String, debug, reflection, error, and log surfaces remain content-free and must not expose the classified host or address.

The classifier is **classification only**. In particular, `allocatedOrLegacyIPv4` and `globalUnicastIPv6` mean only that the address is a broad registry-space candidate. No category means allowed, safe, trusted, reachable, owned by an expected organization, or suitable for a connection.

This decision and its result vocabulary make no claim about DNS, reachability, routability, safety, trust, a consumer verdict, connection eligibility, egress permission, SSRF resistance, redirect or rebinding handling, mixed-answer handling, organization or deployed VPC/corporate coverage, network behavior, persistence, UI behavior, enforcement, or passage of any Stage gate.

The dependency is updated only by an explicit, manually reviewed change that pins new exact bytes, refreshes revision/hash/count metadata, regenerates the projection, shows the semantic prefix/category diff, and passes the full regression suite. There is no automatic registry sync and no runtime fallback to live or platform data. A registry update cannot silently widen later egress.

If any required bundled asset is absent, malformed, unsupported, inconsistent, or fails its exact integrity checks, classifier construction must fail with a bounded content-free unavailable error. It must not return a permissive category, use stale unverified bytes, infer `unallocated`, or fetch a replacement.

## Consequences

### Benefits

- Classification is deterministic and replayable against one explicit four-source revision.
- Special-purpose overlaps and globally reachable exceptions cannot be mistaken for ordinary space.
- Multicast and broad reserved space are covered even where the special-purpose registries alone are incomplete.
- Exact source bytes, license evidence, projection derivation, and update review remain auditable.
- The local core can gain a reusable pure primitive without creating a network, persistence, or service boundary.

### Costs and limitations

- Four upstream snapshots, a derived projection, integrity metadata, and regression fixtures must be maintained together.
- Pinned data becomes stale until a reviewed update ships; freshness must be observable through the source revision rather than hidden by a runtime refresh.
- This profile does not contain deployed Hezo, VPC, subnet, overlay, pod, service, node, cluster-DNS, host-gateway, corporate, or provider-specific ranges.
- A broad registry-space candidate may still be unreachable, unrouted, reassigned, shared, unexpected, or prohibited by later environment policy.
- The closed categories intentionally do not reproduce every upstream registry column or make those columns enforcement policy.

## Safety and rights impact

### Security

This is an offline classification primitive, not the security boundary. It creates no DNS, redirect, transport, browser, crawler, or egress flow. Future connection policy must still validate complete A/AAAA answer sets, mixed answers, every redirect and new connection, the connected peer, alternate endpoints, deployed internal ranges, and public Hezo control surfaces. It must also normalize IPv4-mapped IPv6 before classification.

Fail-unavailable behavior prevents missing or corrupt registry data from becoming an implicit public-destination decision. The profile cannot by itself satisfy the SSRF, DNS-rebinding, redirect, mixed-answer, VPC, organization-network, or sandbox gates in documents 08 and 10. Enforcement scope and stage-gate status do not change.

### Privacy and retention

A conforming classifier operates in memory on a validated host value. It performs no collection, DNS lookup, telemetry, analytics, persistence, or retention. It creates no account or cross-plane identifier. The address and original URL must not appear in descriptions, errors, reflection, logs, metrics labels, or test diagnostics. This record changes no raw-URL retention rule or public privacy claim.

### Sources, licensing, and dependencies

The four data files are IANA protocol-registry data. The [joint IANA/IETF licensing statement](https://www.iana.org/help/licensing-terms), revised 2021-11-10, says the protocol registries may be freely used for any purpose and places any applicable IANA/IETF rights under the [Creative Commons CC0 1.0 dedication](https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt). The dependency package must preserve exact copies of the statement and legal code with their source URLs and integrity metadata. CC0's disclaimers remain applicable; the data carries no warranty and does not affect third-party patent, trademark, privacy, or other rights. The statement does not extend CC0 to linked RFCs or other linked material; the two overlays retain citations and factual prefixes only.

This decision adds registry data, not a third-party runtime library or executable. Its purpose is address classification; it receives no product data and has no runtime data access. Removal means deleting the snapshots and their derived projection and rebuilding without this classifier. Any durable derivative that later depends on a recorded profile revision must be recomputed or marked unavailable before removing that revision.

## Migration and compatibility

A conforming classifier consumes canonical packed bytes from the existing validated-host boundary, avoiding a second parser. Existing URL syntax acceptance, wire contracts, manual-entry UI, and domain handling do not change. Domain hosts receive the distinct not-applicable result; they are not resolved by this slice.

There is no data migration because this decision creates no persistence. Future callers must treat the category as descriptive input to a separately reviewed policy and must not branch from a broad candidate directly to a connection. A later production egress profile must add environment-specific deny ranges and connection-time controls without weakening this registry baseline.

## Rollback

Before an implementation merges, rollback is deletion of the unmerged classifier, projection, dependency package, tests, and implementation-status claims; this Accepted decision may then be superseded or deprecated through the ADR process if the profile is abandoned. After implementation, an integrity, derivation, license, or classification defect requires disabling the dependent caller, restoring the last reviewed pinned profile when safe, or making classification unavailable. Do not fetch current data or retain an unverified profile as an emergency shortcut.

No user, service, database, network, or provider cleanup is required because this slice creates none. The technical owner verifies rollback with clean offline builds/tests and a dependency/source scan.

## Verification

- Verify every pinned XML and rights file byte count, line-ending policy, and SHA-256 against the strict dependency manifest.
- Validate the manifest and generated projection with closed schemas, exact profile revision, source hashes, supported categories, record counts, and derivation rules.
- Recompute the projection independently from the exact XML and require semantic equality with the bundled runtime projection.
- Test every source row, canonical network boundary, adjacent non-match, family, overlap, and longest-prefix rule.
- Prove every special-purpose match returns `specialPurpose`, including registry rows marked globally reachable.
- Prove `224.0.0.0/4` and `ff00::/8` return `multicast` when no special-purpose entry takes precedence.
- Test all broad IPv4 statuses and IPv6 address-space descriptions, and prove a missing profile record is never treated as a permissive result.
- Test absent, truncated, corrupt, hash-mismatched, revision-mismatched, count-mismatched, duplicate, overlapping, and unsupported assets; each must fail unavailable with bounded content-free output.
- Prove domain hosts are not applicable and IPv4-mapped IPv6 is normalized before this boundary.
- Verify descriptions, debug output, reflection, errors, logs, and test failures do not reveal the host, address, or original URL.
- Run the full offline SwiftPM and shared Xcode scheme tests, strict formatting, static review, dependency/source-rights review, secret/signing scans, Markdown-link checks, ADR-index checks, and diff review.

Acceptance of this ADR approves the pinned dependency and classification profile only. It does not assert that implementation, source freshness, Stage 0, Stage 1, Stage 2, SSRF, sandbox, egress, release, or production gates passed.

## Follow-up and review

- **Founder/technical owner:** verify that any dependency-bearing implementation stays within this accepted profile; a material source, category, precedence, failure, or update-policy change requires a new ADR.
- **Security role:** review precedence, complete-space behavior, fail-unavailable handling, content-free output, and the explicit non-enforcement boundary.
- **Infrastructure role:** keep later deployed/private/Hezo ranges and connection-time checks outside this registry primitive and under versioned environment policy.
- **Legal/source-rights role:** verify the exact IANA/IETF statement, CC0 legal code, preserved hashes, and redistribution notices.
- **iOS role:** verify the pure classifier and resources work identically through SwiftPM and the shared Xcode scheme without network access.
- Reconsider this decision when any upstream registry revision changes, a source or rights statement changes, an unknown upstream status appears, a category becomes ambiguous, or a caller proposes using classification as permission.
