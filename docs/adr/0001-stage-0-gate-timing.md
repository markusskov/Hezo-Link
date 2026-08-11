# ADR 0001: Stage 0 gate timing and decision boundaries

| Field | Value |
|---|---|
| Status | Proposed |
| Decision date | Not decided |
| Accountable role | Founder with technical and privacy decision authority |
| Required reviewers | Backend, infrastructure, iOS, security, privacy, and legal/source-rights roles |
| Scope | Stage 0 proof authorization and exit, Stage 1 entry, Stage 2 entry, and O-020 |
| Related decisions and risks | O-001 through O-008, O-014, O-018, O-020; P-009; O-010; O-011; R-001, R-004, R-005, R-007 |
| Supersedes | None |
| Superseded by | None |
| Evidence references | [Stage 0 implementation plan](../11-implementation-plan.md#stage-0--kill-risk-validation), [open-decision register](../12-risks-decisions-and-open-questions.md#open-decisions), [Stage 0 governance](../stage-0/README.md), and [repository safety boundary](../stage-0/repository-safety.md) |

## Context

The public decision register assigns O-001 and O-003 to Stage 1 and O-007 to Stage 2, while its conservative readiness rule currently treats O-001 through O-007 as unresolved Stage 0 blockers. O-020 exists so an accountable human decision resolves that timing conflict rather than allowing an implementation agent to choose the convenient interpretation.

The project also needs to distinguish three kinds of authority:

1. authority to plan and execute disposable Stage 0 proofs;
2. authority to enter Stage 1 and create product foundations; and
3. authority to enter Stage 2 and accept deliberately submitted URLs or call a production source.

A proof-scoped repository/execution choice may authorize a runnable spike without selecting the production backend, every managed service, or final retention behavior. Conversely, a proposed default, a checked-in fixture, an external request, or a successful partial proof cannot authorize the next stage.

Privacy timing needs the same separation. Stage 0 needs an approved data inventory, proof-scoped consent and disclosure material where required, and approval of the canonical MPD definition and limitations. It does not need to accept P-009's proposed production retention schedule or close the final O-010/O-011 launch copy and display decisions.

This ADR is Proposed. It records a recommendation only. Until an accountable human accepts it and the affected source-of-truth documents are updated together, the current conservative rule remains in force and O-001 through O-007 remain Stage 0 blockers.

## Decision drivers

- Invalidate Apple, source-rights, privacy, and hostile-content kill risks before product architecture makes them expensive.
- Prevent a proof harness from implicitly choosing a production repository, stack, cloud service, runner, or isolation boundary.
- Keep every Stage 0 proof bounded, reviewable, reproducible, and disposable.
- Require the decisions that materially affect proof safety before execution while deferring unrelated production lock-in.
- Keep Stage 1 from starting without its backend and managed-dependency ownership decisions.
- Keep Stage 2 from accepting raw URLs or using a production threat source without approved retention and production source authority.
- Preserve the separation between proof-scoped privacy approval and final production retention, consent, App Store, and marketing decisions.
- Make source selection, legal approval, proof completion, spend authority, and runtime enablement independent.
- Retain a fail-safe conservative block whenever decision scope or evidence is ambiguous.

## Options considered

### Option A: Require O-001 through O-007 before Stage 0 exit

Keep the current conservative interpretation permanently. This is easy to audit and prevents any deferred decision from being mistaken for permission. It also forces production backend tooling, managed-service vendors, and final raw-URL retention to be chosen before their stage needs them. That can create premature lock-in, distract from kill-risk proofs, and make a disposable proof architecture appear to be the production foundation.

This option is safe but broader than necessary if proof plans can demonstrate that a deferred decision is outside their scope.

### Option B: Separate proof authorization, Stage 1 entry, and Stage 2 entry

Require the proof-scoped repository/execution decision and every decision that protects Stage 0 execution before a proof can pass. Require O-001 and O-003 before Stage 1 entry unless an accepted repository/execution ADR already resolves them at the necessary production scope. Require O-007 and the production portion of O-008 before Stage 2.

This option aligns authority with the first stage that can exercise it. It reduces premature production choices while retaining explicit stop conditions: a proof or Stage 1 task that actually depends on a deferred decision must pause until that decision is accepted. It adds review work because each plan must state which decision scope it consumes.

### Option C: Run proofs and begin Stage 1 on proposed defaults

Allow Codex or implementers to use the documented proposals until an owner later objects. This appears fast, but a framework, cloud account, isolation tool, retention default, or provider integration would become an unreviewed de facto decision. Evidence produced under an undeclared boundary could not support a pass, and rollback could require discarding code, data, or proof results.

This option is not recommended.

### Keep the current state

Leave O-020 unresolved and preserve the blanket conservative block. No unauthorized work proceeds, but S0-A cannot unlock runnable proofs and the team cannot distinguish genuine Stage 0 prerequisites from later production decisions. More data-only fixtures would not resolve the blocked authority or produce gate evidence.

## Decision

The recommendation is **Option B: separate proof authorization, Stage 1 entry, and Stage 2 entry**.

If accepted, the timing rule would be:

### Required within Stage 0

- Before any runnable proof, an accepted, proof-scoped repository/execution decision authorizes the spike location, runtime and dependency boundary, network behavior, CI behavior, evidence handling, and teardown. It does not select a production stack unless it says so explicitly.
- Before affected infrastructure proofs, O-002 resolves the cloud, US-region, environment, network, and bounded proof-budget scope they consume. Before Stage 0 exit, its complete cloud, region, environment, network-model, and monthly-budget decision is recorded as document 12 requires.
- Before Apple device or distribution proofs, O-004 resolves Apple team, identifier, signing, and external-submission ownership without publishing restricted values.
- Before the S0-B run, O-005 has an owner-approved accountless PIR bearer-token design. The required Apple/sample and distribution evidence must support that design before S0-B or Stage 0 can pass.
- Before S0-D execution, O-006 resolves production isolation technology and patch-SLA ownership sufficiently to approve the S0-D proof boundary.
- Before S0-F execution, the Stage 0 portion of O-008 selects a qualified exact-threat candidate for proof, confirms proof-scope rights, and authorizes bounded proof spend. Before S0-F and Stage 0 can pass, the accountable roles record the viability outcome supported by the completed provider proof. Neither state grants production procurement, account, annual-budget, or runtime authority.
- Before Stage 0 exit, O-014 records the founder's manual-only go/no-go. A go decision does not waive a failed URL Filter criterion; continuing on a manual-only scope requires a separate accepted rescope ADR.
- Before S0-B can pass and before Stage 0 exit, O-018 sets validated inactivity and absolute expiry for PIR evaluation-key protocol state from the required distribution and capacity evidence.
- Before privacy-affecting proof execution, the privacy role approves its data inventory and proof-scoped preliminary consent and disclosure artifacts. Before Stage 0 exit, that role also approves the canonical MPD definition and limitations.
- Before Stage 0 exit, every required S0-A through S0-F package has a current, accountable, reviewed Pass outcome. Governance, schemas, fixtures, a submitted external request, or an unreviewed result does not substitute for an executed proof.

### Required before Stage 1 entry

- O-001 resolves backend language, framework, package manager, and monorepo tooling.
- O-003 resolves the managed queue, cache, object storage, KMS, secrets, and observability choices that Stage 1 will use.

An accepted repository/execution ADR may satisfy O-001 or O-003 only when it explicitly covers the production-scope decision, alternatives, ownership, failure behavior, and rollback. A proof-only choice does not satisfy either decision by implication.

### Required before Stage 2 entry

- O-007 resolves exact raw-URL retention, incident-hold authority, and backup deletion windows.
- The production portion of O-008 approves the applicable procurement or contract, provider account, production cost controls, and annual source budget.

Stage 1 may define and test contracts against the stricter existing privacy ceilings, but it must not accept real URLs, create a hidden retention escape, call a production source, or treat a proposed value as accepted. If any Stage 0 or Stage 1 task actually needs O-001, O-003, or O-007 earlier than the boundary above, that task stops until the applicable decision is accepted.

P-009 remains proposed until its Stage 8 privacy decision. O-010 and O-011 remain open for their final launch scopes. Stage 0 approval of a canonical metric definition, limitations, and proof-scoped preliminary material must not be represented as accepting those later decisions.

Acceptance of this ADR would resolve O-020's timing question only. It would not accept any other listed open decision, approve an ADR's implementation, authorize external testing or spending, or pass a work package or stage gate.

## Consequences

### Benefits

- Stage 0 can focus on evidence that can kill or materially rescope the product.
- Proof infrastructure cannot silently become the production stack.
- Stage 1 and Stage 2 each have explicit entry decisions tied to the first work that consumes them.
- Privacy and source-rights approvals remain purpose- and stage-scoped.
- The conservative stop rule remains available whenever a supposedly deferred decision becomes relevant earlier.
- Gate reviews can distinguish owner authority from proof evidence and from runtime enablement.

### Costs and limitations

- Proof plans and gate reviews must evaluate decision scope rather than relying on one numeric range.
- A repository/execution ADR must say explicitly whether it is proof-only or also resolves production O-001/O-003 scope.
- Some work may pause mid-stage when a deferred choice becomes materially necessary earlier than expected.
- Acceptance would require synchronized updates to documents 11 and 12; this Proposed record changes no current gate.
- This ADR does not select a language, framework, vendor, cloud, isolation product, Apple identifier, source, budget, retention duration, or public copy.

## Safety and rights impact

### Security

The recommendation preserves the requirement for an accepted execution and isolation boundary before runnable proof work. O-002 and O-006 remain Stage 0 requirements, S0-D still requires zero prohibited canary contact, and no proof may use a production route or credential. Deferring O-001/O-003 does not allow a proof tool or dependency to gain production authority.

O-007 may remain open through Stage 1 only while work stays within the stricter existing privacy ceilings and uses synthetic or reserved inputs. Any task that would persist a deliberately submitted raw URL, exercise an incident hold, or rely on a backup-deletion promise must stop for O-007. This ADR changes no verdict, block-eligibility, fail-open, or enforcement scope.

### Privacy and retention

The four production data planes, prohibited joins, consent separation, log exclusions, repository boundary, and deletion obligations do not change. Stage 0 approves only the data inventory, canonical MPD definition and limitations, and proof-scoped preliminary material needed for authorized testing. It does not approve P-009's correction window, final O-010 consent/App Store/age package, or O-011 marketing wording and placement.

Deferring O-007 grants no permission to retain raw URLs. The current conservative ceilings govern synthetic proof and contract work, and no production ingestion begins before O-007. Restricted device, Apple, privacy, security, and deletion evidence remains outside Git.

### Sources, licensing, and dependencies

Stage 0 must still establish a commercially permitted qualified exact-threat source suitable for the Stage 2 manual-check slice. Selection, legal approval, proof pass, proof spend, production procurement, provider account, annual budget, and runtime authorization remain separate. Public eligibility labels or synthetic source-rights vectors satisfy none of those states.

Real terms, contracts, provider responses, budgets, account details, credentials, and raw proof evidence remain in the restricted human-controlled store. No source connector may call a production provider before the production portion of O-008 is approved. A proof-scoped dependency is torn down or separately productionized and cannot be retained by omission.

## Migration and compatibility

While this ADR remains Proposed, no migration occurs and the conservative O-001-through-O-007 block remains authoritative.

If accepted:

1. Update document 12 to record O-020's outcome and replace the temporary blanket rule with the three timing boundaries above.
2. Update document 11's Stage 0 baseline-decision list, Stage 0 exit, and Stage 1/Stage 2 entry language in the same reviewed change so proof-scoped choices and deferred production decisions do not conflict.
3. Review every existing Proposed ADR and proof plan. Mark its repository/execution scope as proof-only or production-capable and list every decision it consumes.
4. Keep existing schemas and fixtures byte-compatible; this timing decision does not change their semantics or identities.
5. Reject any evidence bundle created under an undeclared or retrospectively inferred decision boundary.

No client, database, provider, or production migration is authorized by this ADR.

## Rollback

If acceptance later proves too permissive, or a security, privacy, infrastructure, or legal/source-rights reviewer shows that a deferred decision is required earlier, stop the affected proof or stage transition. Return to the conservative rule that treats the disputed decision as blocking, preserve only policy-permitted evidence, and complete teardown where applicable.

The accountable role must then propose a superseding ADR. Rollback is verified when no affected runner, environment, credential, endpoint, source call, raw-data flow, or Stage 1/Stage 2 task remains active under the disputed authority, and the public decision register again reflects the conservative boundary. Rollback never converts previously incomplete evidence into a pass.

## Verification

Before this ADR may move to Accepted:

- the accountable role and every required reviewer confirm the three timing lists and the stop-when-consumed-earlier rule;
- each distinct decision portion or state within O-001 through O-008, O-014, O-018, and O-020 maps to exactly one required boundary without silently changing its substantive decision; O-008's pre-proof authority, post-proof viability outcome, and pre-Stage 2 production authority remain explicitly separate;
- the privacy review confirms that Stage 0 approval does not accept P-009 or close final O-010/O-011 scope;
- the legal/source-rights review confirms the separation among O-008 pre-proof authority, post-proof viability outcome, and pre-Stage 2 production authority;
- the security/infrastructure review confirms that repository/execution and isolation decisions precede all runnable proof work;
- documents 11 and 12 have a prepared synchronized patch with no contradictory deadline or blanket-range language; and
- repository links, Markdown, and the public/private safety review pass.

After acceptance, the S0-A validator and gate review must verify:

- no proof records Pass without every decision required by its plan, a current reviewed evidence bundle, and complete closeout;
- no Stage 1 entry occurs until O-001/O-003 are accepted or explicitly satisfied by a production-scoped accepted ADR;
- no Stage 2 entry occurs until O-007 and the production portion of O-008 are accepted;
- a deferred decision becoming necessary earlier produces a stop rather than an inferred default; and
- evidence expiry, contradiction, or loss of required external state returns the applicable gate to not passed.

Acceptance of this ADR approves timing and scope boundaries only. It does not assert that any decision, implementation, proof, external request, work package, or release gate passed.

## Follow-up and review

- **Founder/technical/privacy roles:** accept, reject, or revise the recommendation; automation must leave it Proposed until that outcome is recorded.
- **Backend and infrastructure roles:** prepare the proof-scoped repository/execution ADR and state explicitly whether it also covers O-001 or O-003 production scope.
- **iOS and security roles:** ensure S0-B/S0-C plans identify O-004, O-005, O-014, O-018, Apple distribution, device, and privacy-counsel prerequisites.
- **Security and infrastructure roles:** ensure S0-D lists O-002/O-006, the exact isolated environment class, network boundary, and teardown.
- **Privacy role:** review the narrow Stage 0 approval language and the O-007/P-009/O-010/O-011 boundaries.
- **Legal/source-rights role:** review the three O-008 states—pre-proof authority, post-proof viability outcome, and pre-Stage 2 production authority—and their restricted evidence handling.
- **Documentation owner:** if this ADR is accepted, update documents 11 and 12 in the acceptance change and re-run link, Markdown, and contradiction checks.

Reconsider this recommendation if a Stage 0 proof cannot execute safely without O-001, O-003, or O-007, if Stage 1 would accept real URLs or call a production source earlier than documented, or if Apple, privacy, security, or source-rights requirements change the evidence needed at a stage boundary.
