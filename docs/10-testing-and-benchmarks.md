# Testing and benchmarks

## Purpose

Hezo Link can warn or block access to legitimate sites, load hostile pages, and make privacy claims about passive protection. Passing ordinary application tests is therefore insufficient.

This document defines the evidence required to:

- release manual checking;
- operate the isolated analysis pipeline;
- ship Apple URL Filter protection;
- enable exact-source automatic blocking;
- later enable heuristic or campaign-propagated blocking;
- make latency, detection, false-positive, and Monthly Protected Device claims.

The gates are deliberately asymmetric. Missing a malicious URL is harmful, but automatically blocking a legitimate government, bank, health, shared-hosting, or recovery page can also cause immediate harm. Precision and scope dominate recall for automatic enforcement.

## Test principles

- Test the contract and failure behavior, not only the happy path.
- Use deterministic offline fixtures in normal CI.
- Never open a live malicious URL on a developer workstation or ordinary CI runner.
- Treat test feeds, pages, DNS answers, screenshots, and labels as hostile data.
- Separate a clean result from an incomplete result. `Unknown` is not `No known danger`.
- Count `Unknown` as a miss when measuring malicious-detection recall.
- Absence from a threat feed is not a benign label.
- Split benchmarks by time and campaign before training or tuning.
- Report raw counts and confidence intervals alongside percentages.
- Never tune on the final frozen release corpus.
- Keep benchmark licenses and permitted uses in the corpus manifest.
- Make every release result reproducible from a code revision, policy version, source snapshot, corpus manifest, and build digest.

## Test environments

### Local and pull-request CI

Allowed:

- reserved example domains;
- loopback-only fixture servers;
- synthetic DNS and redirect graphs;
- generated HTML, image, archive, and parser fixtures;
- fake Apple attestation objects and Apple-published validation vectors;
- synthetic Bloom/PIR datasets;
- sanitized, non-executable snapshots specifically approved for repository inclusion.

Not allowed:

- live threat feeds or active malicious URLs;
- captured raw submissions, HAR files, screenshots, tokens, or attestations;
- execution of untrusted pages outside the production-equivalent sandbox;
- real cloud metadata access.

### Isolated security staging

Security staging mirrors the production analysis boundary and has no production route or credential. It may run:

- controlled DNS-rebinding and metadata-canary fixtures;
- sandbox conformance and resource-exhaustion tests;
- approved live-corpus analysis under source and retention policy;
- browser/version qualification;
- egress, load, and failure-injection tests.

Canary metadata services contain no real credential or user data. A test succeeds only when they record zero connection from the guest.

### Apple distribution staging

Apple URL Filter and App Attest need physical-device distribution tests. A direct Xcode development build is useful for iteration but is not distribution proof because development URL Filter traffic can bypass Apple's production OHTTP relay and TestFlight uses production App Attest.

Maintain separate development and production-equivalent Apple environments, credentials, datasets, and verification fixtures.

## Test cadence

| Cadence | Required suites |
|---|---|
| Every pull request | Unit, property, schema/contract, deterministic replay, offline integration, log-redaction, smallest relevant regression |
| Nightly | Extended fuzzing, corpus replay, SSRF matrix, sandbox conformance subset, dependency/image scan, blockset reproducibility |
| Weekly | Fresh temporal threat corpus, difficult benign corpus, source drift, browser update qualification, campaign benchmark |
| Before release | 24-hour fuzz campaign, full sandbox boundary suite, physical-device Apple matrix, load/soak, disaster/rollback, manual false-positive adjudication |
| Continuously in production | SLOs, source freshness, false-positive appeals, kill-switch health, image age, egress denials, deletion jobs |

No scheduled suite may silently become optional. A skipped security or privacy gate is a failed gate unless an accepted, expiring decision record says otherwise.

## Unit and property tests

### URL parsing and canonicalization

Cover:

- HTTP and HTTPS syntax, default/non-default ports, empty components, user information, and fragments;
- IDNA/Punycode, Unicode confusables, mixed case, trailing dot, and invalid labels;
- percent encoding, double encoding, encoded separators, invalid escapes, NUL, CR/LF, and control characters;
- alternate IPv4 integer, hexadecimal, octal, shortened, signed, and overflow notation;
- compressed IPv6, IPv4-mapped IPv6, NAT64, 6to4, Teredo, and zone identifiers;
- parser-differential inputs known to produce different host/path interpretations;
- provider-specific canonical forms as separate pure functions with official vectors;
- preservation of the exact raw input for transient analysis and sanitization of durable output;
- keyed transient deduplication without retaining a reversible raw hash.

The ingress validator and egress gateway must produce the same parsed destination. Property tests generate URLs and assert that no later component changes the security-relevant host, scheme, or port.

### Address classification

For every pinned IANA special-purpose IPv4 and IPv6 prefix, test:

