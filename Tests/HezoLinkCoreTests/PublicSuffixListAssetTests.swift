import CryptoKit
import Foundation
import Testing

@testable import HezoLinkCore

struct PublicSuffixListAssetTests {
  @Test func manifestSchemaPoliciesAndInventoryAreFrozen() throws {
    let manifestData = try pslData(at: pslManifestPath)
    let schemaData = try pslData(at: pslManifestSchemaPath)
    let documentationData = try pslData(at: pslDocumentationPath)
    expectPinnedArtifact(manifestData, expected: expectedManifestArtifact, id: "manifest")
    expectPinnedArtifact(schemaData, expected: expectedManifestSchemaArtifact, id: "schema")
    expectPinnedArtifact(
      documentationData,
      expected: expectedDocumentationArtifact,
      id: "documentation"
    )

    let manifest = try pslJSONObject(manifestData)
    let schema = try pslJSONObject(schemaData)
    try verifyFrozenManifestSchemaSurface(schema)
    let evaluator = try URLPolicyOracleFrozenSchemaEvaluator(schema: schema)
    let manifestValidates = try evaluator.validates(manifest)
    #expect(manifestValidates)

    try verifyFrozenManifestSurface(manifest)
    try verifyManifestPolicies(manifest)
    try verifyManifestArtifactMetadata(manifest)
    #expect(try pslFilesOnDisk() == expectedPSLRepositoryInventory)
  }

  @Test func pinnedUpstreamAssetsHaveExactBytesAndCounts() throws {
    let snapshot = try pslData(at: pslSnapshotPath)
    expectPinnedArtifact(snapshot, expected: expectedSnapshotArtifact, id: "snapshot")

    let summary = try summarizeSnapshot(snapshot)
    #expect(summary.versionMarkerCount == 1)
    #expect(summary.commitMarkerCount == 1)
    #expect(summary.icann == RuleCounts(exact: 6_925, wildcard: 16, exception: 8))
    #expect(summary.privateDomain == RuleCounts(exact: 3_025, wildcard: 265, exception: 0))
    #expect(summary.totalRuleCount == 10_239)
    #expect(summary.blankLineCount == 2_063)
    #expect(summary.commentLineCount == 4_107)
    #expect(summary.nonASCIIPhysicalLineCount == 517)
    #expect(summary.nonASCIIRuleLineCount == 459)
    #expect(summary.nonASCIICommentLineCount == 58)

    let officialTests = try pslData(at: pslOfficialTestsPath)
    expectPinnedArtifact(officialTests, expected: expectedOfficialTestsArtifact, id: "tests")
    let corpus = try parseOfficialCorpus(officialTests)
    #expect(corpus.cases.count == 78)
    #expect(corpus.nullExpectedCount == 26)
    #expect(corpus.nonNullExpectedCount == 52)
    #expect(corpus.commentLineCount == 19)
    #expect(corpus.blankLineCount == 1)
    #expect(corpus.unicodeContainingCaseCount == 9)
  }

  @Test func bundledRuntimeResourceAndLicenseHaveExactPinnedBytes() throws {
    let sourceSnapshot = try pslData(at: pslSnapshotPath)
    let bundledSnapshot = try RegistrableDomainClassifier.bundledSnapshotDataForTesting()
    #expect(pslBytesAreEqual(sourceSnapshot, bundledSnapshot))
    expectPinnedArtifact(bundledSnapshot, expected: expectedSnapshotArtifact, id: "bundle")

    let runtimeLicense = try pslData(at: pslLicensePath)
    expectPinnedArtifact(runtimeLicense, expected: expectedLicenseArtifact, id: "license")
  }

  @Test func officialCorpusMatchesTheRuntimeClassifier() throws {
    let classifier = try RegistrableDomainClassifier()
    let corpus = try parseOfficialCorpus(pslData(at: pslOfficialTestsPath))
    var executedCaseCount = 0
    var skippedInvalidCaseCount = 0

    for testCase in corpus.cases {
      guard let domain = testCase.domain, domain.hasPrefix(".") == false else {
        if testCase.expectedRegistrableDomain != nil {
          Issue.record("Official PSL case \(testCase.safeID) has an invalid skip expectation.")
        }
        skippedInvalidCaseCount += 1
        continue
      }

      guard let asciiHost = pslNormalizedASCIIHost(domain) else {
        Issue.record("Official PSL case \(testCase.safeID) could not be normalized.")
        continue
      }
      let expectedASCII = testCase.expectedRegistrableDomain.flatMap(pslNormalizedASCIIHost)
      if testCase.expectedRegistrableDomain != nil, expectedASCII == nil {
        Issue.record("Official PSL case \(testCase.safeID) has an invalid expected value.")
        continue
      }

      let classification = classifier.classifyASCIIHostForTesting(asciiHost)
      guard case .classified(let result) = classification else {
        Issue.record("Official PSL case \(testCase.safeID) was not classified.")
        continue
      }
      let matchesExpected = pslOptionalStringsAreEqual(
        result.registrableDomainASCII,
        expectedASCII
      )
      if matchesExpected == false {
        Issue.record("Official PSL case \(testCase.safeID) produced the wrong result.")
      }
      executedCaseCount += 1
    }

    #expect(executedCaseCount == 73)
    #expect(skippedInvalidCaseCount == 5)
  }

  @Test func strictJSONReaderRejectsEscapeEquivalentDuplicateKeys() {
    let duplicateKeyDocument = Data(
      #"{"manifestId":1,"\u006danifestId":2}"#.utf8
    )
    var validator = StrictJSONDocument(data: duplicateKeyDocument)
    do {
      try validator.validate()
      Issue.record("The strict JSON reader accepted a duplicate key.")
    } catch PublicSuffixListAssetTestError.duplicateJSONKey {
      // Expected: escaped and literal spellings decode to the same object key.
    } catch {
      Issue.record("The strict JSON reader reported the wrong bounded failure.")
    }
  }
}

private struct PinnedArtifact: Sendable {
  let byteCount: Int
  let sha256: String
  let physicalLineCount: Int
}

