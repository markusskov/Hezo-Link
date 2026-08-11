# ADR 0003: Offline manual-entry UI prototype

| Field | Value |
|---|---|
| Status | Accepted |
| Decision date | 2026-08-11 |
| Accountable role | Founder |
| Required reviewers | iOS, security, and privacy roles |
| Scope | Owner-local, offline manual-entry UI prototyping in the existing iOS app shell before the complete Stage 0 exit |
| Related decisions and risks | D-003, D-004, D-012, D-013, D-021, P-001, P-012, O-007, O-020, R-001, and R-007 from [document 12](../12-risks-decisions-and-open-questions.md) |
| Supersedes | None |
| Superseded by | None |
| Evidence references | [ADR 0002](0002-local-first-product-foundation.md), [implementation plan](../11-implementation-plan.md), [repository rules](../../AGENTS.md), [local URL validator](../../Sources/HezoLinkCore/ManualURLInputValidator.swift), and [validator tests](../../Tests/HezoLinkCoreTests/ManualURLInputValidatorTests.swift) |

## Context

[ADR 0002](0002-local-first-product-foundation.md) authorizes an inert iOS shell and deterministic offline foundations, but explicitly excludes a consumer feature flow. The owner has now authorized one further reversible slice: a local manual-entry screen that exercises the existing pure URL syntax validator and presents a bounded, content-free status.

This change needs its own decision because it deliberately crosses ADR 0002's inert-shell boundary. It does not enter Stage 2, perform a threat check, or assert that any Stage 0 proof, product, distribution, or release gate passed.

## Decision drivers

- Exercise the first manual-entry interaction without waiting for external systems.
- Reuse the reviewed local validation and redaction boundary rather than duplicate URL parsing in the view.
- Keep deliberately entered URL content transient and out of logs, telemetry, and durable storage.
- Avoid presenting syntax acceptance as evidence that a destination is safe.
- Keep the prototype removable without data or service migration.

## Options considered

### Option A: Bounded offline interaction prototype

Add one manual-entry surface to the existing shell. Validate only in process, present only finite content-free status, and create no network, persistence, provider, entitlement, or distribution behavior.

### Option B: Retain the inert diagnostics shell

Wait until Stage 2 before implementing any interaction. This preserves the previous boundary but delays useful UI, accessibility, and state-flow feedback that can be obtained safely offline.

### Option C: Begin the connected manual-check flow

Add provider calls, verdicts, share or QR intake, history, or navigation now. This would consume unresolved Stage 0 and Stage 2 decisions and could create misleading product behavior, so it is not authorized.

## Decision

Select **Option A: bounded offline interaction prototype**.

The existing iOS shell may provide:

- one manually editable URL field, including ordinary user-initiated paste through the system text-editing control;
- one explicit action that invokes the existing in-process `ManualURLInputValidator`;
- the closed set of content-free local states: neutral, syntax accepted, unsupported port, invalid URL, unsupported scheme, and input too long; and
- transient view state and deterministic tests using reserved or synthetic inputs.

The editable field may display what the user deliberately entered. Status, error, debug, reflection, accessibility-status, and test-diagnostic surfaces must not repeat the URL, host, query, fragment, or parser diagnostics. Syntax acceptance means only that the input passed the current local syntax profile; it is not a safety verdict, destination-eligibility result, provider match, or navigation capability.

The prototype must not add or perform:

- network access, API construction, provider/source calls, cloud state, database access, or crawler work;
- app-managed persistence, recent-check history, restoration of submitted content, or background processing;
- product analytics, protection measurement, telemetry events, or identifiers;
- automatic or programmatic clipboard reads;
- share-extension intake, QR or camera intake, destination preview, link opening, or navigation to the submitted URL;
- consumer verdicts, evidence, reports, or safety claims;
- URL Filter, Network Extension, App Attest, new entitlements, or capability work; or
- TestFlight, external distribution, release, production-readiness, stage, proof, or gate claims.

This ADR extends ADR 0002 only for the exact prototype above. ADR 0002 continues to govern the surrounding foundation and is not superseded.

## Consequences

### Benefits

- The manual-entry layout, focus, validation trigger, accessibility, and local state transitions become reviewable.
- Existing validation and content-free problem types gain a real offline consumer without creating a connected data flow.
- No external dependency, service, account, or retained dataset is created.

### Costs and limitations

- The screen cannot tell a user whether a URL is safe, dangerous, reachable, supported by a provider, or eligible for navigation.
- User-initiated paste is supported only through normal text editing; the app cannot proactively inspect the clipboard.
- Stage 2 must still implement the connected manual-check contract, provider behavior, verdict display, share/QR intake, and optional history under its own gates.
- This decision does not authorize an externally distributed or release-quality interface.

## Safety and rights impact

### Security

The prototype creates no new network or service trust boundary. The existing validator remains a syntax preflight only. An accepted value cannot be treated as an authorization to resolve, fetch, preview, open, or otherwise contact a destination. Submitted content and parser detail must not enter logs or diagnostics.

### Privacy and retention

The app receives only text deliberately entered in the visible field. It performs no automatic clipboard inspection, analytics, measurement, or transmission. The submission and status exist only in transient process/view state; the app must not write them to preferences, files, databases, caches, restoration state, or history. Clearing or discarding the view removes the app's live reference, but this decision makes no process-memory zeroization claim.

No production retention window is selected, and O-007 remains open for Stage 2.

### Sources, licensing, and dependencies

The prototype uses the existing SwiftUI/system frameworks and first-party URL validator. It adds no provider, feed, third-party runtime dependency, source right, attribution duty, or update channel. If the validator cannot be linked, the prototype must fail to build rather than substitute a permissive parser.

## Migration and compatibility

The existing diagnostics-only shell gains or is replaced by the bounded manual-entry surface. The shared core contracts, URL syntax profile, wire schemas, fixtures, signing configuration boundary, and Stage 0 proof artifacts do not change. There is no data migration because the prototype persists nothing.

## Rollback

If implementation reveals network access, persistence, content leakage, misleading safety copy, or a need for any excluded capability, stop the prototype and restore the inert diagnostics shell. Remove the prototype view and its tests; no user data, service, provider, or database cleanup should be necessary. The iOS owner verifies rollback with a clean offline build and a static review for residual state or capability changes.

## Verification

- Build and exercise the screen without network or credentials.
- Test every finite status, repeated submission, clearing, and view recreation with reserved, synthetic, and invalid inputs.
- Use a sensitive canary to verify that status, error, debug, reflection, accessibility-status, and test-diagnostic output never contains submitted content outside the editable field.
- Verify that view recreation restores no URL or status and that the app writes no submission or history.
- Review the implementation for automatic clipboard access, URL opening, network APIs, persistence APIs, analytics, provider code, URL Filter, App Attest, entitlement, and capability changes; none is permitted.
- Keep all copy explicit that the result is local syntax status rather than a safety verdict.
- Run repository Markdown-link, ADR-index, table, diff, and smallest relevant build/test checks.

Acceptance of this ADR approves the bounded prototype only. It does not assert that implementation, Stage 0, Stage 1, Stage 2, proof, distribution, release, or production gates passed.

## Follow-up and review

- **iOS role:** implement and test the bounded state machine without adding an independent URL parser.
- **Security and privacy roles:** confirm content-free output, transient state, and absence of connected or persistent behavior.
- **Product role:** keep copy limited to syntax status and defer verdict/evidence language to Stage 2.
- Reconsider this decision before adding any data flow, retained state, clipboard inspection, intake channel, destination action, safety result, entitlement, or external distribution.
