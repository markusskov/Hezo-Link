# Stage 0 spike teardown checklist

Every Stage 0 spike ends with an explicit teardown or separate productionization decision, including spikes that pass, fail, stop early, or remain inconclusive. Completion of a proof run does not authorize persistent infrastructure, active credentials, scheduled work, production data, or reuse by later product code.

Copy this checklist into the proof closeout record and replace every prompt. Keep restricted resource inventories, deletion receipts, device logs, and raw evidence outside Git under the [repository safety boundary](repository-safety.md).

| Field | Value |
|---|---|
| Proof ID and work package | Stable IDs |
| Spike location | Path authorized by the applicable ADR |
| Accountable role | Generic role |
| Execution stopped at | Timestamp or `Not run` |
| Evidence-bundle reference | Public-safe path or opaque approved ID |
| Gate outcome | Pass, Stop, Inconclusive, or Not decided |
| Closeout outcome | Teardown or Productionize separately |
| Closeout review date | Date or `Not reviewed` |

## Common closeout checks

- [ ] Stop proof processes, schedules, retries, and external requests before changing or deleting their environment.
- [ ] Record every required case as passed, failed, skipped, or not run; preserve limitations and contradictory results.
- [ ] Identify the exact revision, fixture manifests, material versions, and declared environment in the evidence metadata.
- [ ] Confirm the spike never received production credentials, production data, or an undeclared production route. Record any violation as a stopped proof and escalate privately.
- [ ] Inventory temporary environments, identities, credentials, registrations, routes, storage, queues, logs, artifacts, caches, local state, and third-party resources in the restricted closeout record.
- [ ] Classify each retained item by purpose, owner role, approved location, expiry, and deletion rule. Indefinite retention is not permitted by omission.
- [ ] Move no raw evidence into Git. Publish only the reviewed sanitized outcome or opaque evidence ID.
- [ ] Check the repository and proposed artifacts for secrets, signing material, raw URLs, source rows, captures, logs, device/account identifiers, and build output.
- [ ] Record the chosen closeout outcome below. A missing closeout decision leaves the proof open and unable to support a gate pass.

## Outcome A — teardown

Choose this outcome when the spike will not become a supported implementation, when it failed or is inconclusive, or when productionization has not been explicitly authorized.

- [ ] Disable and remove temporary execution, scheduling, endpoints, routes, registrations, and external integrations through the authorized owner process.
- [ ] Revoke temporary credentials, capabilities, certificates, tokens, and test identities; verify they no longer grant access.
- [ ] Delete transient inputs, state, queues, artifacts, logs, captures, caches, snapshots, replicas, and backups according to their approved retention and deletion rules.
- [ ] Remove temporary dependencies and generated build output. Retain source or fixtures only when an Accepted repository decision permits them and their continuing owner and purpose are explicit.
- [ ] Confirm that no product code, later proof, or environment depends on the removed spike.
- [ ] Confirm that metered or scheduled resources have stopped and no unattended resource remains.
- [ ] Record private deletion/revocation evidence and publish only a sanitized closeout result or opaque approved reference.
- [ ] Have the accountable role review residual access, retained records, limitations, and follow-up regressions.

## Outcome B — productionize separately

Choosing this outcome authorizes planning a supported implementation; it does not promote the spike itself and does not bypass the staged implementation order.

- [ ] Link the Accepted ADRs that authorize architecture, dependencies, data flows, ownership, operations, and failure behavior.
- [ ] Open a separate, stage-appropriate implementation plan with entry gate, tests, migration, rollback, and review. Stage 1 work remains blocked until the full Stage 0 exit gate passes.
- [ ] Identify each spike component as discard, reimplement, or review for reuse. Temporary privilege, shortcuts, debug controls, synthetic assumptions, and proof-only infrastructure default to discard.
- [ ] Review every retained dependency for purpose, data access, license, update and vulnerability policy, operational owner, and unavailable/degraded behavior.
- [ ] Replace proof credentials, identities, endpoints, isolation, and state with least-privilege, environment-separated production designs; never copy raw proof data forward.
- [ ] Complete threat-model and privacy/data-flow review, including logs, metrics, retention, deletion, backups, source removal, and cross-plane negative tests.
- [ ] Add deterministic tests for expected, failure, rollback, security, privacy, and boundary cases. Proof evidence alone is not a regression suite.
- [ ] Define supported deployment, observability, incident response, patching, capacity controls, kill switches, and accountable operations.
- [ ] Rehearse migration and rollback without relying on the temporary spike environment.
- [ ] Tear down all proof-only resources and access not explicitly covered by the production plan.
- [ ] Record a sanitized productionization decision and the still-open implementation gates. Do not describe the capability as production-ready before those gates pass.

## Final review

| Review question | Outcome and public-safe reference |
|---|---|
| Did the accountable role select exactly one closeout outcome? | Not reviewed, Changes required, or Reviewed |
| Are all temporary resources and access removed or explicitly governed by the separate production plan? | Not reviewed, Changes required, or Reviewed |
| Did retention, deletion, rights, privacy, and security owners review their applicable items? | Not reviewed, Changes required, or Reviewed |
| Can the evidence bundle and sanitized closeout be reproduced without raw restricted material? | Not reviewed, Changes required, or Reviewed |
| Are limitations and remaining blockers visible, without claiming later gates passed? | Not reviewed, Changes required, or Reviewed |

The proof is not closed, and cannot support a Stage 0 pass, until the final review is complete. If teardown verification is unavailable or productionization prerequisites are only proposed, record the proof as open, stopped, or inconclusive as appropriate.