private struct RuleCounts: Equatable, Sendable {
  var exact: Int
  var wildcard: Int
  var exception: Int

  var total: Int {
    exact + wildcard + exception
  }
}

private struct SnapshotSummary: Sendable {
  let versionMarkerCount: Int
  let commitMarkerCount: Int
  let icann: RuleCounts
  let privateDomain: RuleCounts
  let blankLineCount: Int
  let commentLineCount: Int
  let nonASCIIPhysicalLineCount: Int
  let nonASCIIRuleLineCount: Int
  let nonASCIICommentLineCount: Int

  var totalRuleCount: Int {
    icann.total + privateDomain.total
  }
}

private struct OfficialCorpusCase: Sendable {
  let safeID: String
  let domain: String?
  let expectedRegistrableDomain: String?
}

private struct OfficialCorpus: Sendable {
  let cases: [OfficialCorpusCase]
  let commentLineCount: Int
  let blankLineCount: Int

  var nullExpectedCount: Int {
    cases.count { $0.expectedRegistrableDomain == nil }
  }

  var nonNullExpectedCount: Int {
    cases.count - nullExpectedCount
  }

  var unicodeContainingCaseCount: Int {
    cases.count { testCase in
      testCase.domain?.utf8.contains(where: { $0 >= 0x80 }) == true
        || testCase.expectedRegistrableDomain?.utf8.contains(where: { $0 >= 0x80 }) == true
    }
  }
}

private enum SnapshotSection {
  case icann
  case privateDomain
}

private enum OfficialCorpusToken {
  case null
  case string(String)

  var value: String? {
    switch self {
    case .null:
      nil
    case .string(let value):
      value
    }
  }
}

private enum PublicSuffixListAssetTestError: Error {
  case unreadableArtifact
  case duplicateJSONKey
  case invalidJSON
  case invalidManifest
  case invalidSnapshot
  case invalidOfficialCorpus
}

private let pslRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let pslSnapshotPath =
  "Sources/HezoLinkCore/Resources/PublicSuffix/hezolink-public-suffix-list-e1b8015c.dat"
private let pslOfficialTestsPath =
  "packages/public-suffix-list/upstream/test_psl-e1b8015c.txt"
private let pslLicensePath =
  "Sources/HezoLinkCore/Resources/PublicSuffix/LICENSE-MPL-2.0.txt"
private let pslManifestPath = "packages/public-suffix-list/manifest.json"
private let pslManifestSchemaPath = "packages/public-suffix-list/manifest.schema.json"
private let pslDocumentationPath = "packages/public-suffix-list/README.md"

private let expectedPSLVersion = "2026-07-25_14-20-03_UTC"
private let expectedPSLCommit = "e1b8015c3b2f0f4f8c18659c2480fc1a22c07b20"

private let expectedSnapshotArtifact = PinnedArtifact(
  byteCount: 332_855,
  sha256: "084a5674d77c1d14900b16da5fc8afee9765af2f00a638552a8c7aa18f44ae81",
  physicalLineCount: 16_409
)

private let expectedOfficialTestsArtifact = PinnedArtifact(
  byteCount: 4_308,
  sha256: "8f50ad958916d6a8f79fba2363501475571acce752757f9126fe9d2f17dd920d",
  physicalLineCount: 98
)

private let expectedLicenseArtifact = PinnedArtifact(
  byteCount: 16_727,
  sha256: "66a3107d5ad6a058aab753eaac2047ccb2ed0e39465dd0fe5844da3e300d5172",
  physicalLineCount: 373
)

private let expectedManifestArtifact = PinnedArtifact(
  byteCount: 12_936,
  sha256: "8a0f954e6b958c736fe6cf9ecb4503f192f8c35e1d74fd36d1e3a36c685c8d73",
  physicalLineCount: 327
)

private let expectedManifestSchemaArtifact = PinnedArtifact(
  byteCount: 17_093,
  sha256: "567cab5ed3900c581daa21b3ab334cb4bf3e1a6bea11b4348b852500214b3d5a",
  physicalLineCount: 456
)

private let expectedDocumentationArtifact = PinnedArtifact(
  byteCount: 7_812,
  sha256: "e286a00db13705d6f5151c5b030465c0ebf170276c6baa9757aa01950d3d079f",
  physicalLineCount: 55
)

private let expectedManifestKeysInOrder = [
  "$schema", "schemaVersion", "manifestId", "purpose", "dependencyReview",
  "sourceSnapshot", "validationRequirements", "artifacts", "listCounts",
  "contentRetention", "usePolicy", "updatePolicy", "removalPolicy",
]

private let expectedArtifactKeys: Set<String> = [
  "manifest", "runtimeList", "runtimeLicense", "upstreamTestCorpus",
  "manifestSchema", "packageDocumentation",
]

private let expectedFileKeys: Set<String> = [
  "repositoryPath", "mediaType", "encoding", "byteCount", "sha256",
  "lineEnding", "physicalLineCount", "finalNewline",
]

private let expectedPSLRepositoryInventory: Set<String> = [
  pslManifestPath,
  pslManifestSchemaPath,
  pslDocumentationPath,
  pslOfficialTestsPath,
  pslSnapshotPath,
  pslLicensePath,
]

private let pslBeginICANNMarker = "// ===BEGIN ICANN DOMAINS==="
private let pslEndICANNMarker = "// ===END ICANN DOMAINS==="
private let pslBeginPrivateMarker = "// ===BEGIN PRIVATE DOMAINS==="
private let pslEndPrivateMarker = "// ===END PRIVATE DOMAINS==="

private func pslData(at relativePath: String) throws -> Data {
  let url = pslRepositoryRoot.appendingPathComponent(relativePath).standardizedFileURL
  guard url.path.hasPrefix(pslRepositoryRoot.path + "/") else {
    throw PublicSuffixListAssetTestError.unreadableArtifact
  }
  do {
    return try Data(contentsOf: url)
  } catch {
    throw PublicSuffixListAssetTestError.unreadableArtifact
  }
}

