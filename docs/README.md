# Hezo Link documentation

This directory is the implementation source of truth for V1.

## Reading order

| Document | Question it answers |
|---|---|
| [01 Product and scope](01-product-and-scope.md) | What are we building, for whom, and what is excluded? |
| [02 Privacy and measurement](02-privacy-and-measurement.md) | What data may exist, where, why, and for how long? |
| [03 Trust Graph and verdicts](03-trust-graph-and-verdicts.md) | How does evidence become an explanation, verdict, and block decision? |
| [04 System architecture](04-system-architecture.md) | Which deployables, jobs, and trust boundaries exist? |
| [05 Data model](05-data-model.md) | How is durable intelligence represented in PostgreSQL? |
| [06 API contracts](06-api-contracts.md) | What do app and service boundaries exchange? |
| [07 Apple platform](07-apple-platform.md) | What must be proved for URL Filter and App Attest? |
| [08 Sandbox and security](08-sandbox-and-security.md) | How are hostile sites analyzed without exposing Hezo? |
| [09 Intelligence sources](09-intelligence-sources.md) | What can seed the product, and under what rights? |
| [10 Testing and benchmarks](10-testing-and-benchmarks.md) | What evidence is required before release or auto-blocking? |
| [11 Implementation plan](11-implementation-plan.md) | In what order should Codex build and verify the system? |
| [12 Decisions and risks](12-risks-decisions-and-open-questions.md) | What is accepted, proposed, unresolved, or capable of killing the plan? |

## Requirement language

- Must and must not are release requirements.
- Should is the recommended default; deviation needs a documented reason.
- May is optional.
- Proposed means an ADR or owner decision is still required.

## Precedence and change control

AGENTS.md defines repository-wide invariants. Accepted decisions in document 12 resolve architectural ambiguity. A more specific document overrides a general summary, but it may not override a privacy or security invariant without an explicit decision record.

When implementation changes a contract:

1. Add or update an ADR.
2. Update the relevant document and OpenAPI/schema source of truth.
3. Add a regression test for the changed assumption.
4. Record migration, rollback, privacy, and licensing impact.

## Resolved baseline decisions

This handoff resolves several early-draft contradictions:

- Do not strip query parameters or fragments before analysis. They may carry payloads or redirect destinations. Sanitize only for retention and provider-specific canonical forms.
- A rotating identifier is pseudonymous while it exists. The implementation may be privacy preserving, but public language must not call it unconditionally anonymous.
- “Likely safe” is replaced with “No known danger.”
- An allowlist does not grant immunity. Official-domain evidence suppresses impersonation signals only; an exact malware or compromise signal can still win.
- A Dangerous verdict and an automatic block are separate decisions.
- Heuristic and campaign-propagated auto-blocking are staged behind stronger gates than exact, qualified threat-feed matches.
- Product analytics is a separate fourth plane, not a hidden extension of MPD measurement.

## Documentation completion rule

No placeholder such as TBD is permission to guess. Open decisions are collected in document 12 with a responsible owner and a required decision point.
