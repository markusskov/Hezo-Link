# Product vision and V1 scope

## Product definition

Hezo Link protects people from phishing, scam links, fake websites, and malicious URLs while minimizing what Hezo can learn about their browsing.

The user question is:

> Is this URL dangerous, and what evidence supports that conclusion?

The strategic question is:

> Is this URL part of a wider malicious campaign that can be recognized before every individual URL is reported?

The consumer app is useful on its own. The defensible asset is the evidence and campaign graph accumulated behind it.

## Launch assumptions

| Dimension | V1 assumption |
|---|---|
| Product name | Hezo Link |
| Device | iPhone first |
| Minimum OS | iOS 26 |
| App Store market | United States first |
| Language | US English |
| Price | Free |
| Account | No |
| Monetization | None in V1 |
| Passive filtering | Apple URL Filter, capability dependent |
| Manual fallback | Always available |

US first means intelligence specialization, not a claim that non-US URLs can never be checked. The general reputation and sandbox pipeline should accept globally valid HTTP and HTTPS URLs. Brand registries, language features, campaign labels, customer support, benchmarks, and launch claims focus on US English and commonly impersonated US entities.

Initial US categories:

- delivery and postal services;
- federal and state government services;
- toll and road-payment scams;
- banks, cards, and payment providers;
- major retail and marketplaces;
- email, cloud, and consumer technology;
- telecom carriers;
- social networks;
- cryptocurrency platforms;
- job, account-reset, and tech-support scams.

No precise location is required for V1. App Store region, language, or a voluntarily selected country may tune copy, but none belongs in security evidence about a submitted URL.

## Core promise

Recommended consumer promise:

> Safer links. Without watching where you browse.

Supporting principles:

- Hezo explains evidence rather than presenting a mysterious percentage.
- Hezo admits uncertainty.
- Passive filtering must not create a Hezo browsing history.
- A user can receive full core protection without registration or unnecessary telemetry.
- The word Safe is not used as an absolute security guarantee.

## V1 capabilities

### Required

- Check a pasted HTTP or HTTPS URL.
- Receive a deliberately shared URL from another app.
- Scan a QR code, preview its destination, and check it before opening.
- Show one of four verdicts: No known danger, Caution, Dangerous, Unknown.
- Explain the verdict using bounded, provenance-backed evidence.
- Detect common US brand impersonation patterns.
- Relate entities to a versioned scam campaign without claiming attacker attribution.
- Submit a scam report.
- Submit an incorrect-verdict or false-positive report.
- Keep recent manual checks locally, with an obvious clear-history control.
- Display protection, blockset, and privacy status.
- Support optional MPD measurement and optional product analytics as separate choices.
- Support automatic URL protection when the Apple capability and server path are production ready.

### Capability-dependent

System-wide URL protection is a separately shippable capability. Its delay must not block the manual product. The app and backend must be releasable in manual-check mode while entitlement, server validation, and production readiness are unresolved.

### Explicit non-goals

V1 does not include:

- accounts or Sign in with Apple;
- cross-device history or settings sync;
- VPN or packet inspection;
- general antivirus or device scanning;
- caller identification;
- SMS, email-inbox, contact, or notification access;
- breach monitoring;
- password management;
- identity monitoring;
- an AI chat interface;
- browser extensions, Android, iPad, or macOS product work;
- enterprise dashboards, public Trust APIs, SDKs, or billing;
- automated takedown requests;
- criminal or actor attribution;
- a consumer per-device “threats blocked” counter that would require browsing logs;
- global language and brand coverage;
- learned end-to-end auto-blocking.

## Primary user journeys

### Onboarding

1. Explain the outcome and offer Set up protection or Check a link instead.
2. Explain on-device filtering and private verification in plain language.
3. Ask separately for MPD measurement consent.
4. Ask separately for product analytics consent.
5. Configure URL protection if available, or explain that manual checking still works.
6. Land on a usable home screen with no sign-in wall.

Consent choices must be neutral, reversible, and non-blocking. Camera permission is requested only when QR scanning begins. Clipboard content is read only through an explicit paste action.

### Manual check

1. The user pastes, shares, or scans a URL.
2. The app validates that the scheme is HTTP or HTTPS and previews the registrable domain.
3. The exact submitted URL is intentionally sent to the security API without analytics, MPD, account, advertising, or attestation identifiers.
4. A cached result returns immediately or the UI enters Analyzing.
5. The app displays the verdict, recommended action, evaluated time, and evidence.
6. The user may close, open despite a warning where policy allows, report the URL, or report an incorrect result.

