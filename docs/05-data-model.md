# PostgreSQL data model

## Purpose and status

This document specifies the implementation direction for durable data. It is intentionally more concrete than a conceptual entity list, but it is not a checked-in SQL migration. Migration SQL begins only after the stack, cloud, physical database, and UUID decisions in [document 12](12-risks-decisions-and-open-questions.md) are resolved by ADR.

The model follows four rules:

1. Observations and provenance are durable facts; relationships, signals, verdicts, and enforcement are versioned derivations.
2. A routine URL check is not a backend browsing-history record.
3. Security intelligence, MPD measurement, product analytics, and anti-abuse live in separate physical production databases.
4. Evidence validity, operational expiry, privacy deletion, and backup deletion are different concepts and must be represented separately.

See [document 03](03-trust-graph-and-verdicts.md) for verdict semantics, [document 04](04-system-architecture.md) for ownership boundaries, [document 06](06-api-contracts.md) for external representations, and [document 09](09-intelligence-sources.md) for source-specific rights.

## PostgreSQL conventions

The proposed baseline is PostgreSQL 17 or later, subject to P-003.

- Use `bigint generated always as identity` for internal, high-volume primary keys.
- Use application-generated UUIDv7 for externally exposed opaque IDs. Never expose sequential internal IDs.
- Use `timestamptz` for instants, `date` for deliberately coarse days, `text` for strings, `bytea` for hashes/ciphertext, `inet` for IP addresses, and `boolean` for booleans.
- Store confidence and bounded contributions as `smallint` basis points from `0` through `10000`. Store the internal risk score as a bounded `smallint` from `0` through `100`; neither is a probability.
- Prefer text plus named `CHECK` constraints over PostgreSQL enum types so values can evolve through forward-safe migrations.
- Use typed columns for fields used in policy or queries. `jsonb` is permitted only for bounded, schema-versioned source or derivation detail.
- Name objects in lowercase snake case and name every constraint/index deliberately.
- Create an index for every foreign-key access path; PostgreSQL does not do this automatically.
- Use composite indexes matching actual equality-then-range queries. Use partial indexes for ready jobs, active rows, and non-null expiry work.
- Revoke the `public` schema and table defaults. Runtime services never connect as owner or superuser.
- Use transaction-mode pooling for application traffic. Give each plane an explicit connection budget with reserved migration/operations capacity; never open one database connection per request. Migrations use a separate direct connection and role.
- Set bounded role-specific `statement_timeout`, `lock_timeout`, and `idle_in_transaction_session_timeout` values. No transaction remains open across a provider, queue, object-store, browser, KMS, or other network call.
- PostgreSQL has no `ADD CONSTRAINT IF NOT EXISTS`. Constraint migrations use deterministic names plus a catalog check or an otherwise idempotent migration framework pattern; large validation is staged so deploys do not take an unbounded lock.
- Do not partition by reflex. Monthly range partitioning is appropriate for time-series tables only when row count, vacuum, or retention deletion justifies it. A likely trigger is on the order of 100 million rows, confirmed by query plans and operations tests.
- Monitor autovacuum/analyze age and dead tuples on high-churn jobs, replay ledgers, intake, and retention tables. Analyze after large imports or backfills, and tune per-table autovacuum thresholds only from measured churn.

## Physical database layout

| Database | Logical schemas | Runtime owners |
|---|---|---|
| `hezo_intelligence` | `catalog`, `graph`, `evidence`, `decision`, `enforcement`, `intake`, `ops`, `audit`, `retention` | Check reader, evidence writer, graph writer, verdict writer, publisher, reviewer, retention worker |
| `hezo_measurement` | `mpd`, `retention`, `audit` | Measurement ingester, aggregate publisher, withdrawal worker, retention worker |
| `hezo_analytics` | `analytics`, `retention`, `audit` | Analytics ingester and retention worker, only if separately approved |
| `hezo_abuse` | `abuse`, `retention`, `audit` | Attestation verifier, capability issuer, rate limiter, retention worker |

These must be separate production databases with separate credentials, encryption keys, backups, and network access. Reusing these schema names inside one production cluster does not satisfy the isolation requirement unless the approved infrastructure ADR proves equivalent physical and administrative isolation. Development may use one local server with separate databases and roles, but tests must still prove cross-database denial.

No foreign key, logical replication subscription, foreign data wrapper, materialized view, data-lake export, or BI connector may cross the four databases. Only non-identifying aggregates leave MPD or analytics.

Apple's PIR service additionally needs a small `hezo_filter_runtime` protocol-state store, which may be a purpose-built managed key/value store rather than PostgreSQL. It is not a fifth product-observation plane: it exists only to associate a pseudorandom Apple protocol `User-Identifier` with its uploaded evaluation key until expiry. It nevertheless has separate credentials, encryption, logs, retention, and network access and cannot be joined to any of the four data planes.

## Intelligence database

### Source catalog and rights

`catalog.sources` identifies a provider product, not merely a company.

