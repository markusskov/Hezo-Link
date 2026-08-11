# Apple URL Filter and App Attest

This document is the implementation contract for Hezo Link's iOS 26 URL Filter and App Attest work. It records Apple requirements verified against current primary sources on **2026-08-11**. Apple can change entitlements, onboarding, beta APIs, service limits, and validation guidance independently of this repository. Recheck the linked sources when Xcode is upgraded, before the first TestFlight build, and before App Store submission.

The two Apple systems solve different problems:

| System | Hezo use | What it must not become |
|---|---|---|
| Network Extension URL Filter | Private, passive enforcement of a qualified binary blockset | A browsing-history, block-event analytics, rich-verdict, DNS, packet, or all-app inspection system |
| App Attest | Anti-abuse proof for requests made by a genuine Hezo app installation | An account, device fingerprint, MPD identifier, Trust Graph identifier, or substitute for Privacy Pass |

The URL Filter is a binary projection of the Trust Graph. The automatic path receives only policy-approved, precisely scoped block entries. Evidence, explanations, `Caution`, `Unknown`, reports, campaign relationships, paste/share/QR checks, and false-positive handling stay in Hezo's manual-check APIs.

## Accepted V1 platform decisions

- Minimum platform is iOS 26 on a physical iPhone.
- Manual checks ship independently of URL Filter approval or availability.
- The consumer URL Filter is fail open: `shouldFailClosed` is explicitly `false`.
- The containing app and control extension never receive passive browsing URLs.
- No consumer block count, block callback, or custom passive block page is promised.
- Only current, qualified, precisely scoped Route A entries enter the initial automatic blockset.
- Bloom and PIR artifacts come from one signed canonical generation. PIR generation `N` is available before Bloom generation `N` is promoted, and a compatible prior generation is retained for rollback.
- App Attest runs in the containing app, not the URL Filter control extension.
- App Attest state remains in the anti-abuse plane. It is stripped before any semantic security-intelligence, MPD, or analytics request.
- URL Filter setup, measurement consent, and analytics consent remain separate user choices. App Attest has its own disclosed anti-abuse purpose, retention, storage, logging, and failure behavior; it is not a fourth V1 consent switch unless the approved privacy/legal data flow specifically requires one.

## 1. URL Filter platform contract

### 1.1 What iOS 26 covers

Apple's URL Filter automatically evaluates HTTP and HTTPS URL requests made through WebKit and Foundation's `URLSession`, including Safari and ordinary `WKWebView` traffic. A client using another HTTP implementation or network stack is covered only if that client voluntarily calls `NEURLFilter.verdict(for:)` before loading the URL and honors `.deny`.

The voluntary API returns `.allow`, `.deny`, or `.unknown`. The participating client chooses its behavior and UI for `.unknown` and `.deny`; Hezo cannot force an arbitrary third-party client to call it or honor it.

Consequences for product and test language:

- Do not describe URL Filter as packet inspection, DNS filtering, a VPN, antivirus, or guaranteed interception of every app.
- Do not claim automatic coverage for a browser or app solely because it can open a URL. Test its actual networking path on the supported OS.
- Custom sockets, non-HTTP protocols, and nonparticipating networking stacks are outside the automatic V1 contract.
- Browser-engine and networking-stack policy can change by OS and app release. Keep a physical-device compatibility matrix for launch-critical apps.

