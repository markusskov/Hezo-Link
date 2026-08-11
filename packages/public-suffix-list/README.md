# Pinned Public Suffix List

This package records the reviewed source, license, integrity, and lifecycle policy for the Public Suffix List snapshot bundled with `HezoLinkCore`. The snapshot supports only offline public-suffix and registrable-domain boundary classification. It adds no executable third-party package.

The repository and CI asset gate must validate `manifest.json` against `manifest.schema.json` and perform the companion integrity and semantic checks named by the manifest. The manifest is review metadata and is not bundled as a runtime resource. The runtime classifier instead validates the pinned resource's embedded markers and structural invariants and reports itself unavailable if the snapshot is missing or invalid. Neither this package nor its runtime consumer may download a replacement, consult DNS, resolve a name, connect to a host, navigate to a URL, or read an external or persistent data source.

## Dependency and source review

| Review item | Decision |
|---|---|
| Purpose | Offline public-suffix and registrable-domain boundary classification only |
| Runtime dependency | Vendored public data; no third-party executable code |
| Data access | Read-only bundled snapshot; no network, DNS, external store, persistent store, provider, telemetry, or captured/user-data access |
| Source | Official `https://publicsuffix.org/list/public_suffix_list.dat` distribution snapshot |
| Pinned revision | Commit `e1b8015c3b2f0f4f8c18659c2480fc1a22c07b20`; embedded version `2026-07-25_14-20-03_UTC` |
| Runtime license | Mozilla Public License 2.0 (`MPL-2.0`) with the exact license text bundled beside the list |
| Upstream test license | The copied `test_psl.txt` carries its upstream CC0 1.0 public-domain dedication in the file |
| Update policy | Reviewed, manual, byte-preserving updates only; no automatic or runtime updater |
| Failure behavior | Fail closed and report the classifier unavailable; no fallback ruleset when the asset is invalid or unavailable, and no stale/network fallback |
| Removal policy | Reviewed manual removal only, coordinated with all consumers, tests, resource declarations, notices, and documentation |

The runtime list at `Sources/HezoLinkCore/Resources/PublicSuffix/hezolink-public-suffix-list-e1b8015c.dat` is a byte-for-byte copy of the staged official publicsuffix.org response. That distribution response embeds the exact `VERSION` and `COMMIT` markers pinned above; it is not claimed to be byte-identical to the repository's unwrapped `public_suffix_list.dat` at the same commit. `Sources/HezoLinkCore/Resources/PublicSuffix/LICENSE-MPL-2.0.txt` is the byte-for-byte repository license text at that commit. `upstream/test_psl-e1b8015c.txt` is the byte-for-byte official upstream test corpus at that commit.

The manifest records repository-relative paths, byte counts, SHA-256 digests, physical-line counts, line-ending requirements, full ICANN and PRIVATE rule counts, Unicode-containing line counts, source URLs, revisions, transformations, and license bindings. It binds every package artifact except itself. A manifest cannot contain its own stable digest; its exact digest belongs in commit or review evidence rather than a circular self-reference.

## Classification-only warning

The [official PSL guidance](https://publicsuffix.org/learn/) warns that using the list to decide whether a domain is valid is dangerous: registries change, while a bundled snapshot is static. Hezo therefore uses this snapshot only to classify public-suffix and registrable-domain boundaries. It is not a DNS or domain-validity registry, and absence from or presence in the snapshot makes no claim about validity, existence, reachability, destination safety, ownership, affiliation, authorization, enforcement eligibility, a verdict, or user-interface treatment.

The official test corpus contains public test-vector strings naming ordinary and potentially resolvable domains. They remain inert upstream text. Tests and tools must never resolve, connect to, fetch, or navigate to them.

## Verbatim source retention

The official list includes public comments, contributor or maintainer names, and public contact addresses used for rule provenance. They are retained verbatim because removing, normalizing, re-encoding, or redacting any of them would stop the resource from being the pinned upstream artifact and would invalidate its digest. They are public upstream source notices, not Hezo observations, submissions, contacts, or operational data.

## Validation and failure behavior

Validation is fail closed at both boundaries. The repository or CI asset gate must reject the asset set if any required file is missing; any byte count, digest, count, marker, path, encoding, LF-only line ending, final newline, section boundary, provenance value, or license binding differs; the manifest or schema is invalid; or an unmanifested artifact is offered as input. The runtime classifier must reject a missing or structurally invalid bundled list. Rejection makes the classifier unavailable; it must not silently replace a rejected asset with an empty list, wildcard-only fallback, older copy, platform heuristic, DNS result, or download. This does not remove the PSL algorithm's official implicit `*` rule: that rule still applies when a successfully validated snapshot contains no matching listed rule.

JSON Schema cannot recompute file digests or projected rule counts. Schema validation is therefore necessary but not sufficient. Companion validation must independently hash the files, count physical and Unicode-containing lines, parse the ICANN and PRIVATE sections, project exact/wildcard/exception totals, verify the wrapper markers, and confirm that every manifest path resolves inside the repository to the intended artifact.

## Reviewed manual update procedure

1. Obtain the candidate list only from the official publicsuffix.org list URL outside runtime code. Record its embedded full commit and version, and reject an unpinned or malformed response.
2. At that same immutable commit, obtain the official upstream test corpus and license. Review the source diff, rule semantics, public notices, CC0 dedication, MPL-2.0 terms, and continued suitability for classification-only use.
3. Stage the exact bytes outside the package. Copy them without decoding, Unicode normalization, newline conversion, reformatting, comment removal, contact redaction, or content edits. Only the repository filenames may change.
4. Verify UTF-8, LF-only endings, final newlines, exact byte counts, SHA-256 digests, physical-line counts, wrapper markers, section boundaries, rule-kind totals, Unicode-containing line totals, and test-corpus counts.
5. Replace the runtime list, runtime license, and upstream test corpus as one reviewed change. Update the strict schema constants, manifest, documentation, classifier expectations, and tests together.
6. Validate the manifest in strict Draft 2020-12 mode, run every companion check and offline test, inspect the complete diff, and obtain independent review. Any unexplained source, count, provenance, license, or behavior drift blocks the update.

No scheduled updater, build-time fetch, runtime fetch, mutable fallback, or reduced-assurance mode is permitted.

## Removal policy

Removal is a reviewed dependency change, not file cleanup. Before removing or replacing this snapshot, identify and remove or migrate every classifier consumer; update all tests, package and Xcode resource declarations, manifests, notices, and documentation; preserve any license obligations for distributed copies; document the replacement failure behavior and classification change; and obtain independent review. Silent removal, leaving an implicit fallback, or deleting the license while a covered resource remains is forbidden.
