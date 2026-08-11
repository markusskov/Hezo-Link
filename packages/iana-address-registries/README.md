# Pinned IANA address registries

This package freezes the public registry material used by Hezo Link's bounded, offline address classification. The runtime reads only the immutable projection copied into the application bundle. It never downloads registry data, parses the XML snapshots, consults a mutable external file, resolves a host, or makes any other network request.

The profile is `iana-address-profile-v1`, version `iana-2025-10-23-hezo-overlay-v1`. A missing resource, an unexpected profile version, an integrity mismatch, a schema or semantic error, or an unsupported field value makes classification unavailable. There is no permissive fallback and no runtime refresh path.

## Exact upstream snapshots

Each XML file below is a byte-for-byte copy from the named official IANA URL. Only the repository filename adds the registry revision. All files are UTF-8, use LF line endings, and end with one LF.

| Registry | Revision | XML records | Projected records | Bytes | Lines | SHA-256 |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| [IPv4 Special-Purpose Address Space](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xml) | 2025-10-09 | 25 | 26 | 13,459 | 384 | `cf24e11f41b7d42c68debe2d18b97cac815084ec413ebb3b244f704028a16f20` |
| [IPv6 Special-Purpose Address Space](https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xml) | 2025-10-09 | 25 | 25 | 13,431 | 383 | `c17f4380ba84fb2160dae82ebfd8bd155a5853cfab624ed3a9fd251638a8be02` |
| [IPv4 Address Space](https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml) | 2025-10-10 | 256 | 256 | 76,759 | 2,646 | `8ca3774374c81e4a673bb12d0eb415e7ac9970c6f5a6ceb14106de64b2cb3dcd` |
| [IPv6 Address Space](https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml) | 2025-10-23 | 20 | 20 | 6,956 | 154 | `15481d1e549b481f3bd0321c5cd2c0327a00cbd3d5a6fc35fc7b53b51e70b1cb` |

The IPv4 special-purpose XML has one record containing two comma-separated `/32` blocks. The projection expands that record into two prefixes without changing its shared source record index or metadata. No other source record expands to more than one prefix.

The package also preserves exact licensing evidence:

