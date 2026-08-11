# Stage 0 governance

Stage 0 exists to invalidate product kill risks before they become production architecture. Its proofs are narrow, disposable, and independent of later product foundations. They use synthetic or reserved data, declare their owner and falsifiable question, and end with a teardown-or-productionization decision.

No work package, stage, or release gate passes without complete, reviewable evidence. A plan, a successful partial case, absence of an observed failure, an external request submission, or an unreviewed result is not a pass. Missing, skipped, expired, inaccessible, or contradictory required evidence leaves the gate not passed.

## Work-package map

S0-A starts first. S0-B through S0-F may proceed independently after the decisions and access required by each proof are ready. Stage 1 remains blocked until the complete [Stage 0 exit gate](../11-implementation-plan.md#stage-0-exit-gate) passes.

| Package | Purpose and kill-risk question | Accountable roles | Required evidence family |
|---|---|---|---|
| S0-A — Decision and proof harness | Can independent proofs be planned, reviewed, and closed without selecting production architecture implicitly or exposing restricted material? | Founder plus iOS, backend, infrastructure, privacy, and security roles | ADR governance, proof and evidence formats, synthetic fixture policy, public/private boundary, teardown rules, and an approved repository/execution decision before runnable harness work |
| S0-B — URL Filter proof | Is there a credible accountless, fail-open development and distribution path with correct private lookup, coverage, rollback, and protocol-state expiry? | iOS role plus the external-submission role | Physical-device cases, synthetic blockset manifest, allowed/denied/false-positive/outage/rollback behavior, coverage limits, and external dependency state |
| S0-C — App Attest proof | Can an installation prove app integrity with body binding and replay resistance while forwarding no attestation identity into intelligence? | iOS role plus backend security role | Environment-separated lifecycle, attestation/assertion validation, counter and replay cases, reinstall/failure behavior, reduced-trust behavior, and subjectless capability output |
| S0-D — Sandbox boundary proof | Can hostile-content analysis run disposably with no secret, production route, direct resolver/Internet bypass, or boundary-canary contact? | Security and infrastructure roles | Controlled egress and address-classification cases, redirect/rebinding/subresource denials, resource limits, typed failures, isolation checks, and zero canary contact |
| S0-E — Privacy and measurement proof | Can the four data planes, optional consents, rotating measurement, withdrawal, logging, and deletion rules be demonstrated without identity or browsing joins? | Privacy role plus iOS and backend roles | Data inventory, prohibited-field and join checks, consent states, month/reset/withdrawal vectors, log canaries, deletion/backup behavior, and reviewed wording limitations |
| S0-F — Source-rights and provider proof | Is at least one commercially permitted qualified exact-threat source suitable for the Stage 2 manual-check slice and operable under explicit rights, expiry, quota, cost-control, attribution, and outage rules? | Founder/legal plus intelligence and backend roles | Rights decisions, restricted terms review, reserved provider fixtures, quota/freshness/outage cases, and proof that unresolved sources stay disabled |

The table assigns generic roles, not private individuals. External requests, contracts, legal opinions, and owner choices remain human-controlled; automation may prepare a sanitized record but must not invent an outcome or treat submission as approval.

## Governance artifacts

- [ADR policy and index](../adr/README.md) records owner-approved material decisions and supersession.
- [Proof-plan template](proof-plan-template.md) defines the question, prerequisites, fixtures, environment, expected cases, pass/stop gates, limitations, evidence, closure, and review for one proof.
- [Evidence-bundle schema](evidence-bundle.schema.json) defines the public-safe evidence metadata contract. Raw evidence remains outside Git.
- [Fixture catalog and policy](../../fixtures/stage-0/README.md) governs deterministic, synthetic, reserved, and offline inputs.
- [MPD v1 public synthetic vectors](../../fixtures/stage-0/mpd/month-token-vectors.json) cover only the data-only, stack-neutral portion of S0-E; their manifest expressly records that no runnable proof or package pass is claimed.
- [Source-rights and provider-policy synthetic vectors](../../fixtures/stage-0/source-rights/README.md) cover only the data-only, stack-neutral portion of S0-F; fictional eligible states are test inputs and cannot evidence a real rights decision, provider exercise, package pass, or production authorization.
- [Repository safety](repository-safety.md) defines what may cross the public/private boundary.
- [Teardown checklist](teardown-checklist.md) closes every spike, including failed and inconclusive ones.

This governance batch does not choose a runnable spike root, repository layout, delivery service, runner, language, cloud, or production dependency. A proof plan must name its eventual location, but no runnable root may be created until an Accepted ADR authorizes the repository and isolated-execution strategy. The proof location must remain visibly separate from product code and must not become a dependency that a later stage is forced to keep.

## Proof lifecycle

1. **Plan:** Copy the proof-plan template and state one falsifiable kill-risk question, its accountable role, linked decisions, prerequisites, and stop conditions.
2. **Authorize:** Resolve required owner decisions and obtain environment/access approval. Plan approval authorizes only the bounded proof; it does not pass its gate.
3. **Prepare:** Select only approved fixture manifests. Ordinary local or pull-request execution uses reserved, loopback, synthetic, generated, or specifically sanitized non-executable inputs; it never opens a live malicious target.
4. **Execute:** Run only in the environment declared by the plan. Stop on boundary, privacy, rights, scope, credential, or evidence-integrity violations.
5. **Record:** Produce evidence metadata conforming to the evidence-bundle schema. Keep raw device, cloud, legal, source, and security evidence private, referenced only by an approved opaque ID.
6. **Review:** Compare every required case with its expected result. Record failures, skips, limitations, external states, and contradictory observations; none may be hidden by an aggregate result.
7. **Close:** Choose teardown or separate productionization and complete the teardown checklist. Proof code is never promoted merely because the proof answered its question.
8. **Decide:** The accountable role records Pass, Stop, or Inconclusive against the cited evidence. Only reviewed Pass outcomes may support the Stage 0 exit decision.

A Stop outcome is useful Stage 0 learning, but it is not a passed gate. An Inconclusive outcome requires a new or revised plan rather than a favorable interpretation.

## Minimum evidence rule

Evidence supporting a proof outcome must identify, at minimum:

- the proof and work-package IDs;
- the exact source revision and relevant artifact or image digests;
- fixture manifest IDs and versions;
- the declared environment class and material version information;
- every required case and its pass, fail, skipped, or not-run result;
- boundary-canary results when the proof has an isolation claim;
- the state of any required external decision or approval;
- limitations, deviations, expiry, and unresolved contradictions;
- sanitized or opaque references to the underlying evidence;
- review outcomes by generic accountable roles; and
- the teardown or productionization outcome.

Evidence that cannot be reproduced, authenticated, reviewed by an authorized role, or retained under its approved policy cannot support a pass.

The evidence schema records one proof per bundle. It rejects undeclared fields, raw evidence payloads, a passing decision with a required failed, skipped, unrun, or not-applicable case, an unreviewed final decision, an incomplete closeout, and any nonzero prohibited S0-D contact count. Schema validation alone never promotes a result.

### Companion validator gate

The S0-A harness must provide a separate semantic and leak validator before any evidence bundle may record Pass, Stop, or Inconclusive. That validator must:

- require the proof ID, work-package ID, and every case-ID prefix to agree;
- prove all IDs are unique and every revision, fixture, environment, evidence, limitation, decision, review, and closeout reference resolves to the expected type;
- parse every timestamp as a real RFC 3339 UTC instant, rejecting impossible calendar dates rather than checking shape alone;
- enforce coherent chronology and freshness at both final-decision time and every later gate consumption: review and evidence timestamps must follow the recorded run, `review_due_at` must still be current, any `evidence_expires_at` must be absent or in the future, and external states must remain within their approved freshness policy; an expired or overdue bundle reverts to unusable evidence until it is rerun or re-reviewed;
- recompute every cited public file digest and size and validate every fixture against its declared manifest and grammar;
- prove required case coverage is complete and derive the permitted gate outcome from case results, required external states, open limitations, reviews, and closeout state;
- accept a skipped or not-applicable exception only when its cited decision is Accepted, unexpired, and explicitly covers that case;
- recompute S0-D contact totals from case evidence and require every prohibited contact count to be zero for a pass;
- scan every string and referenced public artifact for secrets, contact details, local/private paths, live targets, account/device/application identifiers, raw URLs or submissions, attestation material, and other restricted values; and
- reject opaque evidence IDs that encode a provider, location, target, person, account, or enumerable restricted identifier.

The evidence bundle must identify the exact validator revision and sanitized validation result. It also requires a successful repository leak scan and human public-safety review. Until both records pass with zero findings, the schema permits only `not_decided`; no package gate may consume the bundle.

## Stage 0 exit

Package-level evidence does not replace the cross-package exit criteria in [document 11](../11-implementation-plan.md#stage-0-exit-gate) or the owner outcomes required by [document 12](../12-risks-decisions-and-open-questions.md#definition-of-ready-for-implementation). Stage 0 remains open until every required decision and proof is both evidenced and reviewed. Stage 1 product scaffolding must not be used to compensate for a failed, blocked, or missing Stage 0 proof.