private func pslJSONObject(_ data: Data) throws -> [String: Any] {
  var validator = StrictJSONDocument(data: data)
  try validator.validate()
  do {
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    return object
  } catch let error as PublicSuffixListAssetTestError {
    throw error
  } catch {
    throw PublicSuffixListAssetTestError.invalidJSON
  }
}

private func verifyFrozenManifestSchemaSurface(_ schema: [String: Any]) throws {
  let expectedTopLevelKeys: Set<String> = [
    "$schema", "$id", "title", "description", "type", "additionalProperties",
    "required", "properties", "$defs",
  ]
  #expect(Set(schema.keys) == expectedTopLevelKeys)
  #expect(
    try pslRequireString(schema["$schema"])
      == "https://json-schema.org/draft/2020-12/schema"
  )
  #expect(
    try pslRequireString(schema["$id"])
      == "urn:hezo-link:public-suffix-list:manifest:e1b8015c:v1"
  )
  #expect(try pslRequireString(schema["type"]) == "object")
  #expect(try pslRequireBool(schema["additionalProperties"]) == false)
  #expect(try pslRequireStringArray(schema["required"]) == expectedManifestKeysInOrder)

  let properties = try pslRequireObject(schema["properties"])
  #expect(Set(properties.keys) == Set(expectedManifestKeysInOrder))
  let definitions = try pslRequireObject(schema["$defs"])
  #expect(Set(definitions.keys) == ["manifestSchemaFile"])
}

private func verifyFrozenManifestSurface(_ manifest: [String: Any]) throws {
  #expect(Set(manifest.keys) == Set(expectedManifestKeysInOrder))
  #expect(try pslRequireString(manifest["$schema"]) == "./manifest.schema.json")
  #expect(try pslRequireInt(manifest["schemaVersion"]) == 1)
  #expect(
    try pslRequireString(manifest["manifestId"])
      == "hezo-public-suffix-list-e1b8015c-v1"
  )
  #expect(
    try pslRequireString(manifest["purpose"])
      == "offline-public-suffix-and-registrable-domain-boundary-classification-only"
  )

  let source = try pslRequireObject(manifest["sourceSnapshot"])
  #expect(
    Set(source.keys)
      == [
        "publisher", "projectURL", "officialDistributionURL", "repositoryURL",
        "revisionType", "revision", "shortRevision", "version", "versionMarker",
        "commitMarker", "provenanceBasis",
      ]
  )
  #expect(try pslRequireString(source["revision"]) == expectedPSLCommit)
  #expect(try pslRequireString(source["shortRevision"]) == "e1b8015c")
  #expect(try pslRequireString(source["version"]) == expectedPSLVersion)
  #expect(
    try pslRequireString(source["versionMarker"])
      == "// VERSION: \(expectedPSLVersion)"
  )
  #expect(
    try pslRequireString(source["commitMarker"])
      == "// COMMIT: \(expectedPSLCommit)"
  )

  let artifacts = try pslRequireObject(manifest["artifacts"])
  #expect(Set(artifacts.keys) == expectedArtifactKeys)
  let manifestArtifact = try pslRequireObject(artifacts["manifest"])
  #expect(
    Set(manifestArtifact.keys)
      == ["role", "repositoryPath", "selfDigestRecorded", "selfDigestPolicy"]
  )
  #expect(try pslRequireString(manifestArtifact["role"]) == "manifest")
  #expect(try pslRequireString(manifestArtifact["repositoryPath"]) == pslManifestPath)
  #expect(try pslRequireBool(manifestArtifact["selfDigestRecorded"]) == false)

  try verifyManifestCounts(manifest)
}

private func verifyManifestCounts(_ manifest: [String: Any]) throws {
  let counts = try pslRequireObject(manifest["listCounts"])
  #expect(
    Set(counts.keys)
      == [
        "blankLineCount", "commentLineCount", "ruleLineCount",
        "unicodeContainingPhysicalLineCount", "unicodeContainingRuleLineCount",
        "unicodeContainingCommentLineCount", "icann", "private", "total",
      ]
  )
  #expect(try pslRequireInt(counts["blankLineCount"]) == 2_063)
  #expect(try pslRequireInt(counts["commentLineCount"]) == 4_107)
  #expect(try pslRequireInt(counts["ruleLineCount"]) == 10_239)
  #expect(try pslRequireInt(counts["unicodeContainingPhysicalLineCount"]) == 517)
  #expect(try pslRequireInt(counts["unicodeContainingRuleLineCount"]) == 459)
  #expect(try pslRequireInt(counts["unicodeContainingCommentLineCount"]) == 58)

  try verifyManifestRuleCounts(
    try pslRequireObject(counts["icann"]),
    expected: RuleCounts(exact: 6_925, wildcard: 16, exception: 8)
  )
  try verifyManifestRuleCounts(
    try pslRequireObject(counts["private"]),
    expected: RuleCounts(exact: 3_025, wildcard: 265, exception: 0)
  )
  try verifyManifestRuleCounts(
    try pslRequireObject(counts["total"]),
    expected: RuleCounts(exact: 9_950, wildcard: 281, exception: 8)
  )
}

private func verifyManifestRuleCounts(
  _ object: [String: Any],
  expected: RuleCounts
) throws {
  #expect(
    Set(object.keys)
      == ["exactRuleCount", "wildcardRuleCount", "exceptionRuleCount", "totalRuleCount"]
  )
  #expect(try pslRequireInt(object["exactRuleCount"]) == expected.exact)
  #expect(try pslRequireInt(object["wildcardRuleCount"]) == expected.wildcard)
  #expect(try pslRequireInt(object["exceptionRuleCount"]) == expected.exception)
  #expect(try pslRequireInt(object["totalRuleCount"]) == expected.total)
}

