# Codex implementation rules

This is a public contributor and automation policy. It is intentionally committed so human contributors and coding agents follow the same safety rules. Private blocker notes, owner contact details, device/cloud evidence, contracts, budgets, credentials, and raw proof output belong outside Git or in the ignored `.private/` directory and must never be linked from public documents.

This repository starts from a reviewed documentation baseline. Treat the documents in docs as requirements, not inspiration.

## Precedence

When instructions conflict, use this order:

1. Current user instruction
2. Security and privacy invariants in this file
3. Accepted decisions in docs/12-risks-decisions-and-open-questions.md
4. Concern-specific documents in docs
5. README.md

Do not silently resolve a material conflict. Record it as an ADR or ask the owner.

## Work only in the active phase

Follow the build order in docs/11-implementation-plan.md. Implement one reviewable vertical slice at a time. Do not scaffold future products, accounts, enterprise APIs, dashboards, machine-learning infrastructure, or global localization while building V1.

Every phase has an entry gate, deliverables, tests, and an exit gate. Stop if an exit gate fails.

## Architecture invariants

- V1 works without an account.
- Manual checks work without measurement consent, analytics consent, or URL Filter approval.
- Security intelligence, protection measurement, product analytics, and anti-abuse use separate production stores, credentials, service roles, logs, queues, and retention jobs.
- There is no general-purpose service credential that can read more than one sensitive data plane.
- The intelligence store never receives an MPD token, analytics ID, App Attest key ID, advertising ID, account ID, or stable installation ID.
- The MPD and analytics planes never receive URLs, domains, verdict IDs, report IDs, campaign IDs, or browsing events.
- App Attest assertions bind a server nonce and canonical request digest and are checked for replay.
- Raw submitted URLs are encrypted and transient. Long-term graph storage is sanitized and provenance-aware.
- Crawlers have no path to production databases, secrets, internal networks, or other crawler sessions.
- Derived decisions are versioned and replayable from immutable observations.
- Enforcement scope never exceeds evidence scope.
- URL Filter is fail open for V1 and has a remote kill switch and last-known-good rollback.

## Implementation defaults

[ADR 0002](docs/adr/0002-local-first-product-foundation.md) accepts these defaults for the bounded local foundation:

- iOS product code: Swift, SwiftUI, and Swift Package Manager for pure Swift modules.
- Backend direction: Go with Go modules; the first service slice must still decide the HTTP framework or standard-library-only approach.
- API schemas: OpenAPI 3.1 and JSON Schema with generated client/server contract tests.
- Primary intelligence store: PostgreSQL; exact version, UUID, migration, and persistence choices remain open until P-003 is accepted.
- Architecture shape: a modular control-plane service plus worker, with separate deployables introduced only at security or scale boundaries. Do not create a microservice per table.
- Repository: one public monorepo using native Swift and Go tooling unless a later ADR selects cross-language orchestration.
- Xcode: the minimal iOS app shell may compile and import the same shared core sources exposed by the root Swift package for local compiler, simulator, and owner-controlled signing setup. Keep Xcode target membership synchronized when shared source or test files change. Keep only the Team ID and final bundle identifier in ignored local configuration. Certificates, private keys, and provisioning profiles stay in Xcode-, Keychain-, or Apple-managed stores outside the repository and must never be placed in an xcconfig.

These operational defaults remain proposed until their own decisions and gates are complete:

- Apple integration: NetworkExtension, App Attest, and system QR/camera frameworks.
- Operational topology: exact deployment boundaries, environments, networking, and managed services for sandbox, URL-filter distribution, anti-abuse, MPD, and any approved analytics plane.
- Queue and object storage: managed products chosen by ADR; jobs must be idempotent and lease based.
- Browser analysis: a supported Chromium build in a disposable microVM or equivalently strong isolation boundary. Never disable the Chromium sandbox.

## Change requirements

Every implementation change must include:

- the smallest relevant tests;
- migrations that are forward safe and reversible where practical;
- structured logs that exclude URLs, query values, tokens, attestations, and page contents by default;
- metrics with bounded-cardinality labels;
- a threat-model note for new network or data flows;
- documentation updates when a contract or accepted decision changes.

No production dependency may be introduced without recording its purpose, data access, license, update policy, and failure behavior.

## Verdict safety

- Do not turn model confidence into a consumer percentage.
- Do not let an LLM or vision model auto-block.
- Do not count correlated facts as independent evidence.
- Do not make shared hosting, CDNs, registrars, certificate issuers, TLDs, or domain age proxies for guilt.
- Official-domain status suppresses impersonation evidence only; it does not create immunity from compromise.
- Community reports trigger enrichment or review and contribute only within a capped family. They never auto-block alone.
- Heuristic and campaign-propagated blocking remain feature-flagged until the benchmark gates are met.

## Safe development

- Use reserved example domains and offline fixtures in normal tests.
- Never open live malicious URLs on the developer workstation or a normal CI runner.
- Do not commit feed data, captured pages, raw URLs, screenshots, credentials, signing material, or Apple attestation artifacts.
- Do not add third-party analytics, advertising, session-replay, or crash SDKs without explicit privacy review.
- Never bypass certificate validation or ship debug trust overrides.

## Definition of done

A phase is done only when its documented acceptance criteria pass, its security and privacy boundaries are tested, failure behavior is exercised, and the relevant docs reflect the actual implementation.
