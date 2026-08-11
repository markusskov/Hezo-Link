# Stage 0 proof plan: Short title

> Template instructions: copy this file for one bounded proof, replace every prompt, and remove this note. Keep the plan public-safe under [repository safety](repository-safety.md). A completed plan authorizes no production work and proves no gate.

| Field | Value |
|---|---|
| Proof ID | `S0-X-PNN` |
| Work package | S0-A, S0-B, S0-C, S0-D, S0-E, or S0-F |
| Plan status | Draft, Ready for review, Approved to run, In progress, Evidence ready, or Closed |
| Accountable role | Generic role that can decide Pass or Stop |
| Supporting roles | Generic execution and review roles |
| Related kill risks | IDs from [document 12](../12-risks-decisions-and-open-questions.md) |
| Linked decisions | Decision IDs and ADR links, with current status |
| Proof location | Location authorized by an Accepted repository ADR, or `Not authorized` |
| Fixture manifests | Public-safe manifest IDs and repository links |
| Environment class | Local/offline, isolated security, physical-device distribution, or another reviewed class |
| Evidence-bundle reference | Planned public-safe bundle path or opaque approved ID |
| Review point | Date or event that triggers review or expiry |

## Kill-risk question

State one falsifiable question in terms that can be answered by the expected cases. Explain which product path must stop or change if the answer is negative. Do not write a broad goal such as “confirm it works.”

## Scope

### In scope

- List the smallest behaviors and boundaries needed to answer the question.

### Out of scope

- List product features, production architecture, unsupported cases, and follow-up questions this proof deliberately does not resolve.

### Assumptions and unknowns

- Separate accepted facts from assumptions.
- State the observation that would falsify each material assumption.

## Decisions and prerequisites

| Decision, ADR, approval, or access | Required state before execution | Current public-safe state | Stop action if absent |
|---|---|---|---|
| Identifier or link | Exact prerequisite | Proposed, Open, Accepted, External, or another truthful state | Do not run, narrow scope, or stop |

Do not interpret an external request, owner discussion, or plan review as an approved decision. If execution would implicitly select a repository layout, dependency, service, vendor, account, region, runner, or isolation technology, stop until the accountable role records that choice.

## Fixtures

| Fixture ID and version | Manifest or source | Purpose | Safety classification | Cleanup or retention |
|---|---|---|---|---|
| Stable synthetic ID | Repository manifest link | Case coverage | Reserved, loopback, generated, sanitized non-executable, or other approved class | Public fixture or approved restricted retention |

All ordinary local and pull-request fixtures must comply with the [Stage 0 fixture policy](../../fixtures/stage-0/README.md). Never substitute a live malicious URL, feed extract, captured submission, real credential, real attestation, or production data because a synthetic case is inconvenient.

## Environment and isolation

Describe:

- the exact environment class and why it is sufficient for the claim;
- how production routes, credentials, identities, and data are excluded;
- allowed connectivity and how all other egress is technically denied;
- resolver, proxy, boundary-canary, or loopback behavior where relevant;
- material operating-system, device, image, protocol, tool, and policy versions;
- time, request, storage, and resource limits; and
- reset steps that prevent state from one run affecting another.

Record restricted environment identifiers and access instructions outside Git. A policy statement or static scan is not evidence that network isolation worked.

## Expected cases

Include positive, negative, failure, rollback, and limitation cases needed to answer the question. Give each case a stable ID.

| Case ID | Setup and fixture | Action | Expected observable result | Safety invariant | Required evidence after execution |
|---|---|---|---|---|---|
| `S0-A-CASE-001` | Fixture and initial state | Bounded operation | Exact result before execution | Boundary or requirement protected | Sanitized result field or opaque evidence ID |

No required case may disappear after a failure. Add newly discovered cases and preserve the original result.

