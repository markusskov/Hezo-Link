# Sandbox and security

## Security objective

Hezo Link deliberately accepts attacker-controlled URLs and may load hostile web content. Every submitted URL, DNS answer, redirect, response, page, script, document, download, screenshot, DOM snapshot, model input, and derived artifact is untrusted.

The security objective is not to prove that Chromium or a parser can never be compromised. It is to make a compromise disposable and unable to reach:

- a user identity or browsing history;
- another analysis job;
- Hezo production databases, queues, secrets, or control-plane services;
- cloud metadata, node credentials, orchestration APIs, or internal networks;
- an analyst workstation or a consumer-facing origin;
- the blockset without passing trusted schema, provenance, and policy validation.

The browser sandbox is one layer. It is not the Hezo security boundary.

## Threat model

### In scope

The production design must withstand:

- server-side request forgery through direct URLs, redirects, DNS rebinding, mixed IPv4/IPv6 answers, alternate IP encodings, subresources, WebSockets, and client-side navigation;
- a page exploiting Chromium, its renderer, a media or document parser, the guest kernel, or the microVM boundary;
- resource exhaustion through scripts, workers, WebAssembly, redirect loops, oversized responses, decompression bombs, huge DOMs/canvases, process floods, and persistent connections;
- malicious artifacts exploiting image, HTML, archive, malware-scanner, analyst, or support tooling;
- URL parser disagreements between ingress validation, DNS policy, transport, browser, canonicalization, and blockset generation;
- an attacker using Hezo as a public port scanner, traffic amplifier, credential relay, form submitter, or denial-of-service platform;
- malicious or compromised feed data, crawler output, model output, and source metadata;
- replay, key cloning, counter races, and environment confusion around App Attest;
- a bad or corrupt URL-filter generation causing false blocks or an Internet outage;
- secrets or personal data leaking through raw URLs, response bodies, screenshots, traces, logs, metrics, crash reports, or third-party scanning services;
- an operator mistake, stale policy, vulnerable base image, compromised worker, or overly broad service credential.

### Not claimed

V1 does not claim:

- complete protection from an unknown hypervisor or hardware vulnerability;
- coverage of nonparticipating custom network stacks on iOS;
- safe execution of arbitrary downloaded binaries;
- actor attribution;
- that App Attest proves a device or operating system is uncompromised;
- that a malware scanner can certify an artifact as safe;
- that a `No known danger` result proves a site is safe.

## Trust boundaries

Production uses at least these security zones:

~~~text
public client
    |
    v
API edge and control plane
    | opaque job reference; no crawler credential
    v
lease-based analysis queue
    |
    v
dedicated analysis account/project/VPC
    |
    +--> isolated resolver and validating egress gateway
    |
    +--> one disposable microVM per dynamic analysis
    |         |
    |         +--> job-scoped artifact return channel
    |
    v
quarantine and artifact sanitizer
    |
    v
trusted schema/provenance ingestion service
    |
    v
security-intelligence store
~~~

The analysis zone must have no route, peering, workload identity, or credential capable of reaching production PostgreSQL, administrative APIs, the secrets manager, CI, source repositories, orchestration control planes, the MPD store, the analytics store, or the App Attest anti-abuse store.

No general-purpose service credential may cross these boundaries. The architecture and data-plane separation in [document 04](04-system-architecture.md) and [document 02](02-privacy-and-measurement.md) remain authoritative.

## Analysis job lifecycle

Use explicit, idempotent state transitions:

~~~text
accepted
  -> canonicalized
  -> ssrf_preflight_passed
  -> queued
  -> running
  -> artifacts_quarantined
  -> artifacts_promoted
  -> observations_committed
  -> destroyed
~~~

Every failure is terminal for that run and has a bounded reason code, for example:

- `invalid_url`;
- `unsupported_scheme`;
- `unsupported_port`;
- `blocked_destination`;
- `dns_policy_denied`;
- `redirect_limit`;
- `network_budget_exceeded`;
- `content_budget_exceeded`;
- `browser_timeout`;
- `browser_crash`;
- `artifact_rejected`;
- `policy_error`.

