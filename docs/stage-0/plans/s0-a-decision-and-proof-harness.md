# Stage 0 proof plan: Decision and proof harness

This is a Draft plan under the [repository safety boundary](../repository-safety.md). It authorizes no runner, dependency, proof location, execution, evidence publication, or gate outcome.

| Field | Value |
|---|---|
| Proof ID | `S0-A-P01` |
| Work package | S0-A |
| Plan status | Draft |
| Accountable role | Founder role |
| Supporting roles | Backend, iOS, infrastructure, security, privacy, and legal/source-rights roles |
| Related kill risks | R-004, R-005, R-007, R-011, and R-014 from [document 12](../../12-risks-decisions-and-open-questions.md) |
| Linked decisions | O-020 is Open; O-001 remains Open for production scope; [ADR 0001](../../adr/0001-stage-0-gate-timing.md) is Proposed; the proof-scoped repository/execution and language/dependency decisions are not yet filed or Accepted |
| Proof location | Not authorized |
| Fixture manifests | Evidence schema 2.0.0, with archived 1.0.0 rejection coverage; `s0-b-url-filter-synthetic-1000-v1`; `mpd-v1-month-token-vectors-1-manifest`; `s0-f-public-synthetic-provider-policy-vectors-2-manifest` |
| Environment class | Planned local/offline and isolated proof-CI execution; neither is authorized |
| Evidence-bundle reference | Not authorized |
| Review point | After every prerequisite is Accepted and before any run; again before any evidence is consumed by a gate |

## Kill-risk question

Can independent Stage 0 proofs be planned, reviewed, and closed without implicitly selecting production architecture or exposing restricted material, and can the future companion validator deterministically reject unsafe or misleading evidence and validate every currently checked-in public fixture offline in both local and proof-CI environments?

The answer is negative if any required choice is made without accountable approval, any restricted value crosses the public boundary, an unsafe or misleading evidence mutation is accepted, a current fixture cannot be reproduced from its declared contract, or validation needs undeclared network access. In that event, runnable S0-B through S0-F work and Stage 1 foundations remain paused until the harness is redesigned and this proof is rerun.

## Scope

### In scope

- Apply the existing proof-plan, evidence-bundle, fixture, repository-safety, and teardown contracts to one bounded S0-A proof.
- Require explicit authority before choosing a proof root, language, package manager, dependency, runner, or network-isolation mechanism.
- Define deterministic structural, semantic, reference, chronology, gate-derivation, contact-count, leak, digest, fixture, and offline-execution cases for the future companion validator in both approved local and proof-CI environments.
- Validate the checked-in evidence schema, URL Filter 1,000-entry fixture, MPD v1 vectors, and S0-F v2 source-rights vectors without using a live service.
- Require public evidence to contain only sanitized metadata or approved opaque references and to identify exact revisions, fixture manifests, tools, environments, limitations, reviews, and closeout state.
- Exercise both accepted and rejected synthetic evidence shapes without committing filled proof evidence or restricted values.
- Require teardown or a separately Accepted productionization decision after every run, including stopped and inconclusive runs.

### Out of scope

- Selecting the validator language, package manager, schema library, local runner, proof-CI mechanism, operating-system boundary, or dependency before the required ADRs are Accepted.
- Product or release CI, reusable deployment workflows, product scaffolding, production architecture, or deployment resources. This document-only batch adds no runnable validator, dependency manifest, or workflow; the later approved proof must implement only its disposable local and proof-CI harness.
- Running Apple URL Filter, App Attest, sandbox, privacy, source-provider, physical-device, network, or external-approval proofs.
- Validating live URLs, feeds, provider responses, real attestations, device/cloud records, contracts, credentials, private owner records, or raw proof output.
- Approving O-001, O-020, any ADR, a privacy/rights outcome, a fixture's operational use, or a Stage 0 gate.
- Treating schema validity, fixture presence, a static scan, or this plan as evidence that execution is isolated or that any proof passed.

### Assumptions and unknowns

