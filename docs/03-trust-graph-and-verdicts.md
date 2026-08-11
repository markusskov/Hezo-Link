# Trust Graph and verdict specification

## Core principle

Hezo does not ask only whether a URL looks suspicious. It asks:

> What was observed, where did it come from, how fresh and reliable is it, what else is the subject connected to, and what action does that evidence justify?

The durable order is:

~~~text
immutable observations
        |
evidence-backed relationships
        |
versioned derived signals
        |
versioned verdict snapshot
        |
separate block-eligibility decision
~~~

Observations are the durable asset. Relationships, signals, scores, verdicts, campaign membership, explanations, and blocksets must be replaceable and reproducible.

This is an acyclic evaluation graph. Base relationships depend on immutable observations at the selected evidence watermark. A declared higher relationship tier, such as campaign membership, may depend on lower-tier relationships at that same watermark, but its support must flatten back to observations and the tier graph must be acyclic. A signal may depend on those observations and relationship versions. A verdict may depend on signals, relationships, and observations; block eligibility may depend on the resulting verdict snapshot. Relationships never depend on signals or verdicts, signals never depend on verdicts, and no derived stage may read a newer watermark than its inputs. If a new observation changes a relationship, the system recomputes every downstream stage rather than feeding a later result back into an earlier one.

## Canonical vocabulary

| Term | Meaning |
|---|---|
| Entity | A typed thing in the graph, such as a URL, domain, IP, brand, artifact, or campaign |
| Observation | An immutable fact produced by a named collector or source at a time |
| Signal | A versioned interpretation derived from observations and, where policy permits, evidence-backed relationships at the same watermark |
| Edge | An evidence-backed relationship between two entities |
| Evidence item | A user- or analyst-readable reason selected from observations, signals, and edges |
| Risk score | A bounded policy score used for ordering and rules; not a probability |
| Confidence | How strongly the evidence supports a specific observation, edge, or classification |
| Completeness | Whether the collectors required by the active policy profile completed |
| Verdict | Unknown, No known danger, Caution, or Dangerous |
| Block eligible | A separate boolean/action decision under a stricter policy |
| Campaign | A cluster of related observable activity; never attacker attribution |

Risk, confidence, completeness, and block eligibility are different dimensions. Do not collapse them into a single number.

## URL representations

Every URL accepted for manual checking or analysis may have four representations. A report may also retain a separately encrypted restricted-intake copy under O-017; that copy is not an analysis representation or graph field. Any report URL copied into the analysis pipeline follows the 24-hour rules below.

### Raw analysis-submission URL

Exactly what the user submitted, including query and fragment.

- Encrypted transiently.
- Available only to the analysis job that needs it.
- Never written to normal application logs, traces, analytics, error reporting, or durable graph tables.
- Purged as soon as analysis finishes and never later than the current 24-hour hard retention limit in document 02. No incident hold may exceed that ceiling unless O-007 is explicitly decided and every affected privacy, schema, sandbox, test, and backup rule is updated first.

Query strings and fragments must not be stripped before analysis. Redirect targets, campaign selectors, tokens used by the malicious page, and client-side payloads may be present there.

### Network URL

The exact destination navigated by the isolated worker after syntactic validation and security policy. Every redirect creates another transient network URL and must pass the same egress checks.

### Provider-specific canonical form

Each external lookup or blockset format may have its own canonicalization contract. Implement each as a versioned pure function with the provider’s official test vectors. Do not create one invented canonical form and assume every provider accepts it.

### Long-term sanitized security form

Durable representation should contain only what is needed:

- normalized scheme, ASCII host, port when non-default, and normalized path;
- registrable-domain relationship;
- query-key names only when useful;
- explicitly approved non-sensitive query values only;
- cryptographic fingerprint of the exact canonical threat representation;
- canonicalizer version;
- first/last seen and evidence provenance.

Sensitive query values, user information, session tokens, reset codes, and arbitrary fragments are discarded. An exact value needed for an active blockset is held in a restricted, encrypted enforcement table with an expiry and source-rights record, not in the general graph.

## V1 entity types

Base entities:

