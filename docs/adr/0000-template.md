# ADR NNNN: Decision title

> Template instructions: copy this file, replace every prompt, and remove this note. Keep the record public-safe under the [repository safety boundary](../stage-0/repository-safety.md). A template or Proposed ADR grants no implementation authority.

| Field | Value |
|---|---|
| Status | Draft, Proposed, Accepted, Rejected, Withdrawn, Deprecated, or Superseded |
| Decision date | YYYY-MM-DD, or `Not decided` |
| Accountable role | Generic role with authority for this decision |
| Required reviewers | Generic affected roles |
| Scope | Systems, stages, and decisions governed by this record |
| Related decisions and risks | IDs from [document 12](../12-risks-decisions-and-open-questions.md) |
| Supersedes | ADR numbers, or `None` |
| Superseded by | ADR numbers, or `None` |
| Evidence references | Sanitized repository paths or opaque approved IDs; never raw evidence |

## Context

Describe the problem, current constraints, and why a decision is needed now. Distinguish accepted requirements from assumptions. State what remains unknown.

## Decision drivers

- List the outcomes and constraints that matter.
- Include security, privacy, reliability, reversibility, operational ownership, source rights, and failure behavior where relevant.
- Do not use a private budget, negotiation, or vendor promise as an undisclosed driver.

## Options considered

### Option A: Short name

Describe the option and its important benefits, costs, failure modes, and unresolved proof obligations.

### Option B: Short name

Describe the option and its important benefits, costs, failure modes, and unresolved proof obligations.

### Keep the current state

Explain the consequence of deferring or making no change. Remove this subsection only when it is genuinely inapplicable.

## Decision

State the selected option and its exact scope. For a Proposed record, state the recommendation without presenting it as approved. For a Rejected or Withdrawn record, state that no option gained authority.

## Consequences

### Benefits

- Record the intended benefits.

### Costs and limitations

- Record operational burdens, constraints, lock-in, uncertainty, and deliberately unsupported cases.

## Safety and rights impact

### Security

Describe trust-boundary, threat-model, least-privilege, secret-handling, isolation, update, and fail-safe implications. State whether enforcement scope can change.

### Privacy and retention

Describe data-plane, identifier, consent, logging, deletion, backup, and public-claim implications. State explicitly when there is no change.

### Sources, licensing, and dependencies

Describe permitted use, removal/recomputation duties, dependency purpose, update policy, and behavior when the dependency is unavailable. Keep restricted commercial details outside Git.

## Migration and compatibility

Describe how existing data, clients, fixtures, contracts, and operations move to the decision. Identify staged or legacy scope and forward-safe steps.

## Rollback

Define the trigger, accountable role, safe rollback path, data consequences, compatibility constraints, and how rollback is verified.

## Verification

List the cases and evidence needed to validate the decision. Use sanitized references or opaque approved evidence IDs only. Record skipped, failed, expired, or unavailable evidence explicitly; none counts as a pass.

Acceptance of this ADR approves the choice only. It does not assert that implementation or release gates passed.

## Follow-up and review

- List required follow-up work with generic accountable roles and review points.
- State an expiry or reconsideration trigger for time-sensitive assumptions.
- Identify documents, contracts, tests, and older ADRs that must change with this record.