The app must not strip query parameters or fragments before analysis. The backend creates provider-specific and long-term sanitized forms after receiving the exact submission.

### QR check

1. Scan locally.
2. Show the decoded destination before any network navigation.
3. Reject unsupported schemes and clearly label non-URL QR content.
4. Check the URL.
5. Never auto-open the destination as a side effect of scanning.

### Passive protection

1. The app shows whether URL protection is configured and enabled.
2. Apple’s private URL-filter flow checks the Hezo blockset.
3. Hezo does not build passive per-device browsing or block histories.
4. If verification infrastructure fails, V1 fails open.
5. The app can disable filtering through a remotely signed kill switch and recover to a last-known-good configuration.

### Report and appeal

Reports are deliberate security contributions, not product analytics. The user sees what is sent before submission. App Attest protects the endpoint, but its installation identity is removed before the report reaches the Trust Graph.

False-positive feedback is as prominent as scam reporting. Reports against high-impact or official domains receive priority triage, but report volume alone never changes an enforcement decision.

## Result language

### No known danger

Hezo completed the minimum analysis and found no meaningful current malicious evidence.

Required qualifier:

> Hezo did not find current evidence that this website is malicious.

Never say guaranteed, verified safe, or 100% safe.

### Caution

Meaningful suspicious evidence exists, but it is insufficient or contradictory.

Recommended copy:

> This website has characteristics seen in scam sites, but Hezo does not have enough evidence to classify it as dangerous.

### Dangerous

A qualified exact threat or corroborated independent evidence supports a malicious classification.

The result states the likely category, target brand when supported, evidence, and recommended action. It does not accuse a named person or organization of operating the campaign.

### Unknown

Analysis is incomplete, unsupported, stale, or too contradictory to support another state.

Unknown is a successful expression of uncertainty, not an application error.

## Product surfaces

### Home

- protection status;
- threat data version and freshness;
- paste/check field;
- QR scanner action;
- recent manual checks stored locally;
- privacy and protection details.

### Protection details

Explain separately:

- what is known when a user manually submits a URL;
- how passive URL filtering works;
- whether MPD measurement is enabled;
- whether product analytics is enabled;
- where to view the data inventory and change consent.

### Verdict details

Show:

- verdict and recommended action;
- concise primary explanation;
- three to five strongest independent evidence items;
- evaluated and freshness time;
- target brand and campaign only when confidence supports them;
- technical detail disclosure;
- report incorrect result.

Do not show an uncalibrated numeric probability.

## Success measures

Primary product metric:

- Measured Monthly Protected Installations, using the exact consented definition in document 02. “Monthly Protected Devices” is marketing language only under the approved methodology note.

Important supporting measures:

- protection setup completion;
- month-over-month aggregate MPD change, clearly labeled as an aggregate rather than cohort retention;
- manual-check completion and time to first useful result;
- verdict latency and analysis completion rate;
- confirmed false-positive rate, especially automatic blocks;
- time from first observation to qualified detection;
- percentage of new confirmed threats linked to an existing campaign;
- report qualification rate and report-to-review time;
- blockset freshness and rollback success.

Downloads and registrations are not north-star measures. V1 has no registration.

V1 intentionally retains no cross-month installation identifier, so it cannot calculate true per-installation 30-day or 90-day protected retention. Do not relabel aggregate monthly change as retention. A future retention design would require a separate consent, privacy, reidentification, and product decision.

## Future monetization boundary

Future customers may buy intelligence about threats:

- URL/domain reputation;
- brand impersonation monitoring;
- campaign changes and infrastructure relationships;
- feeds or APIs of Hezo-owned or properly licensed derived indicators;
- an embedded protection SDK.

They do not buy individual browsing, check, device, analytics, or report histories. Any B2B output must pass source-license, privacy, provenance, and confidence-policy checks.

Consumer paid features may exist later only when they provide meaningful value such as multi-device, family, or ecosystem capabilities. They are not a V1 requirement.

## Product acceptance criteria

V1 product scope is acceptable when:

- every manual flow works without an account and with both telemetry consents declined;
- QR scanning never navigates before a verdict;
- local history can be disabled and cleared;
- every completed result uses one of the four canonical labels;
- every non-Unknown verdict has policy-backed evidence and freshness;
- no consumer result contains an internal risk percentage;
- URL Filter can be omitted or disabled without breaking manual checks;
- privacy details correctly distinguish deliberate checks from passive filtering;
- report and false-positive paths work with anti-abuse controls;
- no excluded feature appears in the implementation backlog before the V1 gates pass.