private func verifyManifestPolicies(_ manifest: [String: Any]) throws {
  let validation = try pslRequireObject(manifest["validationRequirements"])
  #expect(
    Set(validation.keys)
      == [
        "jsonSchemaDialect", "strictSchemaModeRequired", "digestVerificationRequired",
        "byteCountVerificationRequired", "countVerificationRequired", "utf8Required",
        "lfLineEndingsRequired", "finalNewlineRequired",
        "repositoryRelativePathVerificationRequired", "wrapperMarkerVerificationRequired",
        "sectionBoundaryVerificationRequired", "unmanifestedArtifactUsePermitted",
        "companionSemanticValidationRequired", "companionSemanticChecks",
      ]
  )
  #expect(
    try pslRequireString(validation["jsonSchemaDialect"])
      == "https://json-schema.org/draft/2020-12/schema"
  )
  #expect(
    try pslFieldsAreTrue(
      validation,
      names: [
        "strictSchemaModeRequired", "digestVerificationRequired",
        "byteCountVerificationRequired", "countVerificationRequired", "utf8Required",
        "lfLineEndingsRequired", "finalNewlineRequired",
        "repositoryRelativePathVerificationRequired", "wrapperMarkerVerificationRequired",
        "sectionBoundaryVerificationRequired", "companionSemanticValidationRequired",
      ]
    )
  )
  #expect(try pslRequireBool(validation["unmanifestedArtifactUsePermitted"]) == false)
  #expect(
    try pslRequireStringArray(validation["companionSemanticChecks"])
      == [
        "repository-path-confinement-and-inventory",
        "sha256-byte-and-physical-line-counts",
        "utf8-lf-only-and-final-newline",
        "exact-version-and-commit-markers",
        "single-ordered-icann-and-private-section-boundaries",
        "declared-vs-projected-exact-wildcard-exception-counts",
        "declared-vs-projected-unicode-containing-line-counts",
        "upstream-test-corpus-counts",
        "provenance-license-and-transformation-coherence",
      ]
  )

  let dependency = try pslRequireObject(manifest["dependencyReview"])
  #expect(
    Set(dependency.keys)
      == [
        "dependencyKind", "runtimeCodeDependencyAdded", "runtimeResourceAccess",
        "networkAccessPermitted", "dnsAccessPermitted", "externalDataAccessPermitted",
        "persistentDataAccessPermitted", "providerAccessPermitted",
        "telemetryAccessPermitted", "capturedOrUserDataAccessPermitted",
        "runtimeLicenseSpdx", "updatePolicy", "failureBehavior", "removalPolicy",
      ]
  )
  #expect(try pslRequireString(dependency["dependencyKind"]) == "vendored-public-data")
  #expect(
    try pslRequireString(dependency["runtimeResourceAccess"])
      == "read-only-bundled-snapshot"
  )
  #expect(try pslRequireString(dependency["runtimeLicenseSpdx"]) == "MPL-2.0")
  #expect(try pslRequireString(dependency["updatePolicy"]) == "reviewed-manual-only")
  #expect(
    try pslRequireString(dependency["failureBehavior"])
      == "fail-closed-classifier-unavailable"
  )
  #expect(
    try pslRequireString(dependency["removalPolicy"])
      == "reviewed-manual-coordinated-removal-only"
  )
  #expect(
    try pslFieldsAreFalse(
      dependency,
      names: [
        "runtimeCodeDependencyAdded", "networkAccessPermitted", "dnsAccessPermitted",
        "externalDataAccessPermitted", "persistentDataAccessPermitted",
        "providerAccessPermitted", "telemetryAccessPermitted",
        "capturedOrUserDataAccessPermitted",
      ]
    )
  )

  let retention = try pslRequireObject(manifest["contentRetention"])
  #expect(
    Set(retention.keys)
      == [
        "runtimeSnapshotMode", "upstreamTestCorpusMode", "retainUpstreamCommentsVerbatim",
        "retainPublicNamesVerbatim", "retainPublicEmailAddressesVerbatim",
        "redactionPermitted", "unicodeNormalizationPermitted", "newlineConversionPermitted",
        "rationale",
      ]
  )
  #expect(
    try pslFieldsAreTrue(
      retention,
      names: [
        "retainUpstreamCommentsVerbatim", "retainPublicNamesVerbatim",
        "retainPublicEmailAddressesVerbatim",
      ]
    )
  )
  #expect(
    try pslRequireString(retention["runtimeSnapshotMode"]) == "verbatim-byte-for-byte"
  )
  #expect(
    try pslRequireString(retention["upstreamTestCorpusMode"]) == "verbatim-byte-for-byte"
  )
  #expect(
    try pslFieldsAreFalse(
      retention,
      names: ["redactionPermitted", "unicodeNormalizationPermitted", "newlineConversionPermitted"]
    )
  )

  let usePolicy = try pslRequireObject(manifest["usePolicy"])
  #expect(
    Set(usePolicy.keys)
      == [
        "classificationOnly", "allowedUse", "officialWarningURL", "staticSnapshotWarning",
        "domainValidityClaimPermitted", "dnsExistenceClaimPermitted",
        "reachabilityClaimPermitted", "destinationSafetyClaimPermitted",
        "domainOwnershipClaimPermitted", "affiliationClaimPermitted",
        "authorizationClaimPermitted", "enforcementClaimPermitted", "verdictClaimPermitted",
        "userInterfaceClaimPermitted", "networkResolutionOrNavigationPermitted",
        "operationalHostDataIncluded",
      ]
  )
  #expect(try pslRequireBool(usePolicy["classificationOnly"]))
  #expect(
    try pslRequireString(usePolicy["allowedUse"])
      == "public-suffix-and-registrable-domain-boundary-classification"
  )
  #expect(
    try pslRequireString(usePolicy["staticSnapshotWarning"])
      == "must-not-be-used-as-a-domain-validity-or-dns-existence-authority"
  )
  #expect(
    try pslRequireString(usePolicy["officialWarningURL"]) == "https://publicsuffix.org/learn/")
  #expect(
    try pslFieldsAreFalse(
      usePolicy,
      names: [
        "domainValidityClaimPermitted", "dnsExistenceClaimPermitted",
        "reachabilityClaimPermitted", "destinationSafetyClaimPermitted",
        "domainOwnershipClaimPermitted", "affiliationClaimPermitted",
        "authorizationClaimPermitted", "enforcementClaimPermitted", "verdictClaimPermitted",
        "userInterfaceClaimPermitted", "networkResolutionOrNavigationPermitted",
        "operationalHostDataIncluded",
      ]
    )
  )

  let update = try pslRequireObject(manifest["updatePolicy"])
  #expect(
    Set(update.keys)
      == [
        "mode", "automaticUpdatePermitted", "scheduledUpdatePermitted",
        "buildTimeFetchPermitted", "runtimeFetchPermitted", "mutableFallbackPermitted",
        "independentReviewRequired", "requiredSteps",
      ]
  )
  #expect(try pslRequireString(update["mode"]) == "reviewed-manual-only")
  #expect(
    try pslFieldsAreFalse(
      update,
      names: [
        "automaticUpdatePermitted", "scheduledUpdatePermitted", "buildTimeFetchPermitted",
        "runtimeFetchPermitted", "mutableFallbackPermitted",
      ]
    )
  )
  #expect(try pslRequireBool(update["independentReviewRequired"]))
  #expect(
    try pslRequireStringArray(update["requiredSteps"])
      == [
        "obtain-candidate-only-from-official-publicsuffix-org-list-url",
        "pin-and-verify-embedded-full-commit-and-version",
        "obtain-test-corpus-and-license-at-the-same-immutable-commit",
        "review-source-diff-semantics-public-notices-and-license",
        "copy-bytes-without-content-redaction-normalization-or-reformatting",
        "verify-utf8-lf-final-newline-digests-bytes-markers-and-all-counts",
        "replace-runtime-list-license-test-corpus-manifest-schema-docs-and-tests-together",
        "run-strict-schema-companion-integrity-and-offline-tests",
        "inspect-complete-diff-and-obtain-independent-review",
      ]
  )

  let removal = try pslRequireObject(manifest["removalPolicy"])
  #expect(
    Set(removal.keys)
      == [
        "mode", "silentRemovalPermitted", "implicitFallbackPermitted",
        "independentReviewRequired", "requiredSteps",
      ]
  )
  #expect(
    try pslRequireString(removal["mode"])
      == "reviewed-manual-coordinated-removal-only"
  )
  #expect(
    try pslFieldsAreFalse(
      removal,
      names: ["silentRemovalPermitted", "implicitFallbackPermitted"]
    )
  )
  #expect(try pslRequireBool(removal["independentReviewRequired"]))
  #expect(
    try pslRequireStringArray(removal["requiredSteps"])
      == [
        "identify-remove-or-migrate-every-classifier-consumer",
        "update-tests-package-and-xcode-resource-declarations-manifests-notices-and-documentation",
        "preserve-license-obligations-for-distributed-copies",
        "document-replacement-classification-and-failure-behavior",
        "remove-covered-resource-and-license-binding-coherently",
        "verify-no-implicit-platform-network-or-stale-copy-fallback-remains",
      ]
  )
}