A retry creates a new immutable run linked to the original request. It must not append ambiguous observations to a previous run. Queue messages contain an opaque job ID and policy version, not a plaintext URL. Jobs are leased, bounded, and safe to deliver more than once.

## URL representations

Use the four representations defined in [document 03](03-trust-graph-and-verdicts.md):

1. Raw URL: exactly what the user submitted, encrypted and transient.
2. Network URL: what an isolated worker actually navigates to after policy validation.
3. Canonical threat-check representation: a provider- or enforcement-specific pure function.
4. Long-term sanitized representation: the minimum durable security form.

Query parameters and fragments must not be stripped before security analysis. They can contain redirect targets, client-side payload selectors, and campaign information. They are sanitized after analysis for durable storage.

A hash of a raw URL is not anonymization. Tokens and email addresses may be guessable. If exact transient deduplication is essential, use a short-lived keyed HMAC with a separately controlled key and the same deletion deadline as the raw URL.

## URL parsing and input policy

The validator must:

- accept only syntactically valid `http` and `https` URLs;
- require a host and reject user information such as `user:password@host`;
- reject NUL, CR/LF, control characters, invalid UTF-8, malformed percent escapes, and ambiguous host syntax;
- reject `file`, `data`, `blob`, `javascript`, `gopher`, `ftp`, `dict`, SMB, Unix-socket, and every non-HTTP scheme;
- reject single-label hosts, every IANA Special-Use Domain Name that is not explicitly approved for an isolated fixture, and organization-local suffixes such as `.local`, `.internal`, and `.home.arpa`;
- explicitly deny cloud metadata names, including `metadata.google.internal`;
- normalize IDNs to ASCII/Punycode for network use while retaining the original spelling only as transient evidence;
- reject alternate IPv4 notation, including integer, hexadecimal, octal, shortened dotted, signed, and overflow forms;
- reject IPv6 zone identifiers and normalize IPv4-mapped IPv6 before address classification;
- apply a versioned allowed-port policy.

Proposed V1 port policy is `80` and `443`. A valid HTTP(S) URL on another port should return an explicit unsupported/Unknown outcome, not be reinterpreted. Expanding the set requires an ADR, abuse analysis, and regression corpus because an unrestricted port policy turns Hezo into a public service scanner.

Use one canonical URL and IP parsing implementation across validation and the egress gateway. Pass a parsed structure to the transport layer. Do not validate with one library and later reconnect by reparsing the original string with another library.

## Destination-address policy

Allow only ordinary public-unicast destinations.

The deny policy must include every special-purpose IPv4 and IPv6 allocation in pinned copies of the IANA registries, not only RFC 1918. It therefore covers:

- unspecified, loopback, private, link-local, shared carrier-grade NAT, multicast, broadcast, reserved, documentation, benchmarking, discard, protocol-assignment, transition, and translation space;
- IPv4-mapped IPv6, NAT64, 6to4, Teredo, IPv6 ULA, IPv6 link-local, and IPv6 multicast;
- cloud metadata addresses such as `169.254.169.254`, AWS `[fd00:ec2::254]`, and Google `[fd20:ce::254]`;
- the deployed VPC, subnet, overlay, pod, service, node, cluster-DNS, host-gateway, and corporate ranges;
- public Hezo addresses that expose control-plane, administrative, or otherwise non-public services.

Registry updates are reviewed and versioned. A registry sync cannot silently widen egress.

## DNS rebinding and connection validation

The browser does not own DNS. An isolated resolver and validating egress gateway perform resolution and connection establishment. The resolver uses no host file, multicast discovery, or search suffix. V1 uses validated A/AAAA answers for connection selection and disables DNS SVCB/HTTPS alternative endpoints; supporting them later requires applying the same hostname, port, address-set, and peer checks to every alternative and address hint.

For every top-level navigation, HTTP redirect, client-side navigation, iframe, subresource, fetch/XHR, WebSocket, service-worker request, and new connection:

1. Canonicalize and validate the URL.
2. Resolve the complete CNAME chain through the controlled resolver.
3. Obtain all A and AAAA answers.
4. Reject the request if any answer is prohibited. Do not let the client select one public answer from a mixed public/private set.
5. Cap CNAME depth and detect loops.
6. Connect to a validated socket address without a second hostname resolution in the HTTP library.
7. Preserve the canonical hostname for `Host`, SNI, and TLS certificate verification.
8. Verify that the connected peer is the approved address.
9. Repeat the process for every new connection, even for a previously approved hostname.

