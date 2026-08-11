# Architecture decision records

Architecture decision records (ADRs) preserve material choices and their tradeoffs. They keep an accepted choice from becoming an undocumented assumption and make later replacement explicit.

ADRs are public governance records. Use generic accountable roles and sanitized outcomes. Never include personal contact details, credentials, signing or account identifiers, exact budgets, contract terms, private submission records, live targets, device logs, or raw proof output. Follow the [repository safety boundary](../stage-0/repository-safety.md) when recording supporting evidence.

## When an ADR is required

Write an ADR before a change that:

- selects or replaces a repository, language, framework, dependency, service, storage, deployment, isolation, or delivery strategy;
- changes a trust boundary, data plane, retention rule, security control, failure mode, public claim, source right, or licensing assumption;
- resolves a proposed or open decision in [document 12](../12-risks-decisions-and-open-questions.md); or
- intentionally departs from an accepted decision or a normative requirement.

A local, reversible implementation detail within an accepted design does not need an ADR. When uncertain, raise the conflict for review instead of silently deciding it in code or generated scaffolding.

## File names and numbering

- `0000-template.md` is reserved and is never a decision.
- A decision file is named `NNNN-short-kebab-title.md`, using four decimal digits and a concise, stable title.
- Allocate the next unused number after the highest decision already committed to the target branch.
- If concurrent changes select the same number, renumber one before merge and repair every link in that change.
- Once merged, a number is permanent. Do not reuse numbers, delete historical records, or renumber records when their status changes.
- Add each decision to the record index below in the same change.

The number identifies the record; it does not indicate priority or acceptance order.

## Statuses and lifecycle

Use exactly one of these statuses in a decision record:

| Status | Meaning | Governs implementation? |
|---|---|---|
| Draft | Work in progress that is not ready for formal review. | No |
| Proposed | Complete enough for review; no accountable decision has been recorded. | No |
| Accepted | Approved by the accountable role and binding within its stated scope. | Yes |
| Rejected | Considered and explicitly not selected. | No |
| Withdrawn | Removed from consideration before an accountable decision. | No |
| Deprecated | Still records an implemented choice, but retirement or replacement is expected. Its scope and transition must be explicit. | Only for the remaining legacy scope |
| Superseded | Replaced by one or more accepted ADRs. | No |

Normal transitions are:

- Draft to Proposed or Withdrawn;
- Proposed to Accepted, Rejected, or Withdrawn;
- Accepted to Deprecated or Superseded; and
- Deprecated to Superseded.

Acceptance records decision authority, not proof that an implementation, test, external submission, or release gate passed. Only the accountable human role may move an ADR to Accepted; an automation or coding agent must not infer approval.

## Decision workflow

1. Copy [the template](0000-template.md), allocate a number, and replace every prompt.
2. Link the relevant accepted, proposed, open, and risk IDs from document 12.
3. Compare credible options, including keeping the current state where applicable. Record security, privacy, source-rights, dependency, migration, failure, and rollback effects.
4. Obtain reviews from the roles affected by the decision. Affected security, privacy, legal/source-rights, and operations boundaries require the corresponding review.
5. Have the accountable role record the outcome and decision date. Keep the record Proposed if that outcome is absent.
6. In the same change, update affected requirements, contracts, plans, tests, and the decision register. Do not use an ADR to override a stricter privacy or security invariant silently.
7. Add sanitized evidence references and unresolved verification obligations. Missing evidence remains visible; it is not a pass.

Material changes to an Accepted ADR require a new ADR. Minor corrections that do not alter meaning may edit the existing file and should be clear in version control history.

## Supersession

A replacement is complete only when all of the following happen in one reviewed change:

1. The new ADR is Accepted and lists every record it supersedes.
2. Each old ADR moves to Superseded and links back through its `Superseded by` field.
3. The new ADR explains migration, compatibility, rollback, and any intentionally retained legacy scope.
4. Affected requirements, contracts, plans, and tests are updated.

If the successor is not yet accepted or migration is incomplete, mark the old record Deprecated rather than Superseded and state which scope still governs.

## Evidence references

ADRs may cite public, sanitized repository artifacts or opaque evidence identifiers approved for disclosure. An opaque identifier is a label, not a URL or path into restricted storage. Never commit or link raw evidence merely to make an ADR self-contained. The reviewer uses the authorized private evidence index outside Git when restricted material must be inspected.

## Record index

| Record | Status | Summary |
|---|---|---|
| [0000](0000-template.md) | Template | Copy this file to create a decision record. |
| [0001](0001-stage-0-gate-timing.md) | Proposed | Historical proof-boundary recommendation; [ADR 0002](0002-local-first-product-foundation.md) now governs local product-foundation entry without accepting this proposal wholesale. |
| [0002](0002-local-first-product-foundation.md) | Accepted | Authorizes reversible local product foundations, selects Swift/Go/OpenAPI/PostgreSQL and native monorepo tooling, and keeps all external-state work gated. |
| [0003](0003-offline-manual-entry-prototype.md) | Accepted | Authorizes a transient offline manual-entry UI prototype using local syntax validation, with no network, persistence, telemetry, destination action, or gate claim. |
| [0004](0004-pinned-public-suffix-list.md) | Accepted | Pins the verbatim ICANN-and-PRIVATE Public Suffix List for bounded offline classification, with no validity, safety, ownership, network, or enforcement authority. |
| [0005](0005-pinned-iana-address-profile.md) | Accepted | Selects an exact four-registry IANA/CC0 offline address-classification profile with special-purpose precedence, explicit multicast overlays, manual reviewed updates, fail-unavailable behavior, and no enforcement claim. |
