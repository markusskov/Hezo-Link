# Hezo Link

Hezo Link is an iPhone-first phishing, scam-link, and malicious-URL protection product. Its consumer promise is simple:

> Know before you trust a link.

The long-term company asset is not a generic “AI scam detector.” It is an evidence-backed Trust Graph that connects URLs, domains, infrastructure, brands, page artifacts, and scam campaigns. AI may extract or explain evidence; it does not get to invent the verdict.

This repository contains the reviewed implementation handoff, public governance artifacts for Stage 0 risk proofs, and the bounded offline product foundation authorized by [ADR 0002](docs/adr/0002-local-first-product-foundation.md).

## V1 in one minute

| Decision | V1 |
|---|---|
| Platform | iPhone, minimum iOS 26 |
| Initial launch | United States; English and US impersonation patterns first |
| Price | Free |
| Account | None required or offered |
| Manual protection | Paste a URL, share a URL, or scan a QR code |
| Passive protection | Apple Network Extension URL Filter, subject to capability approval |
| Results | No known danger, Caution, Dangerous, or Unknown, with evidence |
| Reports | Report a scam or an incorrect verdict |
| Recent checks | On-device only by default |
| Measurement | Optional, consented, rotating Monthly Protected Device measurement |
| Product analytics | Optional and separate from security intelligence |
| Fail behavior | Fail open if private filtering infrastructure is unavailable |

V1 is not a VPN, antivirus suite, password manager, caller-ID product, email/SMS inbox scanner, breach monitor, identity-monitoring bundle, or AI chatbot.

## Architecture at a glance

~~~text
Manual check / share / QR
            |
            v
     Check API and cache
       |             |
     known         unknown
       |             |
       |       enrichment + isolated crawl
       |             |
       +------> observations
                     |
              graph relationships
                     |
                  signals
                     |
             versioned verdict
                     |
              blockset compiler
                |         |
           Bloom filter   PIR database
                \         /
             Apple URL Filter
~~~

Four data planes are intentionally non-joinable in production:

1. Security intelligence: deliberately submitted URLs, reports, evidence, entities, and campaigns.
2. Protection measurement: consented, rotating monthly protection receipts.
3. Product analytics: consented coarse product events, with no URLs.
4. Anti-abuse: App Attest material, counters, rate limits, and short-lived capabilities.

No service role may join these planes. A rotating identifier is still pseudonymous while it exists, so public privacy language must describe the mechanism accurately rather than promise magical anonymity.

## Read this first

The implementation handoff is split by concern:

1. [Product and V1 scope](docs/01-product-and-scope.md)
2. [Privacy, analytics, and Monthly Protected Devices](docs/02-privacy-and-measurement.md)
3. [Trust Graph and verdict policy](docs/03-trust-graph-and-verdicts.md)
4. [System architecture and services](docs/04-system-architecture.md)
5. [PostgreSQL data model](docs/05-data-model.md)
6. [API contracts](docs/06-api-contracts.md)
7. [Apple URL Filter and App Attest](docs/07-apple-platform.md)
8. [Sandboxing and security](docs/08-sandbox-and-security.md)
9. [Seed intelligence and licensing](docs/09-intelligence-sources.md)
10. [Testing and benchmarks](docs/10-testing-and-benchmarks.md)
11. [Staged implementation plan and Codex build order](docs/11-implementation-plan.md)
12. [Decisions, risks, and open questions](docs/12-risks-decisions-and-open-questions.md)

[Documentation index](docs/README.md) explains precedence and maintenance. Stage 0 proof work uses the public [ADR process](docs/adr/README.md), [proof governance](docs/stage-0/README.md), and [offline fixture policy](fixtures/stage-0/README.md); owner-only decisions and raw evidence remain outside Git.

Codex must also follow [AGENTS.md](AGENTS.md). It converts the handoff into repository-level implementation rules and prevents premature expansion.

## Non-negotiable engineering principles

- Preserve the exact submitted URL for security analysis in encrypted transient storage. Query strings and fragments can contain redirect targets or payload selectors. Sanitize only for long-term retention.
- Store observations and provenance as the durable asset. Graph relationships, signals, scores, verdicts, and blocksets are versioned derived products that must be reproducible.
- Treat internal risk numbers as policy scores, not probabilities and not consumer copy.
- Never auto-block from domain age, registrar, TLD, ASN, hosting provider, IP, certificate issuer, URL length, keywords, community reports, visual similarity, logo similarity, typo similarity, geography, or an AI classification alone.
- Match enforcement scope to evidence scope. Evidence about one path on a shared host must not block the host.
- Keep Dangerous separate from block eligible.
- Use “No known danger,” never the absolute claim “Safe.”
- Keep manual checking fully usable without URL Filter approval, an account, analytics consent, or MPD consent.
- Never place an App Attest key, MPD token, analytics identifier, advertising identifier, or account identifier in a security-intelligence request or record.
- Treat every crawled URL, document, response, screenshot, and parser input as hostile.