private func verifyManifestArtifactMetadata(_ manifest: [String: Any]) throws {
  let artifacts = try pslRequireObject(manifest["artifacts"])
  let expectedArtifacts: [(String, String, String, String, PinnedArtifact)] = [
    (
      "runtimeList", "runtime-public-suffix-list", pslSnapshotPath, "text/plain",
      expectedSnapshotArtifact
    ),
    (
      "runtimeLicense", "runtime-list-license-text", pslLicensePath, "text/plain",
      expectedLicenseArtifact
    ),
    (
      "upstreamTestCorpus", "upstream-public-suffix-test-corpus", pslOfficialTestsPath,
      "text/plain", expectedOfficialTestsArtifact
    ),
    (
      "manifestSchema", "manifest-schema", pslManifestSchemaPath,
      "application/schema+json", expectedManifestSchemaArtifact
    ),
    (
      "packageDocumentation", "package-documentation", pslDocumentationPath,
      "text/markdown", expectedDocumentationArtifact
    ),
  ]

  var declaredPaths: Set<String> = [pslManifestPath]
  for (key, expectedRole, expectedPath, expectedMediaType, expectedArtifact) in expectedArtifacts {
    let entry = try pslRequireObject(artifacts[key])
    #expect(try pslRequireString(entry["role"]) == expectedRole)
    let file = try pslRequireObject(entry["file"])
    #expect(Set(file.keys) == expectedFileKeys)
    #expect(try pslRequireString(file["repositoryPath"]) == expectedPath)
    #expect(try pslRequireString(file["mediaType"]) == expectedMediaType)
    #expect(try pslRequireString(file["encoding"]) == "UTF-8")
    #expect(try pslRequireInt(file["byteCount"]) == expectedArtifact.byteCount)
    #expect(try pslRequireString(file["sha256"]) == expectedArtifact.sha256)
    #expect(try pslRequireString(file["lineEnding"]) == "LF")
    #expect(
      try pslRequireInt(file["physicalLineCount"]) == expectedArtifact.physicalLineCount
    )
    #expect(try pslRequireBool(file["finalNewline"]))
    declaredPaths.insert(expectedPath)
    expectPinnedArtifact(
      try pslData(at: expectedPath),
      expected: expectedArtifact,
      id: key
    )
  }
  #expect(declaredPaths == expectedPSLRepositoryInventory)

  let runtimeList = try pslRequireObject(artifacts["runtimeList"])
  let listLicense = try pslRequireObject(runtimeList["license"])
  #expect(try pslRequireString(listLicense["spdxIdentifier"]) == "MPL-2.0")
  #expect(
    try pslRequireString(listLicense["licenseRepositoryPath"]) == pslLicensePath
  )

  let runtimeLicense = try pslRequireObject(artifacts["runtimeLicense"])
  let licenseDeclaration = try pslRequireObject(runtimeLicense["license"])
  #expect(try pslRequireString(licenseDeclaration["spdxIdentifier"]) == "MPL-2.0")
  #expect(try pslRequireBool(licenseDeclaration["artifactIsLicenseText"]))

  let upstreamTests = try pslRequireObject(artifacts["upstreamTestCorpus"])
  let testLicense = try pslRequireObject(upstreamTests["license"])
  #expect(try pslRequireString(testLicense["spdxIdentifier"]) == "CC0-1.0")
  #expect(
    try pslRequireString(testLicense["licenseNoticeLocation"])
      == "embedded-first-two-comment-lines"
  )

  for key in ["manifestSchema", "packageDocumentation"] {
    let projectArtifact = try pslRequireObject(artifacts[key])
    let projectLicense = try pslRequireObject(projectArtifact["license"])
    #expect(
      try pslRequireString(projectLicense["status"])
        == "project-license-not-yet-selected"
    )
  }

  try verifyManifestSourceAndTransformationCoherence(artifacts)
}