- network address, first/last address, adjacent allowed address where meaningful, and subnet boundaries;
- literal URL, DNS A/AAAA answer, CNAME target, mixed answer set, redirect, subresource, and WebSocket use;
- organization-specific VPC, node, pod, service, overlay, corporate, and public-admin ranges;
- cloud metadata IPv4, AWS metadata IPv6, Google metadata IPv6, and metadata hostnames;
- IPv4 embedded in IPv6 and transition/translation prefixes.

The classifier is deny by default for a special/unknown class. Updating an IANA registry snapshot must produce a reviewed policy diff and new boundary tests.

### Verdict and block policy

Test the algorithm and invariants from [document 03](03-trust-graph-and-verdicts.md):

- family caps and correlation keys;
- synergy without false independence;
- positive-trust suppression affecting only its intended family;
- contradiction behavior;
- freshness, expiry, retraction, and analyst override;
- deterministic replay of a snapshot under one policy version;
- a new immutable snapshot when policy changes;
- separation of `Dangerous` from block eligibility;
- exact, path-prefix, host, and registrable-domain enforcement scope;
- shared-host and URL-shortener scope protection;
- bounded, provenance-backed explanation reason codes.

Property tests must prove that none of these can auto-block alone:

- age, registrar, TLD, ASN, hosting company, IP, certificate issuer, URL length, keywords, geography, or language;
- community reports;
- logo, visual, typo, or template similarity;
- an AI/ML/LLM output;
- a new certificate;
- popularity or absence from an allowlist.

### Security-critical coverage

Require 100% branch coverage for:

- URL/host parser wrapper;
- IP classifier and egress decision engine;
- redirect validation hook;
- block-eligibility and scope policy;
- App Attest verifier and replay/counter state machine;
- log and durable-URL redaction;
- retention/deletion state machines.

Repository-wide line coverage is not a release metric. Critical-path branch and mutation coverage are more useful than inflating unrelated percentages.

## Fuzzing

Fuzz at least:

- URL parsing and normalization;
- IDNA and percent decoding;
- IP parsing/classification;
- DNS and redirect message handling;
- CBOR/ASN.1 App Attest parsing;
- external-feed parsers;
- HTML/DOM observation extraction interfaces;
- artifact metadata and image sanitizer inputs;
- API and worker result schemas.

Pull requests run at least 10 minutes per changed security-critical target. The pre-release campaign runs continuously for 24 hours against the release build.

Release gate: zero crash, hang, out-of-memory condition, parser disagreement, unbounded allocation, policy bypass, or secret/raw-data log event. Every discovered input becomes a minimized permanent regression fixture.

## API and schema contract tests

OpenAPI 3.1 and generated schemas are the contract source of truth. Test:

- request/response examples against the schema;
- unknown enum/version behavior;
- bounded collection/string sizes;
- idempotency keys and duplicate delivery;
- cancellation, timeout, retry, and partial collector completion;
- stable mapping between operational failure and consumer `Unknown`;
- rejection of URLs or attacker-controlled values in analytics and MPD APIs;
- rejection of MPD tokens, analytics IDs, App Attest key IDs, and device IDs in intelligence APIs;
- anti-abuse gateway stripping its identity before a report reaches Trust Graph ingestion;
- logs, traces, and metrics remaining raw-URL-free for success and every error path.

The negative data-plane tests are mandatory. A schema that merely omits a forbidden field is insufficient if an unstructured metadata object can carry it.

## S0-F offline source-rights contract matrix

Before any real provider call, reserved and wholly synthetic fixtures must define the fail-closed source-rights behavior below. Public fixtures use fictional provider/product names, permanently historical times, fictional quota/cost units, generic roles, and opaque references. They contain no copied terms, contract, private budget, credential, endpoint, provider response, feed row, or real indicator.

| Case family | Required assertions |
|---|---|
| State and references | Selection, legal, proof, and runtime states remain independent; duplicate, dangling, and cross-source references fail; production is denied unless the source is selected, legally approved, proof-passed, and backed by current approved terms and policy. |
| Absent or narrowed rights | Every right is explicit; missing, null, or false rights deny the affected purpose; effective purposes are the intersection of terms and policy; consumer verdict, explanation, client enforcement, benchmark output, derived B2B, raw redistribution, model training, and model validation are tested independently. |
| Effective time and expiry | Terms and policy apply on a half-open interval from effective time through but excluding expiry; equality is expired; the earlier provider or policy hard expiry removes support and schedules recomputation. |
| No match, timeout, and outage | A no-match response supplies no threat support; timeout, unavailable, stale, or exhausted dependency states become incomplete/Unknown as policy requires and never become clean evidence. Last-known-good support ends at its hard expiry. |
| Quota and cost | Below-warning use is allowed, the warning boundary allows and alerts, projected use equal to or above the hard stop is denied, unknown usage is denied, and period reset behavior is deterministic. Thresholds are synthetic, not a production budget. |
| Attribution and advisory notices | Any purpose requiring attribution or advisory copy is denied without the matching approved template reference; a purpose marked `not_required` must not retain a stale template reference. |
| Kill switch and state change | Disabled, blocked, conditional, expired, material-change, and kill-switch cases prevent requests, ingestion, and new support without being represented as a clean result. |
| Terms change | A changed terms digest creates an unapproved snapshot, pauses affected use, prevents silent carry-forward, and requires a new human decision before re-enable. |
| Withdrawal and replay | Retirement, rights narrowing, and retraction stop future access, purge prohibited raw/derived copies and backups, tombstone affected enforcement, recompute outputs, preserve independently permitted Hezo evidence, and remain idempotent on replay. |

