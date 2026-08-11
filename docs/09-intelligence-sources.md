# Seed intelligence, licensing, and source operations

## Purpose and review date

Hezo Link needs external intelligence to bootstrap coverage, but an accessible feed is not necessarily a feed Hezo may use in a commercial consumer product.

This document records the source decision as reviewed on **2026-08-11**. Terms, prices, interfaces, and provider policies can change. A source must pass the production enablement gate below again before first use and after any material terms change.

This is an implementation policy, not legal advice. Unclear rights are a release blocker that the owner must resolve with counsel or the provider; they are not permission for Codex to guess.

## Governing principles

- External observations must retain source, source-record identifier, collection time, freshness, and the exact terms snapshot under which they were obtained.
- Access does not imply commercial-use, storage, derived-output, user-display, model-training, or redistribution rights. Record each right separately.
- Raw third-party feeds are never part of Hezo's public API, analyst export, client blockset, benchmark artifact, or repository unless the applicable agreement expressly permits that output.
- A third-party match may support a Hezo verdict only when the licensed output scope includes consumer protection and consumer-facing explanations.
- Future B2B reputation, monitoring, campaign, API, SDK, and feed products require their own source-rights review. A license for an end-user warning does not automatically permit a commercial intelligence API.
- Provider attribution, advisory text, expiry, deletion, refresh, and geography restrictions propagate into every derived output that depends on the source.
- Source data must not enter MPD, product analytics, or anti-abuse stores. Source credentials and raw responses remain in the security-intelligence plane.
- Source failure, stale support, or revoked rights are not clean results. The verdict engine must exclude the source, recompute affected products, and express incompleteness where policy requires it.
- No source may be used to train, fine-tune, or validate a model unless model use is affirmatively allowed. An omitted right defaults to forbidden.
- Popularity, domain age, registration provider, certificate issuer, hosting provider, ASN, country, TLD, or inclusion in a government-domain registry never establishes that a URL is harmless.

## Source classes

V1 distinguishes four source classes:

1. **Qualified threat intelligence** can contribute a current, exact malicious match after source, product, category, match scope, freshness, quality, and license are approved.
2. **Infrastructure enrichment** supplies facts such as registration dates, certificates, nameservers, IPs, and official-domain relationships. These facts do not independently establish maliciousness.
3. **Public scam context** supplies US scam categories, current narratives, channel trends, and occasionally dated public indicators. Aggregate statistics do not become URL-level evidence.
4. **Benchmark-only data** measures false positives, latency, or coverage and is isolated from production verdicts and blocksets.

An integration must declare exactly one primary class. It may declare additional scopes only after review.

## Decision matrix

| Source | V1 state | Approved V1 role | Commercial and output position | Refresh and cost |
|---|---|---|---|---|
| Google Safe Browsing API | Blocked | None | Google expressly limits the API to non-commercial use | Free, quota limited; irrelevant because use is blocked |
| Google Web Risk Lookup API | Conditionally approved | Current exact malware and social-engineering lookup | Commercial service; consumer warnings require freshness, attribution, and advisory text; no raw-list redistribution right is assumed | Per URL; positive result expires at `expireTime`; first 100,000 calls/month free, then published usage pricing |
| Google Web Risk Update API | Deferred | Possible future local hash-prefix lookup | Terms obligations still apply; current confirmation pricing creates a material cost risk | Follow `recommendedNextDiff`; diff calls free, confirmation calls currently expensive |
| PhishTank | Blocked pending written clarification | Potential verified phishing input | Current page points to Cisco terms while only archived terms clearly describe free commercial data use; rights are too ambiguous for production | Download files update hourly; legacy access is free |
| OpenPhish Community | Blocked | None | Personal/non-commercial; disclosure, distribution, and derivative works are restricted without written consent | Every 12 hours; free |
| OpenPhish Premium or Platinum | Contract required | Potential licensed phishing input | Contract must expressly permit storage, derived verdicts, explanations, and intended future outputs | Every 5 minutes; price by quote |
| URLhaus Community | Blocked for commercial V1 | None | Community terms are principally not-for-profit; website/platform terms also restrict scraping, derivative use, and AI training | Dumps every 5 minutes; authenticated community access is free |
| Spamhaus commercial abuse.ch API | Contract required; optional | Malware-delivery URLs only | Commercial contract must cover local use and derived consumer outputs; not a general phishing feed | Commercial-grade API; 30-day trial; price by quote |
| IANA RDAP bootstrap registries | Approved | Find authoritative RDAP services | Protocol-registry data is CC0 | Refresh conditionally at least daily; free, no SLA |
| Authoritative RDAP responses | Conditionally approved | Bounded domain-registration enrichment | Each registry or registrar has its own terms; no bulk compilation or raw redistribution is assumed | Query on cache miss; honor headers, notices, 429, and `Retry-After`; generally free but rate limited |
| Certificate Transparency logs | Conditionally approved | Certificate and lookalike-domain discovery | Public monitoring is an intended protocol use; verify operator or aggregator terms; Chrome log lists must not power non-Chrome CT enforcement | Log list daily; entries continuous; direct access has no license fee but material infrastructure cost |
| Tranco default list | Blocked from production; legal review for tests | Possible reproducible false-positive benchmark only | Composite includes non-commercial Cloudflare data and has no clear blanket commercial license | Daily by 00:00 UTC; free download |
| CISA `.gov` data | Approved | Official US government-domain relationships | Repository is CC0; omit published security-contact email from ingestion | Daily; free |
| FTC public aggregate data and alerts | Approved for context | US scam taxonomy, narratives, and aggregate trend priors | Most FTC-authored material is US government work; attribute where feasible; raw Consumer Sentinel reports are restricted | Public Explorer quarterly; Data Books annual; alerts ongoing; free |
| FBI IC3 public reports and PSAs | Approved for context and dated observations | US scam taxonomy, tactics, trends, and specifically published indicators | Use public products only; preserve source, alert date, and disclaimers; no raw complaint feed | Annual report plus ad hoc PSAs; free |
| CISA TLP:CLEAR advisories | Conditionally approved | Dated public IOCs and campaign techniques | Sharing is unrestricted under TLP:CLEAR, subject to standard copyright and third-party rights | Ad hoc; free |