Do not cache an “allowed hostname” decision across connections. A cache may retain DNS data according to bounded DNS semantics, but every selected address still passes current policy.

Automatic redirect handling in a generic HTTP client is forbidden unless its redirect hook invokes the complete policy first. Top-level navigation allows at most 10 redirects and terminates loops. Same-host redirects are not exempt.

The guest must not have direct DNS, DNS-over-HTTPS, QUIC, WebRTC UDP, proxy-bypass, or raw-socket egress. The gateway strips or ignores response `Alt-Svc` and protocol-upgrade instructions so the browser cannot establish an unvalidated alternate connection. A network firewall independently denies special and internal destinations even if the gateway or browser is compromised.

## Egress and anti-amplification policy

The microVM may reach only:

- public HTTP(S) through the validating egress gateway;
- one narrow job-control channel, such as a job-scoped vsock endpoint;
- its assigned artifact prefix through that channel.

It must not directly reach DNS, UDP, ICMP, SMTP, SSH, databases, cloud APIs, package repositories, object storage, metadata, or internal services.

The gateway permits only `GET` and `HEAD` in V1, with no outbound request body. The release policy contains an explicit, versioned header allowlist. Its initial set forwarded from the guest is limited to bounded browser-generated values for `Accept`, `Accept-Encoding`, `Accept-Language`, `Cache-Control`, `Pragma`, `Origin`, `Sec-Fetch-Dest`, `Sec-Fetch-Mode`, `Sec-Fetch-Site`, `Sec-Fetch-User`, `Sec-CH-UA`, `Sec-CH-UA-Mobile`, `Sec-CH-UA-Platform`, `Upgrade-Insecure-Requests`, `User-Agent`, and a same-job `Cookie`. Each allowed header has a grammar/value policy and byte cap; enumeration-valued headers and the user agent must match the signed browser policy. The gateway constructs `Host` from the validated canonical hostname and owns all hop-by-hop transport headers; the guest cannot select them. It strips `Referer`, disables cache reuse across jobs, caps cookies by count and bytes, and rejects every unlisted or control-character-bearing header.

This policy blocks script-selected non-idempotent, preflight, or tunneling methods sent toward a destination, including `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`, `CONNECT`, and `TRACE`. It also blocks `Authorization`, `Proxy-Authorization`, `Forwarded`, `X-Forwarded-*`, `Range`, `Upgrade`, WebSocket negotiation headers, unexpected `Content-*`, and arbitrary custom headers. Adding a method or header requires a policy-version change, abuse review, and a gateway regression fixture; it is not accomplished by changing browser flags alone. Cookies created inside the one disposable job may exist only inside that job. They are never imported, exported, or reused.

Because method and header enforcement must also cover HTTPS, the egress gateway is an inspecting proxy, not an opaque TCP forwarder. It terminates the guest-side TLS connection using a private analysis-only CA whose public certificate is trusted only inside the disposable image, independently validates the upstream hostname/certificate, and re-originates the allowed request. The CA private key never enters the guest, ordinary access logging is disabled, and the proxy's transient URL data follows the raw-URL deletion deadline. An internal guest-to-proxy `CONNECT` handshake may be accepted only as this authenticated, job-bound inspection transport; the proxy never forwards it as a destination method or permits an opaque tunnel. If the chosen implementation cannot prove these properties, it does not satisfy the V1 gateway contract.

V1 passive analysis does not:

- click links or buttons;
- enter credentials, payment data, or other form values;
- submit forms or solve CAPTCHAs;
- authenticate to a site;
- upload files;
- honor page requests for camera, microphone, location, Bluetooth, USB, notifications, or clipboard;
- open downloaded files.

Apply rate limits and concurrency budgets per calling capability, destination host, destination address, registrable domain, and globally. A single target must not receive uncontrolled parallel or repeated analysis. The egress gateway enforces byte, request, duration, and connection budgets independently of browser code.

## Isolation requirement

