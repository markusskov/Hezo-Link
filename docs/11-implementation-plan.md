# Staged implementation plan and Codex build order

## Delivery strategy

Build Hezo Link as a sequence of narrow, testable vertical slices. The first objective is not a complete App Store UI. It is to invalidate the highest-risk assumptions before they become expensive architecture.

Rules for every stage:

- Enter only when the prior stage’s exit gate passes.
- Keep manual checking independent from Apple URL Filter.
- Keep all automatic blocking beyond qualified exact-source evidence behind disabled feature flags.
- Keep security intelligence, anti-abuse, MPD measurement, and product analytics physically separable from the first migration onward.
- Prefer a modular control plane over premature service fragmentation.
- Add observability and rollback with each capability, not after it.
- Treat documents, OpenAPI, migrations, policy fixtures, and test corpora as versioned product assets.

## Recommended implementation shape

The exact layout requires an ADR, but the implementation should converge on these responsibility boundaries:

~~~text
apps/
  ios/                    iPhone app, share extension, URL Filter integration

services/
  control-plane/          public check API, orchestration, graph and verdict modules
  worker/                 feed import, DNS/TLS/RDAP, derivation, blockset jobs
  sandbox-broker/         opaque crawl jobs and result validation
  sandbox-runner/         disposable isolated browser image
  anti-abuse/             App Attest keys, challenges, assertions, capabilities
  measurement/            consented MPD receipts and aggregates
  analytics/              optional URL-free product analytics

packages/
  contracts/              OpenAPI, JSON Schema, generated models, error catalog
  url-policy/             parsing, IDNA, provider canonicalization, redaction
  verdict-policy/         deterministic rules, reason codes, replay fixtures

infra/
  development/
  staging/
  production/

docs/
  adr/
~~~

This is a responsibility map, not permission to generate every directory on day one. Create only what the active stage uses.

Production should begin with:

- one modular control-plane deployable;
- one general background worker deployable;
- a strongly isolated sandbox plane;
- separately credentialed anti-abuse, measurement, analytics, and URL-filter distribution boundaries.

Split a module into another service only when its security boundary, scale, release cadence, or operational ownership justifies it.

## Stage 0 — kill-risk validation

### Goal

Prove that the platform, privacy, licensing, and hostile-content assumptions can support the product.

Stage 0 is allowed to create narrowly scoped proof code because its purpose is to invalidate risks. That code is not the production app or service foundation. Each spike must be isolated, use synthetic/reserved data, state its owner and question, include a teardown-or-productionization decision, and avoid creating dependencies that later stages are forced to keep.

### 0.1 Record baseline decisions

Create ADRs for:

- repository and dependency strategy;
- iOS project structure and signing environments;
- backend language and web framework;
- cloud/provider and US deployment region;
- queue, object store, secrets, and key-management choices;
- production isolation technology for dynamic crawling;
- physical database boundaries;
- URL canonicalization and exact-match representation;
- raw-URL retention and privacy disclosure;
- initial production threat sources.

Do not let a framework generator decide these implicitly.

### 0.2 Apple URL Filter proof

Deliver:

- Apple capability request submitted and tracked;
- CloudKit/Identity & Trust configuration understood;
- development-signed app with a synthetic 1,000-entry test blockset;
- Bloom and PIR artifacts generated from the same manifest;
- allowed, denied, Bloom false-positive, outage, and rollback cases on a physical iPhone;
- written result for an accountless PIR bearer-token approach;
- coverage proof for Safari, WKWebView, URLSession, participating clients, and a nonparticipating client;
- production-distribution dependency list for Apple validation.

The proof uses reserved test domains. It does not depend on live malicious sites.

### 0.3 App Attest proof

Deliver:

- one-installation key lifecycle on a physical device;
- server challenge, attestation, assertion, request-body binding, and counter checks;
- replay, reinstall, unsupported-device, TestFlight/production-environment, and transient-failure tests;
- short-lived capability issuance with no attestation identity forwarded to intelligence;
- documented extension limitation and containing-app handoff.

### 0.4 Sandbox network proof

Deliver:

- dedicated test environment with no production access;
- one disposable isolated worker per job;
- mandatory egress proxy that owns DNS;
- complete public/special IP classification for IPv4 and IPv6;
- direct, redirect, mixed-answer, CNAME, DNS rebinding, metadata, WebSocket, and subresource denial tests;
- resource-budget enforcement and typed failures;
- proof that the guest has no secrets, internal route, or direct DNS/Internet path.

### 0.5 Privacy and measurement proof

Deliver:

- approved data-flow diagram and data inventory;
- four data planes with prohibited fields and joins;
- neutral, separate consent copy;
- month-token generation and reset prototype;
- edge/log configuration that demonstrably drops IP, URL, token, and User-Agent where required;
- opt-out plus one-at-a-time withdrawal for every locally derivable open or provisional month;
- preliminary App Store privacy-label mapping and privacy-manifest plan;
- approved public MPD definition and limitations.

### 0.6 Source-rights proof

Deliver:

- a public-safe source-rights registry contract and synthetic offline vectors; these artifacts define expected behavior but cannot pass S0-F;
- current terms snapshots for each real candidate in the restricted, human-controlled evidence store, not Git;
- separate owner-controlled selection, legal, proof, and runtime state records with opaque public references only; runtime remains disabled during proof;
- a Stage 0 viability, rights, and proof-spend outcome for at least one commercially permitted qualified exact-threat source suitable for the Stage 2 manual-check slice;
- reserved-input proof of quota/cost, notices, freshness/expiry, no-match/outage, kill-switch, terms-change, withdrawal, and replay behavior for that source, with no production ingestion;
- a Google Web Risk project, proof-stage cost ceiling, attribution, advisory, cache-expiry, and outage plan only if P-010 is accepted and that product is selected;
- explicit feature flags off for legally unresolved feeds.

The Stage 0 portion of O-008 is the viability, rights, and bounded proof-spend outcome needed to decide whether the exact-threat path is credible. Production procurement, provider account readiness, and the annual source budget may follow during Stage 1, but must be approved before Stage 2 integrates or calls a production source. Neither P-010 nor P-011 is accepted by this plan.

### Stage 0 exit gate

Proceed only if:

- manual app development is viable independently;
- Apple URL Filter has a credible development and approval path;
- accountless private-verification authentication has a credible design;
- O-018 sets validated inactivity and absolute expiry for PIR evaluation-key protocol state;
- the sandbox has zero boundary-canary contacts;
- at least one commercially permitted qualified exact-threat source is selected and proof-passed as suitable for the Stage 2 manual-check slice, with the Stage 0 portion of O-008 resolved; infrastructure, context, benchmark, CISA advisory, and CISA `.gov` enrichment sources do not satisfy this gate;
- the privacy owner approves the data inventory and MPD wording;
- no critical open decision in document 12 remains ownerless.

If URL Filter approval appears infeasible, decide explicitly whether the manual-only product remains commercially worthwhile before continuing.

## Stage 1 — contracts, policy core, and storage

### Goal

Create deterministic foundations without a user-facing product.

### Build order

1. Establish formatting, linting, unit tests, secret scanning, dependency review, and reproducible local services.
2. Create OpenAPI 3.1 and JSON Schema sources for check, status, report (including `incorrect_verdict`), attestation, measurement, and error envelopes. Do not create a separate feedback endpoint.
3. Implement the shared URL parser and versioned representations.
4. Import official canonicalization, IDNA, parser-differential, IPv4, and IPv6 test vectors.
5. Implement log-safe redaction and bounded error types before any endpoint accepts a URL.
6. Create separate local schemas/databases and production role boundaries.
7. Add migrations for entities, source rights, observations, derivations, verdict snapshots, jobs, and outbox events.
8. Implement idempotent observation ingestion.
9. Implement the deterministic verdict-policy interface with fixtures but only a minimal exact-source rule.
10. Add replay tooling that reproduces a verdict from frozen observations and policy version.

### Exit gate

- Contracts generate and round-trip across iOS/backend models.
- URL/parser fuzz and policy property tests pass.
- No prohibited field exists in the wrong schema or contract.
- Duplicate ingestion is harmless.
- A frozen observation snapshot produces a bit-for-bit stable verdict explanation.
- Migrations work from an empty database and through rollback rehearsal where safe.

## Stage 2 — known-threat manual vertical slice

### Goal

Ship an end-to-end manual check using only qualified, precisely scoped known intelligence.

Before Stage 2 begins, the production portion of O-008 must approve the applicable procurement/contract, provider account, production cost controls, and annual source budget. A Stage 0 proof-spend decision is not production purchasing authority.

### Backend

1. Implement the check endpoint, request caps, cache, pending result capability, and typed errors.
2. Integrate one selected, legally approved, proof-passed exact-lookup source behind a provider interface; authorize production runtime separately.
3. Apply provider expiry, quota, attribution, advisory text, and cost controls.
4. Store an immutable source observation and derived verdict.
5. Return bounded structured reason codes.
6. Add a source outage circuit breaker; an outage becomes Unknown, not clean.

### iOS