| Column | Direction |
|---|---|
| `id` | Internal identity primary key |
| `public_id` | UUIDv7, unique |
| `slug` | Stable text, unique |
| `provider_name`, `product_name` | Display and audit fields |
| `source_class` | `qualified_threat`, `infrastructure`, `public_context`, or `benchmark_only` |
| `legal_state` | `proposed`, `trial`, `conditionally_approved`, `approved`, `paused`, `blocked`, or `retired` |
| `runtime_state` | Independently `disabled`, `shadow`, or `production` |
| `default_confidence_bp` | `0..10000` |
| `current_terms_snapshot_id` | Nullable until terms are approved |
| `contract_reference`, `legal_owner`, `credential_owner` | Non-secret ownership and approval references |
| `credential_config_reference` | Opaque deployment/secrets-manager reference, never credential material |
| `next_terms_review_at` | Mandatory review deadline for any non-retired source |
| `created_at`, `updated_at` | Audit instants |

Legal approval and runtime enablement are independent. Database constraints and the connector policy layer must prevent `runtime_state = 'production'` unless `legal_state = 'approved'`, the current terms snapshot is approved and unexpired, and a current operational policy exists. Pausing, blocking, retiring, or expiring the legal basis automatically disables new production ingestion and schedules affected-output replay; changing a feature flag must never manufacture legal approval.

`catalog.source_terms_snapshots` is immutable and records the rights in [document 09](09-intelligence-sources.md):

- source and terms version;
- terms URL and captured content digest;
- captured/effective/expiry times;
- `internal_use_allowed`;
- `consumer_verdict_allowed`;
- `consumer_explanation_allowed`;
- `client_enforcement_allowed`;
- `derived_b2b_allowed`;
- `raw_redistribution_allowed`;
- `model_training_allowed` and `model_validation_allowed`;
- attribution/advisory requirements and approved template reference;
- geography and customer restrictions;
- refresh, deletion, termination, and backup requirements;
- reviewer, decision time, and review expiry.

Rights default to false when omitted. Primary key may be an internal ID with unique `(source_id, terms_version)`. `catalog.sources.current_terms_snapshot_id` uses `ON DELETE RESTRICT`.

`catalog.source_operational_policies` is versioned and executable rather than free-form notes. It records:

- source, policy version, configuration digest, effective/review/retirement times, and approving owners;
- allowed indicator types, categories, match semantics, source class, and enforcement scopes;
- approved personal-data field allowlist and transformation policy;
- minimum polling interval, normal freshness, hard expiry, and maximum raw retention;
- quota units, budget period, warning threshold, hard cost/volume stop, and outage behavior;
- required attribution/advisory template references, correction endpoint, and feature-flag key; and
- permitted consumer, blockset, benchmark, model, and future-output scopes after intersecting the current terms snapshot.

Unique `(source_id, policy_version)` preserves history. Production ingestion references both a terms snapshot and an operational policy. An absent scope, field, or limit is denied; no connector supplies its own permissive default.

`catalog.import_runs` records one fetch or import:

- external UUIDv7;
- source and terms snapshot;
- upstream batch/version digest;
- encrypted raw-artifact reference, if permitted;
- content digest, fetch and completion times;
- status and stable error code;
- item counts;
- collector/parser build and configuration digest;
- `delete_after`.

Unique `(source_id, upstream_batch_digest)` prevents duplicate imports. Index `(source_id, fetched_at desc)` and partial `(status, fetched_at)` for incomplete runs.

Source credentials belong in a secrets manager and are referenced by deployment configuration, never a database row.

### Entities and versioned identities

`graph.entities` contains only fields common to all entity types:

- `id bigint` primary key;
- `public_id uuid` unique;
- `entity_type` with a V1 allowlist;
- `first_seen_at`, `last_seen_at`;
- `created_at`;
- `tombstoned_at`;
- `retention_policy_id`.

Index `(entity_type, last_seen_at desc)`. `last_seen_at >= first_seen_at` is a constraint.

`graph.entity_identities` permits canonicalizer and keyed-digest rotation:

- `entity_id`;
- `identity_kind` such as `domain_ascii`, `url_security_hmac`, `certificate_sha256`, or `artifact_sha256`;
- `identity_version`;
- `identity_digest bytea`;
- `created_at`, `retired_at`.

Unique `(identity_kind, identity_version, identity_digest)`, plus index `(entity_id, identity_kind)`. Hash columns have a length constraint appropriate to the algorithm. HMAC keys remain in KMS. Before retiring a URL lookup-key version, create current-version identities for every still-active exact threat representation.

The generic identity table does not replace typed subtype constraints.

#### Core subtype tables

`graph.domains`

- `entity_id` primary/foreign key;
- lower-case IDNA ASCII `ascii_name`, unique;
- `registrable_domain_entity_id`, nullable for public suffixes and special cases;
- `public_suffix_list_version`;
- `is_public_suffix`.

Constraints require the normalized form and prohibit a domain pointing to itself as registrable domain. Index the registrable-domain foreign key.

`graph.urls`

