# Stage 0 repository safety

This repository is intended to be safe for public review. Treat every tracked file, commit message, branch, patch, issue excerpt, and build artifact as potentially public, even before publication.

The ignored `.private/` directory is a convenience for temporary local restricted work, not a secure vault. Ignoring a file does not encrypt it, control access, create retention, or provide backup. Shared restricted material belongs in an approved access-controlled system outside Git.

## Public/private boundary

| Public repository may contain | Keep outside Git |
|---|---|
| Normative requirements, governance templates, schemas, and generic role assignments | Personal names, contact details, private owner mappings, or internal communication |
| Accepted ADR outcomes and sanitized rationale | Credentials, tokens, keys, certificates, signing material, provisioning material, secret values, or recovery data |
| Deterministic synthetic, reserved-domain, loopback, generated, or approved sanitized non-executable fixtures | Live malicious or sensitive URLs, threat-feed rows, captured submissions, real DNS answers, raw pages, archives, HAR files, screenshots, or executable hostile content |
| Public-safe fixture manifests, expected results, and deterministic generators after rights review | Device, cloud, edge, proxy, resolver, service, security, or incident logs; raw proof output; attestation objects or receipts |
| Sanitized proof summaries, limitations, case outcomes, and opaque evidence IDs | Account, application, bundle, team, project, device, installation, attestation, analytics, or submission identifiers |
| Public source citations and relative links to tracked public-safe artifacts | Contracts, terms snapshots, vendor negotiations, procurement records, exact budgets, invoices, or private legal advice |
| Non-sensitive digests of public or high-entropy artifacts when they aid reproducibility | Digests that disclose, confirm, or make guessable a secret, live target, low-entropy identifier, or restricted record |
| Explicitly reviewed source and configuration with inert placeholders | Private endpoints, unpublished service origins, internal network details, exploit instructions, boundary-canary locations, or incident evidence |

Public visibility does not grant reuse rights. Until O-019 is decided, do not add license claims, contribution promises, or wording that implies permission beyond applicable law.

## Fixture and network boundary

Ordinary local and pull-request tests may use only the safe classes defined in [document 10](../10-testing-and-benchmarks.md#local-and-pull-request-ci): reserved example domains, loopback fixture services, synthetic graphs and datasets, generated content, published validation vectors where redistribution is permitted, and specifically approved sanitized non-executable snapshots.

They must not open live malicious URLs, pull live threat feeds, replay captured submissions, execute hostile pages, use real attestation material, or contact real metadata services. A test harness must deny undeclared egress technically; source review, a URL-pattern scan, or a promise not to connect is insufficient evidence. The actual isolated-execution mechanism requires an Accepted ADR and is not selected by this governance batch.

## Evidence references

Public plans, ADRs, and evidence bundles may refer to restricted evidence only through an opaque approved ID and a sanitized outcome. The ID must reveal no storage path, service URL, personal identity, target, provider account, or secret. It is resolved through a separate authorized index outside Git.

Do not link to `.private/`, a local filesystem path, a restricted collaboration page, a signed download, a private service, or a live target. Do not paste raw evidence into a review discussion to work around this rule. When reviewers need the underlying record, use the approved private review channel and publish only the minimum sanitized conclusion.

## Before committing

Review the complete staged change, including generated files and metadata, and confirm:

- every name is a generic role or public project term;
- all fixtures are declared in a manifest and are synthetic, reserved, loopback-only, or explicitly approved for public inclusion;
- no URL, hostname, address, identifier, log fragment, screenshot, or payload came from a live submission, threat source, device, account, or environment;
- examples contain inert placeholders rather than realistic secrets;
- public digests cannot be used to guess or confirm restricted values;
- contracts, budgets, terms snapshots, account details, and external approval artifacts remain outside Git;
- links resolve only to public-safe tracked files or public references, never restricted storage or live targets;
- dependency and fixture licenses permit the intended public use;
- build output, caches, captures, result bundles, and editor/OS metadata are not staged; and
- the change makes no unsupported claim that a test, review, external request, approval, or gate passed.

The ignore file is defense in depth, not the check. A file already tracked remains tracked even if a later ignore pattern matches it.

## If restricted material crosses the boundary

1. Stop the proof or publication flow and notify the accountable security/privacy role through the private channel.
2. Treat credentials and secrets as exposed; revoke or rotate them through the authorized process.
3. Preserve only the restricted incident record required by policy. Do not copy the material into another Git branch, issue, or chat.
4. Remove the material from the proposed change and assess repository history, mirrors, caches, artifacts, and downstream exposure before resuming.
5. Add a sanitized regression or process correction without reproducing the restricted value.
6. Mark affected evidence incomplete or failed. A leak response does not retroactively make its proof pass.

History rewriting, deletion from shared systems, and incident disclosure are owner-controlled actions; this document does not authorize them automatically.