Primary sources: [Apple URL filters](https://developer.apple.com/documentation/networkextension/url-filters), [WWDC25: Filter and tunnel network traffic with NetworkExtension](https://developer.apple.com/videos/play/wwdc2025/234/), and [Apple DTS explanation of coverage and deployment](https://developer.apple.com/forums/thread/815498).

### 1.2 What Hezo can observe

The system, not Hezo code, is on the per-request decision path. The containing app configures the feature. The control extension supplies the Bloom prefilter. Neither receives the passive request URL, PIR query result, or a consumer block event.

iOS 26 therefore provides no supported basis for:

- a consumer browsing history;
- a per-installation or aggregate "threats blocked" counter;
- an automatic explanation screen for the blocked URL;
- a callback that opens Hezo with the blocked URL;
- MPD based on URL requests, PIR queries, or blocks;
- automatic reporting of suspicious-but-not-blocked URLs to Hezo.

Apple DTS states that URL Filter has no configuration for a custom system denial page or denial reason. A voluntarily participating third-party app may choose its own `.deny` UI, but Apple does not give Hezo a reason-bearing callback. The app can invite a user to paste or share a URL for a rich explanation as a separate deliberate action.

Primary source: [Apple DTS: URL Filter Network Extension](https://developer.apple.com/forums/thread/815498).

### 1.3 Consumer, supervised, and beta reporting behavior

URL Filter itself can be used on an unmanaged consumer device. Do not confuse it with the older content-filter provider APIs whose iOS deployment is supervised-device constrained. An MDM-installed configuration still requires the applicable supervision and payload rules.

The public blocked-entry reporting properties added in the iOS 27 beta SDK are not part of the iOS 26 V1 contract. Apple's current beta documentation says reporting is sent only from supervised devices; a configuration can be saved on an unmanaged device without producing reports. Reports contain accumulated matching blocklist entries, not a guaranteed record of each complete URL the user visited.

Likewise, iOS 27 beta parsing and regex customization must not leak into the iOS 26 implementation or launch claims. Revisit them only through an ADR after the API is non-beta and the privacy model is reviewed.

Primary sources: [`reportEndpoint`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/reportendpoint), [Network Extension updates](https://developer.apple.com/documentation/updates/networkextension), and [`urlParsingConfiguration`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/urlparsingconfiguration).

## 2. Xcode targets, identifiers, entitlements, and configuration

### 2.1 Required targets

V1 needs:

1. the containing Hezo Link iOS app; and
2. a URL Filter control app extension implementing `NEURLFilterControlProvider`.

The containing app owns setup, status, enable/disable UX, fail behavior, PIR configuration, authentication-token bootstrap, cache reset, and parameter refresh. The control extension owns only prefilter lifecycle: start, stop, and fetch/verify/return a Bloom artifact.

Do not run App Attest from the control extension. Do not route manual URL checks through the control extension. Do not put a general API credential, App Attest key, App Attest receipt, MPD secret, analytics identifier, or raw URL in an App Group shared with the extension. If an App Group is approved, its URL Filter contract is limited to nonidentity state such as the verified manifest generation, expiry/freshness, bounded update outcome, and signed kill-switch state needed by the app's health adapter.

### 2.2 Exact Network Extension entitlement

Both the containing app and the URL Filter control extension use the same entitlement key with an array value:

~~~xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>url-filter-provider</string>
</array>
~~~

There is no entitlement key named `com.apple.developer.networking.networkextension.url-filter-provider`. Add the Network Extensions capability to the explicit App IDs and signing profiles for both targets, then verify the signed entitlements in archived artifacts rather than trusting the project editor.

The control extension's `Info.plist` extension point is:

~~~xml
<key>EXAppExtensionAttributes</key>
<dict>
    <key>EXExtensionPointIdentifier</key>
    <string>com.apple.networkextension.url-filter-control</string>
</dict>
~~~

The main app bundle identifier is the identifier registered for the NEURLFilter PIR/OHTTP use case. The control extension bundle identifier is passed separately as `controlProviderBundleIdentifier` when configuring `NEURLFilterManager`.

Primary sources: [Network Extension entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.networkextension), [Apple's URL Filter sample](https://developer.apple.com/documentation/networkextension/filtering-traffic-by-url), and [Apple DTS entitlement clarification](https://developer.apple.com/forums/thread/821619).

### 2.3 Containing-app setup sequence

The app must perform setup through the shared `NEURLFilterManager` in this order:

1. Call `loadFromPreferences()` before reading or mutating persisted configuration.
2. Obtain a valid accountless PIR bearer token using the Stage 0 design in section 7.
3. Call `setConfiguration(pirServerURL:pirPrivacyPassIssuerURL:pirAuthenticationToken:controlProviderBundleIdentifier:)`.
4. Set `prefilterFetchInterval` explicitly. The proposed V1 beta value is the minimum documented interval, 2,700 seconds, subject to artifact-size and operational validation. Do not rely on a framework or sample default.
5. Set `shouldFailClosed = false` explicitly.
6. Set a truthful `localizedDescription` and `isEnabled` state.
7. Call `saveToPreferences()` and handle rejection or user cancellation without breaking manual checks.
8. Observe status changes through `handleStatusChange()`. Map `invalid`, `stopped`, `starting`, `running`, and `stopping` to bounded product states.
9. After an unexpected stop, inspect `lastDisconnectError` for diagnostics, while treating it as potentially stale and never copying raw framework text into analytics.
10. Treat `serverSetupIncomplete` as a configuration/onboarding failure, not a clean or healthy state.

The app must present setup as optional protection configuration, not an account wall. The exact authorization and Settings UX is tested on physical iOS 26 devices because Apple's public documentation does not fully specify every consumer prompt and recovery state.

Primary sources: [`NEURLFilterManager`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager), [`setConfiguration`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/setconfiguration(pirserverurl:pirprivacypassissuerurl:pirauthenticationtoken:controlproviderbundleidentifier:)), [`prefilterFetchInterval`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/prefilterfetchinterval), and [`shouldFailClosed`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/shouldfailclosed).

### 2.4 Status and product copy

Use a small app-owned status model rather than exposing Apple enum names:

| App state | Minimum evidence | Product behavior |
|---|---|---|
| Not set up | Manager disabled or no valid configuration | Offer setup; manual checks remain available |
| Starting | Manager reports starting | Do not yet claim protection is active |
| Protected | Manager enabled and running; app health adapter has a valid, unexpired prefilter generation; no active kill switch or known degraded state | May qualify for a consented MPD health receipt under document 02 |
| Degraded | Enabled but not running, stale beyond policy, or known service/configuration failure | Ordinary browsing remains allowed; show troubleshooting and freshness truthfully |
| Paused | User disabled it or a signed safety control is active | Explain that passive protection is paused; manual checks remain available |

`lastDisconnectError` is diagnostic context, not the sole health source. Never turn a PIR request count into a protection-health claim.

## 3. Prefilter and blockset contract

### 3.1 How the decision path works

The iOS 26 path is intentionally private:

~~~text
HTTP(S) URL through a covered client
              |
              v
    system-owned Bloom prefilter
       | negative       | positive
       v                v
     allow      encrypted PIR membership query
                         |
                exact absent | exact value = 1
                         |    |
                         v    v
                       allow deny
~~~

A Bloom positive is only a reason to perform a private lookup. It is not evidence and must not itself block. A Bloom false positive resolves to allow through the exact PIR dataset. A URL missing from the Bloom never reaches PIR, so a stale Bloom creates false negatives for newly added threats.

### 3.2 Dataset rules

The blockset compiler must:

- export only `block_eligible` entries whose evidence and exact scope satisfy document 03;
- build Bloom and PIR from the identical canonical manifest;
- encode each PIR URL key in Apple's URL Filter data format, without a scheme and with integer value `1`;
- Punycode every applicable hostname before hashing or publication;
- match Apple's documented sub-URL parsing behavior for host, port, path, query, and fragment candidates;
- exclude wildcard and regex semantics from the iOS 26 format;
- distinguish exact path evidence from host-wide evidence so canonicalization cannot widen a block;
- use Apple's `BloomFilterTool` and sample fixtures as the reference implementation;
- pin a canonicalizer version, tool version, compiler version, manifest digest, PIR parameter version, and source blockset generation in the signed release manifest.

Do not independently "simplify" URLs for this projection. In particular, do not strip query or fragment data before security analysis, and do not assume the manual-check canonical form is automatically identical to Apple's enforcement candidates. Prove equivalence with fixtures.

Primary sources: [`NEURLFilterManager`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager), [Apple PIR sample repository](https://github.com/apple/pir-service-example), and [Apple's NEURLFilter data format](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/NEURLFilterDataFormat.md).

### 3.3 Bloom implementation contract

`fetchPrefilter(existingPrefilterTag:)` has two distinct behaviors:

- On the first call, where the existing tag is absent, the extension must return a valid non-null Bloom prefilter.
- On later calls, it may return `nil` to state that the installed prefilter remains current. The system retains the current filter.

Apple specifies 32-bit FNV-1a and 32-bit MurmurHash3 with double hashing for the Bloom artifact. All input URLs must already be Punycode-normalized. Use the exact Apple formula and seed behavior; a merely similar Bloom implementation is incompatible. Prefer Apple's tool to produce fixtures, and require byte-for-byte conformance before accepting another generator.

For UTF-8 input `x`, the required index family is:

~~~text
h1 = FNV-1a-32(x)
h2 = MurmurHash3-32(x, murmurSeed)

for i in 0 ..< hashCount:
    index[i] = (h1 + i * h2) mod bitCount
~~~

The implementation uses the same 32-bit wrapping arithmetic, byte order, seed, `bitCount`, and `hashCount` as the Apple artifact. Cross-language tests must compare both the calculated indices and final bytes with Apple's `BloomFilterTool`; matching only an observed allow/deny case is insufficient.

Use a content digest tied to the signed generation, such as SHA-256, as the prefilter tag. For large bitsets, return a verified temporary file using the framework's file-backed path rather than duplicating the full artifact in memory. The file contains only the opaque bitset, never URL source lists. Apple's public API does not state exactly when ownership or copying completes, so do not delete the file immediately after returning it; copy the official sample's lifecycle first, then prove a bounded stale-file cleanup policy on physical devices before changing that behavior.

The extension must authenticate the artifact manifest, verify digest, size, format version, declared bit count, hash count, and safe resource bounds before returning a new prefilter. On a later corrupt or unavailable update, keep the last-known-good filter by returning no replacement. An invalid first artifact is a startup failure and must surface as degraded rather than installing unverified data.

Primary source: [`fetchPrefilter(existingPrefilterTag:)`](https://developer.apple.com/documentation/networkextension/neurlfiltercontrolprovider/fetchprefilter(existingprefiltertag:)).

### 3.4 Fetch freshness

Apple currently documents a framework default `prefilterFetchInterval` of 86,400 seconds and a minimum of 2,700 seconds. Scheduling may drift. Apple's sample material has also used 45 minutes as an app default; that is not proof of the framework default. Hezo sets the value explicitly and measures effective age rather than assuming exact execution.

The signed manifest includes `generated_at`, `promoted_at`, `expires_at`, generation, and compatible PIR parameter range. If the filter is running but the artifact has exceeded the policy freshness window, the app shows degraded protection. Manual checks remain capable of using current server intelligence.

### 3.5 Publication, cache, refresh, and rollback

For every generation:

1. Freeze a deterministic canonical input manifest.
2. Generate PIR and Bloom artifacts from that same manifest.
3. Sign the release manifest and verify it in an isolated staging environment.
4. Publish PIR generation `N` and verify `/config`, `/key`, and `/queries` against it.
5. Retain all PIR parameters and data needed by installed generation `N-1`.
6. Promote Bloom generation `N` atomically.
7. Invoke `resetPIRCache()` after a material PIR dataset change so cached results cannot outlive a removal or correction.
8. Invoke `refreshPIRParameters()` when reprocessing changes the parameter shape, such as shard count, encryption parameters, table size, or cuckoo parameters. Do not use it as a routine substitute for data publication.
9. Observe rollout health using aggregate, bounded operational metrics that contain no URL or stable installation identity.
10. Roll back the manifest/Bloom to a still-supported generation if validation fails. Keep the compatible PIR generation available throughout rollback.

Adding a threat requires the new Bloom to reach a device before that new entry can reach PIR. Removing a threat requires the PIR target and cache state to be corrected even while an older Bloom may continue producing harmless false-positive lookups. Recovery targets and user copy must reflect these asymmetric propagation limits.

Primary sources: [`resetPIRCache()`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/resetpircache()), [`refreshPIRParameters()`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/refreshpirparameters()), and [Apple PIR service example](https://github.com/apple/pir-service-example).

### 3.6 Fail-open and kill-switch behavior

`shouldFailClosed` defaults to false, but V1 sets it to false explicitly. If the system cannot make a decision, including a PIR communication failure, ordinary browsing is allowed. This availability choice does not silently convert an unknown result into a clean security observation; it is only the passive enforcement behavior.

Required safety controls:

- signed remote publication kill switch;
- signed generation denylist;
- last-known-good Bloom retention;
- compatible PIR generation retention;
- atomic manifest promotion and rollback;
- bounded startup/update resource use;
- degraded app status for setup, relay, service, prefilter, or freshness failure;
- manual checks independent of the passive path.

A remote app-side disable action is not guaranteed to execute immediately because iOS may not launch the app in the background. Do not promise an instantaneous global device switch. Server-side availability controls, expiration, rollback, and fail-open behavior are the dependable safety layers; the app applies local configuration changes when it next runs or receives an allowed execution opportunity.

## 4. OHTTP, PIR, and Privacy Pass production service

### 4.1 Ownership and privacy boundary

For distribution builds, the system sends URL Filter service traffic through Oblivious HTTP. Apple provides the OHTTP relay. Hezo must operate or contract for:

- an OHTTP gateway that supports HTTP/2;
- a PIR service exposing the protocol endpoints, including `/config`, `/key`, and `/queries`;
- a Privacy Pass token issuer, either at a separate configured origin or, where supported by Apple's API, at the PIR origin;
- the bearer-token bootstrap and rotation service used by the containing app;
- signed Bloom artifact distribution to the control extension.

The privacy design combines separate protections. OHTTP prevents Hezo's gateway/service side from receiving the client's source IP in the ordinary flow. PIR prevents the service from learning the URL membership query or its result in cleartext. Privacy Pass allows repeated private requests without attaching the long-lived bearer token to each PIR query.

Apple's PIR protocol does include a pseudorandom `User-Identifier` header so the service can associate an uploaded evaluation key with later encrypted queries. That value can correlate protocol requests even though it does not reveal the bearer-token identity or requested URL. Treat it as pseudonymous protocol state: never log, export, analyze, or forward it, and delete the associated evaluation key on the O-018-approved inactivity/absolute-expiry schedule. It is not an MPD, analytics, anti-abuse, or Trust Graph identifier.

The required service behavior is:

- `POST /config` returns current use-case configuration and evaluation-key status;
- `POST /key` accepts the client's homomorphic-encryption evaluation key;
- `POST /queries` evaluates encrypted PIR requests using the stored evaluation key;
- PIR requests authenticate with one-use Privacy Pass tokens, not the long-lived bearer token;
- the issuer exposes `/.well-known/private-token-issuer-directory`, `/token-key-for-user-token`, and its advertised issuance URI;
- only issuer requests carry the long-lived bearer token;
- request size, Protobuf depth/count, evaluation-key storage, concurrency, expiration, and rate limits are bounded and tested.

Do not add custom per-client headers, query logging, request-body debugging, stable cookies, or high-cardinality timing labels around these services. Suppress the protocol `Authorization`, `User-Identifier`, and detailed `User-Agent` fields at every layer. Edge, gateway, issuer, PIR, and observability configuration must be reviewed together because one default access log can defeat the intended privacy boundary.

Primary sources: [Apple URL filters](https://developer.apple.com/documentation/networkextension/url-filters), [Apple PIR privacy explanation](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/PrivacyExplanation.md), [Apple PIR HTTP endpoints](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/HTTPEndpoints.md), and [Apple PIR authentication](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Authentication.md).

### 4.2 Production origin requirements

Apple's current onboarding guide says that, starting with iOS and macOS 26.4, distribution configuration must use origins on subdomains rather than custom paths. Treat the production contract as:

- HTTPS only;
- standard HTTPS port;
- origin URL with no custom path;
- no trailing slash;
- separate subdomain origins where separate services are configured;
- OHTTP gateway negotiates HTTP/2.

Examples:

~~~text
https://gateway.urlfilter.example
https://issuer.urlfilter.example
https://service.urlfilter.example
~~~

Direct-Xcode development installs are intentionally more permissive and may use HTTP, custom ports, or paths. That convenience is not evidence that a distribution configuration is valid.

Primary source: [Apple OHTTP onboarding guide](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Onboarding.md).

### 4.3 Distribution matrix

| Install/signing path | Apple relay onboarding required for a valid release proof? | What it proves |
|---|---:|---|
| Direct install from Xcode | No; Apple documents a development bypass | App/extension structure, local service protocol, Bloom/PIR logic |
| Ad hoc distribution | Yes | Distribution signing and relay provisioning |
| TestFlight | Yes | Production App Attest environment and Apple OHTTP relay path |
| App Store | Yes | Release path |
| Enterprise distribution | Yes | Distribution path if ever used |
| Developer ID on macOS | Yes | Out of V1 scope, but covered by Apple's current distribution guidance |

Moving from development to distribution does not use a different URL Filter entitlement. It does require a separate OHTTP relay onboarding and approval process. Register the Network Extension URL Filter configuration in **CloudKit Console → Identity & Trust**. Apple does not currently publish a reliable approval SLA or portal status contract; an Apple DTS engineer reported seeing forum timelines measured in weeks rather than days. Treat that only as planning evidence, not a guarantee.

Primary sources: [WWDC25 NetworkExtension session](https://developer.apple.com/videos/play/wwdc2025/234/), [Apple OHTTP onboarding](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Onboarding.md), [CloudKit Identity & Trust](https://icloud.developer.apple.com/dashboard/identity), and [Apple DTS distribution clarification](https://developer.apple.com/forums/thread/821619).

### 4.4 Current Apple onboarding checklist

Before registration, Hezo must have a live validation environment and provide:

- the main Hezo Link application bundle identifier for NEURLFilter;
- the PIR use-case identifier `<main-app-bundle-id>.url.filtering` where required by the PIR service configuration;
- expected request and response sizes;
- peak requests per second and total requests per day, by continent;
- a PIR test record `www.apple.com/url-filter-test` with integer value `1`;
- a working HTTP/2 OHTTP gateway;
- the OHTTP gateway configuration resource;
- the OHTTP gateway origin;
- the Privacy Pass issuer origin;
- the PIR service origin;
- a bearer token Apple can use to validate the deployment;
- a DNS TXT record on the service domain: `apple-url-filter=<main-app-bundle-id>`;
- all gateway, issuer, and PIR components running while Apple validates them.

Use the main application bundle identifier for the current NEURLFilter onboarding form and DNS proof. Some older Apple sample text has referred to an extension identifier when describing PIR setup; current onboarding, API guidance, WWDC material, and Apple DTS guidance distinguish the main app identifier from the control extension identifier. Record the exact submitted values and escalate any portal disagreement to Apple rather than guessing.

### 4.5 Apple sample code is not a production service

Apple's `pir-service-example` is the protocol reference and test oracle. Its own repository warns that it is functional example code and should not be run as a production service. Hezo must add production authentication, isolation, capacity control, observability without query leakage, high availability, signed/versioned datasets, rollback, patching, abuse controls, and incident response.

The repository is Apache-2.0 licensed. If code is reused rather than used only as a reference, retain required notices and review all transitive dependency licenses. Pin a reviewed revision; do not deploy from the moving `main` branch.

Primary sources: [Apple PIR service example](https://github.com/apple/pir-service-example) and [license](https://github.com/apple/pir-service-example/blob/main/LICENSE.txt).

## 5. App Attest role and app-side lifecycle

### 5.1 Scope

App Attest lets Hezo's anti-abuse server verify that a request is associated with a genuine instance of Hezo Link, using an Apple-attested hardware-backed key where supported. It does not prove that:

- the person is a particular identity;
- the device or OS is uncompromised;
- the submitted URL or report is truthful;
- one key equals one unique human or durable physical device;
- requests should bypass semantic validation, rate limits, or fraud controls.

The key ID, public key, receipt, counters, and risk metrics remain only in the anti-abuse plane. The anti-abuse service may issue a short-lived, purpose-scoped capability after verification. The receiving intelligence, report, token-bootstrap, or measurement service sees the capability and purpose, not the App Attest identity.

### 5.2 Extension restriction

Call `DCAppAttestService` only from the containing iOS app. Apple's current sources conflict on the complete supported-extension list: the `isSupported` reference says only watchOS extensions on watchOS 9 or later, while WWDC26 says Action and SSO app extensions are supported. Neither source includes Network Extension or URL Filter extensions, and the API reference warns that `generateKey` fails for unsupported extension types regardless of the value reported by `isSupported`. A URL Filter control extension must therefore not generate a key, attest a key, or create an assertion.

If the filter needs an authenticated configuration outcome, the containing app completes App Attest and writes only the minimum nonidentity configuration through the supported manager API. Do not share the App Attest key ID or material with the extension.

Primary sources: [`DCAppAttestService.isSupported`](https://developer.apple.com/documentation/devicecheck/dcappattestservice/issupported) and [WWDC26: Secure your apps with App Attest](https://developer.apple.com/videos/play/wwdc2026/201/).

### 5.3 Exact entitlement and environments

Add the App Attest capability to the containing app's explicit App ID. Its entitlement is:

~~~xml
<key>com.apple.developer.devicecheck.appattest-environment</key>
<string>development</string>
~~~

or:

~~~xml
<key>com.apple.developer.devicecheck.appattest-environment</key>
<string>production</string>
~~~

Environment rules:

| Build/install | Effective App Attest environment |
|---|---|
| Direct development build with development entitlement | Sandbox/development |
| Direct development build with production entitlement | Production; use only for deliberate production-path testing |
| TestFlight | Production regardless of entitlement value |
| App Store | Production regardless of entitlement value |
| Enterprise distribution | Production regardless of entitlement value |

Development and production keys, attestations, receipts, metrics, verification policies/fixtures, and database rows must not interoperate. Reject environment confusion server-side. Use the Apple trust anchors Apple documents for each artifact; environment separation comes from the AAGUID, endpoint, receipt, key, and server-owned configuration rather than inventing a different root certificate.

Primary sources: [App Attest environment entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.devicecheck.appattest-environment) and [Preparing to use App Attest](https://developer.apple.com/documentation/devicecheck/preparing-to-use-the-app-attest-service).

### 5.4 One-installation lifecycle

Use one App Attest key for one app installation on one device:

1. Check `DCAppAttestService.shared.isSupported` in the containing app.
2. If supported and no usable registered key exists, call `generateKey()` once and persist the returned key ID immediately in protected app storage.
3. Request a 32-byte randomized, single-use registration challenge from Hezo's anti-abuse service.
4. Compute the exact `clientDataHash` required by the registration contract and call `attestKey(_:clientDataHash:)` once for that key.
5. Send the key ID, attestation object, challenge ID, and contract version to the anti-abuse service over authenticated TLS.
6. The server validates the full attestation and stores the public key before acknowledging registration.
7. For each protected operation, obtain a fresh purpose-scoped challenge, construct canonical client data bound to that exact request, call `generateAssertion(_:clientDataHash:)`, and submit it to anti-abuse.
8. Anti-abuse validates and atomically consumes the challenge and advances the counter, then returns a short-lived capability restricted to the requested operation.

App Attest keys normally survive an app update but are scoped to an installation and are not restored or migrated as a durable cross-installation identity. A reinstall, device migration, backup/restore discontinuity, or invalid key requires a fresh key and registration. Protected storage may have platform-specific persistence behavior; never interpret a surviving locally stored key ID as proof of continuity. If Apple reports `invalidKey`, discard stale local state and restart registration.

App Attest is not available on every execution environment. Unsupported devices keep core read-only manual checks under stricter anonymous abuse limits. A request that can influence scoring, reports, or automatic enforcement may require valid attestation/capability according to document 06 and must never silently gain influence because attestation is unavailable.

Primary sources: [Establishing app integrity](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity), [`generateKey`](https://developer.apple.com/documentation/devicecheck/dcappattestservice/generatekey%28completionhandler%3A%29), [`attestKey`](https://developer.apple.com/documentation/devicecheck/dcappattestservice/attestkey%28_%3Aclientdatahash%3Acompletionhandler%3A%29), and [`generateAssertion`](https://developer.apple.com/documentation/devicecheck/dcappattestservice/generateassertion%28_%3Aclientdatahash%3Acompletionhandler%3A%29).

### 5.5 Retry and reset behavior

- If `attestKey` returns Apple's `serverUnavailable`, retry the same key with the same `clientDataHash` after bounded exponential backoff and jitter.
- Do not call `attestKey` again with unrelated challenge data for a key that may already be attested. A key can be attested only once.
- Make Hezo's registration endpoint idempotent by key ID and challenge transaction. If Hezo accepted an attestation but the response was lost, the client retries the same registration object rather than generating a new Apple attestation.
- For a definitive nontransient attestation failure, mark the attempted key unusable and begin with a fresh key, while first checking whether an earlier server registration was accepted.
- On assertion `invalidKey`, expire related capabilities, remove stale local state, and register a new key.
- On network or Apple-service failure, do not reuse an assertion/challenge for a different body, path, or purpose. Retry the identical idempotent transaction or obtain a fresh challenge.

Apple's current guidance asks developers to keep `attestKey` traffic below 100 requests per second across all app installations and to ramp no more than 10 million users per day per app. Apple describes the limit as dynamic, not a reserved quota or SLA. Implement server-controlled rollout, a kill switch, jittered retry, idempotency, and dashboards before enabling broad attestation.

Primary source: [Preparing to use App Attest](https://developer.apple.com/documentation/devicecheck/preparing-to-use-the-app-attest-service).

## 6. App Attest server verification contract

### 6.1 Challenge and client-data contract

Every registration and assertion starts with a server-generated cryptographically random 32-byte challenge. Apple requires at least 16 bytes; Hezo's stricter V1 default is 32. Store only what the verifier needs, with:

- a random challenge ID distinct from the challenge value;
- environment;
- key-registration attempt or registered key reference;
- one purpose enum;
- canonical HTTP method and route template;
- SHA-256 of the exact request body bytes or an explicitly versioned empty-body digest;
- contract version;
- issue and expiry time;
- unused/consumed state.

The proposed challenge TTL is five minutes. A challenge is valid for one exact operation. The canonical client data must be deterministic and domain separated, for example by a fixed Hezo protocol label and version. It binds the challenge, purpose, method, route, and request-body digest. Never hash an object whose JSON field order, Unicode normalization, floating-point representation, or omitted/default fields can differ between client and server. Use the byte-level canonicalization contract from document 06 and frozen cross-language fixtures.

Consume the challenge and update assertion state atomically only after all cryptographic and semantic checks succeed. Expired, used, wrong-environment, wrong-purpose, wrong-route, and wrong-body challenges fail. Do not reveal which cryptographic subcheck failed to the client.

### 6.2 Attestation-object validation

The anti-abuse server must implement Apple's complete validation guide, not merely verify a certificate signature. At minimum, in this order:

1. Apply request-size, CBOR nesting, item-count, and byte-string limits; decode strict CBOR and require format `apple-appattest`.
2. Extract the credential certificate and intermediate from `x5c`, validate their dates, constraints, signatures, and chain to the pinned Apple App Attestation Root CA. Do not substitute the operating system's general trust store.
3. Recompute `clientDataHash` from the exact registered challenge contract.
4. Compute the nonce from `authenticatorData || clientDataHash` as Apple specifies and compare it in constant time with certificate extension OID `1.2.840.113635.100.8.2` after correct ASN.1 decoding.
5. Extract the P-256 public key in ANSI X9.62 uncompressed form, hash it with SHA-256, encode it with standard Base64, and compare it with the submitted key ID.
6. Construct the expected App ID from the actual App ID prefix and bundle identifier. Do not assume the App ID prefix always equals the Team ID. Require the authenticator RP ID hash to equal SHA-256 of that exact App ID string.
7. Require the attestation sign counter to be zero.
8. Require the AAGUID allowed for the server-owned environment; production must never accept a development AAGUID.
9. Require the credential ID in authenticator data to match the key ID.
10. Parse authenticator flags, attested credential data, and any supported Apple authenticator-data extensions exactly; reject malformed, duplicate, trailing, or contradictory data.
11. Independently validate the attestation receipt. Store the encrypted receipt if Hezo enables Apple's fraud-risk refresh service; otherwise retain only the approved validation metadata and delete the raw receipt on the transient schedule.
12. Enforce that the public key/key ID is not already bound to a different anti-abuse installation record or environment.
13. Store the verified public key, key ID, environment, RP ID hash, AAGUID, initial counter, receipt metadata, and registration audit outcome in the anti-abuse store only.

No attestation blob, certificate, receipt, public key, key ID, challenge, assertion, or DeviceCheck JWT may enter ordinary logs, traces, crash reports, support tools, intelligence tables, MPD, or analytics.

Primary sources: [Attestation Object Validation Guide](https://developer.apple.com/documentation/devicecheck/attestation-object-validation-guide), [Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server), and [Apple App Attestation Root CA](https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem).

### 6.3 Assertion validation and replay protection

For every assertion:

1. Strictly decode the assertion object with the same parser limits.
2. Reconstruct the exact canonical client data from the stored challenge and received request and compute `clientDataHash = SHA256(clientData)`.
3. Compute `nonce = SHA256(authenticatorData || clientDataHash)` exactly as Apple specifies. Verify the ECDSA signature with the registered P-256 public key against that digest, using a crypto API's prehashed/digest mode where required so the digest is not accidentally hashed twice.
4. Verify the RP ID hash against the registered App ID.
5. Parse the unsigned assertion counter as specified by Apple and require it to be strictly greater than the stored counter. Do **not** require `previous + 1`; Apple says some increments can be skipped.
6. Verify environment, key state, purpose, route, method, body digest, contract version, expiry, and unused challenge state.
7. In one transaction, mark the challenge used and replace the stored counter with the accepted higher value.
8. Issue a short-lived, single-purpose capability with no App Attest key identifier in the downstream payload.

Concurrent assertions for the same key can arrive out of counter order. The higher accepted counter makes a later-arriving lower assertion invalid even if its signature is genuine. The client must serialize security-sensitive assertions per key or obtain a fresh challenge and assertion after a counter-race rejection. Never relax the monotonic check to accommodate concurrency.

The following must fail: exact replay, duplicate concurrent submission, stale counter, body substitution, route substitution, method substitution, purpose substitution, challenge substitution, expired challenge, wrong environment, wrong App ID, malformed CBOR, invalid signature, revoked key, and capability reuse outside scope.

Primary source: [Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server).

### 6.4 iOS 27 validation extensions

Apple's 2026 guidance adds authenticator-data extension fields including `apple_validation_category_01` and `apple_bundle_version_01` for newer SDK/OS combinations. V1 must remain compatible with valid iOS 26 attestations where those extensions are absent. If the fields are present, parse them strictly and compare them with a server-owned allowlist; do not trust the client to state its category or version.

Before making either field mandatory, freeze physical-device fixtures for each supported iOS/Xcode combination and confirm Apple's definition of bundle version. Current public material has not been fully consistent about OS gating and whether the version maps to `CFBundleVersion` or another bundle value. This is a Stage 0/DTS verification item, not permission to skip all extension parsing.

### 6.5 Receipt and fraud-risk service

Receipt validation is part of accepting an attestation. The later server-to-server exchange that refreshes the receipt and obtains Apple's fraud metric is optional. For every initial receipt:

- validate the receipt's PKCS #7/CMS signature and chain to Apple Root CA G3;
- require field 2 to contain the expected app identifier, field 3 to contain the attested public key, field 4 to contain the expected client hash, and field 12 creation time to be no more than five minutes old for an initial receipt;
- distinguish the App Attestation certificate root from the separate Apple receipt-signing root;
- if fraud-risk refresh is enabled, keep the latest encrypted receipt in the anti-abuse store and replace it with Apple's refreshed receipt response;
- refresh only after field 19 (`Not Before`) and before field 21 (`Expiration Time`), rather than on each user request;
- authenticate server-to-server calls with `Authorization: <JWT>`, using a short-lived ES256 JWT signed by a DeviceCheck-enabled Apple private key;
- use the sandbox endpoint only with development receipts and the production endpoint only with production receipts;
- keep the private key in KMS/HSM-backed signing, never in the app or repository;
- treat the approximately 30-day attested-key risk metric as an abuse signal, not a unique-device count or MPD input.

Current endpoints documented by Apple are:

~~~text
https://data-development.appattest.apple.com/v1/attestationData
https://data.appattest.apple.com/v1/attestationData
~~~

Primary source: [Assessing fraud risk](https://developer.apple.com/documentation/devicecheck/assessing-fraud-risk).

### 6.6 Minimum anti-abuse records

The anti-abuse store should model, at minimum:

| Record | Required fields |
|---|---|
| App Attest key | Opaque internal ID, key ID, environment, verified public key, App ID/RP hash, AAGUID, optional validated category/version, state, attested time, last accepted counter, revocation reason/time |
| Challenge | Opaque ID, environment, key/registration attempt, purpose, method, route, request digest, protocol version, issued/expiry time, consumed time |
| Receipt | Key reference, encrypted current receipt, validated issue/expiry metadata, last risk result/time, next refresh, state |
| Capability audit | Opaque capability digest, allowed purpose, issued/expiry/consumed state, verifier outcome; no raw token and no semantic URL/report body |

Unique constraints cover `(environment, key_id)` and one-time challenge/capability consumption. Counter update and challenge consumption share a transaction. Raw artifacts are retained only as long as the approved anti-abuse debugging and fraud-risk purpose requires, with an explicit deletion job and no general analyst access.

## 7. Accountless Privacy Pass token: Stage 0 release spike

`NEURLFilterManager.setConfiguration` requires the app to supply a PIR authentication token. Apple's system presents it to the Privacy Pass issuer as a bearer token and obtains unlinkable tokens for private service requests. This token is not an App Attest key and App Attest does not replace Apple's Privacy Pass, PIR, or OHTTP path.

V1 has no account, so token issuance is a release-critical open design, not a string to hard-code. The proposed design to test is:

1. The containing app registers its App Attest key with the anti-abuse service.
2. It requests a fresh assertion bound specifically to `pir_token_bootstrap` or `pir_token_refresh` and the exact request body.
3. Anti-abuse verifies the assertion and issues a short-lived internal capability with no key ID in its downstream claims.
4. The isolated PIR-auth service exchanges the capability for a revocable, rate-limited bearer token acceptable to Apple's configured Privacy Pass issuer.
5. The containing app stores the bearer token using platform data protection and passes it to `NEURLFilterManager.setConfiguration`.
6. Token refresh and reinstall issue a new token without creating an account or sending any URL, graph identifier, MPD token, or analytics identifier.

This is a hypothesis until Apple onboarding and physical distribution tests prove it. Stage 0 must answer:

- Does Apple's current issuer/sample protocol accept this accountless bearer-token lifecycle and rotation behavior?
- How and when does the system reuse, refresh, or reject a replaced authentication token?
- Can the issuer revoke abuse without maintaining a long-lived cross-purpose installation profile?
- What happens when App Attest is unsupported, temporarily unavailable, reset by reinstall, or rate-limited?
- Does `pirPrivacyPassIssuerURL = nil` validly cohost issuance at the PIR origin for Hezo's production configuration, and is a separate origin operationally safer?
- Which origin sees the long-lived bearer token, which logs can observe it, and how are all such logs suppressed?
- What issuance and PIR-query capacity must Apple approve for launch and 10x load?
- What recovery UX applies if the token is missing or invalid while manual checks remain available?

Do not embed a shared production bearer token in the app, ship one in configuration, put one in an App Group, derive one from IDFV, or use the App Attest key ID itself as the token. Record the approved answer in an ADR and in the CloudKit Identity & Trust submission.

Primary sources: [`pirAuthenticationToken`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/pirauthenticationtoken), [`setConfiguration`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager/setconfiguration(pirserverurl:pirprivacypassissuerurl:pirauthenticationtoken:controlproviderbundleidentifier:)), and [Apple PIR authentication](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Authentication.md).

## 8. DeviceCheck and MPD boundaries

The legacy `DCDevice` API produces an ephemeral token that lets a server read or update two Apple-held per-device bits. It is a different facility from App Attest. Hezo Link V1 does not need those bits for URL filtering, App Attest assertion validation, or MPD.

Do not use DeviceCheck bits or tokens as an analytics identifier, an installation table join, or a workaround for reinstall deduplication. Introducing legacy DeviceCheck requires a separate privacy/threat-model ADR with a specific abuse purpose and retention policy.

MPD remains a separately consented app-side health receipt. It may report only that the manager was enabled and healthy/running at least once in the UTC month, using the rotating measurement design in document 02. It must not use App Attest key IDs, DeviceCheck tokens, PIR queries, URL Filter blocks, URLs, or domains. Anti-abuse may authorize a measurement receipt and then strip its identity before the measurement service receives the payload.

Primary source: [Accessing and modifying per-device data](https://developer.apple.com/documentation/devicecheck/accessing-and-modifying-per-device-data).

## 9. Stage 0 proof plan

Stage 0 uses reserved example domains and a synthetic 1,000-entry dataset. It must not open a live malicious site from a workstation, Simulator, or ordinary CI runner.

### 9.1 Apple administrative proof

- Name the Apple Developer team, main app ID, control extension ID, App ID prefix, App Group if any, signing owner, and backup owner.
- Enable and verify the Network Extension capability for both targets and App Attest for the containing app.
- Create development and distribution profiles; inspect the final signed entitlements.
- Register the URL Filter configuration in CloudKit Console Identity & Trust as soon as the live validation service exists.
- Record submitted origins, bundle ID, DNS TXT record, traffic estimates, test record, contact, submission date, Apple response, and current status.
- Decide the manual-only launch response if production onboarding is rejected or delayed.

### 9.2 Development URL Filter proof

- Run on a physical supported iPhone; Simulator success is not accepted as a networking proof.
- Verify allow, exact deny, Bloom false positive resolved by PIR allow, invalid/unknown, PIR outage, issuer outage, gateway outage, corrupt Bloom, missing initial Bloom, later unchanged Bloom, stale Bloom, cache reset, parameter refresh, rollback, disable, reinstall, and reboot.
- Verify automatic coverage in Safari, `WKWebView`, and `URLSession`.
- Build one nonparticipating custom-stack fixture and prove it is not automatically covered.
- Build one voluntary-client fixture and prove `.allow`, `.deny`, and `.unknown` handling.
- Prove the app and extension receive no passive URLs or block callbacks.
- Prove fail-open behavior without converting the incident into a clean intelligence observation.
- Prove generation `N`, retained `N-1`, addition propagation, removal propagation, corrupt promotion, and kill-switch recovery.

### 9.3 Distribution URL Filter proof

- Complete Apple OHTTP onboarding with live HTTPS origins, HTTP/2 gateway, DNS proof, bearer token, test record, and capacity estimates.
- Install a distribution path—TestFlight at minimum—on a physical iOS 26.4-or-later iPhone.
- Keep the Stage 0 TestFlight path restricted to an internal proof group unless O-010 is closed and every other external-testing prerequisite is satisfied. Obtain the required privacy-counsel review before TestFlight and use approved proof-scoped consent and disclosure artifacts; this evidence does not authorize external testing or close the final O-010 launch package.
- Prove the device uses the Apple OHTTP relay path and does not depend on direct-Xcode relaxations.
- Prove the Apple system-to-gateway/PIR/issuer path uses OHTTP and does not disclose the client's IP to those Hezo services. Separately prove an ordinary app-to-Hezo token-bootstrap edge does not retain or forward source IP into application logs or stores. No service or ordinary log may receive a clear URL or PIR result, an app-generated stable installation identifier, or the bearer token outside the issuer/auth boundary. Prove Apple's protocol-required pseudorandom `User-Identifier` and evaluation key stay confined to ephemeral PIR state and are never logged or joined.
- Exercise relay provisioning missing/incorrect and verify `serverSetupIncomplete` recovery.
- Confirm production origin validation rejects path, port, scheme, and trailing-slash configurations as expected.
- Measure the evaluation-key lifecycle, recovery, storage pressure, and key re-upload behavior needed to decide O-018; prove the selected inactivity and absolute expiries delete the `User-Identifier` digest and evaluation key together.

### 9.4 App Attest proof

- Validate a development attestation and assertion on a physical device using development-only records.
- Validate a TestFlight attestation against production-only records.
- Prove update continuity, reinstall/reset behavior, invalid-key recovery, unsupported-device fallback, Apple transient failure, and idempotent lost-response recovery.
- Reject replay, duplicate concurrency, counter rollback, out-of-order counter, body swap, method/route/purpose swap, expired challenge, environment confusion, bad App ID prefix, malformed CBOR/ASN.1, bad chain, bad nonce, bad signature, and revoked key.
- Verify attestation and assertion fixtures from an implementation independent of the production verifier.
- Prove an issued capability contains no App Attest key ID and cannot be used for another purpose or after expiry.
- Prove no App Attest material can reach intelligence, MPD, analytics, general logs, traces, or support tools.
- If receipts are enabled, validate sandbox and production risk calls separately and exercise receipt refresh, expiry, invalid signature, and key rotation.

### 9.5 Accountless token proof

- Exercise first issue, system configuration, normal refresh, reinstall, revocation, offline use, unsupported App Attest, issuer failure, and abuse throttling.
- Confirm the issuer never requires an account or URL.
- Confirm token/bootstrap state cannot join to the Trust Graph, MPD, or analytics.
- Obtain written Apple/onboarding confirmation or successful distribution evidence for the chosen topology and token lifecycle.

## 10. Release acceptance checklist

Passive URL protection is not release ready until every applicable item is checked:

### Project and platform

- [ ] Minimum deployment target and physical-device matrix include iOS 26 and the current iOS 26.x security release.
- [ ] Main app and control extension signed entitlements contain `com.apple.developer.networking.networkextension` with `url-filter-provider`.
- [ ] Control extension uses `com.apple.networkextension.url-filter-control`.
- [ ] Only the containing app has the App Attest capability and effective environment is verified from archived builds.
- [ ] Bundle IDs, App ID prefix, signing ownership, and environment mapping are recorded.

### URL Filter correctness and privacy

- [ ] Initial non-null Bloom, later unchanged return, corrupt update, resource bounds, freshness, and last-known-good behavior pass.
- [ ] Bloom and PIR are reproducible from one signed canonical manifest and official-tool fixtures.
- [ ] PIR `N` is live before Bloom `N`; compatible prior data survives rollout and rollback.
- [ ] Addition, removal, `resetPIRCache()`, parameter-shape change, `refreshPIRParameters()`, rollback, and kill-switch drills pass.
- [ ] Fail-open is explicitly configured and exercised for every dependency outage.
- [ ] Safari, WebKit, URLSession, voluntary-client, and nonparticipating-client results match documented scope.
- [ ] No app/extension callback, log, metric, trace, report, or MPD path contains passive URLs or block events.
- [ ] Product copy promises no broader coverage or custom block explanation than Apple supplies.

### Distribution service

- [ ] CloudKit Identity & Trust onboarding is approved for the main app bundle ID.
- [ ] Production origins satisfy iOS 26.4 HTTPS/subdomain/port/path rules and gateway negotiates HTTP/2.
- [ ] DNS TXT proof, Apple test record, gateway resource, issuer, service, token, and traffic estimates validate.
- [ ] A physical TestFlight build completes allow and deny through the Apple relay.
- [ ] Service and observability review proves the OHTTP/PIR/Privacy Pass privacy boundary.
- [ ] Accountless bearer-token lifecycle and fallback are accepted and evidenced.
- [ ] Apple sample code is not deployed unmodified; production hardening and license notices are complete.

### App Attest and anti-abuse

- [ ] Development and production stores, configuration, credentials, and test fixtures are separate.
- [ ] Full attestation chain, nonce, key ID, App ID/RP ID, AAGUID, credential ID, counter, and extension validation pass.
- [ ] Assertions bind a fresh 32-byte challenge and exact purpose/method/route/body/version.
- [ ] Challenge consumption and strictly increasing counter update are atomic.
- [ ] Replay, substitution, race, malformed-input, reinstall, unsupported-device, transient-failure, and revocation tests pass.
- [ ] Short-lived downstream capabilities contain no App Attest identity and are single purpose.
- [ ] No App Attest or DeviceCheck material appears in intelligence, MPD, analytics, logs, traces, crash reports, or support tools.
- [ ] Rollout and retry controls keep `attestKey` demand within Apple's current dynamic guidance.

### Product fallback

- [ ] Paste, share, and QR checks work when URL Filter is unavailable, unapproved, disabled, or degraded.
- [ ] Declining MPD or analytics consent does not change URL Filter or manual-check eligibility.
- [ ] A manual-only release decision exists if Apple approval misses the go/no-go date.
- [ ] User-facing status distinguishes not set up, starting, protected, degraded, and paused.

## 11. Claims that are changing, ambiguous, or externally controlled

These items require explicit revalidation; Codex must not silently choose an interpretation:

| Claim | Current working rule | Required action |
|---|---|---|
| OHTTP approval timing/status | Separate distribution approval exists; no published SLA or reliable status contract | Apply in Stage 0, record evidence, and escalate delays to Apple |
| URL Filter capability wording | Same entitlement for development/distribution; separate OHTTP approval | Verify signed profiles and the current Identity & Trust workflow |
| NEURLFilter onboarding bundle ID | Current guide says main application ID; older material has caused confusion with extension ID | Use main app ID, record both IDs, and obtain Apple confirmation if portal copy differs |
| Production origin enforcement | Current onboarding says iOS/macOS 26.4 removes custom paths and requires production-style origins | Test the exact minimum iOS 26.x and TestFlight configuration |
| Accountless PIR bearer token | Proposed App-Attest-authorized bootstrap, not yet an Apple-approved Hezo contract | Complete section 7 spike before Stage 0 exit |
| PIR evaluation-key session lifetime | Apple requires correlatable protocol state but Hezo has not approved inactivity/absolute TTLs | Decide O-018 from physical distribution and service-capacity evidence before Stage 0 exit |
| Prefilter interval default | Current API reference says 86,400 seconds; sample defaults have differed | Set 2,700 seconds explicitly and test effective cadence/cost |
| Consumer setup UX | API exists for unmanaged devices; every prompt/Settings recovery path is not fully documented | Freeze physical-device UX fixtures for supported iOS releases |
| Consumer block reporting | None in iOS 26; iOS 27 beta reporting is supervised-only | Exclude from V1 and re-review after non-beta release |
| URL parsing/regex | iOS 27 beta customization, not iOS 26 | Keep out of V1 code path and blockset contract |
| Development App Attest AAGUID | Apple pages have shown both `appattestdevelop` and `appattestsandbox` wording | Accept only Apple-documented development values in sandbox fixtures, log OS/SDK out of general telemetry, file DTS/Feedback; production accepts only production AAGUID |
| App Attest extension support list | Current API reference says watchOS extensions only; WWDC26 also names Action and SSO extensions | Treat URL Filter as unsupported in all cases; ask Apple before enabling App Attest in any future extension type |
| App Attest extension fields | 2026 guidance adds category/bundle-version fields with incomplete compatibility detail | Parse if present; keep iOS 26 absence valid; verify before making mandatory |
| App Attest key persistence | Installation scoped; local protected-storage survival can differ | Treat stale IDs as recoverable, never as cross-install identity |
| App Attest attestation limits | Current `<100/s` and 10M-users/day guidance is dynamic | Use controlled ramp, backoff, kill switch, and current-doc check |
| Browser coverage | API boundary is stable; individual browser engines/stacks can change | Re-run the physical compatibility matrix for each release |
| iOS 27 material | Current documentation is beta as of this review | No V1 requirement may depend on it |

Production AAGUID validation remains strict: the production value is `appattest` followed by seven zero bytes. Development ambiguity must never broaden production acceptance.

## 12. Primary Apple source index

### URL Filter and Network Extension

- [URL filters overview](https://developer.apple.com/documentation/networkextension/url-filters)
- [Filtering traffic by URL sample](https://developer.apple.com/documentation/networkextension/filtering-traffic-by-url)
- [`NEURLFilterManager`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager)
- [`NEURLFilterControlProvider`](https://developer.apple.com/documentation/networkextension/neurlfiltercontrolprovider)
- [`fetchPrefilter(existingPrefilterTag:)`](https://developer.apple.com/documentation/networkextension/neurlfiltercontrolprovider/fetchprefilter(existingprefiltertag:))
- [Network Extension entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.networkextension)
- [WWDC25 NetworkExtension session](https://developer.apple.com/videos/play/wwdc2025/234/)
- [Apple PIR service example](https://github.com/apple/pir-service-example)
- [Apple OHTTP onboarding guide](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Onboarding.md)
- [Apple PIR authentication](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/Authentication.md)
- [Apple PIR HTTP endpoints](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/HTTPEndpoints.md)
- [Apple PIR privacy explanation](https://github.com/apple/pir-service-example/blob/main/Sources/PIRService/PIRService.docc/PrivacyExplanation.md)
- [Using Apple's Bloom filter tool](https://developer.apple.com/documentation/networkextension/using-the-bloom-filter-tool)
- [Apple DTS: consumer deployment, scope, and custom denial UI](https://developer.apple.com/forums/thread/815498)
- [Apple DTS: entitlement and distribution onboarding](https://developer.apple.com/forums/thread/821619)

### App Attest and DeviceCheck

- [Preparing to use App Attest](https://developer.apple.com/documentation/devicecheck/preparing-to-use-the-app-attest-service)
- [Establishing app integrity](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
- [Attestation Object Validation Guide](https://developer.apple.com/documentation/devicecheck/attestation-object-validation-guide)
- [Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [Assessing fraud risk](https://developer.apple.com/documentation/devicecheck/assessing-fraud-risk)
- [WWDC26: Secure your apps with App Attest](https://developer.apple.com/videos/play/wwdc2026/201/)
- [App Attest environment entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.devicecheck.appattest-environment)
- [`DCAppAttestService.isSupported`](https://developer.apple.com/documentation/devicecheck/dcappattestservice/issupported)
- [Legacy DeviceCheck per-device data](https://developer.apple.com/documentation/devicecheck/accessing-and-modifying-per-device-data)
- [Apple certificate authority](https://www.apple.com/certificateauthority/)

## Maintenance rule

When an Apple SDK, OS, sample revision, portal workflow, or onboarding answer changes any requirement above:

1. save the primary-source URL, observed date, SDK/OS version, and exact changed claim;
2. update this document and the affected tests in the same change;
3. update document 12 if an accepted decision, risk, or open question changes;
4. add an ADR for any architectural, privacy, signing, token, or failure-policy change;
5. rerun development and distribution physical-device gates before release.

An Xcode-successful development install is never sufficient evidence for URL Filter distribution readiness, and a syntactically valid App Attest object is never sufficient evidence without full server verification and replay protection.
