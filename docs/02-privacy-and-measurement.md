# Privacy, measurement, and data lifecycle

## Purpose

Hezo Link must be able to protect a person, operate a useful threat-intelligence system, resist abuse, and measure product reach without turning those capabilities into one behavioral profile.

This document defines:

- the production data-plane boundaries;
- what each plane may and may not receive;
- the privacy behavior of passive filtering, manual checks, reports, MPD, and optional analytics;
- the exact internal Monthly Protected Installation measure;
- consent, withdrawal, deletion, and retention behavior;
- preliminary App Store privacy disclosures and the App Tracking Transparency boundary;
- US-first legal-review assumptions; and
- privacy acceptance tests.

The durable architectural rule is:

> A security submission, an App Attest installation, an MPD receipt, and an analytics batch must never become one joinable record.

A rotating identifier is pseudonymous while it exists. The implementation may make it short-lived and difficult to link, but neither product copy nor internal documentation may call the raw receipt unconditionally anonymous.

This is an engineering specification, not legal advice. The legal and product decisions identified as open in [document 12](12-risks-decisions-and-open-questions.md) still require their named owners.

## Privacy outcomes

V1 must satisfy all of the following:

- Manual paste, share, and QR checks work without an account, MPD consent, product-analytics consent, or URL Filter approval.
- Passive protection does not create a Hezo browsing or block history.
- The exact URL deliberately submitted for a manual check is available for security analysis, including its query and fragment, but is encrypted and transient.
- Long-term Trust Graph data is about threats and evidence, not the person or installation that encountered them.
- App Attest material is anti-abuse evidence, not a product-analytics or intelligence identifier.
- MPD measures consenting installation-months and nothing about browsing behavior.
- Product analytics is omitted unless a concrete, approved event allowlist justifies it.
- No user- or installation-level data is sold, shared with data brokers, or used for advertising.
- Declining or withdrawing optional measurement has no product penalty.
- Deletion and retention are enforced in queues, object storage, logs, replicas, and backups, not only primary tables.

## Data classification vocabulary

Use these terms consistently:

| Term | Meaning in Hezo Link |
|---|---|
| Transient submitted content | A raw URL or sandbox artifact retained only long enough to service and inspect a deliberate request. It may contain personal data or secrets. |
| Pseudonymous installation data | Data that recognizes one app installation for a bounded purpose, including an App Attest key or month-scoped MPD token. It is not anonymous. |
| Sanitized security intelligence | Threat entities and evidence retained without the submitter or installation. Sanitization reduces privacy risk but does not automatically make attacker-controlled URLs or page content non-personal. |
| Aggregate measurement | A count or bounded operational statistic with no contributing row or key remaining. |
| Tracking | Apple’s narrower term for cross-company advertising or advertising-measurement joins, or sharing user/device data with a data broker. It is not a synonym for all analytics. |

## Four-plane production architecture

The four planes use separate production stores, credentials, service roles, queues, encryption keys, retention jobs, logs, administrative tools, and bounded operational metrics.

| Plane | Purpose | Typical retained records | Explicitly prohibited |
|---|---|---|---|
| Security intelligence | Answer a deliberate check, create observations, enrich threats, compile verdicts and blocksets | Sanitized URL/domain entities, observations, evidence, graph relationships, verdict versions, report content after identity stripping | MPD token, analytics ID, App Attest key ID, IDFV, IDFA, account ID, stable installation ID, raw source IP |
| Anti-abuse | Verify legitimate app installations, prevent replay, rate-limit writes, issue short-lived capabilities | App Attest public key/key ID, receipt where required, counters, challenge state, replay entry, bounded risk/rate state, spent capability digest | Raw URL, domain, page content, verdict, campaign ID, MPD token, analytics batch |
| Protection measurement | Count consented protected installation-months | UTC month, month-token digest, spent anonymous-credential digest, definition version, finalized aggregate | URL, domain, verdict, report, campaign, App Attest key ID, IDFV, IDFA, raw IP, user agent, locale, carrier, device model |
| Product analytics | Answer an approved product question using coarse, URL-free events | Fixed event code, coarse period, integer count, schema version, one-time batch identifier | URL, domain, query/fragment, verdict or campaign ID, report ID, App Attest key, MPD token, advertising ID, persistent analytics ID, raw IP |

No general-purpose role may read two planes. No central event warehouse may ingest their raw records. A cross-plane join cannot be justified as “internal only,” “temporary,” “debugging,” “fraud analysis,” or “support.”

The following are privacy incidents:

- the same stable or rotating identifier and a URL/domain appear in one request, table, trace, queue, log, analyst view, or export;
- an App Attest key is reused as MPD or analytics identity;
- an MPD token is attached to a manual check, report, verdict, or PIR request;
- a trace or request ID correlates anti-abuse issuance with MPD redemption;
- support or observability tooling can search more than one sensitive plane.

The response is defined under R-007 in [document 12](12-risks-decisions-and-open-questions.md): stop the flow, preserve only approved incident evidence, delete or rotate where possible, review disclosures, and add a regression test.

## Subflow privacy contracts

### Passive URL Filter

Apple’s iOS 26 URL Filter architecture is the only passive browsing path in V1.

The expected privacy properties are:

- an on-device prefilter resolves most lookups locally;
- possible matches use Private Information Retrieval;
- Apple’s Oblivious HTTP relay hides the originating IP from Hezo’s PIR service;
- the Hezo PIR service does not learn the queried URL or returned result;
- the containing app and its extension do not receive passive browsing traffic; and
- Privacy Pass authenticates access without exporting an ordinary user identity to the PIR origin.

