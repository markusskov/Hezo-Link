# ADR 0002: Local-first product foundation

| Field | Value |
|---|---|
| Status | Accepted |
| Decision date | 2026-08-11 |
| Accountable role | Founder |
| Required reviewers | iOS, backend, security, privacy, and infrastructure roles |
| Scope | Local product-foundation implementation, repository layout, languages, contract tooling, and the pre–Stage 0 exit local implementation boundary |
| Related decisions and risks | P-001, P-002, P-004, O-001, O-002, O-003, O-020, R-005, R-007, R-013, and R-014 from [document 12](../12-risks-decisions-and-open-questions.md) |
| Supersedes | None |
| Superseded by | None |
| Evidence references | [Implementation plan](../11-implementation-plan.md), [API contracts](../06-api-contracts.md), [repository rules](../../AGENTS.md), and the tests introduced with each implementation slice |

## Context

The documentation baseline originally barred all product foundations until every Stage 0 proof passed. That protected unresolved external and privacy boundaries, but it also prevented reversible code that neither creates external state nor consumes the blocked decisions. The accountable owner has directed implementation to begin, selected the foundation defaults below, and required blocked external work to be recorded and skipped while other work continues.

This decision does not assert that any Stage 0 proof passed or resolve O-020 for Stage 0 proof execution and exit. It creates a narrower implementation exception in which deterministic, offline product foundations may be built and reviewed before the external proof program completes.

## Decision drivers

- Produce executable product value rather than additional speculative scaffolding.
- Keep the earliest slices local, deterministic, dependency-light, and reversible.
- Avoid selecting managed services merely to compile contracts or policy code.
- Preserve all existing privacy, data-plane, log-safety, source-rights, and sandbox invariants.
- Keep Apple, provider, cloud, credential, and live-data work stopped until its own authority and evidence exist.
- Use native language tooling so Swift and Go code can be tested independently without a new monorepo framework.

## Options considered

### Option A: Progressive local foundation

Begin only the S1-A contract and URL-policy core locally while all live, paid, device-distribution, provider, crawler, database, and production-infrastructure work remains gated. Each slice must be independently useful, tested, and safe to remove.

### Option B: Preserve the full Stage 0 block

Continue producing proof plans and fixtures until every Stage 0 package passes before adding any product code. This minimizes scheduling ambiguity but blocks code that does not consume the unresolved external decisions.

### Option C: Scaffold the complete production platform

Choose every managed service and create the app, backend, database, infrastructure, and delivery system immediately. This would create premature lock-in and violate unresolved Apple, provider, isolation, privacy, and cost boundaries.

## Decision

Select **Option A: progressive local foundation**.

The accepted foundation is:

- Swift and SwiftUI for the iOS product; Swift Package Manager for pure Swift product-core modules.
- Go and Go modules for backend services; the HTTP framework or standard-library-only decision remains open until the first service slice.
- OpenAPI 3.1 and JSON Schema as the cross-language wire-contract sources.
- PostgreSQL as the initial durable intelligence store.
- A modular control plane plus worker, with separate deployables introduced only at security or scale boundaries; exact deployment and managed-service topology remains open.
- One public monorepo using native Swift and Go tooling. A cross-language build orchestrator is not selected yet.
- Local containers only when a slice needs a reproducible PostgreSQL or other approved local service.
- Terraform for later infrastructure; AWS in a US region is the intended provider direction, but exact region, network, managed services, and deployment remain separate decisions.

The repository may now implement the bounded S1-A foundation before the complete Stage 0 exit: shared contract values, error envelopes, parsing and redaction, offline fixtures, URL-policy interfaces, and tests. The first slice is a dependency-free Swift contract core. Database migrations, persistence, and replay infrastructure remain outside this exception until their own decisions and stage entry are complete. O-020 remains open for the Stage 0 proof-timing and exit rules; this exception is not authority to execute a proof.

The following remain unauthorized until their own gates are complete:

- cloud resources, public endpoints, production routes, paid API calls, and provider accounts;
- Apple entitlement requests, signing changes, device or TestFlight execution, OHTTP/PIR onboarding, and App Attest service calls;
- live or captured threat inputs, raw evidence, production credentials, and crawler execution;
- product analytics or any cross-plane identifier;
- retention behavior that exceeds the strict existing ceilings; and
- Stage 2 production-source integration or a user-facing release.

An owner-controlled external-spend ceiling exists in the private decision record. Public code and tests must not depend on its exact value. Any slice that could create external cost pauses before doing so.

## Consequences

### Benefits

- Product contracts and policy primitives become executable and reviewable immediately.
- Swift and Go can converge on the same wire values without waiting for managed infrastructure.
- Blocked Apple, source-rights, and sandbox work no longer stalls unrelated local foundations.
- The first batches have no third-party runtime dependency or external data flow.

### Costs and limitations

- Stage 0 and Stage 1 can now overlap, so every PR must state which blocked decisions it does not consume.
- Cross-language generation, local PostgreSQL, and Go service layout still require later slices.
- O-001 remains open only for the Go HTTP framework and any cross-language build orchestration not covered by native SwiftPM and Go commands.
- O-003 remains open for managed queue, cache, object storage, KMS, secrets, and observability choices.
- Exact AWS region/network and all deployment details remain open.
- This decision does not authorize a consumer UI, production API, vendor connector, or release.

## Safety and rights impact

### Security

Early code runs offline and uses synthetic or reserved inputs. It must not weaken URL validation, verdict separation, fail-open behavior, App Attest boundaries, or sandbox isolation. New network or persistence flows still require a threat-model note and their stage-specific authority.

### Privacy and retention

The four data planes and prohibited joins remain unchanged. This decision authorizes no collection. Early tests use no account, URL history, MPD contribution, analytics event, advertising identifier, attestation material, or raw proof evidence. No new retention window is created by scaffolding.

### Sources, licensing, and dependencies

The first Swift slice has no third-party dependency. Later dependencies require purpose, data access, license, update policy, failure behavior, and removal review. No provider is called merely because a connector or schema exists.

## Migration and compatibility

The documentation-only repository gains a root Swift package first. Later iOS targets may import the product-core module without making it the app bundle or URL Filter extension. Go services, shared contract sources, database files, and infrastructure use separate top-level paths when their slices begin.

Existing Stage 0 plans and fixtures remain valid as proof contracts. Their Draft and Not-decided states do not become favorable merely because local product code exists.

## Rollback

If the selected foundation proves unsuitable, stop after the current safe batch, preserve contract fixtures, and supersede this ADR before changing languages or repository layout. The root Swift package is removable without deleting production data because this phase creates none. No external resource may be retained by omission.

## Verification

- Every new Swift and Go package builds from a clean checkout with native tooling.
- Tests are deterministic, offline, and use no credentials or live targets.
- Contract values round-trip with exact documented wire spellings.
- Security-sensitive descriptions and logs exclude attacker-controlled detail.
- Static review, dependency review, secret scanning, and the smallest relevant tests pass for each batch.
- Stage 0 status remains truthful and no implementation PR claims a proof or release gate passed.

Acceptance of this ADR approves the choice only. It does not assert that implementation, Stage 0, Stage 1, or release gates passed.

## Follow-up and review

- iOS and backend roles review every shared contract before cross-language generation is declared complete.
- Infrastructure records exact AWS region, network, managed-service, and deployment choices before creating cloud state.
- Security and privacy review the first new network or persistence flow before it runs.
- Reconsider this ADR if native tooling becomes inconsistent, a slice needs external state earlier than planned, or the owner changes the implementation or cost boundary.