- The committed schemas and manifests are intended as normative public contracts. A compile failure, unresolved local reference, or contradiction between a manifest and its bytes falsifies this assumption.
- The four current public fixture families can be validated with local bytes only. A required network lookup, current-clock dependency, machine-specific path, or undeclared external schema falsifies this assumption.
- A future validator can derive gate usability rather than trusting a claimed result. Acceptance of a pass with a failed required case, stale approval, gate-blocking limitation, incomplete review, or incomplete closeout falsifies this assumption.
- Public-safety scanning can cover every string and referenced public artifact. An unscanned field, path escape, symlink escape, opaque identifier that encodes restricted data, or accepted restricted test value falsifies this assumption.
- Deterministic output can be reproduced from an exact revision and declared tool environment. A repeated run over identical bytes that produces a different normalized result falsifies this assumption.
- The exact local runner, proof-CI mechanism, resource bounds, independent implementations, and isolation controls remain unknown until the repository/execution and language/dependency decisions are Accepted. Their absence keeps this plan in Draft and prevents execution.

## Decisions and prerequisites

| Decision, ADR, approval, or access | Required state before execution | Current public-safe state | Stop action if absent |
|---|---|---|---|
| Repository and isolated-execution ADR under the [ADR policy](../../adr/README.md) | Accepted; names the exact proof root, execution boundary, no-egress control, allowed file access, reset, output handling, ownership, and teardown | No record is filed or Accepted | Keep proof location `Not authorized`; do not add or run a harness |
| Proof implementation language and dependency policy | Accepted ADR names the validator language, package manager, exact dependencies, purpose, license, update policy, unavailable behavior, and rollback; it states whether the choice is proof-only or also resolves any O-001 production scope | No proof-scoped record is filed or Accepted; O-001 remains Open for production | Do not choose a language, library, package manager, or dependency; require full O-001 resolution too if the accepted O-020 outcome keeps it as a Stage 0 prerequisite |
| O-020 Stage 0 decision-timing reconciliation | Owner-approved outcome recorded and affected gate documents updated consistently | Open; [ADR 0001](../../adr/0001-stage-0-gate-timing.md) is Proposed and grants no authority | Do not interpret later table deadlines as authority or consume an S0-A result at the Stage 0 gate |
| Accountable plan authorization | Plan moved from Draft to Approved to run by the accountable human role after all prerequisites and reviews | Not approved | Do not execute |
| Technical correctness review | Backend or other authorized implementation role reviews case completeness, schema dialect, deterministic semantics, and reproducibility | Not reviewed | Return the plan for changes |
| Security-boundary review | Security and infrastructure roles review no-egress enforcement, file/path isolation, leak mutations, resource bounds, containment, and teardown | Not reviewed | Do not execute |
| Privacy and retention review | Privacy role reviews prohibited-value coverage, public/private handling, evidence retention, expiry, deletion, and backup implications | Not reviewed | Do not execute or publish evidence |
| Rights and dependency review | Legal/source-rights role reviews fixture redistribution basis and every proposed dependency license | Not reviewed | Do not execute with the fixture or dependency in question |
| Current revision freeze | Exact repository revision plus schema, fixture, and manifest digests recorded before the run | Not frozen for a run | Do not execute against moving or unexplained bytes |

An owner discussion, a Draft or Proposed ADR, installed local tooling, or a successful manual command is not an Accepted prerequisite.

## Fixtures