- URL;
- domain;
- IP address;
- autonomous system;
- TLS certificate;
- nameserver;
- brand;
- organization;
- page template;
- visual fingerprint;
- favicon;
- script or asset fingerprint;
- form target;
- redirect target;
- campaign.

Future entities such as phone numbers, email senders, wallets, social profiles, and media are reserved conceptually but must not be implemented in V1.

Entity identity is type specific. Examples:

- a domain is keyed by lowercased IDNA ASCII name;
- an IP uses canonical binary network form;
- a certificate uses the cryptographic fingerprint of DER bytes;
- an artifact uses algorithm plus digest;
- a URL uses versioned provider/security canonical fingerprints rather than a retained raw string.

## Relationship types

Initial edges include:

- URL LOCATED_ON domain;
- domain RESOLVES_TO IP;
- IP BELONGS_TO ASN;
- domain USES_NAMESERVER nameserver;
- domain or URL USES_CERTIFICATE certificate;
- URL REDIRECTS_TO URL;
- page POSTS_TO form target;
- page LOADS_ASSET artifact;
- URL IMPERSONATES brand;
- brand VERIFIED_DOMAIN domain;
- entity SHARES_TEMPLATE_WITH entity;
- entity SHARES_FAVICON_WITH entity;
- entity MEMBER_OF campaign;
- campaign TARGETS brand.

Every edge carries:

- source and target;
- relationship type and scope;
- first and last observed time;
- confidence;
- supporting observation IDs;
- derivation or collector version;
- expiry or next-review time;
- license/usage constraints inherited from its support;
- status such as active, stale, contradicted, or retracted.

An edge is not attribution. Similar infrastructure or artifacts justify “appears related to this campaign,” not “operated by the same criminal.”

## Observation contract

Observations are append-only. Corrections are new observations that supersede or contradict older ones.

Required fields:

- observation ID;
- subject entity ID;
- observation type;
- typed value or bounded JSON value;
- source ID and source record ID where available;
- collection or import run ID;
- collector version;
- observed-at and source-published-at times;
- ingested-at time;
- expiry or recheck time;
- confidence in the observed fact;
- license snapshot and usage scope;
- content fingerprint for idempotency;
- optional supersedes or contradicts reference.

Collectors report facts, not verdicts. RDAP reports a registration date. A versioned derivation turns that into domain_age_under_24_hours.

## Provenance and license propagation

Every external observation must resolve to a source and terms snapshot containing at least:

- provider and product;
- terms URL and captured/effective date;
- permitted internal use;
- whether consumer verdicts and explanations are permitted;
- whether derived B2B output is permitted;
- whether raw redistribution is permitted;
- attribution and advisory-text requirements;
- deletion, expiry, and refresh requirements;
- geography or customer restrictions.

Derived edges, verdict evidence, blockset entries, exports, and APIs must compute an effective usage scope from their supporting observations. If any required support is not licensed for an output, the output is forbidden or must be recomputed without that support.

## Signal families and independence

Correlated observations do not become independent evidence by being numerous.

Initial family caps are policy configuration, not statistical truth:

| Family | Examples | Initial maximum positive contribution |
|---|---|---:|
| Qualified external intelligence | Exact Web Risk, licensed malware feed, analyst-confirmed source | 100 |
| Malicious behavior | Credential exfiltration, malware delivery, exploit or malicious redirect | 80 |
| Identity and impersonation | Unrelated domain plus brand, page, or flow similarity | 40 |
| Campaign relationship | High-specificity link to a confirmed campaign | 70 |
| Infrastructure | DNS, IP, certificate, or nameserver relationships | 25 |
| Lifecycle and lexical | Domain age, confusables, typo, encoding | 15 |
| Community | Validated independent reports | 15 |
| Combination | Explicit cross-family synergy rule | 25 |
| Positive trust | Official relationship and stable clean evidence | Targeted suppression only |

The combination family can raise a score but never counts as an independent family for a Dangerous or block rule.

Examples of correlated facts:

- domain created today;
- certificate created today;
- DNS first observed today.

These primarily describe infrastructure newness. Their raw sum is capped inside lifecycle/infrastructure policy and does not satisfy a multiple-independent-family requirement.

