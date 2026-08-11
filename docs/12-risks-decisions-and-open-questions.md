# Decisions, risks, and open questions

This is the sanitized public decision register. It contains architectural decisions, generic accountable roles, and public-safe risk handling needed to implement and review Hezo Link. Never add personal owner details, exact budgets, vendor negotiations, Apple identifiers or submissions, incident evidence, exploit detail, contracts, credentials, device logs, or private approval records here. Those belong outside Git or in the ignored `.private/` workspace; this document may link only an opaque approved reference or sanitized outcome.

## Status vocabulary

- Accepted: implementation must follow this decision unless an ADR supersedes it.
- Proposed: recommended default; implementation needs an ADR or owner confirmation.
- Open: a named decision is required before the listed stage.
- External: controlled partly by Apple, a provider, or another third party.

## Accepted product decisions

| ID | Decision | Rationale |
|---|---|---|
| D-001 | Hezo Link solves dangerous-link and fake-website protection first. | Narrow job, clear consumer value, and a graph-shaped data moat. |
| D-002 | iPhone and iOS 26 are first; US English intelligence is first. | URL Filter availability and focused brand/campaign coverage. |
| D-003 | V1 is free and has no account. | Core functionality needs no identity; active protection matters more than registrations. |
| D-004 | Manual paste, share, and QR checking are independent of URL Filter. | Apple approval must not become a single product kill switch. |
| D-005 | The four user verdicts are Unknown, No known danger, Caution, and Dangerous. | Express uncertainty and avoid absolute safety claims. |
| D-006 | Dangerous and block eligible are separate. | Automatic enforcement needs a higher false-positive bar. |
| D-007 | Initial beta auto-blocking uses only current, qualified, precisely scoped Route A evidence. | Protect users while proprietary heuristics are still being calibrated. |
| D-008 | Route B and Route C are implemented behind separate disabled flags. | Detection value can be measured in shadow mode before enforcement. |
| D-009 | Evidence scope limits enforcement scope. | Prevent catastrophic shared-host and platform false positives. |
| D-010 | Observations are immutable; every derivation and decision is versioned. | Reproducibility, audit, correction, and source removal. |
| D-011 | PostgreSQL is the initial graph store; Neo4j is not a launch dependency. | Relational constraints, operations, and V1 graph scale are sufficient. |
| D-012 | The raw submitted URL is preserved only for transient analysis. | Query and fragment may carry security meaning but also sensitive data. |
| D-013 | Security intelligence, anti-abuse, MPD, and product analytics are separate production data planes. | Prevent identity or behavioral joins by architecture. |
| D-014 | MPD and product analytics are separate, optional consents. | Measurement is not required to provide protection. |
| D-015 | MPD is a consented installation-month measure, not a hardware-device claim. | Reinstalls, restores, opt-out, and background limits prevent literal unique-device truth. |
| D-016 | App Attest is anti-abuse evidence, not user identity or analytics. | Validates app installation requests without creating a product profile. |
| D-017 | URL Filter is fail open in consumer V1. | An availability incident must not break normal browsing. |
| D-018 | Models create bounded signals or explanations, never sole verdict/block authority. | Current model outputs are not durable evidence and are evadable. |
| D-019 | A campaign is an operational cluster, not attacker attribution. | Avoid unsupported legal and product claims. |
| D-020 | Future revenue comes from Hezo-owned/licensed threat intelligence, not user behavior. | Align business incentives with a digital-trust brand. |
| D-021 | Reversible local product foundations may begin before every Stage 0 proof passes, within the no-network, no-live-data, and no product/service/provider/production-state boundary in [ADR 0002](adr/0002-local-first-product-foundation.md). [ADR 0003](adr/0003-offline-manual-entry-prototype.md) adds one transient offline manual-entry UI that uses the existing local syntax validator and content-free status. Owner-local Apple development provisioning is the sole non-proof external-state exception. | Converts reviewed contracts and one bounded offline interaction into executable code without treating blocked Apple, provider, cloud, or privacy work as approved. |

## Accepted technical decisions