Schema validation proves only artifact shape. Semantic execution against all positive and negative cases, owner-controlled source selection and rights decisions, an authorized proof-spend outcome, reserved-input provider behavior, and restricted evidence are separate requirements. Adding or validating new data-only vectors cannot pass S0-F, and real terms archives, contracts, negotiated budgets, provider evidence, credentials, or named approvals must remain outside Git under human control.

## End-to-end analysis tests

Build a controlled fixture web with deterministic DNS, TLS, redirects, HTML, scripts, forms, and resources. Exercise:

- API acceptance through lease, microVM, quarantine, trusted ingestion, signal derivation, and verdict;
- fast-profile exact intelligence without starting a browser;
- standard-profile enrichment and typed partial failure;
- browser crash, worker death, queue redelivery, lease expiry, and stale result rejection;
- two workers receiving a duplicate job without duplicate observations;
- artifact hash/ownership mismatch;
- image or policy version changing between lease and result;
- source outage versus clean source response;
- deletion of transient input after completion and at the 24-hour hard deadline.

No crawler process has a database credential. The test must fail if a result can bypass trusted schema/provenance ingestion.

## SSRF and DNS-rebinding suite

The suite must attempt prohibited access through every request surface:

- direct top-level URL;
- each HTTP redirect status;
- scheme-relative and encoded `Location` values;
- meta refresh and JavaScript navigation;
- iframe, image, CSS, font, media, script, fetch/XHR, form action discovery, WebSocket, and service worker;
- same-host and cross-host connection reuse;
- public CNAME to private A/AAAA;
- public answer on first resolution and private answer on the next;
- mixed public/private A and AAAA answers;
- zero-TTL and rotating answers;
- SVCB/HTTPS alternative targets, ports, and address hints;
- CNAME loops and excessive depth;
- redirect loops;
- IPv4 mapped/embedded in IPv6 and alternate IPv4 spelling;
- cloud metadata hostnames and addresses;
- VPC, host gateway, cluster DNS, pod/service/node, corporate, and public-admin ranges;
- direct DNS, DNS-over-HTTPS, QUIC, WebRTC, raw socket, and proxy-bypass attempts;
- response `Alt-Svc`, protocol upgrade, and an opaque proxy-tunnel attempt;
- script-driven `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`, `CONNECT`, and `TRACE`, automatic form submission, `sendBeacon`, and any outbound request body;
- `Authorization`, `Proxy-Authorization`, `Forwarded`, `X-Forwarded-*`, `Referer`, `Range`, `Upgrade`, WebSocket negotiation, unexpected `Content-*`, arbitrary custom, and control-character-bearing headers;
- mutation of gateway-owned `Host` or hop-by-hop headers, plus over-count and over-byte cookie sets.

For each case assert:

1. The egress gateway returns a bounded denial.
2. The canary receives zero TCP/UDP application connection.
3. The worker does not retry through another representation or address family.
4. The result is `Unknown`/typed operational denial, never `No known danger`.
5. No raw destination URL or query value appears in logs.

For method/header fixtures, ordinary approved `GET` and `HEAD` controls must reach the public fixture with only the versioned allowlist from [document 08](08-sandbox-and-security.md). The fixture records the method, body length, and header names, and the test asserts that the gateway—not browser cooperation—stops every prohibited method, body, or header. It also proves that `Host` is reconstructed from the validated destination, `Referer` is absent, and a bounded same-job cookie can neither escape its origin scope nor survive into another job. An HTTPS fixture proves the inspecting gateway validates the real upstream certificate while its analysis-only CA key remains unreachable from the guest; invalid certificates fail, no opaque `CONNECT` tunnel succeeds, and no proxy access log retains the URL. This distinguishes a real policy test from a broken fixture.

Release gate: 100% of the versioned SSRF corpus is denied and zero prohibited canary contact occurs.

## Sandbox-conformance suite

A safe adversarial guest fixture attempts:

- host filesystem, device-node, container-runtime socket, proc/cgroup, VMM control, and orchestration access;
- mount, ptrace, privileged syscalls, namespace changes, raw sockets, and privilege escalation;
- host network, metadata, another microVM, another artifact prefix, and production service access;
- writes outside scratch and artifact quota;
- process/fork floods, memory pressure, disk fill, file-descriptor exhaustion, and CPU loops;
- infinite JavaScript, WebAssembly loops, huge DOM/canvas, decompression bombs, endless streams, redirect storms, WebSockets, and service-worker persistence;
- reuse of cookies, cache, local storage, IndexedDB, browser profile, or writable disk from a prior run;
- reading synthetic tripwire files or reaching tripwire endpoints.

Assert that the job is killed within its budget, the host remains healthy, and a concurrently running neighbor stays within 10% of baseline latency/throughput.

Release gate: zero boundary crossing, zero cross-job data read/write, zero tripwire access, and no material neighbor availability impact.

## Artifact and quarantine tests

Include:

- forged MIME type and extension;
- path traversal and malicious filename;
- polyglot, malformed PNG, SVG/script, HTML, PDF, archive, executable, and oversized object;
- ZIP/decompression bomb and excessive nesting;
- formula-injection text intended for CSV/spreadsheet export;
- XSS payload in title, page text, header, error, and filename;
- object-count, dimension, decoded-size, and expansion-ratio boundaries;
- image re-encoding failure;
- antivirus/YARA timeout and false-negative simulation;
- artifact access from the wrong job or role;
- expired analyst hold and deletion from primary storage, queue, replicas, and backup lifecycle.

Only explicitly permitted PNG/JSON/text representations can leave quarantine. Captured HTML must never execute on a Hezo or analyst origin.

## App Attest tests

Follow [document 07](07-apple-platform.md) and Apple's published validation guide.

Server negative vectors include:

- challenge shorter than policy, expired, unknown, reused, or consumed concurrently;
- malformed CBOR or ASN.1;
- invalid or untrusted `x5c` chain;
- nonce extension mismatch;
- wrong App ID/RP ID;
- key ID/public-key hash or credential ID mismatch;
- development AAGUID in production and production fixture in development;
- nonzero initial attestation counter;
- assertion signature or canonical request digest mismatch;
- replayed, equal, lower, concurrent, and deliberately out-of-order assertion counters;
- assertion for a different method, path, body, challenge, or contract version;
- unknown, revoked, reinstalled, migrated, or restored key;
- `isSupported == false`, Apple unavailability, and attestation throttling;
- an invalid/unattested report attempting to affect a verdict or block.

Always validate the initial attestation receipt locally before key acceptance: verify its chain, receipt application identifier (Team ID plus bundle identifier), public key, client hash, creation time, and applicable expiry fields. If Apple's fraud-risk redemption/refresh service is enabled, additionally test sandbox/production endpoint separation, authorization failures, rate limits, replacement, and refresh timing; if disabled, prove zero risk-service calls and raw-receipt deletion after approved local derivation. Apple's approximate fraud metric is anti-abuse context only: it is not MPD, a stable device identity, or sole authority to deny protection.

The verifier accepts legacy iOS 26 authenticator data without later extension fields and correctly parses supported newer extension data. Validation-category or bundle-version anomalies are explicit anti-abuse signals, not an undocumented hard block.

Client tests cover ordinary update, reinstall, migration/restore, key loss, retry, cancellation, and degraded read-only behavior. A retry after Apple's `serverUnavailable` uses the same key and same client-data hash; other nonrecoverable attestation failures discard the unusable key reference and begin registration under bounded retry policy.

Current Apple documentation has used more than one development AAGUID label across versions. Pin fixtures to the release Xcode/iOS combination and cover documented development encodings without weakening strict production verification.

Run the full path on physical devices and TestFlight. TestFlight always exercises production App Attest, even if development entitlements were used locally.

Release gate: every invalid/replayed assertion is rejected atomically, the core manual read path remains usable on unsupported devices, and invalid reports contribute zero security weight.

## Apple URL Filter tests

### Configuration and onboarding

Verify:

- app and control extension entitlements contain `com.apple.developer.networking.networkextension` with array value `url-filter-provider`;
- the control extension uses extension point `com.apple.networkextension.url-filter-control`, and its bundle identifier matches configuration;
- CloudKit Identity & Trust registration and Apple OHTTP onboarding are approved for the exact production origins;
- iOS 26.4-and-later production service origins use HTTPS, a standard port, and the required domain-only subdomain form with no path, custom port, or trailing slash;
- the Apple onboarding test record for `www.apple.com/url-filter-test` returns integer `1`;
- the required DNS TXT ownership record is exactly `apple-url-filter=<app bundle ID>`;
- the accountless PIR bearer-token design is accepted and exposes neither a permanent account identity nor the requested URL to the PIR service;
- a direct Xcode development build is never accepted as the distribution release proof.

The first `fetchPrefilter(existingPrefilterTag: nil)` returns a valid, nonempty prefilter. A later `nil` result intentionally retains the existing prefilter. Test changed, unchanged, corrupt, missing, oversized, interrupted, and rolled-back fetches.

### Bloom and PIR correctness