## Initial signal policy

The following values are bootstrap policy weights. They must live in versioned configuration and be recalibrated against the benchmark corpus.

### Qualified external intelligence

| Signal | Initial score | Can independently produce Dangerous? | Can auto-block alone? |
|---|---:|---|---|
| Current Hezo analyst-confirmed exact malicious URL | 100 | Yes | Yes, at exact reviewed scope |
| Current qualified commercial exact URL match | 100 | Yes | Only when source/category is explicitly approved |
| Current verified-and-online phishing exact URL | 90 | Yes | Only after licensing and source-quality approval |
| Hezo-confirmed domain-wide malicious control | 90 | Yes | Yes, only at reviewed domain scope |
| Lower-confidence or extended-coverage match | 25 | No | No |
| Unverified community/external report | 10 | No | No |

“Qualified” is an allowlisted tuple of provider, product, category, match type, freshness, and scope. A generic confidence field or a provider name is insufficient.

### Malicious behavior

| Signal | Initial score |
|---|---:|
| Redirects to a current confirmed malicious URL | 80 |
| Delivers confirmed malware or known exploit | 80 |
| Credential form submits to an unrelated suspicious endpoint | 35 |
| Payment-card form on an unrelated impersonating domain | 35 |
| Password form on a newly observed non-brand domain | 10 |
| Obfuscated automatic multi-hop redirect chain | 10 |
| Browser notification prompt | 2 |
| Generic login page | 0 alone |

The crawler does not submit forms. It analyzes action targets, inputs, scripts, and network behavior produced by passive loading.

### Identity and lifecycle

Initial examples:

- strong brand/page resemblance on an unrelated domain: up to 20;
- brand-confusable IDN: up to 15;
- strong protected-brand typo: up to 10;
- logo or visual match alone: up to 8;
- domain younger than 24 hours: up to 8;
- domain age one to seven days: up to 5;
- brand plus urgency term: up to 5;
- raw IP destination: up to 4;
- long URL or unusual subdomain depth: low single digits.

The following have zero score alone:

- a particular TLD;
- a particular registrar, CDN, host, ASN, country, or language;
- a free certificate or a particular certificate authority;
- a generic login, payment, or notification UI.

Visual or language models may create bounded observations and signals. They can never create Dangerous or block eligible alone.

### Community

Community contribution is capped at 15 and requires valid anti-abuse capabilities, temporal diversity, rate limits, and independence checks. A provisional scale may trigger enrichment at 5, increase priority at 20, and reach the family cap only at very high qualified volume.

No volume of community reports can auto-block by itself.

## Positive trust and contradictions

Positive trust is family-specific.

An official brand-domain relationship:

- strongly suppresses an impersonation signal for that brand;
- does not suppress exact malware, compromise, malicious redirect, or other behavior evidence;
- does not permanently allow the domain;
- must itself have provenance and periodic verification.

Weak positive evidence such as domain longevity, popularity, stable infrastructure, or a long clean history may reduce uncertainty but never grants immunity.

A large popularity list must not be used as a global allowlist.

Contradictions are first-class records. Examples:

- official-domain evidence conflicts with brand-impersonation inference;
- a qualified exact threat match conflicts with a recent analyst retraction;
- two sources disagree on current online status;
- campaign similarity is high but a shared multi-tenant service explains the relationship.

Unresolved high-confidence contradictions prevent heuristic block eligibility. They normally produce Caution or Unknown and a review task.

Emergency allow/block overrides are separate, audited, scoped, expiring decisions. They never delete the observations that led to the original result.

## Risk-score calculation

For policy version P:

1. Select current, non-retracted signals valid for the subject and evaluation time.
2. Group by signal family and correlation key.
3. Apply within-family deduplication and cap.
4. Apply explicit, versioned combination rules.
5. Apply only family-targeted positive-trust suppression.
6. Clip the internal policy score to 0 through 100.
7. Record every included, excluded, capped, and suppressed contribution.

The score is useful for ordering and deterministic rules. It must not be called a probability unless a future calibration study supports that separate output.

## Initial verdict algorithm

Evaluate in this order.

### 1. Hard threat

