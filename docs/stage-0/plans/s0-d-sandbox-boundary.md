# S0-D sandbox boundary proof plan

This is a Draft plan under the [repository safety boundary](../repository-safety.md). It authorizes no proof root, runner, dependency, cloud resource, network, resolver, proxy, certificate authority, browser, image, fixture package, canary, route, credential, evidence location, execution, external request, productionization, approval, or gate outcome.

| Field | Value |
|---|---|
| Proof ID | `S0-D-P01` |
| Work package | S0-D |
| Plan status | Draft |
| Accountable role | Joint security and infrastructure roles; one must be designated as the evidence schema's single final-decision role before approval, with recorded concurrence from the other |
| Supporting roles | Privacy/retention, dependency/licensing, technical-correctness, public-safety, and incident-response roles |
| Related kill risks | [R-005, R-006, and R-014](../../12-risks-decisions-and-open-questions.md#external-dependencies-and-kill-risks) |
| Linked decisions | [D-012 and D-013](../../12-risks-decisions-and-open-questions.md#accepted-product-decisions) are Accepted; [P-006, P-007, and P-008](../../12-risks-decisions-and-open-questions.md#proposed-technical-decisions) remain Proposed; [O-001, O-002, O-003, O-006, O-007, O-015, O-016, and O-020](../../12-risks-decisions-and-open-questions.md#open-decisions) are Open; [ADR 0001](../../adr/0001-stage-0-gate-timing.md) is Proposed only |
| Proof location | Not authorized |
| Fixture manifests | Not authorized; no S0-D fixture manifest exists |
| Environment class | Planned `local_offline` with `offline`, and `isolated_security_staging` with `isolated_fixture_network`; neither authorized |
| Evidence-bundle reference | Not authorized |
| Review point | Before any fixture, runner, dependency, image, route, identity, certificate, service, canary, or evidence store is created; after any material policy, registry, browser, guest, VMM, dependency, or topology change |

## Kill-risk question

Can Hezo run one synthetic hostile-content analysis in a fresh disposable, separate-kernel boundary so that every URL, DNS, redirect, browser, protocol, resource-exhaustion, guest-compromise, result-channel, and artifact attempt remains bounded, while the guest has no secret, production route, direct resolver or Internet path, cross-job access, or prohibited boundary-canary contact?

The answer is negative if an approved, reproducible positive control cannot traverse the validating gateway; a prohibited probe produces any TCP, UDP, application, metadata, production-resource, or cross-job contact; the guest bypasses the resolver, inspecting gateway, firewall, resource limit, or schema-bound output path; an isolation, state-reuse, credential, quarantine, or trusted-ingestion boundary fails; or the selected production-candidate isolation and patch policy cannot satisfy the frozen matrix.

A negative answer pauses dynamic hostile-content analysis and every product claim that depends on it. Other independently authorized bounded Stage 0 proofs may continue only within their own accepted plans; Stage 1 product implementation and the complete Stage 0 exit remain blocked absent the required Pass outcomes or an Accepted rescope. The result cannot be compensated for by relaxing destination policy, allowing opaque tunnels, treating incomplete analysis as `no_known_danger`, reusing a hostile worker, or promoting proof infrastructure as production.

## Scope

### In scope

- A minimal disposable runner and proof-only control plane sufficient to exercise the boundary, not a crawler product.
- One accepted, isolated-security topology with no production peering, route, credential, data, or live-threat access.
- One controlled resolver, validating inspecting egress gateway, independent firewall, schema-bound job/control channel, artifact return channel, and independently observed boundary canaries.
- The complete URL, host, port, IP, DNS, connection, redirect, client-navigation, subresource, method, header, cookie, TLS, and bypass matrix from [document 08](../../08-sandbox-and-security.md) and [document 10](../../10-testing-and-benchmarks.md).
- One fresh separate-kernel disposable worker per job; guest, host, cross-job, browser-state, resource, crash, retry, and destruction controls.
- Opaque task and signed result-envelope behavior, quarantine entry, strict schema/provenance promotion stub, and proof that the runner cannot write graph, verdict, or blockset state.
- Signed immutable images, SBOM/provenance, vulnerability admission, patch ownership, rollback, kill switch, and suspected-escape containment.
- Synthetic privacy/log canaries, transient deletion, evidence sanitation, and explicit teardown or separately authorized productionization closeout.

### Out of scope

- A production crawler, production broker, product API, database, queue, object store, KMS, observability stack, consumer UI, verdict engine, Trust Graph ingestion, or blockset publisher.
- Selecting a cloud, region, VMM or managed isolation product, resolver, proxy, firewall, CA implementation, browser build, parser, scanner, language, framework, package manager, CI runner, or evidence system.
- Live malicious URLs, live threat feeds, captured submissions, real metadata services, third-party targets, production services, analyst workstations, or uncontrolled public Internet access.
- Proving that a browser, guest kernel, VMM, hypervisor, or hardware boundary has no unknown vulnerability.
- Production availability, scale, cost, latency, accuracy, crawler completeness, release readiness, penetration testing, or Stage 0 exit.
- Retaining hostile artifacts beyond the current conservative proof policy, exercising an incident hold, or resolving O-007/O-016 by implication.
- Executing captured HTML, documents, downloads, archives, or exploit samples; all proof inputs remain deterministic, synthetic, bounded, and governed.

### Assumptions and unknowns

- A production-representative isolation technology can satisfy the boundary. A reproducible escape, prohibited contact, secret/route exposure, or failure to destroy hostile state falsifies this assumption.
- A permitted positive HTTP/HTTPS fixture can be reached only through the same validating path without granting the guest a broad Internet route or adding a production classifier exception. No topology currently proves this; an accepted proof-only design is required.
- Independent canary observers can distinguish observed zero contact from absent telemetry. A failed or ambiguous observer makes the affected authorized run Inconclusive, never Pass.
- The evidence schema's S0-D contact fields count prohibited boundary-canary contacts, not permitted fixture traffic. This interpretation and its arithmetic must be frozen in the companion validator before execution.
- The evidence schema has a root Inconclusive decision but no per-case `inconclusive` outcome. A finite outcome/`observed_code` mapping and root-derivation rule for an executed but undecidable case must be accepted before execution; it cannot be invented after a run or represented as `not_run`.
- Current 80/443, resource ceilings, redirect limit, and patch intervals are proposed defaults. The proof uses only values accepted for its exact revision and records deviations from the proposals rather than treating documentation as approval.
- Static configuration review cannot prove runtime isolation. Every runtime isolation, network, browser, guest/host, teardown, or other Class B denial/absence claim requires the manifest-declared executable probe or control plus an independently healthy observer in the approved isolated environment. Pure Class A governance, schema, manifest, and closed policy checks prove only their offline contract assertions and do not claim a live boundary observation.

## Decisions and prerequisites

| Decision, ADR, approval, or access | Required state before execution | Current public-safe state | Stop action if absent |
|---|---|---|---|
| Exact plan revision and accountability | Human-approved `Approved to run`; one security/infrastructure role designated as schema final-decision role; concurrence and named generic reviewers recorded | Draft; roles not confirmed | Dispatch no case |
| S0-A governance and validator | Evidence schema 2.0.0 plus accepted companion semantic, contact-arithmetic, chronology, freshness, and leak validator available | S0-A Draft; no authorized validator/runner | No terminal Pass, Stop, or Inconclusive bundle |
| O-020 and decision timing | Owner-approved O-020 outcome synchronized across gate documents, with every decision it makes blocking for S0-D complete; while Open, O-001 through O-007 are all complete under the conservative rule | O-020 Open; ADR 0001 Proposed only | Remain Draft; do not infer later deadlines |
| Repository and proof execution | Accepted proof-only roots, language/dependencies, CI/network behavior, evidence handling, reset, bounds, retention, and teardown | Not accepted; locations Not authorized | Create no runnable root, workflow, project, package, or dependency |
| O-002 proof infrastructure | Accepted US proof region, environment, network model, route classes, account/project separation, budget and cost stop | Open | Create no cloud resource, route, identity, or metered service |
| O-006 isolation and patch ownership | Accepted production isolation technology or managed equivalent, proof boundary, image/browser qualification, vulnerability admission, patch SLA, exception authority, rollback, and accountable owner | Open; P-006 and numerical patch defaults Proposed | Select no VMM/runner/image; do not run |
| Port and protocol policy | Accepted proof policy for allowed ports and protocols; any O-015 dependency resolved | 80/443 and HTTP(S)-only direction documented, but P-007/O-015 not silently accepted by this plan | Freeze no numeric port expectation and open no route |
| URL, IP, DNS, connection, gateway, and browser policies | Closed versioned contracts, complete registry snapshots, parser ownership, redirect/CNAME/rate limits, method/header grammars, TLS behavior, and stable typed outcomes | Normative direction exists; exact proof artifacts and several limits unselected | Do not let a fixture choose policy |
| Positive-control and canary topology | Accepted safe allowed-path design, independent observer/calibration design, reset rules, counter vocabulary, and proof that no production exception or live target is introduced | Missing | No network case may run |
| Resource and neighbor methodology | Accepted exact per-job/global ceilings, equal/over-boundary semantics, measurement windows, baseline, and material-impact calculation | Document 08 values and document 10 ten-percent target are proposals/requirements awaiting proof authorization | Run no exhaustion case |
| Image, tool, and dependency record | Selected versions/digests, origin, license, SBOM/provenance, vulnerability state, update/unavailable behavior, and rollback are approved for proof | Unselected | Download, build, or execute nothing |
| Fixture manifests and rights | Each planned alias maps to one strict type-specific reviewed manifest with deterministic construction, digests, rights, handling mode, and case bindings | No S0-D schema or manifest | Do not generate, deploy, or cite a fixture |
| Evidence environment and Inconclusive encoding | Schema-compatible environment records, restricted topology evidence, exact per-case undecidable mapping, contact arithmetic, and root outcome precedence approved | Evidence vocabulary is lossy; mapping absent | Do not mislabel the run or decide retrospectively |
| Privacy, retention, and public boundary | Proof data inventory, raw/transient deletion, backup behavior, restricted evidence location/access/expiry, public scanner, and no-hold default approved; O-007 satisfied if current O-020 rule requires it | D-012 Accepted; P-008 Proposed; O-007 Open | Persist no deliberately submitted URL; create no evidence store |
| Incident and closeout authority | Kill-switch operators, containment sequence, retained-evidence rule, teardown inventory, deletion/revocation proof, and productionization authority approved | Generic checklist only | Do not start a resource that cannot be contained and removed |

No prerequisite is satisfied by this plan, a Proposed ADR, a fixture alias, a configuration screenshot, an external request, a successful local container run, or a tool default.

## Fixtures

The following IDs are plan-local roles only. They are not manifest IDs, paths, fixture approvals, or evidence references. Before execution, every applicable role must map exactly once to a reviewed immutable fixture manifest; evidence `fixture_refs` use the actual manifest IDs, never these aliases.

| Fixture ID and version | Planned source | Purpose | Safety classification | Cleanup or retention |
|---|---|---|---|---|
| `S0-D-FX-001-v1` | Location Not authorized | Governance, reference, contact-accounting, evidence, review, and closeout mutations | Planned public synthetic metadata | Retain only under reviewed manifest |
| `S0-D-FX-002-v1` | Location Not authorized | Proof environment, allowed-path, topology-class, canary-observer, and reset contract without deployed locations | Planned public-safe specification; deployed details restricted | Delete deployed state; retain only approved specification |
| `S0-D-FX-003-v1` | Location Not authorized | URL parser, port, IANA IPv4/IPv6, organization-range, metadata, and address-boundary vectors | Planned public standard/synthetic data after provenance and rights review | Retain only under reviewed manifest |
| `S0-D-FX-004-v1` | Location Not authorized | DNS, CNAME, mixed-answer, rebinding, zero-TTL, SVCB/HTTPS, and connection-binding matrix | Planned synthetic graph; no deployed answer or endpoint in Git | Delete service state and raw output |
| `S0-D-FX-005-v1` | Location Not authorized | Redirect, navigation, iframe, subresource, fetch, WebSocket, service-worker, and bypass procedures | Planned bounded generated content; non-executable in Git | Generate only inside approved proof; delete raw output |
| `S0-D-FX-006-v1` | Location Not authorized | Gateway method, body, header, Host, cookie, TLS, CONNECT, interaction, and CA-boundary vectors | Planned synthetic procedure/data | Delete CA/runtime state and raw logs |
| `S0-D-FX-007-v1` | Location Not authorized | Safe adversarial guest, host/cross-job tripwire, writable-state, and reset procedures | Planned isolated-security procedure; no exploit or live tripwire in Git | Delete guest, tripwire state, and raw evidence |
| `S0-D-FX-008-v1` | Location Not authorized | Resource equal/over-boundary, termination, and neighbor-baseline matrix | Planned bounded generated procedure | Destroy workers and raw performance output |
| `S0-D-FX-009-v1` | Location Not authorized | Opaque task/result envelope, lease, replay, stale-work, failure, and typed-code vectors | Planned public synthetic contract data | Retain only under reviewed manifest |
| `S0-D-FX-010-v1` | Location Not authorized | Artifact, quarantine, sanitizer, schema, path/MIME, and trusted-promotion mutations | Planned synthetic non-executable data/procedure | Delete hostile-shaped runtime artifacts |
| `S0-D-FX-011-v1` | Location Not authorized | Privacy/log/deletion, image/SBOM/vulnerability, rollback, incident, and teardown schedules | Planned public-safe metadata; operational evidence restricted | Retain governed metadata only; delete runtime state |

Planned bindings are closed and inclusive: `S0-D-FX-001-v1` binds cases 001–010, 089, 900, and 901; `S0-D-FX-002-v1` binds 008–009, 011–089, and 900–901; `S0-D-FX-003-v1` binds 021–033; `S0-D-FX-004-v1` binds 034–044; `S0-D-FX-005-v1` binds 045–057; `S0-D-FX-006-v1` binds 058–068; `S0-D-FX-007-v1` binds 069–074; `S0-D-FX-008-v1` binds 075–080; `S0-D-FX-009-v1` binds 081–085; `S0-D-FX-010-v1` binds 071, 079, and 084–087; and `S0-D-FX-011-v1` binds 086–089, 900, and 901. A case may cite more than one actual manifest. Missing, dangling, duplicate, cross-version, or undeclared mappings block execution.

Public manifests may describe deterministic generators and safe procedure structure, but they must never publish deployed endpoints, routes, canary placement, live DNS answers, exploit details, credentials, raw logs/captures, hostile executable bytes, or private environment identifiers.

## Environment and isolation

### Class A — offline reference

- Uses only reviewed deterministic fixture bytes and closed pure policy functions.
- Has no network route, cloud credential, live target, metadata access, or hostile execution.
- May validate schemas, parser/address vectors, expected codes, manifest bindings, and contact arithmetic.
- Cannot prove resolver, gateway, browser, microVM, canary, destruction, or incident behavior.

### Class B — isolated security staging

- Uses the selected O-006 separate-kernel boundary, one fresh worker per job, and a dedicated O-002 proof account/project/network with no production peering, workload identity, service, data, or credential.
- Gives the guest only the inspecting gateway and one schema-bound job-control/artifact channel. The guest has no direct DNS, Internet, internal route, or reusable secret.
- Uses a controlled resolver, independent firewall, proof-only synthetic destination services, and boundary observers whose exact locations remain restricted.
- Includes a positive permitted HTTP/HTTPS control that exercises the real gateway path without adding a production classifier exception or reaching a third-party target. The accepted topology must explain how.
- Records exact image, guest, browser, VMM/runner, resolver, gateway, firewall, policy, registry, fixture, schema, and observer revisions in restricted evidence with public-safe version/digest references.
- Resets observer counters before guest activity and destroys the worker, browser profile, writable storage, job authority, and temporary service state after every run.

The Class A public evidence environment uses schema class `local_offline` with network mode `offline`. The Class B public evidence environment uses `isolated_security_staging` with `isolated_fixture_network`. Both use data mode `synthetic_or_sanitized` and false production-credential, production-data, and live-threat flags. Exact topology and component composition remain in approved restricted evidence. If the schema cannot truthfully represent the run, update and review it before execution rather than adding ad hoc public fields or mislabeling the environment.

Case-to-environment mapping is closed before execution:

- cases 001–007 and 010 execute only in Class A and reference its exact environment record;
- cases 008–009, 011–089, 900, and 901 use Class B and reference its exact environment record even when one closeout branch is `not_applicable`; and
- no row implicitly runs in both classes. A future need for both observations requires a new stable case ID or an approved schema/plan revision rather than two results hidden behind one case.

Executed Class A cases set `contact_counts.applicable: false` and all eight counters to zero because no guest or boundary probe exists. Executed Class B cases set `applicable: true`; their manifest freezes the exact `test_attempts` count, which may truthfully be zero for a non-probe inspection/control case, and the exact expected `egress_denials`. Every non-executed case instead follows the all-zero/inapplicable rule below. This mapping is part of companion validation and cannot change after observing a result.

## Contact accounting

For every applicable Class B case, `test_attempts` is the manifest-declared count of deliberate guest probes toward prohibited boundaries, including zero when the case performs no such probe. `egress_denials` is the independently observed count of policy denials. The six remaining counters record prohibited-boundary observations only:

- `tcp_connections`;
- `udp_datagrams`;
- `application_requests`;
- `metadata_contacts`;
- `production_resource_contacts`; and
- `cross_job_contacts`.

Every one of those six counters must be zero in every case and in recomputed root totals for Pass. Permitted fixture traffic is recorded separately in bounded evidence and never placed in, subtracted from, or hidden between prohibited counters. A denial is not a prohibited contact. A zero with no healthy observer is not evidence.

Before guest probes, the controller performs an out-of-band positive self-test for every observer under a different calibration identity, proves expected detection, resets counters, and freezes the zero baseline. Calibration traffic is not guest traffic and cannot be mixed into proof counters. After the run, a second health check proves the observer remained functional. If the observer cannot distinguish zero contact from missing telemetry, the affected executed case uses the preaccepted undecidable-case encoding and drives root Inconclusive; it does not become Pass or `not_run`.

Every non-executed case, including a required ordinary case remaining after an early operational halt, stays in the bundle. It has no interval or duration, `contact_counts.applicable: false`, all eight counters zero, the schema-required exception-decision fields and safe notes, and evidence references to the Stop/Inconclusive cause and case-preservation record. The preaccepted companion mapping distinguishes this structural nonexecution from an optional-case waiver: an Accepted, unexpired exception is required only to consume an optional non-pass case in a Pass, never to erase a required case after Stop/Inconclusive. No ordinary case becomes optional, waived, or passed.

## Expected cases

Every regular case 001 through 089 is `required: true`. Every row expands into every manifest-declared subvector; one favorable aggregate cannot hide a failed mutation. Expected rejection is recorded as case `pass` with a bounded rejection code. Cases 900 and 901 follow the mutually exclusive closeout rule after the tables.

### Governance and contract cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-001` | Frozen plan and approval matrix | Attempt dispatch | Only the exact `Approved to run` revision with designated accountability dispatches; every Draft, Open, Proposed, stale, or merely submitted state denies before access | No resource or dependency is selected by implication | Sanitized prerequisite matrix, decision revisions/times, zero preauthorization access |
| `S0-D-CASE-002` | O-020 outcome and decision register | Resolve applied timing boundary | Every decision made blocking is complete before run; current conservative O-001–O-007 rule applies until replaced by an accepted synchronized outcome | Later table deadlines cannot authorize execution | Decision-state map and applied-boundary reference |
| `S0-D-CASE-003` | O-002, O-006, budget, patch, and owner records | Validate proof scope | Region/environment/network/cost stop, isolation technology, patch ownership, exception authority, and rollback are exact and current | The proof cannot create shadow production | Sanitized completeness matrix and opaque restricted refs |
| `S0-D-CASE-004` | Accepted repository/execution decision | Resolve all planned roots and behaviors | Runtime, dependency, CI, network, evidence, reset, retention, and teardown scope are explicitly authorized and proof-only | A plan cannot choose a stack by convention | ADR revision, approved path classes, dependency and teardown owners |
| `S0-D-CASE-005` | Schema 2.0.0 and companion validator | Run positive and mutation controls | Prefixes, refs, chronology, freshness, contact sums, S0-D zeros, undecidable mapping, reviews, closeout, and leaks are enforced; schema shape alone yields no gate | Invalid evidence cannot masquerade as Pass | Validator/schema revisions and mutation matrix |
| `S0-D-CASE-006` | Approved tool/dependency inventory | Verify origin, license, pin, digest, SBOM, vulnerability, update, unavailable, and rollback records | Every executable input is selected and governed; unknown or drifting input rejects | Supply-chain convenience cannot widen proof authority | Public-safe inventory summary and opaque approvals |
| `S0-D-CASE-007` | Actual strict fixture manifests and alias map | Validate bytes, digests, rights, safety, references, construction, and case bindings | Every alias resolves exactly once; live/restricted/executable prohibited content is absent | Planned aliases are never treated as fixtures | Manifest IDs/digests, validation results, rights/safety review |
| `S0-D-CASE-008` | Approved evidence store, public boundary, retention, and access policy | Exercise create, cite, expire, delete, and public projection controls | Raw proof output remains restricted; public output contains only approved metadata and opaque refs; expiry/deletion are enforceable | Evidence cannot become a public topology or indefinite archive | Data inventory, access/expiry results, scan and opaque deletion refs |
| `S0-D-CASE-009` | Frozen environment, bounds, observer set, and reset recipe | Calibrate, reset, run twice from clean state | Every observer is healthy before/after; exact revisions repeat bounded results; no prior state affects either run | Zero means observed zero and a stale worker cannot validate itself | Calibration/reset refs, repeat comparison, exact versions |
| `S0-D-CASE-010` | Complete case/vector/reference graph | Recompute coverage, counters, public scan, and outcome precedence | Every required subvector is represented; root counters equal per-case sums; Stop precedes Inconclusive and Pass; no dangling evidence | Aggregation cannot hide failure or contact | Coverage/ref graph, arithmetic result, public-safety result |

### Environment and isolation-foundation cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-011` | Approved Class B environment record | Compare actual environment with schema and restricted topology | Class, network mode, synthetic-data state, tools, and no-production/live-threat assertions are truthful and complete through references | Evidence vocabulary cannot obscure the real boundary | Environment record, topology review, mismatch result |
| `S0-D-CASE-012` | Dedicated proof account/project/network | Inspect routes, peering, workload placement, and identity | No production peering, shared production workload, implicit trust, or cross-account authority exists | Isolation starts outside the guest | Sanitized route/placement matrix and opaque configuration refs |
| `S0-D-CASE-013` | Production/control/admin/internal canaries | Probe every prohibited route class through approved synthetic identities | Every probe denies before canary contact; no alternate route appears | Compromise cannot reach a production or control plane | Attempt/denial counts and six zero contact counters |
| `S0-D-CASE-014` | CI, repository, orchestrator, secrets, cloud, queue, object, database, and admin canaries | Attempt discovery and access from guest/runner scopes | All paths are absent or denied; no reusable workload/service identity exists | Proof code cannot inherit operator authority | Capability/route matrix and zero contact/read results |
| `S0-D-CASE-015` | Guest image and analysis CA boundary | Search every guest-readable source and attempt CA/proxy credential use | No secret, private key, production certificate, token, or reusable proxy credential exists | A guest escape cannot steal a useful credential | Secret scan, denied-use results, public-key-only result |
| `S0-D-CASE-016` | One-job lease, input, artifact, and result capabilities | Use valid, wrong-job, wrong-object, over-scope, expired, and replayed forms | Only the exact live job/object/prefix/action succeeds; every mutation denies and alerts | Authority is one job and one object, not a service credential | Capability matrix, expiry/replay result, zero cross-job effect |
| `S0-D-CASE-017` | Default-deny firewall and permitted channels | Attempt every interface, route, protocol, and channel outside gateway plus control/artifact path | Only the schema-bound control/artifact channel and approved proxy transport work | The browser cannot create a second egress path | Firewall observations, allowed-channel control, denial/contact counts |
| `S0-D-CASE-018` | Controlled resolver configuration | Probe hosts file, search suffix, multicast discovery, guest DNS, and resolver selection | Resolver owns DNS with no search/mDNS/guest-selected alternative; all bypass probes deny | Hostname policy cannot be bypassed before the gateway | Config revision, probe matrix, UDP/application zeros |
| `S0-D-CASE-019` | Inspecting gateway plus independent firewall | Fault or bypass each layer separately | Each layer independently prevents prohibited reachability; allowed control fails visibly when its required layer is disabled | Browser cooperation is never the security boundary | Layer-failure matrix, observer results, permitted-control results |
| `S0-D-CASE-020` | Signed minimal immutable read-only image and clean-worker lifecycle | Boot with a random non-root guest identity and encrypted ephemeral scratch; attempt mutable/unknown/post-hostile reuse, crash, then destroy | Only signed pinned pre-untrusted state boots; each job gets a fresh browser profile and scratch; all writable state and authority disappear after every terminal event | Hostile state is disposable and never reused | Image digest/signature/attestation, guest-identity class, storage policy, lifecycle timeline, destruction/reset evidence |

### URL, host, port, and address cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-021` | Valid HTTP/HTTPS, IDNA/Punycode, mixed-case, reviewed trailing-dot, percent-encoding, query, and fragment permitted-destination controls | Parse and traverse the approved gateway while tracing only synthetic canaries | Original spelling/query/fragment remain transient for analysis, network host is the exact normalized ASCII representation, ingress/gateway agree, and the control reaches only the fixture; raw values reach no durable/log sink | Negative tests cannot pass because networking is broken, and canonicalization cannot discard security-bearing input | Parsed fields, transient/network comparison, allowed fixture count, sink scan, observer health |
| `S0-D-CASE-022` | Invalid UTF-8, NUL/CRLF/control, malformed/double escapes, encoded separators, invalid IDNA labels, userinfo, missing/single-label/ambiguous host, and known parser-differential vectors | Submit through ingress and gateway parsers before resolution | One canonical parser/parsed structure yields the same bounded `invalid_url` or approved interpretation at every layer; rejected vectors cause no DNS or destination contact | Parser disagreement or Unicode/encoding ambiguity stops before network | Per-vector cross-layer result, zero resolution/contact, parser revision |
| `S0-D-CASE-023` | All non-HTTP schemes including file/data/blob/javascript/gopher/ftp/dict/SMB/Unix forms | Submit before resolution | Every vector returns `unsupported_scheme` and causes no network or local-file action | Scheme parsing cannot become a protocol/file tunnel | Per-scheme result and zero access counters |
| `S0-D-CASE-024` | Special-use/local/home/metadata hostname matrix | Resolve under proof policy | All non-fixture special names deny; any explicit isolated fixture exception is proof-only and cannot enter production policy | Local naming cannot bypass address checks | Name/rule matrix, policy diff, zero canary contact |
| `S0-D-CASE-025` | Accepted default-port controls | Submit explicit/implicit allowed ports | Each accepted form maps to the same frozen destination semantics and reaches only the fixture | Defaults cannot change between parser and gateway | Parsed/transport comparison and allowed counts |
| `S0-D-CASE-026` | Every non-approved port boundary vector | Submit through all URL surfaces | Each returns explicit unsupported/Unknown without reinterpretation or destination contact | Hezo cannot become a public port scanner | Port/result matrix and zero contacts |
| `S0-D-CASE-027` | Integer, hexadecimal, octal, shortened, signed, overflow, and encoded IPv4 spellings | Parse and classify | Every alternate spelling rejects before connection | Equivalent private addresses cannot hide in syntax | Parser/classifier results and zero connection |
| `S0-D-CASE-028` | IPv6 zone and IPv4-mapped IPv6 vectors | Parse and classify | Zone identifiers reject; mapped IPv4 normalizes before the same IPv4 policy | Address families cannot disagree on policy | Normalization/classification matrix |
| `S0-D-CASE-029` | Pinned IANA IPv4 registry boundaries and adjacent controls | Test literal, answer, CNAME, redirect, subresource, and WebSocket forms | Every special prefix boundary denies; only reviewed ordinary-public controls proceed | The classifier covers more than RFC 1918 | Registry revision, per-prefix/mode result, contact zeros |
| `S0-D-CASE-030` | Pinned IANA IPv6 registry boundaries and adjacent controls | Exercise the same surfaces | Every special prefix boundary denies; reviewed ordinary-public controls proceed | IPv6 cannot be a weaker policy path | Registry revision, per-prefix/mode result, contact zeros |
| `S0-D-CASE-031` | Proof VPC, subnet, overlay, pod, service, node, cluster DNS, host gateway, and corporate classes | Probe each synthetic canary | Every class denies independently of public/special registry status | Deployed topology is part of policy | Range-policy revision and six zero contact counters |
| `S0-D-CASE-032` | Synthetic cloud metadata IPv4, documented IPv6, and hostname classes | Probe through every request surface | All deny before metadata contact and return bounded operational denial | No real credential is used as a canary | Per-class attempts/denials and `metadata_contacts: 0` |
| `S0-D-CASE-033` | NAT64, 6to4, Teredo, translation/transition, and Hezo public-admin range vectors | Parse, resolve, and connect | Each prohibited or ambiguous mapping denies before contact; approved public control remains reachable | Translation cannot smuggle an internal/admin peer | Mapping results, peer checks, zero prohibited contact |

### DNS and connection-validation cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-034` | Allowed A-answer control | Resolve and connect through gateway | Complete answer set validates, selected peer matches, and fixture receives the bounded request | DNS denial tests have a working IPv4 control | Answer/peer/result record |
| `S0-D-CASE-035` | Allowed AAAA-answer control | Resolve and connect through gateway | Complete answer set validates, selected peer matches, and fixture receives the bounded request | DNS denial tests have a working IPv6 control | Answer/peer/result record |
| `S0-D-CASE-036` | Allowed bounded CNAME chain | Resolve complete chain and connect | Every hop and final answer validates; one approved peer is used | The resolver can follow safe chains without skipping validation | Chain/answer/peer and allowed result |
| `S0-D-CASE-037` | Public-shaped CNAME ending in prohibited A/AAAA | Resolve and attempt connection | Entire request denies before peer contact | A benign first label cannot launder a denied target | Chain classification, denial, zero contact |
| `S0-D-CASE-038` | Mixed allowed/prohibited A, AAAA, and combined sets | Resolve under selection pressure | Any prohibited candidate rejects the whole request; no address-family fallback occurs | Client selection cannot choose the one unsafe answer | Full answer sets, denial, zero contacts |
| `S0-D-CASE-039` | First allowed answer then prohibited rebinding answer | Make initial and new connections | First approved control may connect; every later resolution is reclassified and prohibited answer denies | No hostname-level allow cache survives rebinding | Resolution/connection timeline and second-contact zero |
| `S0-D-CASE-040` | Zero-TTL and rotating answer schedule | Open repeated/new connections | Every selected address passes current policy; prohibited rotation denies without fallback | TTL and connection reuse cannot freeze an allow | Schedule, selected peers, denials/contact zeros |
| `S0-D-CASE-041` | CNAME loop and depth N/N+1 | Resolve | Loop and over-depth terminate boundedly with DNS-policy denial; no connection | Resolver work is bounded and closed | Depth policy, per-case count/time/result |
| `S0-D-CASE-042` | SVCB/HTTPS alternative target, port, and address hints | Serve every variant | V1 disables or rejects alternatives; no hinted endpoint is contacted | Modern DNS hints cannot bypass canonical policy | Record-type matrix and zero alternate contacts |
| `S0-D-CASE-043` | Same host across sequential new connections | Change answers/policy between connections | Every new connection re-resolves/revalidates; prior allow supplies no authority | Connection policy is current, not hostname cached | Connection IDs, policy versions, selected peers |
| `S0-D-CASE-044` | Ingress/gateway differential, resolver/library/peer/Host/SNI/certificate substitution vectors | Pass the one approved parsed structure to transport and attempt every reparse/substitution | No component reparses the original string or performs a second library resolution; scheme/host/port remain identical; connected peer, canonical Host, SNI, and verified certificate all match; every substitution rejects | Parser and transport cannot disagree after validation | Parsed-structure identity, resolution count, per-layer host/port, peer/TLS comparison |

### Redirect, browser-surface, and bypass cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-045` | Each 300–308 status under pinned browser behavior | Follow statuses that policy follows, with allowed and prohibited targets | Allowed controls behave as frozen; every followed prohibited target denies before contact; non-followed statuses remain bounded | Redirect status quirks cannot skip policy | Status/action/result matrix and zero prohibited contacts |
| `S0-D-CASE-046` | Scheme-relative, encoded, double-encoded, and malformed `Location` values | Process redirect | Each target is parsed once under the canonical rules; ambiguous/malformed forms reject | Header encoding cannot create a second interpretation | Raw synthetic class, parsed result, denial/contact count |
| `S0-D-CASE-047` | Same-host redirect to prohibited target | Navigate | Full DNS/address/port policy reruns and denies | Same host is not a trust exception | Redirect and policy events, zero contact |
| `S0-D-CASE-048` | Redirect loop and exact N/N+1 chain | Navigate | Approved N behavior is bounded; N+1 returns `redirect_limit` and destroys the run as policy requires | Redirect work cannot become unbounded | Hop count, timing, terminal code |
| `S0-D-CASE-049` | Meta refresh, JavaScript/client navigation, and new-window target | Execute bounded generated page | Every new navigation traverses the full policy; prohibited targets receive no contact | Browser-initiated navigation is not exempt | Surface/result matrix and contact zeros |
| `S0-D-CASE-050` | Iframe target matrix | Load bounded page | Each frame request is revalidated; prohibited frame receives no contact | Nested contexts cannot bypass egress | Frame request/result and zero contact |
| `S0-D-CASE-051` | Image, CSS, font, media, and script target matrix | Load bounded page | Every subresource traverses full policy; prohibited destination receives nothing | Passive resources are network requests | Per-type request/denial/contact results |
| `S0-D-CASE-052` | Fetch and XHR target/method matrix | Execute bounded calls | Every request traverses URL, method, header, body, DNS, and peer policy | Script APIs cannot open a hidden client | Request/result matrix and zero prohibited contact |
| `S0-D-CASE-053` | WebSocket and upgrade attempts | Execute from page | Negotiation and connection deny; no opaque upgraded channel reaches destination | Long-lived upgrade cannot escape inspection | Gateway denial and zero application/TCP contacts |
| `S0-D-CASE-054` | Service-worker install and request attempts | Execute then start clean job | Requests traverse policy; worker state cannot survive or affect next job | Persistent browser machinery remains job-local | Request results and next-job state absence |
| `S0-D-CASE-055` | Same-host and cross-host pooled connections | Attempt destination changes over reuse | Current validated host/address/peer policy applies; connection pooling cannot carry authority across target | Transport reuse cannot weaken isolation | Connection ownership/peer/result matrix |
| `S0-D-CASE-056` | Response `Alt-Svc` and protocol-upgrade instructions | Load through gateway | Instructions are stripped/ignored and no alternative endpoint is contacted | Server-controlled hints cannot open bypass | Response-policy events and zero alternate contact |
| `S0-D-CASE-057` | Direct DNS, DoH, QUIC, WebRTC UDP, raw socket, alternate proxy, ICMP, SMTP, SSH, database, cloud API, package repo, and object-store attempts | Execute safe probes from guest | Every path denies independently of browser policy; no retry through another representation | Guest has no direct resolver or Internet path | Probe/denial matrix, all six prohibited contact counters zero |

### Inspecting gateway and interaction cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-058` | Approved GET control | Request fixture | Gateway emits one bodyless GET with only approved headers to validated peer | A working control distinguishes denial from outage | Fixture observation and policy comparison |
| `S0-D-CASE-059` | Approved HEAD control | Request fixture | Gateway emits one bodyless HEAD with only approved headers to validated peer | HEAD cannot gain body or header privilege | Fixture observation and policy comparison |
| `S0-D-CASE-060` | POST, PUT, PATCH, DELETE, OPTIONS, TRACE, destination CONNECT, form submit, sendBeacon, and one-byte/body-bearing vectors | Execute from browser/script | Every unapproved method or body denies before destination; internal proxy CONNECT is excluded and tested in 065 | Hezo cannot submit forms, scan, relay, or amplify | Method/body matrix, denials, zero destination requests |
| `S0-D-CASE-061` | Every allowed header at valid and boundary grammar/value/byte sizes | Send through gateway | Only exact allowlisted bounded values proceed; over/invalid forms deny | Header forwarding is a closed contract | Per-header boundary results and forwarded names only |
| `S0-D-CASE-062` | Authorization, proxy auth, forwarding, Referer, Range, Upgrade/WebSocket, unexpected Content, custom, and control-bearing headers | Attempt emission | Every field is stripped or denied as policy specifies; fixture never observes it | Page code cannot relay secrets or choose transport semantics | Attempt/fixture-observed name matrix |
| `S0-D-CASE-063` | Host and hop-by-hop mutation vectors | Attempt guest-selected values | Gateway reconstructs Host and owns transport headers; mutations never reach fixture | Destination identity remains server-controlled | Canonical host and observed-header comparison |
| `S0-D-CASE-064` | Same-origin, cross-origin, over-count, over-byte, and next-job cookies | Set and request | Only bounded same-job/same-origin cookie works; cross-origin, excess, export, and next-job reuse fail | Cookies cannot become cross-job identity or exfiltration | Cookie scope/count/byte and reset results |
| `S0-D-CASE-065` | Job-bound guest-to-proxy CONNECT plus foreign/opaque tunnel mutations | Open inspection transport | Only authenticated job-bound inspection transport succeeds; proxy never forwards destination CONNECT or opaque bytes | TLS inspection cannot degrade into a tunnel | Transport binding, destination method count, tunnel denial |
| `S0-D-CASE-066` | Valid, expired, untrusted, name-mismatched, and invalid upstream certificates | Request HTTPS fixture | Valid control proceeds; every invalid certificate stops with typed observation and no content acceptance | Coverage never justifies certificate bypass | Cert-class/result matrix and upstream peer record |
| `S0-D-CASE-067` | Analysis CA, isolated gateway/key boundary, guest trust, proxy configuration, and log sinks | Inspect trust distribution and probe key/log access | Guest has only the public trust certificate; the private signing key is confined to the isolated inspecting-gateway/key boundary and unreachable from guest; neither key nor trust certificate exists on developer, analyst, consumer, or non-analysis systems; ordinary proxy URL logs remain empty and transient state deletes on deadline | Inspection cannot create a reusable trust anchor or browsing log | Key-access denial, gateway custody and trust-scope review, log/deletion scan |
| `S0-D-CASE-068` | Pinned browser-hardening and empty-profile policy plus click, button, CAPTCHA, auth, upload, download-open, form, extension/plugin/PDF, and every device-permission vector | Inspect launch/profile state and execute bounded page | Chromium sandbox and Site Isolation remain on; WebRTC and QUIC are disabled; no browser direct-DNS, DoH, alternate-proxy, proxy-bypass, certificate/debug-bypass, saved cookie/credential/client certificate, autofill, password manager, history, synchronization, extension/plugin, printing, or PDF/document execution state exists; camera, microphone, geolocation, Bluetooth, USB, clipboard, notifications, downloads, and all interactions remain denied | Passive analysis cannot weaken the browser boundary, retain consumer state, impersonate a user, or execute a download | Launch/profile policy diff, sandbox/site-isolation result, network-feature state, interaction/request counts, per-permission and download state |

### Guest isolation and resource cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-069` | Non-root jailed/chrooted runner with approved seccomp, cgroup, minimal-device, host-hardening, image-attestation, mount, passthrough, SSH/certificate, runtime/VMM, and orchestrator policy | Inspect the host boundary and probe host/runner-sensitive filesystem, proc/cgroup, device, socket, and control surfaces | Runner hardening matches the frozen policy; bounded guest-local proc/cgroup/device views reveal no host authority; host mounts, passthrough, runtime/control sockets, SSH keys, production certificates, and every unexpected host/control surface are absent or denied; tripwire remains unread | Guest compromise cannot reach host control | Runner-policy result, guest-view inventory, probe results, and zero tripwire/host contact |
| `S0-D-CASE-070` | Mount, ptrace, privileged syscall, namespace change, raw privilege, and escalation attempts | Execute bounded adversarial guest procedure | Every action denies or terminates the worker within policy; host remains healthy | Guest kernel controls remain layered | Per-action outcome, host health, terminal code |
| `S0-D-CASE-071` | Other worker/job/profile/artifact prefix and host-network canaries | Attempt read, write, and contact | All attempts deny; six prohibited counters remain zero and no state changes | One hostile job cannot affect a neighbor | Access results, object digests/state, cross-job zeros |
| `S0-D-CASE-072` | Scratch path policy plus below/equal/N+1 hard quota vectors | Exercise preflight-invalid paths and consume actual runtime storage to each boundary | Outside-scratch paths deny before write; below/equal behavior matches the frozen contract; any actual N+1 hard-ceiling crossing terminates and destroys the whole worker with a typed result | Writable state is small and hard runtime ceilings are not weakened into partial rejection | Byte/path-class results, terminal code, worker destruction evidence |
| `S0-D-CASE-073` | Cookie, cache, local storage, IndexedDB, service worker, browser profile, and disk markers | Complete one hostile run then start another | Second job observes none of the first job's markers | No hostile state is reused | Per-state absence and distinct worker/profile refs |
| `S0-D-CASE-074` | Synthetic guest file and endpoint tripwires | Attempt access through all approved guest surfaces | Tripwires record zero read/write/contact while controller calibration remains healthy | Boundary claims have independent detection | Calibration evidence, attempts/denials, tripwire zeros |
| `S0-D-CASE-075` | Accepted CPU, process/PID, and file-descriptor boundaries at below/equal/over values | Run bounded pressure | Allowed values remain bounded; over value terminates the whole worker with typed code; host/neighbor remain healthy | Local exhaustion cannot escape the worker | Resource series, termination time/code, host health |
| `S0-D-CASE-076` | Accepted memory and writable-disk below/equal/N+1 hard boundaries | Apply pressure through each boundary | Below/equal behavior matches the frozen contract; every N+1 crossing terminates and destroys the whole worker; no host swap/disk impact or residual state remains | Memory/disk pressure cannot become host denial of service | Usage series, terminal code, destruction and host-cleanup results |
| `S0-D-CASE-077` | Infinite JS, WebAssembly, huge DOM/canvas, export preflight, and actual below/equal/N+1 hard runtime vectors | Execute bounded generated content | A soft output preflight may reject before work; below/equal behavior matches contract; any actual hard runtime crossing terminates and destroys the whole worker with typed outcome; no persistence remains | Browser content is hard bounded and truncation cannot substitute after crossing | Per-fixture resource curve, preflight/runtime distinction, terminal result and destruction |
| `S0-D-CASE-078` | Request, connection, redirect, wall/navigation time, wire-byte, and per-capability/host/address/registrable-domain/global rate and concurrency boundaries across multiple jobs | Exercise below/equal/N+1 values, distinct-job concentration, retry/queue storms, and an unrelated healthy-target control | Accepted edge behaves as frozen; each N+1 hard crossing terminates the affected worker; aggregate gateway limits stop concentrated jobs without uncontrolled target traffic; unrelated control remains healthy | Network amplification, scanning, and hangs are bounded across jobs independently of browser cooperation | Per-scope/job counts, times/bytes, retry/queue decisions, terminal codes, target totals and unrelated-control result |
| `S0-D-CASE-079` | Response, decoded, archive expansion/nesting, screenshot, DOM, and artifact-count preflight plus actual below/equal/N+1 runtime boundaries | Reject structurally invalid inputs before work, then process bounded synthetic artifacts through each hard boundary | Invalid/preflight-oversize objects reject before runtime; below/equal behavior matches contract; any actual decoded/runtime/artifact hard-ceiling crossing terminates and destroys the whole worker | Compression, rendering, or post-run rejection cannot weaken a crossed guest hard limit | Encoded/decoded sizes, dimensions/counts, preflight/runtime result matrix, destruction evidence |
| `S0-D-CASE-080` | Concurrent calibrated neighbor plus combined exhaustion workload | Run stress to hard termination | Target worker dies within policy; host stays healthy; neighbor remains within the accepted methodology and no more than the frozen material-impact threshold | One job cannot materially degrade another | Baseline/window/method, target result, neighbor delta |

### Task, result, quarantine, privacy, and operations cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-081` | Every invalid, blocked, timeout, crash, artifact, policy, and resource result plus an active nonterminal control | Map state and terminal code to consumer semantics | Only genuinely active work may be pending; every terminal incomplete/denied/crashed/resource result completes as `unknown` with one bounded operational code, never indefinite pending or `no_known_danger`; no retry uses a second representation/address family | Operational failure is never a clean verdict or an endless poll | Complete state/code/mapping/retry matrix |
| `S0-D-CASE-082` | Timeout, browser crash, guest crash, runner loss, and forced cancellation | Interrupt at each lifecycle point | Job terminates boundedly; VM/profile/scratch and authority are destroyed/revoked; next run is fresh | Failure cannot leave a warm hostile worker | Lifecycle timeline, destruction/revocation, next-run reset |
| `S0-D-CASE-083` | Duplicate delivery, lease race, expiry, retry, and late result | Run concurrent and reordered schedules | Each retry is immutable; at most one semantic effect survives; stale/late result cannot advance state or append ambiguous observations | At-least-once delivery cannot duplicate trust evidence | Schedule/result graph, lease decisions, effect counts |
| `S0-D-CASE-084` | Valid and mutated task/result envelopes | Substitute plaintext/raw fields, object digest, job/attempt, image/policy/schema, lease, artifact manifest, signature, ownership, and size | Only closed bounded opaque task and authentic current result proceed; every mutation rejects to redacted quarantine | Worker messages carry no production credential or attacker payload | Schema/mutation matrix, signature/ownership result |
| `S0-D-CASE-085` | Runner, low-privilege quarantine/sanitizer, trusted-promotion stub, graph/verdict/blockset canaries, and `S0-D-FX-010-v1` forged MIME/extension, filename/traversal, polyglot, malformed PNG, SVG/HTML/PDF/archive/executable, re-encode failure, XSS/formula, scanner timeout/false-negative, wrong-job/role, and state-transition mutations | Attempt direct writes and every malformed promotion/access path; exercise positive re-encoded PNG, bounded JSON/text/hash/sanitized-metadata controls, and `untrusted` through deleted/rejected state transitions | Runner has no direct database/write authority; internally generated names defeat traversal; promotion re-parses closed schema/provenance/digests/ownership; only approved re-encoded/bounded typed representations pass; every unsafe mutation, wrong role/job, failed re-encode, timeout, and false-negative control rejects without treating non-detection as safety; captured HTML never executes on a Hezo/analyst origin | Hostile output cannot become trusted state or execute directly, and quarantine lifecycle is closed | Credential/route absence, complete artifact/schema/sanitizer/access/state matrix, allowed-output digests, escaped-text result, and zero trusted writes |
| `S0-D-CASE-086` | Synthetic URL/query/header/page/error/token-like canaries across every sink | Execute success and every failure path | Raw values are confined to approved transient object/artifact scope and absent from logs, traces, metrics, crashes, support, queues, dead letters, object names, durable DB, and wrong planes | Debugging cannot erase the privacy boundary | Sink inventory, scan results, opaque restricted refs |
| `S0-D-CASE-087` | Terminal job, queue/retry copies, transient proxy state, artifacts, replicas, snapshots/backups, and no-hold policy | Complete and advance time/deletion jobs under accepted proof policy | Data deletes immediately when possible and within frozen conservative ceilings; no hidden legal/incident hold or recoverable backup remains | Proposed retention is not silently extended | Lifecycle/deletion/restore-unreadability results |
| `S0-D-CASE-088` | Proof-equivalent crawl/image/pool/egress/promotion kill switches and suspected-escape drill | Trigger owner-controlled containment | Scheduling stops, egress cuts, authority revokes, outputs quarantine, minimum approved evidence is preserved, known-good rebuild occurs, and restore requires security approval | A plausible escape is containable without touching production | Ordered drill events, residual inventory, approval/rollback refs |
| `S0-D-CASE-089` | Frozen image/SBOM/provenance/vulnerability/patch/rollback state, Accepted O-006 numerical policy, and complete evidence | Exercise release-admission and deployed-image Critical/High before/equality/after timing, browser-qualification cadence, stale-image, missing/expired/mitigated/unmitigated High exception, supported/unsupported rollback, image kill switch, repeat validation, contact arithmetic, reviews, and public scan | No Critical or unmitigated High remains; release admission never borrows the deployed patch window; any permitted High exception is named/approved/current/compensated; each timing boundary and stale image follows the Accepted policy; rollback is signed/supported; unsafe image kill switch works; all results reproduce and public scan is clean | Patch debt, policy-boundary ambiguity, stale evidence, or self-validation cannot be hidden at the gate | Policy revision, timing/exception/qualification matrix, scan/rollback/kill-switch summaries, repeat matrix, review inputs |

### Closeout cases

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-D-CASE-900` | Stopped or Inconclusive run with any subset of worker, image, route, resolver, gateway, CA, identity, capability, fixture, canary, state, artifact, log, schedule, evidence, or metered resource | Apply the [teardown checklist](../teardown-checklist.md) immediately under owner control | Traffic and scheduling stop; egress is cut; identities/authority revoked; temporary resources and state removed; policy-permitted restricted result/closeout evidence and its opaque index retain explicit owner/access/expiry/deletion rules | Failure cannot leave a reachable analysis path, credential, cost, hostile state, or unmanaged evidence | Sanitized inventory, zero ungoverned residuals, opaque revocation/deletion refs, completion time |
| `S0-D-CASE-901` | Completed run eligible for final review | Select exactly one closeout: Teardown or Productionize separately | Teardown completes, or a separate stage-appropriate plan and Accepted ADRs govern every retained component while proof-only privilege/state is removed; no proof runner is promoted by omission | A proof result is not production authorization | Closeout outcome/time, retained-item allowlist, governing decisions, reviewer outcomes |

Closeout applicability is outcome-dependent and fixed before execution. Case 900 is `required: true` for Stop or Inconclusive and `required: false` for a completed run advancing to final review. Case 901 is `required: true` for a completed run advancing to final review and `required: false` for Stop or Inconclusive. Exactly one is required and executed. The unused branch is `not_applicable`, has no interval/duration, has inapplicable/all-zero counters, and cites a separate pre-run Accepted, unexpired closeout-applicability decision through the schema's exception fields. The companion validator rejects both-required, neither-required, both-executed, outcome-mismatched, missing/expired applicability, or fabricated intervals.

## Gates

### Pass gate

Pass requires all of the following together:

- the exact plan is Approved to run; both accountable roles concur; one final-decision role is designated; every applied prerequisite, external state, fixture mapping, policy, environment, observer, bound, and reviewer remains current;
- all regular cases 001–089 and the applicable case 901 execute and pass every declared subvector with no unexplained deviation, skip, not-run, not-applicable, contradiction, or gate-blocking limitation;
- the allowed HTTP/HTTPS and schema-bound channel controls work through the frozen topology, every canary observer passes pre/post calibration, and zero cannot be explained by broken instrumentation;
- for every case and recomputed aggregate, prohibited `tcp_connections`, `udp_datagrams`, `application_requests`, `metadata_contacts`, `production_resource_contacts`, and `cross_job_contacts` equal zero; deliberate attempts and gateway denials are recorded independently and permitted control traffic is not mixed into those fields;
- the guest has no secret, production/internal route, direct DNS/Internet, opaque tunnel, cross-job access, reusable state, general credential, or direct trusted-store write; the pinned browser profile independently disables WebRTC, QUIC, direct DNS/DoH, and alternate-proxy/proxy-bypass configuration;
- every over-limit vector terminates the whole worker within its frozen bound, leaves the host healthy, and keeps the calibrated neighbor inside the approved material-impact threshold;
- task/result, quarantine, schema/provenance, artifact, log/redaction, deletion, image/SBOM/provenance, vulnerability, patch, rollback, kill-switch, and containment cases all produce their exact expected result;
- evidence identifies the exact revision, manifests, environment, versions, bounds, attempts, counters, deviations, limitations, and restricted references; schema 2.0.0, companion validation, repository leak scan, and independent human public-safety review pass with zero findings;
- technical correctness, security, infrastructure, privacy/retention, dependency/licensing, and final gate reviews are complete and current; and
- case 901 records completed Teardown or a separately Accepted productionization outcome. Nothing remains active or retained by omission.

A Pass answers only the frozen S0-D kill-risk question in the exact approved environment. It does not authorize a production crawler or support a release/security certification claim.

### Stop gate

Stop takes precedence over Inconclusive and Pass when any of the following occurs:

- any prohibited contact counter is nonzero, a tripwire is accessed, an undeclared route/peer/protocol becomes reachable, or a direct resolver/Internet/proxy-bypass path works;
- a secret, production credential/data, CA private key, host/control surface, another job, or trusted graph/verdict/blockset write becomes available;
- a denied URL/address/DNS/redirect/navigation/subresource/method/body/header/tunnel/certificate vector reaches its prohibited target;
- the browser sandbox/Site Isolation or certificate validation is disabled, hostile state is reused, a resource escapes its bound, or a neighbor exceeds the accepted material-impact threshold;
- a live threat, captured submission, real metadata service, third-party target, production route/data, or live, captured, unapproved, exploit-bearing, or otherwise out-of-manifest executable content enters the proof; approved bounded synthetic adversarial content generated only inside Class B remains permitted;
- a required positive control reproducibly fails under an otherwise healthy exact approved matrix, falsifying the boundary rather than exposing a transient fixture fault;
- an actual runtime plan, fixture, image, dependency, registry, policy, topology, observer, or evidence revision differs from the frozen approved bytes/state without prior approval;
- restricted material crosses the public boundary, raw values reach prohibited sinks, or required evidence is corrupted, irreproducible, unsafe, or discovered to be false; or
- containment, revocation, deletion, known-good rebuild, or case 900 teardown encounters a failure under the accepted plan.

Immediate containment is to stop scheduling, cut egress, revoke job/artifact/CA/service authority, isolate the affected pool, quarantine outputs, preserve only privacy-approved restricted incident evidence, audit the affected window, rebuild from signed known-good inputs, and require explicit security approval before any restore. Execute case 900. Discovery of a Stop condition creates an operational halt and Stop intent immediately. If containment, teardown, evidence review, or closeout is incomplete, the evidence bundle remains `not_decided` with an open gate-blocking limitation and incomplete closeout; a terminal `stop` decision is recorded only after schema-required review and closeout are complete. Dynamic analysis and dependent claims remain paused throughout. A final Stop can answer the kill-risk question successfully; it never counts as a passed gate.

### Inconclusive outcome

Inconclusive is available only after an authorized run, with no observed safety or authorization failure, when a required result is genuinely undecidable because:

- pre/post observer calibration cannot establish that zero contact is an observed zero;
- an approved fixture service, image, dependency, baseline, or independent evidence source is temporarily unavailable or confounded by unrelated environment failure;
- an immutable approved reference, fixture, or evidence source becomes unavailable midrun while independent evidence proves the executed runtime bytes, topology, and policy did not drift; or
- an authorized reviewer temporarily cannot access required restricted evidence and no evidence-integrity failure is shown.

The exact per-case outcome/`observed_code` representation and root derivation must match the preaccepted evidence contract. Missing authority, topology, manifest, tool, observer, or location before execution leaves the plan Draft, not Inconclusive. Any observed contact, bypass, secret, production access, boundary failure, or evidence falsehood is Stop. Complete case 900, preserve the limitation, revise and reapprove the plan, reset the environment, and rerun every affected case; partial success is never rounded up.

## Evidence plan

The public bundle uses [evidence schema 2.0.0](../evidence-bundle.schema.json) and the exact S0-A companion validator. It records the root run interval and, for every executed case, start/end/recorded times, expected and observed bounded codes, environment/revision/fixture references, evidence finalization time, deviations, limitations, and typed contact counts. The validator proves case coverage, prefix/reference integrity, real chronology/freshness, contact arithmetic, closeout applicability, decision equality, and outcome precedence.

Public-safe evidence may contain:

- generic roles, plan/schema/fixture revisions, reviewed public artifact digests, bounded tool/version classes, case/result/failure codes, attempt/denial/prohibited-contact counts, resource classes, sanitized limitations, review states, closeout outcome, and non-enumerable opaque restricted references.

Restricted evidence outside Git contains:

- cloud/account/project/host/image/service identifiers; network diagrams, routes, ranges, endpoints, DNS answers, canary/tripwire placement, CA/key/capability material; raw URLs, pages, scripts, artifacts, screenshots, HAR/network captures; proxy/resolver/browser/host/security logs; resource traces; incident detail; raw evidence; private owner/access paths; and deletion/revocation receipts.

Public opaque IDs must not encode a provider, environment, address, route, target, person, account, project, location, or enumerable identifier. Public digests are allowed only for reviewed public or high-entropy artifacts when they cannot confirm a restricted value. The public bundle sets exactly the schema's eight declarations to false: `contains_raw_url`, `contains_live_threat_data`, `contains_page_or_capture_content`, `contains_attestation_material`, `contains_credentials_or_tokens`, `contains_personal_owner_data`, `contains_private_approval_records`, and `contains_device_or_cloud_identifiers`. The semantic leak scan and human sanitization review additionally reject production data, restricted source data, endpoints, topology, and every other repository-prohibited category; no ad hoc declaration field is added.

Every retained restricted result and closeout record has a purpose, authorized reviewer role, approved location, creation/finalization time, expiry, deletion rule, and opaque-index entry. Raw working copies, transient inputs, packet captures, proxy state, VM state, artifacts, queues, replicas, snapshots, and backups follow the approved proof policy and are not retained indefinitely. A public summary cannot be used to reconstruct the deployment.

## Limitations and unsupported claims

Even a future Pass does not establish that:

- the selected boundary is immune to unknown hypervisor, hardware, browser, kernel, parser, or supply-chain vulnerabilities;
- a proof runner, image, proxy, resolver, CA, firewall, fixture service, or dependency is production-ready or may be reused;
- the production crawler, artifact pipeline, Trust Graph, verdict system, blockset, manual product, or URL Filter exists or is safe;
- arbitrary binaries, documents, downloads, live threats, captured submissions, or analyst workflows were tested safely;
- the system may scan arbitrary ports, send non-GET/HEAD traffic, submit forms, authenticate, click, upload, or bypass certificate errors;
- zero canary contact outside the frozen matrix proves complete SSRF resistance or authorizes weaker monitoring later;
- proposed 80/443, numerical resource, patch, or retention defaults became accepted production policy;
- a timeout, denial, empty result, or unavailable scanner means a page is safe or `no_known_danger`;
- S0-D Pass implies S0-A/S0-B/S0-C/S0-E/S0-F Pass, Stage 0 exit, Stage 4 completion, production availability, security certification, legal/privacy compliance, penetration-test completion, or release readiness.

Evidence expires at its approved review point and must be revalidated after any material image, browser, guest, VMM, dependency, registry, resolver, gateway, firewall, policy, fixture, topology, observer, resource, schema, or patch-state change.

## Dangerous actions explicitly forbidden

- Do not browse, search, scrape, or replay a live threat or captured submission.
- Do not probe any real, unapproved, or non-proof-scoped metadata, private/internal/production, Hezo/admin, or third-party target, or any unapproved port. Only manifest-approved synthetic Class B canaries may represent those prohibited classes.
- Do not execute hostile content on a workstation, ordinary CI runner, analyst machine, or shared-kernel production container.
- Do not give the guest direct Internet, DNS, DoH, UDP, raw socket, or opaque tunnel access.
- Do not use `--no-sandbox`, disable Site Isolation or certificate validation, add a debug trust override, install the analysis CA trust certificate outside the isolated analysis guest/gateway trust scope, place its private key outside the isolated gateway/key boundary, or put that key in the guest.
- Do not use a real secret, credential, token, identity, or production datum as a canary.
- Do not click, submit, authenticate, upload, solve a CAPTCHA, grant device permission, or open a download.
- Do not publish topology, canary endpoints, routes, raw logs/captures/artifacts, exploit detail, or incident evidence.
- Do not let crawler output write graph, verdict, or block state directly, and do not treat antivirus/YARA non-detection as safety.
- Do not patch a running image in place, roll back to mutable/unsupported state, infer Pass from zero logs or partial cases, or retain proof infrastructure/evidence by omission.

## Teardown or productionization

Every run completes [the teardown checklist](../teardown-checklist.md) through case 900 or 901. Default for Stop, Inconclusive, or any run without separately accepted productionization is Teardown.

Teardown stops schedules, retries, traffic, and metered resources; cuts egress; removes routes and temporary services; revokes identities, capabilities, certificates, CA/proxy authority, and test credentials; destroys workers, profiles, scratch, queues, caches, artifacts, captures, logs, snapshots, replicas, and backups under the approved rule; removes proof builds/dependencies/output; and verifies that no product or later proof depends on the spike. Policy-permitted restricted result/closeout evidence and its opaque index may survive only with explicit owner, access, purpose, expiry, and deletion rule.

Productionize separately requires new stage-appropriate Accepted ADRs and an implementation plan covering supported architecture, operations, data flows, dependencies, patching, capacity, observability, retention, deletion, incident response, migration, and rollback. The proof runner, shortcuts, identities, routes, CA, state, data, and privilege are not promoted. Proof-only resources not explicitly authorized by that new plan are still torn down.

## Review and gate decision

| Review | Accountable role | Required evidence | Outcome |
|---|---|---|---|
| Technical correctness | `QA role`, independent from the implementation under test | Case/vector coverage, exact versions, permitted controls, typed outcomes, repeatability, and limitations | Not reviewed |
| Security boundary | `Security role` | Prohibited-contact arithmetic, resolver/gateway/firewall, guest/host/cross-job, resource, quarantine, patch, rollback, and incident evidence | Not reviewed |
| Infrastructure and operations | `Infrastructure role` | O-002/O-006 scope, topology, identity/routes, lifecycle, cost stops, destruction, and recoverability | Not reviewed |
| Privacy and retention | `Privacy role` | Data inventory, sink canaries, public/private boundary, expiry, deletion, backups, and retained-evidence rules | Not reviewed |
| Dependencies and rights | `Legal role`, with technical input from `Operations role` as needed | Origin, license, pinning, SBOM/provenance, vulnerability, update, and fixture rights records | Not reviewed |
| Public safety | `Release role`, using a reviewer independent from the implementation and every technical reviewer | Repository scan, public artifact review, opaque-reference safety, and zero restricted findings | Not reviewed |
| Final gate decision | One designated `Security role` or `Infrastructure role`, with recorded concurrence from the other | Complete current evidence bundle, all required reviews, and completed closeout | Not decided |

Only authorized human roles may approve the plan, mark a review complete, or decide Pass, Stop, or Inconclusive. A coding agent may prepare fixtures, run authorized procedures, and summarize observed results; it may not create authority or promote its own evidence.