- `entity_id` primary/foreign key;
- nullable `host_domain_entity_id` referencing `graph.domains(entity_id)`;
- nullable `host_ip_entity_id` referencing `graph.ip_addresses(entity_id)`;
- `scheme` limited to `http` or `https`;
- `effective_port`;
- sanitized normalized path;
- optional bounded query-key names, never arbitrary values;
- `fragment_was_present` without the value;
- redacted display form;
- canonicalizer version.

An exactly-one-host constraint requires one of the two host references and prohibits both. Index each host foreign key with `entity_id` as the second column. The durable row never contains user information, password, session/reset token, arbitrary query value, or fragment. Exact matching uses `graph.entity_identities` or the restricted enforcement representation below.

`graph.ip_addresses`

- `entity_id` primary/foreign key;
- `address inet`, unique;
- canonical address family.

`graph.asns`

- entity ID and positive ASN, unique.

`graph.certificates`

- entity ID;
- DER and SPKI SHA-256 digests;
- bounded, approved metadata such as validity times and issuer key identifier where licensed and useful.

Unique fingerprint constraints prevent duplicate certificate entities. Subject identity fields are not copied indiscriminately from certificates.

Additional V1 subtype tables cover nameservers, brands, organizations, page templates, visual fingerprints, favicons, scripts/assets, form targets, and campaigns. Each must have a deterministic typed identity, not a display-name key.

Visual embeddings belong in `graph.visual_embeddings(entity_id, model_name, model_version, embedding, created_at, delete_after)` with unique `(entity_id, model_name, model_version)`. `pgvector` and approximate indexes require a separate measured ADR; cryptographic and perceptual hashes do not wait for it.

### Immutable observations

`evidence.observations` is append-only to ordinary runtime roles.

| Column | Requirement |
|---|---|
| `id`, `public_id` | Internal identity and external UUIDv7 |
| `subject_entity_id` | Primary subject |
| `observation_type` | Stable typed fact name |
| `value_schema_version` | Required for bounded `value_json` |
| Typed value columns / `value_json` | Use typed columns where policy queries the value; JSON is bounded |
| `source_id`, `source_terms_snapshot_id` | Required provenance |
| `source_record_digest` | Keyed or hashed source-record identity; do not copy sensitive upstream IDs blindly |
| `import_run_id` | Nullable for first-party collector or report observations |
| `collector_name`, `collector_version`, `collector_config_digest` | Reproducibility |
| `observed_at` | When the fact was true or measured |
| `source_published_at` | Nullable upstream publication time |
| `ingested_at` | Hezo receipt time |
| `valid_until`, `next_review_at` | Decision freshness, not deletion |
| `confidence_bp` | `0..10000` confidence in the fact |
| `content_fingerprint` | Semantic idempotency identity |
| `supersedes_observation_id`, `contradicts_observation_id` | Optional explicit correction links |
| `usage_scope_digest` | Effective rights snapshot for derivation/export checks |
| `retention_policy_id`, `delete_after` | Physical deletion policy |

Constraints include:

- `confidence_bp between 0 and 10000`;
- `valid_until is null or valid_until >= observed_at`;
- `next_review_at is null or next_review_at >= observed_at`;
- `delete_after > ingested_at` for rows requiring deletion;
- supersedes/contradicts cannot self-reference;
- source terms belong to the same source;
- unique `(source_id, content_fingerprint)` for the semantic source record/version.

The content fingerprint includes the source record/version or observation instant plus the normalized typed fact and collector contract. A delivery retry therefore collides, while a genuine later refresh or changed fact creates a new immutable observation.

Indexes:

- `(subject_entity_id, observed_at desc)`;
- `(source_id, ingested_at desc)`;
- `(import_run_id)`;
- partial `(valid_until)` where `valid_until is not null`;
- partial `(next_review_at)` where `next_review_at is not null`;
- `(delete_after)`;
- indexes on supersedes and contradicts foreign keys.

`evidence.observation_entities` relates one observation to multiple entities with a role such as `target`, `redirect_target`, `brand`, `certificate`, `form_target`, or `artifact`.

- Primary key `(observation_id, entity_id, role)`.
- Reverse index `(entity_id, observation_id)`.

If observations are later partitioned by `ingested_at`, keep a small non-partitioned `evidence.observation_dedupe(source_id, content_fingerprint, observation_public_id, first_seen_at)` ledger so semantic uniqueness remains global. Do not weaken idempotency to accommodate partitioning.

Corrections create new observations and explicit supersession/contradiction links. No connector or reviewer updates historical fact values in place.

### Relationships

`graph.relationships` is a versioned materialized derivation:

- ID/public ID;
- subject entity, relation type, object entity;
- relationship scope;
- declared derivation tier;
- algorithm name/version and configuration digest;
- evidence watermark;
- first/last observed time;
- confidence basis points;
- status: `active`, `stale`, `contradicted`, or `retracted`;
- valid/review/delete times;
- effective usage-scope digest.