| ID | Decision | Authority and limits |
|---|---|---|
| P-001 | Swift and SwiftUI for the iOS product; Swift Package Manager for pure Swift product-core modules. | Accepted by [ADR 0002](adr/0002-local-first-product-foundation.md); [ADR 0003](adr/0003-offline-manual-entry-prototype.md) additionally permits one transient offline manual-entry surface using local syntax validation. Owner-local automatic signing is allowed, but no connected check, persistence, extension, entitlement, device/TestFlight proof, external distribution, or committed signing identity is authorized. |
| P-002 | OpenAPI 3.1 and JSON Schema are the shared wire-contract sources. | Accepted by [ADR 0002](adr/0002-local-first-product-foundation.md); generation is verified in later slices. |
| P-004 | Use a modular control plane plus worker and split deployables only at security or scale boundaries. | Accepted by [ADR 0002](adr/0002-local-first-product-foundation.md); managed-service topology remains open. |
| P-013 | Pin exact XML snapshots of the IANA IPv4/IPv6 special-purpose and address-space registries under the IANA/IETF CC0 statement, derive one validated offline profile, apply longest-prefix matching with special-purpose precedence and explicit multicast overlays, update only by manual review, and fail unavailable. The closed categories are `specialPurpose`, `allocatedOrLegacyIPv4`, `globalUnicastIPv6`, `multicast`, `reserved`, and `unallocated`; broad categories are registry-space candidates only. | Accepted by [ADR 0005](adr/0005-pinned-iana-address-profile.md). Acceptance selects the data dependency and classification profile only; it does not claim the classifier is implemented, approve a connection or egress decision, or pass any proof, stage, SSRF, sandbox, release, or production gate. |

## Proposed technical decisions

Every entry remaining in this table is **Proposed** until its named decision point produces an owner-approved record. Listing a proposal here, assessing public terms in document 09, or adding a synthetic fixture does not accept it. P-010 and P-011 are explicitly still Proposed.

| ID | Proposal | Decision point |
|---|---|---|
| P-003 | PostgreSQL 17 or later with application-generated time-sortable UUIDs. | ADR before first migration. |
| P-005 | Managed queue, object storage, KMS, and secrets service in a US region. | Cloud ADR in Stage 0. |
| P-006 | Hardware-virtualized disposable worker per dynamic crawl. | Sandbox ADR before Stage 4. |
| P-007 | V1 browser navigation supports HTTP/HTTPS on ports 80 and 443 only. | Threat-model review in Stage 0; surface unsupported port truthfully. |
| P-008 | Raw URLs have a 24-hour hard maximum and a shorter normal target. | Privacy/legal approval before Stage 2. |
| P-009 | Raw MPD tokens live for current month plus 45-day correction window. | Privacy approval before Stage 8. |
| P-010 | Google Web Risk Lookup is the candidate initial commercial exact-source integration; no provider is selected yet. | Stage 0 viability, rights, and proof-spend decision; production cost, terms, account, and procurement approval before Stage 2. |
| P-011 | CISA dot-gov data is candidate official-US-government relationship enrichment only; it cannot satisfy the qualified exact-threat source gate. | Source-rights and ingestion review before Stage 3. |
| P-012 | Product analytics is omitted unless specific V1 questions justify an event allowlist. | Product/privacy review before Stage 8. |

## Open decisions

These are deliberate owner decisions, not invitations for Codex to guess.

