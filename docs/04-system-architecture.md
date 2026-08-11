# System architecture and service boundaries

## Purpose

This document turns the product, privacy, Trust Graph, Apple, and sandbox requirements into implementation boundaries. It defines what may be deployed together, what must remain separate, and how work moves through the system.

Hezo Link should begin as a small number of cohesive deployables, not a microservice per table. Physical separation is required where identity, hostile execution, Apple protocol, or privacy purpose changes. Logical modules may remain in the same control-plane process when they share a trust boundary and release cadence.

Read this with:

- [Privacy, analytics, and Monthly Protected Devices](02-privacy-and-measurement.md) for consent and data-purpose rules;
- [Trust Graph and verdicts](03-trust-graph-and-verdicts.md) for evidence and decision policy;
- [PostgreSQL data model](05-data-model.md) for durable records;
- [API contracts](06-api-contracts.md) for boundary messages;
- [Apple platform](07-apple-platform.md) for URL Filter and App Attest requirements;
- [Sandbox and security](08-sandbox-and-security.md) for hostile-content isolation;
- [Implementation plan](11-implementation-plan.md) for the repository-wide build sequence.

## Architectural principles

- V1 has no account, user profile, registration record, cloud history, or cross-device identity.
- A manual check works when URL Filter is unavailable and when both optional telemetry consents are declined.
- Security intelligence, MPD measurement, product analytics, and anti-abuse are four physically isolated production data planes.
- Raw submitted URLs are encrypted and transient. Routine checks do not create a durable browsing history.
- Immutable observations and provenance are the source of truth. Relationships, signals, verdicts, explanations, and blocksets are versioned projections.
- App Attest proves facts about a genuine app installation request; it is not a user identity and never becomes an MPD or analytics key.
- The crawler is a hostile-execution system with no path to production stores or credentials.
- Automatic enforcement is a separately versioned projection of eligible verdicts. `dangerous` does not imply block eligible.
- Failure is explicit and bounded. Missing evidence, stale evidence, provider outage, and analysis failure never become a clean result.

## Four non-joinable data planes

Production separation means separate databases, credentials, service roles, queues, encryption keys, object stores or buckets, logs, dashboards, backups, and retention workers. Different schemas inside one database, prefixes behind one broadly readable object credential, or topics inside one broadly readable queue namespace are insufficient for these four planes.

| Plane | Permitted purpose | Permitted examples | Prohibited examples |
|---|---|---|---|
| Security intelligence | Answer a deliberate check, collect threat evidence, derive graph relationships and verdicts, compile enforcement | Transient submitted URL, sanitized URL entity, reports, source observations, campaign entities, verdict snapshots | MPD token, analytics identifier, App Attest key, IDFV, IDFA, account ID, stable installation ID |
| MPD measurement | Count consented protected installation-months using the definition in document 02 | UTC month, rotating month-token digest, optional spent anonymous-credential digest, deletion deadline; definition/methodology and counts at aggregate level | URL/domain, verdict/check/report/campaign ID, per-row health or consent, analytics ID, App Attest key, raw IP, User-Agent |
| Product analytics | Answer a small approved set of product-usage questions after separate consent | One-time batch identifier, allowlisted coarse event code, coarse period, integer count, schema version | URL/domain, verdict/check/report/campaign ID, persistent analytics ID, MPD token, App Attest key, raw IP, passive browsing or block event |
| Anti-abuse | Validate genuine app requests and bound abusive traffic | App Attest key and public key, environment, challenge, assertion counter, risk receipt, rotating network-prefix HMAC, rate bucket | URL/domain/page content, graph entity, MPD token, analytics ID, consumer verdict history |

There must be no foreign data wrapper, cross-plane read replica, raw multi-plane warehouse, analyst view, support view, or general-purpose service credential that can join these planes.

### Allowed crossings

Cross-plane communication is limited to one of these forms:

1. A short-lived, audience-bound capability from anti-abuse after it validates an assertion over a canonical request digest. The capability has no stable subject claim.
2. A non-identifying aggregate exported from MPD or analytics after its raw retention window closes and minimum reporting thresholds pass.
3. Bounded operational health such as success count, latency histogram, or queue depth with no high-cardinality identifier or payload value.

The anti-abuse boundary may see an opaque request digest. It must not receive or log the decoded URL, report text, MPD token, or analytics event payload. The downstream plane validates that the capability digest matches its exact request bytes.