Unique `(subject_entity_id, relationship_type, object_entity_id, algorithm_version, evidence_watermark)` preserves recomputation history.

Indexes:

- `(subject_entity_id, relationship_type, last_observed_at desc)`;
- `(object_entity_id, relationship_type, last_observed_at desc)` for reverse traversal;
- partial `(valid_until)` for active expiry work;
- `(delete_after)`.

`graph.relationship_evidence` has primary key `(relationship_id, observation_id)` and reverse index `(observation_id, relationship_id)`. An active relationship eligible for policy must have supporting evidence. Relationship algorithms may not hide untraceable support in JSON.

When a higher-tier relationship uses lower-tier relationships, `graph.relationship_dependencies(parent_relationship_id, supporting_relationship_id)` records that dependency. Both rows use the same evidence watermark, and the supporting tier must be strictly lower than the parent tier. A deferred constraint trigger or the single relationship writer rejects same-tier, reverse-tier, cross-watermark, and cyclic dependencies. The parent also materializes the transitive observation support in `graph.relationship_evidence`, so replay and licensing do not depend on an opaque graph traversal.

Campaign membership uses the same relationship/evidence model. A campaign is an entity and never an attacker identity.

### Signal definitions and occurrences

`decision.signal_definitions`

- stable signal code and version;
- signal family and correlation-key strategy;
- derivation engine/configuration digest;
- polarity;
- maximum family contribution;
- effective and retirement times;
- explanation reason-code mapping.

Primary key `(signal_code, signal_version)`.

`decision.signal_occurrences`

- target entity;
- signal code/version;
- producer run;
- evidence watermark;
- correlation key digest;
- polarity;
- raw contribution and applied contribution basis points;
- confidence basis points;
- observed/valid/delete times;
- bounded schema-versioned detail.

Unique `(target_entity_id, signal_code, signal_version, evidence_watermark, correlation_key_digest)`. Index `(target_entity_id, valid_until)` and the definition foreign key.

`decision.signal_evidence` explicitly links an occurrence to observations and/or relationships. Use separate nullable foreign keys with an exactly-one-target constraint, or two dedicated join tables. Avoid a polymorphic unvalidated text reference.

### Policy, analysis completeness, and verdicts

`decision.policy_versions` stores immutable signed or content-addressed policy documents for verdict, block eligibility, explanation, and analysis profiles. Each record includes policy kind/version, configuration digest, effective times, creator/reviewer, and retirement time.

`decision.analysis_runs` contains no raw URL:

- public run ID and optional subject entity;
- transient input-reference digest, not object locator in ordinary read roles;
- analysis profile and policy version;
- canonicalizer, collector, analyzer, and sandbox image versions;
- state and bounded terminal code;
- start/completion times;
- collector completeness summary;
- evidence watermark produced;
- artifact-manifest digest and deletion deadline.

Index partial `(state, started_at)` for nonterminal work and `(delete_after)`.

`decision.verdict_snapshots` is immutable:

- internal/public ID;
- target entity;
- verdict policy version;
- analysis profile and completeness state;
- evidence watermark/evaluation time;
- internal risk score `0..100`;
- confidence basis points;
- public label constrained to `unknown`, `no_known_danger`, `caution`, or `dangerous`;
- contradiction state;
- source availability summary;
- reason-set digest;
- valid/review/delete times;
- engine build and usage-scope digest.

The public label constraint exists even if internal policy uses more granular diagnostic states. The API never exposes a different verdict vocabulary.

Unique `(target_entity_id, verdict_policy_version, evidence_watermark)`. Index `(target_entity_id, evaluated_at desc)` and expiry/delete fields.

`decision.verdict_reasons`

- verdict snapshot;
- stable reason code;
- rank;
- source signal occurrence or direct hard-threat observation;
- included/capped/suppressed/excluded disposition;
- contribution basis points;
- explanation-data schema version and bounded values.

Primary key `(verdict_snapshot_id, reason_code, rank)`. Each reason must resolve to permitted, current support.

`decision.verdict_heads`

- `(target_entity_id, verdict_policy_version)` primary key;
- current verdict snapshot;
- evidence watermark;
- updated time.

Advance the head in one transaction only if the new watermark is equal or newer. A late worker may preserve its snapshot for audit but cannot make it current.

### Enforcement and blockset generations

`enforcement.eligibility_decisions`

- verdict snapshot and independent enforcement-policy version;
- `eligible boolean`;
- route `a`, `b`, `c`, or none;
- exact scope and rationale;
- contradiction/benchmark/feature-flag gates;
- decided/valid/delete times.

`enforcement.entries`

- public ID;
- eligibility decision;
- provider-specific canonicalizer/format version;
- exact/path-prefix/host/domain scope;
- keyed canonical fingerprint;
- restricted encrypted exact value only when format production requires it and rights permit it;
- source-rights digest;
- created/last-validated/expiry times;
- rollback group;
- state `candidate`, `active`, `tombstoned`, or `expired`.