If a current qualified hard-threat rule matches at the evaluated scope, return Dangerous even if some enrichment is incomplete. Record the source tuple, freshness, and scope.

### 2. Corroborated Dangerous

Return Dangerous only when all are true:

- risk score is at least 70;
- at least two genuinely independent positive signal families contribute;
- at least one contributing family is qualified external intelligence, malicious behavior, or confirmed campaign relationship;
- there is no unresolved high-confidence contradiction;
- evidence freshness satisfies the policy.

### 3. Caution

Return Caution when any is true:

- score is 25 through 69;
- a meaningful suspicious signal exists but corroboration is insufficient;
- evidence is materially contradictory;
- a lower-confidence external source matches;
- a model or campaign relation raises concern but cannot stand alone.

### 4. No known danger

Return No known danger only when:

- the policy’s minimum analysis profile completed;
- score is below 25;
- no meaningful current malicious signal or unresolved high-confidence contradiction exists;
- required internal/source data is fresh enough.

### 5. Unknown

Return Unknown otherwise for an accepted HTTP(S) target, including a parser disagreement discovered after request acceptance, an unsupported-but-syntactically-valid port, critical collector failure, insufficient data, stale support, or incomplete analysis. Malformed input and non-HTTP(S) schemes are rejected before verdict evaluation and therefore do not produce a verdict.

Operational failures are represented separately from the user verdict so the UI can distinguish “we do not know” from “try again later.”

## Analysis profiles and completeness

The active policy declares required collectors for each profile.

### Fast profile

- URL syntax and IDNA handling;
- current exact internal intelligence;
- current qualified exact external lookups;
- existing domain/brand/campaign relationships.

Fast may return Dangerous from a hard threat. It generally returns analyzing or Unknown for a novel URL rather than inventing No known danger.

### Standard profile

- fast profile;
- DNS, TLS, and RDAP where applicable;
- redirect and page analysis when risk or novelty policy requires it;
- current signal derivation and contradiction resolution.

No known danger for an unknown site requires completion of the policy-selected standard work, not success from every optional integration.

Completeness must name unavailable collectors. A failed source is not the same as a clean source result.

## Block eligibility

Dangerous does not imply block eligible.

### Route A: qualified exact threat

A current, explicitly approved hard-threat source or Hezo analyst decision can create an exact-scope block. The source policy controls expiry and revalidation.

This is the only automatic route enabled for the earliest consumer beta.

### Route B: high-confidence Hezo detection

Requires all:

- score at least 85;
- at least three independent families;
- one family is malicious behavior, confirmed campaign relationship, or qualified external intelligence;
- no unresolved high-confidence contradiction;
- precise block scope;
- benchmark gate passed;
- feature flag enabled.

Route B is implemented and tested before it is enabled.

### Route C: campaign propagation

Requires all:

- the campaign already contains a current confirmed malicious member;
- campaign and membership confidence are both very high under the active cluster policy;
- membership has at least two high-specificity supports, or one near-unique support plus independent malicious evidence;
- common infrastructure and multi-tenancy explanations are excluded;
- scope and expiry are explicit;
- campaign-propagation benchmark gate passed;
- feature flag enabled.

Route C remains disabled at initial release.

### Things that never auto-block alone

- age, registrar, TLD, ASN, hosting company, IP, certificate issuer, URL length, keywords, geography, or language;
- community reports;
- logo, visual, domain-typo, or template similarity;
- an AI/ML/LLM output;
- a new certificate;
- popularity or absence from an allowlist.

Property tests must enforce this list.

## Enforcement scope

Allowed scopes are explicit:

- exact threat representation;
- exact path or prefix when supported;
- host;
- registrable domain only after domain-wide control is justified.

Shared platforms, URL shorteners, cloud storage, hosted site builders, CDNs, and multi-tenant services default to the narrowest exact scope. A malicious page on a shared host never justifies blocking the platform.

Every block entry records its source verdict, scope rationale, creation policy, expiry, last validation, and rollback group.

## Campaign clustering

V1 uses deterministic graph/rule clustering before graph neural networks.

### High-specificity relationships