Raw capabilities and JTIs are never logged or retained by both planes. Anti-abuse and the destination may keep only different, domain-separated keyed replay digests until expiry, so their replay tables are not directly joinable. A direct capability still has timing-correlation limits and is not the blinded credential needed for a cryptographically unlinkable public MPD count.

### Identifier and trace rules

- Strip `X-Forwarded-For`, CDN request IDs, and upstream trace context before forwarding from the anti-abuse edge to another plane.
- Generate a new plane-local trace ID at every boundary.
- Never copy a client-generated idempotency key from one plane into another.
- Do not place request bodies, authorization material, URL components, MPD tokens, analytics IDs, App Attest keys, assertions, or receipt blobs in logs or trace attributes.
- Edge infrastructure that cannot meet the plane's IP, header, and body logging policy is not an acceptable processor.
- A new field that could enable a cross-plane join requires an ADR and privacy review before implementation.

## Production zones and deployables

~~~text
                                   +-----------------------+
                                   | signed filter publish |
                                   | Bloom / PIR / manifest|
                                   +-----------+-----------+
                                               ^
                                               |
public iPhone                                  | eligible projection
    |                                          |
    v                                          |
+----------------+      subjectless      +-----+------------------+
| edge / abuse   |---- capability ------>| intelligence control  |
| App Attest     |      body bound       | plane                  |
+----------------+                       | check, graph, verdict  |
      |                                  +-----+-----------+------+
      |                                        |           |
      | opaque job reference                   |           |
      |                                        v           v
      |                                  +-----------+ +-----------+
      |                                  | workers   | | transient |
      |                                  | feeds and | | raw URL   |
      |                                  | derivation| | vault     |
      |                                  +-----+-----+ +-----+-----+
      |                                        |             |
      |                                        |      opaque lease
      |                                        |             v
      |                                        |      +-------------+
      |                                        |      | sandbox     |
      |                                        |      | broker      |
      |                                        |      +------+------+
      |                                        |             |
      |                                        |             v
      |                                        |      disposable runner
      |                                        |      isolated account/VPC
      |
      +---- subjectless capability ----+-----------------------------+
                                       |                             |
                                       v                             v
                                 +-----------+                 +-----------+
                                 | MPD plane |                 | analytics |
                                 | opt-in    |                 | opt-in    |
                                 +-----------+                 +-----------+
~~~

The line from anti-abuse to another plane represents a signed authorization result, not shared storage or a stable key.

### Intelligence control plane

The initial control plane is one modular service with clear internal packages and least-privilege roles:

- **Check API:** validates the request contract, obtains transient URL material, performs current lookup, and returns or schedules a result.
- **URL policy:** versioned parsing, IDNA handling, provider-specific canonicalization, exact transient fingerprints, and durable redaction.
- **Entity resolver:** creates typed graph entities and versioned identities.
- **Evidence ingest:** accepts only trusted typed observations with source and terms provenance.
- **Graph module:** materializes evidence-backed relationships.
- **Signal module:** applies versioned derivations and correlation-family caps.
- **Verdict module:** creates immutable snapshots and atomically advances current heads.
- **Report intake:** accepts explicit scam and incorrect-verdict submissions after anti-abuse authorization.
- **Block eligibility:** separately evaluates Route A, B, and C rules and exact enforcement scope.
- **Administration:** internal source, policy, review, override, and retraction operations with audit records.

The public API role cannot write observations, relationships, signals, verdict heads, source terms, analyst decisions, or block entries directly. Each internal writer has narrower grants described in [document 05](05-data-model.md).

### General intelligence worker

One initial worker deployable may host feed imports, bounded DNS/TLS/RDAP collectors, graph rebuilding, signal evaluation, verdict compilation, expiry, source removal, and bundle compilation. Modules still use separate queue job types and database roles so they can split later without changing contracts.

Do not split a module merely because it has its own table. Split when one of these is true:

- the module crosses a security or privacy boundary;
- it executes hostile content;
- it needs independent scaling or failure containment;
- it carries a distinct external license or secret boundary;
- its release cadence or operational ownership is materially different.

### Transient URL vault

The exact deliberately submitted URL, including query and fragment, is stored only when asynchronous work requires it.