Verify:

- 32-bit FNV-1a and 32-bit MurmurHash3 double hashing match one captured Apple-tool oracle, including its generated Murmur seed; separate stock-tool runs are not expected to be byte-identical because the current tool chooses that seed randomly;
- the generation manifest sets `falsePositiveTolerance` explicitly to the reviewed target rather than inheriting Apple's current `0.001` stock default;
- every input URL is Punycode where required;
- Apple sub-URL generation/matching semantics using golden vectors for host, `www`, port, path segment, query, fragment, and encoding variants;
- shared-host exact paths do not create host-wide blocks;
- measured Bloom false positives go to PIR and return allow;
- a Bloom miss never becomes a block;
- Bloom and PIR are generated from the same canonical blockset manifest; the selected deterministic generator or adapter reproduces the captured Apple oracle byte for byte when supplied its exact seed and parameters;
- rollout stages PIR generation `N` before Bloom `N` and retains rollback-compatible prior data;
- PIR cache reset occurs when dataset content changes;
- PIR parameter refresh occurs only when the parameter shape, shards, or cryptographic processing changes;
- interrupted or corrupt rollout keeps the last-known-good generation;
- an emergency removal and rollback are auditable and bounded.

### Device coverage matrix

Test on the minimum supported iOS 26 release and current supported point release, using at least two physical iPhone generations:

- Safari/WebKit;
- a `WKWebView` fixture;
- `URLSession`;
- a custom network-stack fixture that calls `NEURLFilter.verdict(for:)` and honors deny;
- a raw/nonparticipating network fixture proving the documented coverage limitation;
- enable, disable, reboot, app update, extension restart, offline state, stale prefilter, PIR timeout/outage, Privacy Pass/OHTTP failure, and system time change.

iOS 26 provides no consumer URL/block callback or custom per-URL block explanation. Tests must prove that the app and extension receive no browsing history and that no custom telemetry was added. Supervised-only reporting introduced in later platform APIs is outside V1.

Set `prefilterFetchInterval` explicitly. Apple documents 86,400 seconds as the default and 2,700 seconds as the minimum, with scheduling drift. Test the chosen interval for fetch behavior, power, data, and last-known-good operation; do not assert exact wall-clock delivery.

Consumer V1 uses `shouldFailClosed = false`. During PIR or indeterminate failure, ordinary browsing proceeds, the app exposes degraded protection state when it can do so without URL telemetry, and recovery does not require reinstalling.

Release gate: the physical TestFlight matrix passes, the OHTTP path is approved, observed Bloom false positives never block, fail-open/rollback works, and no URL or stable device identity is visible to Hezo's PIR service.

## Corpus governance

Each benchmark sample has an immutable manifest:

~~~text
sample_id
label
label_source
label_reviewers
acquired_at
first_seen_at
last_verified_at
source_and_terms_snapshot
allowed_uses
raw_or_sanitized_fingerprint
registrable_domain
final_destination
campaign_id
template_or_kit_hash
brand
expected_enforcement_scope
split
~~~

Labels are:

- `confirmed_malicious`;
- `verified_benign`;
- `unresolved`.

Unresolved samples are excluded from accuracy denominators but counted and reported as an operational cohort. Dead, unreachable, or changed pages are not silently relabeled.

Corpus access, raw retention, and licensing follow [document 02](02-privacy-and-measurement.md) and [document 09](09-intelligence-sources.md). Do not commit a live corpus, captured page, raw URL, screenshot, credential, or provider dump to Git.

## Split and leakage policy

Split data by acquisition time before feature/model tuning. Then ensure no near-duplicate crosses train/development/test through:

- exact/fuzzy URL;
- redirect/final destination;
- registrable domain;
- campaign;
- phishing kit/template or distinctive asset bundle;
- credential/form endpoint;
- mirror/feed duplication.

The frozen release corpus is not used to choose weights or thresholds. A rolling weekly corpus contains threats first observed after the active policy/model/source snapshot and measures real drift.

Report results by source, threat age, target brand, host type, locale, shared-host status, campaign, and evidence availability. A single aggregate number can hide severe cohort failures.

## Malicious corpus

Maintain separate cohorts:

1. Qualified current exact-source entries: validates ingestion, canonicalization, expiry, and enforcement scope.
2. Confirmed fresh unseen threats: excludes exact matches available to the evaluated system at decision time.
3. Known campaign variants: tests graph relationships without leaking the same entity.
4. Malware delivery, credential phishing, payment scams, redirects, cloaking, IDNs, QR destinations, and unsupported/incomplete pages.
5. Evasion variants: logo removal/color changes, DOM changes, delayed/client-side navigation, alternate user agents, and split-view behavior.

Visual or model benchmarks are supporting-signal tests. They do not authorize model-only `Dangerous` or blocking.

## Benign and false-positive corpus

The benign corpus intentionally overrepresents hard negatives:

- official US government, postal, bank, card, healthcare, telecom, retail, cloud, and identity domains;
- legitimate login, password-reset, payment, donation, document-sharing, and account-recovery pages;
- newly registered legitimate businesses and low-popularity long-tail sites;
- IDNs and non-English pages;
- shared platforms such as hosted sites, cloud storage, developer pages, commerce platforms, CDNs, and URL shorteners;
- sites sharing IPs, ASN, nameservers, registrar, certificate issuer, frameworks, templates, favicons, or brand references with threats;
- parked, error, maintenance, and unavailable pages.

Tranco is blocked from Hezo benchmarks unless the source review in [document 09](09-intelligence-sources.md) clears a specific snapshot and use. If a popularity source is approved, it may seed testing but never create a safe label or allowlist. Labels require verification appropriate to the cohort.

Every automatic block and every `Dangerous` result in a verified-benign corpus is manually reviewed by two independent reviewers, with adjudication on disagreement. Record the precise signal, scope, source, policy version, blast radius, and regression fixture.

Any confirmed automatic false block on an official or shared-host legitimate page stops release until removal, rollback, root cause, and a regression test are complete.

## Detection metrics and proposed gates

Report confusion matrices, raw counts, and 95% confidence intervals. For malicious recall, `Unknown` and `No known danger` are misses. Report `Caution or Dangerous`, `Dangerous`, and `block eligible` separately.

The fresh-unseen gate requires at least 1,000 confirmed malicious samples across four independent weekly temporal cohorts. The difficult long-tail benign rate requires at least 20,000 verified samples. If the corpus is smaller, publish the result with its interval but do not use it to authorize a broader enforcement route.

Proposed product-quality and Route A gates:

| Cohort or metric | Gate |
|---|---:|
| Qualified exact entry represented at correct scope in regression corpus | 100% |
| Qualified exact source end-to-end rolling coverage | at least 99.9% |
| Fresh unseen confirmed threats: `Caution` or `Dangerous` | at least 80% recall |
| Fresh unseen confirmed threats: `Dangerous` | at least 60% recall |
| Auto-block-eligible decisions | at least 99.9% adjudicated precision |
| Confirmed false auto-blocks in at least 100,000 verified benign URLs | 0 |
| `Dangerous` false-positive rate, high-trust benign cohort | at most 0.005% |
| `Dangerous` false-positive rate, difficult long-tail cohort | at most 0.05% |
| `Caution` false-positive rate, difficult long-tail cohort | at most 1% |

Do not claim “one in a million” from an undersized corpus. A zero-error result still needs its confidence bound and sample composition. Apply the precision gate to the confidence bound when the sample supports it; as a practical reference, a two-sided 95% lower bound above 99.9% requires roughly 3,700 independently adjudicated block-eligible results with zero errors. If the system does not produce enough decisions, keep the route in shadow mode rather than waiving the gate.

## Route B benchmark

Route B is a high-confidence Hezo block-eligibility route, not a synonym for the general `Dangerous` consumer verdict or its recall above. It remains disabled until all are true:

| Route B requirement | Gate |
|---|---:|
| Adjudicated block-candidate precision, two-sided 95% lower bound | above 99.9% |
| Confirmed Route B false blocks in the required 100,000 verified-benign corpus | 0 |
| False candidate caused only by a forbidden weak/single signal | 0 |
| False candidate on official/shared-host hard-negative cohort | 0 |
| Consecutive production-like shadow period | at least 30 days |
| Independently adjudicated Route B candidates | at least 3,700 with zero confirmed benign results, or a larger sample needed to satisfy the bound |

The shadow report also states Route B's incremental confirmed-threat yield over Route A, evidence age, scope distribution, source overlap, expiry behavior, and false-positive appeal simulation. There is no permission to lower the precision gate merely because incremental recall is valuable. An accepted decision record is still required to enable the route.

Production passive requests are deliberately hidden by Apple's PIR/OHTTP design. Hezo therefore cannot calculate a browsing-request false-positive denominator through passive telemetry. Use offline corpora, deliberate opt-in reports, support signals, synthetic checks, and controlled review without weakening that privacy boundary.

## Campaign-clustering benchmark

Create analyst-reviewed gold clusters and hard negative pairs.

Positive examples include shared rare:

- credential/form collection endpoint;
- payment or wallet destination;
- redirect sink;
- kit/asset bundle;
- structural page template;
- obfuscation artifact;
- short-window infrastructure combination with measured rarity.

Hard negatives include:

- different campaigns targeting the same brand;
- unrelated tenants on the same CDN, IP, shared host, or nameserver provider;
- the same registrar, ASN, certificate issuer, framework, language, or domain age;
- generic WordPress/bootstrap assets and common favicons;
- infrastructure reused after the original evidence expired.

Measure pairwise precision/recall, B-cubed precision/recall, cluster purity, and propagation-eligible membership precision.