- `upstream/licensing/iana-ietf-protocol-registry-licensing-terms-2021-11-10.html` is the official [joint IANA/IETF protocol-registry licensing statement](https://www.iana.org/help/licensing-terms), 8,375 bytes, 190 lines, SHA-256 `9e9694eb818bcd620f153c208f431e9a0212c7202d35951f5cc3fcfe3720754b`.
- `upstream/licensing/CC0-1.0-legalcode.txt` is the exact [Creative Commons CC0 1.0 legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt), 7,048 bytes, 121 lines, SHA-256 `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499`.

The joint statement is dated 2021-11-10. It identifies the linked technical protocol registries, states that IANA and IETF intend them to be freely usable for any purpose, and subjects any applicable rights they hold to the CC0 1.0 dedication. The statement's qualifications and the full CC0 limitations remain applicable; this package does not extend those terms to linked RFCs or other material.

## Runtime projection

`projection/iana-address-profile-v1.json` and `Sources/HezoLinkCore/Resources/AddressRegistry/iana-address-profile-v1.json` are exact copies. Each is 118,651 bytes and 4,342 lines with SHA-256 `9697f3b6da69ec68fea355c7f6bb0ae95151125fedb8c363e72d1cd7844af0be`.

The projection has 329 records:

- 283 IPv4 records: 26 expanded special-purpose prefixes, all 256 IPv4 `/8` address-space records, and the explicit `224.0.0.0/4` multicast policy overlay;
- 46 IPv6 records: 25 special-purpose prefixes, all 20 IPv6 address-space records, and the explicit `ff00::/8` multicast policy overlay.

The two overlays are project policy derived from [RFC 1112, Section 4](https://www.rfc-editor.org/rfc/rfc1112.html#section-4) and [RFC 4291, Section 2.7](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.7). They are explicit because multicast classification must not depend on whether a special-purpose registry happens to list multicast. The IPv6 overlay deliberately coincides with the IPv6 address-space registry's multicast record; the independent provenance is retained.

For every projected prefix, the file retains the source registry ID, the zero-based XML record index when applicable, address family, prefix length, fixed-width lowercase network bytes in hexadecimal, record name, source status where present, allocation date, termination date, and the five special-purpose flags. Flag values are lossless four-state strings: `true`, `false`, `not-applicable`, or `unspecified`. Address-space and overlay records have `flags: null`.

The projection is deterministic:

1. Parse only the four checked-in XML snapshots in the order declared in the projection.
2. Select records in XML document order and split only comma-separated special-purpose address blocks.
3. Parse each CIDR strictly, require a prefix-aligned network, and encode its complete four- or sixteen-byte network address as lowercase hexadecimal.
4. Normalize record text by XML decoding, trimming its edges, and replacing each internal whitespace run with one ASCII space. Do not infer missing source fields.
5. Map special-purpose flag text exactly: `True` to `true`, `False` to `false`, `N/A` to `not-applicable`, and an absent or empty field to `unspecified`.
6. Add the two reviewed multicast overlays.
7. Sort by address family (`ipv4` before `ipv6`), numeric network bytes, descending prefix length, registry ID, then source record index with a missing overlay index before numeric indexes.
8. Serialize as UTF-8 JSON with two-space indentation, LF line endings, and one final LF.

The Draft 2020-12 schema at `schemas/iana-address-profile-v1.schema.json` is strict: every object rejects unknown properties, tuple metadata is pinned, record types are constrained by registry, byte widths match their family, counts are exact, and overlay records are constants. Schema validation is necessary but not sufficient.

## Classification meaning

Every special-purpose or multicast-overlay match is classified as non-public or special regardless of the source registry's reachability flags. Without such a match, IPv4 `ALLOCATED` and `LEGACY` `/8` records are public-unicast candidates, while `RESERVED` records are not. This snapshot contains 129 `ALLOCATED`, 92 `LEGACY`, and 35 `RESERVED` IPv4 records; it contains no `UNALLOCATED` status. An unknown future status must make the profile unavailable until reviewed.

The IPv6 address-space XML has no status field. Only the exact `Global Unicast` record (`2000::/3`) is a public-unicast candidate. Its other exact names are `Reserved by IETF` (16 records), `Unique Local Unicast`, `Link-Scoped Unicast`, and `Multicast`; those are non-public candidates. An unknown future name must make the profile unavailable until reviewed.

Longest-prefix matching is required because the registries intentionally contain overlapping prefixes. Retired records remain represented with their termination date. A current address match against a terminated special-purpose record is still treated as special by this conservative classification profile.

## Required validation

Before the package or runtime resource is accepted, validation must fail on any of the following:

- invalid JSON, a duplicate JSON object key, a schema compile or validation error in strict Draft 2020-12 mode, an unknown field, or an unrecognized enum value;
- a file missing from the manifest, a manifest path escaping its declared root, an unmanifested package artifact other than `manifest.json`, or a package/runtime projection mismatch;
- an incorrect byte count, SHA-256 digest, UTF-8 decode, LF-only requirement, physical line count, or final newline;
- an XML root or revision mismatch, unexpected source record count, malformed or non-network CIDR, invalid flag token, or unexpected projection expansion;
- a duplicate `(registryId, networkBytesHex, prefixLength)` identity, an out-of-range source index, a nonzero host bit, incorrect deterministic order, or a declared count that differs from a projection of the records;
- drift between the source snapshots and a newly regenerated projection, including names, status, dates, termination, flags, prefix bytes, or source indexes.

Any failure means the classifier is unavailable. Validation must not skip an artifact, weaken a check, fetch a replacement, or silently continue with a partial table.

## Reviewed update procedure

Updates are manual dependency changes, never application behavior.

1. Retrieve each candidate from its exact official HTTPS URL outside the application runtime. Record the retrieval date and compare the XML `<updated>` revision with the current package.
2. Review the upstream diff, registry semantics, policy impact, and licensing evidence. Stop if provenance, rights, completeness, or a new field/status cannot be explained.
3. Preserve source bytes exactly. Do not reserialize XML, normalize Unicode, convert newlines, strip comments, or rewrite the official content.
4. Regenerate the projection from all four reviewed snapshots using the deterministic rules above. Never hand-edit only the runtime copy.
5. Recompute every byte count, line count, record count, and SHA-256 digest; update both strict schemas and the manifest; then prove the package and runtime projections are byte-identical.
6. Run strict schema validation, all companion semantic checks, Swift package tests, Xcode tests, and an independent security/governance review before merge.

There is no automatic updater. A newer registry publication does not invalidate a running pinned build, but adopting it requires this complete review.

## Removal policy

Remove this dependency only in a reviewed change that also removes or replaces every classifier reference, test expectation, package/runtime projection copy, SwiftPM resource declaration, and Xcode resource entry. Verify that no code falls back to a network fetch, platform heuristic, stale cached table, or permissive result. Repository history retains the imported material and its provenance; do not rewrite history to erase attribution. If provenance or rights become uncertain, keep classification unavailable until an approved replacement or complete removal is shipped.

## Nonclaims

This package and its classifications do not establish URL validity, DNS behavior, current allocation within a registry block, destination ownership, reachability, routability in any particular network, redirect safety, transport security, SSRF resistance, provider identity, authorization to connect, or permission for any runtime network operation. A `public-unicast candidate` is only the absence of a denial in this pinned registry profile. Later environment-specific, provider-specific, egress, redirect, and authorization controls remain mandatory.

The package contains no user input, captured traffic, account data, device data, secret, credential, endpoint observation, or operational destination. Registry organizations, servers, and linked references present in the exact upstream XML are public source data and are never contacted by the runtime.