| Fixture ID and version | Manifest or source | Purpose | Safety classification | Cleanup or retention |
|---|---|---|---|---|
| Stage 0 evidence-bundle schema 2.0.0 | [Current public evidence schema](../evidence-bundle.schema.json) and [archived schema 1.0.0](../evidence-bundle-1.0.0.schema.json) | Compile the current contract, reject cross-version inputs, and generate bounded positive and negative in-memory evidence shapes | Public sanitized schemas; no filled evidence | Retain the reviewed schemas; delete temporary test bundles and mutation output |
| `s0-b-url-filter-synthetic-1000-v1` | [Manifest](../../../fixtures/stage-0/url-filter/synthetic-1000.manifest.json) and [manifest schema](../../../fixtures/stage-0/manifest.schema.json) | Verify exact bytes, SHA-256, count, uniqueness, ordering, grammar, and reserved-only records | Project-generated public synthetic `.test` keys; offline only | Retain the reviewed public fixture; delete temporary mutations |
| `mpd-v1-month-token-vectors-1-manifest` | [Manifest](../../../fixtures/stage-0/mpd/month-token-vectors.manifest.json), [payload schema](../../../fixtures/stage-0/mpd/month-token-vectors.schema.json), and [manifest schema](../../../fixtures/stage-0/mpd/manifest.schema.json) | Recompute deterministic MPD known answers and validate malformed, month-boundary, request, and withdrawal cases | Project-generated public synthetic test values; historical and operationally forbidden | Retain the reviewed public fixture; delete temporary mutations and computed output |
| `s0-f-public-synthetic-provider-policy-vectors-2-manifest` | [Manifest](../../../fixtures/stage-0/source-rights/provider-policy-vectors.manifest.json), [registry schema](../../../fixtures/stage-0/source-rights/source-rights-registry.schema.json), [vector schema](../../../fixtures/stage-0/source-rights/provider-policy-vectors.schema.json), and [manifest schema](../../../fixtures/stage-0/source-rights/manifest.schema.json) | Validate strict structure, references, case counts, temporal boundaries, rights intersections, source isolation, resource gates, and withdrawal/replay expectations | Project-generated public synthetic `.invalid` identities, historical instants, and fictional XTS thresholds; operationally forbidden | Retain the reviewed public fixture; delete temporary mutations and computed output |

All inputs remain governed by the [Stage 0 fixture policy](../../../fixtures/stage-0/README.md). The future validator must copy any negative mutation into approved temporary storage; it must never modify a tracked fixture merely to demonstrate rejection.

## Environment and isolation

No proof environment is currently authorized. The intended classes are a fresh, bounded local/offline environment and a disposable proof-CI environment created under the future Accepted repository/execution ADR. Neither may be product CI or a reusable release foundation.

Before a run, the approved design must establish and record:

- an exact repository revision and read-only access to only the declared public plans, schemas, fixtures, and manifests;
- a fresh temporary output location outside tracked paths, with no access to `.private/`, user documents, credentials, signing material, device records, cloud configuration, production routes, or secret-bearing environment variables;
- technical denial of all network access, including dependency resolution, remote schema retrieval, DNS, loopback services, and fallback resolvers during proof execution;
- a local registry for every schema identifier and reference so draft 2020-12 compilation never retrieves a remote resource;
- deterministic locale, time-zone, clock/reference-time, Unicode, path, and JSON-decoding rules declared by the implementation decision;
- reviewed wall-time, memory, file-count, input-size, output-size, and process limits, plus a bounded failure for each exceeded limit;
- observation capable of distinguishing zero network attempts from blocked attempts and of recording zero endpoint-free boundary-canary contacts without committing an endpoint; and
- a reset that removes temporary mutations and outputs, clears process state, and starts the next run from the same immutable revision.

Material runtime, schema-library, standard-library, cryptographic implementation, operating-system, architecture, policy, and scanner versions must be recorded in sanitized evidence. Dependency acquisition and environment construction happen only through the separately approved process; the validator run itself remains offline. A static URL scan or a policy sentence is not evidence that the boundary worked.

## Expected cases