| Metric | Route C benchmark gate |
|---|---:|
| Pairwise campaign precision | at least 95% |
| B-cubed recall | at least 60% |
| Cluster purity | at least 95% |
| Propagation-eligible membership precision | at least 99.9% |
| False merges caused only by CDN/IP/ASN/issuer/registrar/brand | 0 |

Route C remains disabled at initial release even if the offline benchmark passes. A later enablement also requires the Route B shadow duration/sample discipline applied to propagation candidates, bounded blast radius, expiry/contradiction tests, emergency rollback, and an accepted decision record.

## Blockset tests

Every build proves:

- identical observations, source snapshots, canonicalizer, and policy produce bit-identical output;
- every entry has current provenance, license scope, enforcement scope, reason, added time, expiry/review time, and policy version;
- exact/path evidence never widens to a shared host or registrable domain;
- domain scope exists only after explicit domain-wide control evidence;
- expired, retracted, or unlicensed support removes the entry;
- emergency removals/tombstones win deterministically and are audited;
- source/category qualification is allowlisted, not inferred from a provider name;
- manifests/artifacts are signed and corrupt/partial data is rejected;
- generation rollback does not mutate verdict or observation history;
- no model or community-only entry can enter the blockset.

Measure build duration, artifact size, expiry lag, removal lag, and scope distribution. An unexpected host/domain-scope increase is a release anomaly requiring review.

## Performance, load, and availability targets

These proposed starting targets are measured from US launch regions with release builds and realistic payloads. They are not consumer claims until sustained in production.

| Path | Proposed release target |
|---|---:|
| Cached manual verdict API | p95 at most 300 ms; p99 at most 750 ms |
| Uncached static/fast analysis | p95 at most 2 seconds |
| Dynamic standard analysis | p95 at most 15 seconds; hard stop 30 seconds |
| Qualifying verdict to published PIR generation | p95 at most 5 minutes |
| Qualifying verdict to signed Bloom bundle | p95 at most 15 minutes |
| Online device receiving eligible prefilter | empirical p95 at most 90 minutes, not a guarantee |
| PIR added lookup latency across US test regions | p95 at most 500 ms; p99 at most 1.5 seconds |
| PIR service availability | at least 99.9% monthly |
| Measured Bloom nonmember false-positive rate | at most 1 x 10^-5 |
| Bloom false positives producing blocks | 0 |
| Load soak | 2x forecast for 30 minutes |
| Burst | 5x forecast for 5 minutes |
| Error rate at 2x forecast | below 1% |
| Cross-job data/artifact leakage | 0 |

Load tests include queue depth, lease expiry, duplicate work, PostgreSQL connection limits, object-store throttling, source-provider limits, PIR capacity, cache stampede, and kill-switch propagation. Third-party-source failure must degrade to explicit incompleteness rather than retry amplification.

Apple documents a minimum URL Filter prefilter interval of 45 minutes and allows scheduling drift. Do not market system-wide protection as instant. Manual checks and server intelligence can become current faster than an on-device prefilter.

## Privacy and retention tests

Test with synthetic canary values placed in URL query, fragment, headers, page text, screenshots, and errors. Search every allowed sink:

- application and edge logs;
- traces and metrics;
- queue payloads and dead-letter storage;
- crash reports;
- PostgreSQL durable tables;
- MPD and analytics stores;
- App Attest/anti-abuse store;
- support and export tools;
- object storage, replicas, and backups.

Expected result under the conservative P-008 default while O-007 and O-016 remain unresolved:

- exact raw URL only in the encrypted transient job object;
- raw/artifact deletion immediately after completion and always within 24 hours;
- an explicit analyst/report hold expires within seven days;
- restricted report content, replay digest, per-record key, deletion capability, report-only support, and backups follow the approved O-017 fixtures;
- Apple PIR protocol state follows O-018 inactivity/absolute expiry and deletes the `User-Identifier` digest with its evaluation key;
- no intelligence identifier joins to MPD, analytics, or App Attest identity;
- no URL/domain/verdict/report/campaign data enters MPD or analytics;
- withdrawal immediately stops future MPD/analytics contributions without disabling protection.

A later approved retention policy must replace these fixtures and gates in the same change that updates every affected contract, including documents 02, 05, 06, 07, 08, 10, and 12 as applicable. O-016 decides only whether the exceptional hold needs the full seven-day maximum or a shorter one; it does not authorize longer screenshot/DOM storage.

Inject deletion-worker failure and verify alerting, retry, bounded backlog, and recovery. A missed hard TTL is a release-blocking privacy incident.

## Supply-chain and release-security tests

Before release:

- verify signatures and provenance for app, server, browser, guest, VMM/runner, sanitizer, Bloom, and PIR artifacts;
- generate and archive SBOMs;
- scan dependencies and images;
- reject mutable/unpinned production images;
- verify no secret, feed data, raw URL, captured page, signing material, or attestation artifact exists in source or build output;
- exercise browser/image kill switch and signed rollback;
- check Critical/High vulnerability policy from [document 08](08-sandbox-and-security.md);
- verify production debug flags cannot disable certificate, browser-sandbox, egress, App Attest, or URL Filter privacy controls.