Unique active semantic identity should cover canonicalizer version, fingerprint, and scope. Use a partial index for active, unexpired entries. A shared host defaults to exact scope as required by [document 03](03-trust-graph-and-verdicts.md).

`enforcement.bundle_generations`

- generation ID/channel;
- input enforcement watermark;
- Bloom/PIR/manifest format versions;
- entry and tombstone counts;
- artifact digests and object references;
- signing key ID, signature, creation/expiry times;
- state `staged`, `published`, `rolled_back`, `withdrawn`;
- predecessor/rollback generation.

Unique `(channel, generation_id)` and `(channel, input_watermark, format_version)`. Publishing is an audited compare-and-swap so two compilers cannot race.

### Apple PIR protocol runtime state

This state is owned by the separately deployed PIR service, not the Trust Graph or bundle compiler. If PostgreSQL is selected, the minimum logical record is `pir.evaluation_key_sessions`:

- filter-runtime-keyed digest of Apple's pseudorandom `User-Identifier`;
- encrypted or opaque homomorphic-encryption evaluation key;
- PIR use-case, parameter-set, and compatible dataset-generation versions;
- bounded state;
- created, last-used, inactivity-expiry, absolute-expiry, and deletion times.

Unique `user_identifier_digest`; partial indexes on inactivity and absolute expiry. Delete the evaluation key and row together. Store no URL, canonical URL fingerprint, encrypted-query body, decrypted membership key, query result, long-lived bearer-token identity, Privacy Pass issuance identity, App Attest key, IP, MPD token, analytics value, graph entity, or cross-plane trace ID.

The `User-Identifier` is required pseudonymous protocol state and can correlate its own key/query lifecycle until expiry. It is not an app-generated stable product identity, MPD/analytics identifier, or evidence that Hezo sees a URL or membership result. Exclude the raw header and digest from logs, metrics, exports, support tools, and general audit search. Retention and parameter compatibility follow [document 07](07-apple-platform.md); O-018 owns the measured inactivity TTL, absolute TTL, capacity impact, and required-stage approval.

### Reports and analyst decisions

`intake.reports`

- public report ID;
- report type `scam` or `incorrect_verdict`;
- short-lived check-capability digest or encrypted restricted-content reference;
- per-record encryption-key reference and key-destruction time, never key material or a recoverable wrapped key copied into the content-backup domain;
- nullable target entity after safe resolution;
- bounded category;
- optional encrypted comment;
- client-generated deletion-capability digest while identifiable report content remains;
- status;
- received/resolved/delete times;
- consent/disclosure version for explicit submission;
- anti-abuse authorization class, not key identity.

Unique `(idempotency_scope, request_digest)` for the proposed 24-hour-or-shorter API replay window. The body-free idempotency digest is deleted independently of the restricted content. Index open review work by `(status, priority, received_at)`. No reporter identity, App Attest key, MPD token, analytics ID, account, email, or raw IP is present.

`intake.report_observations` converts only qualified, policy-capped report facts into ordinary observations. Raw reports never directly change a verdict score. A converted observation contains no free text, personal query/fragment value, report receipt, deletion capability, content-object reference, or submitter linkage. O-017 decides whether raw-report deletion retracts report-only support and when independent Hezo re-observation may supersede that dependency.

`decision.analyst_actions`

- named workforce actor reference;
- action type;
- target entity/verdict/enforcement entry;
- reason code and bounded note;
- scope, expiry, approval actor when required;
- created/revoked times.

Analyst actions are append-only audit events. Overrides and retractions create new state; they do not delete evidence.

### Jobs, outbox, and idempotency

`ops.outbox_events`

- UUIDv7 event ID;
- aggregate kind/public reference;
- event type and schema version;
- evidence watermark where relevant;
- bounded payload;
- created/published times, attempt count, delete deadline.

Partial index `(created_at, event_id)` where `published_at is null`; index `delete_after`.

`ops.inbox_receipts`

- consumer name;
- event ID;
- processed time;
- result digest;
- delete deadline.

Primary key `(consumer_name, event_id)`.

If PostgreSQL backs initial worker leasing, `ops.jobs` includes:

- job/public ID, job type, payload schema version;
- semantic idempotency digest;
- state `ready`, `leased`, `succeeded`, `failed`, or `dead`;
- priority, available time, leased-until, worker lease digest;
- attempt/max-attempt counts;
- opaque payload/artifact reference;
- policy/configuration versions;
- stable terminal/error code;
- created/completed/delete times.

Unique `(job_type, idempotency_digest)`. Use a partial ready index on `(priority desc, available_at, id)` where `state = 'ready'` and a partial lease-expiry index where `state = 'leased'`. Claims use `FOR UPDATE SKIP LOCKED`; no external call happens inside the claim transaction.

`ops.job_attempts` records bounded diagnostic code, timing, worker/image version, and retry decision. It never records payloads, URLs, page content, provider secrets, or attacker-controlled error text.

### Audit and retention

`retention.policies`

- policy ID/code/version;
- purpose and data class;
- normal retention duration;
- maximum duration;
- backup maximum age;
- purge mode;
- owner/reviewer and effective times.