private func verifyManifestSourceAndTransformationCoherence(
  _ artifacts: [String: Any]
) throws {
  for key in ["runtimeList", "runtimeLicense", "upstreamTestCorpus"] {
    let artifact = try pslRequireObject(artifacts[key])
    let source = try pslRequireObject(artifact["source"])
    #expect(try pslRequireString(source["publisher"]) == "Public Suffix List project")
    #expect(try pslRequireString(source["revision"]) == expectedPSLCommit)
    let transformations = try pslRequireObjectArray(artifact["transformations"])
    #expect(transformations.count == 2)
    #expect(
      try transformations.allSatisfy { transformation in
        try pslRequireBool(transformation["contentChanged"]) == false
      }
    )
    #expect(
      try transformations.map { try pslRequireString($0["operation"]) }
        == ["byte-for-byte-copy", "repository-path-rename-only"]
    )
  }

  let runtimeList = try pslRequireObject(artifacts["runtimeList"])
  let runtimeListSource = try pslRequireObject(runtimeList["source"])
  #expect(try pslRequireString(runtimeListSource["version"]) == expectedPSLVersion)

  for key in ["manifestSchema", "packageDocumentation"] {
    let artifact = try pslRequireObject(artifacts[key])
    let source = try pslRequireObject(artifact["source"])
    #expect(try pslRequireString(source["publisher"]) == "Hezo Link project")
    #expect(try pslRequireString(source["sourceType"]) == "project-authored")
    let transformations = try pslRequireObjectArray(artifact["transformations"])
    #expect(transformations.count == 1)
    let transformation = try pslRequireObject(transformations.first)
    #expect(try pslRequireString(transformation["operation"]) == "project-authored")
    #expect(try pslRequireBool(transformation["contentChanged"]))
  }
}

private func pslFilesOnDisk() throws -> Set<String> {
  let roots = [
    "packages/public-suffix-list",
    "Sources/HezoLinkCore/Resources/PublicSuffix",
  ]
  var paths = Set<String>()
  let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey]

  for relativeRoot in roots {
    let root = pslRepositoryRoot.appendingPathComponent(relativeRoot).standardizedFileURL
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: keys
      )
    else {
      throw PublicSuffixListAssetTestError.unreadableArtifact
    }
    for case let url as URL in enumerator {
      let values = try url.resourceValues(forKeys: Set(keys))
      guard values.isSymbolicLink != true else {
        throw PublicSuffixListAssetTestError.invalidManifest
      }
      guard values.isRegularFile == true else {
        continue
      }
      let standardized = url.standardizedFileURL
      guard standardized.path.hasPrefix(pslRepositoryRoot.path + "/") else {
        throw PublicSuffixListAssetTestError.invalidManifest
      }
      paths.insert(String(standardized.path.dropFirst(pslRepositoryRoot.path.count + 1)))
    }
  }
  return paths
}

private func pslRequireObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return object
}

private func pslRequireString(_ value: Any?) throws -> String {
  guard let string = value as? String else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return string
}

private func pslRequireStringArray(_ value: Any?) throws -> [String] {
  guard let strings = value as? [String] else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return strings
}

private func pslRequireObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let objects = value as? [[String: Any]] else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return objects
}

private func pslRequireBool(_ value: Any?) throws -> Bool {
  guard let bool = value as? Bool else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return bool
}

private func pslRequireInt(_ value: Any?) throws -> Int {
  guard let integer = value as? Int else {
    throw PublicSuffixListAssetTestError.invalidManifest
  }
  return integer
}

private func pslFieldsAreFalse(_ object: [String: Any], names: [String]) throws -> Bool {
  try names.allSatisfy { try pslRequireBool(object[$0]) == false }
}

private func pslFieldsAreTrue(_ object: [String: Any], names: [String]) throws -> Bool {
  try names.allSatisfy { try pslRequireBool(object[$0]) }
}

private struct StrictJSONDocument {
  private let bytes: [UInt8]
  private var index = 0

  init(data: Data) {
    bytes = Array(data)
  }

  mutating func validate() throws {
    skipWhitespace()
    try parseValue()
    skipWhitespace()
    guard index == bytes.count else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
  }

  private mutating func parseValue() throws {
    guard let byte = currentByte else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    switch byte {
    case 0x7B:
      try parseObject()
    case 0x5B:
      try parseArray()
    case 0x22:
      _ = try parseString()
    case 0x74:
      try parseLiteral([0x74, 0x72, 0x75, 0x65])
    case 0x66:
      try parseLiteral([0x66, 0x61, 0x6C, 0x73, 0x65])
    case 0x6E:
      try parseLiteral([0x6E, 0x75, 0x6C, 0x6C])
    case 0x2D, 0x30...0x39:
      try parseNumber()
    default:
      throw PublicSuffixListAssetTestError.invalidJSON
    }
  }

  private mutating func parseObject() throws {
    guard consume(0x7B) else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    skipWhitespace()
    if consume(0x7D) {
      return
    }

    var keys = Set<String>()
    while true {
      let key = try parseString()
      guard keys.insert(key).inserted else {
        throw PublicSuffixListAssetTestError.duplicateJSONKey
      }
      skipWhitespace()
      guard consume(0x3A) else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      skipWhitespace()
      try parseValue()
      skipWhitespace()
      if consume(0x7D) {
        return
      }
      guard consume(0x2C) else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      skipWhitespace()
    }
  }

  private mutating func parseArray() throws {
    guard consume(0x5B) else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    skipWhitespace()
    if consume(0x5D) {
      return
    }
    while true {
      try parseValue()
      skipWhitespace()
      if consume(0x5D) {
        return
      }
      guard consume(0x2C) else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      skipWhitespace()
    }
  }