Dynamic analysis of arbitrary public pages must run in a fresh hardware-virtualized microVM or an equivalently strong managed boundary with a separate guest kernel. Firecracker is a suitable reference architecture, not an implementation decision by itself.

Each run gets:

- a microVM from a signed, immutable, minimal, read-only base image;
- no host mounts, container-runtime socket, device passthrough, orchestration token, cloud credential, SSH key, or production certificate;
- a random non-root guest identity;
- ephemeral encrypted scratch storage;
- a browser profile created after boot;
- no state created by another hostile run;
- no reuse after hostile content executes.

A warm snapshot is allowed only if captured before any untrusted work and tied to an image digest. The entire VM and writable storage are destroyed after the run, including on timeout or crash.

The VMM/runner belongs on a dedicated analysis node pool. It runs non-root where supported and uses a jail/chroot, seccomp, cgroups, minimal device model, host hardening, image attestation, and no colocated production workloads.

Plain containers share the host kernel and are not a production release boundary for hostile Chromium. If containers are used for local development or non-executing fixtures, require a sandboxed runtime such as gVisor, user namespaces, read-only root, dropped capabilities, seccomp, AppArmor/SELinux, `no-new-privileges`, no host network/PID/IPC, and no service-account token. This does not waive the production microVM requirement.

## Browser hardening

Use a supported, pinned Chromium build. Keep Chromium's own sandbox and Site Isolation enabled. `--no-sandbox`, global certificate-error bypasses, and debug trust overrides are forbidden.

The browser profile has:

- no saved cookies, credentials, client certificates, autofill, password manager, history, extension, synchronization, or consumer data;
- camera, microphone, geolocation, Bluetooth, USB, clipboard, notifications, printing, and downloads denied;
- WebRTC and QUIC disabled;
- no direct DNS or proxy bypass;
- no installed extension or plugin;
- PDF/document execution disabled;
- cache, cookies, IndexedDB, local storage, and service-worker state destroyed with the VM.

Upstream certificate failures observed by the inspecting gateway are recorded as typed observations and stop that connection. The crawler must not turn a certificate error into an accepted page merely to improve coverage. The analysis-only CA is never installed on a host, developer workstation, consumer device, or non-analysis service.

Page-triggered downloads are intercepted and not opened. A future dedicated download collector must use a separate disposable microVM, stream through strict byte/type limits, and write directly to quarantine. It requires an ADR and is not implied by the browser crawler.

Disabling the GPU is the proposed V1 default. Disabling JIT may reduce exploitability but materially changes page behavior; it may be evaluated as a second profile, not silently enabled in the primary behavioral profile without benchmark evidence.

## Proposed per-job resource budgets

These are security ceilings, not product latency promises. An ADR or benchmark result may tighten them.

| Resource | Proposed V1 ceiling |
|---|---:|
| vCPU | 2 |
| Memory | 2 GiB |
| Wall time | 30 seconds |
| Primary navigation wait | 15 seconds |
| Processes/PIDs | 128 |
| File descriptors | 1,024 |
| Network requests | 500 |
| Top-level redirects | 10 |
| Wire bytes | 30 MiB |
| Decoded bytes | 64 MiB |
| Single response | 8 MiB |
| Outbound request body | 0 bytes |
| Outbound request headers | 16 KiB total; at most 50 cookies and 8 KiB cookie data |
| DOM export | 5 MiB |
| Writable profile and scratch | 256 MiB |
| Screenshot dimensions | 4096 x 4096 |
| Archive/decompression expansion | 20:1 |

Crossing a hard ceiling terminates the entire microVM. Timeout, truncation, and resource exhaustion are typed analysis outcomes. They do not justify relaxing isolation or returning `No known danger`.

## Artifact quarantine

Browser output is hostile data. It enters quarantine before a trusted service can consume it.

V1-promotable artifacts are limited to:

- a re-encoded PNG screenshot;
- schema-validated, bounded JSON observations;
- bounded plain-text extraction;
- cryptographic or perceptual hashes;
- sanitized redirect/header metadata;
- a structural DOM fingerprint rather than executable HTML.

Required controls:

- Generate storage names internally; never use a URL or response filename.
- Enforce size and object-count limits before and after decoding.
- MIME-sniff and validate signatures; do not trust `Content-Type` or an extension.
- Re-encode images in a separate low-privilege sanitizer boundary.
- Never render captured HTML on a Hezo application origin. If retained for an approved analyst hold, deliver it escaped as text from an isolated, non-cookie origin.
- Use restrictive content types and `Content-Disposition: attachment` for any analyst retrieval.
- Never copy hostile artifacts onto a normal developer or analyst workstation.
- Do not submit samples to a third-party scanner without explicit privacy, licensing, and data-residency approval.

Artifact states are explicit:

~~~text
untrusted
  -> scanning
  -> quarantined
  -> safe_to_process | rejected
  -> expired
  -> deleted
~~~

`safe_to_process` means safe for the named downstream parser under the current policy. It does not mean globally clean or non-malicious. Antivirus or YARA non-detection never establishes safety.

## Trusted ingestion boundary

The crawler never writes graph rows, verdicts, or block entries.

The trusted ingestion service:

- validates a closed schema and bounds every string, collection, and numeric value;
- treats page text and model output as attacker-controlled;
- attaches collector, image, policy, and run versions;
- verifies artifact digests and job ownership;
- strips transient data before durable writes;
- rejects unknown observation types rather than storing arbitrary JSON;
- creates observations, never an unreviewed verdict or block;
- has no credential to the MPD, analytics, or anti-abuse stores.

Any HTML displayed to an analyst is escaped. Spreadsheet exports protect against formula injection. Log and metric values use bounded enums instead of attacker-controlled labels.

## Secrets and service identities

The guest contains no secret. The analysis runner receives only short-lived, job-scoped authority to:

- lease one job;
- write to one artifact prefix;
- return one signed result envelope.

It cannot query PostgreSQL directly. Egress authentication should use workload/network identity outside the guest rather than a reusable proxy secret embedded in the image.

Base images, build manifests, and prefilter artifacts are signed. Production verifies signatures and expected digests before use. CI produces an SBOM and provenance for the browser, guest, VMM/runner, sanitizer, and security-critical libraries.

## Privacy and retention at the sandbox boundary

Raw URLs and artifacts may contain reset tokens, email addresses, session values, credentials, or other personal data.

The raw URL is transient under accepted decision D-012. Exact raw-URL timing remains owner decision O-007, and O-016 decides whether an exceptional artifact hold may use the full seven-day ceiling or must be shorter, in [document 12](12-risks-decisions-and-open-questions.md). Until accepted decisions tighten the policy, use the conservative P-008 implementation default:

- The encrypted raw URL is deleted immediately after the terminal job/verdict and has a hard queue/storage/backup TTL of 24 hours.
- DOM, HAR/network traces, response material, screenshots, and downloads are encrypted and quarantined with a default hard TTL of 24 hours.
- An explicit report or analyst hold may extend selected artifacts to at most seven days. It requires a reason, owner, access audit, and expiry.
- Durable Trust Graph data contains only the sanitized security representation and allowed derived evidence, with no submitter, raw IP, MPD token, analytics ID, or App Attest key ID.

Retaining confirmed-malicious screenshots or DOM evidence beyond seven days is not authorized, and O-016 does not create that option. It would require a new accepted decision, documented necessity, privacy/legal approval, role and access controls, and updates to documents 02, 05, 08, 10, and 12 before implementation.

Ordinary logs, traces, metrics, crash reports, and support tools must never contain:

- a full URL, query value, fragment, cookie, authorization header, or request/response body;
- page text, screenshot pixels, or form values;
- an App Attest attestation, assertion, challenge, public key, or key ID;
- an MPD token or analytics identifier;
- an unbounded attacker-controlled hostname, error string, or artifact name.

Deletion jobs and backup expiry are tested. Under the current policy, a legal or security-incident record does not override the raw-URL 24-hour ceiling or the selected-artifact seven-day ceiling. Any future exception requires the explicit O-007/new-decision process and synchronized privacy, schema, sandbox, test, and backup changes; a generic “hold” flag is never a hidden retention escape.

## Security logging and alerting

Log only bounded operational facts:

- job and run IDs;
- policy, image, collector, and schema versions;
- state transitions and typed failure reason;
- address-policy rule and destination classification, without raw URL path/query;
- resource ceiling triggered;
- artifact digest, size class, and state;
- worker identity and administrative action.