- Encrypt each object with a per-object data key wrapped by an intelligence-plane KMS key.
- Queue messages contain an opaque reference, expected digest, policy version, and deletion deadline, never plaintext.
- Limit a capability to one object and one analysis job.
- Delete on terminal completion with a proposed 24-hour hard maximum pending decision O-007/P-008.
- Exclude transient raw objects and artifacts from long-lived backup/versioning paths; replication, snapshots, object versions, wrapped data keys, and retry copies must also be gone or cryptographically erased by the hard deadline.
- A cache hit or synchronous lookup that needs no asynchronous work should leave no durable check record.
- A hash is not anonymization; any transient deduplication digest inherits the raw URL's deletion deadline.

### Sandbox broker and runner

The broker is the only control-plane component that communicates with the analysis zone. It converts a job-scoped lease into an opaque sandbox task and validates the returned envelope.

The runner lives in a dedicated account/project/VPC and uses one disposable microVM or equivalently strong boundary per job. It has no production database, queue, object-store, secrets, CI, orchestration, MPD, analytics, or anti-abuse credentials. The complete requirements are in [document 08](08-sandbox-and-security.md).

Sandbox output enters quarantine. A trusted sanitizer and schema validator promotes only bounded typed findings. Hostile HTML, scripts, documents, downloads, screenshots, and network captures never enter ordinary PostgreSQL JSON or a public origin.

### Filter distribution plane

The filter publisher is a separately credentialed projection boundary even though its input comes from intelligence:

- consume only current block-eligible entries and explicit tombstones;
- compile Bloom and PIR artifacts from the same canonical manifest;
- sign manifest and artifacts;
- publish PIR generation `N` before the Bloom representation for `N`;
- retain compatible `N-1` for rollback;
- support kill switch, atomic promotion, expiry, and last-known-good recovery;
- do not ingest URL Filter queries, block events, or device identifiers into intelligence.

Apple’s OHTTP, Privacy Pass, CloudKit, entitlement, and fail-open details belong to [document 07](07-apple-platform.md). Filter download or PIR access logs are not MPD or analytics events.

Apple's PIR protocol requires a pseudorandom `User-Identifier` so the PIR service can associate an uploaded homomorphic-encryption evaluation key with later encrypted queries. This is required protocol state, not an app-generated stable product identity and not evidence that Hezo can see the queried URL or returned membership result.

Keep it in a separate filter-runtime protocol store with its own credential and key:

- persist only a filter-keyed digest of `User-Identifier`, the encrypted/opaque evaluation key, parameter/generation version, bounded state, and created/last-used/expiry times;
- set a strict inactivity and absolute expiry and delete the evaluation key and protocol row together;
- never log, trace, export, analyze, or forward `User-Identifier` or use it in a metric label;
- never copy it to intelligence, anti-abuse, MPD, analytics, reports, support, or a warehouse;
- never attach a URL, PIR request body, decrypted query, membership result, bearer-token identity, App Attest key, or cross-plane trace ID;
- prohibit service roles for intelligence, MPD, analytics, and anti-abuse from reading the filter-runtime store.

OHTTP hides the originating IP in the normal distribution path, PIR hides the queried membership key and result, and Privacy Pass keeps the long-lived bootstrap bearer token off ordinary PIR queries. The protocol `User-Identifier` can still correlate its own evaluation-key/query lifecycle until expiry, so privacy language must call it pseudonymous protocol state rather than anonymous or nonexistent state.

### Anti-abuse plane

This deployable owns:

- App Attest registration and environment separation;
- challenge issuance and expiry;
- certificate, nonce, App ID, key, AAGUID, receipt, and assertion verification;
- monotonic assertion counters and replay rejection;
- short-lived, purpose- and body-bound capability issuance;
- rate buckets and abuse decisions;
- server-controlled attestation rollout and pullback.

Only this service knows an App Attest key ID or retained IP-derived rate key. It forwards neither value. The public request body may be streamed through an edge that computes its digest without semantic logging; the downstream service receives the body while anti-abuse receives only the digest needed for binding.

Hezo does not invoke App Attest from, or make App Attest material available to, the URL Filter extension; only the containing app uses it. The containing app establishes narrowly scoped credentials as specified in document 07. Core manual protection must degrade safely when App Attest is unsupported or temporarily unavailable; policy may lower trust, rate-limit, defer reports, or use a more limited check path rather than falsely treating failure as fraud.

### MPD measurement plane

The MPD service accepts only the consented monthly protection receipt defined in [document 02](02-privacy-and-measurement.md). It atomically deduplicates a rotating month token, supports withdrawal for locally derivable open or provisional months, finalizes an aggregate after the correction period, destroys the month pepper, and deletes raw token material on schedule.