  private mutating func parseString() throws -> String {
    let start = index
    guard consume(0x22) else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    while let byte = currentByte {
      switch byte {
      case 0x00...0x1F:
        throw PublicSuffixListAssetTestError.invalidJSON
      case 0x22:
        index += 1
        let encoded = Data(bytes[start..<index])
        do {
          return try JSONDecoder().decode(String.self, from: encoded)
        } catch {
          throw PublicSuffixListAssetTestError.invalidJSON
        }
      case 0x5C:
        index += 1
        guard let escape = currentByte else {
          throw PublicSuffixListAssetTestError.invalidJSON
        }
        if escape == 0x75 {
          index += 1
          for _ in 0..<4 {
            guard let scalar = currentByte, pslIsASCIIHexDigit(scalar) else {
              throw PublicSuffixListAssetTestError.invalidJSON
            }
            index += 1
          }
        } else {
          guard [0x22, 0x5C, 0x2F, 0x62, 0x66, 0x6E, 0x72, 0x74].contains(escape)
          else {
            throw PublicSuffixListAssetTestError.invalidJSON
          }
          index += 1
        }
      default:
        index += 1
      }
    }
    throw PublicSuffixListAssetTestError.invalidJSON
  }

  private mutating func parseLiteral(_ literal: [UInt8]) throws {
    guard index + literal.count <= bytes.count,
      Array(bytes[index..<(index + literal.count)]) == literal
    else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    index += literal.count
  }

  private mutating func parseNumber() throws {
    _ = consume(0x2D)
    guard let first = currentByte else {
      throw PublicSuffixListAssetTestError.invalidJSON
    }
    if first == 0x30 {
      index += 1
      if let next = currentByte, (0x30...0x39).contains(next) {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
    } else {
      guard (0x31...0x39).contains(first) else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      consumeDigits()
    }

    if consume(0x2E) {
      guard let firstFractionDigit = currentByte,
        (0x30...0x39).contains(firstFractionDigit)
      else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      consumeDigits()
    }

    if currentByte == 0x65 || currentByte == 0x45 {
      index += 1
      if currentByte == 0x2B || currentByte == 0x2D {
        index += 1
      }
      guard let firstExponentDigit = currentByte,
        (0x30...0x39).contains(firstExponentDigit)
      else {
        throw PublicSuffixListAssetTestError.invalidJSON
      }
      consumeDigits()
    }
  }

  private mutating func consumeDigits() {
    while let byte = currentByte, (0x30...0x39).contains(byte) {
      index += 1
    }
  }

  private mutating func skipWhitespace() {
    while let byte = currentByte, [0x20, 0x09, 0x0A, 0x0D].contains(byte) {
      index += 1
    }
  }

  private mutating func consume(_ byte: UInt8) -> Bool {
    guard currentByte == byte else {
      return false
    }
    index += 1
    return true
  }

  private var currentByte: UInt8? {
    index < bytes.count ? bytes[index] : nil
  }
}

private func pslIsASCIIHexDigit(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
    || (0x61...0x66).contains(byte)
}

private func expectPinnedArtifact(
  _ data: Data,
  expected: PinnedArtifact,
  id: String
) {
  #expect(data.count == expected.byteCount, "Pinned \(id) byte count drifted.")
  #expect(pslSHA256Hex(data) == expected.sha256, "Pinned \(id) digest drifted.")
  #expect(
    data.reduce(into: 0) { count, byte in
      if byte == 0x0A { count += 1 }
    } == expected.physicalLineCount,
    "Pinned \(id) line count drifted."
  )
  #expect(data.contains(0x0D) == false, "Pinned \(id) is not LF-only.")
  #expect(data.last == 0x0A, "Pinned \(id) lost its final newline.")
  #expect(String(data: data, encoding: .utf8) != nil, "Pinned \(id) is not UTF-8.")
}