- exact form or collection endpoint;
- distinctive script or asset hash;
- distinctive page-template fingerprint;
- rare favicon plus template combination;
- exact redirect sink;
- exact wallet or payment destination;
- repeated unique DOM or obfuscation artifact.

### Medium-specificity relationships

- certificate fingerprint;
- narrow infrastructure co-occurrence in a short time window;
- visual/template similarity with measured collision rate;
- uncommon nameserver or redirect pattern.

### Weak relationships

- ASN, public-cloud provider, CDN, registrar, TLD, target brand, language, or domain age;
- IP sharing without tenancy analysis;
- common framework or common favicon.

Feature weights depend on rarity and collision rate, not intuition alone. Weak relationships may prioritize analysis but cannot establish membership.

Campaign IDs describe an operational cluster. Product copy may say “linked to an active campaign” only when membership confidence and current confirmed members satisfy policy. Never identify or imply a criminal actor without a separate, reviewed attribution process outside V1.

## Freshness, expiry, and re-evaluation

Every observation, signal, edge, verdict, and block entry has a freshness policy.

Proposed starting review windows:

| Evidence | Recheck or expiry guidance |
|---|---|
| Active exact threat-feed match | Provider expiry or frequent current-status refresh |
| DNS, redirect, page behavior | Hours to a few days, faster for active campaigns |
| TLS certificate | On change plus periodic refresh |
| RDAP creation facts | Durable fact; registration status rechecked periodically |
| Community velocity | Strong decay over hours/days |
| Official brand-domain relation | Periodic manual review plus change monitoring |
| Analyst block | Mandatory expiry or scheduled review; never permanent by accident |

Re-evaluate on:

- new or expired supporting evidence;
- source retraction;
- material DNS/TLS/redirect/page change;
- new qualified report or false-positive appeal;
- campaign membership change;
- policy, collector, canonicalizer, or model version change;
- impending block expiry.

Current verdict is a view over the latest valid snapshot. History remains auditable.

## Explanation policy

Consumer explanations:

- select three to five strongest independent items;
- prefer direct behavior and exact-source evidence over weak heuristics;
- identify recency and scope;
- distinguish observed facts from Hezo inference;
- omit raw URLs, personal query values, source-restricted data, and attacker-controlled copy;
- avoid provider attribution when license or product policy forbids it;
- use bounded templates, not free-form model claims.

An LLM may rewrite approved structured reason codes into plain language only if output is constrained, tested, and traceable to those reason codes. The structured reasons remain the source of truth.

## Reports, appeals, and analyst action

- Scam reports create observations and enrichment priority, not automatic truth.
- False-positive reports create contradiction/review tasks and can trigger a temporary scoped safety override.
- High-impact domains and high-volume false-positive spikes receive priority.
- Analyst decisions require reason, evidence, scope, reviewer, expiry, and audit trail.
- Retractions never delete original observations; they supersede them.
- A kill switch can withdraw a blockset generation without changing the underlying verdict history.

## Reproducibility

For any verdict or block entry, an authorized reviewer must be able to recover:

- subject and evaluated representation;
- policy and model versions;
- observation and edge versions;
- included, capped, excluded, stale, and suppressed signals;
- contradictions;
- source terms snapshots;
- explanation reason codes;
- block route and scope;
- evaluation time and expiry.

Offline replay of the same snapshot and versions must produce the same result.

## Acceptance tests

- Replaying stored observations under the same policy is deterministic.
- Changing policy produces a new verdict snapshot without mutating evidence.
- The no-single-weak-signal property holds for every forbidden auto-block input.
- Correlated newness signals cannot satisfy independent-family requirements.
- A malicious exact path on a shared host never creates a host/domain block.
- Official-domain evidence suppresses impersonation but not exact compromise evidence.
- Stale hard-threat evidence cannot continue blocking past policy without revalidation.
- A high-confidence contradiction disables Route B and Route C.
- Community volume alone cannot produce Dangerous or block eligible.
- Visual/LLM output alone cannot produce Dangerous or block eligible.
- Campaign propagation is disabled until its dedicated release gate passes.
- Consumer explanations contain only supported, permitted reason codes.
- Every block entry can be traced to a current verdict, route, scope, and expiry.
