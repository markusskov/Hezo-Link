# S0-F source-rights and provider proof plan

This is a Draft plan under the [repository safety boundary](../repository-safety.md). It authorizes no proof root, runner, dependency, service, provider selection, provider call, account, credential, endpoint, network, cloud resource, live URL, threat item, terms access, contract, legal conclusion, budget, spend, connector, ingestion, runtime state, migration, evidence location, productionization, approval, or gate outcome.

| Field | Value |
|---|---|
| Proof ID | `S0-F-P01` |
| Work package | S0-F |
| Plan status | Draft |
| Accountable role | `Founder role`, with mandatory recorded concurrence from the `Legal role` and `Source rights role` |
| Supporting roles | `Intelligence role`, `Backend role`, `Privacy role`, `Security role`, `Infrastructure role`, `Operations role`, `QA role`, and `Release role`; the Release entry owns the independent public-safety review |
| Related kill risks | [R-003, R-004, R-007, R-010, R-012, and R-013](../../12-risks-decisions-and-open-questions.md#external-dependencies-and-kill-risks) |
| Linked decisions | [D-005, D-009, D-010, D-012, D-013, and D-020](../../12-risks-decisions-and-open-questions.md#accepted-product-decisions) are Accepted; [P-010 and P-011](../../12-risks-decisions-and-open-questions.md#proposed-technical-decisions) remain Proposed; [O-001 through O-008 and O-020](../../12-risks-decisions-and-open-questions.md#open-decisions) are Open; [ADR 0001](../../adr/0001-stage-0-gate-timing.md) is Proposed only |
| Proof location | Not authorized |
| Fixture manifests | The checked-in `s0-f-public-synthetic-provider-policy-vectors-2-manifest` is data-only input; every other fixture location and manifest is Not authorized |
| Environment class | Planned `local_offline` with `offline`, `loopback_fixture` with `loopback_only`, and `isolated_security_staging` with a network mode that must be made truthful before execution; none is authorized |
| Evidence-bundle reference | Not authorized |
| Review point | Before any candidate, terms, rights, proof-spend, account, credential, route, provider input, call, raw response, fixture, runner, dependency, or evidence store is accessed or created; after any material provider, product, terms, pricing, interface, notice, rights, privacy, quota, freshness, or outage-policy change |

## Kill-risk question

Can one owner-selected, commercially permitted qualified exact-threat candidate be exercised with provider-authorized reserved inputs, under explicit proof rights and bounded proof-spend authority, so its exact support, scope, notices, quota/cost, freshness/expiry, no-match/outage, kill-switch, terms-change, withdrawal, and replay behavior remains deterministic and fail closed, while no production ingestion, production runtime, live threat, unauthorized output, or unapproved retained material occurs?

The answer is negative if no candidate has current rights suitable for the Stage 2 manual-check slice; the selected product lacks a safe reserved-input exercise; a healthy authorized exercise cannot produce its frozen exact result; selection, legal, proof, and runtime state become conflated; an absent right becomes allowed; source or policy scope widens terms; a notice, quota, cost, expiry, no-match, outage, withdrawal, deletion, backup, replay, or recomputation invariant fails; or any provider, credential, terms material, raw response, live threat, production resource, or exact private commercial value crosses an unapproved boundary.

A negative answer pauses S0-F, the qualified exact-source path, Stage 2 source integration, and the complete Stage 0 exit. It cannot be compensated for by a public eligibility label, a fictional positive fixture state, infrastructure enrichment, public context, benchmark-only data, CISA `.gov` data, another unapproved provider, broader scaffolding, a favorable partial case, or treating an incomplete source as clean.

## Scope

### In scope

- The checked-in v2 public synthetic source-rights registry, provider-policy schemas, manifest, and all 60 data-only vectors.
- A restricted, human-controlled Stage 0 O-008 decision selecting exactly one qualified exact-threat candidate for proof, confirming proof-scope rights, and authorizing bounded proof spend without granting production authority.
- A current immutable restricted terms/contract basis for the exact provider product, plus a complete executable rights, scope, obligation, freshness, retention, quota, cost, notice, correction, change, and withdrawal policy.
- Independent selection, legal, proof, and runtime state, including positive proof that runtime remains disabled throughout and after S0-F.
- A deterministic loopback exercise of provider-specific policy and failure behavior without provider contact.
- A narrowly allowlisted proof-only exercise using only provider-authorized reserved inputs after every prerequisite is accepted; raw provider observations remain restricted.
- Exact-match/category/scope mapping suitable for the Stage 2 manual-check slice, without implying automatic client enforcement or any broader output right.
- Fail-closed quota, cost, retry, freshness, expiry, no-match, outage, last-known-good, terms-change, kill-switch, withdrawal, backup purge, recomputation, and idempotent replay behavior.
- Public-safe evidence metadata, restricted evidence review, and teardown or separately authorized productionization closeout.

### Out of scope

- Selecting P-010, P-011, or any provider/product through this plan; naming a selected proof candidate publicly; accepting a public eligibility label as legal approval.
- A production connector, production account, production credential, production procurement, annual budget, scheduled ingestion, feed download, source catalog migration, Trust Graph integration, verdict service, blockset, API, client, or consumer UI.
- Live malicious or sensitive URLs, copied feed rows, captured submissions, real user data, production observations, provider samples without redistribution rights, or uncontrolled Internet testing.
- Proving provider coverage, accuracy, recall, false-positive rate, production capacity, SLA, availability, commercial durability, or launch economics.
- Client enforcement, benchmark output, derived B2B output, raw redistribution, model training, or model validation unless each is independently approved later; the proof tests that absent rights deny those uses.
- Final Stage 2 procurement, provider account readiness, production cost controls, annual source budget, runtime enablement, or release approval.
- Legal advice, public terms publication, contract publication, exact prices, exact quotas, exact proof spend, private owner mappings, or evidence storage details.
- Treating proof code, temporary access, restricted records, or proof infrastructure as a production dependency.

### Assumptions and unknowns

- At least one exact provider product can grant the current commercial, consumer-verdict, consumer-explanation, processing, transient-storage, correction, and termination rights needed by the manual-check slice. A complete current review that denies any required use falsifies this assumption.
- The candidate offers a provider-authorized reserved-input mechanism that can exercise a current exact match and a no-match without contacting a live threat. If not, the proof remains blocked and may not substitute live data.
- A loopback policy oracle can reproduce the approved provider-specific contract while remaining independent of the implementation under test. A self-validating or incomplete oracle makes the affected result Inconclusive.
- A proof-only credential can be isolated from production identity and revoked at closeout. Any production authority, route, data, or reusable credential in the proof is a Stop.
- The current evidence schema can represent offline and loopback cases exactly. It does not explicitly name narrowly allowlisted real-provider proof egress; that mapping must be accepted or the schema revised before any Class C execution.
- Real terms, contracts, prices, quotas, account details, credentials, requests, responses, and legal reasoning can be reviewed in an approved restricted store and projected through non-enumerable opaque references. If public evidence is needed to reconstruct those values, the proof design is invalid.
- Contact counters describe prohibited boundary contacts, not permitted loopback or provider traffic. The S0-A companion validator must freeze that interpretation and exact arithmetic before execution.
- Evidence schema 2.0.0 has a root Inconclusive decision but no per-case `inconclusive` outcome. The exact accepted successor/companion contract must freeze an executed-undecidable code mapping and root precedence before execution.
- Evidence schema 2.0.0 has no restricted provider/source-observation evidence kind. A new explicitly versioned successor schema must add one before cases 050 or 054 can execute, while 2.0.0 remains immutable and continues to validate only its original contract; an existing unrelated evidence kind or an opaque identifier alone may not disguise raw provider evidence.

## Decisions and prerequisites

| Decision, ADR, approval, or access | Required state before execution | Current public-safe state | Stop action if absent |
|---|---|---|---|
| Exact plan revision and accountability | Human-approved `Approved to run`; Founder final-decision role and mandatory legal/source-rights concurrence recorded | Draft; no approval | Dispatch no case |
| S0-A governance and validator | One exact accepted dispatched evidence-schema version plus its companion prefix, reference, chronology, freshness, case, external-state, exception, contact, decision, closeout, and leak validator; Class C requires an explicitly versioned successor to immutable 2.0.0 with truthful provider-observation evidence | No authorized S0-F runner, successor schema, or validator is cited | No Class C execution or terminal Pass, Stop, or Inconclusive bundle |
| O-020 and decision timing | Owner-approved synchronized outcome; every decision it makes blocking for S0-F complete; while Open, O-001 through O-007 are complete under the conservative rule | O-020 Open; ADR 0001 Proposed only | Remain Draft; infer no later deadline |
| Repository and proof execution | Accepted proof-only root, language/dependencies, CI/network behavior, evidence handling, reset, retention, and teardown | Not accepted; location Not authorized | Create no runnable root, project, package, workflow, or dependency |
| O-002/O-003 proof environment | Accepted proof environment, region if applicable, network model, allowlisted route, secret/evidence services, budget/cost stop, and teardown ownership | Open under current conservative timing | Create no account, route, identity, service, store, or metered resource |
| Stage 0 O-008 pre-proof authority | Exactly one qualified exact-threat candidate selected for proof; proof-scope rights and bounded proof spend approved | Open; no candidate, right, or spend approved | Access no provider material and make no call |
| Stage 0 O-008 viability outcome | Founder/legal roles can inspect current completed proof evidence and record a separate post-proof viability outcome | No proof exists | Do not decide S0-F or Stage 0 |
| Production O-008 authority | Explicitly remains outside S0-F: procurement/contract activation, production account, production cost controls, and annual budget require later approval before Stage 2 | Open | Keep runtime disabled; create no production dependency |
| P-010/P-011 status | Exact Proposed states preserved unless independently accepted; P-011 remains infrastructure enrichment and cannot satisfy this gate | Both Proposed | Do not select either by plan wording or fixture |
| Candidate terms and rights review | Current immutable exact-product basis, complete rights/scope/obligation matrix, legal/source-rights review, review expiry, and terms-change process approved in restricted evidence | Absent | Read or use no provider data; do not infer omitted rights |
| Proof privacy/security review | Reserved-input transfer, transient request/response handling, processors, field allowlist, logging, retention, backups, deletion, correction, and termination reviewed | Absent | Send no input and retain no raw response |
| Provider proof access | Proof-only account/credential/endpoint class, owner, rate/cost cap, revocation, TLS/auth policy, and allowlisted route approved privately | Not authorized | Create no account/credential and contact no provider |
| Reserved-input and expected-result contract | Provider-authorized safe inputs, redistribution/handling class, canonicalization, requested/returned categories, match semantics, expiry, and expected bounded results frozen before run | Absent | Do not invent or publish a provider sample |
| Operational policies | Exact quota/cost units, warning/hard stops, concurrency/retry reservation, UTC reset, freshness, provider/policy expiry, outage/LKG, notice, correction, kill-switch, and recovery behavior approved | Only synthetic XTS/fictional policy exists | Do not let provider/tool defaults choose behavior |
| Withdrawal and retention | Locate/purge/tombstone/recompute/replay procedure, raw/derived/backup deadlines, proof receipt, and independent-Hezo-support rule approved | Normative direction only | Create no state that cannot be withdrawn and deleted |
| Environment-schema truthfulness | Class C network mode and proof-credential semantics truthfully representable by the evidence schema and companion validator | Current enum is ambiguous for real-provider proof egress | Run only Class A/B until accepted mapping or schema revision |
| Provider-evidence schema truthfulness | A restricted provider/source-observation evidence kind, its opaque-reference rules, access, retention, expiry, and public projection are represented by a new reviewed and explicitly dispatched successor schema; 2.0.0 is not changed in place | Schema 2.0.0 has no truthful kind for raw provider proof output | Execute no Class C provider request and invent no substitute evidence kind |
| Fixture manifests and rights | Every planning alias maps to one strict reviewed public-safe manifest; checked-in v2 bytes/digests reverified; restricted inputs remain separate evidence | One data-only package exists; others absent | Execute no unmanifested fixture or procedure |
| Evidence and public boundary | Approved restricted store/index/access/expiry, public projection, leak scan, independent review, and opaque-ID policy | Not authorized | Produce no raw result or public gate claim |
| Incident and closeout authority | Provider kill switch, access revocation, spend stop, legal/privacy escalation, deletion verification, teardown inventory, and residual-state owners approved | Generic requirements only | Start nothing that cannot be stopped and erased |

No prerequisite is satisfied by this plan, a Proposed ADR, a public-source eligibility label, a checked-in vector, a schema-valid file, an external request, an account application, a terms-page fetch, a successful partial case, or an opaque reference without reviewable underlying evidence.

## Fixtures

The IDs below are plan-local roles. Except for the cited checked-in v2 manifest, they are not manifest IDs, paths, approvals, provider identities, terms references, or evidence references. Before execution, every applicable role maps exactly once to a strict reviewed public-safe manifest. Restricted terms, contracts, account material, credentials, provider inputs without redistribution rights, requests, responses, and proof observations resolve separately through opaque `evidence_refs`; they never satisfy `fixture_refs`.

| Fixture ID and version | Planned source | Purpose | Safety classification | Cleanup or retention |
|---|---|---|---|---|
| `S0-F-FX-001-v1` | Location Not authorized | Governance, prerequisites, evidence schema, reference graph, outcome precedence, review, and closeout | Planned public synthetic metadata | Retain only reviewed public metadata |
| `S0-F-FX-002-v2` | [`s0-f-public-synthetic-provider-policy-vectors-2-manifest`](../../../fixtures/stage-0/source-rights/provider-policy-vectors.manifest.json) | Existing strict registry and 60 enablement, rights, notice, freshness, resource, source-class, withdrawal, and negative-contract vectors | Checked-in public synthetic, historical, offline, operational use forbidden | Retain exact reviewed fixture bytes only |
| `S0-F-FX-003-v1` | Location Not authorized | Candidate-selection, immutable-terms, rights, legal-review, O-008, P-010/P-011, and suitability projection contract | Planned public-safe metadata; underlying records restricted | Retain sanitized metadata only; restricted retention follows approval |
| `S0-F-FX-004-v1` | Location Not authorized | Environment, route, credential-class, canary, reset, kill-switch, and closeout procedure | Planned public-safe specification; deployed details restricted | Delete runtime state; retain sanitized contract only |
| `S0-F-FX-005-v1` | Location Not authorized | Provider-authorized reserved-input, request, canonicalization, TLS, and authentication procedure | Planned governed procedure; actual values restricted unless redistribution approved | Delete inputs, request state, and raw evidence |
| `S0-F-FX-006-v1` | Location Not authorized | Response parsing, category, match, scope, exact-support, no-match, malformed-response, replay, and correction matrix | Planned public synthetic/procedure metadata; raw responses restricted | Delete raw responses; retain bounded outcomes only |
| `S0-F-FX-007-v1` | Location Not authorized | Attribution, advisory, display, correction, and notice-state vectors | Planned public-safe template-reference metadata; actual approved copy restricted | Retain only sanitized result codes |
| `S0-F-FX-008-v1` | Location Not authorized | Quota, cost, warning, hard stop, retry, concurrency, reservation, and UTC-period-reset matrix | Planned synthetic thresholds; real values restricted | Delete runtime counters; retain bounded outcomes only |
| `S0-F-FX-009-v1` | Location Not authorized | Normal freshness, provider expiry, policy hard expiry, no-match, rate limit, outage, LKG, and recovery schedule | Planned public synthetic schedule; provider observations restricted | Delete raw observations; retain bounded outcomes only |
| `S0-F-FX-010-v1` | Location Not authorized | Enablement, runtime-disabled, kill-switch, terms-change, legal-state, and re-enable transitions | Planned public synthetic state contract | Delete proof state; retain sanitized transitions only |
| `S0-F-FX-011-v1` | Location Not authorized | Retraction, retirement, rights narrowing, purge, backup, tombstone, recomputation, independent support, and idempotent replay | Planned synthetic state/procedure contract | Delete proof stores/backups; retain sanitized receipt only |
| `S0-F-FX-012-v1` | Location Not authorized | Privacy, log, raw-response retention, evidence sanitation, review, incident, and teardown schedules | Planned public-safe metadata; raw operational evidence restricted | Delete runtime material; retain governed metadata only |

The checked-in v2 package freezes these exact public identities and digests:

- manifest ID `s0-f-public-synthetic-provider-policy-vectors-2-manifest` and fixture ID `s0-f-public-synthetic-provider-policy-vectors-2`;
- manifest SHA-256 `b7b26ba9e0c6773c9fe23f51c9879f1442771a21cd323f95219cdfa94c9b281f`;
- payload SHA-256 `ce7cb9a006f20aef59e0b21b02a90e01e46f7215109a0ce6a5e75d1b04dff718`;
- registry-schema SHA-256 `1687a946e24b0ce87fa610261e9d2e19933bbccd75fde93a562132002610d9ab`;
- vector-schema SHA-256 `e253cba1c29ea6736a7d70f1c0774b77e2c404e46da177b7e12c2fbf8cd37c76`; and
- manifest-schema SHA-256 `bc107e90877a2ab5c81337e308504e1a3aacc10e6e0013585508da967505d69d`.

Its 60 subordinate vectors are eight enablement, ten rights, three notices, eight freshness, seven resource-control, six source-class, eight withdrawal, and ten negative-contract cases. They are data-only inputs under cases 020–028 below, not S0-F proof evidence, a real registry, a provider exercise, a legal decision, or a gate result. Every subordinate vector remains individually visible; one favorable aggregate cannot hide a failure.

Planned bindings are closed. A case may cite multiple actual manifest IDs, but only from this map. Missing, duplicate, dangling, cross-version, undeclared, or scope-incompatible mappings block execution.

- `S0-F-FX-001-v1` binds cases 001–010, 117–118, 900, and 901.
- `S0-F-FX-002-v2` binds cases 007 and 020–028.
- `S0-F-FX-003-v1` binds cases 005–007, 030–039, 090–093, 103, 110–118, 900, and 901.
- `S0-F-FX-004-v1` binds cases 007–008, 040–049, 078–079, 116, 900, and 901.
- `S0-F-FX-005-v1` binds cases 007, 044–045, 049–054, 056–058, 112, 900, and 901.
- `S0-F-FX-006-v1` binds cases 007, 048, 050–059, 112–115, 900, and 901.
- `S0-F-FX-007-v1` binds cases 007, 034, 050, 052–053, 059–064, 111–113, 900, and 901.
- `S0-F-FX-008-v1` binds cases 007, 036, 049, 070–079, 114, 900, and 901.
- `S0-F-FX-009-v1` binds cases 007, 050, 054–056, 080–089, 112–114, 900, and 901.
- `S0-F-FX-010-v1` binds cases 007, 035, 078, 090–093, 103, 115–116, 900, and 901.
- `S0-F-FX-011-v1` binds cases 007, 047, 058–059, 094–103, 115–116, 900, and 901.
- `S0-F-FX-012-v1` binds cases 007–010, 034, 037, 039–049, 064, 096–099, 117–118, 900, and 901.

Public manifests may describe deterministic construction, input class, procedure structure, expected bounded codes, provenance, rights review class, and an opaque restricted-input reference. They must not contain a real provider identity, endpoint, account, credential, terms text or URL, contract, price, quota, budget, live URL, provider response, feed row, exact route, raw log, or evidence location.

Every alias binds `S0-F-CASE-007`, so that case validates every actual manifest rather than only the checked-in package. Cases 900 and 901 cite `S0-F-FX-001-v1` plus every resource-bearing actual manifest above. The complete `S0-F-FX-001-v1` inventory records each non-resource public artifact as retained-governed or none-created. The historical `S0-F-FX-002-v2` payload is retained as a reviewed public fixture and is not loaded into, regenerated by, or treated as runtime input to Class C closeout.

## Environment and isolation

### Class A — offline contract and review projection

- Uses only reviewed public synthetic fixtures, closed schemas/policy functions, immutable public digests, and sanitized decision/evidence projections.
- Has no network, provider access, account, credential, live target, production route, production data, or operational source record.
- Validates governance, the complete 60-vector package, public/private references, decision-state independence, rights defaults, case coverage, and final sanitized reconciliation.
- Cannot prove provider transport, provider response, proof access isolation, real legal rights, actual cost, runtime withdrawal, or deletion from a provider-controlled system.

### Class B — loopback provider-policy simulation

- Uses a loopback-only deterministic provider stub and policy oracle built only after an Accepted repository/execution decision.
- Loads provider-specific policy through an approved restricted projection without exposing provider identity, terms, prices, quotas, credentials, endpoints, or response bytes in Git.
- Exercises parser mutations, notices, quota/cost, retry, freshness, expiry, outage, LKG, terms-change, kill-switch, withdrawal, backup purge, recomputation, and replay without a provider call.
- Has no external network route, production credential, production data, live threat, or scheduled ingestion and resets every counter, store, cache, key, log, and fixture state between cases.

### Class C — isolated reserved-input provider proof

- Uses one approved proof-only environment and one proof-only provider access path for the exact candidate/product selected by the restricted O-008 decision.
- Allows only the provider-authorized reserved-input route and schema-bound proof control/evidence channels. Every other egress, metadata, production, administrative, cross-plane, and live-threat path is technically denied and independently observed.
- Uses no production credential, production account authority, production Hezo service, production data, live threat, captured submission, or scheduled ingestion. Runtime state remains disabled.
- Records exact private account, credential, endpoint, route, provider, request, response, quota, cost, and observer detail only in approved restricted evidence.
- Resets counters before each call, bounds retries/concurrency/spend, destroys transient request/response state after derivation, and revokes proof access at closeout.

The public evidence records Class A as `local_offline`/`offline` and Class B as `loopback_fixture`/`loopback_only`. For Class C, the planned class is `isolated_security_staging`. Evidence schema 2.0.0 currently offers `isolated_fixture_network`, which may be used only after an Accepted S0-A interpretation states that it truthfully covers this exact allowlisted provider-reserved-input path. Otherwise the schema and plan must gain a reviewed explicit mode before Class C runs. A note, hidden route, or false `offline`/`loopback` label is prohibited.

All environment records use `synthetic_or_sanitized` and set `production_credentials_present`, `production_data_access`, and `live_threat_access` to false. A proof credential is not a production credential, but that distinction must be frozen in the schema/companion contract rather than inferred after execution.

Case-to-environment mapping is closed:

- cases 001–039 and 110–118 execute only in Class A;
- cases 048–049, 051–053, and 055–103 execute only in Class B;
- cases 040–047, 050, 054, 900, and 901 execute only in Class C; and
- no row implicitly runs in multiple classes. A required second observation receives a new stable case ID or an approved plan/schema revision.

Cases 900 and 901 use a pre-frozen Class C closeout-controller environment record. Its single `environment_ref`, immutable tool revisions, `S0-F-FX-001-v1` inventory, resource-bearing manifest refs, and evidence dependencies enumerate every Class A/B/C artifact or resource whose disposition it reconciles. The controller does not claim those resources executed in Class C. If the evidence schema and companion validator cannot represent that controller-and-dependency meaning truthfully, closeout cannot execute until a reviewed schema/plan revision resolves it.

Cases 040–047, 050, 054, 900, and 901 set `contact_counts.applicable: true`. Their actual manifests freeze the exact number of deliberate prohibited-route `test_attempts` and expected `egress_denials`, including zero for a case that performs no prohibited probe. For Pass, `tcp_connections`, `udp_datagrams`, `application_requests`, `metadata_contacts`, `production_resource_contacts`, and `cross_job_contacts` are zero in every applicable case and in the recomputed bundle totals.

Every executed Class A/B case sets `contact_counts.applicable: false` and all eight counters to zero. Permitted loopback/provider traffic, provider attempt counts, proof costs, privacy-canary insertions, and expected fixture hits are separate bounded evidence and never placed in, subtracted from, or hidden between prohibited-contact counters. A zero without healthy observers is Inconclusive. Every nonexecuted case has no interval or duration, uses inapplicable/all-zero counters, retains the schema-required exception-decision fields and safe notes, and cites the Stop/Inconclusive cause.

## External-state encoding

The final public bundle keeps four materially different decisions separate:

- `s0-f-o008-pre-proof-authority-stage-gate`: `kind: other_owner_decision`, `scope: stage_gate`, `required_for_pass: true`, `accountable_role: Founder role`; state may be `approved` only for the restricted exact-candidate, proof-rights, and bounded-proof-spend decision.
- `s0-f-o008-post-proof-viability-stage-gate`: `kind: other_owner_decision`, `scope: stage_gate`, `required_for_pass: true`, `accountable_role: Founder role`; state may be `approved` only after mandatory legal/source-rights review of the completed current proof.
- `s0-f-o020-timing-stage-gate`: `kind: other_owner_decision`, `scope: stage_gate`, `required_for_pass: true`, `accountable_role: Founder role`; it records the owner-approved applied timing boundary, not Proposed ADR 0001.
- `s0-f-source-production-use`: `kind: source_production_use`, `scope: production_use`, `required_for_pass: false`, `accountable_role: Founder role`; it preserves the truthful current nonapproved state, normally `not_started` or `pending`, for production procurement, account, cost controls, annual budget, and runtime authorization.

The companion validator rejects merging the pre-proof and post-proof O-008 states; treating proof spend as production budget; treating provider exercise as production-use approval; using P-010/P-011 or a fixture state as an external decision; omitting the nonrequired production-use state; or allowing an opaque reference to encode the provider, product, account, person, location, or terms source.

## Rights and operational semantics

- The exact provider product, not merely its company, is the unit of review.
- Selection, legal approval, proof completion, and runtime enablement are independent. No state or reference implies another, and S0-F runtime remains disabled.
- Every right is explicit. Missing, null, unknown, stale, or false means denied. Effective rights and scope are intersections, never unions.
- The manual-check suitability gate requires current commercial internal use, deliberately submitted/reserved-input transfer for the approved purpose, consumer-verdict support, the actual consumer explanation/display form, approved processing, transient storage, correction, deletion, and termination behavior. It does not silently require or grant client enforcement, benchmark, B2B, redistribution, or model rights.
- Terms and policy intervals are half-open. Equality with effective expiry, terms expiry, review expiry, provider expiry, or policy hard expiry is expired. The earliest applicable expiry wins.
- Required attribution or advisory copy must resolve to the exact approved current template and be rendered for the affected purpose. Missing copy denies that output. `not_required` forbids a stale template reference.
- A match can contribute only at its licensed indicator, category, match-semantic, and enforcement scope. Exact/path support never widens to host/domain or automatic blocking by convenience.
- A no-match provides no source support and never proves clean. Timeout, unavailable, rate-limited, malformed, auth-failed, unknown-usage, and exhausted states are incomplete/Unknown as policy requires.
- Last-known-good support is usable only if explicitly permitted, before the earliest hard expiry, with stale disclosure. At expiry it is excluded and affected outputs are scheduled for recomputation.
- Warning equality allows and alerts only when the accepted policy says so. Projected use equal to or above quota or cost hard stop denies before the request. Unknown usage denies. UTC-month reset occurs at the exact boundary. Retries/concurrency reserve projected units atomically and cannot amplify calls or spend.
- A terms digest change creates a new unapproved immutable snapshot, stops new requests/ingestion and new support, marks prior support pending review, and schedules recomputation. Re-enable requires a new current human decision.
- Retirement, rights narrowing, and retraction locate affected observations and outputs, stop disallowed access, purge prohibited raw/derived and backup material, tombstone disallowed enforcement, recompute verdicts/blocksets/exports, preserve independently permitted Hezo evidence, and remain idempotent on replay.

## Expected cases

Cases 001 through 118 listed below—97 regular cases across the intentionally unused numbering gaps—are `required: true`. Every row expands into every manifest-declared mutation or subvector. Expected denial is recorded as case `pass` with the frozen bounded denial code. Cases 900 and 901 use the mutually exclusive closeout rule after the tables.

### Governance and evidence cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-001` | Frozen plan and prerequisite matrix | Attempt dispatch | Only the exact `Approved to run` revision with designated roles and current prerequisites dispatches; Draft, Open, Proposed, stale, or submitted-only states deny before access | Planning creates no provider or tool authority | Sanitized prerequisite matrix, decision revisions/times, and zero preauthorization access |
| `S0-F-CASE-002` | Exact accepted dispatched evidence schema and companion validator, including cross-version dispatch against immutable 2.0.0 and the required Class C successor | Run valid and invalid prefix, version, reference, chronology, expiry, exception, external-state, contact, decision, review, closeout, and leak mutations | Each bundle validates only under its declared exact schema; invalid or cross-version evidence cannot reach a terminal outcome; schema shape alone never passes | Evidence cannot manufacture selection, rights, proof, or a schema upgrade | Validator/schema revisions, cross-version rejection, and mutation results |
| `S0-F-CASE-003` | O-020 record and decision register | Resolve applied timing | Every decision made blocking is complete; conservative O-001–O-007 handling applies until a synchronized owner-approved replacement | Later table deadlines cannot authorize S0-F | Decision-state map and applied-boundary reference |
| `S0-F-CASE-004` | Accepted repository/execution decision | Resolve every root, runner, dependency, CI/network behavior, evidence sink, reset, retention, and teardown owner | Only explicit proof-scoped artifacts are permitted; no production choice is inferred | A framework or fixture cannot become architecture | ADR revision, approved path classes, dependency/license inventory, and teardown owners |
| `S0-F-CASE-005` | O-008 pre-proof, post-proof, and production portions | Project the three states independently | Candidate/rights/proof-spend authority precedes provider access; viability follows completed proof; production procurement/account/annual budget remains separate | One approval cannot silently cover three purposes | Sanitized state matrix and opaque restricted refs |
| `S0-F-CASE-006` | Four planned external-state records | Validate kinds, scopes, required flags, accountable roles, state, dates, and evidence refs | Required Stage 0 states are current; production use remains truthful and nonrequired; no fixture fills an external state | Public metadata cannot turn proof into runtime authority | External-state projection and mutation denials |
| `S0-F-CASE-007` | Every actual fixture manifest and the checked-in v2 package | Validate schema, bytes, digest, size, construction, safety, provenance, rights, and case binding | Each planning alias resolves exactly once; v2 identities/digests/counts match; restricted/live material is absent | Planned aliases and opaque refs are not fixtures | Manifest IDs/digests, verification results, rights/safety review, and binding graph |
| `S0-F-CASE-008` | Frozen Class A/B/C environment and contact map | Validate each actual environment against schema and restricted configuration | Each case has one truthful environment; applicable counters have calibrated observers; other cases are explicitly inapplicable/all-zero | An ambiguous environment or zero cannot support Pass | Environment records, mapping result, calibration/reset refs, and counter vocabulary |
| `S0-F-CASE-009` | Approved evidence boundary, opaque-ID policy, retention, and public scanner | Exercise create, cite, expire, review, delete, and public-project controls | Raw/restricted evidence remains private; public output contains only approved metadata and non-enumerable opaque refs | Git cannot become a terms, provider, account, or evidence index | Data inventory, access/expiry/deletion results, scan result, and opaque refs |
| `S0-F-CASE-010` | Complete case/vector/reference/outcome graph | Recompute required coverage, fixture/evidence refs, contact sums, freshness, reviews, closeout, and outcome precedence | All 97 regular cases, 60 subordinate vectors, and one closeout path are represented; Stop precedes Inconclusive and Pass | Aggregation cannot hide a failed vector or missing evidence | Coverage graph, arithmetic result, reference resolution, and precedence result |

### Checked-in v2 contract cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-020` | Exact manifest, payload, and three schema files | Recompute bytes, SHA-256, counts, UTF-8/LF/final-newline, strict schemas, identities, and historical/safety constants | Every recorded identity, digest, size, count, and safety declaration matches; no network occurs | Data-only bytes cannot drift silently | File revisions, recomputed digests/sizes/counts, and schema results |
| `S0-F-CASE-021` | Eight `enablement_cases` | Evaluate each state independently | Only all-gates-satisfied permits the fictional production branch; candidate, failed proof, conditional legal, disabled runtime, expired governance, kill switch, and material change deny with exact reasons | Fictional positive state never describes Hezo | Eight individual inputs/results and coverage count |
| `S0-F-CASE-022` | Ten `rights_cases` | Evaluate all nine independent rights and the positive intersection | Every false/absent right denies its purpose; terms and policy must both allow the positive result | Omission or unrelated permission cannot grant a right | Ten individual inputs/results and rights-field coverage |
| `S0-F-CASE-023` | Three `notice_cases` | Render both notices, omit attribution, then omit advisory | Complete required copy allows the fictional explanation; either omission denies with its exact code | Required notices are executable obligations | Three individual results and template-ref comparison |
| `S0-F-CASE-024` | Eight `freshness_cases` | Evaluate before/equal boundaries, no-match, timeout, outage/LKG, hard expiry, rate limit, and earlier provider expiry | Half-open/earliest expiry and not-clean semantics match every expected result | Stale or absent support cannot become clean | Eight individual timelines/results and recomputation flags |
| `S0-F-CASE-025` | Seven `resource_control_cases` | Evaluate below warning, warning equality, hard-stop equality, unknown usage, and UTC reset | Warning permits/alerts; projected hard-stop equality and unknown usage deny; exact UTC reset is deterministic | Cost/quota cannot fail open | Seven individual arithmetic results and reset boundary |
| `S0-F-CASE-026` | Six `source_class_cases` | Request dangerous/enforcement/production support from each class | Only qualified exact support can satisfy its allowed fictional case; infrastructure, public context, and benchmark-only sources deny disallowed uses | Context and infrastructure cannot become exact threat authority | Six individual class/use results |
| `S0-F-CASE-027` | Eight `withdrawal_cases` | Apply retirement, retraction, rights narrowing, intersection, purge, repeat, and independent-support scenarios | Counts, effective rights, actions, purge, tombstone, recompute, preservation, and duplicate-effect values match exactly | Withdrawal cannot be partial or non-idempotent | Eight before/after records and action/result comparison |
| `S0-F-CASE-028` | Ten `negative_contract_cases` | Apply every declared schema and semantic mutation | Missing rights, unknown fields, unsafe refs, inconsistent gates, bad refs, broadened scope, unordered limits/times, and retention/notice mismatch reject at the exact layer | Strict shape does not replace semantic validation | Ten mutation IDs, JSON pointers, validation layers, and rejection results |

### Candidate, terms, rights, and review cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-030` | Restricted O-008 pre-proof record | Validate candidate class, exact product, selection purpose, proof rights, bounded spend, dates, and roles through a public-safe projection | Exactly one qualified exact-threat product is selected for proof; no public provider identity or production authority appears | A public matrix cannot select a candidate | Sanitized completeness result and opaque selection/right/spend refs |
| `S0-F-CASE-031` | Current immutable terms/contract basis | Verify exact product, source, capture/effective/expiry/review times, immutable content basis, supersession, and reviewer status | One current approved restricted basis supports the proof; changes create new records rather than mutation | Stale or mutable terms cannot support Pass | Sanitized currentness result and opaque rights-review ref |
| `S0-F-CASE-032` | Complete nine-right matrix from terms and policy | Evaluate each purpose, missing/null/false mutations, and the intended manual-check purposes | Every right is explicit/default-deny; only the intersection permits an intended use | General commercial access cannot imply output rights | Per-right allow/deny matrix and intersection result |
| `S0-F-CASE-033` | Indicator, category, match-semantic, source-class, field, and enforcement-scope ceilings | Attempt exact allowed use and every policy/output broadening | Exact approved use succeeds; host/domain/category/field/output widening denies | Enforcement and explanation cannot exceed evidence/license scope | Scope matrices, denial codes, and no-widening result |
| `S0-F-CASE-034` | Geography, processors, contractors, storage, backups, attribution, advisory, correction, audit, retention, and termination obligations | Compare intended proof/manual-check behavior with every obligation | All consumed obligations are affirmative/current and executable; omitted obligations deny the affected behavior | Operational convenience cannot override terms | Sanitized obligation coverage and opaque legal/privacy refs |
| `S0-F-CASE-035` | Independent selection, legal, proof, and runtime states | Apply valid and cross-implying transitions | No state manufactures another; S0-F runtime remains disabled before, during, and after proof | Proof success is not runtime enablement | Transition matrix, disabled runtime evidence, and rejected conflations |
| `S0-F-CASE-036` | Restricted proof-spend authority and public synthetic cost contract | Validate owner, purpose, expiry, private ceiling, warning/stop mapping, and production exclusion | Bounded proof spend is current and enforceable; no amount appears publicly and no annual/production budget is inferred | Metered proof work cannot become open-ended purchasing | Sanitized authority state, bounded outcome codes, and opaque approval ref |
| `S0-F-CASE-037` | Candidate-specific proof data flow and security/privacy review | Trace reserved input, request, provider, response, derivation, logs, evidence, deletion, and processors | Only approved fields/sinks exist; no identifier enters another data plane; deletion/retention is exact | A reserved URL can still be sensitive | Sanitized flow result, field/sink allowlists, and opaque reviews |
| `S0-F-CASE-038` | Public eligibility matrix and P-010/P-011 states | Attempt to use public labels, P-010, P-011, CISA `.gov`, infrastructure, context, or benchmark status as selection/gate evidence | Every substitution denies; P-010/P-011 remain Proposed and P-011 cannot satisfy exact-threat qualification | Eligibility and enrichment are not rights or proof | Proposal-state projection and substitution denials |
| `S0-F-CASE-039` | Legal, source-rights, privacy, security, intelligence, backend, and operations review requirements | Validate reviewer role, current evidence access, review/terms expiry, contradictions, and next review | Every required role can inspect its restricted evidence and no material contradiction/open required review remains | An opaque ref without an authorized reviewer is not evidence | Sanitized review matrix, dates, contradictions result, and opaque review refs |

### Provider-proof environment and access cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-040` | Approved Class C environment and schema mapping | Compare actual tools, network, credential class, data mode, routes, stores, observers, and resets with the frozen record | Evidence class/network mode is truthful; every material component/revision is represented without private detail | Evidence vocabulary cannot hide provider egress | Environment record, restricted configuration review, and mismatch result |
| `S0-F-CASE-041` | Proof-only account/access inventory plus manifest-approved synthetic invalid-identity representations | Use the valid proof identity only for the authorized external control; evaluate every production, cross-environment, expired, and over-scope representation pre-network or against a local loopback authentication fixture | Only the proof identity reaches the exact proof product; every synthetic invalid representation denies without an external call; no real production/cross-environment identity, account, or credential is created or used | Proof credentials are not production credentials | Capability matrix, expiry/revocation result, zero invalid external calls, and zero cross-environment effect |
| `S0-F-CASE-042` | Allowlisted provider route plus manifest-approved isolated synthetic representations of internal, metadata, production, admin, and arbitrary-Internet canaries | Probe the approved synthetic route classes under calibrated independent observers; never address a real internal, metadata, production, admin, or unapproved third-party resource | Only the approved provider-reserved-input route works; every synthetic prohibited-route probe denies with six prohibited-contact counters zero | Provider access cannot become general egress | Attempt/denial counts, permitted-route count, observer health, canary safety review, and zero contact counters |
| `S0-F-CASE-043` | Static production source/runtime/configuration inventory plus manifest-approved synthetic sentinels | Inspect proof configuration and exercise only synthetic sentinel capabilities for connector, scheduler, catalog, queue, store, feature-flag, and ingestion classes; never provision, query, or address a real production resource | No production dependency or enabled runtime path exists; every sentinel is absent or denied | S0-F cannot create shadow production | Static inventory/search result, sentinel denials, and runtime-disabled evidence |
| `S0-F-CASE-044` | Provider-authorized reserved exact-match/no-match inputs and handling record | Validate provenance, authorization, non-live status, allowed use, expiry, and restricted/public classification before call | Only the exact approved reserved inputs are eligible; live/copied/expired/unreviewed values deny before network | Test convenience cannot introduce a live threat | Input-class decision, opaque provenance/rights refs, and zero rejected-input calls |
| `S0-F-CASE-045` | Exact route/TLS/provider-authentication policy, proof credential, and controlled loopback negative fixture | Send only the valid control and any explicitly provider-authorized reserved negative externally; evaluate all other scheme/host/port/path/method, redirect, DNS-peer/special-address, proxy, certificate/SNI, protocol, authentication, and debug-override mutations pre-network or against the controlled fixture | The valid proof transport authenticates as designed; redirects are disabled or fully revalidated without forwarding credentials or reserved input; every alternate peer/proxy/endpoint, mismatch, invalid certificate, debug override, or unapproved method denies; certificate validation is never disabled | No proof bypass may weaken transport/authentication or redirect authority | Bounded route/transport/auth results, zero unauthorized external mutations, peer/Host/SNI binding, and restricted valid-control handshake evidence |
| `S0-F-CASE-046` | Secret, request, response, URL-like, account, and provider-identity canaries | Exercise success and every error/retry path, then scan logs, traces, metrics, crashes, queues, support, and public output | No restricted value reaches a prohibited sink; bounded labels contain no input/provider/account identity | Operational visibility cannot leak source material | Canary family/count results, sink scan, and observer health |
| `S0-F-CASE-047` | Encrypted transient request/response store, derivation, replicas, snapshots, backups, and deletion worker | Create the minimum approved proof material, derive bounded facts, expire/delete, and restore-check | Raw material is inaccessible after its exact deadline in every copy; only approved restricted audit/provenance remains | Proof evidence cannot become an indefinite feed archive | Lifecycle timeline, deletion/restore results, and opaque receipts |
| `S0-F-CASE-048` | Loopback response parser and bounded mutation corpus, pinned to the identical parser artifact/configuration digest used for Class C responses | Inject unknown fields, wrong types, oversized/deep values, duplicate keys, truncation, invalid encoding, compression/signature/checksum variants as applicable and compare the Class B/Class C parser digests | Every malformed/untrusted response rejects with bounded errors and no observation/support; untrusted parsing has no proof credential, control/evidence authority, executable surface, or route to another data plane | Provider input is untrusted even when authenticated, and a different Class C parser cannot bypass the corpus | Per-mutation results, both parser/configuration digests, isolation/resource bounds, and zero accepted bad facts |
| `S0-F-CASE-049` | Reset, cancellation, timeout, retry, concurrency, and idempotency schedule | Interrupt each phase and repeat from clean/ambiguous states | Requests and units remain bounded; committed outcomes reconcile once; no duplicate support, leaked state, or retry amplification occurs | Failure recovery cannot multiply provider calls or spend | Attempt/unit/effect counts, state transitions, and reset evidence |

### Provider match, scope, failure, and correction cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-050` | Healthy authorized Class C provider path and frozen reserved exact-match input | Perform one bounded proof request | Provider returns the exact expected current match/category/scope under the frozen contract; only bounded restricted evidence is retained | A provider proof needs one real safe positive control | Attempt/result/expiry categories, exact revisions, cost units, and an opaque provider-observation ref under the required future schema kind; the current schema gap blocks execution |
| `S0-F-CASE-051` | Provider-specific canonicalization vectors and independent oracle | Apply every official/approved vector and parser differential in Class B | Implementation and oracle produce the exact frozen provider representation or reject identically | General URL canonicalization cannot be guessed for a provider | Per-vector comparison, oracle independence, and canonicalizer revision |
| `S0-F-CASE-052` | Requested/returned threat types, indicator types, categories, and match semantics | Map allowed and unknown/contradictory combinations | Known combinations map exactly; unknown, missing, overbroad, or contradictory semantics reject without support | Provider names cannot substitute for semantic qualification | Mapping matrix and rejection results |
| `S0-F-CASE-053` | Exact/path/host/domain and consumer-verdict/enforcement output requests | Apply licensed scope intersection | Only explicitly licensed evidence/output scope survives; exact/path support never widens and verdict right never implies block right | Dangerous and block eligibility remain separate | Per-scope result and zero widened outputs |
| `S0-F-CASE-054` | Healthy authorized Class C path and frozen reserved no-match input | Perform one bounded proof request | Result is `no_source_support`, never clean, safe, trusted, or evidence of benignness | Absence from one source is not a benign label | Attempt/result code, provider availability state, and an opaque provider-observation ref under the required future schema kind; the current schema gap blocks execution |
| `S0-F-CASE-055` | Loopback timeout and unavailable injections with no current LKG | Evaluate the manual-check source result | Result is explicit incomplete/Unknown with zero source support and no clean claim | Dependency failure cannot fail clean | Per-injection status and consumer-completeness mapping |
| `S0-F-CASE-056` | Auth denied, forbidden, credential expired, and wrong-product injections | Attempt source access and evaluate result | Calls fail closed with bounded operational codes; no source support or clean claim is produced | Authentication failure cannot be reinterpreted as no match | Attempt/result matrix and zero accepted support |
| `S0-F-CASE-057` | Malformed, corrupt, replayed-old, unknown-category, and impossible-expiry responses | Parse and evaluate | Every invalid response rejects/quarantines, creates no observation, and yields incomplete/Unknown | Corrupt provider data cannot enter evidence | Per-response rejection, quarantine/deletion result, and zero observations |
| `S0-F-CASE-058` | Duplicate request/response, redelivery, lease expiry, and replay schedule | Deliver each event concurrently and repeatedly | Exactly one proof-local fact/effect exists; retries are harmless and bounded | Delivery semantics cannot duplicate source weight | Attempt/dedupe/effect counts and idempotency keys/classes |
| `S0-F-CASE-059` | Approved provider correction/false-positive workflow and synthetic disputed support | Invoke the proof-local correction path and simulate provider acknowledgement/retraction states without an unauthorized external submission | The workflow is reachable, scoped, auditable, and can suspend/retract support; no public accusation or provider contact occurs unless separately authorized | A selected source needs a correction path | State/result matrix, owner role, and opaque workflow review |

### Attribution and advisory cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-060` | Required current attribution reference and proof renderer | Render the affected explanation | Exact approved attribution reference is used and output eligibility is true | Attribution is policy, not hard-coded decoration | Template revision class and sanitized render result |
| `S0-F-CASE-061` | Required current advisory reference and proof renderer | Render the affected explanation | Exact approved advisory reference is used and output eligibility is true | Required limitations cannot be omitted | Template revision class and sanitized render result |
| `S0-F-CASE-062` | Required attribution/advisory with each template or rendered component removed/stale | Evaluate affected output | Each missing, stale, mismatched, or unrendered obligation denies with its exact code | Consumer copy cannot outrun legal obligations | Mutation matrix and denial results |
| `S0-F-CASE-063` | Terms/policy notice status `not_required` plus stale template references | Validate and render | Any stale reference rejects; no unnecessary provider copy is retained/rendered | Old obligations cannot linger invisibly | Schema/semantic results and zero stale render |
| `S0-F-CASE-064` | Restricted approved notice/correction copy and public projection | Review currentness, purpose, locale, scope, expiry, and public-safe output | Authorized roles can inspect exact copy; public evidence exposes only bounded codes and opaque refs | Public evidence cannot publish contract-derived copy | Sanitized review result, dates, and opaque refs |

### Quota, cost, retry, and kill-switch cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-070` | Known usage below both approved private warning boundaries | Reserve one projected unit | Request is allowed without alert | Normal use remains bounded and measured | Sanitized before/projected state and result code |
| `S0-F-CASE-071` | Known projected usage equal to each warning boundary | Reserve one unit for quota and cost variants | Request is allowed and the correct bounded alert fires once | Warning equality cannot be ambiguous | Per-resource arithmetic and alert count |
| `S0-F-CASE-072` | Known projected quota equal to and above hard stop | Attempt reservation/request | Both deny before provider contact and alert once | Hard quota is a pre-call stop | Arithmetic, zero provider attempts, and alert result |
| `S0-F-CASE-073` | Known projected cost equal to and above hard stop | Attempt reservation/request | Both deny before provider contact and alert once | Cost ceiling is enforceable, not advisory | Arithmetic, zero provider attempts, and alert result |
| `S0-F-CASE-074` | Missing, stale, corrupt, or contradictory usage state | Attempt reservation/request | Every variant denies and alerts with `usage_unknown`-class result | Unknown accounting cannot fail open | Variant results and zero provider attempts |
| `S0-F-CASE-075` | Usage immediately before and exactly at UTC month boundary | Evaluate/reset and reserve | Prior-period use applies before boundary; exact boundary opens a clean new period once without carrying or double resetting | Local time and race cannot reset quota | UTC instants, before/after totals, and reset count |
| `S0-F-CASE-076` | Rate limit with valid, missing, malformed, past, excessive, and repeated `Retry-After` classes | Schedule retry through bounded policy | Valid value is honored within cap; unsafe values use approved bound/deny; no immediate loop or clean result occurs | Provider backoff cannot amplify traffic | Retry decisions, next-attempt classes, and call counts |
| `S0-F-CASE-077` | Concurrent requests, retries, cancellation, and ambiguous completion at N-1/N boundaries | Reserve, commit/release, and reconcile units atomically | Projected totals never cross hard stop; each real attempt/effect is charged once; no lost or duplicate reservation occurs | Concurrency cannot bypass quota/cost | Reservation ledger classes, attempts, effects, and final totals |
| `S0-F-CASE-078` | Feature flag and independent provider kill switch | Engage before dispatch, in flight, and before retry | New requests/ingestion stop immediately; in-flight handling follows frozen cancel/delete policy; no retry or new support appears | Runtime control is independent of deploy | Switch propagation times, request/effect counts, and disabled state |
| `S0-F-CASE-079` | Complete private proof resource record and authorized ceiling | Reconcile attempts, quota/cost units, alerts, denial, and residual metering | Proof remains within current bounded authority; public result contains no exact amount/value; metering ends at closeout | S0-F cannot disclose or exceed private spend | Sanitized within-ceiling result, zero residual schedule, and opaque spend review |

### Freshness, expiry, no-match, and outage cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-080` | Current match one instant before normal freshness boundary | Evaluate support | Support is current, scoped, and not a clean claim | Current malicious support still expresses uncertainty correctly | Timeline and support/result code |
| `S0-F-CASE-081` | LKG exists exactly at normal freshness boundary | Evaluate under permitted LKG policy | Support becomes stale/LKG with required disclosure, not current | Half-open freshness cannot drift by one instant | Boundary timeline and disclosure result |
| `S0-F-CASE-082` | Provider unavailable after normal boundary but one instant before effective hard expiry | Evaluate LKG | LKG contributes only if explicitly allowed and disclosed; no clean claim | Outage cannot silently extend freshness | Timeline, policy right, disclosure, and support result |
| `S0-F-CASE-083` | Provider expiry earlier than policy hard expiry, evaluated just before and exactly at provider expiry | Evaluate support | Before-boundary behavior follows policy; equality excludes support and schedules recomputation | Earliest expiry always wins | Both instants, effective-expiry derivation, and recompute result |
| `S0-F-CASE-084` | Policy hard expiry earlier/equal, evaluated just before and exactly at boundary | Evaluate support | Equality excludes support and schedules recomputation; no LKG survives | Hard expiry is not a refresh suggestion | Both instants and recomputation evidence |
| `S0-F-CASE-085` | Matching provider response with no explicit expiry | Apply exact provider-approved fallback policy | Only a separately approved bounded fallback is used; absent fallback rejects support | One provider's default cannot become a global guess | Restricted policy reference, derived deadline, and result |
| `S0-F-CASE-086` | Provider rate-limited before current support exists and with current LKG variants | Evaluate retry/completeness | No-LKG case is incomplete; permitted unexpired LKG is disclosed; retry is deferred and bounded | Rate limit is not no-match or clean | Availability/support/retry matrix |
| `S0-F-CASE-087` | No-match, timeout, unavailable, rate-limit, malformed, and auth-failed results | Map to source availability and consumer completeness | Each retains a distinct bounded code; none produces clean support and only no-match is `no_source_support` | Operational failures cannot collapse into absence | Complete mapping matrix and consumer outcome |
| `S0-F-CASE-088` | Stale source plus other incomplete or unrelated evidence | Recompute source-availability summary and verdict input | Stale/unavailable support remains visible and cannot be hidden by aggregation | An aggregate cannot hide missing exact intelligence | Availability summary and input/output mapping |
| `S0-F-CASE-089` | Provider recovers after outage with pre-expiry, expired, changed, and retracted LKG states | Revalidate | Only a fresh current authorized result restores support; expired/retracted state never resurrects | Recovery requires new evidence | Revalidation attempts/results and zero resurrected support |

### Terms-change, withdrawal, deletion, and replay cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-090` | Current approved terms basis and changed content digest | Detect change and create successor | New immutable unapproved snapshot appears; new requests/ingestion/support pause and recomputation is scheduled | Terms cannot mutate in place or carry approval forward | Snapshot/state transitions and pause/recompute result |
| `S0-F-CASE-091` | Proposed, conditional, paused, blocked, retired, expired, and approved/current legal states | Evaluate access and support | Only exact approved/current state can satisfy its gate; every other state denies without clean result | Legal ambiguity is denial | State/result matrix |
| `S0-F-CASE-092` | Current broad rights and approved narrower successor | Apply rights narrowing | Newly prohibited access/output stops; effective scope narrows immediately under approved timing and affected support is located | Old permission cannot survive narrowing | Before/after rights, affected counts, and transition time |
| `S0-F-CASE-093` | Selected/proof-passed source with runtime disabled plus attempted runtime/production transitions | Apply proof completion, failure, expiry, and illegal runtime-enable mutations | Proof state changes independently; runtime remains disabled; every unauthorized production transition rejects | A passed proof is not production authority | Transition results and disabled runtime evidence |
| `S0-F-CASE-094` | Source retirement with proof-local observations, raw data, derived output, enforcement, and backups | Execute retirement workflow | Requests/ingestion stop; affected data/output is located, purged/tombstoned/recomputed as required | Retirement is an operational state change, not a note | Before/after counts, actions, and receipt |
| `S0-F-CASE-095` | Provider retraction identifying one source fact among unaffected facts | Apply retraction | Only affected source support/raw/derived/enforcement state is removed; unrelated current support remains separately evaluated | Retraction must be scoped and complete | Affected/unaffected counts and recompute result |
| `S0-F-CASE-096` | Complete source-observation and derived-output reverse index | Locate support for retirement, narrowing, and retraction variants | Every affected observation, relationship, signal, verdict, explanation, blockset/export candidate, raw object, and backup class is identified with no hidden support | Withdrawal requires traceable provenance | Coverage counts and zero unlocated affected items |
| `S0-F-CASE-097` | Raw provider objects, transient requests/responses, prohibited derived copies, replicas, and caches | Execute approved purge | Every prohibited live copy is deleted or cryptographically destroyed by deadline; allowed minimal audit/provenance remains only if licensed | Source data cannot remain by omission | Per-class before/after counts and opaque deletion receipts |
| `S0-F-CASE-098` | Proof-only snapshots, replicas, versioned objects, and backups | Purge, restore into isolation, and rescan | No prohibited source material is readable after purge/restore; shorter contractual deadline wins over general backup age | Backup is not a retention escape | Restore scan, key-destruction result, and residual count zero |
| `S0-F-CASE-099` | Enforcement candidates supported wholly/partly by withdrawn source | Apply tombstone and publication simulation | Disallowed entries are tombstoned/removed deterministically; no exact/path scope widens during removal | Withdrawal cannot leave stale protection authority | Entry before/after state and deterministic removal result |
| `S0-F-CASE-100` | Verdicts, explanations, blocksets, exports, and benchmarks with multi-source support | Recompute effective rights after one source is withdrawn/narrowed | Outputs are regenerated from surviving permitted support; a forbidden source cannot be hidden inside a union | Derived outputs inherit the most restrictive support | Before/after usage-scope digests/classes and output results |
| `S0-F-CASE-101` | Same entities with independent Hezo-owned support | Withdraw external source | Independently permitted Hezo evidence remains and is reevaluated on its own; provider-derived support disappears | Withdrawal is not indiscriminate deletion | Support provenance before/after and preservation result |
| `S0-F-CASE-102` | Completed withdrawal receipt and terminal state | Replay serially, concurrently, after retry, and after worker restart | No extra deletion, tombstone, recompute, receipt, or effect occurs; terminal counts remain identical | Withdrawal is idempotent across delivery failures | Replay attempts, effect counts, and identical final state |
| `S0-F-CASE-103` | Withdrawn/material-change state and candidate new terms/policy | Attempt automatic, flag-only, stale-reference, and owner-approved re-enable paths | Only a new current approved terms/policy/legal/proof authority can permit a later separately authorized path; S0-F still leaves runtime disabled | Recovery cannot infer renewed rights | Re-enable matrix and zero unauthorized requests/support |

### Suitability, review, and closure-preparation cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-110` | Completed evidence for candidate class and exact Stage 2 need | Compare qualified exact threat against infrastructure, context, benchmark, advisory, and `.gov` enrichment classes | At least one restricted candidate is qualified exact-threat and suitable in principle; every nonqualifying class is rejected as gate substitute | P-011/infrastructure cannot satisfy S0-F | Sanitized qualification matrix and opaque candidate ref |
| `S0-F-CASE-111` | Current effective rights/obligations for the manual-check slice | Evaluate commercial internal, request/transfer, consumer verdict/explanation, processing, retention, correction, and termination needs | Every consumed use is affirmatively permitted/current; unrelated absent rights remain false without blocking this narrow slice | Narrow suitability does not grant future outputs | Purpose/right/obligation coverage and legal concurrence |
| `S0-F-CASE-112` | Reserved match/no-match evidence plus proof-local immutable observation contract | Materialize only bounded typed provenance and replay it | Exact source/product terms/policy, category/match/scope, observed/confirmed/expiry times, fingerprint, and usage scope reproduce deterministically without production ingestion | Provider response cannot become an unversioned fact | Sanitized observation fields, revisions, replay result, and opaque raw refs |
| `S0-F-CASE-113` | Completed copy, privacy, freshness, and availability evidence | Reconcile the hypothetical manual response contract | Current support can be expressed with required notice and scope; no-match/outage/stale states remain truthful Unknown/incomplete as applicable | Suitability includes truthful failure semantics | Bounded response-category matrix and reviewer results |
| `S0-F-CASE-114` | Completed quota/cost, retry, expiry, and proof-spend evidence | Review operational viability within the owner-approved bounded proof scope | Controls are demonstrably enforceable and the proof stayed within authority; no annual budget or production cost conclusion is made | Technical proof cannot approve procurement | Sanitized viability result and opaque spend/operations refs |
| `S0-F-CASE-115` | Completed correction, kill-switch, terms-change, withdrawal, purge, and recomputation evidence | Review end-to-end source removal | Affected use can be stopped and removed deterministically within approved proof bounds; independent support remains correct | A source must be removable before it is depended on | Sanitized drill result and opaque deletion/review refs |
| `S0-F-CASE-116` | Full proof resource/runtime/dependency inventory | Search for production connector, credential, account authority, schedule, ingestion, catalog row, migration, service, feature enablement, or downstream dependency | None exists; proof access is disabled/revoked or governed only for closeout; runtime is disabled | S0-F Pass cannot create production by residue | Inventory result, runtime state, residual schedule/cost zero, and teardown dependency set |
| `S0-F-CASE-117` | Complete current regular-case evidence and pre-closeout readiness matrix | Collect separate provisional readiness checks from `Backend role`, `Intelligence role`, `Infrastructure role`, `Privacy role`, `Security role`, `Operations role`, `Legal role`, `Source rights role`, and independent-public-safety `Release role`, without marking the root review entries reviewed | All nine roles can inspect the regular-case basis, identify closeout evidence they must later review, and return `ready_for_closeout`; any `changes_required` is a case failure/Stop-path result, while a genuinely undecidable check uses the accepted executed-undecidable mapping; no final human review is claimed | Founder decision cannot replace or merge specialist checks, and a pre-closeout check cannot satisfy final review | Nine distinct pre-closeout readiness records/times/evidence refs, required closeout-review scopes, and contradiction result |
| `S0-F-CASE-118` | Sanitized regular-case evidence, limitations, external states, nine `ready_for_closeout` records, and the preaccepted closeout-branch derivation rule | Recompute the maximum truthful pre-closeout conclusion, run the leak review, and derive the applicable branch | Only a clean `appears_met` result makes the case pass and selects case 901; `appears_failed` is a case failure/Stop path selecting case 900; genuine uncertainty uses the accepted executed-undecidable mapping and selects case 900; the provisional projection contains no gate decision or reviewed root entry, and P-010/P-011 and production authority remain unchanged | A branch cannot be selected before its inputs, and a pre-closeout projection cannot become a final outcome, review, provider endorsement, or production claim | Provisional public projection, limitation set, external-state comparison, deterministic branch derivation, and leak review; final projection and all root review entries wait for closeout |

### Closeout cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-F-CASE-900` | A pre-closeout Stop/Inconclusive path, complete resource inventory, and authorized teardown | Stop calls/retries/schedules, engage kill switch, revoke proof access, delete governed request/response/store/backup state, preserve only allowed restricted audit evidence, scan public artifacts, and verify no dependency remains | Teardown is complete, accepted, current, and reviewable; no provider access, metering, runtime, raw material, or production dependency remains | A failed/undecidable proof cannot leave active access or data | Teardown timeline, per-resource disposition, zero residual schedule/access/readable prohibited data, opaque receipts, and sanitized closeout |
| `S0-F-CASE-901` | A completed regular-case path advancing to closeout, complete resource inventory, and preselected teardown or separately authorized productionization outcome | Execute the selected outcome and then verify access, data, rights, metering, runtime, dependencies, retained evidence, and public projection | Closeout is complete, accepted, current, and compatible with final review; proof runtime remains disabled and no proof artifact is silently promoted | Completed cases do not authorize indefinite proof infrastructure | Closeout decision/time, inventory dispositions, zero unauthorized residue, opaque receipts, and sanitized closeout |

Closeout applicability is determined by the path immediately before closeout, not by the final gate decision that can be recorded only after closeout:

- If any regular case has already produced a Stop/fail condition—including case 117 `changes_required` or case 118 `appears_failed`—or the regular-case path is already genuinely undecidable under the accepted mapping, `S0-F-CASE-900` is `required: true` and executes. `S0-F-CASE-901` is `required: false` and `not_applicable` under the preaccepted closeout-applicability decision.
- Only if all nine case 117 records are `ready_for_closeout`, case 118 returns clean `appears_met`, and every other regular case has produced its expected result does `S0-F-CASE-901` become `required: true` and execute. `S0-F-CASE-900` is then `required: false` and `not_applicable` under that same decision.
- A safety, rights, privacy, access, deletion, retention, evidence, or production-boundary failure first discovered while executing `S0-F-CASE-901` remains a failed `S0-F-CASE-901`; it does not retrospectively switch applicability to `S0-F-CASE-900` or erase the completed-run closeout evidence. The root outcome can become Stop only after the failed closeout is contained and closeout is completed/re-reviewed through an approved continuation or revised case plan.
- If either applicable closeout case is incomplete, blocked, stale, contradictory, or not reviewed, `closeout.state` remains truthful and `gate_decision`/`review.final_decision` remain `not_decided`. An incomplete closeout is never Pass, Stop, or Inconclusive under the exact accepted evidence schema.

Exactly one closeout case is required and executed. The unused branch has no interval/duration, uses inapplicable/all-zero contacts, and includes an Accepted, unexpired pre-run `exception_decision_ref`, `exception_decision_state`, `exception_expires_at`, and safe notes. The companion validator rejects both-required, neither-required, both-executed, path-mismatched, retrospective switching, missing/expired applicability, incomplete terminal closeout, or fabricated final-decision states.

After the applicable closeout case completes and its sanitized/private evidence is finalized, all nine roles named in case 117 must inspect the complete regular-case, closeout, limitation, external-state, and public-projection record again. Each writes one distinct root `review.entries` record dated after closeout completion; a pre-closeout readiness record cannot be reused. Only then may the `Founder role` record a matching final Pass, Stop, or Inconclusive decision. This post-closeout chronology applies to every terminal outcome.

## Gates

### Pass gate

All conditions below must be true together:

- this exact plan revision was `Approved to run` before access or execution, and every decision required by the applied O-020 boundary was current; while the conservative boundary remained applicable, O-001 through O-007 were complete rather than inferred from later deadlines;
- an Accepted proof-only repository/execution decision, truthful environments, approved proof privacy/security/retention policy, approved evidence boundary, exact fixture mappings, and the exact accepted successor evidence schema plus companion validator were in place before their first consumed case; immutable schema 2.0.0 was not silently broadened;
- the Stage 0 pre-proof O-008 state selected exactly one qualified exact-threat candidate, confirmed proof rights, and authorized bounded proof spend; the separate post-proof viability state was approved only after complete current evidence; the production O-008 state remained nonapproved and runtime remained disabled;
- P-010 and P-011 remained Proposed unless independently changed by an Accepted owner record, and neither a proposal nor P-011/infrastructure enrichment was used to satisfy the gate;
- all 97 required regular cases produced their expected result and every one of the 60 v2 subordinate vectors remained individually visible and correct, with no unexplained skip, exception, missing mutation, or favorable aggregate hiding a failure;
- the current immutable exact-product legal/source-rights basis affirmatively covered every use consumed by the Stage 2 manual-check suitability claim; every absent/unrelated right remained denied and policy/scope never exceeded terms;
- the reserved-input Class C positive and no-match controls used only authorized non-live inputs, exact approved access, bounded calls/spend, truthful environment evidence, and zero prohibited contact; all raw observations remained restricted and were deleted on schedule;
- notices, exact scope, category/match mapping, half-open earliest expiry, no-match, timeout, outage/LKG, rate-limit, quota/cost, retry, terms-change, correction, withdrawal, backup purge, recomputation, independent-support, and replay cases all matched their frozen fail-closed outcomes;
- after the selected completed-run `S0-F-CASE-901` closeout finished, `Backend role`, `Intelligence role`, `Infrastructure role`, `Privacy role`, `Security role`, `Operations role`, `Legal role`, `Source rights role`, and independent-public-safety `Release role` each inspected the complete current evidence including closeout/public projection, resolved contradictions, and recorded one distinct later reviewed entry; automation made no human decision;
- the selected completed-run `S0-F-CASE-901` closeout path completed successfully, was accepted/current, and left no unauthorized access, schedule, metering, runtime, data, dependency, or proof residue; and
- evidence schema, semantic validation, sanitization scan/review, reference resolution, chronology, freshness, external states, limitations, contact arithmetic, root/nested decision equality, and public/private boundary all passed with zero findings.

A Pass establishes only that one unnamed candidate was rights-viable and proof-passed for this bounded Stage 0 question. It does not authorize production procurement, account readiness, annual budget, connector implementation, provider runtime, Stage 2 entry, automatic enforcement, endorsement, or a public provider claim.

### Stop gate

Before execution, missing authority, terms, rights, spend, candidate, fixture, environment, runner, provider access, evidence location, or reviewer leaves this plan Draft; it is not an executed Stop or Inconclusive result.

After an authorized run begins, a Stop condition exists if any of these occurs:

- a secret, provider/account identity, terms/contract material, exact price/quota/budget, raw request/response, live or submitted URL, feed row, production datum, or restricted evidence reaches Git, a public artifact, another data plane, or any unapproved sink;
- an undeclared provider, endpoint, credential, route, dependency, input, tool, policy, fixture revision, environment, or production resource is accessed or used;
- proof rights are absent, stale, ambiguous, contradicted, narrowed, revoked, exceeded, or unsupported by the exact product basis; a public label, proposal, fixture state, or opaque reference is treated as approval;
- a healthy authorized reserved-input exercise definitively fails its frozen exact result or reveals that the candidate cannot support the narrow Stage 2 use;
- selection/legal/proof/runtime independence, default-deny rights, scope intersection, notices, expiry, no-match/outage truthfulness, quota/cost hard stop, kill switch, withdrawal, purge, backup, recomputation, replay, or production-disabled invariant fails;
- any prohibited boundary counter is nonzero; observer/calibration evidence shows an actual route, production, metadata, or cross-job contact; or a proof credential grants broader/reusable authority;
- a resource/request/spend bound is exceeded, retries amplify calls/cost, a raw retention/deletion deadline is missed, or prohibited material remains readable in a replica/snapshot/backup;
- required evidence is corrupted, fabricated, non-reproducible, unsafe to retain, inaccessible because of proof-caused handling, or published with a restricted/guessable reference; or
- a definitive completed-run closeout failure is observed in `S0-F-CASE-901`. That failure stays attached to case 901; branch applicability is not rewritten.

For a regular-case Stop, immediately stop requests, retries, schedules, metering, fixture services, and proof execution; engage the independent kill switch; cut proof egress/access through the authorized owner; revoke proof credentials; quarantine and delete only as allowed by the approved rights/incident policy; preserve the minimum restricted incident evidence; notify legal/source-rights/privacy/security roles privately; keep runtime disabled; and execute `S0-F-CASE-900`.

For a failure first discovered during `S0-F-CASE-901`, immediately contain it through the same owner-controlled process but keep case 901 as the applicable failed closeout. Until containment, deletion/revocation, evidence, and review are complete, both root decisions remain `not_decided`. After an approved continuation or revised closeout case completes, the accountable role may record Stop against the preserved failed-901 evidence. A Stop is useful kill-risk evidence and never a passed gate.

### Inconclusive outcome

An already-authorized regular-case path is Inconclusive only when a required observation is genuinely undecidable and no authorization, rights, safety, privacy, boundary, scope, spend, or evidence-integrity failure occurred. Examples are a transient provider outage that prevents the frozen reserved control; an approved observer that cannot distinguish absence from missing telemetry; a provider-controlled reserved fixture or restricted evidence record that is temporarily unavailable; or an unexpected externally controlled interface/terms publication change detected before use whose legal/technical effect cannot yet be determined.

A known missing right, ambiguous/expired terms before run, unavailable candidate/access before dispatch, definitive healthy-provider mismatch, actual material-terms use after change, unauthorized revision, public leak, exceeded limit, or proof-caused lost evidence is Stop or Draft—not Inconclusive. Offline and loopback success, a provider submission, silence, or a favorable partial call cannot be rounded up.

An Inconclusive regular-case path executes `S0-F-CASE-900`. A completed-run path whose `S0-F-CASE-901` closeout becomes undecidable remains `not_decided` while closeout is incomplete and stays on case 901; it cannot switch branches or record root Inconclusive until an approved continuation/revision completes and reviews closeout. Every final Inconclusive outcome requires complete closeout, preserved limitations, a revised/reapproved plan, clean reset, and rerun before S0-F can pass.

## Evidence plan

Public evidence uses one exact accepted dispatched evidence-schema version and its matching companion validator. The checked-in [evidence-bundle schema 2.0.0](../evidence-bundle.schema.json) remains the immutable baseline, but it cannot represent the required provider-observation evidence; Class C and every terminal S0-F bundle therefore wait for a newly versioned successor with exact cross-version dispatch. Evidence schema 1.0.0 is historical only, and neither 1.0.0 nor 2.0.0 may be relabeled or enriched in place to support this plan.

Before execution, the approved plan revision freezes for every case:

- actual fixture manifest IDs and digests from the closed alias map;
- exact revision and truthful single environment reference;
- finite expected/observed code vocabulary and executed-undecidable mapping;
- contact applicability, attempt/denial expectations, and observer calibration;
- required public and restricted evidence classes, retention, expiry, and reviewers;
- external-state and limitation dependencies; and
- closeout-path applicability and outcome precedence.

Every executed case records its own `started_at`, `ended_at`, result `recorded_at`, optional bounded `duration_ms`, exact environment/revision/fixture references, expected and observed bounded codes, evidence references, typed contact counts, deviations, retries, partial results, contradictory observations, limitations, and evidence finalization time. Every final case has at least one evidence reference. Root counters equal per-case sums; every timestamp is real RFC 3339 UTC and chronology/freshness is recomputed at final decision and later consumption.

Public evidence may contain:

- this plan, public source-policy documents, schema/validator revisions, and the exact checked-in v2 fixture identities, digests, sizes, and counts;
- generic role names, truthful environment classes/modes, safe version classes, bounded expected/observed codes, attempt/denial/effect counts, review dates, and expiry dates;
- sanitized statements that one unnamed qualified exact candidate was or was not suitable for the bounded proof question;
- non-enumerable `PRIV-` evidence references that encode no provider, product, person, account, endpoint, target, terms source, storage location, or private identifier;
- explicit limitations and the truthful nonapproved production-use state; and
- a reviewed sanitized closeout result.

Keep outside Git:

- provider/product identity when it would reveal the selected proof candidate, owner identities, negotiations, legal advice, terms URLs/text/snapshots/digests, contracts, order forms, invoices, prices, exact quotas, budgets, spend amounts, account/project IDs, credentials, secret references, endpoints, and routes;
- provider-specific reserved inputs unless redistribution is affirmatively approved, raw requests/responses, source records, feed rows, exact categories or values that disclose restricted provider behavior, and any live/submitted URL;
- network, proxy, WAF, secret-manager, service, cloud, canary, evidence-store, and deletion configuration; logs, traces, metrics, captures, screenshots, tickets, correction correspondence, incident records, and access instructions; and
- raw proof output, reviewer communication, provider evidence, deletion/revocation receipts, and any digest that confirms a low-entropy or guessable restricted value.

The public leak scanner and human review cover the plan, bundle, referenced public artifacts, branch diff, commit metadata, links, and opaque IDs. Any finding blocks a terminal decision and invokes the repository-safety response. A public-safe hash of a public artifact aids reproducibility; a hash of terms, a private provider input, account, endpoint, contract, or raw response is not sanitization.

## Limitations and unsupported claims

- The checked-in v2 package proves only a public data contract. Its fictional `selected`, `approved`, `passed`, and `production` values do not describe Hezo or a real source.
- A successful proof does not prove production rights, account readiness, procurement, annual budget, provider SLA, commercial permanence, coverage, accuracy, false-positive rate, or launch economics.
- S0-F does not select or accept P-010 or P-011. P-011/CISA `.gov` is official-domain enrichment only and cannot satisfy the qualified exact-threat gate.
- A provider no-match, timeout, outage, or absence never proves a URL safe. S0-F does not authorize `No known danger` from incomplete analysis.
- Manual-check suitability does not grant automatic blocking, client blockset, benchmark, B2B, raw redistribution, training, validation, export, API, or future-product rights.
- One provider's canonicalization, no-expiry fallback, notices, categories, quota, price, or terms cannot be generalized to another product.
- Reserved-input behavior is not production availability or real-threat coverage. No live threat, real user input, or feed content is exercised.
- Public evidence intentionally cannot reproduce private terms, cost, account, route, or response values. Authorized reviewers must inspect the restricted basis.
- Selection, legal approval, proof pass, and runtime state remain independent. A final S0-F Pass leaves production runtime disabled.
- This proof does not authorize application code, migrations, services, dependencies, cloud deployment, production source calls, Stage 1, Stage 2, or the Stage 0 exit.

## Teardown or productionization

The default outcome for Pass, Stop, and Inconclusive is **Teardown**. Use the [Stage 0 teardown checklist](../teardown-checklist.md) and the applicable 900/901 path.

Teardown must:

- stop proof calls, retries, queues, schedules, fixtures, terms monitors, metering, alerts, and provider access before altering resources;
- engage the provider kill switch and keep source runtime disabled;
- revoke proof credentials/capabilities, close or disable proof-only access through its owner-controlled process, and verify it no longer grants access;
- delete transient reserved inputs, requests, responses, raw objects, parser quarantine, caches, queues, logs, traces, metrics, captures, temporary stores, replicas, snapshots, backups, counters, and local state under the approved rights/retention policy;
- restore-scan and verify prohibited material cannot be recovered, while retaining only the minimum licensed/required restricted terms, rights, audit, proof, and legal records under an explicit owner, purpose, location, review date, and expiry;
- confirm that no connector, production account/credential, source catalog/runtime row, migration, service, schedule, feature enablement, provider dependency, downstream output, or residual metered resource exists;
- remove temporary runner/dependency/build output under the Accepted repository decision without touching the checked-in reviewed v2 public fixture package;
- scan every proposed public artifact and publish only sanitized outcome/limitations or approved opaque refs; and
- record complete per-resource disposition, deletion/revocation evidence privately, sanitized closeout publicly, and mandatory legal/source-rights/privacy/security/operations review.

**Productionize separately** is available only if a new Accepted stage-appropriate decision and plan authorize architecture, dependency, exact source/product, production procurement/contract, account, credential, cost controls, annual budget, privacy/data flow, retention/deletion/backups, observability, operations, correction, terms monitoring, incident response, migration, rollback, and runtime. It does not promote this proof or bypass Stage 0/Stage 1/Stage 2 order. Proof credentials, accounts, data, responses, raw evidence, shortcuts, and infrastructure default to teardown and may not be retained by omission.

Indefinite retention, an active proof credential, an open schedule, continuing metering, a merely submitted deletion request, or incomplete backup verification is not closeout. As specified above, an incomplete closeout keeps the bundle `not_decided`.

## Review and gate decision

The rows below are the final root review entries. They occur only after the applicable case 900 or 901 closeout completes and the complete evidence/public projection is available. Case 117's readiness records are provisional inputs and cannot satisfy these rows.

| Review | Accountable role | Required evidence | Current outcome |
|---|---|---|---|
| Technical correctness | `Backend role` | All contract, parser, provider behavior, state-machine, idempotency, and replay cases; revisions and reproducibility | Not reviewed |
| Intelligence suitability | `Intelligence role` | Qualified exact-source class, categories/match/scope, freshness, correction, and Stage 2 manual-slice fit | Not reviewed |
| Proof environment | `Infrastructure role` | Exact Class B/Class C configuration, route and observer isolation, proof identity boundaries, reset, resource inventory, and closeout | Not reviewed |
| Security boundary | `Security role` | Access/credential/network isolation, transport, untrusted input, canaries, kill switch, incident containment, and teardown | Not reviewed |
| Privacy and retention | `Privacy role` | Reserved-input data flow, sinks, field allowlist, raw retention, deletion, backups, public projection, and nonclaims | Not reviewed |
| Operations and bounded proof cost | `Operations role` | Quota/cost/retry/circuit-breaker behavior, metering stop, withdrawal, recomputation, and residual-resource checks | Not reviewed |
| Rights and external terms | Separate `Legal role` and `Source rights role` entries | Current restricted exact-product basis, complete rights/obligations, proof authority, terms change, withdrawal, and limitations | Not reviewed |
| Public safety | `Release role`, independent from implementation and every technical reviewer | Full public diff, artifacts, links, fixture rights, opaque IDs, scanner result, and unsupported-claim review | Not reviewed |
| Final gate decision | `Founder role` | Complete current schema-validated bundle, all mandatory reviews, external states, limitations, and completed accepted closeout | Not decided |

No coding agent may mark a human review complete, choose a candidate, approve a right or spend, infer a provider outcome, or record Pass, Stop, or Inconclusive. Until the complete evidence and applicable closeout are current and reviewed, the truthful state is Draft/Not authorized/Not decided.