private func pslSHA256Hex(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func pslBytesAreEqual(_ lhs: Data, _ rhs: Data) -> Bool {
  lhs == rhs
}

private func summarizeSnapshot(_ data: Data) throws -> SnapshotSummary {
  let lines = try pslPhysicalLines(in: data, error: .invalidSnapshot)
  var currentSection: SnapshotSection?
  var icann = RuleCounts(exact: 0, wildcard: 0, exception: 0)
  var privateDomain = RuleCounts(exact: 0, wildcard: 0, exception: 0)
  var seenRules = Set<String>()
  var markerSequence = [String]()
  var blankLineCount = 0
  var commentLineCount = 0
  var nonASCIIPhysicalLineCount = 0
  var nonASCIIRuleLineCount = 0
  var nonASCIICommentLineCount = 0

  for line in lines {
    let containsNonASCII = line.utf8.contains { $0 >= 0x80 }
    if containsNonASCII {
      nonASCIIPhysicalLineCount += 1
    }
    if line.isEmpty {
      blankLineCount += 1
    } else if line.hasPrefix("//") {
      commentLineCount += 1
    }

    switch line {
    case pslBeginICANNMarker:
      guard currentSection == nil else {
        throw PublicSuffixListAssetTestError.invalidSnapshot
      }
      currentSection = .icann
      markerSequence.append(line)
    case pslEndICANNMarker:
      guard currentSection == .icann else {
        throw PublicSuffixListAssetTestError.invalidSnapshot
      }
      currentSection = nil
      markerSequence.append(line)
    case pslBeginPrivateMarker:
      guard currentSection == nil else {
        throw PublicSuffixListAssetTestError.invalidSnapshot
      }
      currentSection = .privateDomain
      markerSequence.append(line)
    case pslEndPrivateMarker:
      guard currentSection == .privateDomain else {
        throw PublicSuffixListAssetTestError.invalidSnapshot
      }
      currentSection = nil
      markerSequence.append(line)
    default:
      if line.isEmpty {
        continue
      }
      if line.hasPrefix("//") {
        if containsNonASCII {
          nonASCIICommentLineCount += 1
        }
        continue
      }
      guard let section = currentSection,
        line.trimmingCharacters(in: .whitespaces) == line,
        pslRuleHasValidShape(line),
        seenRules.insert(line).inserted
      else {
        throw PublicSuffixListAssetTestError.invalidSnapshot
      }
      if containsNonASCII {
        nonASCIIRuleLineCount += 1
      }
      switch section {
      case .icann:
        incrementRuleCount(for: line, counts: &icann)
      case .privateDomain:
        incrementRuleCount(for: line, counts: &privateDomain)
      }
    }
  }

  guard currentSection == nil,
    markerSequence
      == [
        pslBeginICANNMarker, pslEndICANNMarker,
        pslBeginPrivateMarker, pslEndPrivateMarker,
      ]
  else {
    throw PublicSuffixListAssetTestError.invalidSnapshot
  }

  return SnapshotSummary(
    versionMarkerCount: lines.count { $0 == "// VERSION: \(expectedPSLVersion)" },
    commitMarkerCount: lines.count { $0 == "// COMMIT: \(expectedPSLCommit)" },
    icann: icann,
    privateDomain: privateDomain,
    blankLineCount: blankLineCount,
    commentLineCount: commentLineCount,
    nonASCIIPhysicalLineCount: nonASCIIPhysicalLineCount,
    nonASCIIRuleLineCount: nonASCIIRuleLineCount,
    nonASCIICommentLineCount: nonASCIICommentLineCount
  )
}

private func incrementRuleCount(for line: String, counts: inout RuleCounts) {
  if line.hasPrefix("!") {
    counts.exception += 1
  } else if line.hasPrefix("*.") {
    counts.wildcard += 1
  } else {
    counts.exact += 1
  }
}

private func pslRuleHasValidShape(_ line: String) -> Bool {
  let body: Substring
  if line.hasPrefix("!") {
    body = line.dropFirst()
  } else if line.hasPrefix("*.") {
    body = line.dropFirst(2)
  } else {
    body = line[...]
  }
  guard body.isEmpty == false, body.hasPrefix(".") == false, body.hasSuffix(".") == false else {
    return false
  }
  return body.split(separator: ".", omittingEmptySubsequences: false).allSatisfy {
    $0.isEmpty == false
  }
}

private func parseOfficialCorpus(_ data: Data) throws -> OfficialCorpus {
  let lines = try pslPhysicalLines(in: data, error: .invalidOfficialCorpus)
  var cases = [OfficialCorpusCase]()
  var commentLineCount = 0
  var blankLineCount = 0

  for (offset, line) in lines.enumerated() {
    if line.isEmpty {
      blankLineCount += 1
    } else if line.hasPrefix("//") {
      commentLineCount += 1
    } else {
      cases.append(try parseOfficialCorpusCase(line, lineNumber: offset + 1))
    }
  }

  return OfficialCorpus(
    cases: cases,
    commentLineCount: commentLineCount,
    blankLineCount: blankLineCount
  )
}

private func parseOfficialCorpusCase(
  _ line: String,
  lineNumber: Int
) throws -> OfficialCorpusCase {
  let prefix = "checkPublicSuffix("
  let suffix = ");"
  guard line.hasPrefix(prefix), line.hasSuffix(suffix) else {
    throw PublicSuffixListAssetTestError.invalidOfficialCorpus
  }
  let bodyStart = line.index(line.startIndex, offsetBy: prefix.count)
  let bodyEnd = line.index(line.endIndex, offsetBy: -suffix.count)
  let body = line[bodyStart..<bodyEnd]
  guard let separator = body.range(of: ", "),
    body[separator.upperBound...].contains(", ") == false
  else {
    throw PublicSuffixListAssetTestError.invalidOfficialCorpus
  }

  let domainToken = try parseOfficialCorpusToken(body[..<separator.lowerBound])
  let expectedToken = try parseOfficialCorpusToken(body[separator.upperBound...])
  return OfficialCorpusCase(
    safeID: "test-psl-line-\(lineNumber)",
    domain: domainToken.value,
    expectedRegistrableDomain: expectedToken.value
  )
}

private func parseOfficialCorpusToken(_ token: Substring) throws -> OfficialCorpusToken {
  if token == "null" {
    return .null
  }
  guard token.count >= 2, token.first == "'", token.last == "'" else {
    throw PublicSuffixListAssetTestError.invalidOfficialCorpus
  }
  let value = String(token.dropFirst().dropLast())
  guard value.contains("'") == false, value.contains("\\") == false else {
    throw PublicSuffixListAssetTestError.invalidOfficialCorpus
  }
  return .string(value)
}

private func pslPhysicalLines(
  in data: Data,
  error: PublicSuffixListAssetTestError
) throws -> [String] {
  guard data.last == 0x0A, data.contains(0x0D) == false,
    let text = String(data: data, encoding: .utf8)
  else {
    throw error
  }
  var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
  guard lines.last == "" else {
    throw error
  }
  lines.removeLast()
  return lines
}

private func pslNormalizedASCIIHost(_ domain: String) -> String? {
  guard domain.isEmpty == false, domain.hasPrefix(".") == false,
    domain.hasSuffix(".") == false
  else {
    return nil
  }
  var components = URLComponents()
  components.scheme = "https"
  components.host = domain
  components.path = "/"
  guard let asciiHost = components.url?.host?.lowercased(),
    asciiHost.unicodeScalars.allSatisfy({ $0.isASCII }),
    pslASCIIHostHasValidShape(asciiHost)
  else {
    return nil
  }
  return asciiHost
}

private func pslASCIIHostHasValidShape(_ host: String) -> Bool {
  guard host.utf8.count <= 253 else {
    return false
  }
  return host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { label in
    guard (1...63).contains(label.utf8.count),
      let first = label.utf8.first,
      let last = label.utf8.last,
      pslIsASCIIAlphaNumeric(first),
      pslIsASCIIAlphaNumeric(last)
    else {
      return false
    }
    return label.utf8.allSatisfy { byte in
      pslIsASCIIAlphaNumeric(byte) || byte == 0x2D
    }
  }
}

private func pslIsASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x61...0x7A).contains(byte)
}

private func pslOptionalStringsAreEqual(_ lhs: String?, _ rhs: String?) -> Bool {
  lhs == rhs
}