It has no intelligence client, graph identifier, analytics identifier, App Attest key, raw IP, or URL-aware logs. A simple App Attest-backed subjectless capability may separate stored planes, but the issuer can still correlate issuance timing and must not be described as cryptographic unlinkability. A public manipulation-resistant count requires the gated blinded, month-bound credential decision in document 02; no key-to-token mapping may be stored or exported in either design.

### Product analytics plane

Product analytics is optional and separate from MPD. It should be omitted entirely unless Stage 8 approves specific questions and a bounded event allowlist.

If enabled, it has:

- independent neutral consent and reset behavior;
- its own collection hostname, store, credentials, queue, KMS key, processor inventory, and retention worker;
- one-time, non-reused batch identifiers rather than a persistent installation or cross-month analytics identifier;
- a schema that rejects URLs, domains, verdicts, check/report/campaign IDs, App Attest keys, MPD tokens, source-app names, clipboard content, QR content, and passive browsing/block events;
- coarse timestamps and versions only where needed;
- aggregation thresholds before reports leave the plane.

No third-party analytics or session-replay SDK may be introduced without an ADR and privacy review.

## Main request flows

### Manual paste, share, or QR check

1. The app validates HTTP/HTTPS syntax locally and previews the registrable domain.
2. The app sends the exact deliberately submitted URL only to the check endpoint. It sends no MPD token or analytics identifier.
3. The edge validates size/media type and, when required, obtains anti-abuse authorization bound to the canonical request digest.
4. The check service performs exact current-intelligence and cache lookups without recording a durable check history.
5. A current qualified result returns immediately.
6. An unknown target that needs enrichment receives a transient URL-vault object and opaque analysis job.
7. Static or dynamic collectors create immutable observations through the evidence writer.
8. Graph, signal, and verdict jobs recompute against an evidence watermark.
9. The client polls with a short-lived opaque check capability or receives `unknown` when the selected profile cannot complete.
10. The app may keep recent results locally; the backend does not create an account history.

The exact public verdict values are `unknown`, `no_known_danger`, `caution`, and `dangerous`. `unknown` is a successful uncertainty result, not necessarily an HTTP error.

### Evidence ingestion and re-evaluation

1. A connector records the current source-terms snapshot and an import run.
2. Each source record is normalized into facts and deduplicated by content identity.
3. The observation transaction commits an outbox event carrying only entity references and an evidence watermark.
4. Relationship work materializes evidence-backed edges for the affected subjects.
5. Signal work evaluates current, non-retracted support and correlation caps.
6. Verdict work writes an immutable snapshot and advances the head only if its watermark is not stale.
7. Block-eligibility work evaluates the snapshot under a separately versioned policy.
8. New, expired, contradicted, retracted, or source-rights-disabled evidence follows the same chain.

The canonical DAG is observations → base relationships → declared higher relationship tiers → signals → verdict → block eligibility. Every stage uses one evidence watermark. Higher relationship tiers may depend only on strictly lower tiers and must flatten support to observations; relationships never depend on signals or verdicts. Signals may use observations and same-watermark relationships, but never verdicts. Workers may calculate independent subjects in parallel, while publication waits for the required predecessor versions at the same watermark.

### Report and false-positive flow

1. The app obtains a report-purpose anti-abuse authorization over the exact report body.
2. The report service stores the explicit submission in the restricted intelligence intake schema without the App Attest identity.
3. Restricted content uses a deletable per-record key and the O-017 live/replay/backup lifecycle; deletion-capability state is not a product identity.
4. The report schedules enrichment or review; it does not directly create a threat verdict. Any durable observation is sanitized, capped, and has no free text or submitter linkage.
5. Qualified reviewer action records reason, scope, expiry, and audit evidence.
6. A false-positive safety override can remove enforcement quickly without deleting historical observations.

### MPD and analytics

MPD and analytics requests use different consent state, hostnames, schemas, capabilities, storage, and deletion flows. The app must never batch them together. Neither call is made when its own consent is off. Revoking one consent does not alter the other or any protection feature.

## Jobs, queues, and transaction rules

Assume at-least-once delivery. Exactly-once effects are created by deterministic identities, unique constraints, and atomic upserts.

### Initial job catalog