`retention.runs` records policy, cutoff, affected table/partition, rows/objects deleted, start/end/status, and non-sensitive failure code. It does not preserve deleted values.

`audit.events` records named administrative actions, source/policy changes, exports, overrides, bundle promotions, and retention overrides. Ordinary consumer checks are not audit events.

A retention override is a separate, access-controlled record with owner, legal/security reason, exact scope, approval, and mandatory expiry. A nullable `delete_after` must not become an accidental indefinite hold.

## MPD measurement database

The canonical metric and consent behavior are defined in [document 02](02-privacy-and-measurement.md). Internally it is a measured protected installation-month, not proof of unique hardware.

`mpd.months`

- UTC month primary key;
- definition and methodology versions;
- acceptance start/end and finalization times;
- state `open`, `provisional`, or `final`;
- aggregate/publication references.

`mpd.monthly_presence`

- UTC month;
- server-keyed digest of the client month token;
- optional spent anonymous-credential digest for replay prevention;
- delete deadline.

Primary key `(month, token_digest)`. Token digests have an exact byte-length check. A partial unique constraint on `(month, spent_credential_digest)` where the digest is non-null prevents anonymous-credential replay. Upsert makes duplicate token delivery harmless. Protection enabled/healthy, production build, consent, definition version, and current UTC month are validated before acceptance; they are not copied into a per-installation profile row. The table has no event count, URL, verdict, check/report ID, App Attest key, analytics ID, raw IP, User-Agent, app/build version, device model, locale, carrier, timestamp, or precise behavior.

`mpd.withdrawal_requests`

- one open or provisional month;
- token digest;
- received/processed time;
- result code and delete deadline.

The client can derive and present one token per still-open or provisional month. Requests must not batch multiple month tokens because that would link them directly. The measurement service deletes the matching raw presence and returns the same result whether a row existed; it cannot recover already-purged tokens.

`mpd.monthly_rollups`

- month and methodology version;
- distinct accepted count;
- invalid/withdrawn exclusion counts;
- finalized/published times;
- reproducibility query/configuration digest;
- publication signature and correction predecessor.

Primary key `(month, methodology_version, publication_revision)`. Raw token material follows P-009: current month plus the approved 45-day correction window, then deletion and destruction of that month's server pepper. Non-identifying aggregates may be retained for published history.

Only the aggregate publisher can read token rows and write rollups. Public/reporting roles can read finalized rollups only.

## Product analytics database

Product analytics is omitted unless P-012 is affirmatively approved. If approved, schemas are generated from a reviewed allowlist, not a generic `track(name, properties)` endpoint.

`analytics.event_definitions`

- event name/version;
- exact product question and owner;
- permitted typed properties and cardinality limits;
- permitted coarse time precision;
- consent-copy version;
- retention duration and review expiry;
- enabled state.

`analytics.batches`

- one-time random batch digest used only for accidental replay prevention;
- schema version;
- approved coarse period;
- received/delete times;
- optional client-generated deletion-capability digest while the raw batch remains.

`analytics.batch_counts`

- batch reference;
- event name/version;
- positive bounded integer count;
- bounded schema-validated aggregate properties only when the definition permits them.

Primary key `(batch_id, event_name, event_version, property_set_digest)`. Constraints reject unknown event versions and properties. Every property is typed and allowlisted. A batch ID is never reused and is not a product identity. Rows may never contain a URL or URL fragment, domain, verdict, check/report/campaign/entity ID, MPD token, App Attest key, IDFV, IDFA, source-app name, QR/clipboard value, passive URL Filter query, blocked-event record, persistent installation ID, or cross-month contributor identifier.

Do not invent a 30/90-day installation identifier merely to make a retention chart possible. The accepted V1 analytics model intentionally cannot calculate true per-installation retention.

`analytics.rollups` contains only thresholded coarse aggregates. Only rollups may leave the plane.

## Anti-abuse database

The exact Apple validation procedure is in [document 07](07-apple-platform.md). The data model must support both iOS 26 legacy authenticator data and iOS 27 extensions without making newer fields mandatory.

`abuse.app_attest_keys`

- internal ID;
- environment `sandbox` or `production`;
- keyed digest of submitted key ID;
- validated P-256 public key and public-key digest;
- App ID and RP ID hash;
- AAGUID;
- nullable validation category and bundle version;
- attested time and state;
- last assertion counter stored as `bigint`;
- encrypted current receipt and receipt type;
- nullable risk metric, receipt not-before/expiry/refresh times;
- first/last seen, revoked, and inactive-delete times.

Unique `(environment, key_id_digest)` and `(environment, public_key_digest)`. `last_counter >= 0`. Sandbox and production records and encryption keys are isolated.

`abuse.challenges`

- random challenge digest;
- environment;
- challenge type/purpose;
- nullable key binding;
- HTTP method and route class;
- canonical request-body digest;
- issued/expiry/consumed times;
- state and bounded retry status.