Every case below is required. Results remain `not_run` until an authorized environment executes them.

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-A-CASE-001` | Exact current and archived evidence schemas plus all three type-specific fixture manifest schemas registered locally | Compile every schema in strict draft 2020-12 mode without remote resolution | All schemas compile from declared local bytes; zero network attempt and zero unresolved schema reference | Schema compilation cannot create an undeclared data or network flow | Schema/tool revisions, local registry digest, result code, and defined contact counters |
| `S0-A-CASE-002` | Minimal in-memory 2.0.0 S0-A bundle with root and review decisions `not_decided`, every case `not_run`, no run interval, pending closeout, and all other required safe fields | Validate the control, then add an executed case without a run interval or a nested final review decision while the root remains `not_decided` | The control is accepted structurally without implying execution, review, closeout, or pass; both mutations are rejected | A pre-run record cannot fabricate execution or conceal a favorable gate outcome in nested review state | Input digest, schema digest, bounded validation result |
| `S0-A-CASE-003` | Separate in-memory mutations for an unknown root field, unknown nested field, wrong type, over-bound value, malformed ID, terminal CR/LF in every constrained string family, and false privacy declaration, plus raw serialized JSON bytes containing duplicate keys | Parse and validate each mutation in every approved validator | Every mutation is rejected with the same bounded non-sensitive category across validators; duplicate keys fail before object construction | Strict parsing and schemas expose no generic metadata, suffix-byte, or payload escape hatch | Mutation IDs, validator revisions, expected/observed rejection codes, and cross-validator comparison; no rejected value copied into evidence |
| `S0-A-CASE-004` | Final-decision bundle mutations missing run interval, case/evidence timestamps, case evidence, semantic validation, sanitization review, human review, decision timestamp/references, or complete timestamped closeout | Validate and derive usability | Every final-decision mutation is rejected or marked unusable; none is treated as pass | Structural success alone cannot promote evidence | Mutation matrix and derived gate-usability codes |
| `S0-A-CASE-005` | Valid-shaped 1.0.0 and 2.0.0 controls plus version/field mutations in both directions | Dispatch each input only to its exact schema version and evaluate gate usability | Each control validates only against its own version; cross-version inputs fail, and 1.0.0 is unusable for a new final gate without rerun and review under 2.0.0 | Historical metadata is never upgraded by invented timestamps or contact allocation | Schema digests, cross-version matrix, and gate-usability result |
| `S0-A-CASE-010` | Synthetic bundles for S0-A through S0-F with one proof-ID, work-package, and case-prefix mismatch at a time | Run semantic identity checks | Every mismatch is rejected; the fully aligned control is accepted for further validation only | Evidence cannot be reassigned across work packages | Case matrix and identity-resolution result |
| `S0-A-CASE-011` | Synthetic duplicate IDs plus missing, duplicate, wrong-type, and cross-object references | Resolve revisions, fixtures, environments, evidence, limitations, decisions, reviews, and closeout references | All invalid graphs are rejected; the complete acyclic control resolves exactly once per reference | An unresolved or ambiguous reference cannot support a claim | Reference graph digest and bounded resolution report |
| `S0-A-CASE-012` | Bundle with an omitted required case and another with a result but no evidence reference | Compare declared plan coverage with evidence cases | Missing coverage and missing final-result evidence are rejected | Required failures and omissions remain visible | Plan/case-set digests and missing-case codes |
| `S0-A-CASE-013` | Valid-shaped final records representing pass, stop, inconclusive, and not decided | Derive the only permitted decision from cases, external states, limitations, validation, review, and closeout | Derived result matches the complete inputs; a claimed result that differs is rejected | The validator derives gate usability rather than trusting a label | Decision truth table and derived-result digest |
| `S0-A-CASE-014` | Required and optional synthetic cases marked failed, skipped, not run, or not applicable, with missing, Proposed, expired, unrelated, and Accepted in-scope exception decisions | Evaluate exception policy | Only an optional `required: false` case with an Accepted, unexpired, explicitly in-scope exception may remain eligible; no required non-pass case can support an S0-A pass | Skips cannot silently become success | Exception matrix with required flag, decision state, expiry, scope, and derived result |
| `S0-A-CASE-015` | Pass mutations containing a gate-blocking limitation, stale required external state, incomplete review, or incomplete teardown | Derive gate usability | Every mutation is unusable for pass | Limitations, external control, review, and closeout remain hard gates | Gate-factor matrix and rejection codes |
| `S0-A-CASE-020` | RFC 3339-shaped valid controls and impossible dates, offsets, leap-day errors, and non-UTC timestamps | Parse timestamps as real UTC instants | Valid UTC instants parse; impossible or non-UTC inputs are rejected | Regex shape cannot substitute for calendar validation | Parser version and timestamp-case results |
| `S0-A-CASE-021` | Run start/end, executed-case start/end/result, cited-result finalization, semantic/sanitization review, reviewer, closeout-completion, final-decision, bundle-recording, expiry, and review-due instants in valid and contradictory orders | Check chronology, distinguishing prerequisite artifacts that may predate the run from result evidence that may not | Every impossible or reversed applicable lifecycle is rejected; the ordered control proceeds | Result evidence cannot predate its run or outlive its approved lifecycle silently | Chronology matrix and result codes |
| `S0-A-CASE-022` | Evidence consumed immediately before, exactly at, and after bundle review, evidence, optional-case exception, and external-state `review_due_at` deadlines | Apply half-open freshness at gate-consumption time | Before-deadline control is eligible; equality and later are stale and unusable | Expired evidence or external state never remains valid by cached prior review | Fixed reference time and freshness-boundary results |
| `S0-A-CASE-030` | In-memory mutations containing synthetic secret, contact, private/local path, live-target, account, device, application identifier, raw URL/submission, attestation, receipt, token, and restricted-source patterns | Scan every string field before schema/gate acceptance | Every mutation is rejected with a category-only finding; finding output contains none of the matched value | The scanner cannot preserve or echo restricted material | Mutation IDs, finding categories, zero-value-echo assertion |
| `S0-A-CASE-031` | Declared public artifacts plus traversal, dotfile, symlink-escape, private-root, absolute-path, and undeclared-file mutations | Resolve and scan referenced files under the approved public roots | Only declared in-root regular files are read; every escape or undeclared file is rejected before content access | A reference cannot widen file-system authority | Canonical public-root digest, path-case outcomes, accessed-file allowlist |
| `S0-A-CASE-032` | Opaque evidence IDs that are random controls or encode a person, provider, location, target, account, device, or enumerable restricted identifier | Apply opaque-ID policy | Encoded identifiers are rejected; non-enumerable controls proceed | An opaque label is not a covert public index into restricted state | Identifier mutation classes and results |
| `S0-A-CASE-040` | Current schemas, manifests, payloads, and fixture files plus one missing and one wrong-type reference mutation per family | Resolve the complete public fixture graph | Current controls resolve locally; all missing or type-confused references fail closed | The validator never guesses a schema or substitutes a similarly named fixture | Resolution graph and exact referenced digests |
| `S0-A-CASE-041` | Synthetic S0-D case evidence and bundle counters for `test_attempts`, `egress_denials`, TCP connections, UDP datagrams, application requests, metadata contacts, production-resource contacts, and cross-job contacts, with one mismatch, one nonzero prohibited counter, or one positive counter assigned to a non-executed case at a time | Check non-executed cases, recompute every bundle-wide counter from the referenced case evidence, and derive pass eligibility | The internally consistent zero-contact control may proceed; non-executed cases must be inapplicable with zero counters, and every mismatch or nonzero prohibited contact rejects pass | A boundary contact or test attempt cannot be hidden by an omitted, non-executed, or inconsistent category | Referenced case-count report, recomputed schema-field counters, outcome/contact coherence, and gate result |
| `S0-A-CASE-042` | Synthetic final bundle with semantic validation omitted, failed, stale, or recorded from a different validator revision | Check validator self-identification and freshness | Only the exact successful current validator revision may support final review; no case alone establishes pass | Unvalidated evidence cannot validate itself | Validator revision/digest and validation-state matrix |
| `S0-A-CASE-050` | Exact current public fixture and schema bytes | Recompute byte lengths and SHA-256 values declared by every manifest | Every declared value matches the checked-in bytes exactly | A manifest assertion is verified, not trusted | File allowlist, byte counts, computed and declared digests |
| `S0-A-CASE-051` | Temporary copies with one byte changed, one final LF removed, one declared count changed, and one digest changed | Re-run manifest verification | Every mutation fails with the specific integrity category | An unexplained byte change cannot be normalized into success | Mutation IDs, integrity categories, cleanup result |
| `S0-A-CASE-052` | URL Filter 1,000-entry seed and manifest | Validate UTF-8/LF/final newline, exact count 1,000, uniqueness, bytewise order, no blank record, reserved `.test` naming, no scheme, and record value `1` | Every invariant passes for the exact fixture; isolated mutations fail | No real URL or widened key grammar enters the seed | Fixture digest, recomputed counts, grammar-check summary |
| `S0-A-CASE-053` | MPD v1 manifest, schema, and payload | Validate exact case counts and references; recompute HKDF/HMAC intermediates, base64url form, UTC boundaries, malformed inputs, request-month rules, and withdrawal invariants using the approved independent implementations | All expected values and results match; mutation controls fail | Public protocol-shaped values remain synthetic, historical, and operationally forbidden | Implementation revisions, recomputed-value digest, case summary |
| `S0-A-CASE-054` | S0-F v2 manifest, schemas, registry, and vector payload | Validate counts, unique/source-local references, real UTC chronology, half-open expiry, rights intersections, notices, freshness, quota/cost boundaries, outage handling, and withdrawal/replay expectations | All declared cases match; cross-source, boundary, and mutation controls fail closed | Fictional approved states cannot authorize a real source or production use | Semantic result digest, case/category counts, isolation summary |
| `S0-A-CASE-060` | Exact inputs and a local schema registry in the technically no-egress environment | Run the complete validation set with remote schema retrieval, DNS, sockets, and loopback unavailable | Complete validation succeeds from local bytes with zero network attempts and zero canary contacts | Offline means no attempted dependency, schema, or fixture retrieval | Boundary configuration reference, attempt/contact counts, complete result digest |
| `S0-A-CASE-061` | Identical immutable inputs executed repeatedly under every approved locale/time-zone variation and clean process state | Compare normalized public-safe outputs | Outputs are bit-identical after excluding no fields; differences fail the proof | Current clock, locale, path, and residual state cannot alter evidence | Environment matrix and output digests |
| `S0-A-CASE-062` | Deliberate undeclared remote schema reference and unavailable local dependency in temporary mutations | Execute with network denied | Validator fails closed with a bounded local error and makes no network attempt | Missing dependencies never trigger fallback egress | Mutation IDs, error codes, zero-attempt evidence |
| `S0-A-CASE-063` | Exact frozen inputs and approved immutable dependencies in the disposable proof-CI environment | Execute the complete suite with dependencies resolved only from approved local bytes and every undeclared route technically disabled | Results match the approved local control; zero network attempt, zero prohibited contact, and no live-threat access are recorded | CI cannot contact a live threat or silently fetch a schema, tool, or fixture | Proof-CI environment/policy revisions, local-to-CI result digests, attempt/contact counts, and teardown result |
| `S0-A-CASE-070` | Completed, stopped, and inconclusive synthetic run closeouts | Apply the teardown checklist to temporary files, process state, dependencies, outputs, and restricted references | Each run reaches one explicit closeout; temporary state is removed and no product dependency remains | Failed and inconclusive proofs do not leave an unmanaged harness | Closeout result, retained-public-file allowlist, zero residual-item count or reviewed exception |

No required case may disappear after a failure. A newly discovered edge case is added with a new stable ID, while the original result remains in evidence.

## Gates

### Pass gate

All of the following must be true together before the accountable role may decide Pass:

- the repository/execution and proof language/dependency ADRs are Accepted, O-020 has an owner-approved recorded outcome reflected in the gate documents, every decision that outcome makes a Stage 0 prerequisite is complete, every prerequisite review is complete, and the evidence proves the plan was Approved to run before execution and later advanced through the required lifecycle states;
- the exact repository revision, validator revision, dependencies, tool environment, fixture manifests, schemas, and payload digests are recorded;
- every required case above passes with its expected result and no unexplained skip, unrun case, contradiction, stale exception, or evidence gap;
- structural validation, semantic validation, chronology, reference resolution, leak scanning, gate derivation, and teardown checks agree;
- every current fixture validates from local bytes, all declared sizes/counts/digests recompute, and all negative mutations fail for the expected reason;
- the complete local and proof-CI runs make zero network attempt, record zero prohibited contact, read no undeclared or restricted file, and produce identical normalized results across the approved repeatability matrix;
- no secret, contact detail, private path, live target, raw submission, account/device/application identifier, attestation material, restricted source data, or other prohibited value appears in public output;
- a schema-valid evidence bundle identifies the validator and leak-scan revisions, records zero findings, remains current at review time, and references only sanitized public files or approved opaque IDs;
- technical, security, privacy/retention, and rights/dependency reviewers can inspect the authorized evidence and record Reviewed; and
- teardown is complete or a separate productionization plan and governing ADRs are Accepted, with all proof-only state still closed safely.

Passing this proof establishes only that the reviewed harness can enforce the bounded governance and current-fixture contracts. It does not pass S0-B through S0-F or the Stage 0 exit gate.

### Stop gate

Stop immediately if execution begins without an Accepted prerequisite; the validator attempts undeclared network access; any canary records contact; any file access escapes the declared public roots; a secret, identifier, raw value, or restricted record enters an unapproved sink; a fixture digest or reference cannot be explained; a negative mutation is accepted; a favorable gate result can be claimed without its required cases, review, external state, limitation handling, or closeout; a resource bound is exceeded without bounded failure; or the environment differs materially from the approved plan.

Containment is to terminate the run, deny further access, preserve only the minimum sanitized failure metadata permitted by the approved retention policy, delete temporary mutations and output, and have security/privacy roles review any possible boundary event. Runnable S0-B through S0-F work and Stage 1 foundations remain paused until the cause is corrected, a regression case is added, and S0-A is replanned and rerun. A Stop outcome is useful evidence but never a passed gate.

### Inconclusive outcome

The result is Inconclusive if an already-authorized run cannot determine a case because the approved validator dependency is unavailable, the immutable revision or fixture becomes inaccessible, the isolation observer cannot distinguish zero attempts from blocked attempts, an independent recomputation cannot be completed, evidence needed by an authorized reviewer is unavailable, or a concurrent repository change invalidates the frozen input set without demonstrating a contract failure.

Before authorization, a missing prerequisite leaves the plan Draft; it is not an Inconclusive run. After an inconclusive run, close it safely, revise the plan or environment, freeze a new revision, and rerun every affected case. Do not infer Pass from partial results.

## Evidence plan

The public metadata contract is the [evidence-bundle schema](../evidence-bundle.schema.json), but the evidence-bundle reference remains `Not authorized` until an Accepted repository/execution ADR names its public-safe location.

For every executed case, schema 2.0.0 records exact input and expected-result identifiers, `started_at`, `ended_at`, result `recorded_at`, optional `duration_ms`, revision and digest references, fixture references, environment, bounded expected/observed codes, per-case `contact_counts`, notes where safely representable, and timestamped sanitized or opaque evidence references. Detailed retries or deviations that do not fit the closed public schema remain in authorized underlying evidence and are surfaced through bounded notes, limitations, and evidence references rather than undeclared fields. Aggregate evidence must also include:

- the frozen plan, repository, validator, scanner, local-schema-registry, and dependency revisions or digests;
- a complete case-result set, including failures, skips, mutations, contradictory observations, and newly discovered cases, plus root contact counters proven equal to the per-case sums;
- recomputed public file sizes, counts, digests, reference graph, fixture semantic summary, and deterministic output digest;
- freshness evaluation at review time and any evidence expiry or review deadline;
- public-safety scan categories and zero finding count without retaining matched prohibited values;
- generic roles authorized to inspect restricted underlying evidence, where applicable; and
- teardown or separate productionization state.

Machine-readable raw output, process traces, local paths, security-boundary configuration, and any restricted evidence remain in approved private storage under the later retention decision. The public bundle may contain only bounded sanitized metadata or a non-enumerable approved opaque reference. A failed scan must not publish the value that caused it.

## Limitations and unsupported claims

- This Draft contains no validator, local runner, proof-CI workflow, dependency, executed case, evidence bundle, review approval, or gate result.
- The existing schemas and manifests contain declared validation states, but this plan does not independently substantiate those declarations.
- JSON Schema 2.0.0 represents the run interval, executed-case interval/result time, evidence finalization, external-state review deadline, per-case contacts, decision time, and closeout completion, but cannot by itself establish real chronology, reference integrity, contact arithmetic, digest correctness, semantic case coverage, zero network access, leak freedom, or gate eligibility; those require the future companion validator and reviewed execution boundary.
- Archived schema 1.0.0 lacks the lifecycle and per-case contact fields required by this plan. No timestamp or contact allocation may be inferred to upgrade an old record; affected evidence must be rerun and re-reviewed under 2.0.0.
- A bounded negative-pattern set cannot prove that every future restricted format will be recognized. Newly discovered leak classes require a regression and re-review.
- Offline fixture validation does not prove physical-device behavior, sandbox isolation, production privacy, source rights, provider access, external approval, performance, or availability.
- One implementation may reproduce its own mistake. Independent implementations and their accepted dependency/licensing basis must be selected before the relevant known-answer claim is accepted.
- Cross-architecture determinism is unsupported unless the Accepted environment matrix actually includes and passes more than one architecture.
- Any change to the evidence schema, proof-plan contract, fixture schema, payload, manifest, semantic rule, validator, scanner, or environment invalidates the affected evidence until it is rerun or reviewed against the new digest.
- O-020 remains Open, O-001 remains Open for production scope, the proof location and evidence location remain unauthorized, and Stage 0 remains open under the current conservative rule.
- No security, privacy, legal, product, marketing, production-readiness, or release claim may cite this Draft plan as evidence.

## Teardown or productionization

Every authorized run must use the [teardown checklist](../teardown-checklist.md) and choose exactly one reviewed closeout.

The default for a stopped or inconclusive run is Teardown: terminate processes, remove temporary mutations and computed output, clear caches and residual state, revoke any proof-only access, delete restricted raw output under its approved retention rule, and verify that no later proof or product path depends on the harness. The reviewed public plan, schemas, and synthetic fixtures may remain because they are governed repository assets, not temporary run output.

Productionize separately is permitted only after Accepted ADRs authorize the supported implementation, dependencies, ownership, operations, failure behavior, retention, and rollback. Proof code, proof-only privilege, temporary isolation, debug controls, and proof output do not become production assets automatically. Indefinite retention or an open process after the run is not a valid closeout.

At Draft stage no process, credential, endpoint, temporary resource, dependency, or raw output has been authorized or created by this plan, so there is currently nothing to tear down.

## Review and gate decision

| Review | Accountable role | Required evidence | Outcome |
|---|---|---|---|
| Technical correctness | Backend or authorized implementation role | Cases, schema/reference behavior, fixture recomputation, versioning, and reproducibility | Not reviewed |
| Security boundaries | Security and infrastructure roles | No-egress enforcement, file isolation, negative cases, canary/contact counts, containment, and teardown | Not reviewed |
| Privacy and retention | Privacy role | Prohibited-value coverage, public/private sinks, evidence expiry, deletion, and restricted retention | Not reviewed |
| Rights and external terms | Legal/source-rights role | Fixture redistribution basis and dependency licenses; no provider approval inferred | Not reviewed |
| Final gate decision | Founder role | Complete current evidence bundle, all reviews, and closeout | Not decided |

No reviewer is named privately here. Only the accountable human roles may change these outcomes, approve execution, or decide Pass, Stop, or Inconclusive.