## Before live or externally connected implementation starts

Phase 0 is a set of kill-risk validations, not product construction:

- Submit the Apple URL Filter capability request and record its status.
- Prove the development URL Filter flow with a small synthetic blockset.
- Prove App Attest registration, assertion verification, replay protection, and key reset behavior.
- Prove the crawler cannot reach private, link-local, metadata, or internal destinations through direct requests, redirects, DNS rebinding, or IPv6 encodings.
- Confirm commercial rights for every production threat source.
- Approve the Stage 0 privacy data-flow inventory and canonical MPD definition and limitations, without accepting P-009 or closing the final O-010/O-011 launch decisions.
- Record stack and hosting decisions in an ADR.

Do not build the complete app or create product, service, provider, or production external state before these risks are understood. Offline S1-A contract and URL-policy core work may proceed only within [ADR 0002](docs/adr/0002-local-first-product-foundation.md). Owner-local Apple automatic signing for the inert shell is the sole external-state exception: it may create or fetch development provisioning state, but is neither proof evidence nor authority for entitlements, TestFlight, or release. The exact build sequence and stop gates are in the [implementation plan](docs/11-implementation-plan.md).

## Local verification

Open `HezoLink.xcodeproj` in Xcode for the minimal iOS app shell, the shared core sources, and their iOS test target. The same core sources remain a root Swift package for command-line and cross-platform testing. The shell exists only to surface Xcode build, runtime, and signing diagnostics; it does not yet implement a consumer flow or create network or persistent state. The shared `HezoLink` scheme runs all core tests with Product > Test.

For a signed device build, copy `Config/Signing.local.example.xcconfig` to `Config/Signing.local.xcconfig` and replace the two placeholder values. The local file is ignored by Git so the Apple Team and final bundle identifier do not enter the public repository. Keep certificates, private keys, and provisioning profiles in Xcode, Keychain, or Apple-managed stores—not in either xcconfig. Simulator builds require no signing identity.

The current Swift foundation has no third-party dependencies and performs no network access:

- `packages/contracts/` contains the strict Check Request V1 OpenAPI/JSON Schema component and reserved-domain schema fixtures.
- `packages/url-policy-oracles/` contains pinned, licensed, offline Unicode, URL-parser, and IP-syntax oracle data plus strict provenance manifests.
- `Sources/HezoLinkCore/` contains bounded contract values plus the local URL-input syntax preflight and constant log redactor used by later manual-input surfaces.

The URL-input preflight preserves the exact sensitive submission for transient analysis and rejects known ambiguous or prohibited syntax. Syntax profile 2 pins the [IANA Special-Use Domain Names registry](https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml) revision dated 2026-05-22 and adds oracle-backed IDNA-hyphen, numeric-ending host, and RFC 5952 IPv6 rules. Its offline tests replay pinned Unicode 17 IDNA data, a fixed Web Platform Tests URL-parser corpus, and project-authored RFC IP-syntax cases; acceptance remains deliberately narrower than a general-purpose browser parser. It is not a provider canonicalizer, destination-reachability or safety decision, durable URL representation, navigation capability, or consumer screen. A pinned Public Suffix List, complete special-address registry/classifier, ingress-to-egress parser equivalence, and the release branch-coverage gate remain required before that broader boundary can be called complete.

~~~sh
swift test
xcrun swift-format lint --configuration .swift-format --recursive Apps Sources Tests Package.swift
xcodebuild build -project HezoLink.xcodeproj -scheme HezoLink -destination 'generic/platform=iOS Simulator'
~~~

## Future business direction

Core consumer protection remains free in the intended model. Future revenue comes from intelligence about malicious infrastructure and campaigns, not consumer behavior:

- URL and domain reputation API
- Brand-impersonation monitoring
- Emerging-campaign intelligence feed
- Embedded SDK for banks, messaging products, marketplaces, and browsers
- Optional consumer ecosystem features only after they create real account value

External-source licenses must allow each commercial output. Hezo must never repackage or resell a third party’s raw feed without explicit rights.

## Repository status

Documentation baseline: reviewed and merged.

Stage 0: public governance and deterministic offline fixtures are established. The runnable proof harness remains paused until the repository and isolated-execution decisions are accepted; no proof is claimed complete.

Application code: the bounded local S1-A foundation is authorized by [ADR 0002](docs/adr/0002-local-first-product-foundation.md). It currently contains the offline contract core, strict Check Request V1 data contract, minimal Xcode diagnostics shell, and URL-input policy primitives with executable tests. It contains no consumer flow, network client, persistence, provider integration, crawler, URL Filter, App Attest, analytics, or measurement behavior. Owner-local automatic signing may create Apple development provisioning state as the sole non-proof exception. Nothing here makes a Stage 0, Stage 1, release, or production-readiness claim.

Project license: not yet selected. Public visibility does not imply permission to reuse; O-019 requires the owner/legal decision before external contributions or reuse are promoted.