The current [evidence-bundle schema](evidence-bundle.schema.json) records a root run interval. Every executed case records `started_at`, `ended_at`, result `recorded_at`, optional `duration_ms`, and typed `contact_counts`; non-executed cases do not fabricate an interval and declare contact counting inapplicable with zero counters. Each cited evidence record has its own finalization time. The companion validator, not JSON Schema alone, proves chronology and that bundle contact counters equal the per-case sums.

## Gates

### Pass gate

State all conditions that must be true together. At minimum:

- every prerequisite is in its required state;
- every required case produced its expected result with no unexplained skip;
- no safety, privacy, rights, isolation, or public/private boundary invariant failed;
- evidence identifies the exact revision, fixtures, environment, versions, and deviations;
- limitations are compatible with the stated product path;
- required external states are confirmed rather than inferred;
- authorized reviewers can inspect the evidence needed for their review; and
- the teardown-or-productionization outcome is recorded.

### Stop gate

Stop execution and preserve only policy-permitted evidence when any declared stop condition occurs. Include, as applicable:

- a boundary canary receives contact or an undeclared route becomes reachable;
- a secret, personal identifier, raw URL, restricted source item, or production datum enters an unapproved sink;
- the environment, fixture, dependency, or protocol differs materially from the plan;
- a required owner decision, right, or external approval is absent or contradicted;
- the resource or request bound is exceeded;
- evidence becomes incomplete, non-reproducible, corrupted, or unsafe to retain; or
- the kill-risk assumption is falsified.

Define the immediate containment action and the product work that must remain paused. A Stop outcome can successfully answer a kill-risk question; it never counts as a passed gate.

### Inconclusive outcome

Define conditions that make the result undecidable, such as an unavailable external dependency or an invalid fixture. An inconclusive proof must be replanned and rerun; it is not rounded up to Pass.

## Evidence plan

Use [the evidence-bundle schema](evidence-bundle.schema.json) for public-safe metadata. Before execution, list the expected evidence for each case and its retention class. After execution, record:

- exact root run interval and, for every executed case, its start, end, result-recording time, optional duration, typed contact counters, revision, fixture version, and material environment versions;
- skips, retries, deviations, partial failures, and contradictory observations;
- sanitized summary or opaque approved evidence ID with the time that reference became citeable;
- evidence expiry or review deadline; and
- the role authorized to inspect any restricted underlying material.

The final review records its decision time, and a completed teardown or productionization closeout records `completed_at`. Do not put private storage paths, access URLs, raw logs, screenshots, captures, attestations, source records, identifiers, or credentials in the plan or evidence bundle.

## Limitations and unsupported claims

State what this proof cannot establish, which environments or cases it does not represent, how long its evidence remains relevant, and which marketing, security, privacy, performance, or production claims remain prohibited.

## Teardown or productionization

Use the [teardown checklist](teardown-checklist.md) and choose exactly one closeout outcome after execution:

- **Teardown:** remove the spike and its temporary resources, access, state, and restricted output under the approved retention policy; or
- **Productionize separately:** authorize a new, stage-appropriate implementation plan and ADR set. Proof code and temporary infrastructure remain nonproduction until independently reviewed and replaced or hardened.

State the default closeout if the proof stops or is inconclusive. Indefinite retention is not an outcome.

## Review and gate decision

| Review | Accountable role | Required evidence | Outcome |
|---|---|---|---|
| Technical correctness | Relevant engineering role | Cases, versions, reproducibility, and limitations | Not reviewed, Changes required, or Reviewed |
| Security boundaries | Security role when applicable | Negative cases, isolation, canaries, and containment | Not reviewed, Changes required, or Reviewed |
| Privacy and retention | Privacy role when applicable | Data inventory, sinks, deletion, and public wording | Not reviewed, Changes required, or Reviewed |
| Rights and external terms | Legal/source-rights role when applicable | Authorized restricted record and sanitized outcome | Not reviewed, Changes required, or Reviewed |
| Final gate decision | Accountable role | Complete evidence bundle and closeout | Not decided, Pass, Stop, or Inconclusive |

Record review roles and outcomes without private names or approval artifacts. A coding agent may summarize observed results but may not mark a human review complete or make the final gate decision.