## Disaster and operational drills

Exercise at least:

- bad exact-source import;
- false block of a high-impact/shared host;
- corrupt Bloom or mismatched PIR generation;
- PIR regional outage;
- Apple OHTTP/Privacy Pass failure;
- dynamic crawler escape suspicion;
- browser zero-day kill;
- source license withdrawal;
- queue poison/retry storm;
- raw-data deletion failure;
- App Attest verifier regression;
- compromised signing or runner credential.

Record detection time, decision owner, kill-switch time, rollback time, affected scope, communication path, and follow-up regression. A runbook that has not been exercised is not an effective control.

## Staged release gates

### Manual-check beta

May ship only when:

- accountless manual flows work with MPD and analytics declined;
- API/schema/data-plane tests pass;
- URL parser, exact-source, verdict replay, and log-redaction gates pass;
- dynamic analysis is either disabled or its full sandbox boundary passes;
- raw input and artifacts meet the 24-hour hard TTL;
- the product never returns `No known danger` from incomplete required analysis.

Apple URL Filter approval is not required for this stage.

### Exact-source passive-protection beta

Adds these gates:

- Route A is the only enabled automatic block route;
- Apple entitlement, CloudKit/OHTTP onboarding, production origins, and physical TestFlight matrix pass;
- Bloom/PIR versioning, false-positive resolution, fail-open, last-known-good, and rollback pass;
- exact-source scope/expiry/licensing and false-positive gates pass;
- support and emergency-removal runbooks are staffed and exercised.

### Heuristic Route B

Remains feature-flagged off until:

- the dedicated Route B precision, corpus-size, and 30-day shadow gates pass on frozen and fresh temporal corpora;
- no forbidden single signal can enter the blockset;
- extended shadow evaluation finds no confirmed benign auto-block;
- high-impact blast-radius controls and automatic expiry pass;
- an accepted decision record authorizes enablement.

### Campaign propagation Route C

Remains feature-flagged off at initial release. Later enablement requires all Route B controls plus the campaign-specific precision, purity, shadow, contradiction, multi-tenancy, expiry, and rollback gates.

## Definition of release evidence

Each candidate produces a signed or immutable release-evidence bundle containing:

- code and image revisions;
- SBOM/provenance references;
- policy, canonicalizer, collector, model, source, and blockset versions;
- corpus manifest IDs and split dates;
- test results, skips, raw counts, confidence intervals, and benchmark breakdowns;
- vulnerability exceptions;
- physical-device/OS matrix;
- load and failure-injection result;
- kill-switch/rollback drill result;
- named reviewer approvals.

If the evidence cannot reproduce the released verdict and blockset behavior, the candidate fails.

## References

- [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)
- [IANA IPv6 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml)
- [IANA Special-Use Domain Names Registry](https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml)
- [RFC 9460: Service Binding and HTTPS DNS Resource Records](https://www.rfc-editor.org/rfc/rfc9460.html)
- [RFC 7838: HTTP Alternative Services](https://www.rfc-editor.org/rfc/rfc7838.html)
- [Apple URL filters](https://developer.apple.com/documentation/networkextension/url-filters)
- [Apple Network Extension entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.networkextension)
- [Apple `NEURLFilterManager`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager)
- [Apple `NEURLFilterControlProvider`](https://developer.apple.com/documentation/networkextension/neurlfiltercontrolprovider)
- [Apple: Using the Bloom filter tool to configure a URL filter](https://developer.apple.com/documentation/networkextension/using-the-bloom-filter-tool)
- [Apple: Setting up a PIR server for URL filtering](https://developer.apple.com/documentation/networkextension/setting-up-a-pir-server-for-url-filtering)
- [Apple PIR service OHTTP onboarding guide](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Onboarding.md)
- [Apple: Filter and tunnel network traffic with NetworkExtension](https://developer.apple.com/videos/play/wwdc2025/234/)
- [Apple `prefilterFetchInterval`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/prefilterfetchinterval)
- [Apple: Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [Apple App Attest validation guide](https://developer.apple.com/documentation/devicecheck/attestation-object-validation-guide)
- [Apple: Preparing to use the App Attest service](https://developer.apple.com/documentation/devicecheck/preparing-to-use-the-app-attest-service)
- [Apple: Assessing fraud risk](https://developer.apple.com/documentation/devicecheck/assessing-fraud-risk)
- [Google Safe Browsing URL canonicalization and hash expressions](https://developers.google.com/safe-browsing/v4/urls-hashing)
- [USENIX Security 2025: Evaluating visual-similarity phishing detectors on 451,000 real-world sites](https://www.usenix.org/conference/usenixsecurity25/presentation/ji)
- [NIST Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final)