| ID | Decision required | Owner | Needed by |
|---|---|---|---|
| O-001 | Select the Go HTTP framework or standard-library-only approach and any cross-language build orchestration. Swift/SwiftPM, Go/Go modules, and the public monorepo are already accepted by ADR 0002. | Backend lead/founder | Before the first Go service slice |
| O-002 | Exact AWS US region, environments, network model, managed capacity, and operation within the private owner-controlled spending ceiling. | Infrastructure owner | Before creating cloud state |
| O-003 | Managed queue, cache, object storage, KMS, secrets, and observability vendors. | Infrastructure owner | Stage 1 |
| O-004 | Apple Developer team, bundle IDs, App Groups, signing ownership, and entitlement-request owner. | iOS owner | Stage 0 |
| O-005 | Accountless PIR bearer-token design accepted by Apple/sample implementation. | iOS/security owner | Stage 0 |
| O-006 | Production sandbox isolation technology and patch SLA ownership. | Security/infrastructure | Stage 0 |
| O-007 | Exact raw-URL retention, incident-hold authority, and backup deletion windows. | Privacy/legal/security | Stage 2 |
| O-008 | Stage 0: decide qualified exact-threat source viability, rights, and bounded proof spend. Before Stage 2: approve production procurement/contract, provider account, cost controls, and annual source budget. | Founder/legal | Stage 0 exit / before Stage 2 |
| O-009 | Initial protected-brand registry and evidence needed to call a domain official. | Product/intelligence | Stage 3 |
| O-010 | Public privacy policy, final consent copy, App Store label, and age-rating decisions. Restricted internal Stage 0 distribution testing still requires privacy-counsel-approved proof-scoped preliminary artifacts and all applicable platform prerequisites, but does not close this final launch decision. | Product/privacy/legal | Before external TestFlight or public beta |
| O-011 | Exact public wording and display location for MPD. | Founder/product/privacy | Stage 8 |
| O-012 | Support channel, analyst/reviewer roles, false-positive SLA, and on-call ownership. | Operations | Public beta |
| O-013 | Independent penetration-test/security-review provider and budget. | Founder/security | Stage 9 |
| O-014 | Whether manual-only V1 remains a go if URL Filter production approval fails. | Founder | Stage 0 exit |
| O-015 | Whether ports beyond the accepted 80/443 V1 default are necessary and how their abuse is contained. Until this is approved, every other port remains unsupported. | Security/product | Before enabling any non-default port |
| O-016 | Whether an exceptional report/analyst artifact hold needs the full seven-day maximum or a shorter maximum. Retention beyond seven days is not authorized without a new decision. | Intelligence/privacy/legal | Stage 4 |
| O-017 | Exact lifecycle for restricted report URL/comment/receipt, deletion-capability and idempotency digests, per-record key destruction, backups, and report-only derived support. The proposed ceiling is delete after triage/derivation and no later than 30 days, with a 24-hour replay digest. | Privacy/legal/intelligence/operations | Before Stage 6 |
| O-018 | Exact inactivity and absolute expiry for Apple PIR `User-Identifier` digest/evaluation-key state, validated against Apple's protocol lifecycle, capacity, and recovery behavior. | iOS/security/privacy/infrastructure | Stage 0 distribution proof |
| O-019 | Project license or explicit proprietary policy, contribution terms, and copyright owner wording. Until selected, do not imply that public visibility grants reuse rights. | Founder/legal | Before accepting external contributions or promoting reuse |
| O-020 | Reconcile Stage 0 proof authorization and exit timing. [ADR 0002](adr/0002-local-first-product-foundation.md) authorizes a local product-foundation exception only; it does not authorize proof execution or resolve the Stage 0 exit. | Founder/technical/privacy | Before Stage 0 gate review |

## External dependencies and kill risks

### R-001 Apple URL Filter approval and OHTTP validation

Impact: passive protection cannot ship.

Mitigation:

- apply in Stage 0;
- build only a small development proof before full integration;
- keep manual product independently useful;
- document capability status and Apple feedback;
- establish a clear manual-only go/no-go date.

Trigger: capability rejection, incompatible server validation, accountless authentication failure, or no credible approval timeline.

Response: pause Stage 7, keep manual vertical slice, and make an explicit product decision rather than disguising the limitation.

### R-002 Coverage is narrower than “all traffic”

Impact: misleading marketing and protection gaps in nonparticipating network stacks.

Mitigation:

- test Safari, WebKit, URLSession, voluntary participants, and nonparticipants;
- describe coverage precisely;
- never market the product as packet-level antivirus or every-app interception.

### R-003 False-positive harm

Impact: blocked legitimate services, user harm, brand damage, emergency App Store reviews, or legal disputes.

Mitigation:

- exact scope;
- Route A only in initial beta;
- no weak/model/community sole blocks;
- difficult-benign corpus;
- false-positive action on every verdict;
- signed rollback, tombstones, overrides, and kill switches;
- two-person approval for policies that broaden automatic blocking.