Apple's PIR HTTP protocol still uses a pseudorandom User-Identifier so the service can associate an uploaded homomorphic-encryption evaluation key with later encrypted queries. That value can correlate its own protocol lifecycle even though it does not reveal the bearer-token identity, queried URL, or returned membership result. Treat it as pseudonymous filter-runtime state: keep only a filter-keyed digest plus the opaque evaluation key and expiry, never log, export, analyze, or join it, and delete both on the approved inactivity or absolute deadline. It is not an MPD, analytics, App Attest, Trust Graph, or consumer-history identifier.

Hezo must not add custom passive URL logging, block-event telemetry, per-installation counters, or a “threats blocked” history around this path. PIR request volume, Bloom matches, denials, and block events are not MPD inputs.

Development-signed direct-Xcode behavior is not proof of those distribution properties. Apple entitlement approval, CloudKit Identity & Trust configuration, OHTTP validation, Privacy Pass behavior, and a physical distribution build are launch gates in [document 07](07-apple-platform.md).

Primary platform sources:

- [Apple URL filters documentation](https://developer.apple.com/documentation/networkextension/url-filters)
- [WWDC25: Filter and tunnel network traffic with NetworkExtension](https://developer.apple.com/videos/play/wwdc2025/234/)
- [Apple PIR HTTP endpoints](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/HTTPEndpoints.md)

### Manual paste, share, and QR check

A manual check is a deliberate security request, not passive telemetry.

The app must disclose that the exact submitted URL is sent for analysis before the first such submission. Pressing Check after that clear disclosure may express the request to process that URL; legal/privacy review must approve the final just-in-time copy.

The security request may contain:

- the exact submitted HTTP or HTTPS URL, including query and fragment;
- a request-scoped random identifier;
- the API/schema version; and
- a short-lived anonymous capability where abuse control requires one.

It must not contain:

- an App Attest key or assertion;
- an MPD or analytics identifier;
- an IDFV, IDFA, push token, advertising attribution value, or account ID;
- device model, carrier, precise location, contact data, or clipboard history; or
- recent-check history.

If the anti-abuse plane authorizes the call, it verifies an assertion over an opaque canonical request digest and returns a narrowly scoped capability. The security API receives the capability, not the App Attest key. The anti-abuse service receives the digest, not the URL or request body. The assertion and request digest exist only for the verification and replay window, then are deleted; logs record a coarse validation outcome, not the assertion, digest, or body.

The raw URL is encrypted for processing. Query and fragment are not stripped before analysis because they may select malicious behavior or redirects. The normal target is deletion immediately after the terminal job or verdict; the proposed V1 hard limit is 24 hours across queue, storage, replicas, and backups. See O-007 and P-008 in [document 12](12-risks-decisions-and-open-questions.md).

### Sandbox artifacts

DOM, response material, HAR/network traces, screenshots, and downloads may expose credentials, account-reset links, email addresses, messages, or payment data.

The current proposed contract, shared with [document 08](08-sandbox-and-security.md), is:

- encrypt and quarantine every artifact;
- delete at terminal processing with a 24-hour hard default TTL;
- allow an explicit report or analyst hold to extend selected artifacts to no more than seven days;
- require a reason, owner, access audit, and fixed expiry for that hold; and
- retain only the sanitized security representation and approved derived evidence in the Trust Graph.

O-016 in [document 12](12-risks-decisions-and-open-questions.md) remains the decision point if the intelligence team proposes longer confirmed-malicious evidence retention. A longer period is not authorized by this document.

A hash of a full URL is not anonymization. Email addresses, reset links, campaign parameters, and tokens may be guessable. If exact transient deduplication is necessary, use a short-lived keyed HMAC with a separately controlled key and the same expiry as the raw URL.

### Deliberate report and false-positive appeal

A report is a separate, explicit security contribution.

Before submission, preview the security content that will be sent. App Attest may protect the endpoint, but the Trust Graph receives only the report capability and report content after the anti-abuse boundary removes installation identity.

The report record must not contain MPD or product-analytics identifiers. A deletion capability may be generated locally and stored with the report receipt so a no-account user can request deletion while the identifiable report record remains.

Pending O-017, the proposed conservative lifecycle is to delete the restricted report URL, bounded comment, receipt linkage, and deletion-capability digest as soon as triage and safe derivation complete and never later than 30 days after receipt. The report API's body-free idempotency/replay digest has a proposed 24-hour maximum. Each restricted report record should use a deletable per-record encryption key held in a deletion-aware key store outside the content-backup set, or an equivalently tested design, so withdrawal can make backup ciphertext unreadable without retaining a report-to-user identity. Do not claim immediate backup erasure until that mechanism passes restore tests.

A longer-lived Trust Graph observation may remain only after it has been reduced to the approved sanitized security representation, contains no free text, personal query/fragment value, report receipt, deletion capability, anti-abuse value, or submitter linkage, and records that its source class was a deliberate report. O-017 must decide whether deletion of a raw report retracts report-only derived support, how a qualified independently re-observed threat becomes Hezo evidence, and the exact live-store, idempotency, key-destruction, and backup deadlines before Stage 6.

Report volume never becomes an automatic verdict or block by itself.

## Field contracts

### Cross-plane deny list

The following fields and equivalents are denied outside their named plane:

| Field/data | Sole allowed plane or handling |
|---|---|
| Exact manually checked URL | Transient security request/sandbox only |
| Manual-check query value or fragment | Transient security request/sandbox only |
| Explicit report URL/comment | Restricted intelligence intake only under O-017; never a routine graph field |
| Sanitized URL/domain entity | Security intelligence only |
| App Attest key ID/public key/receipt/counter | Anti-abuse only |
| App Attest attestation/assertion/challenge | Anti-abuse transient verification only |
| Apple PIR User-Identifier digest/evaluation key | Filter-runtime protocol store only, until approved expiry |
| MPD wire token/token digest | MPD only |
| Product analytics batch/event | Analytics only |
| IDFA | Nowhere in V1 |
| IDFV | Nowhere in V1 |
| Advertising/session-replay attribution ID | Nowhere in V1 |
| Push token as identity | Nowhere in V1 |
| Account/email identity | No V1 account; support records remain outside product data |
| Raw source IP or full user agent | No retained application record in any plane |

### Operational logging allow list

Logs and metrics may contain only bounded operational values required for reliability or security, such as:

- service and schema version;
- bounded route code, not raw path parameters;
- response-status class;
- latency and payload-size bucket;
- typed failure code from a finite enum;
- state transition;
- queue depth and age bucket;
- environment;
- aggregate rate-limit decision count; and
- service-local trace ID with short retention and no propagation into another sensitive plane.

They must never contain:

- request or response body;
- raw or sanitized URL/domain in a general log;
- Authorization, cookie, App Attest, Privacy Pass, or deletion-capability material;
- MPD or analytics payload;
- source IP, full user agent, locale, carrier, or device model;
- page content, screenshot pixels, DOM, HAR, form value, or attacker-controlled error text; or
- an unbounded label derived from a request.

Edge/CDN, load balancer, APM, crash, database slow-query, support, and cloud audit configurations belong in the privacy data inventory. If a processor retains IP addresses or request material beyond real-time service, App Store and legal disclosures must reflect the actual behavior. “The app does not log it” is insufficient.

## Measured Monthly Protected Installations

### Canonical name

The internal canonical name is:

> Measured Monthly Protected Installations

Marketing may use Monthly Protected Devices only with the visible methodology note approved under O-011 in [document 12](12-risks-decisions-and-open-questions.md).

MPD is not:

- monthly active users;
- unique people, households, Apple accounts, or hardware devices;
- downloads or installed base;
- launches or sessions;
- number of checks, URLs, blocks, threats, or reports;
- continuously protected devices; or
- all protected installations, because non-consenting installations are excluded.

### Exact semantic definition

For UTC calendar month M, a qualifying installation is one for which all of the following became true at least once during M:

1. It is a production Hezo Link iPhone installation.
2. The user’s optional MPD consent is active when the receipt is prepared.
3. Web Protection is enabled in the system.
4. The URL Filter health adapter reports a valid, non-expired configuration/prefilter generation and no active Hezo kill switch or known degraded state.
5. The counter accepts a well-formed receipt for M during M.

The client emits the receipt only after conditions 2 through 4 are true. The payload does not repeat a browsing event or block count as evidence.

Formally:

~~~text
Q(M) = {
  T(i, M) |
  installation i is production,
  MPD consent is active,
  protection is enabled and healthy at least once in M,
  and receipt T(i, M) is accepted during M
}

MeasuredMonthlyProtectedInstallations(M) = cardinality(Q(M))
~~~

The unique month token means retries from the same installation-month are idempotent. A token for an earlier month is not accepted as catch-up traffic. The correction window is for deletion, fraud correction, and reconciliation, not late historical submission.

A device that was healthy once and later degraded still qualifies for that month. Therefore the metric must not be described as continuous protection.

### Token generation

Generate a random 256-bit installation secret with the system cryptographic random-number generator:

~~~text
S_install = CSPRNG(32 bytes)
~~~

Store S_install in the containing app or App Group container:

- with iOS Data Protection;
- excluded from backup and synchronization;
- inaccessible to other Hezo apps;
- never transmitted;
- not derived from hardware, IDFV, IDFA, App Attest, locale, or network properties; and
- deleted by the contribution-data reset flow.

Do not use Keychain persistence to make the measurement identity survive uninstall. Reinstall continuity is neither necessary nor desirable for this privacy-first metric.

Derive the month key and receipt using domain-separated standard primitives:

~~~text
M = ASCII UTC month in YYYY-MM form

K_month = HKDF-SHA256(
  input_key_material = S_install,
  salt = SHA256("hezo-link/mpd/v1"),
  info = "month:" || M,
  output_length = 32
)

T_month = HMAC-SHA256(
  key = K_month,
  message = "qualified-protected-installation"
)
~~~

Transmit all 32 bytes of T_month as unpadded base64url. The construction is stable within one installation-month and cryptographically separated across months if S_install remains secret.

The same seed must not be shared with a future Hezo app. Cross-app ecosystem measurement requires a separate product and legal decision.

### Server-side storage

The counter must not store T_month directly.

For each month, generate a random KMS-held pepper P_month:

~~~text
P_month = CSPRNG(32 bytes)
D_month = HMAC-SHA256(P_month, T_month)
~~~

Store only D_month with a uniqueness constraint on month and digest. Destroy P_month when the corresponding raw rows expire.

Minimum open-row direction:

| Column | Purpose |
|---|---|
| month | UTC month, first-day date |
| token_digest | D_month; primary deduplication value |
| spent_credential_digest | Optional replay prevention for anonymous integrity credential |

Definition version, finalized count, correction count, and methodology version belong in the monthly aggregate record. Do not add a per-row device, build, OS, country, locale, timestamp, IP, user agent, App Attest key, or general created-by identifier merely because it is convenient.

The counter endpoint direction is:

~~~http
POST /v1/measurement/mpd
Content-Type: application/json
Authorization: PrivateToken <credential when enabled>

{
  "schema": 1,
  "month": "2026-08",
  "token": "<base64url 32-byte token>"
}
~~~

Return the same generic success response for a new receipt and a duplicate. Use server UTC or a signed server month from the protection manifest; reject a client’s past or future month rather than silently re-bucketing it.

Do not submit multiple months in one request. That would directly link the rotating tokens.

### Integrity and manipulation resistance

Random month tokens provide deduplication but do not prove that the sender is a genuine installation. A script can manufacture arbitrary tokens. A public audience-size claim therefore needs an explicit integrity decision.

The base Stage 8 implementation may validate token rotation, consent, storage, and deletion internally. It must not be promoted as a manipulation-resistant or cryptographically unlinkable public count solely because it uses HMAC.

App Attest remains in the anti-abuse plane:

1. The containing app enrolls one installation-specific App Attest key.
2. The anti-abuse service validates Apple’s chain, nonce, RP ID/App ID, environment, key, and assertion counter.
3. It authorizes a narrowly scoped measurement capability.
4. The measurement service receives the capability and month token, never the App Attest key.

A simple gateway that verifies an assertion and forwards a token can enforce policy separation, but the gateway sees both values in memory and can correlate issuance timing. It must not be described as cryptographic unlinkability.

A stronger design may use a blinded, month-bound Privacy Pass credential:

- the anti-abuse service acts as attester/issuer after App Attest validation;
- the client obtains a blinded credential scoped to the MPD origin and month;
- the MPD service redeems the credential without receiving the App Attest identity; and
- issuance and redemption use separate hosts, stores, keys, logs, service roles, and request IDs.

This is a gated security protocol, not a small implementation task. Before it is selected:

- write an ADR covering threat model, issuer/origin separation, replay, timing correlation, unsupported devices, deletion, key rotation, operations, and failure behavior;
- use an audited implementation of the standardized protocol rather than hand-rolled blind-signature cryptography;
- review whether it can safely reuse code, but not tokens, issuers, keys, origins, or logs, from Apple URL Filter infrastructure;
- conduct an independent protocol/security review; and
- verify privacy claims against packet captures and retained data.

Relevant standards:

- [RFC 9576: The Privacy Pass Architecture](https://www.rfc-editor.org/info/rfc9576/)
- [RFC 9577: The Privacy Pass HTTP Authentication Scheme](https://www.rfc-editor.org/info/rfc9577/)
- [RFC 9578: Privacy Pass Issuance Protocols](https://www.rfc-editor.org/rfc/rfc9578.html)

Blind issuance hides redemption linkage from the counter. It does not make the App Attest issuer’s installation record anonymous, and timing or network metadata can still correlate poorly separated deployments.

If the stronger credential is not production-ready, keep the count internal or label it an observed estimate. A proposed conservative reporting model is to keep observed receipts internal and use only anonymously credentialed receipts for a public verified count. O-011 must approve the final public policy.

App Attest failure or lack of support must never disable core protection. The accepted security boundary and fallback behavior live in [document 07](07-apple-platform.md) and [document 08](08-sandbox-and-security.md).

### Metric lifecycle and publication

The proposed lifecycle is:

1. **Open:** accept current-month receipts and withdrawals.
2. **Provisional:** stop accepting that month at UTC month end; allow deletion, invalidation, and reconciliation.
3. **Final:** after the 45-day correction period, compute the final distinct count, purge raw rows, destroy the month pepper, and retain the aggregate.

Only a final count should support an unqualified headline. A provisional number must be labeled provisional and may decline.

For every published month retain:

- month and definition version;
- final count;
- finalization time;
- aggregation-query or build identifier;
- correction totals by bounded reason;
- approval record;
- methodology version; and
- evidence that raw rows and month pepper were destroyed.

Do not round an unverified value up to a threshold. “1,000,000+” requires a final count of at least 1,000,000 under the displayed definition.

Apple App Store Connect Active Devices may be used only as a separate reasonableness check. Apple’s metric covers devices with an app session and is based on Apple analytics sharing; it does not prove URL Filter health and must not be merged into MPD.

### Known limitations

The methodology must disclose:

- A reinstall, restore, migration, local reset, or seed loss can create a new installation token and an overcount.
- A non-consenting protected installation is absent.
- An installation that remains protected but cannot run the receipt client can be undercounted.
- Excluding the local secret from backup deliberately makes a restored device a new installation for measurement.
- Multiple physical devices are multiple installations.
- A malicious client can inflate an uncredentialed observed count.
- App Attest proves a valid app installation under Apple’s model, not a human, Apple account, or permanently unique hardware device.
- The metric says nothing about how many URLs were checked, threats were blocked, or how long protection remained healthy.

No retained V1 identifier may link one installation across months. Consequently, V1 cannot calculate true per-installation 30-day or 90-day retention from MPD. Month-over-month aggregate change is not cohort retention and must not be labeled as such.

## Product analytics

Product analytics is a separate optional system, not an extension of MPD.

P-012 in [document 12](12-risks-decisions-and-open-questions.md) is the default:

> Omit product analytics unless specific V1 questions justify a reviewed event allowlist.

App Store Connect’s Apple-provided aggregate analytics may be used as an external operational reference. Direct Hezo analytics requires:

- a named product question;
- a privacy owner;
- separate neutral consent, default off;
- a fixed schema and bounded-cardinality event enum;
- on-device aggregation where practical;
- no persistent installation or cross-month identifier;
- its own endpoint, store, credentials, keys, logs, and deletion job; and
- an updated privacy policy, Privacy Nutrition Label, processor inventory, and network-capture review.

A minimal approved batch could contain only:

~~~json
{
  "schema": 1,
  "batch": "<one-time random value>",
  "period": "2026-08-11",
  "events": [
    { "code": "protection_setup_completed", "count": 1 },
    { "code": "manual_check_completed", "count": 2 }
  ]
}
~~~

The one-time batch value prevents accidental replay; it is not reused and is not a product identity.

Possible allowed questions include:

- Was protection setup completed?
- Did a manual check complete or fail with a bounded technical error?
- Is a particular app build crashing or timing out?

Forbidden analytics include:

- which URL, domain, brand, campaign, verdict, or threat was encountered;
- whether a particular site was blocked;
- a user’s recent-check history;
- report content or report ID;
- a persistent retention/cohort identifier;
- device fingerprint components;
- exact event timestamps;
- precise/coarse location inferred from IP; and
- free-form properties or remotely added events outside review.

Do not claim 30-day or 90-day installation retention unless a future approved privacy-preserving design actually measures it. The current four-plane and cross-month-unlinkability decisions intentionally prevent that join.

## Consent

### Separate choices

V1 has at least three distinct privacy decisions:

1. Enable network filtering after clear disclosure of filtering behavior and data use.
2. Contribute the optional monthly protection receipt.
3. Share optional product analytics/diagnostics, if that system is approved.

Deliberate reports are previewed and confirmed per submission.

Do not bundle these choices into one switch. Do not preselect them, degrade protection, delay verdicts, hide decline, or repeatedly nag after a refusal. A user can change each optional choice in Settings.

Apple’s [App Review Guidelines section 5.1](https://developer.apple.com/app-store/review/guidelines/) require consent for user or usage-data collection even when considered anonymous, an accessible withdrawal path, a clear privacy policy, minimization, and no undisclosed repurposing or reidentification.

### Recommended MPD copy

Final copy remains open under O-010 and O-011, but the implementation should be reviewable against language no broader than:

> **Help count protected installations**
>
> Once each month, Link can send a random code that works only for that month. It contains no URL, browsing history, name, email, advertising ID, precise location, or identifier that follows you across months. We use it only to count participating installations with Web Protection enabled. Link works the same if you decline, and you can stop or delete this data in Settings.

If App Attest-backed issuance is enabled, the detail view must also say that a separate integrity service retains an installation-specific App Attest key to prevent false or duplicate participation. It must not imply that the entire flow lacks an installation identifier.

Store the consent status, policy version, and grant time on-device. Do not create a server-side consent profile solely to prove consent.

## Withdrawal, deletion, and no-account rights

### MPD withdrawal

When MPD consent is turned off:

1. Persist the off state before starting network work.
2. Stop receipt scheduling and integrity-credential issuance.
3. Derive deletion capabilities for every locally derivable month that is still open or provisional.
4. Send one generic deletion request per month without a cross-plane request ID or logging.
5. If offline, retain only the deletion capability in a protected retry queue until success or raw-row expiry.
6. Delete pending measurement uploads.
7. Delete S_install after deletion succeeds or the retry deadline expires.

The deletion endpoint treats the month token as a high-entropy capability. It returns the same response whether a row existed.

Re-consenting after the seed is destroyed creates a new installation identity and can recount within the month. This is an accepted privacy trade-off and must appear in methodology limitations.

### Product-analytics withdrawal

When analytics consent is turned off:

- stop collection before sending another batch;
- delete pending on-device batches;
- use locally retained one-time deletion capabilities to remove still-raw accepted batches where supported; and
- do not use MPD or App Attest to find prior analytics.

After raw analytics batches have been irreversibly aggregated and their deletion keys removed, explain that the aggregate cannot be traced back to one installation.

### Report deletion

While restricted report content remains readable, the app stores the report receipt and random deletion-capability secret locally. A deletion request presents those values to the intelligence intake origin, receives the same generic result whether a row exists, destroys the per-record data key and readable content, removes the capability digest, and invokes the O-017 rule for report-only derived support. It never uses an account, App Attest key, MPD token, analytics value, or support-supplied identity to locate the report.

If the local capability is lost or the app is uninstalled, Hezo cannot reliably identify the contributor. The proposed 30-day maximum and per-record key destruction provide eventual erasure; O-017 must approve the final live and backup behavior before report intake is implemented.

### Final aggregates

After MPD raw rows and P_month are destroyed, only the aggregate count remains. It cannot be associated with one installation or selectively reduced on that installation’s request.

The privacy policy must say this plainly. It must not promise deletion of non-joinable aggregate statistics.

### No account

The app must expose one-tap in-app withdrawal and deletion because an email support request cannot reliably identify a pseudonymous no-account row.

A public Privacy Choices page and support channel still accept applicable rights requests. Do not collect identity documents or additional personal data merely to search for data that was intentionally made unlinkable. Legal counsel must approve the verification and denial process for covered state laws.

Uninstall does not provide a reliable server callback. The app should make the in-app deletion control easy to find before removal, while raw TTLs guarantee eventual deletion if the request is never sent.

## Retention schedule

The following is the proposed V1 privacy schedule. P-008, P-009, O-007, O-010, O-016, O-017, and O-018 in [document 12](12-risks-decisions-and-open-questions.md) identify approvals still required.

| Data | Normal retention | Hard behavior |
|---|---|---|
| Passive URL Filter query/result at Hezo | None by design | No custom passive URL/block log |
| Apple PIR User-Identifier digest/evaluation key | O-018 must set measured inactivity and absolute limits | Distribution path remains unapproved until set; separate store with no logging, export, cross-plane join, or product use |
| Raw manually checked URL | Delete at terminal job/verdict | 24-hour maximum across queue/storage/backup |
| Restricted report URL/comment/receipt and deletion-capability digest | Proposed: delete after triage/derivation; 30-day maximum | One deletion capability while readable; deletion-aware key/backup design must pass restore tests; O-017 must approve |
| Report idempotency/replay digest | Proposed: retry window only; 24-hour maximum | Body-free and plane-local; never reused as report or submitter identity |
| DOM, HAR, response, screenshot, download | Delete at terminal job | 24-hour default maximum |
| Explicit report/analyst artifact hold | Only selected evidence | At most 7 days with reason, owner, audit, and expiry |
| Sanitized Trust Graph evidence | Evidence/source-specific | No submitter or installation link; obey license/freshness/deletion |
| MPD wire token | Process in memory | Persist only server-peppered digest |
| MPD token digest | Current month plus 45-day correction period | Delete at finalization; destroy month pepper |
| Final MPD aggregate | Indefinite | Contains count/method only, no contributing row |
| MPD consent record | On-device until withdrawal/reset | Never uploaded as a profile |
| App Attest challenge/assertion | Verification window only | No general logging or export |
| App Attest key/public-key record | Proposed: active purpose plus 180 days inactivity | Delete earlier if no other disclosed anti-abuse purpose remains |
| App Attest monthly issuance/rate ledger | Proposed: month plus 45 days | Separate from MPD redemption |
| Optional analytics raw batch | Proposed: 30 days | Deletion capability while raw |
| Optional analytics aggregate | Proposed: 13 months | No persistent contributor ID |
| Application IP/body/user-agent log | None | Processor behavior must match |
| Privacy/support request | Approved support schedule | Isolated from product data; minimize identity |

The App Attest and analytics periods above require an ADR/privacy approval before implementation. A stable App Attest key that remains necessary for report abuse prevention may outlive MPD withdrawal, but its MPD issuance ledger must not.

Deletion jobs must cover:

- primary and replica databases;
- object storage and versioning;
- queues, dead-letter queues, and retry state;
- search indexes and caches;
- analytics and debug exports;
- snapshots and backups;
- developer/support copies; and
- KMS peppers or wrapping keys whose destruction is part of erasure.

## App Store privacy disclosures

The final App Store Connect answers must be generated from the implemented data-flow inventory, every bundled SDK, processor configuration, and a physical-device network capture. The following is a conservative preliminary map, not permission to collect a category.

| Implemented flow | Likely Apple data type | Purpose | Tracking |
|---|---|---|---|
| Month-scoped MPD token plus protection qualification | Device ID; Other Usage Data or Product Interaction | Analytics | No |
| Retained App Attest key ID/counter | Device ID | App Functionality/security | No |
| Optional product events | Product Interaction; Other Usage Data | Analytics | No |
| Direct crash/performance telemetry | Crash Data; Performance Data | App Functionality or Analytics | No |
| Retained manual URL/check | Search History and potentially Browsing History or Other User Content | App Functionality | No |
| Explicit report text | Other User Content; potentially Browsing History | App Functionality | No |
| Passive URL, query, and result in Apple Bloom/PIR/OHTTP filtering | None collected by Hezo | Not applicable | No |
| Apple PIR User-Identifier digest and evaluation-key protocol state | Conservatively assess as Device ID or Other Data | App Functionality/security | No |
| Retained source IP | Depends on use: Device ID, Coarse Location, or Diagnostics | Actual use | No unless used for tracking |

Apple defines collection as off-device transmission retained in readable form longer than necessary to service the request. On-device-only processing is not collected. A value transmitted only for real-time service and immediately discarded may not require a label entry, but the privacy policy still must describe material transient processing.

Opt-in-only data still belongs in the label. MPD is recurring primary measurement and does not meet Apple’s narrow optional-disclosure exception.

Whether a month-scoped token qualifies as “not linked” is implementation-dependent. Apple treats data associated with a device as linked unless protections break and prevent relinking. Conservatively disclose the MPD token and retained App Attest key as linked to an installation/device unless the final schema, controls, and App Review guidance support a different answer.

Primary Apple guidance:

- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)

### Privacy manifest and SDK policy

The iOS targets must contain accurate PrivacyInfo.xcprivacy manifests and required-reason API declarations. Reconcile:

- app and extension manifests;
- generated Xcode privacy report;
- App Store Connect answers;
- privacy policy;
- consent copy;
- actual device traffic; and
- processor/SDK inventory.

Do not add a third-party analytics, advertising, attribution, session-replay, or crash SDK without an explicit privacy review, data inventory, manifest review, consent decision, retention contract, and update to this document.

## App Tracking Transparency boundary

V1 does not need or show the App Tracking Transparency prompt.

ATT applies when app data is linked with other companies’ app, website, or offline data for targeted advertising or advertising measurement, or when user/device data is shared with a data broker. First-party MPD is not automatically ATT tracking, but it still requires Apple-required consent and accurate privacy disclosure.

V1 must:

- never access IDFA;
- not include NSUserTrackingUsageDescription;
- avoid IDFV even though Apple permits same-provider analytics without ATT;
- include no advertising or attribution SDK;
- never share MPD tokens, App Attest keys, analytics batches, reports, URLs, or browsing data with B2B customers; and
- sell only Hezo-owned or licensed threat intelligence that is not connected to a person or device.

ATT permission would not make fingerprinting acceptable. Do not derive a unique identity from device model, configuration, locale, carrier, network, IP, timing, or similar signals.

Reassess ATT and App Review requirements before:

- cross-company advertising or measurement;
- a data-broker relationship;
- user/device-level external sharing;
- third-party login or SDK behavior that joins data;
- a common identifier across future Hezo apps; or
- B2B outputs that are not truly threat-level aggregates.

Apple’s boundary and fingerprinting rule are explained in [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/).

## Reidentification threat model

Deidentification is a risk-reduction process, not a promise created by deleting a name. [NISTIR 8053](https://www.nist.gov/publications/de-identification-personal-information) notes that deidentified datasets can sometimes be reidentified.

Hezo must explicitly test these linkage routes:

### Stable-key linkage

- IDFV, IDFA, push token, Keychain survivor, App Attest key, or account ID reused as MPD/analytics identity.
- One secret reused across Hezo apps.
- A deletion or support identifier reused as a product identity.

### Network and timing linkage

- Source IP, full user agent, TLS metadata, precise receipt time, locale, carrier, device model, or rare build retained with a token.
- App Attest issuance and MPD redemption sharing a trace ID, source-IP log, or near-identical timestamp.
- Multiple monthly tokens sent together.
- Immediate deterministic redemption after issuance.

### Payload linkage

- URL query values containing email, phone, session, payment, reset, or campaign identifiers.
- Full-URL hashes vulnerable to guessing.
- Analytics properties containing domain, verdict, report, campaign, or free-form text.
- Rare multi-dimensional cohorts.

### Operational linkage

- APM, crash, slow-query, CDN, queue, backup, support, or data-lake copies bypassing field contracts.
- A service account or analyst console that can search two planes.
- Future repurposing of “anonymous” records or joining them to customer/third-party datasets.
- A processor retaining data longer than the Hezo service.

Mitigations include:

- separate infrastructure and IAM;
- no shared trace/request IDs;
- body/header/IP log suppression;
- randomized credential redemption delay where compatible with month-end correctness;
- schema deny-list tests;
- no cross-plane warehouse;
- coarse, single-purpose analytics;
- minimum cohort thresholds and disclosure review before publishing any breakdown;
- short retention and cryptographic key destruction;
- processor contracts and configuration audits; and
- periodic reidentification exercises by a team without production implementation assumptions.

## US-first launch assumptions

US first is a product and operations scope, not a claim about every user’s residence.

V1 assumes:

- United States App Store availability first;
- US English interface, support, legal copy, and intelligence specialization;
- US-region hosting under the cloud ADR;
- no account;
- no ads, sale, behavioral sharing, or precise location;
- no IP geolocation for MPD or analytics;
- a general-audience product, not the Kids Category; and
- public Privacy Policy and Privacy Choices pages plus accessible in-app controls.

App Store territory does not prove residency, and a user may travel. Do not call MPD “US devices” based on source IP. If the app is US-storefront-only, describe the statistic as belonging to the US-first release rather than measuring current location or residence.

### FTC and objective claims

The FTC can enforce privacy/security promises that are deceptive or unfair. Objective advertising claims need a reasonable basis before publication.

Implications:

- “Safer links. Without watching where you browse” must be true across Hezo, Apple-facing configuration, processors, logs, backups, and support.
- “Anonymous” must not describe a retained pseudonymous token or App Attest record.
- “1,000,000 Monthly Protected Devices” requires the final count, methodology, limitations, and manipulation controls it implies.
- Security effectiveness, coverage, and false-positive claims require evidence matched to the claim.

Primary sources:

- [FTC Privacy and Security guidance](https://www.ftc.gov/business-guidance/privacy-security)
- [FTC Policy Statement Regarding Advertising Substantiation](https://www.ftc.gov/legal-library/browse/ftc-policy-statement-regarding-advertising-substantiation)
- [FTC: Marketing Your Mobile App](https://www.ftc.gov/business-guidance/resources/marketing-your-mobile-app-get-it-right-start)
- [FTC: App Developers, Start with Security](https://www.ftc.gov/business-guidance/resources/app-developers-start-security)

### State privacy laws

State applicability depends on business model, scale, residence, data, and statutory thresholds. US-first does not mean one federal privacy rule.

The launch legal review must maintain a current state-law matrix covering:

- applicability thresholds;
- notice at collection;
- access, correction, deletion, portability, and appeal;
- opt-out and universal opt-out obligations;
- sensitive-data and child consent;
- processor contracts;
- assessments, audits, and security;
- data minimization and purpose limitation; and
- incident/breach duties.

California personal information can include IP addresses, online identifiers, unique pseudonyms, and device identifiers when reasonably linkable. CCPA duties apply only when the statutory business tests are met, but the system should support deletion and minimization before that point.

Primary California sources:

- [California Civil Code section 1798.140](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CIV&sectionNum=1798.140.)
- [California Attorney General CCPA overview](https://oag.ca.gov/privacy/ccpa)
- [California Privacy Protection Agency FAQ](https://cppa.ca.gov/faq)

Colorado’s law can apply to a controller processing personal data of at least 100,000 Colorado consumers in a year, with a separate lower sale-related threshold. It includes transparency, rights, minimization, security, purpose limitation, and consent duties for sensitive data.

Primary source:

- [Colorado Attorney General: Colorado Privacy Act](https://coag.gov/resources/colorado-privacy-act/)

Do not collect state solely to calculate legal thresholds. Use total scale and conservative nationwide controls, and obtain US privacy counsel before TestFlight/public launch and before any enterprise data product.

### Children

COPPA applies when an online service is directed to children under 13 or has actual knowledge it is collecting personal information from a child under 13. Persistent identifiers can be personal information.

Hezo Link is planned as general audience, but an App Store age rating or terms statement is not by itself a COPPA compliance strategy. O-010 must decide age rating and copy with counsel. Do not knowingly collect optional MPD or analytics from an under-13 user without an approved compliant design.

Primary source:

- [FTC COPPA Frequently Asked Questions](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)

### Conservative product policies

The following are deliberate V1 trust policies, not claims that every US law universally requires them:

- MPD and analytics opt in separately and default off.
- Core protection works without either.
- No sale/share/targeted advertising.
- No precise or inferred location.
- No persistent analytics identity.
- Nationwide in-app withdrawal/deletion.
- Short raw retention and no cross-plane warehouse.
- Plain disclosure of final aggregate-deletion limits.

Counsel must review the public privacy policy, consent copy, age rating, processor contracts, rights workflow, incident plan, state-law matrix, and public MPD claim before launch.

## Acceptance tests

### Consent and network behavior

- With both optional consents off, a clean install sends no MPD or product-analytics request.
- Declining or withdrawing either consent has no effect on manual checks, verdict quality, passive filtering eligibility, reports, or app performance.
- MPD cannot send before consent is persisted and protection health qualifies.
- Analytics cannot initialize or transmit before its separate consent is persisted.
- A UI test proves neutral accept/decline prominence and an accessible Settings withdrawal path.
- Camera access is requested only when QR scanning starts; clipboard content is read only through explicit paste.

### Token correctness

- Fixed test vectors cover CSPRNG seed format, HKDF domain separation, HMAC output, base64url encoding, and UTC month boundaries.
- The same seed/month produces the same token.
- Different months or seeds produce different tokens.
- The full token is 32 bytes and malformed lengths/encodings are rejected.
- The app-container seed is excluded from backup/sync and does not survive the defined reinstall/reset test.
- No future Hezo app or target can read/reuse the seed.
- Retries are idempotent.
- Past/future tokens and multi-month catch-up are rejected.
- Server pepper rotation and destruction are tested.

### Metric correctness

- A production, consented, enabled, healthy installation contributes at most one row in a UTC month.
- Disabled, degraded, killed, expired, non-production, and non-consenting states do not emit a receipt.
- No URL visit, threat, report, Bloom match, PIR request, or block event is required or counted.
- The aggregation query equals the distinct accepted token rows after deletions/corrections.
- Provisional and final states cannot be confused in API, dashboard, or public copy.
- A final record contains definition/methodology provenance and purge evidence.
- Apple Active Devices remains a separate cross-check and is never merged into MPD.
- No dashboard labels month-over-month change as 30-day or 90-day cohort retention.

### Withdrawal and deletion

- Turning MPD off stops new issuance before the next network operation.
- Every locally derivable open/provisional-month deletion is idempotent and returns a generic result.
- Offline deletion retries contain only the deletion capability and expire.
- Re-consent/reset behavior and possible same-month recount are tested and documented.
- MPD raw rows and month pepper disappear at finalization from primary, replica, queue, cache, snapshot, and backup according to policy.
- Final aggregate history cannot be queried back to a token.
- Analytics withdrawal clears pending batches and exercises deletion capabilities for still-raw batches.
- Report deletion returns a generic result, destroys readable restricted content and its per-record key, removes the deletion-capability digest, and applies the approved O-017 rule to report-only derived support.
- Report live, replay, replica, object, key, and backup deadlines pass the approved O-017 fixtures.

### Plane isolation

- Contract tests fail if a denied field is added to any request or schema.
- Database roles cannot read another plane.
- Queue and object-store credentials are plane-specific.
- Egress policy prevents the MPD and analytics services from reaching intelligence or anti-abuse stores.
- No shared request/trace ID crosses anti-abuse issuance and measurement redemption.
- O-018 PIR tests prove inactivity and absolute expiry delete the `User-Identifier` digest and evaluation key together without breaking the validated Apple lifecycle.
- An analyst/support account cannot search multiple planes.
- The Trust Graph never receives App Attest, MPD, analytics, advertising, account, or stable installation identifiers.
- The filter-runtime store cannot read another plane; its User-Identifier digest/evaluation key expires and never appears in logs, exports, support tools, metrics, or product identifiers.

### Logging and processor verification

- Canary URLs, query secrets, App Attest values, MPD tokens, Privacy Pass credentials, deletion handles, and analytics batches do not appear in edge, load-balancer, application, APM, trace, crash, database, queue, cloud, support, or backup logs.
- Source IP and full user agent are absent from retained application/processor records, or the exception blocks release and updates disclosures.
- Metrics reject unbounded labels.
- Processor retention, access, subprocessor, deletion, and incident settings match the data inventory.

### App Attest and gated anonymous integrity

- App Attest registration/assertion fixtures prove chain, nonce, RP ID, environment, key, body digest, counter, replay, reset, and unsupported-device behavior.
- App Attest key IDs remain exclusively in anti-abuse storage.
- An issued measurement capability is scope-, origin-, and time-bounded.
- The measurement service cannot recover the App Attest key from a capability.
- If Privacy Pass is selected, standard test vectors, blindness/unforgeability library tests, replay/spent-token behavior, origin/month binding, timing-correlation exercises, key rotation, issuer outage, and independent review pass before public use.
- No documentation claims that a simple stripping gateway provides cryptographic unlinkability.

### App Store and legal readiness

- Physical-device network capture matches the privacy inventory and labels.
- PrivacyInfo.xcprivacy, required-reason APIs, SDK manifests, privacy policy, consent copy, and App Store Connect answers reconcile.
- IDFA/AdSupport, IDFV-based measurement, advertising, attribution, session replay, and unapproved analytics SDKs are absent.
- Privacy Choices and in-app deletion work without an account.
- The state-law matrix, processor contracts, age decision, incident plan, and public MPD wording have named legal/product approval.
- Every objective public privacy, coverage, effectiveness, and audience-size claim has pre-publication substantiation.

## Primary-source reference set

Apple:

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Establishing your app’s integrity with App Attest](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
- [Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [URL filters](https://developer.apple.com/documentation/networkextension/url-filters)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)
- [App Store Connect analytics metric definitions](https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions)

United States:

- [FTC Privacy and Security](https://www.ftc.gov/business-guidance/privacy-security)
- [FTC Advertising Substantiation Policy](https://www.ftc.gov/legal-library/browse/ftc-policy-statement-regarding-advertising-substantiation)
- [FTC App Developers: Start with Security](https://www.ftc.gov/business-guidance/resources/app-developers-start-security)
- [FTC Marketing Your Mobile App](https://www.ftc.gov/business-guidance/resources/marketing-your-mobile-app-get-it-right-start)
- [FTC COPPA FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [California Civil Code section 1798.140](https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CIV&sectionNum=1798.140.)
- [California Attorney General CCPA overview](https://oag.ca.gov/privacy/ccpa)
- [California Privacy Protection Agency FAQ](https://cppa.ca.gov/faq)
- [Colorado Attorney General: Colorado Privacy Act](https://coag.gov/resources/colorado-privacy-act/)
- [NISTIR 8053: De-Identification of Personal Information](https://www.nist.gov/publications/de-identification-personal-information)

Privacy Pass:

- [RFC 9576](https://www.rfc-editor.org/info/rfc9576/)
- [RFC 9577](https://www.rfc-editor.org/info/rfc9577/)
- [RFC 9578](https://www.rfc-editor.org/rfc/rfc9578.html)