| Job | Input | Durable effect |
|---|---|---|
| `source.fetch` | Source/version reference | Import run and encrypted raw artifact reference |
| `source.parse` | Import-run reference | Idempotent immutable observations |
| `entity.resolve` | Typed identity and version | Entity/identity upsert |
| `collect.dns`, `collect.tls`, `collect.rdap` | Entity and collector policy | Versioned observations |
| `analysis.static` | Opaque transient object reference | Typed static observations |
| `analysis.dynamic` | Opaque transient object reference and sandbox policy | Quarantined artifact envelope |
| `artifact.promote` | Signed quarantine manifest | Sanitized typed observations |
| `graph.rebuild_subject` | Subject and evidence watermark | Versioned relationships |
| `signals.evaluate_subject` | Subject, policy versions, watermark | Signal occurrences |
| `verdict.compile_subject` | Subject, policy version, watermark | Verdict snapshot and conditional head update |
| `block.evaluate` | Verdict snapshot | Scoped eligibility decision |
| `bundle.compile`, `bundle.publish` | Enforcement watermark and format version | Signed staged/published generation |
| `report.triage` | Report reference | Review priority or bounded report observation |
| `retention.purge` | Plane-local retention policy | Deletion audit counts |

MPD and analytics use their own queues if asynchronous processing is necessary. Their envelopes never reuse an intelligence job ID or correlation value.

### Envelope and versioning

Every durable event or job carries:

- time-sortable event/job ID;
- job/event type;
- payload schema version;
- producer name and version;
- plane-local correlation ID;
- idempotency key;
- creation and availability time;
- policy, collector, canonicalizer, or evidence watermark required by that job;
- bounded typed payload or opaque object reference;
- deletion deadline.

Messages must not contain raw URLs, URL components, page content, IPs, MPD tokens, analytics identifiers, App Attest material, credentials, or report free text. Consumers reject unsupported schema versions to quarantine and alert; they do not silently reinterpret them.

### Idempotency identities

- Source record: source + upstream record/version digest.
- Collector: subject identity + collector/configuration version + observation time bucket or upstream version.
- Static/dynamic analysis: transient input digest + runner image + analyzer/policy version.
- Relationship: subject + relationship algorithm version + evidence watermark.
- Signal: subject + signal definition version + evidence watermark.
- Verdict: subject + verdict policy version + evidence watermark.
- Bundle: blockset policy + enforcement watermark + artifact format version.
- Report: report-purpose idempotency key + body digest.

An idempotency key is plane local and expires according to its purpose. Reusing a key with a different body is a conflict.

### Outbox, leases, and stale work

- Commit an outbox event in the same transaction as its source mutation.
- Record a per-consumer inbox receipt before acknowledging completion.
- Claim jobs with a lease and bounded heartbeat. Never hold a database transaction across network, browser, provider, or object-store calls.
- Use exponential backoff with jitter and a bounded attempt count.
- Put poison work in a redacted dead-letter store with replay tooling and an expiry.
- A retry creates no duplicate observation or report because the write has a unique semantic identity.
- A late job may create historical derived output, but it may not replace a newer current head. Head advancement compares evidence watermarks transactionally.
- External dependency errors, invalid input, policy denial, timeout, and internal failure use distinct stable codes and retry rules.

The managed queue/cache/object/KMS choices remain O-003. A PostgreSQL `FOR UPDATE SKIP LOCKED` queue is acceptable for an initial low-volume internal worker if the same envelope, lease, dedupe, and dead-letter semantics are preserved.

## Failure and degradation policy

| Failure | Required behavior |
|---|---|
| Qualified source unavailable | Mark collector unavailable; do not treat it as a negative match |
| Check cache unavailable | Bypass or return bounded degraded result; do not record more data to compensate |
| Static/dynamic analysis unavailable | Return pending or `unknown`; never synthesize `no_known_danger` |
| Sandbox boundary canary or escape suspicion | Stop scheduling, revoke job capabilities, quarantine outputs, preserve incident evidence under approved authority |
| Bad feed/policy | Disable source/policy, recompute, roll back enforcement generation |
| MPD unavailable | Drop or retry only within consented bounded client policy; protection continues |
| Analytics unavailable | Drop events; protection and MPD continue |
| Anti-abuse unavailable | Apply documented reduced-trust/rate path where safe; manual protection must not become an account wall |
| URL Filter distribution unavailable | Fail open and use last-known-good artifacts according to Apple policy; manual checks continue |

Queues are not an excuse for unbounded eventual processing. Each job class defines a maximum age after which it expires or must be recomputed from current evidence.

## Secrets, roles, and administration