Trigger: any confirmed false auto-block on an official or shared-host page.

Response: remove/rollback immediately, freeze broadening changes, determine blast radius, add a regression, and require review before re-enable.

### R-004 Seed-source rights are insufficient

Impact: connector shutdown, forced evidence deletion, invalid B2B outputs, or legal exposure.

Mitigation:

- source-rights registry and terms snapshots;
- default production/redistribution/model-training permissions to false;
- evaluate the proposed commercial exact-threat candidate without treating P-010 or any public-terms label as selection or approval; noncommercial Safe Browsing remains blocked;
- keep PhishTank, OpenPhish, and URLhaus community connectors off until written rights;
- recompute derived outputs when a source is disabled.

Real terms archives, contracts, negotiated budgets, provider-account details, credentials, named decisions, and proof evidence remain restricted and human-controlled. Git may contain only public-source assessments, synthetic contracts/vectors, generic roles, sanitized outcomes, and opaque references.

### R-005 Sandbox escape or SSRF

Impact: production compromise, cloud credential theft, internal reconnaissance, abuse of Hezo infrastructure.

Mitigation:

- separate analysis network/account;
- microVM per crawl;
- no guest secrets or production routes;
- controlled resolver and mandatory proxy;
- deny all special/internal IPv4/IPv6 destinations on every connection;
- one-job capabilities;
- signed images, patch SLA, conformance tests, and emergency pool shutdown.

Trigger: any boundary canary contact, unexpected egress, host integrity event, or plausible escape.

Response: stop scheduling, cut egress, revoke credentials, quarantine outputs, rebuild from known good, investigate, and require security approval.

### R-006 Crawler is abused as a scanner or denial-of-service tool

Impact: provider complaints, target harm, cost, IP blocking, or legal exposure.

Mitigation:

- App Attest/rate limits;
- HTTP(S) only and proposed 80/443 restriction;
- no arbitrary methods, headers, uploads, form submission, clicks, or authentication;
- per-installation, per-domain, per-IP, and global budgets;
- passive navigation and strict bytes/time/request caps;
- abuse monitoring and destination denylist.

### R-007 Data-plane separation erodes

Impact: Hezo can link device/install identity with URL or behavior, invalidating the privacy promise.

Mitigation:

- separate stores, accounts, credentials, queues, domains, and logs;
- contract field deny lists and schema tests;
- no cross-plane warehouse;
- privacy review for every new event or operational join;
- short retention and edge-log suppression;
- prohibit support tooling with multi-plane access.

Trigger: a stable identifier and security entity appear in the same request, table, log, trace, queue, or analyst view.

Response: stop the flow, treat as a privacy incident, delete/rotate where possible, review disclosures, and add a regression.

### R-008 MPD is misunderstood or inflated

Impact: deceptive public claim and poor internal decisions.

Mitigation:

- call it an installation-month measure internally;
- publish exact definition and date range;
- count only consented accepted tokens;
- do not extrapolate opt-out users into the count;
- document reinstall overcount and background undercount;
- keep Apple App Store active-device analytics as a separate cross-check;
- audit the aggregation query and retention.

### R-009 Cold-start intelligence adds little beyond providers

Impact: product becomes an API wrapper with weak defensibility.

Mitigation:

- benchmark incremental detection and campaign linkage separately from provider matches;
- build proprietary observations, page artifacts, brand registry, contradictions, and campaign graph;
- measure time-to-detection and newly linked threats;
- stop or redirect investment if clustering cannot beat a flat exact list.

Trigger: after Stage 5, graph features do not produce high-precision novel relationships or materially earlier warnings.

### R-010 External source outage, corruption, or terms change

Impact: false clean results, bad blocks, cost spike, or illegal use.

Mitigation:

- per-source circuit breaker and status;
- unavailable is not clean;
- signed/import manifests and anomaly checks;
- quotas and cost caps;
- terms-change pause;
- source-specific partitions and recomputation;
- last-known-good with policy expiry.