Sanitize CR/LF and delimiters before structured logging. Security/audit logs are access-controlled, tamper-evident, and independent from application analytics. All access and configuration changes are audited.

Proposed raw-free retention is 30 days for worker/control-plane operational logs and 365 days for security, configuration, artifact-access, and administrative audit events. A hosting ADR may tighten these periods, but it may not add raw URLs, client IPs, page content, App Attest material, or cross-plane identifiers to make an investigation easier. Destination-security records may retain the analyzed public address and bounded classification when that fact is a licensed Trust Graph observation, not as an unstructured log field.

Alert on:

- any internal, metadata, or denied-address attempt;
- direct DNS, proxy bypass, a new protocol, or unexpected port;
- host-integrity or VMM anomaly;
- unexpected syscall, device access, or write outside scratch;
- sudden browser crash, timeout, or resource-exhaustion spikes;
- artifact sanitizer or schema-validation failures;
- anomalous target concentration or egress volume;
- runner credential use outside the assigned job;
- analysis from an unapproved image or stale vulnerable browser.

## Proposed patch and vulnerability policy

Production images are rebuilt rather than patched in place. The numerical SLA below is the proposed security default; O-006 requires an ADR to assign the production technology and accountable owner.

Release admission and deployed-image patch timing are distinct. A High finding is never implicitly acceptable for seven days in a new release candidate. Release policy:

- no known Critical vulnerability in a release candidate or deployed analysis image;
- every unresolved High is a release blocker unless a named approver accepts a time-bounded exception with verified compensating controls, exploitability analysis, and a fix/retirement date;
- an unmitigated High cannot receive an exception;
- a deployed image affected by a newly disclosed High with an available fix is rebuilt within seven days at most, sooner when exploitability or exposure warrants, or disabled until it can comply;
- Critical browser/guest fixes are evaluated and deployed within 48 hours of availability;
- a normal supported-browser update is evaluated at least weekly;
- vulnerability exceptions record exploitability, compensating controls, owner, approval, expiry, and verification evidence;
- rollback returns to a still-supported signed image, never an untracked mutable host.

An emergency image kill switch stops new dynamic jobs while manual exact-intelligence checks continue.

## App Attest security boundary

Detailed Apple integration lives in [document 07](07-apple-platform.md). Security invariants are:

- App Attest runs in the containing app, not the URL Filter control extension.
- The server issues a random, single-use challenge. Apple requires at least 16 bytes; Hezo uses 32 bytes and a proposed five-minute TTL.
- Attestation verification includes Apple certificate chain, nonce extension, App ID/RP ID, key/credential ID, environment AAGUID, and initial counter.
- Assertions bind the exact canonical method, path, body digest, challenge, and contract version.
- Assertion counters are checked and advanced atomically; replay, rollback, concurrent duplicate, and out-of-order use fail.
- Development and production credentials, verifier policies/fixtures, and data stores are separate. Use the Apple trust anchors documented for each artifact; environment separation comes from server-owned configuration and verified fields such as the AAGUID, not from inventing different App Attest roots. TestFlight uses production App Attest.
- Unsupported devices and transient Apple failure degrade gracefully. Core read-only manual checks remain usable under stricter rate limits.
- Unattested or invalid reports may trigger abuse review but cannot contribute to automatic blocking.
- App Attest key IDs stay in the anti-abuse plane and never become an analytics, MPD, or Trust Graph identifier.

Current Apple documentation has shown inconsistent development AAGUID wording across versions. Pin verification fixtures to the deployed Xcode/iOS SDK and test both documented development encodings where necessary; production verification remains strict and does not accept a development AAGUID.

## URL Filter security boundary

Detailed platform configuration lives in [document 07](07-apple-platform.md). Security invariants are:

- Consumer V1 is fail open and has a remote, signed kill switch.
- The app and extension do not receive passive URL traffic.
- No custom passive URL or block-event telemetry is built around Apple's Bloom/PIR path.
- The Bloom prefilter and PIR data are reproducible from the same canonical blockset generation.
- Publish PIR generation `N` before the Bloom artifact for `N`, and retain compatible prior PIR data during rollout.
- Corrupt, unsigned, or incompatible artifacts are rejected while the last-known-good generation remains active.
- A Bloom match is a private lookup candidate, not proof of a block. PIR resolves false positives.
- iOS 26 automatically covers WebKit and `URLSession`; other clients must voluntarily call `NEURLFilter.verdict(for:)` and honor the result.
- Development-signed direct-Xcode behavior is not distribution proof. CloudKit Identity & Trust/OHTTP onboarding and a distribution build must pass before passive protection ships.

If the PIR path is unavailable or indeterminate, ordinary browsing is allowed and the app reports degraded protection status without claiming full coverage.

## Quarantine and incident controls

Required independent kill switches can stop:

- all dynamic crawling;
- one browser or guest image;
- one worker node, pool, region, destination, or ASN;
- artifact promotion;
- Trust Graph ingestion from one collector version;
- blockset publication;
- one URL Filter generation.

On a suspected escape or trust-boundary violation:

1. Stop new scheduling on the affected pool.
2. Cut the pool's egress.
3. Revoke runner and artifact credentials.
4. Quarantine artifacts and observations from the affected image/node/time window.
5. Preserve only privacy-approved forensic evidence.
6. Audit control-plane and production access for the same window.
7. Rebuild nodes and images from signed, known-good sources.
8. Require explicit security approval before restoring dynamic analysis.

Use synthetic, non-sensitive tripwire files and endpoints behind boundaries. A tripwire proves attempted access without putting a real production secret in reach.

## Security acceptance criteria

The sandbox boundary is ready for a production pilot only when:

- the SSRF and DNS-rebinding suite in [document 10](10-testing-and-benchmarks.md) makes zero connection to a prohibited canary;
- direct and redirected IPv4, IPv6, alternate encoding, mixed-answer, and metadata cases all terminate with a typed denial;
- a guest cannot bypass the egress gateway or contact another job, metadata service, orchestrator, production service, internal network, or host surface other than the single approved, schema-bound job-control/artifact channel;
- resource-exhaustion fixtures terminate within policy without affecting a neighboring job;
- no browser profile, writable disk, cookie, cache, service worker, or artifact is reused across hostile runs;
- raw URL and artifact deletion passes the active approved policy, initially the 24-hour P-008 hard-TTL default, including queues and backups;
- crawler output cannot write directly to the graph or blockset;
- signed-image, SBOM, provenance, patch, and rollback gates pass;
- kill switches and the suspected-escape runbook have been exercised;
- no unresolved Critical vulnerability and no unmitigated High vulnerability remains; any permitted High exception is named, approved, within its expiry, and has verified compensating controls.

This gate covers the dynamic-analysis boundary. URL Filter distribution, fail-open, and last-known-good gates apply separately when passive protection is enabled, as specified in [document 10](10-testing-and-benchmarks.md).

## References

- [OWASP Server-Side Request Forgery Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP Web Security Testing Guide: Testing for SSRF](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/07-Input_Validation_Testing/19-Testing_for_Server-Side_Request_Forgery)
- [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)
- [IANA IPv6 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml)
- [IANA Special-Use Domain Names Registry](https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml)
- [RFC 9460: Service Binding and HTTPS DNS Resource Records](https://www.rfc-editor.org/rfc/rfc9460.html)
- [RFC 7838: HTTP Alternative Services](https://www.rfc-editor.org/rfc/rfc7838.html)
- [AWS EC2 instance metadata endpoints](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [Google Compute Engine metadata endpoints](https://docs.cloud.google.com/compute/docs/metadata/querying-metadata)
- [Azure Instance Metadata Service](https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service)
- [Chromium Site Isolation](https://www.chromium.org/Home/chromium-security/site-isolation/)
- [Firecracker: Lightweight Virtualization for Serverless Applications](https://www.usenix.org/conference/nsdi20/presentation/agache)
- [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [Apple URL filters](https://developer.apple.com/documentation/networkextension/url-filters)
- [Apple `NEURLFilterManager`](https://developer.apple.com/documentation/networkextension/neurlfiltermanager)
- [Apple: Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [Apple App Attest validation guide](https://developer.apple.com/documentation/devicecheck/attestation-object-validation-guide)