Unique challenge digest; partial expiry index for unconsumed rows. Challenges contain at least 16 bytes of entropy; the recommended value is 32 bytes. Successful verification atomically consumes the challenge and advances the counter.

`abuse.capability_jtis`

- JTI digest;
- audience/purpose;
- body digest;
- expiry/consumed times.

The downstream capability contains no key ID or stable subject and is single use. Raw JTIs are never logged. If the destination needs a replay row, it stores a destination-secret, domain-separated HMAC that cannot be directly joined to anti-abuse's digest and deletes it at capability expiry. A direct subjectless capability still has timing-correlation limits and is not a substitute for the blinded public-MPD credential described in document 02.

`abuse.rate_limit_buckets`

- rotating keyed digest of a coarse network prefix or App Attest key;
- key-rotation version;
- endpoint class and bounded time bucket;
- count, risk outcome, and delete deadline.

Raw IP is processed in memory and never inserted. Network-derived digests rotate frequently and are proposed for no more than 72 hours. Do not combine network and key digests into a long-lived installation profile.

`abuse.receipt_refresh_jobs` stores only key reference, environment, eligibility time, attempt state, and deletion deadline. DeviceCheck signing keys live in the secrets manager.

If a blinded month-bound MPD credential is approved, `abuse.monthly_credential_issuance` records only the App Attest key reference, UTC month, issuance protocol/version, bounded issuance count/state, issue time, and delete deadline needed to prevent unlimited minting. It stores no blinded request material after issuance, redeemed credential, MPD token/digest, measurement request ID, redemption time, or cross-plane trace. The proposed retention is that month plus the 45-day correction window.

The anti-abuse service must not persist the semantic request body. A short-lived body digest is permitted only for assertion binding and replay control and expires with that control.

## Validity and retention

Use these fields consistently:

| Field | Meaning |
|---|---|
| `observed_at` | When a fact was observed or true |
| `valid_until` | Last time policy may treat support as current without refresh |
| `next_review_at` | Scheduled refresh/review time; not necessarily expiry |
| `expires_at` | Operational capability/job/artifact expiry |
| `delete_after` | Deadline for physical deletion from the live store |
| `retention_policy_id` | Versioned reason and maximum duration |
| `tombstoned_at` | Entity or enforcement state is withdrawn while minimal identity remains for propagation/rollback |

Proposed defaults, subject to document 02 and O-007/O-016/O-017/O-018:

| Data | Default direction |
|---|---|
| Known synchronous check | Memory only |
| Check capability, request digest, idempotency | 10–15 minutes |
| Exact encrypted URL for asynchronous analysis | Delete on completion; 24-hour hard maximum |
| DOM, HAR, response, screenshot, download | Delete at terminal processing; 24-hour hard maximum |
| Explicit analyst/report artifact hold | Selected artifacts only; seven-day maximum with owner, reason, audit, and expiry |
| Longer confirmed-malicious screenshot/DOM retention | Not authorized; O-016 only decides seven days versus shorter, and any longer period needs a new accepted decision plus synchronized document/test change |
| Report URL/comment/receipt and deletion-capability digest | Delete after triage/derivation; proposed 30-day maximum, per-record key destruction, final under O-017 |
| Report request idempotency/replay digest | Proposed 24-hour maximum, body-free and plane-local |
| Jobs / dead letters | Proposed 14 / 30 days with no sensitive payload |
| Public intelligence request/access logs | Seven days maximum and redacted; no body, URL, IP, or capability |
| Raw-free worker/control-plane operational logs | Proposed 30 days as in document 08; bounded fields only |
| Raw IP | Never persisted |
| Rotating anti-abuse network digest | Proposed 72 hours |
| Challenge and assertion replay state | Minutes to 24 hours by purpose |
| App Attest raw registration material | Delete after verified derivation except encrypted current receipt needed for refresh |
| Inactive App Attest derived state | Proposed 180 days, then re-attestation required |
| Apple PIR `User-Identifier` digest/evaluation key | O-018 sets validated inactivity and absolute TTLs; delete both together |
| MPD token digest | Current month plus approved 45-day correction window |
| Optional analytics raw batch | Proposed 30 days, with a local deletion capability while raw |
| Optional analytics aggregate | Proposed 13 months, with no contributor identifier |
| Final MPD aggregate | May be retained as non-identifying published history |
| Backups | Proposed 35-day maximum; run elapsed retention immediately after restore |

Source observations follow their terms snapshot and validity policy. Licensed non-user-derived threat intelligence may outlive these defaults, but an indefinite row requires an explicit retention policy and review date.

The general backup maximum never extends a shorter data-class deadline. Raw submitted URLs and hostile artifacts are excluded from long-lived snapshots/object versioning, and their per-object keys and every replica/version are deleted or cryptographically destroyed within the 24-hour hard limit. Restricted reports use an O-017-approved deletion-aware key store outside the content-backup set, or an equivalently proven design, so a deletion request or expiry makes backup ciphertext unreadable. Restore tests must prove the key cannot be recovered from snapshots, replicas, logs, or disaster-recovery copies. MPD month peppers and other erasure keys follow their own earlier destruction schedule.