- Application services never connect as database owner or superuser.
- Migration roles are offline and unavailable to runtime workloads.
- Source credentials are connector scoped and cannot read the intelligence database.
- Sandbox jobs receive only one-job capabilities and no general cloud credentials.
- Signing keys for filter artifacts are isolated from compilers; signing receives a content digest and approved manifest.
- KMS keys are plane and environment specific. Sandbox, development, staging, TestFlight/production App Attest, and production data never share keys.
- Administrative actions use named workforce identity, least privilege, approval for high-impact changes, immutable audit records, and bounded reason codes.
- No support or analyst interface may display anti-abuse, MPD, analytics, and intelligence records together.

## Observability

Allowed metrics use bounded labels such as service, endpoint class, outcome code, policy version, source slug, queue name, or coarse latency bucket. A source slug is allowed only inside the intelligence plane.

Forbidden labels and log fields include URL, host, path, query, entity ID, check/report ID, MPD token, analytics ID, App Attest key, IP, User-Agent, assertion counter, page title, error payload, screenshot hash, or arbitrary attacker-controlled text.

Each plane has its own telemetry sink and retention. Cross-plane operational dashboards may show only coarse aggregate health. Privacy regression tests send canary values and fail if any reaches logs, traces, crash reporting, queues, or the wrong store.

## Architecture build order

This sequence is subordinate to the full stages in [document 11](11-implementation-plan.md):

1. Record ADRs for stack, cloud, physical databases, queue/object/KMS, canonicalization, and raw-URL retention.
2. Create contract sources and prohibited-field tests before public endpoints.
3. Establish four isolated local/production plane configurations, least-privilege roles, redacted observability, and retention job skeletons.
4. Build URL policy, source terms, entity identity, immutable observations, outbox, and deterministic replay.
5. Build exact-source check flow with no durable routine history.
6. Add collectors, relationship/signal/verdict jobs, and watermark-safe current heads.
7. Prove the transient vault, sandbox broker, disposable runner, quarantine, and promotion path.
8. Productionize App Attest and report capabilities; incorrect-verdict feedback is `report_type = 'incorrect_verdict'`, not a separate endpoint or capability.
9. Build exact-scope block eligibility and signed Apple filter publication.
10. Add MPD only after its consent and deletion proof; add product analytics only if separately approved.

## Architecture acceptance criteria

- Manual paste, share, and QR checks complete with no account, URL Filter, MPD consent, or analytics consent.
- Each of the four planes uses separate production storage, credentials, KMS material, logs, queues, backups, and retention execution.
- No runtime credential can read more than one sensitive plane.
- Contract and migration tests reject every prohibited cross-plane field.
- A known check leaves no durable check-history row, and an unknown raw URL is purged within the approved deadline.
- Anti-abuse can authorize a body without forwarding a key ID, IP-derived value, or stable subject.
- No queue or dead letter contains plaintext URL or other prohibited payload.
- Duplicate and reordered jobs cannot duplicate observations or replace a newer verdict head.
- Every relationship, signal, verdict, explanation, and block entry traces to versioned observations, policy, source rights, and an evidence watermark.
- A source outage, crawler failure, or stale dependency cannot produce `no_known_danger`.
- Sandbox compromise has no credential or route to production, other jobs, or control planes.
- MPD or analytics outage and either consent choice have no protection impact.
- A URL Filter outage is fail open, rollback is rehearsed, and manual checks remain available.
- PIR `User-Identifier` and evaluation-key state exists only in the expiring filter-runtime store; canaries prove it is absent from logs, exports, support, and all four data planes.
- Privacy canaries are absent from logs, traces, metrics, crash reports, object names, queue envelopes, and cross-plane stores.

## Decisions that remain ADRs

Do not resolve these by scaffolding:

- O-001 backend language/framework and repository tooling;
- O-002 cloud, US region, environment, and network model;
- O-003 managed queue, cache, object store, KMS, secrets, and observability vendors;
- O-005 accountless Apple PIR bearer-token design;
- O-006 production sandbox isolation technology;
- O-007 exact raw-URL and backup retention;
- O-017 restricted report, deletion, derived-support, and backup lifecycle;
- O-018 Apple PIR protocol-state inactivity and absolute expiry;
- P-003 exact PostgreSQL version and UUIDv7 generation mechanism;
- whether the subjectless App Attest capability is exchanged inline or through a separate endpoint;
- whether product analytics is needed at all in V1.

The owner and decision point for each accepted, proposed, and open item are in [document 12](12-risks-decisions-and-open-questions.md).