1. Create the minimal app shell with no account.
2. Add explicit paste entry.
3. Add share extension handoff.
4. Add QR scan, destination preview, and unsupported-scheme handling.
5. Render all four verdict states and evidence.
6. Store optional recent manual checks locally with clear/delete controls.
7. Add privacy/protection details and no-telemetry path.

### Exit gate

- Paste, share, and QR complete on a physical minimum-OS device.
- The exact user submission reaches only the security plane.
- A known current threat returns the expected scoped evidence.
- A source outage or unsupported URL returns a truthful Unknown/error state.
- Both telemetry consents can remain declined.
- No live-malware dependency exists in automated tests.

This stage is the first useful product slice and the fallback if later URL Filter work is delayed.

## Stage 3 — durable enrichment and evidence graph

### Goal

Analyze unknown domains through safe static collectors and make all decisions reproducible.

### Build order

1. Add DNS collector with controlled resolution and bounded results.
2. Add TLS certificate collector.
3. Add bounded RDAP collector with provider terms/rate handling and personal-field allowlisting.
4. Add domain, IP, ASN, certificate, nameserver, brand, and relationship tables/views.
5. Add source-import runs, leases, retries, dead letters, and outbox processing.
6. Add derived lifecycle, lexical, infrastructure, and positive-trust signals.
7. Add collector completeness and freshness policy.
8. Add re-evaluation on new, expired, retracted, or changed evidence.
9. Expand explanations using only approved reason codes.

### Exit gate

- Collectors are idempotent, bounded, rate compliant, and replayable.
- Personal RDAP fields and raw responses do not enter the durable graph.
- Correlated newness evidence obeys family caps.
- No weak signal can produce Dangerous or block eligible.
- Every result shows source availability and evidence freshness correctly.

## Stage 4 — isolated dynamic analysis

### Goal

Collect redirect, page, form, and artifact observations without trusting the target.

### Build order

1. Implement sandbox job and result schemas.
2. Deploy the broker and dedicated analysis network.
3. Build and sign the pinned browser/microVM image with SBOM and rollback.
4. Enforce egress validation on every connection, redirect, and subresource.
5. Add strict navigation, process, time, request, byte, DOM, screenshot, and disk budgets.
6. Extract redirect chains, bounded DOM structure, forms, input types, page text features, scripts/assets, favicon, and screenshot.
7. Quarantine everything.
8. Re-encode permitted images and validate JSON through a separate trusted ingestion service.
9. Destroy the worker after one job.
10. Add kill switches for crawl, image version, pool, target, and artifact promotion.

### Exit gate

- Complete SSRF, rebinding, isolation, exhaustion, and artifact suites pass.
- No sandbox host or guest can reach a production/control-plane resource.
- No form is submitted and no downloaded content is executed outside isolation.
- Duplicate/retried runs cannot create ambiguous observations.
- Raw and artifact retention jobs pass deletion tests.

## Stage 5 — impersonation, campaigns, and conservative detection

### Goal

Create proprietary relationship value without widening automatic blocking.

### Build order

1. Build the curated, provenance-backed US brand registry.
2. Add official-domain, terminology, favicon, asset, template, form-target, and visual observations.
3. Add bounded deterministic impersonation signals.
4. Add campaign entities and membership candidates.
5. Implement rarity/collision statistics for relationship features.
6. Implement deterministic clustering and frozen gold-cluster evaluation.
7. Add contradiction and multi-tenancy explanations.
8. Add the corroborated `Dangerous` manual-verdict policy behind a controlled rollout flag. This is a consumer verdict rule, not Route B block eligibility.
9. Produce Route B block-eligibility candidates in shadow mode behind a separate disabled enforcement flag.
10. Add campaign propagation Route C behind its own disabled flag.

### Exit gate

- Visual/language/AI evidence alone cannot create Dangerous.
- Shared CDN/IP/ASN/registrar/brand relationships produce zero false campaign merges by themselves.
- Campaign precision and purity gates in document 10 pass.
- Every membership and explanation is traceable.
- The corroborated `Dangerous` verdict and Route B candidate decision are stored and measured separately.
- Route B and Route C enforcement remain off until their independent block gates pass.

## Stage 6 — reports, false positives, and analyst operations

### Goal

Accept useful community input without creating an anonymous voting system.

### Build order