## Migration rules

- One migration has one clear owner and forward-safe purpose.
- Add nullable columns or defaults safely, backfill in bounded batches, then enforce constraints.
- Add large indexes concurrently where the migration system supports it.
- Add expensive foreign/check constraints as `NOT VALID`, validate separately, then make them required.
- Do not rewrite or lock a high-volume table during a normal deploy.
- Do not delete or rename a contract field until all producers/consumers have passed a versioned deprecation window.
- Preserve old canonicalizer, collector, signal, and policy versions needed for replay.
- Migration rollback must not destroy newly collected evidence. Prefer forward repair when destructive reversal would lose facts.
- Every migration has an empty-database test, upgrade test, privilege test, forbidden-field test, query-plan check for critical paths, and retention impact note.

## Data-model build order

1. Create separate local databases and runtime/migration roles; prove cross-database denial.
2. Add source catalog, separate legal/runtime states, immutable terms snapshots, executable source operational policies, retention policies, and import runs.
3. Add entities, typed identities, domains/URLs, and deterministic canonicalization fixtures.
4. Add immutable observations, observation-entity roles, global semantic dedupe, and outbox.
5. Add relationship/evidence, signal/evidence, policy versions, verdict snapshots/reasons/heads, and replay fixtures.
6. Add jobs/leases/inbox and static collector-specific subtype tables.
7. Add restricted transient-analysis metadata, reports, analyst actions, and audit.
8. Add enforcement eligibility, entries, and signed generation metadata.
9. Add the anti-abuse database only with the App Attest proof.
10. Add MPD after consent, token, withdrawal, and deletion proofs; add analytics only after separate approval.

## Data-model acceptance criteria

- No prohibited cross-plane field exists in a table, view, index, queue, audit event, or backup export.
- Runtime grants prevent every service from writing outside its module and prevent all cross-plane reads.
- Every foreign key used for lookup or deletion has a supporting index.
- Duplicate import, collector, analysis, graph, signal, verdict, report, job, and MPD writes are harmless under concurrency.
- Observations cannot be updated or deleted by normal application roles.
- Every relationship and signal has explicit evidence support and version information.
- Relationship dependencies are same-watermark and strictly tiered; cycles and signal-to-relationship dependencies are impossible.
- Every verdict can be reproduced from its observation/relationship/signal snapshot, policy versions, and evidence watermark.
- Public verdict labels are constrained to `unknown`, `no_known_danger`, `caution`, and `dangerous`.
- A stale verdict job cannot replace a newer head.
- A `dangerous` verdict does not create an enforcement entry without a separate eligibility record.
- Exact/path evidence cannot widen to host/domain scope without an explicit scoped decision.
- A known routine check creates no durable history row.
- A raw submitted URL, query value, fragment, credential, or attacker-controlled page value cannot enter a normal graph, log, job, or error table.
- Restricted report content, replay state, deletion capability, derived support, per-record key, and backups follow the approved O-017 lifecycle and deletion tests.
- Source-rights withdrawal can identify affected observations and deterministically recompute or remove every derived output.
- A source cannot enter production unless legal approval, terms snapshot, operational policy, scope, freshness, and cost gates are all current and executable.
- Retention sweeps and backup-restore rehearsals delete rows and objects after `delete_after` without changing finalized aggregate counts.
- Repeated MPD presence for one month token counts once, and the token cannot be linked to an App Attest or analytics record from retained data.
- Apple PIR `User-Identifier` maps only to an expiring evaluation key in the filter-runtime store and cannot be queried from any product data-plane role.
- O-018 tests prove PIR inactivity/absolute expiry deletes the evaluation key and identifier digest together while preserving the validated Apple protocol lifecycle.
- Query plans use the entity identity, subject/time, reverse-edge, verdict-head, ready-job, expiry, and deletion indexes at the release-scale fixture.
- Non-production release-scale tests use `EXPLAIN (ANALYZE, BUFFERS)` for critical queries, verify the intended composite/partial indexes, and fail on material plan regressions; production diagnostics do not execute unsafe payload-bearing ad hoc plans.
- Load tests stay within each plane's connection budget, and timeout/lock tests prove a stalled worker or migration cannot exhaust the pool or leave an idle transaction holding locks.

## Open schema decisions

The implementation must not guess:

- exact UUIDv7 generation library/extension;
- managed queue versus PostgreSQL leasing;
- whether `pgvector` is justified and the embedding model/dimension/index;
- the partition thresholds and partition-management tool;
- exact raw URL, report, App Attest, PIR runtime-state, artifact, and backup retention;
- whether product analytics exists in V1 and, if so, the exact aggregate event allowlist;
- exact source contracts and source-specific retention/output restrictions;
- final MPD withdrawal/finalization methodology;
- exact scope and storage needed by Apple's production Bloom/PIR formats.

Record these through the ADR and decision process in [document 12](12-risks-decisions-and-open-questions.md).
