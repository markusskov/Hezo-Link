# URL-policy oracles

This package freezes public reference material for the bounded, offline URL-policy work in manual URL syntax profile 2. Every consumer must validate `manifest.json`, verify every listed byte count and SHA-256 digest, and then validate the project-authored case payload against its Draft 2020-12 schema before reading a case.

The package is test data only. Operational use is forbidden. A test or tool must not resolve, connect to, fetch, or navigate to any string in these files. The package contains no operational or captured input, credential, secret, production observation, or permission to make a network request. No literal is sourced from live Hezo traffic.

The verbatim WPT artifact includes public parser-test literals that name potentially resolvable hosts or resemble historical filesystem paths. They are upstream test-vector strings, not Hezo observations or captured user data, and the offline rule applies to them without exception.

## Contents and provenance

- `upstream/unicode/IdnaTestV2-17.0.0.txt` is a byte-for-byte copy of the Unicode 17.0.0 `IdnaTestV2.txt` conformance data for UTS #46. Its source URL, revision, exact size, digest, record counts, and Unicode-3.0 license binding are pinned in the manifest.
- `upstream/wpt/urltestdata-eb7aa8a1.json` is a byte-for-byte copy of Web Platform Tests `url/resources/urltestdata.json` at commit `eb7aa8a1d700d76170f68cf5c8da748928abd32f`. Only its repository path was renamed. Its source URL, revision, exact size, digest, entry counts, and BSD-3-Clause license binding are pinned in the manifest.
- `upstream/unicode/LICENSE.txt` and `upstream/wpt/LICENSE.md` are byte-for-byte copies of the corresponding upstream license texts.
- `cases/address-policy-cases-v1.json` is project-authored from the exact RFC sections cited by each case. It covers canonical IPv4, rejection of alternate IPv4 spellings, RFC 5952 rendering variants, IPv4-mapped IPv6 normalization, NAT64, 6to4, Teredo syntax, malformed IPv6, and forbidden zone identifiers. Ordinary addresses use RFC-reserved documentation space. Transition-mechanism cases use the applicable standard mechanism prefix with embedded TEST-NET values where the format carries IPv4 bytes.
- `schemas/address-policy-cases-v1.schema.json` and `manifest.schema.json` are strict JSON Schemas using Draft 2020-12.

`manifest.json` binds every package artifact except itself. A manifest cannot contain its own stable digest; reviewers must record its exact hash in the commit or review evidence instead of adding a circular self-reference.

## Intended use

The Unicode corpus is an upstream UTS #46 conformance oracle. The WPT corpus is an upstream WHATWG URL parser oracle and a source of parser-differential inputs. The RFC-derived cases are the executable expectations for Hezo's narrower address-literal syntax policy.

Hezo's manual-input validator is intentionally more restrictive than a general-purpose browser URL parser. An upstream WPT success therefore does not imply that Hezo should accept the input. Tests must distinguish upstream parser behavior from project policy and must never silently treat one corpus as the other's expected-result format.

Accepted address expectations name their normalization basis. In particular, profile 2 deliberately collapses IPv4-mapped IPv6 to the shared IPv4 policy identity and uses a project-owned hexadecimal IPv6 rendering for NAT64. Those are Hezo policy/parser transformations, not claims that the resulting text is the canonical mixed notation recommended by the cited RFCs.

Validation is fail closed: missing files, unlisted files used as oracle inputs, schema errors, duplicate project case IDs, count drift, digest drift, non-LF line endings, a missing final newline, provenance drift, or license drift makes the package unusable until reviewed.

Draft 2020-12 does not express uniqueness or aggregate equality after projecting fields from an array. Schema validation is therefore necessary but not sufficient. Every consumer must also run the companion semantic checks named in the manifest: case-ID uniqueness; declared versus projected category and outcome counts; the distinct RFC-document count; exact coherence of every RFC document/section/URL tuple; and transformation-role coherence. The checked-in test harness is the reference implementation of those checks. Skipping that companion validation is a validation failure, not a reduced assurance mode.

## Nonclaims

This package does not establish:

- complete conformance of any Hezo parser, IDNA implementation, Foundation release, or operating system;
- destination reachability, routability, public/special address classification, DNS safety, SSRF resistance, redirect safety, or authorization to connect;
- provider canonicalization, durable URL identity, Public Suffix List behavior, or IANA address-registry coverage;
- equivalence between WHATWG URL parsing, UTS #46 processing, RFC syntax, and Hezo policy;
- complete branch coverage, a sustained fuzz campaign, production readiness, or any Stage 0/Stage 1 exit result.

## Update procedure

Updates are deliberate maintainer changes, never runtime downloads. Keep the package and its test harness offline.

1. Outside this package, obtain a candidate only from the official publisher URL. Pin an immutable revision before import; never use an unpinned branch or mutable latest URL for WPT data.
2. Review redistribution terms and stage the exact license text beside the candidate. Reject the update if provenance, rights, or the immutable revision cannot be established.
3. Copy the approved source bytes into `upstream/` without decoding, reformatting, Unicode normalization, newline conversion, comment removal, or JSON reserialization. A repository-only filename change must be recorded as such and must not change content bytes.
4. Verify SHA-256, byte count, UTF-8 decoding, LF-only endings, final newline, and the type-specific counts defined by `manifest.schema.json`. Compare the imported digest with the staged source digest before deleting staging material.
5. For project-authored cases, use only reserved documentation values or the named standard mechanism prefixes, cite the exact current RFC section on every case, keep network and operational use forbidden, update category/outcome/RFC counts, and validate unique IDs.
6. Update the manifest only after every other package file is final. Validate both schemas in strict Draft 2020-12 mode, validate both payloads, verify every manifest path resolves inside this directory, and recompute every manifest-bound digest and count from bytes on disk.
7. Run the Swift/package tests and an independent review. Treat any unexpected corpus, parser, normalization, license, or provenance change as a blocked update rather than weakening an expectation.

Do not add an automatic updater or fallback fetch path. A future corpus revision is a reviewed source change, not a reason for tests to access the network.