`Conditionally approved` means the source still needs connector-specific privacy, security, quality, and output-scope sign-off. It does not authorize enabling a production credential by itself.

## Recommended V1 seed stack

The defensible initial combination is:

- Google Web Risk Lookup for a current qualified exact external signal;
- CISA `.gov` data for verified US government-domain relationships;
- bounded authoritative RDAP enrichment;
- direct or properly licensed Certificate Transparency monitoring for discovery;
- public FTC, IC3, and CISA material for US scam taxonomy and dated public observations;
- Hezo analyst-confirmed observations and deliberately submitted reports under the Trust Graph policy.

PhishTank, OpenPhish, URLhaus, and any Tranco fixture must remain disabled until their specific gate is satisfied. Connector interfaces may be defined behind feature flags, but credentials, scheduled ingestion, feed samples, and production dependencies must not be added speculatively.

## Google Safe Browsing and Web Risk

### Safe Browsing API: prohibited for Hezo Link

Google states that the Safe Browsing API is for non-commercial use only, meaning not for sale or revenue-generating purposes. A free V1 app is not a sufficient basis for treating a planned commercial product as non-commercial.

Codex must not add a Safe Browsing API key, SDK, fixture copied from its lists, or production call path.

Primary sources:

- [Google Safe Browsing overview](https://developers.google.com/safe-browsing)
- [Safe Browsing appropriate usage](https://developers.google.com/safe-browsing/reference/Appropriate.Usage)

### Web Risk Lookup API: proposed qualified baseline

Web Risk is Google's commercial malicious-URL service. The Lookup API accepts one URL per request and can check multiple threat types in that request. A matching response contains the threat types and an `expireTime`; an empty response means only that the URL was not present in the requested lists at that evaluation time.

Allowed V1 use, subject to the Google Cloud agreement:

- backend lookup of a deliberately submitted URL or approved enrichment target;
- an expiring source observation recording the exact requested threat types and returned match types;
- a consumer warning whose support includes the current match;
- provider-specific canonicalization implemented as a versioned pure function.

Required controls:

- Do not describe an empty response as proof that a site is safe.
- Expire a positive match at the returned `expireTime`.
- Google's Web Risk terms permit displaying a warning based on its unsafe-site list only when the result is current: before the supplied expiration, or within 30 minutes when the response supplies no expiration.
- The warning must include Google attribution and a conspicuous notice, using language similar to Google's advisory, that the protection may not be comprehensive or error free and can miss risky sites or identify safe sites in error.
- Store the attribution and advisory template in source policy, not hard-coded in general verdict copy.
- Do not expose raw Google responses, list material, or downloaded hash prefixes in Hezo exports.
- Record requests, quota, latency, and billing with bounded labels that contain no URL or domain.
- Document the external Google transfer in the privacy data-flow inventory. URLs can contain personal data or secrets even when no Hezo identifier accompanies them.

Avoid the Brand Phishing Protection, Evaluate, and Submission APIs in V1. The current service-specific terms state that submitted URLs, content, and metadata for those products are not Customer Confidential Information or Customer Data and may be used and shared by Google. A future use requires a separate privacy and product decision.

Published Lookup pricing at the review date:

| Monthly `uris.search` calls | Price |
|---:|---:|
| 1 through 100,000 | No charge |
| 100,001 through 10,000,000 | USD 0.50 per 1,000 calls above the free tier |
| More than 10,000,000 | Contact Google Cloud sales |

The provider's worked example prices 500,000 monthly Lookup calls at USD 200 after the free tier. Billing alerts, a monthly hard budget, per-client abuse limits, and a circuit breaker are required before production.

Primary sources:

- [Web Risk Lookup API](https://cloud.google.com/web-risk/docs/lookup-api)
- [Web Risk pricing](https://cloud.google.com/web-risk/pricing)
- [Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms), section titled **Web Risk**

### Web Risk Update API: deferred

The Update API downloads hash prefixes for a local or in-memory database and confirms local prefix matches against Google. Clients must follow `recommendedNextDiff`, validate checksums, and preserve the version token.

It is not the V1 default because current published pricing lists `hashes.search` confirmations at USD 50 per 1,000 calls. The pricing page also warns that calling `threatLists.computeDiff` changes associated `uris.search` calls to `hashes.search` pricing. This creates a severe accidental-cost risk.

Before any experiment:

- obtain an explicit billing interpretation from Google;
- isolate the experiment in a dedicated Cloud project and credentials;
- cap confirmation volume and spend;
- prove purge, checksum reset, list-version rollback, and source expiry;
- confirm that downloaded prefixes cannot enter client blocksets or external exports under the agreement.

Primary sources:

- [Web Risk Update API](https://cloud.google.com/web-risk/docs/update-api)
- [Web Risk pricing](https://cloud.google.com/web-risk/pricing)

## PhishTank

PhishTank's technical documentation provides downloadable verified-and-online phishing data in multiple formats, updated hourly. It requires a descriptive User-Agent; an application key increases limits, and keyed clients can use unlimited HEAD requests to inspect `ETag` without repeatedly downloading the file.

The rights position is not clear enough for V1 production:

- the current PhishTank terms page directs users to Cisco's General Terms;
- the archived OpenDNS text on that page says API-defined `Data` is available for commercial use without charge;
- the same archived page contains a CC BY-SA 2.5 statement, but its scope over current feed data is unclear;
- Cisco's current General Terms restrict transferring, selling, sublicensing, monetizing, providing service functionality to a third party, and making derivative works except as authorized.

Do not rely on an archived grant where the current provider points to different terms.

Written Cisco/Talos confirmation must cover:

- commercial consumer protection;
- local storage, normalization, and campaign correlation;
- derived risk signals, verdicts, explanations, and exact-scope blocks;
- whether any ShareAlike obligation attaches to feed data or derived products;
- required attribution and false-positive notice;
- raw-feed and external-API restrictions;
- use by Hezo's hosting providers and contractors;
- retention, backups, deletion, and rights after termination;
- a TLS-protected download path and integrity mechanism.

Until then, `production_use_allowed`, `consumer_display_allowed`, and `derived_output_allowed` are false. Do not commit a feed sample as a test fixture.

Primary sources:

- [PhishTank terms](https://phishtank.net/terms.php)
- [Cisco General Terms](https://www.cisco.com/c/en/us/about/legal/cloud-and-software/end_user_license_agreement.html)
- [PhishTank developer information](https://www.phishtank.com/developer_info.php)
- [PhishTank API information](https://phishtank.net/api_info.php)

## OpenPhish

OpenPhish's general terms provide the service solely for personal use and prohibit commercial use without prior written consent. Unless OpenPhish permits it in writing, the terms also prohibit licensing, selling, renting, transferring, assigning, distributing, displaying, disclosing, creating derivative works from, or otherwise making the information available to a third party.

The Community feed is therefore blocked for Hezo Link, including production, model evaluation, benchmark fixtures, and development seed data.

The product comparison presents Premium and Platinum as supporting commercial use and updating every five minutes, compared with the Community feed's limited URLs and 12-hour update. Pricing and the operative commercial agreement require direct contact.

A paid agreement must affirmatively permit:

- Hezo's production consumer-protection use;
- transient and durable storage boundaries;
- normalization, entity extraction, clustering, and derived verdicts;
- the exact evidence that may appear to a consumer;
- blockset compilation at the source-approved URL or domain scope;
- false-positive review and sharing with the provider;
- cloud processors and disaster-recovery backups;
- retention and purge after expiry or termination;
- every planned B2B output separately;
- model training or validation, if ever proposed.

Subscription access alone is not evidence that raw redistribution or future Hezo intelligence products are allowed.

Primary sources:

- [OpenPhish Terms of Use](https://openphish.com/terms.html)
- [OpenPhish feed comparison](https://openphish.com/phishing_feeds.html)
- [OpenPhish Academic Use Program](https://openphish.com/academic_use.html)

## URLhaus and the commercial abuse.ch API

URLhaus collects URLs that directly distribute malware. Its submission policy explicitly excludes ordinary phishing sites, phishing kits, redirectors, and URL shorteners that do not themselves host the final malware payload. It can supplement malware coverage; it cannot replace a phishing source.

The abuse.ch platform terms effective 2025-11-04 provide authenticated community access for not-for-profit purposes under query-volume limits. Commercial or for-profit users may require a paid subscription managed by Spamhaus. The accompanying site terms prohibit high-volume scraping and prohibit using the site, published data, or related services to develop, train, fine-tune, or validate an AI system or model.

For commercial V1:

- do not use the Community API or scrape the URLhaus website;
- consider the Spamhaus commercial abuse.ch API only if malware-delivery coverage justifies it;
- use a provider-issued commercial credential and documented API or export;
- preserve `URLhaus` or `abuse.ch` as source provenance rather than relabeling its observations as Hezo-owned;
- treat the match as `malware_delivery`, not generic `phishing`;
- never use the data for model work unless a signed agreement expressly supersedes the published restriction.

Spamhaus advertises a 30-day commercial trial and quote-based pricing. The agreement must answer storage, derived-output, end-user display, attribution, retention, backup, support, false-positive, and termination questions before the connector is enabled.

URLhaus dumps are generated every five minutes and must not be fetched more often than every five minutes. Use the required Auth-Key, conditional requests where supported, and provider backoff.

Primary sources:

- [URLhaus Community API and submission policy](https://urlhaus.abuse.ch/api/)
- [URLhaus purpose and feeds](https://urlhaus.abuse.ch/about/)
- [abuse.ch platform Terms of Use](https://abuse.ch/terms-of-use/)
- [abuse.ch website Terms and Conditions](https://abuse.ch/terms-and-conditions/)
- [Spamhaus commercial abuse.ch API](https://www.spamhaus.com/data-access/abusech-api/)

## RDAP

### IANA bootstrap data

IANA's RDAP bootstrap registries map namespaces to authoritative RDAP services. IANA and the IETF dedicate their applicable protocol-registry rights to the public domain under CC0 1.0. Bootstrap data is approved for production service discovery.

Refresh the bootstrap JSON at least daily with conditional HTTP requests. Retain the version hash and fetch time. A refresh failure uses the last-known-good registry and raises a freshness alert; it does not erase the prior mapping.

Primary sources:

- [IANA RDAP domain bootstrap registry](https://www.iana.org/assignments/rdap-dns/rdap-dns.xhtml)
- [IANA protocol-registry licensing terms](https://www.iana.org/help/licensing-terms)
- [ICANN RDAP overview](https://www.icann.org/rdap/)

### Authoritative registry and registrar responses

IANA's CC0 dedication does not license the registration data returned by every registry or registrar. RDAP responses may include a `rel="terms-of-service"` link and provider notices. Provider terms commonly prohibit high-volume automated querying, bulk compilation, repackaging, or dissemination. Responses may still contain public contact or organization data after privacy redaction.

Approved bounded enrichment fields are:

- domain registration, expiration, last-change, and RDAP-database-update times;
- registrar identifier and display name;
- domain status values;
- nameserver hostnames;
- DNSSEC state;
- authoritative RDAP base URL, response terms URL, and fetch time.

Do not retain registrant or administrative names, addresses, telephone numbers, personal email addresses, free-text remarks, or unreviewed entities. The parser must use a field allowlist rather than a list of fields to redact.

Connector requirements:

- resolve the authoritative service through the current bootstrap registry;
- capture the terms link and notices before accepting the response;
- maintain a per-RDAP-service terms decision and rate policy;
- honor `Cache-Control`, `Expires`, `ETag`, `Last-Modified`, HTTP 429, and `Retry-After`;
- use bounded concurrency and per-provider circuit breakers;
- keep raw responses encrypted and transient, then retain only approved derived observations;
- never bulk harvest or redistribute an RDAP database;
- treat absent or redacted data as unavailable, not suspicious;
- treat domain age, registrar, status, and nameservers as contextual infrastructure evidence only.

Google Registry's published RDAP terms illustrate the provider-specific risk: they prohibit high-volume automated access and compiling, repackaging, disseminating, or otherwise using the database in its entirety or a substantial portion without permission.

At production scale, a contract-backed commercial registration-data provider may be safer than coordinating many authoritative terms. That dependency still needs the same data-minimization and output-rights review.

Primary source example:

- [Google Registry RDAP terms](https://www.registry.google/policies/rdap-terms/)

## Certificate Transparency

Certificate Transparency creates publicly auditable, append-only logs of publicly trusted TLS certificates. RFC 9162 expects monitors to inspect every new entry in the logs they watch and says a monitor may keep copies of entire logs. Logged certificates can reveal domains, subdomains, and organization information.

This makes CT suitable for internal discovery of:

- certificates newly issued for brand-like domains;
- SAN values that expand a candidate-domain set;
- certificate fingerprints shared by related URLs or domains;
- issuer, validity, and log-time relationships;
- possible lookalike infrastructure that should be enriched or reviewed.

CT is not a maliciousness feed. New issuance, a particular CA, a free certificate, shared certificate infrastructure, or presence in a log has zero malicious score alone.

Chrome publishes signed CT log lists daily. Its usage policy allows certificate submitters, monitors, and auditors to use the lists for compatibility with or investigation of CT and WebPKI. It expressly prohibits using Chrome's list to facilitate CT enforcement in a TLS client other than Chrome without written permission. Hezo must not implement independent client certificate enforcement from this list.

Operational requirements:

- consume the signed log list daily and verify its signature;
- use it only to discover and monitor logs, not to make iOS trust decisions;
- follow each log's Maximum Merge Delay and capacity limits;
- store log ID/operator, certificate fingerprint, approved SAN/domain values, issuer, validity, and observation times;
- avoid durable storage or display of unnecessary subject identity fields;
- verify the terms of each log operator or use a commercial CT stream whose agreement permits Hezo's use;
- do not assume a third-party aggregator such as crt.sh grants commercial reuse merely because its search is publicly reachable;
- plan for no Chrome log-list SLA and substantial ingestion, verification, storage, and deduplication cost.

Primary sources:

- [RFC 9162: Certificate Transparency Version 2.0](https://www.rfc-editor.org/rfc/rfc9162.html)
- [Chrome CT log lists and acceptable-use policy](https://googlechrome.github.io/CertificateTransparency/log_lists.html)
- [Certificate Transparency overview](https://certificate.transparency.dev/howctworks/)
- [Chrome guidance on the public contents of certificates](https://googlechrome.github.io/CertificateTransparency/site_operators.html)

## Tranco and benign testing data

Tranco publishes a research-oriented ranking of one million domains, averaged across constituent rankings over 30 days. The standard list is updated daily by 00:00 UTC and provides a permanent list ID for reproducibility.

It is not approved for production:

- Tranco discloses that the default list includes Cloudflare Radar data under CC BY-NC 4.0;
- it also combines other sources with differing attribution, ShareAlike, free-access, or unclear rights;
- Tranco does not publish a clear blanket commercial license for the resulting standard list;
- a popularity ranking is not a safety list and can include compromised or malicious destinations.

Do not use Tranco to suppress a verdict, create a `trusted` graph edge, exempt a domain from sandboxing, or compile a client allowlist.

If counsel clears a particular snapshot for internal benchmark use:

- record its permanent ID, configuration, generation date, retrieval date, and constituent-source licenses;
- keep it in a benchmark-only store with no production lookup path;
- use it to measure false-positive rate, parser resilience, cache behavior, and latency;
- never open the live domains from ordinary CI or a developer workstation;
- construct offline HTTP, DNS, TLS, RDAP, and page fixtures using reserved domains rather than copying live content;
- do not commit or redistribute the snapshot without explicit permission;
- make the test assert that popularity cannot override exact malicious evidence.

A preferable benign corpus is Hezo-owned or contributed under an explicit benchmark license. Direct CrUX data is published under CC BY 4.0 and may be considered as a candidate source of popular origins after its own privacy, quality, cost, and attribution review; it is not proof of safety either.

Primary sources:

- [Tranco access, cadence, attribution, and source licenses](https://tranco-list.eu/)
- [Tranco methodology](https://tranco-list.eu/methodology)
- [Tranco research paper](https://tranco-list.eu/assets/tranco-ndss19.pdf)
- [Cloudflare Radar license statement](https://developers.cloudflare.com/radar/)
- [CrUX dataset license](https://developer.chrome.com/docs/crux/methodology)

## US public seed intelligence

### CISA `.gov` domain data

The CISA-operated `.gov` registry publishes the authoritative full list of registered `.gov` second-level domains, a federal subset, and the `.gov` zone file. The repository uses the CC0-1.0 license and updates its principal files daily when there is activity.

Approved ingestion fields:

- domain name;
- registrant organization;
- government domain type;
- federal agency classification where supplied;
- city and state only when needed for organization disambiguation;
- dataset revision and fetch time.

Do not ingest the published security-contact email. Do not infer that the dataset lists every government hostname or every legitimate US government service; it lists registered second-level `.gov` domains, and some registered domains offer no online service.

An exact registry-backed `.gov` relationship creates positive official-domain evidence for government impersonation policy. It suppresses a conflicting government-impersonation signal only. It does not suppress malware, compromise, malicious redirects, or other exact behavior evidence.

Primary sources:

- [get.gov public data](https://get.gov/about/data/)
- [CISA dotgov-data repository](https://github.com/cisagov/dotgov-data/)
- [dotgov-data CC0-1.0 license](https://github.com/cisagov/dotgov-data/blob/main/LICENSE)

### FTC aggregate data and Consumer Alerts

The FTC's website policy says most FTC website material is US government work in the public domain. It asks that use, duplication, or redistribution carry appropriate attribution where feasible. Hezo must not imply FTC endorsement, misuse the FTC seal, or assume that third-party materials embedded in an FTC page are public domain.

Approved uses:

- current US scam taxonomy and consumer vocabulary;
- common impersonation, contact-channel, and payment-method patterns;
- aggregate category and loss trends as product-research priors;
- manually reviewed scenario fixtures derived from public guidance;
- links to authoritative consumer guidance.

The public Consumer Sentinel Data Book contains aggregated information based on unverified consumer reports. The interactive public data is updated quarterly. Raw Consumer Sentinel reports are available only to law-enforcement participants and are governed by confidentiality obligations; they are not a Hezo seed feed.

Aggregate volume must not influence a particular URL verdict without an entity-level observation. A common scam story can prioritize a brand or scenario for coverage, but it is not evidence that a matching phrase or category is malicious.

Attribution should use a bounded form such as `Source: U.S. Federal Trade Commission, ftc.gov`, link the public product, and avoid logos or seals.

Primary sources:

- [FTC website policy](https://www.ftc.gov/policy-notices/website-policy)
- [Consumer Sentinel Network access](https://www.ftc.gov/enforcement/consumer-sentinel-network)
- [Public Consumer Sentinel reports](https://www.ftc.gov/enforcement/consumer-sentinel-network/reports)
- [Consumer Sentinel Data Book and public data](https://www.ftc.gov/reports/consumer-sentinel-network-data-book-2024)
- [FTC Consumer Alerts archive](https://consumer.ftc.gov/consumer-alerts/archive)
- [Consumer Sentinel confidentiality agreement](https://www.ftc.gov/system/files/documents/cooperation_agreements/000720csnagreement.pdf)

### FBI Internet Crime Complaint Center

IC3 publishes annual Internet Crime Reports and ad hoc Public Service Announcements. These are useful for US scam categories, channels, tactics, loss context, and current campaign narratives. Some PSAs publish specific indicators.

Approved use requires:

- public reports and PSAs only, never complaint records or victim information;
- source product, alert number, publication/revision date, and source URL on every observation;
- retention of the `as is` and no-commercial-endorsement context;
- separate provenance when an indicator is attributed to a partner or trusted third party;
- revalidation and short freshness for operational indicators;
- no FBI seal, third-party artwork, or implication that FBI endorses Hezo.

An annual statistic or PSA narrative informs taxonomy and campaign hypotheses. Only a specifically published, scoped, current indicator may become an entity-level observation, and it remains subject to the normal corroboration, contradiction, decay, and block-eligibility policy.

Primary sources:

- [2025 IC3 Annual Report](https://www.ic3.gov/AnnualReport/Reports/2025_IC3Report.pdf)
- [2026 IC3 Public Service Announcements](https://www.ic3.gov/PSA/2026)
- [Example 2026 malicious-traffic-distribution PSA](https://www.ic3.gov/PSA/2026/PSA260618)

### CISA TLP:CLEAR advisories

CISA Cybersecurity Advisories can publish domains, URLs, IP addresses, file hashes, techniques, affected periods, and mitigation context. CISA describes TLP:CLEAR as publicly releasable, and TLP:CLEAR material may be shared without restriction subject to standard copyright rules.

TLP is an information-sharing convention, not a copyright license. Joint products and their tables can contain partner or third-party material. Ingest factual indicators rather than copying an advisory wholesale, and preserve the named source for each indicator.

Required fields and controls:

- CISA alert or advisory code and revision;
- title, public URL, publication and last-revised times;
- TLP marking;
- indicator type, exact de-fanged source value, scope, and observed period;
- named authoring organization or third-party source;
- source caveats about historical, shared, or reassigned infrastructure;
- revalidation time and expiry;
- review before an indicator becomes block eligible.

Only TLP:CLEAR or otherwise expressly public material belongs in this connector. Do not ingest TLP:GREEN, TLP:AMBER, TLP:AMBER+STRICT, TLP:RED, partner-portal, or access-controlled information without a separate sharing agreement and architecture review.

Primary sources:

- [CISA Cybersecurity Alerts and Advisories](https://www.cisa.gov/news-events/cybersecurity-advisories)
- [CISA adoption of TLP 2.0](https://www.cisa.gov/news-events/alerts/2022/10/25/cisa-upgrades-version-20-traffic-light-protocol-one-week-join-us)
- [Example CISA advisory with public IOCs](https://www.cisa.gov/news-events/cybersecurity-advisories/aa23-187a)

### Public-source limitation

No US government source reviewed here provides a public, continuously updated raw scam-URL feed comparable to a licensed phishing service.

- FTC and IC3 primarily inform taxonomy, explanations, priorities, and aggregate trends.
- CISA advisories occasionally provide dated IOCs rather than a comprehensive consumer scam feed.
- CISA `.gov` data supplies authoritative official-domain relationships rather than malicious URLs.

Do not present these sources as coverage substitutes for current exact threat intelligence and Hezo's own evidence pipeline.

## Licensing-aware schema direction

The PostgreSQL model must make source rights executable. Names below are logical; document 05 owns final physical naming.

### Intelligence source

One row identifies the provider and product, not merely the provider. Google Safe Browsing and Google Web Risk are separate products with different rights. OpenPhish Community and Premium are separate products.

Required fields:

- stable source ID, provider, product name, and source class;
- homepage, documentation, API/feed, pricing, terms, privacy, and correction URLs;
- credential owner and secret reference, never the credential value;
- production state: proposed, trial, conditionally approved, approved, paused, blocked, or retired;
- commercial internal-use, consumer-verdict, consumer-display, client-enforcement, B2B-output, raw-redistribution, and model-use booleans;
- allowed indicator types, categories, match types, and enforcement scopes;
- attribution and advisory templates;
- personal-data possibility and approved field allowlist;
- minimum poll interval, default freshness, hard expiry, and maximum raw retention;
- quota and cost model with alert and hard-stop thresholds;
- contract reference, owner, review date, and next review date.

An absent right is false. Do not use nullable booleans to mean “probably allowed.”

### Source terms snapshot

Required fields:

- source ID;
- exact terms URL;
- retrieved, published, and effective times when available;
- immutable normalized text or approved archived document reference;
- cryptographic content hash;
- reviewer and decision;
- rights matrix and structured obligations;
- material-change summary;
- superseded snapshot reference.

Terms snapshots are immutable. A changed page creates a new snapshot and review task; it does not mutate the prior basis for old observations.

### Ingestion run

Required fields:

- source, connector version, terms snapshot, and environment;
- requested and completed times;
- conditional-request metadata such as `ETag` and `Last-Modified`;
- provider dataset/version identifier and content hash;
- item counts accepted, rejected, retracted, expired, and unchanged;
- quota/cost units and bounded status;
- retry/backoff time and last-known-good pointer;
- raw encrypted object reference with destruction time, if retention is allowed.

The run record must not contain an indicator value in loggable error text.

### Observation provenance

Every imported observation carries:

- source ID and source terms snapshot ID;
- source record ID and public record URL where allowed;
- ingestion run and collector version;
- source-published, observed, ingested, last-confirmed, recheck, and expiry times;
- exact match/category/scope semantics;
- source confidence or verification state without treating it as a Hezo probability;
- content fingerprint for idempotency;
- TLP or other handling marking;
- raw payload reference only when licensed and still within retention;
- supersedes, contradicts, or retracts reference when applicable.

### Effective usage scope

Derived signals, edges, verdict evidence, block entries, analyst exports, benchmark outputs, and future API records need a computed effective-usage record. It is the intersection of rights inherited from all supporting observations.

At minimum it answers:

- may this support an internal verdict;
- may it appear in a consumer explanation;
- may the exact value enter an on-device blockset;
- may a sanitized derived indicator appear in a B2B product;
- what attribution, advisory, freshness, and deletion obligations apply;
- which support must be removed or recomputed if the license expires.

A prohibited supporting observation cannot be hidden by combining it with Hezo-owned evidence.

## Connector operational contract

Every source connector must implement:

- a feature flag and production kill switch independent of deploy;
- fail-closed source-policy evaluation before a request, import, or output;
- separate credentials per environment and source product;
- documented provider canonicalization with official test vectors where available;
- bounded concurrency, rate limiting, jittered retry, `Retry-After`, and circuit breaking;
- conditional fetching and last-known-good behavior;
- signature, checksum, schema, compression-bomb, and size validation as applicable;
- strict parser field allowlists and bounded strings/arrays;
- idempotent imports and deterministic retraction/expiry behavior;
- freshness and staleness metrics without indicator labels;
- cost/quota alerts and a hard monthly stop;
- encrypted transient raw storage and a source-specific destruction job;
- a provider correction and false-positive workflow;
- test fixtures built from reserved examples, never copied live feed records;
- an exercised process to disable the source and replay verdicts without it.

Feed downloads, API responses, terms pages, archives, and compressed files are untrusted inputs. They must not share a parser process or credential with the crawler and must not be able to reach another data plane.

## Production enablement checklist

A production source remains disabled until all required answers are documented.

### Rights and contract

- [ ] Provider and exact product are identified.
- [ ] Current terms and any order form or addendum are archived and hashed.
- [ ] Commercial internal use is expressly permitted.
- [ ] Consumer verdict use is expressly permitted.
- [ ] The exact consumer evidence/display format is permitted.
- [ ] Client blockset or enforcement use is permitted, if proposed.
- [ ] Derived B2B output is separately permitted or explicitly disabled.
- [ ] Raw redistribution is separately permitted or explicitly disabled.
- [ ] Model training and validation are separately permitted or explicitly disabled.
- [ ] Cloud processors, contractors, backups, and disaster recovery are covered.
- [ ] Attribution, advisory, correction, audit, geography, retention, and termination obligations are encoded.
- [ ] Legal/owner review and next-review date are recorded.

### Privacy and security

- [ ] The provider data-flow is in the privacy inventory.
- [ ] URLs or other submitted values are minimized consistently with the provider contract and security need.
- [ ] Personal-data fields have an allowlist and deletion schedule.
- [ ] Source credentials are isolated and rotation is tested.
- [ ] TLS, provider authentication, signatures/checksums, parser limits, and backoff are tested.
- [ ] Raw payloads cannot reach logs, traces, analytics, MPD, anti-abuse, or the repository.
- [ ] Provider compromise, malformed data, replay, rollback, and stale-feed behavior are tested.

### Quality and verdict policy

- [ ] Indicator types, categories, match semantics, and evidence scope are mapped explicitly.
- [ ] Freshness, expiry, retraction, and false-positive behavior are defined.
- [ ] A current benchmark establishes coverage and false-positive characteristics.
- [ ] Correlated sources are assigned to the correct signal family and cap.
- [ ] Exact-match Dangerous and auto-block eligibility are separately approved.
- [ ] Source absence, timeout, quota exhaustion, and outage affect completeness correctly.
- [ ] Consumer explanation and provider-required notices pass copy and UI tests.

### Operations and cost

- [ ] Minimum poll interval, quota, and cache behavior follow provider documentation.
- [ ] Monthly cost forecast, alert thresholds, and hard stop are configured.
- [ ] Last-known-good, rollback, source pause, and recovery are exercised.
- [ ] Source freshness, item volume, parse rejection, and correction metrics have bounded cardinality.
- [ ] A terms-monitor and recurring manual review are assigned.
- [ ] Raw and derived deletion jobs are verified against backups.
- [ ] Verdict, blockset, and export recomputation without the source is tested.

## Terms-change and retirement procedure

1. Fetch and normalize monitored terms and pricing pages on a recurring schedule.
2. When a content hash changes, create a new unapproved terms snapshot and alert the owner.
3. Pause new ingestion automatically when a material right, retention rule, price, interface, or attribution obligation may have changed.
4. Continue using unexpired prior observations only when the prior agreement expressly preserves that right; otherwise exclude them.
5. Review the change, update structured obligations, tests, forecasts, and public copy, then approve or retire.
6. On retirement, revoke credentials, stop jobs, destroy raw data and prohibited derived products, and recompute affected verdicts and blocksets.
7. Retain only the audit records and provenance that the agreement and law allow.

An unavailable source must not silently remain influential beyond its approved freshness window.

## Acceptance criteria

The intelligence-source baseline is ready for implementation when:

- Safe Browsing, OpenPhish Community, URLhaus Community, default Tranco production use, and uncleared PhishTank use are encoded as blocked;
- Web Risk Lookup cannot produce a current warning without its expiry, attribution, and advisory obligations;
- no third-party raw feed can be returned by a Hezo API or committed to the repository;
- every external observation references an immutable source and terms snapshot;
- every derived output computes effective rights from its support;
- terms changes can pause ingestion without a deploy;
- a source can be disabled and affected verdicts and blocksets can be replayed without it;
- RDAP retains only approved fields and honors provider-specific terms and rate limits;
- CT monitoring cannot become non-Chrome certificate enforcement;
- CISA `.gov` data suppresses only government-impersonation evidence and never grants immunity;
- FTC and IC3 aggregates cannot become URL-level evidence;
- TLP markings and third-party authorship survive CISA advisory ingestion;
- source credentials, raw data, logs, queues, and retention remain confined to the security-intelligence plane;
- every enabled source has a cost ceiling, freshness alarm, correction path, recurring terms review, and tested kill switch.