### R-011 Stale blockset or PIR/Bloom skew

Impact: missed threats or false decisions.

Mitigation:

- one canonical manifest;
- publish PIR N before Bloom N;
- retain compatible N-1;
- signed atomic promotion;
- freshness/degraded status;
- fail open;
- rollback and kill switch.

### R-012 Legal and reputational claims

Impact: unsupported accusations, privacy enforcement, trademark complaints, or deceptive-security claims.

Mitigation:

- campaigns are not attribution;
- factual evidence and uncertainty language;
- no absolute safe guarantee;
- trademarks/logos used only as necessary for internal detection and reviewed product display;
- US privacy and consumer-protection counsel before launch;
- accurate provider attribution/advisories;
- clear correction process.

### R-013 Operating cost

Impact: a free product creates uncapped feed, crawl, storage, PIR, and support costs.

Mitigation:

- cache and exact lookup first;
- risk/novelty-based dynamic analysis;
- hard per-job budgets;
- deduplication and campaign reuse;
- source cost counters and project ceilings;
- degrade to cached/Unknown rather than create surprise spend;
- model launch and 10x scenarios before beta.

### R-014 Browser and supply-chain patch velocity

Impact: a known browser/runtime vulnerability defeats isolation.

Mitigation:

- pinned digests, SBOM, provenance, signed images;
- critical/high patch SLA;
- dedicated image canary and rollback;
- dependency scanning and minimal guest/host;
- no long-lived worker reuse.

## Metric wording decision

Internal canonical name:

> Measured Monthly Protected Installations

Marketing may use Monthly Protected Devices only with a visible methodology note:

> A measured protected device is a consented Hezo Link installation that reported URL protection enabled and healthy at least once during the stated UTC calendar month. The rotating measurement token changes monthly. Reinstalls may be counted again; protected installations that decline measurement are not counted.

The exact wording must be reviewed against the actual Stage 8 implementation. Do not say that one million people, accounts, unique humans, continuously protected devices, or all protected installations exist unless a separate measure proves it.

## Definition of ready for implementation

The documentation handoff is ready when:

- every required concern has a document;
- no contradiction remains between API, schema, privacy, verdict, sandbox, and test rules;
- primary external requirements are linked;
- Stage 0 decisions have owners;
- Codex can identify exactly one first work package;
- application code has not been prematurely scaffolded.

[ADR 0002](adr/0002-local-first-product-foundation.md) authorizes a narrow local product-foundation exception: bounded local S1-A code may overlap incomplete Stage 0 proofs, but it creates no live, paid, device-distribution, provider, crawler, database, or production state. [ADR 0003](adr/0003-offline-manual-entry-prototype.md) adds only a transient offline manual-entry surface with local syntax status; it does not authorize a connected check, persistence, telemetry, destination action, distribution, or safety verdict. [ADR 0005](adr/0005-pinned-iana-address-profile.md) and P-013 accept the exact four-registry address-classification dependency and profile only. Acceptance does not assert that a classifier is implemented or verified, and it does not authorize DNS, reachability, a connection, egress, SSRF enforcement, persistence, UI, a safety verdict, or any stage/proof gate claim. O-020 remains open for Stage 0 proof authorization and exit, so the conservative rule still applies to those proof runs until a synchronized owner outcome replaces it. The complete Stage 0 exit is still required before Stage 2, a user-facing release, or any operation that consumes a blocked decision. The Stage 0 viability/rights/proof-spend portion of O-008, O-014, O-018, the required S0-A through S0-F proof outcomes, and privacy-owner approval of the Stage 0 data inventory and canonical MPD definition/limitations remain incomplete until evidenced. The production procurement/account/annual-budget portion of O-008 must be approved before Stage 2 integrates or calls a production source. O-017 must be decided before Stage 6 report intake begins.

## Change policy

When an accepted decision changes:

1. Write an ADR explaining context, options, decision, privacy/security/source impact, migration, and rollback.
2. Update every affected contract and document in the same change.
3. Add a test that would have failed under the old unstated assumption.
4. Re-run verdict replay and, if enforcement can change, the frozen false-positive and blockset gates.