1. Decide O-017 and encode its live, replay, deletion, derived-support, key-destruction, and backup fixtures before accepting report content.
2. Productionize App Attest key registration and assertion exchange.
3. Issue scoped, short-lived capabilities for check, report (including `incorrect_verdict`), and measurement purposes. Do not create a separate feedback capability.
4. Implement report and incorrect-verdict APIs with strict schemas and rate limits.
5. Strip attestation identity before semantic messages enter the Trust Graph.
6. Add report independence, time-bucket, velocity, and coordination checks.
7. Add review queue, evidence viewer, scoped expiring override, retraction, and audit log.
8. Add high-impact-domain and false-positive-spike priority.
9. Exercise emergency removal and policy rollback.

### Exit gate

- Replayed, body-swapped, invalid, and counter-rollback assertions fail.
- Unattested/invalid reports cannot influence scoring.
- Any report volume alone remains incapable of auto-blocking.
- Intelligence reviewers cannot query anti-abuse or analytics identities.
- Report deletion and expiry destroy readable live/backup content and apply the approved O-017 rule to report-only support.
- A false block can be removed from the online enforcement store inside the target recovery time.

## Stage 7 — blockset and Apple URL Filter

### Goal

Turn qualified verdicts into private, fail-open passive protection.

### Build order

1. Implement scoped blockset entries with provenance, expiry, tombstones, and overrides.
2. Make compilation deterministic from a signed manifest.
3. Generate Bloom and PIR artifacts from the identical canonical set.
4. Validate Apple Punycode and sub-URL behavior using official tooling.
5. Publish PIR generation N before Bloom generation N and retain compatible N-1.
6. Add signed manifests, atomic promotion, last-known-good rollback, and kill switches.
7. Complete CloudKit, Privacy Pass, PIR bearer-token, OHTTP relay, entitlement, and production validation.
8. Integrate status/setup UX in the app.
9. Run the physical-device, outage, performance, privacy, and version-skew matrix.
10. Enable only Route A entries for initial beta.

### Exit gate

- Apple production-distribution approval and validation are complete.
- A Bloom false positive never becomes a false block.
- No cleartext URL or stable device identity is observable at the PIR service.
- Fail-open, last-known-good, corrupt-update, and kill-switch behavior pass.
- Exact evidence does not widen on shared hosts.
- A removal reaches the online PIR target and new signed prefilter within the recovery targets.

## Stage 8 — MPD and optional product analytics

### Goal

Measure product health without creating a browsing or permanent installation profile.

### Build order

1. Implement separate neutral consent controls, default off.
2. Generate the month-scoped pseudonymous token locally from a random app-container secret.
3. Implement a minimal monthly receipt emitted only after local protection-health qualification, plus one-at-a-time withdrawal for every locally derivable open or provisional month.
4. Deploy the separate measurement service/store/keys/log policy.
5. Add attested capability exchange without forwarding App Attest identity.
6. Aggregate distinct accepted tokens by UTC month.
7. Delete raw tokens on schedule; retain only non-identifying aggregate history.
8. If product analytics is approved, add a separate URL-free coarse event allowlist and its own consent/store.
9. Validate App Store privacy labels, privacy manifest, policy copy, export/delete behavior, and processor inventory.
10. Add metric-quality caveats and diagnostics for undercount/reinstall overcount.

### Exit gate

- Declining or withdrawing either consent has no product penalty.
- No MPD/analytics row or log contains a URL, domain, verdict, report, campaign, App Attest key, IDFV, IDFA, or raw IP.
- Cross-month token linkage is infeasible from retained measurement data.
- Retention and all still-open/provisional-month withdrawal tests pass, including backups.
- The public MPD statement matches the implemented count exactly.

## Stage 9 — hardening and staged beta

### Goal

Demonstrate quality, safety, recoverability, and operational ownership before public claims.

### Build order

1. Freeze a release corpus and source manifest.
2. Run 24-hour fuzzing and full sandbox conformance.
3. Run false-positive, difficult-benign, fresh-threat, campaign, blockset, and performance gates.
4. Conduct an independent security review of public APIs, App Attest, sandbox, supply chain, and URL Filter distribution.
5. Conduct privacy and source-license review against actual data flows.
6. Rehearse bad-feed, bad-policy, false-block, PIR outage, OHTTP issue, corrupt bundle, sandbox escape suspicion, and deletion failure.
7. Run an internal physical-device alpha.
8. Run a small TestFlight beta with Route A only.
9. Expand gradually with blockset/policy canaries and rollback groups.
10. Enable Route B or Route C only through a separate approval after their gates pass in production-like shadow mode.

### Public-launch gate

All cross-document acceptance criteria must pass. Specifically:

- Apple distribution approval;
- no critical/high-unmitigated security issue;
- zero SSRF boundary contacts or sandbox escapes;
- zero confirmed automatic false blocks in the required frozen benign corpus;
- signed, reproducible, reversible blockset publication;
- selected, legally approved, current proof-passed, runtime-authorized state for every active connector;
- privacy labels/policy/consent match observed traffic;
- live kill switches and on-call runbooks;
- support and false-positive escalation ownership;
- cost ceilings and degradation modes;
- product remains useful if URL Filter, Web Risk, dynamic crawl, MPD, or analytics is unavailable.

## Codex work packages and ownership

The stage rule applies to stages, not to independent proofs inside Stage 0. Start with S0-A. After its relevant decisions are recorded, S0-B through S0-F may proceed in parallel when they do not share files or infrastructure. Stage 1 product foundations do not begin until the Stage 0 exit gate passes.

| Order | Work package | Accountable owner | Codex scope and completion evidence |
|---|---|---|---|
| S0-A | Decision and proof harness | Founder plus named iOS, backend, infrastructure, privacy, and security owners | Add ADR infrastructure; record only owner-approved choices; define synthetic fixtures, evidence-bundle format, spike locations, teardown rules, and CI that cannot contact live threats. No product framework scaffolding. |
| S0-B | URL Filter proof | iOS owner; Apple-account owner for external submission | Minimal physical-device app/control-extension and local reference service using the synthetic 1,000-entry set; prove entitlement shape, Bloom/PIR behavior, coverage, fail-open, rollback, distribution dependencies, and O-018 protocol-state expiry evidence. Do not build consumer UI. |
| S0-C | App Attest proof | iOS owner plus backend security owner | Minimal containing-app client and isolated verifier; prove environment separation, full attestation/assertion validation, body binding, replay/counter behavior, reset, reduced-trust fallback, and subjectless capability output. |
| S0-D | Sandbox boundary proof | Security/infrastructure owner | Disposable runner, controlled DNS/egress, synthetic adversarial destinations, and boundary canaries only; prove zero private/internal contact and no secret/production route. This is not the production crawler. |
| S0-E | Privacy and measurement proof | Privacy owner plus iOS/backend owners | Data-flow inventory, consent-state prototype, monthly-token/withdrawal vectors, plane-deny schemas, processor/log canaries, and deletion/backup evidence. No public metric claim. |
| S0-F | Source-rights and provider proof | Founder/legal plus intelligence/backend owner | Define the public synthetic rights contract, then keep real terms, selection/legal decisions, proof-spend outcome, provider exercise, and evidence in the restricted human-controlled store. Exercise one commercially permitted qualified exact-threat source with reserved inputs across rights, quota/cost, notices, freshness/expiry, no-match/outage, kill-switch, terms change, withdrawal, and replay, with no production ingestion. A new schema or data-only vector set cannot pass S0-F. |
| S1-A | First product-foundation PR | Backend/iOS leads | Only after Stage 0 passes: contract/error envelope, minimal check schemas, URL-policy parsing/IDNA/redaction, official parser/IP fixtures, property tests, and CI. No production API, database, UI, crawler, vendor connector, or cloud deployment yet. |

The Apple capability/OHTTP requests, provider selection and contracts, real terms archives, proof and production budgets, provider accounts and credentials, restricted evidence, privacy approvals, and owner choices are human-controlled external work. Codex may prepare public-safe contracts, synthetic vectors, evidence templates, and forms but must not invent an approval, budget, account, credential, or proof result, and must not treat a submitted request as success. If a work package cannot meet its proof, record the result and invoke the Stage 0 exit decision instead of compensating with broader scaffolding.

## Feature-flag defaults

| Capability | Default before public beta |
|---|---|
| Manual exact-source checks | On |
| Static DNS/TLS/RDAP enrichment | On after Stage 3 gates |
| Dynamic crawl | Controlled rollout |
| Model-generated signals | Shadow/limited |
| Heuristic Dangerous verdict | Shadow, then controlled |
| Route B heuristic auto-block | Off |
| Campaign display | On only at qualified confidence |
| Route C campaign auto-block | Off |
| Community score contribution | Off until anti-abuse gates |
| URL Filter | Off until Apple and device-matrix gates |
| MPD measurement | Off until consent/privacy gates |
| Product analytics | Off until separately approved |
| External source connector | Off until separately selected, legally approved, proof-passed, and runtime-authorized |

## What “done” means

The project is not done because the happy path works. V1 is ready only when:

- uncertainty and dependency failure are truthful;
- the fastest rollback is rehearsed;
- false-positive recovery is fast;
- hostile content cannot reach trusted systems;
- measurements cannot become identity joins;
- external data can be removed and verdicts recomputed;
- the documentation describes the implementation that actually ships.
