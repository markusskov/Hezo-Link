import CoreFoundation
import CryptoKit
import Darwin
import Foundation
import Testing

@testable import HezoLinkCore

#if canImport(FoundationXML)
  import FoundationXML
#endif

struct IANAAddressRegistryAssetTests {
  @Test func frozenPackageIntegrityAndProvenanceAreExact() throws {
    let manifestData = try ianaLoadRepositoryData("packages/iana-address-registries/manifest.json")
    try ianaRequireAsset(
      manifestData.count == 9_914
        && ianaSHA256Hex(manifestData)
          == "17aa4eea10696368cdf5fe0d2002d0864b06e39c7add927f2a5a8b3201a11c37"
    )
    let manifest = try ianaDecode(IANAAddressManifest.self, from: manifestData)

    #expect(throws: Never.self, "Manifest constants must remain frozen.") {
      try ianaVerifyManifestConstants(manifest)
    }
    #expect(throws: Never.self, "Manifest inventory must be closed and confined.") {
      try ianaVerifyManifestInventory(manifest)
    }
    #expect(throws: Never.self, "Every manifested artifact must match its frozen identity.") {
      try ianaVerifyFrozenArtifacts(manifest)
    }
    #expect(throws: Never.self, "Public-domain evidence and policy must remain explicit.") {
      try ianaVerifyPublicDomainPolicy(manifest)
    }
  }

  @Test func strictSchemasValidateTheFrozenManifestAndProjection() throws {
    let packageRoot =
      ianaAddressRepositoryRoot
      .appendingPathComponent("packages/iana-address-registries")
    let manifestSchema = try ianaStrictJSONObject(
      at: packageRoot.appendingPathComponent("manifest.schema.json")
    )
    let profileSchema = try ianaStrictJSONObject(
      at: packageRoot.appendingPathComponent(
        "schemas/iana-address-profile-v1.schema.json"
      )
    )
    let manifest = try ianaStrictJSONObject(
      at: packageRoot.appendingPathComponent("manifest.json")
    )
    let profile = try ianaStrictJSONObject(
      at: packageRoot.appendingPathComponent("projection/iana-address-profile-v1.json")
    )

    let manifestEvaluator = try IANAFrozenSchemaEvaluator(schema: manifestSchema)
    let profileEvaluator = try IANAFrozenSchemaEvaluator(schema: profileSchema)
    #expect(try manifestEvaluator.validates(manifest))
    #expect(try profileEvaluator.validates(profile))
  }

  @Test func strictSchemasRejectShapeTupleAndValueDrift() throws {
    let (manifestEvaluator, manifest) = try ianaSchemaMutationSubject(
      schemaPath: "manifest.schema.json",
      payloadPath: "manifest.json"
    )
    var manifestWithUnknownField = manifest
    manifestWithUnknownField["unexpected"] = true
    #expect(try manifestEvaluator.validates(manifestWithUnknownField) == false)

    var reorderedManifest = manifest
    var sources = try ianaRequireArray(reorderedManifest["sourceRegistries"])
    sources.swapAt(0, 1)
    reorderedManifest["sourceRegistries"] = sources
    #expect(try manifestEvaluator.validates(reorderedManifest) == false)

    var escapingManifest = manifest
    var documentation = try ianaRequireObject(escapingManifest["documentation"])
    var documentationFile = try ianaRequireObject(documentation["file"])
    documentationFile["path"] = "../README.md"
    documentation["file"] = documentationFile
    escapingManifest["documentation"] = documentation
    #expect(try manifestEvaluator.validates(escapingManifest) == false)

    let (profileEvaluator, profile) = try ianaSchemaMutationSubject(
      schemaPath: "schemas/iana-address-profile-v1.schema.json",
      payloadPath: "projection/iana-address-profile-v1.json"
    )
    var profileWithUnknownRecordField = profile
    var records = try ianaRequireArray(profileWithUnknownRecordField["records"])
    var firstRecord = try ianaRequireObject(records.first)
    firstRecord["unexpected"] = true
    records[0] = firstRecord
    profileWithUnknownRecordField["records"] = records
    #expect(try profileEvaluator.validates(profileWithUnknownRecordField) == false)

    var wrongWidthProfile = profile
    records = try ianaRequireArray(wrongWidthProfile["records"])
    firstRecord = try ianaRequireObject(records.first)
    firstRecord["networkBytesHex"] = "0000000000"
    records[0] = firstRecord
    wrongWidthProfile["records"] = records
    #expect(try profileEvaluator.validates(wrongWidthProfile) == false)

    var wrongPrefixProfile = profile
    records = try ianaRequireArray(wrongPrefixProfile["records"])
    firstRecord = try ianaRequireObject(records.first)
    firstRecord["prefixLength"] = 33
    records[0] = firstRecord
    wrongPrefixProfile["records"] = records
    #expect(try profileEvaluator.validates(wrongPrefixProfile) == false)

    var wrongFlagProfile = profile
    records = try ianaRequireArray(wrongFlagProfile["records"])
    firstRecord = try ianaRequireObject(records.first)
    var flags = try ianaRequireObject(firstRecord["flags"])
    flags["source"] = true
    firstRecord["flags"] = flags
    records[0] = firstRecord
    wrongFlagProfile["records"] = records
    #expect(try profileEvaluator.validates(wrongFlagProfile) == false)
  }

  @Test func strictJSONRejectsDuplicateKeysAtEveryDepth() throws {
    let projectionData = try ianaProjectionData()
    let projectionString = try #require(String(data: projectionData, encoding: .utf8))
    let topLevelDuplicate = try #require(
      projectionString.replacingFirstOccurrence(
        of: "\"schemaVersion\": 1,",
        with: "\"schemaVersion\": 1,\n  \"schemaVersion\": 1,"
      )
    )
    #expect(throws: IANAAddressAssetTestError.duplicateJSONKey) {
      try ianaVerifyStrictJSON(Data(topLevelDuplicate.utf8))
    }

    let nestedDuplicate = try #require(
      projectionString.replacingFirstOccurrence(
        of: "\"sourceRegistryCount\": 4,",
        with: "\"sourceRegistryCount\": 4,\n    \"sourceRegistryCount\": 4,"
      )
    )
    #expect(throws: IANAAddressAssetTestError.duplicateJSONKey) {
      try ianaVerifyStrictJSON(Data(nestedDuplicate.utf8))
    }
  }

  @Test func frozenSchemaEvaluatorRejectsVocabularyExpansion() throws {
    let packageRoot =
      ianaAddressRepositoryRoot
      .appendingPathComponent("packages/iana-address-registries")
    var schema = try ianaStrictJSONObject(
      at: packageRoot.appendingPathComponent("manifest.schema.json")
    )
    schema["unevaluatedProperties"] = false

    #expect(throws: IANAAddressAssetTestError.unsupportedSchemaVocabulary) {
      _ = try IANAFrozenSchemaEvaluator(schema: schema)
    }
  }

  @Test func packageProjectionRuntimeCopyAndSwiftPMResourceAreByteIdentical() throws {
    let packageProjection = try ianaProjectionData()
    let repositoryResource = try ianaLoadRepositoryData(
      "Sources/HezoLinkCore/Resources/AddressRegistry/iana-address-profile-v1.json"
    )
    #expect(repositoryResource == packageProjection)
    #expect(packageProjection.count == AddressRegistryClassifier.projectionByteCount)
    #expect(ianaSHA256Hex(packageProjection) == AddressRegistryClassifier.projectionSHA256)

    #if SWIFT_PACKAGE
      let resourceURL = try #require(
        Bundle.module.url(
          forResource: "iana-address-profile-v1",
          withExtension: "json",
          subdirectory: "AddressRegistry"
        )
      )
      let bundledResource = try Data(contentsOf: resourceURL)
      #expect(bundledResource == packageProjection)
    #endif

    _ = try AddressRegistryClassifier()
  }

  @Test func projectionIsAnExactDeterministicProjectionOfEverySourceRecord() throws {
    let projection = try ianaLoadProjection()
    let regenerated = try ianaRegenerateProjectionRecords(
      sources: projection.sourceRegistries,
      overlays: projection.policyOverlays
    )

    #expect(regenerated == projection.records)
    try ianaVerifyProjectionCounts(projection)
    try ianaVerifyProjectionOrderAndIdentities(projection.records)
  }

  @Test func everyProjectedPrefixAndAdjacentBoundaryMatchesTheIndependentOracle() throws {
    let projectionData = try ianaProjectionData()
    let projection = try ianaDecode(IANAAddressProjection.self, from: projectionData)
    let classifier = try AddressRegistryClassifier(
      projectionLoader: { projectionData },
      expectation: AddressRegistryProjectionExpectation(data: projectionData)
    )

    var vectors = Set<IANAAddressBoundaryVector>()
    for record in projection.records {
      let network = try ianaDecodeLowercaseHex(record.networkBytesHex)
      let last = try ianaLastAddress(network: network, prefixLength: record.prefixLength)
      vectors.insert(IANAAddressBoundaryVector(family: record.family, bytes: network))
      vectors.insert(IANAAddressBoundaryVector(family: record.family, bytes: last))
      if let preceding = ianaDecrementAddress(network) {
        vectors.insert(IANAAddressBoundaryVector(family: record.family, bytes: preceding))
      }
      if let following = ianaIncrementAddress(last) {
        vectors.insert(IANAAddressBoundaryVector(family: record.family, bytes: following))
      }
    }

    for vector in vectors {
      try ianaVerifyClassification(
        classifier: classifier,
        projection: projection,
        vector: vector
      )
    }
  }

  @Test func injectedProjectionLoaderFailsClosedForIntegrityAndShapeMutations() throws {
    let originalData = try ianaProjectionData()

    #expect(throws: AddressRegistryClassifierError.projectionUnavailable) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { throw IANAAddressAssetTestError.invalidFixture },
        expectation: AddressRegistryProjectionExpectation(data: originalData)
      )
    }

    var changedByteData = originalData
    changedByteData[0] ^= 0x01
    #expect(throws: AddressRegistryClassifierError.projectionIntegrityMismatch) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { changedByteData },
        expectation: AddressRegistryProjectionExpectation(data: originalData)
      )
    }

    let projectionString = try #require(String(data: originalData, encoding: .utf8))
    let duplicateKey = try #require(
      projectionString.replacingFirstOccurrence(
        of: "\"schemaVersion\": 1,",
        with: "\"schemaVersion\": 1,\n  \"schemaVersion\": 1,"
      )
    )
    try ianaExpectClassifierError(
      for: Data(duplicateKey.utf8),
      expected: .malformedProjection,
      label: "duplicate JSON key"
    )

    let unknownField = try ianaMutatedProjectionData { root in
      root["unexpected"] = true
    }
    try ianaExpectClassifierError(
      for: unknownField,
      expected: .malformedProjection,
      label: "unknown top-level field"
    )

    let wrongProfileVersion = try ianaMutatedProjectionData { root in
      root["profileVersion"] = "iana-future-unreviewed"
    }
    try ianaExpectClassifierError(
      for: wrongProfileVersion,
      expected: .inconsistentProjection,
      label: "wrong profile version"
    )
  }

  @Test func injectedProjectionLoaderFailsClosedForCoverageAndSemanticMutations() throws {
    let reorderedSources = try ianaMutatedProjectionData { root in
      var sources = try ianaRequireArray(root["sourceRegistries"])
      sources.swapAt(0, 1)
      root["sourceRegistries"] = sources
    }
    try ianaExpectClassifierError(for: reorderedSources, expected: .inconsistentProjection)

    let missingRecord = try ianaMutatedProjectionData { root in
      var records = try ianaRequireArray(root["records"])
      records.removeLast()
      root["records"] = records
    }
    try ianaExpectClassifierError(for: missingRecord, expected: .incompleteProjection)

    let wrongHexWidth = try ianaMutatedProjectionRecord(at: 0) { record in
      record["networkBytesHex"] = "0000000000"
    }
    try ianaExpectClassifierError(for: wrongHexWidth, expected: .inconsistentProjection)

    let invalidPrefixLength = try ianaMutatedProjectionRecord(at: 0) { record in
      record["prefixLength"] = 33
    }
    try ianaExpectClassifierError(for: invalidPrefixLength, expected: .inconsistentProjection)

    let nonNetworkBytes = try ianaMutatedProjectionRecord(
      matchingRegistryID: "iana-ipv4-address-space"
    ) { record in
      record["networkBytesHex"] = "00000001"
    }
    try ianaExpectClassifierError(for: nonNetworkBytes, expected: .inconsistentProjection)

    let booleanFlag = try ianaMutatedProjectionRecord(
      matchingRegistryID: "iana-ipv4-special-purpose"
    ) { record in
      var flags = try ianaRequireObject(record["flags"])
      flags["source"] = true
      record["flags"] = flags
    }
    try ianaExpectClassifierError(for: booleanFlag, expected: .malformedProjection)

    let unknownStatus = try ianaMutatedProjectionRecord(
      matchingRegistryID: "iana-ipv4-address-space"
    ) { record in
      record["status"] = "UNALLOCATED"
    }
    try ianaExpectClassifierError(for: unknownStatus, expected: .inconsistentProjection)

    let changedOverlay = try ianaMutatedProjectionData { root in
      var overlays = try ianaRequireArray(root["policyOverlays"])
      var overlay = try ianaRequireObject(overlays.first)
      overlay["prefix"] = "225.0.0.0/8"
      overlays[0] = overlay
      root["policyOverlays"] = overlays
    }
    try ianaExpectClassifierError(for: changedOverlay, expected: .inconsistentProjection)

    let duplicateIdentity = try ianaMutatedProjectionData { root in
      var records = try ianaRequireArray(root["records"])
      records[1] = records[0]
      root["records"] = records
    }
    try ianaExpectClassifierError(for: duplicateIdentity, expected: .inconsistentProjection)

    let orderSwap = try ianaMutatedProjectionData { root in
      var records = try ianaRequireArray(root["records"])
      records.swapAt(0, 1)
      root["records"] = records
    }
    try ianaExpectClassifierError(for: orderSwap, expected: .inconsistentProjection)
  }
}

private enum IANAAddressAssetTestError: Error, Equatable {
  case duplicateJSONKey
  case invalidFixture
  case pathEscapesRoot
  case unsupportedSchemaVocabulary
}

private let ianaAddressRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private struct IANAAddressFileIdentity: Decodable, Equatable {
  let pathBase: String
  let path: String
  let mediaType: String
  let encoding: String
  let byteCount: Int
  let sha256: String
  let lineEnding: String
  let physicalLineCount: Int
  let finalNewline: Bool
}

private struct IANAAddressManifest: Decodable {
  let schemaVersion: Int
  let manifestId: String
  let purpose: String
  let profileVersion: String
  let safety: Safety
  let validationRequirements: ValidationRequirements
  let sourceRegistries: [SourceRegistry]
  let licensing: Licensing
  let runtimeProjection: RuntimeProjection
  let schemas: [Schema]
  let documentation: Documentation

  struct Safety: Decodable {
    let runtimeNetworkAccessPermitted: Bool
    let runtimeExternalDataAccessPermitted: Bool
    let runtimeSourceSnapshotParsingPermitted: Bool
    let containsUserData: Bool
    let containsSecrets: Bool
    let classificationOnly: Bool
    let failureBehavior: String
  }

  struct ValidationRequirements: Decodable {
    let jsonSchemaDialect: String
    let strictSchemaModeRequired: Bool
    let duplicateJSONKeysRejected: Bool
    let digestVerificationRequired: Bool
    let countVerificationRequired: Bool
    let inventoryClosureRequired: Bool
    let lfLineEndingsRequired: Bool
    let finalNewlineRequired: Bool
    let sourceSnapshotsByteExact: Bool
    let runtimeProjectionByteEqualityRequired: Bool
    let companionSemanticValidationRequired: Bool
    let companionSemanticChecks: [String]
  }

  struct SourceRegistry: Decodable {
    let id: String
    let family: String
    let kind: String
    let file: IANAAddressFileIdentity
    let source: Source
    let sourceRecordCount: Int
    let projectedRecordCount: Int
    let transformation: String

    struct Source: Decodable {
      let publisher: String
      let sourceURL: String
      let revision: String
      let retrievedOn: String
      let licenseSpdx: String
    }
  }

  struct Licensing: Decodable {
    let spdxIdentifier: String
    let applicability: String
    let evidence: LicenseArtifact
    let legalCode: LicenseArtifact
  }

  struct LicenseArtifact: Decodable {
    let file: IANAAddressFileIdentity
    let sourceURL: String
    let sourceRevision: String
    let transformation: String
  }

  struct RuntimeProjection: Decodable {
    let profileId: String
    let profileVersion: String
    let packageFile: IANAAddressFileIdentity
    let runtimeResourceFile: IANAAddressFileIdentity
    let counts: Counts
    let transformation: String

    struct Counts: Decodable {
      let sourceRegistryCount: Int
      let policyOverlayCount: Int
      let recordCount: Int
      let familyRecords: [String: Int]
      let registryRecords: [String: Int]
      let ipv4StatusCounts: [String: Int]
      let ipv6AddressSpaceNameCounts: [String: Int]
    }
  }

  struct Schema: Decodable {
    let role: String
    let dialect: String
    let file: IANAAddressFileIdentity
  }

  struct Documentation: Decodable {
    let role: String
    let file: IANAAddressFileIdentity
  }
}

private struct IANAAddressProjection: Decodable {
  let schemaVersion: Int
  let profileId: String
  let profileVersion: String
  let projectionAlgorithmVersion: Int
  let purpose: String
  let sourceRegistries: [SourceRegistry]
  let policyOverlays: [PolicyOverlay]
  let counts: Counts
  let records: [Record]

  struct SourceRegistry: Decodable, Equatable {
    let id: String
    let family: String
    let kind: String
    let revision: String
    let sourceURL: String
    let snapshotPath: String
    let snapshotSha256: String
    let sourceRecordCount: Int
    let projectedRecordCount: Int
  }

  struct PolicyOverlay: Decodable, Equatable {
    let id: String
    let family: String
    let revision: String
    let sourceURL: String
    let prefix: String
  }

  struct Counts: Decodable, Equatable {
    let sourceRegistryCount: Int
    let policyOverlayCount: Int
    let recordCount: Int
    let familyRecords: [String: Int]
    let registryRecords: [String: Int]
  }

  struct Record: Decodable, Equatable {
    let registryId: String
    let sourceRecordIndex: Int?
    let family: String
    let prefixLength: Int
    let networkBytesHex: String
    let name: String
    let status: String?
    let allocationDate: String?
    let terminationDate: String?
    let flags: Flags?
  }

  struct Flags: Decodable, Equatable {
    let source: String
    let destination: String
    let forwardable: String
    let globallyReachable: String
    let reservedByProtocol: String
  }
}

private struct IANAFrozenArtifact: Equatable {
  let pathBase: String
  let path: String
  let byteCount: Int
  let physicalLineCount: Int
  let sha256: String
}

private let ianaFrozenPackageArtifacts: [IANAFrozenArtifact] = [
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "README.md",
    byteCount: 11_298,
    physicalLineCount: 95,
    sha256: "cf289c8f4266a78dffd0a171bc0b342b1fb93cc12e50dd34a76e12974791d12e"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "manifest.schema.json",
    byteCount: 27_302,
    physicalLineCount: 1_135,
    sha256: "39816cb025b7b01d544f4bebf822ed158c782f8b53bc3d176deb7da5c664ac39"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "schemas/iana-address-profile-v1.schema.json",
    byteCount: 21_412,
    physicalLineCount: 914,
    sha256: "7cd2cd135c547f51d33c5c43a6f88f27bfcf7f0793ec1df47d465501873367e7"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "projection/iana-address-profile-v1.json",
    byteCount: 118_651,
    physicalLineCount: 4_342,
    sha256: "9697f3b6da69ec68fea355c7f6bb0ae95151125fedb8c363e72d1cd7844af0be"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/iana/iana-ipv4-special-registry-2025-10-09.xml",
    byteCount: 13_459,
    physicalLineCount: 384,
    sha256: "cf24e11f41b7d42c68debe2d18b97cac815084ec413ebb3b244f704028a16f20"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/iana/iana-ipv6-special-registry-2025-10-09.xml",
    byteCount: 13_431,
    physicalLineCount: 383,
    sha256: "c17f4380ba84fb2160dae82ebfd8bd155a5853cfab624ed3a9fd251638a8be02"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/iana/ipv4-address-space-2025-10-10.xml",
    byteCount: 76_759,
    physicalLineCount: 2_646,
    sha256: "8ca3774374c81e4a673bb12d0eb415e7ac9970c6f5a6ceb14106de64b2cb3dcd"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/iana/ipv6-address-space-2025-10-23.xml",
    byteCount: 6_956,
    physicalLineCount: 154,
    sha256: "15481d1e549b481f3bd0321c5cd2c0327a00cbd3d5a6fc35fc7b53b51e70b1cb"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/licensing/iana-ietf-protocol-registry-licensing-terms-2021-11-10.html",
    byteCount: 8_375,
    physicalLineCount: 190,
    sha256: "9e9694eb818bcd620f153c208f431e9a0212c7202d35951f5cc3fcfe3720754b"
  ),
  IANAFrozenArtifact(
    pathBase: "package-relative",
    path: "upstream/licensing/CC0-1.0-legalcode.txt",
    byteCount: 7_048,
    physicalLineCount: 121,
    sha256: "a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499"
  ),
]

private let ianaFrozenRuntimeArtifact = IANAFrozenArtifact(
  pathBase: "repository-relative",
  path: "Sources/HezoLinkCore/Resources/AddressRegistry/iana-address-profile-v1.json",
  byteCount: 118_651,
  physicalLineCount: 4_342,
  sha256: "9697f3b6da69ec68fea355c7f6bb0ae95151125fedb8c363e72d1cd7844af0be"
)

private func ianaVerifyManifestConstants(_ manifest: IANAAddressManifest) throws {
  try ianaRequireAsset(manifest.schemaVersion == 1)
  try ianaRequireAsset(manifest.manifestId == "hezo-iana-address-registries-v1")
  try ianaRequireAsset(manifest.purpose == "offline-address-registry-classification")
  try ianaRequireAsset(manifest.profileVersion == "iana-2025-10-23-hezo-overlay-v1")

  let safety = manifest.safety
  try ianaRequireAsset(safety.runtimeNetworkAccessPermitted == false)
  try ianaRequireAsset(safety.runtimeExternalDataAccessPermitted == false)
  try ianaRequireAsset(safety.runtimeSourceSnapshotParsingPermitted == false)
  try ianaRequireAsset(safety.containsUserData == false)
  try ianaRequireAsset(safety.containsSecrets == false)
  try ianaRequireAsset(safety.classificationOnly)
  try ianaRequireAsset(
    safety.failureBehavior == "unavailable-on-missing-invalid-or-integrity-mismatched-resource"
  )

  let requirements = manifest.validationRequirements
  try ianaRequireAsset(
    requirements.jsonSchemaDialect == "https://json-schema.org/draft/2020-12/schema"
  )
  try ianaRequireAsset(requirements.strictSchemaModeRequired)
  try ianaRequireAsset(requirements.duplicateJSONKeysRejected)
  try ianaRequireAsset(requirements.digestVerificationRequired)
  try ianaRequireAsset(requirements.countVerificationRequired)
  try ianaRequireAsset(requirements.inventoryClosureRequired)
  try ianaRequireAsset(requirements.lfLineEndingsRequired)
  try ianaRequireAsset(requirements.finalNewlineRequired)
  try ianaRequireAsset(requirements.sourceSnapshotsByteExact)
  try ianaRequireAsset(requirements.runtimeProjectionByteEqualityRequired)
  try ianaRequireAsset(requirements.companionSemanticValidationRequired)
  try ianaRequireAsset(
    requirements.companionSemanticChecks
      == [
        "duplicate-json-key-rejection",
        "manifest-inventory-closure",
        "file-identity-and-format",
        "source-registry-revision-and-counts",
        "deterministic-projection-regeneration",
        "prefix-normalization-and-order",
        "record-identity-uniqueness",
        "declared-count-coherence",
        "package-runtime-projection-byte-equality",
      ]
  )

  let runtime = manifest.runtimeProjection
  try ianaRequireAsset(runtime.profileId == "iana-address-profile-v1")
  try ianaRequireAsset(runtime.profileVersion == "iana-2025-10-23-hezo-overlay-v1")
  try ianaRequireAsset(
    runtime.transformation == "deterministic-normalization-and-byte-for-byte-runtime-copy"
  )
  try ianaRequireAsset(runtime.counts.sourceRegistryCount == 4)
  try ianaRequireAsset(runtime.counts.policyOverlayCount == 2)
  try ianaRequireAsset(runtime.counts.recordCount == 329)
  try ianaRequireAsset(runtime.counts.familyRecords == ["ipv4": 283, "ipv6": 46])
  try ianaRequireAsset(
    runtime.counts.registryRecords
      == [
        "iana-ipv4-special-purpose": 26,
        "iana-ipv6-special-purpose": 25,
        "iana-ipv4-address-space": 256,
        "iana-ipv6-address-space": 20,
        "hezo-ipv4-multicast-overlay": 1,
        "hezo-ipv6-multicast-overlay": 1,
      ]
  )
  try ianaRequireAsset(
    runtime.counts.ipv4StatusCounts
      == ["ALLOCATED": 129, "LEGACY": 92, "RESERVED": 35]
  )
  try ianaRequireAsset(
    runtime.counts.ipv6AddressSpaceNameCounts
      == [
        "Reserved by IETF": 16,
        "Global Unicast": 1,
        "Unique Local Unicast": 1,
        "Link-Scoped Unicast": 1,
        "Multicast": 1,
      ]
  )
}

private func ianaVerifyManifestInventory(_ manifest: IANAAddressManifest) throws {
  let expectedSourceMetadata:
    [(
      id: String, family: String, kind: String, url: String, revision: String,
      sourceCount: Int, projectedCount: Int
    )] = [
      (
        "iana-ipv4-special-purpose", "ipv4", "special-purpose",
        "https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xml",
        "2025-10-09", 25, 26
      ),
      (
        "iana-ipv6-special-purpose", "ipv6", "special-purpose",
        "https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xml",
        "2025-10-09", 25, 25
      ),
      (
        "iana-ipv4-address-space", "ipv4", "address-space",
        "https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml",
        "2025-10-10", 256, 256
      ),
      (
        "iana-ipv6-address-space", "ipv6", "address-space",
        "https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml",
        "2025-10-23", 20, 20
      ),
    ]
  try ianaRequireAsset(manifest.sourceRegistries.count == expectedSourceMetadata.count)
  for (source, expected) in zip(manifest.sourceRegistries, expectedSourceMetadata) {
    try ianaRequireAsset(source.id == expected.id)
    try ianaRequireAsset(source.family == expected.family)
    try ianaRequireAsset(source.kind == expected.kind)
    try ianaRequireAsset(source.source.publisher == "Internet Assigned Numbers Authority")
    try ianaRequireAsset(source.source.sourceURL == expected.url)
    try ianaRequireAsset(source.source.revision == expected.revision)
    try ianaRequireAsset(source.source.retrievedOn == "2026-08-11")
    try ianaRequireAsset(source.source.licenseSpdx == "CC0-1.0")
    try ianaRequireAsset(source.sourceRecordCount == expected.sourceCount)
    try ianaRequireAsset(source.projectedRecordCount == expected.projectedCount)
    try ianaRequireAsset(
      source.transformation == "byte-for-byte-copy-with-repository-filename-only"
    )
  }

  try ianaRequireAsset(
    manifest.schemas.map(\.role) == ["manifest-schema", "runtime-profile-schema"])
  try ianaRequireAsset(
    manifest.schemas.allSatisfy {
      $0.dialect == "https://json-schema.org/draft/2020-12/schema"
    }
  )
  try ianaRequireAsset(manifest.documentation.role == "package-readme")

  let manifestedPackageFiles = Set(
    manifest.sourceRegistries.map(\.file.path)
      + [manifest.licensing.evidence.file.path, manifest.licensing.legalCode.file.path]
      + [manifest.runtimeProjection.packageFile.path]
      + manifest.schemas.map(\.file.path)
      + [manifest.documentation.file.path]
  )
  let expectedPackageFiles = Set(ianaFrozenPackageArtifacts.map(\.path))
  try ianaRequireAsset(manifestedPackageFiles == expectedPackageFiles)

  let packageRoot =
    ianaAddressRepositoryRoot
    .appendingPathComponent("packages/iana-address-registries")
    .standardizedFileURL
  let filesOnDisk = try ianaRelativeRegularFiles(in: packageRoot)
  try ianaRequireAsset(filesOnDisk == expectedPackageFiles.union(["manifest.json"]))

  for path in manifestedPackageFiles {
    _ = try ianaConfinedURL(relativePath: path, root: packageRoot)
  }
  try ianaRequireAsset(
    manifest.runtimeProjection.runtimeResourceFile.pathBase == "repository-relative")
  _ = try ianaConfinedURL(
    relativePath: manifest.runtimeProjection.runtimeResourceFile.path,
    root: ianaAddressRepositoryRoot
  )
}

private func ianaVerifyFrozenArtifacts(_ manifest: IANAAddressManifest) throws {
  let manifestIdentities =
    manifest.sourceRegistries.map(\.file)
    + [manifest.licensing.evidence.file, manifest.licensing.legalCode.file]
    + [manifest.runtimeProjection.packageFile]
    + manifest.schemas.map(\.file)
    + [manifest.documentation.file]
  try ianaRequireAsset(manifestIdentities.count == ianaFrozenPackageArtifacts.count)

  let identitiesByPath = Dictionary(
    uniqueKeysWithValues: manifestIdentities.map { ($0.path, $0) }
  )
  for expected in ianaFrozenPackageArtifacts {
    let identity = try ianaRequireValue(identitiesByPath[expected.path])
    try ianaVerifyIdentity(identity, equals: expected)
    let data = try ianaLoadRepositoryData("packages/iana-address-registries/\(expected.path)")
    try ianaVerifyBytes(data, expected: expected)
  }

  try ianaVerifyIdentity(
    manifest.runtimeProjection.runtimeResourceFile,
    equals: ianaFrozenRuntimeArtifact
  )
  let runtimeData = try ianaLoadRepositoryData(ianaFrozenRuntimeArtifact.path)
  try ianaVerifyBytes(runtimeData, expected: ianaFrozenRuntimeArtifact)
}

private func ianaVerifyPublicDomainPolicy(_ manifest: IANAAddressManifest) throws {
  let licensing = manifest.licensing
  try ianaRequireAsset(licensing.spdxIdentifier == "CC0-1.0")
  try ianaRequireAsset(licensing.applicability == "iana-ietf-protocol-registry-data")
  try ianaRequireAsset(licensing.evidence.sourceURL == "https://www.iana.org/help/licensing-terms")
  try ianaRequireAsset(licensing.evidence.sourceRevision == "2021-11-10")
  try ianaRequireAsset(
    licensing.legalCode.sourceURL
      == "https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt"
  )
  try ianaRequireAsset(licensing.legalCode.sourceRevision == "CC0 1.0 Universal")
  try ianaRequireAsset(
    licensing.evidence.transformation == "byte-for-byte-copy-with-repository-filename-only"
  )
  try ianaRequireAsset(
    licensing.legalCode.transformation == "byte-for-byte-copy-with-repository-filename-only"
  )

  let evidence = try ianaLoadRepositoryString(
    "packages/iana-address-registries/\(licensing.evidence.file.path)"
  ).lowercased()
  let legalCode = try ianaLoadRepositoryString(
    "packages/iana-address-registries/\(licensing.legalCode.file.path)"
  ).lowercased()
  try ianaRequireAsset(evidence.contains("freely used by any party for any purpose"))
  try ianaRequireAsset(evidence.contains("to the public domain"))
  try ianaRequireAsset(evidence.contains("creative commons cc0 1.0 dedication"))
  try ianaRequireAsset(legalCode.contains("cc0 1.0 universal"))
  try ianaRequireAsset(legalCode.contains("2. waiver"))
  try ianaRequireAsset(legalCode.contains("3. public license fallback"))
}

private func ianaVerifyIdentity(
  _ identity: IANAAddressFileIdentity,
  equals expected: IANAFrozenArtifact
) throws {
  try ianaRequireAsset(identity.pathBase == expected.pathBase)
  try ianaRequireAsset(identity.path == expected.path)
  try ianaRequireAsset(identity.encoding == "UTF-8")
  try ianaRequireAsset(identity.byteCount == expected.byteCount)
  try ianaRequireAsset(identity.sha256 == expected.sha256)
  try ianaRequireAsset(identity.lineEnding == "LF")
  try ianaRequireAsset(identity.physicalLineCount == expected.physicalLineCount)
  try ianaRequireAsset(identity.finalNewline)
}

private func ianaVerifyBytes(_ data: Data, expected: IANAFrozenArtifact) throws {
  try ianaRequireAsset(data.count == expected.byteCount)
  try ianaRequireAsset(ianaSHA256Hex(data) == expected.sha256)
  try ianaRequireAsset(String(data: data, encoding: .utf8) != nil)
  try ianaRequireAsset(data.last == 0x0A)
  try ianaRequireAsset(data.contains(0x0D) == false)
  try ianaRequireAsset(data.filter { $0 == 0x0A }.count == expected.physicalLineCount)
}

private func ianaLoadRepositoryData(_ relativePath: String) throws -> Data {
  let url = try ianaConfinedURL(relativePath: relativePath, root: ianaAddressRepositoryRoot)
  do {
    return try Data(contentsOf: url, options: [.mappedIfSafe])
  } catch {
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaLoadRepositoryString(_ relativePath: String) throws -> String {
  let data = try ianaLoadRepositoryData(relativePath)
  guard let value = String(data: data, encoding: .utf8) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return value
}

private func ianaProjectionData() throws -> Data {
  try ianaLoadRepositoryData(
    "packages/iana-address-registries/projection/iana-address-profile-v1.json"
  )
}

private func ianaLoadProjection() throws -> IANAAddressProjection {
  try ianaDecode(IANAAddressProjection.self, from: ianaProjectionData())
}

private func ianaDecode<Value: Decodable>(_: Value.Type, from data: Data) throws -> Value {
  do {
    return try JSONDecoder().decode(Value.self, from: data)
  } catch {
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaSHA256Hex(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func ianaConfinedURL(relativePath: String, root: URL) throws -> URL {
  guard relativePath.isEmpty == false, relativePath.hasPrefix("/") == false else {
    throw IANAAddressAssetTestError.pathEscapesRoot
  }
  let standardizedRoot = root.standardizedFileURL
  let candidate = standardizedRoot.appendingPathComponent(relativePath).standardizedFileURL
  let rootPrefix =
    standardizedRoot.path.hasSuffix("/")
    ? standardizedRoot.path
    : standardizedRoot.path + "/"
  guard candidate.path.hasPrefix(rootPrefix) else {
    throw IANAAddressAssetTestError.pathEscapesRoot
  }
  return candidate
}

private func ianaRelativeRegularFiles(in root: URL) throws -> Set<String> {
  let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey]
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: keys,
      options: []
    )
  else {
    throw IANAAddressAssetTestError.invalidFixture
  }

  var files = Set<String>()
  for case let url as URL in enumerator {
    let values = try url.resourceValues(forKeys: Set(keys))
    guard values.isSymbolicLink != true else {
      throw IANAAddressAssetTestError.pathEscapesRoot
    }
    guard values.isRegularFile == true else { continue }
    let prefix = root.standardizedFileURL.path + "/"
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(prefix) else {
      throw IANAAddressAssetTestError.pathEscapesRoot
    }
    files.insert(String(path.dropFirst(prefix.count)))
  }
  return files
}

private func ianaRequireAsset(_ condition: @autoclosure () throws -> Bool) throws {
  guard try condition() else {
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaRequireValue<Value>(_ value: Value?) throws -> Value {
  guard let value else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return value
}

private func ianaStrictJSONObject(at url: URL) throws -> [String: Any] {
  let data: Data
  do {
    data = try Data(contentsOf: url, options: [.mappedIfSafe])
  } catch {
    throw IANAAddressAssetTestError.invalidFixture
  }
  try ianaVerifyStrictJSON(data)
  do {
    guard
      let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        as? [String: Any]
    else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    return object
  } catch is IANAAddressAssetTestError {
    throw IANAAddressAssetTestError.invalidFixture
  } catch {
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaVerifyStrictJSON(_ data: Data) throws {
  var scanner = IANAStrictJSONScanner(data: data)
  try scanner.scanDocument()
}

private struct IANAStrictJSONScanner {
  private let bytes: [UInt8]
  private var index = 0

  init(data: Data) {
    bytes = Array(data)
  }

  mutating func scanDocument() throws {
    skipWhitespace()
    try scanValue()
    skipWhitespace()
    guard index == bytes.count else {
      throw IANAAddressAssetTestError.invalidFixture
    }
  }

  private mutating func scanValue() throws {
    guard index < bytes.count else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    switch bytes[index] {
    case 0x7B:
      try scanObject()
    case 0x5B:
      try scanArray()
    case 0x22:
      _ = try scanString()
    case 0x74:
      try scanLiteral("true")
    case 0x66:
      try scanLiteral("false")
    case 0x6E:
      try scanLiteral("null")
    case 0x2D, 0x30...0x39:
      try scanNumber()
    default:
      throw IANAAddressAssetTestError.invalidFixture
    }
  }

  private mutating func scanObject() throws {
    try consume(0x7B)
    skipWhitespace()
    if consumeIfPresent(0x7D) { return }

    var keys = Set<String>()
    while true {
      let key = try scanString()
      guard keys.insert(key).inserted else {
        throw IANAAddressAssetTestError.duplicateJSONKey
      }
      skipWhitespace()
      try consume(0x3A)
      skipWhitespace()
      try scanValue()
      skipWhitespace()
      if consumeIfPresent(0x7D) { return }
      try consume(0x2C)
      skipWhitespace()
    }
  }

  private mutating func scanArray() throws {
    try consume(0x5B)
    skipWhitespace()
    if consumeIfPresent(0x5D) { return }

    while true {
      try scanValue()
      skipWhitespace()
      if consumeIfPresent(0x5D) { return }
      try consume(0x2C)
      skipWhitespace()
    }
  }

  private mutating func scanString() throws -> String {
    let start = index
    try consume(0x22)
    while index < bytes.count {
      let byte = bytes[index]
      index += 1
      switch byte {
      case 0x22:
        let encodedString = Data(bytes[start..<index])
        do {
          guard
            let values = try JSONSerialization.jsonObject(
              with: Data("[".utf8) + encodedString + Data("]".utf8)
            ) as? [String],
            values.count == 1,
            let value = values.first
          else {
            throw IANAAddressAssetTestError.invalidFixture
          }
          return value
        } catch {
          throw IANAAddressAssetTestError.invalidFixture
        }
      case 0x5C:
        guard index < bytes.count else {
          throw IANAAddressAssetTestError.invalidFixture
        }
        let escaped = bytes[index]
        index += 1
        if escaped == 0x75 {
          guard index + 4 <= bytes.count,
            bytes[index..<(index + 4)].allSatisfy(ianaIsHexDigit)
          else {
            throw IANAAddressAssetTestError.invalidFixture
          }
          index += 4
        } else if [0x22, 0x5C, 0x2F, 0x62, 0x66, 0x6E, 0x72, 0x74].contains(escaped) == false {
          throw IANAAddressAssetTestError.invalidFixture
        }
      case 0x00...0x1F:
        throw IANAAddressAssetTestError.invalidFixture
      default:
        continue
      }
    }
    throw IANAAddressAssetTestError.invalidFixture
  }

  private mutating func scanLiteral(_ literal: StaticString) throws {
    let expected = Array(String(describing: literal).utf8)
    guard index + expected.count <= bytes.count,
      Array(bytes[index..<(index + expected.count)]) == expected
    else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    index += expected.count
  }

  private mutating func scanNumber() throws {
    let start = index
    while index < bytes.count,
      [0x2B, 0x2D, 0x2E, 0x45, 0x65].contains(bytes[index])
        || (0x30...0x39).contains(bytes[index])
    {
      index += 1
    }
    guard index > start else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    let token = Data(bytes[start..<index])
    do {
      _ = try JSONSerialization.jsonObject(
        with: Data("[".utf8) + token + Data("]".utf8)
      )
    } catch {
      throw IANAAddressAssetTestError.invalidFixture
    }
  }

  private mutating func consume(_ byte: UInt8) throws {
    guard consumeIfPresent(byte) else {
      throw IANAAddressAssetTestError.invalidFixture
    }
  }

  private mutating func consumeIfPresent(_ byte: UInt8) -> Bool {
    guard index < bytes.count, bytes[index] == byte else { return false }
    index += 1
    return true
  }

  private mutating func skipWhitespace() {
    while index < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[index]) {
      index += 1
    }
  }
}

private func ianaIsHexDigit(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte) || (0x61...0x66).contains(byte)
}

private struct IANAFrozenSchemaEvaluator {
  private let rootSchema: [String: Any]

  init(schema: [String: Any]) throws {
    try Self.verifyFrozenVocabulary(in: schema, rootSchema: schema)
    rootSchema = schema
  }

  func validates(_ instance: Any) throws -> Bool {
    try validate(instance, against: rootSchema)
  }

  private func validate(_ instance: Any, against schema: Any) throws -> Bool {
    if let booleanSchema = ianaJSONBoolean(schema) {
      return booleanSchema
    }
    guard let object = schema as? [String: Any] else {
      throw IANAAddressAssetTestError.invalidFixture
    }

    if let reference = object["$ref"] as? String,
      try validate(instance, against: Self.resolve(reference, in: rootSchema)) == false
    {
      return false
    }
    if let typeName = object["type"] as? String,
      ianaJSONValue(instance, matchesType: typeName) == false
    {
      return false
    }
    if let constant = object["const"], ianaJSONValuesEqual(instance, constant) == false {
      return false
    }
    if let choices = object["enum"] as? [Any],
      choices.contains(where: { ianaJSONValuesEqual(instance, $0) }) == false
    {
      return false
    }
    if try validateStringAssertions(instance, schema: object) == false {
      return false
    }
    if validateNumericAssertions(instance, schema: object) == false {
      return false
    }
    if try validateObjectAssertions(instance, schema: object) == false {
      return false
    }
    if try validateArrayAssertions(instance, schema: object) == false {
      return false
    }
    if let schemas = object["allOf"] as? [Any] {
      for nestedSchema in schemas where try validate(instance, against: nestedSchema) == false {
        return false
      }
    }
    if let schemas = object["oneOf"] as? [Any] {
      var matches = 0
      for nestedSchema in schemas where try validate(instance, against: nestedSchema) {
        matches += 1
      }
      if matches != 1 { return false }
    }
    if let condition = object["if"] {
      if try validate(instance, against: condition) {
        if let consequence = object["then"],
          try validate(instance, against: consequence) == false
        {
          return false
        }
      } else if let alternative = object["else"],
        try validate(instance, against: alternative) == false
      {
        return false
      }
    }
    return true
  }

  private func validateStringAssertions(_ instance: Any, schema: [String: Any]) throws -> Bool {
    guard let string = instance as? String else { return true }
    let length = string.unicodeScalars.count
    if let minimum = ianaJSONInteger(schema["minLength"]), length < minimum { return false }
    if let maximum = ianaJSONInteger(schema["maxLength"]), length > maximum { return false }
    if let pattern = schema["pattern"] as? String {
      let expression: NSRegularExpression
      do {
        expression = try NSRegularExpression(pattern: pattern)
      } catch {
        throw IANAAddressAssetTestError.invalidFixture
      }
      let range = NSRange(string.startIndex..<string.endIndex, in: string)
      if expression.firstMatch(in: string, range: range) == nil { return false }
    }
    return true
  }

  private func validateNumericAssertions(_ instance: Any, schema: [String: Any]) -> Bool {
    guard let number = ianaJSONNumber(instance) else { return true }
    if let minimum = ianaJSONNumber(schema["minimum"]),
      number.compare(minimum) == .orderedAscending
    {
      return false
    }
    if let maximum = ianaJSONNumber(schema["maximum"]),
      number.compare(maximum) == .orderedDescending
    {
      return false
    }
    return true
  }

  private func validateObjectAssertions(_ instance: Any, schema: [String: Any]) throws -> Bool {
    guard let value = instance as? [String: Any] else { return true }
    if let required = schema["required"] as? [String],
      required.contains(where: { value[$0] == nil })
    {
      return false
    }
    let properties = schema["properties"] as? [String: Any] ?? [:]
    for (name, propertySchema) in properties {
      guard let propertyValue = value[name] else { continue }
      if try validate(propertyValue, against: propertySchema) == false { return false }
    }
    if ianaJSONBoolean(schema["additionalProperties"]) == false,
      Set(value.keys).subtracting(properties.keys).isEmpty == false
    {
      return false
    }
    return true
  }

  private func validateArrayAssertions(_ instance: Any, schema: [String: Any]) throws -> Bool {
    guard let value = instance as? [Any] else { return true }
    if let minimum = ianaJSONInteger(schema["minItems"]), value.count < minimum { return false }
    if let maximum = ianaJSONInteger(schema["maxItems"]), value.count > maximum { return false }
    if ianaJSONBoolean(schema["uniqueItems"]) == true, ianaJSONArrayHasDuplicates(value) {
      return false
    }

    let prefixSchemas = schema["prefixItems"] as? [Any] ?? []
    for index in 0..<min(value.count, prefixSchemas.count) {
      if try validate(value[index], against: prefixSchemas[index]) == false { return false }
    }
    if let items = schema["items"], value.count > prefixSchemas.count {
      for index in prefixSchemas.count..<value.count {
        if try validate(value[index], against: items) == false { return false }
      }
    }
    return true
  }

  private static func verifyFrozenVocabulary(in schema: Any, rootSchema: [String: Any]) throws {
    if ianaJSONBoolean(schema) != nil { return }
    guard let object = schema as? [String: Any] else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    let supportedKeywords: Set<String> = [
      "$defs", "$id", "$ref", "$schema", "additionalProperties", "allOf", "const",
      "description", "else", "enum", "if", "items", "maxItems", "maxLength", "maximum",
      "minItems", "minLength", "minimum", "oneOf", "pattern", "prefixItems", "properties",
      "required", "then", "title", "type", "uniqueItems",
    ]
    guard Set(object.keys).subtracting(supportedKeywords).isEmpty else {
      throw IANAAddressAssetTestError.unsupportedSchemaVocabulary
    }

    if let definitions = object["$defs"] {
      guard let values = definitions as? [String: Any] else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      for schema in values.values {
        try verifyFrozenVocabulary(in: schema, rootSchema: rootSchema)
      }
    }
    if let reference = object["$ref"] {
      guard let value = reference as? String else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      _ = try resolve(value, in: rootSchema)
    }
    if let properties = object["properties"] {
      guard let values = properties as? [String: Any] else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      for schema in values.values {
        try verifyFrozenVocabulary(in: schema, rootSchema: rootSchema)
      }
    }
    for keyword in ["items", "if", "then", "else"] {
      if let schema = object[keyword] {
        try verifyFrozenVocabulary(in: schema, rootSchema: rootSchema)
      }
    }
    for keyword in ["allOf", "oneOf", "prefixItems"] {
      guard let rawSchemas = object[keyword] else { continue }
      guard let schemas = rawSchemas as? [Any] else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      for schema in schemas {
        try verifyFrozenVocabulary(in: schema, rootSchema: rootSchema)
      }
    }
    try verifyKeywordShapes(object)
  }

  private static func verifyKeywordShapes(_ schema: [String: Any]) throws {
    for keyword in ["$id", "$schema", "description", "title"] {
      if let value = schema[keyword], (value is String) == false {
        throw IANAAddressAssetTestError.invalidFixture
      }
    }
    if let type = schema["type"] {
      let types: Set<String> = [
        "array", "boolean", "integer", "null", "number", "object", "string",
      ]
      guard let value = type as? String, types.contains(value) else {
        throw IANAAddressAssetTestError.invalidFixture
      }
    }
    if let required = schema["required"] {
      guard let names = required as? [String], Set(names).count == names.count else {
        throw IANAAddressAssetTestError.invalidFixture
      }
    }
    if let additional = schema["additionalProperties"], ianaJSONBoolean(additional) == nil {
      throw IANAAddressAssetTestError.invalidFixture
    }
    if let unique = schema["uniqueItems"], ianaJSONBoolean(unique) == nil {
      throw IANAAddressAssetTestError.invalidFixture
    }
    for keyword in ["minItems", "maxItems", "minLength", "maxLength"] {
      if let value = schema[keyword], (ianaJSONInteger(value) ?? -1) < 0 {
        throw IANAAddressAssetTestError.invalidFixture
      }
    }
    if let pattern = schema["pattern"] {
      guard let value = pattern as? String else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      do {
        _ = try NSRegularExpression(pattern: value)
      } catch {
        throw IANAAddressAssetTestError.invalidFixture
      }
    }
  }

  private static func resolve(_ reference: String, in root: [String: Any]) throws -> Any {
    guard reference.hasPrefix("#/"), reference.count > 2 else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    var current: Any = root
    for rawToken in reference.dropFirst(2).split(separator: "/", omittingEmptySubsequences: false) {
      let token = rawToken.replacingOccurrences(of: "~1", with: "/")
        .replacingOccurrences(of: "~0", with: "~")
      guard let object = current as? [String: Any], let value = object[token] else {
        throw IANAAddressAssetTestError.invalidFixture
      }
      current = value
    }
    return current
  }
}

private func ianaSchemaMutationSubject(
  schemaPath: String,
  payloadPath: String
) throws -> (IANAFrozenSchemaEvaluator, [String: Any]) {
  let packageRoot =
    ianaAddressRepositoryRoot
    .appendingPathComponent("packages/iana-address-registries")
  let schema = try ianaStrictJSONObject(at: packageRoot.appendingPathComponent(schemaPath))
  let payload = try ianaStrictJSONObject(at: packageRoot.appendingPathComponent(payloadPath))
  return (try IANAFrozenSchemaEvaluator(schema: schema), payload)
}

private func ianaRequireObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return object
}

private func ianaRequireArray(_ value: Any?) throws -> [Any] {
  guard let array = value as? [Any] else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return array
}

private func ianaJSONValue(_ value: Any, matchesType typeName: String) -> Bool {
  switch typeName {
  case "array":
    value is [Any]
  case "boolean":
    ianaJSONBoolean(value) != nil
  case "integer":
    ianaJSONInteger(value) != nil
  case "null":
    value is NSNull
  case "number":
    ianaJSONNumber(value) != nil
  case "object":
    value is [String: Any]
  case "string":
    value is String
  default:
    false
  }
}

private func ianaJSONBoolean(_ value: Any?) -> Bool? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) == CFBooleanGetTypeID()
  else {
    return nil
  }
  return number.boolValue
}

private func ianaJSONNumber(_ value: Any?) -> NSNumber? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID(),
    number.doubleValue.isFinite
  else {
    return nil
  }
  return number
}

private func ianaJSONInteger(_ value: Any?) -> Int? {
  guard let number = ianaJSONNumber(value),
    number.doubleValue.rounded(.towardZero) == number.doubleValue,
    let integer = Int(exactly: number.int64Value)
  else {
    return nil
  }
  return integer
}

private func ianaJSONArrayHasDuplicates(_ values: [Any]) -> Bool {
  for leftIndex in values.indices {
    for rightIndex in values.index(after: leftIndex)..<values.endIndex
    where ianaJSONValuesEqual(values[leftIndex], values[rightIndex]) {
      return true
    }
  }
  return false
}

private func ianaJSONValuesEqual(_ left: Any, _ right: Any) -> Bool {
  if left is NSNull || right is NSNull { return left is NSNull && right is NSNull }
  if let leftBoolean = ianaJSONBoolean(left), let rightBoolean = ianaJSONBoolean(right) {
    return leftBoolean == rightBoolean
  }
  if ianaJSONBoolean(left) != nil || ianaJSONBoolean(right) != nil { return false }
  if let leftNumber = ianaJSONNumber(left), let rightNumber = ianaJSONNumber(right) {
    return leftNumber.compare(rightNumber) == .orderedSame
  }
  if let leftString = left as? String, let rightString = right as? String {
    return leftString.unicodeScalars.elementsEqual(rightString.unicodeScalars)
  }
  if let leftArray = left as? [Any], let rightArray = right as? [Any] {
    return leftArray.count == rightArray.count
      && zip(leftArray, rightArray).allSatisfy { ianaJSONValuesEqual($0.0, $0.1) }
  }
  if let leftObject = left as? [String: Any], let rightObject = right as? [String: Any] {
    guard Set(leftObject.keys) == Set(rightObject.keys) else { return false }
    return leftObject.allSatisfy { key, value in
      guard let rightValue = rightObject[key] else { return false }
      return ianaJSONValuesEqual(value, rightValue)
    }
  }
  return false
}

private extension String {
  func replacingFirstOccurrence(of target: String, with replacement: String) -> String? {
    guard let range = range(of: target) else { return nil }
    return replacingCharacters(in: range, with: replacement)
  }
}

private final class IANAXMLRecordCollector: NSObject, XMLParserDelegate {
  private(set) var rootRegistryID: String?
  private(set) var revision: String?
  private(set) var records: [[String: String]] = []
  private(set) var failure: Error?

  private var elementStack: [String] = []
  private var textStack: [String] = []
  private var currentRecord: [String: String]?

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    if rootRegistryID == nil, elementName == "registry" {
      rootRegistryID = attributeDict["id"]
    }
    elementStack.append(elementName)
    textStack.append("")
    if elementName == "record" {
      guard currentRecord == nil else {
        failure = IANAAddressAssetTestError.invalidFixture
        parser.abortParsing()
        return
      }
      currentRecord = [:]
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard textStack.isEmpty == false else { return }
    textStack[textStack.index(before: textStack.endIndex)].append(string)
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    guard elementStack.last == elementName, let rawText = textStack.popLast() else {
      failure = IANAAddressAssetTestError.invalidFixture
      parser.abortParsing()
      return
    }
    elementStack.removeLast()
    let text = ianaNormalizeXMLText(rawText)

    if elementName == "record" {
      guard let completed = currentRecord else {
        failure = IANAAddressAssetTestError.invalidFixture
        parser.abortParsing()
        return
      }
      records.append(completed)
      currentRecord = nil
    } else if currentRecord != nil, elementStack.last == "record" {
      currentRecord?[elementName] = text
    } else if elementName == "updated", revision == nil {
      revision = text
    }

    if textStack.isEmpty == false {
      textStack[textStack.index(before: textStack.endIndex)].append(rawText)
    }
  }

  func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    if failure == nil {
      failure = parseError
    }
  }
}

private func ianaRegenerateProjectionRecords(
  sources: [IANAAddressProjection.SourceRegistry],
  overlays: [IANAAddressProjection.PolicyOverlay]
) throws -> [IANAAddressProjection.Record] {
  var projected: [IANAAddressProjection.Record] = []

  for source in sources {
    let data = try ianaLoadRepositoryData(
      "packages/iana-address-registries/\(source.snapshotPath)"
    )
    try ianaRequireAsset(ianaSHA256Hex(data) == source.snapshotSha256)
    let parsed = try ianaParseRegistryXML(data)
    try ianaRequireAsset(parsed.rootRegistryID == ianaExpectedXMLRegistryID(source.id))
    try ianaRequireAsset(parsed.revision == source.revision)
    try ianaRequireAsset(parsed.records.count == source.sourceRecordCount)

    switch source.id {
    case "iana-ipv4-special-purpose", "iana-ipv6-special-purpose":
      projected.append(contentsOf: try ianaProjectSpecialPurpose(parsed.records, source: source))
    case "iana-ipv4-address-space":
      projected.append(contentsOf: try ianaProjectIPv4AddressSpace(parsed.records, source: source))
    case "iana-ipv6-address-space":
      projected.append(contentsOf: try ianaProjectIPv6AddressSpace(parsed.records, source: source))
    default:
      throw IANAAddressAssetTestError.invalidFixture
    }

    let actualCount = projected.filter { $0.registryId == source.id }.count
    try ianaRequireAsset(actualCount == source.projectedRecordCount)
  }

  for overlay in overlays {
    let parsedPrefix = try ianaParseCIDR(overlay.prefix, family: overlay.family)
    projected.append(
      IANAAddressProjection.Record(
        registryId: overlay.id,
        sourceRecordIndex: nil,
        family: overlay.family,
        prefixLength: parsedPrefix.prefixLength,
        networkBytesHex: ianaLowercaseHex(parsedPrefix.networkBytes),
        name: "Multicast",
        status: "POLICY-OVERLAY",
        allocationDate: nil,
        terminationDate: nil,
        flags: nil
      )
    )
  }

  return projected.sorted(by: ianaProjectionRecordPrecedes)
}

private func ianaParseRegistryXML(_ data: Data) throws -> IANAXMLRecordCollector {
  let collector = IANAXMLRecordCollector()
  let parser = XMLParser(data: data)
  parser.delegate = collector
  parser.shouldResolveExternalEntities = false
  guard parser.parse(), collector.failure == nil else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return collector
}

private func ianaExpectedXMLRegistryID(_ sourceID: String) throws -> String {
  switch sourceID {
  case "iana-ipv4-special-purpose":
    "iana-ipv4-special-registry"
  case "iana-ipv6-special-purpose":
    "iana-ipv6-special-registry"
  case "iana-ipv4-address-space":
    "ipv4-address-space"
  case "iana-ipv6-address-space":
    "ipv6-address-space"
  default:
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaProjectSpecialPurpose(
  _ sourceRecords: [[String: String]],
  source: IANAAddressProjection.SourceRegistry
) throws -> [IANAAddressProjection.Record] {
  var result: [IANAAddressProjection.Record] = []
  for (index, fields) in sourceRecords.enumerated() {
    let rawAddress = try ianaRequireNonempty(fields["address"])
    let name = try ianaRequireNonempty(fields["name"])
    let flags = IANAAddressProjection.Flags(
      source: try ianaProjectionFlag(fields["source"]),
      destination: try ianaProjectionFlag(fields["destination"]),
      forwardable: try ianaProjectionFlag(fields["forwardable"]),
      globallyReachable: try ianaProjectionFlag(fields["global"]),
      reservedByProtocol: try ianaProjectionFlag(fields["reserved"])
    )
    let addresses = rawAddress.split(separator: ",", omittingEmptySubsequences: false)
    try ianaRequireAsset(addresses.isEmpty == false)
    for address in addresses {
      let parsed = try ianaParseCIDR(
        String(address).trimmingCharacters(in: .whitespacesAndNewlines),
        family: source.family
      )
      result.append(
        IANAAddressProjection.Record(
          registryId: source.id,
          sourceRecordIndex: index,
          family: source.family,
          prefixLength: parsed.prefixLength,
          networkBytesHex: ianaLowercaseHex(parsed.networkBytes),
          name: name,
          status: nil,
          allocationDate: ianaNonempty(fields["allocation"]),
          terminationDate: ianaNonempty(fields["termination"]),
          flags: flags
        )
      )
    }
  }
  return result
}

private func ianaProjectIPv4AddressSpace(
  _ sourceRecords: [[String: String]],
  source: IANAAddressProjection.SourceRegistry
) throws -> [IANAAddressProjection.Record] {
  try sourceRecords.enumerated().map { index, fields in
    let rawPrefix = try ianaRequireNonempty(fields["prefix"])
    let pieces = rawPrefix.split(separator: "/", omittingEmptySubsequences: false)
    guard pieces.count == 2, let firstOctet = UInt8(pieces[0]), pieces[1] == "8" else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    return IANAAddressProjection.Record(
      registryId: source.id,
      sourceRecordIndex: index,
      family: "ipv4",
      prefixLength: 8,
      networkBytesHex: ianaLowercaseHex([firstOctet, 0, 0, 0]),
      name: try ianaRequireNonempty(fields["designation"]),
      status: try ianaRequireNonempty(fields["status"]),
      allocationDate: ianaNonempty(fields["date"]),
      terminationDate: nil,
      flags: nil
    )
  }
}

private func ianaProjectIPv6AddressSpace(
  _ sourceRecords: [[String: String]],
  source: IANAAddressProjection.SourceRegistry
) throws -> [IANAAddressProjection.Record] {
  try sourceRecords.enumerated().map { index, fields in
    let parsed = try ianaParseCIDR(
      try ianaRequireNonempty(fields["prefix"]),
      family: "ipv6"
    )
    return IANAAddressProjection.Record(
      registryId: source.id,
      sourceRecordIndex: index,
      family: "ipv6",
      prefixLength: parsed.prefixLength,
      networkBytesHex: ianaLowercaseHex(parsed.networkBytes),
      name: try ianaRequireNonempty(fields["description"]),
      status: nil,
      allocationDate: nil,
      terminationDate: nil,
      flags: nil
    )
  }
}

private func ianaNormalizeXMLText(_ value: String) -> String {
  value.components(separatedBy: .whitespacesAndNewlines)
    .filter { $0.isEmpty == false }
    .joined(separator: " ")
}

private func ianaRequireNonempty(_ value: String?) throws -> String {
  guard let value = ianaNonempty(value) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return value
}

private func ianaNonempty(_ value: String?) -> String? {
  guard let value, value.isEmpty == false else { return nil }
  return value
}

private func ianaProjectionFlag(_ sourceValue: String?) throws -> String {
  switch ianaNonempty(sourceValue) {
  case nil:
    "unspecified"
  case "True":
    "true"
  case "False":
    "false"
  case "N/A":
    "not-applicable"
  default:
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private struct IANACIDR {
  let networkBytes: [UInt8]
  let prefixLength: Int
}

private func ianaParseCIDR(_ value: String, family: String) throws -> IANACIDR {
  let components = value.split(separator: "/", omittingEmptySubsequences: false)
  guard components.count == 2, let prefixLength = Int(components[1]) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  let address = String(components[0])
  let bytes: [UInt8]
  let maximumPrefixLength: Int

  switch family {
  case "ipv4":
    var parsed = in_addr()
    guard address.withCString({ inet_pton(AF_INET, $0, &parsed) }) == 1 else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    bytes = withUnsafeBytes(of: &parsed) { Array($0) }
    maximumPrefixLength = 32
  case "ipv6":
    var parsed = in6_addr()
    guard address.withCString({ inet_pton(AF_INET6, $0, &parsed) }) == 1 else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    bytes = withUnsafeBytes(of: &parsed) { Array($0) }
    maximumPrefixLength = 128
  default:
    throw IANAAddressAssetTestError.invalidFixture
  }

  guard (0...maximumPrefixLength).contains(prefixLength),
    ianaIsCanonicalNetwork(bytes, prefixLength: prefixLength)
  else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  return IANACIDR(networkBytes: bytes, prefixLength: prefixLength)
}

private func ianaIsCanonicalNetwork(_ bytes: [UInt8], prefixLength: Int) -> Bool {
  guard prefixLength >= 0, prefixLength <= bytes.count * 8 else { return false }
  let wholeBytes = prefixLength / 8
  let remainingBits = prefixLength % 8
  if remainingBits > 0 {
    let hostMask = UInt8.max >> UInt8(remainingBits)
    if bytes[wholeBytes] & hostMask != 0 { return false }
  }
  let trailingStart = wholeBytes + (remainingBits > 0 ? 1 : 0)
  return bytes[trailingStart...].allSatisfy { $0 == 0 }
}

private func ianaLowercaseHex(_ bytes: [UInt8]) -> String {
  bytes.map { String(format: "%02x", $0) }.joined()
}

private func ianaDecodeLowercaseHex(_ value: String) throws -> [UInt8] {
  let bytes = Array(value.utf8)
  guard bytes.isEmpty == false, bytes.count.isMultiple(of: 2) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  var result: [UInt8] = []
  result.reserveCapacity(bytes.count / 2)
  for index in stride(from: 0, to: bytes.count, by: 2) {
    guard let high = ianaLowercaseHexNibble(bytes[index]),
      let low = ianaLowercaseHexNibble(bytes[index + 1])
    else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    result.append((high << 4) | low)
  }
  return result
}

private func ianaLowercaseHexNibble(_ value: UInt8) -> UInt8? {
  switch value {
  case 0x30...0x39:
    value - 0x30
  case 0x61...0x66:
    value - 0x61 + 10
  default:
    nil
  }
}

private func ianaProjectionRecordPrecedes(
  _ lhs: IANAAddressProjection.Record,
  _ rhs: IANAAddressProjection.Record
) -> Bool {
  let lhsFamily = lhs.family == "ipv4" ? 0 : 1
  let rhsFamily = rhs.family == "ipv4" ? 0 : 1
  if lhsFamily != rhsFamily { return lhsFamily < rhsFamily }

  let lhsBytes = (try? ianaDecodeLowercaseHex(lhs.networkBytesHex)) ?? []
  let rhsBytes = (try? ianaDecodeLowercaseHex(rhs.networkBytesHex)) ?? []
  if lhsBytes != rhsBytes { return lhsBytes.lexicographicallyPrecedes(rhsBytes) }
  if lhs.prefixLength != rhs.prefixLength { return lhs.prefixLength > rhs.prefixLength }
  if lhs.registryId != rhs.registryId { return lhs.registryId < rhs.registryId }
  if lhs.sourceRecordIndex != rhs.sourceRecordIndex {
    return (lhs.sourceRecordIndex ?? -1) < (rhs.sourceRecordIndex ?? -1)
  }
  return lhs.name < rhs.name
}

private func ianaVerifyProjectionCounts(_ projection: IANAAddressProjection) throws {
  try ianaRequireAsset(projection.schemaVersion == 1)
  try ianaRequireAsset(projection.profileId == "iana-address-profile-v1")
  try ianaRequireAsset(projection.profileVersion == "iana-2025-10-23-hezo-overlay-v1")
  try ianaRequireAsset(projection.projectionAlgorithmVersion == 1)
  try ianaRequireAsset(projection.purpose == "offline-address-classification")
  try ianaRequireAsset(projection.sourceRegistries.count == 4)
  try ianaRequireAsset(projection.policyOverlays.count == 2)
  try ianaRequireAsset(projection.records.count == 329)
  try ianaRequireAsset(projection.counts.sourceRegistryCount == 4)
  try ianaRequireAsset(projection.counts.policyOverlayCount == 2)
  try ianaRequireAsset(projection.counts.recordCount == 329)

  let familyCounts = Dictionary(grouping: projection.records, by: \.family).mapValues(\.count)
  let registryCounts = Dictionary(grouping: projection.records, by: \.registryId).mapValues(\.count)
  try ianaRequireAsset(familyCounts == projection.counts.familyRecords)
  try ianaRequireAsset(registryCounts == projection.counts.registryRecords)

  for source in projection.sourceRegistries {
    let sourceRows = projection.records.filter { $0.registryId == source.id }
    try ianaRequireAsset(sourceRows.count == source.projectedRecordCount)
    let indexCounts = Dictionary(
      grouping: sourceRows.compactMap(\.sourceRecordIndex),
      by: { $0 }
    ).mapValues(\.count)
    var expected = Dictionary(uniqueKeysWithValues: (0..<source.sourceRecordCount).map { ($0, 1) })
    if source.id == "iana-ipv4-special-purpose" { expected[12] = 2 }
    try ianaRequireAsset(indexCounts == expected)
  }
}

private func ianaVerifyProjectionOrderAndIdentities(
  _ records: [IANAAddressProjection.Record]
) throws {
  var identities = Set<String>()
  for (index, record) in records.enumerated() {
    let bytes = try ianaDecodeLowercaseHex(record.networkBytesHex)
    try ianaRequireAsset(bytes.count == (record.family == "ipv4" ? 4 : 16))
    try ianaRequireAsset(ianaIsCanonicalNetwork(bytes, prefixLength: record.prefixLength))
    let identity = "\(record.registryId)|\(record.networkBytesHex)|\(record.prefixLength)"
    try ianaRequireAsset(identities.insert(identity).inserted)
    if index > 0 {
      try ianaRequireAsset(ianaProjectionRecordPrecedes(record, records[index - 1]) == false)
    }
  }
}

private struct IANAAddressBoundaryVector: Hashable {
  let family: String
  let bytes: [UInt8]
}

private func ianaLastAddress(network: [UInt8], prefixLength: Int) throws -> [UInt8] {
  guard ianaIsCanonicalNetwork(network, prefixLength: prefixLength) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  var result = network
  for bitIndex in prefixLength..<(network.count * 8) {
    let byteIndex = bitIndex / 8
    let bitInByte = bitIndex % 8
    result[byteIndex] |= UInt8(1 << (7 - bitInByte))
  }
  return result
}

private func ianaIncrementAddress(_ bytes: [UInt8]) -> [UInt8]? {
  var result = bytes
  for index in result.indices.reversed() {
    if result[index] == UInt8.max {
      result[index] = 0
    } else {
      result[index] += 1
      return result
    }
  }
  return nil
}

private func ianaDecrementAddress(_ bytes: [UInt8]) -> [UInt8]? {
  var result = bytes
  for index in result.indices.reversed() {
    if result[index] == 0 {
      result[index] = UInt8.max
    } else {
      result[index] -= 1
      return result
    }
  }
  return nil
}

private func ianaVerifyClassification(
  classifier: AddressRegistryClassifier,
  projection: IANAAddressProjection,
  vector: IANAAddressBoundaryVector
) throws {
  let host: ValidatedURLHost
  switch vector.family {
  case "ipv4":
    host = try ianaRequireValue(ValidatedURLHost(ipv4PackedAddressBytes: vector.bytes))
  case "ipv6":
    host = try ianaRequireValue(ValidatedURLHost(ipv6PackedAddressBytes: vector.bytes))
  default:
    throw IANAAddressAssetTestError.invalidFixture
  }

  guard case .ip(let actual) = classifier.classify(host) else {
    throw IANAAddressAssetTestError.invalidFixture
  }
  let effectiveFamily: String
  let effectiveBytes: [UInt8]
  switch host.kind {
  case .ipv4Literal:
    effectiveFamily = "ipv4"
    effectiveBytes = try ianaRequireValue(host.packedAddressBytes)
  case .ipv6Literal:
    effectiveFamily = "ipv6"
    effectiveBytes = try ianaRequireValue(host.packedAddressBytes)
  case .domainName:
    throw IANAAddressAssetTestError.invalidFixture
  }
  let expectedRecord = try ianaExpectedRecord(
    for: effectiveBytes,
    family: effectiveFamily,
    records: projection.records
  )
  let expectedFamily: AddressRegistryIPFamily = effectiveFamily == "ipv4" ? .ipv4 : .ipv6
  try ianaRequireAsset(actual.family == expectedFamily)
  try ianaRequireAsset(actual.sourceRevision == AddressRegistryClassifier.profileRevision)

  guard let expectedRecord else {
    try ianaRequireAsset(actual.category == .unallocated)
    try ianaRequireAsset(actual.match == nil)
    return
  }

  try ianaRequireAsset(actual.category == ianaExpectedCategory(expectedRecord))
  let match = try ianaRequireValue(actual.match)
  let network = try ianaDecodeLowercaseHex(expectedRecord.networkBytesHex)
  let networkHost: ValidatedURLHost
  if effectiveFamily == "ipv4" {
    networkHost = try ianaRequireValue(ValidatedURLHost(ipv4PackedAddressBytes: network))
  } else {
    networkHost = try ianaRequireValue(ValidatedURLHost(ipv6PackedAddressBytes: network))
  }
  try ianaRequireAsset(match.prefix == "\(networkHost.asciiValue)/\(expectedRecord.prefixLength)")
  try ianaRequireAsset(match.name == expectedRecord.name)

  if let source = projection.sourceRegistries.first(where: { $0.id == expectedRecord.registryId }) {
    try ianaRequireAsset(match.source.identifier == source.id)
    try ianaRequireAsset(match.source.updated == source.revision)
    try ianaRequireAsset(match.source.publicURL == source.sourceURL)
  } else {
    let overlay = try ianaRequireValue(
      projection.policyOverlays.first(where: { $0.id == expectedRecord.registryId })
    )
    try ianaRequireAsset(match.source.identifier == overlay.id)
    try ianaRequireAsset(match.source.updated == overlay.revision)
    try ianaRequireAsset(match.source.publicURL == overlay.sourceURL)
  }
}

private func ianaExpectedRecord(
  for bytes: [UInt8],
  family: String,
  records: [IANAAddressProjection.Record]
) throws -> IANAAddressProjection.Record? {
  let matching = try records.filter { record in
    guard record.family == family else { return false }
    let network = try ianaDecodeLowercaseHex(record.networkBytesHex)
    return ianaPrefixContains(
      address: bytes,
      network: network,
      prefixLength: record.prefixLength
    )
  }
  for layer in [0, 1, 2] {
    let layerMatches = matching.filter { ianaRecordLayer($0) == layer }
    if let longest = layerMatches.max(by: { $0.prefixLength < $1.prefixLength }) {
      return longest
    }
  }
  return nil
}

private func ianaRecordLayer(_ record: IANAAddressProjection.Record) -> Int {
  if record.registryId.hasSuffix("special-purpose") { return 0 }
  if record.registryId.hasSuffix("multicast-overlay") { return 1 }
  return 2
}

private func ianaExpectedCategory(
  _ record: IANAAddressProjection.Record
) -> AddressRegistryCategory {
  switch ianaRecordLayer(record) {
  case 0:
    return .specialPurpose
  case 1:
    return .multicast
  default:
    if record.family == "ipv4" {
      return record.status == "ALLOCATED" || record.status == "LEGACY"
        ? .allocatedOrLegacyIPv4
        : .reserved
    }
    switch record.name {
    case "Global Unicast":
      return .globalUnicastIPv6
    case "Multicast":
      return .multicast
    default:
      return .reserved
    }
  }
}

private func ianaPrefixContains(
  address: [UInt8],
  network: [UInt8],
  prefixLength: Int
) -> Bool {
  guard address.count == network.count else { return false }
  let wholeBytes = prefixLength / 8
  if wholeBytes > 0, address[..<wholeBytes] != network[..<wholeBytes] { return false }
  let remainingBits = prefixLength % 8
  guard remainingBits > 0 else { return true }
  let mask = UInt8.max << UInt8(8 - remainingBits)
  return address[wholeBytes] & mask == network[wholeBytes] & mask
}

private func ianaMutatedProjectionData(
  _ mutate: (inout [String: Any]) throws -> Void
) throws -> Data {
  let packageRoot =
    ianaAddressRepositoryRoot
    .appendingPathComponent("packages/iana-address-registries")
  var root = try ianaStrictJSONObject(
    at: packageRoot.appendingPathComponent("projection/iana-address-profile-v1.json")
  )
  try mutate(&root)
  do {
    return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
  } catch {
    throw IANAAddressAssetTestError.invalidFixture
  }
}

private func ianaMutatedProjectionRecord(
  at index: Int,
  _ mutate: (inout [String: Any]) throws -> Void
) throws -> Data {
  try ianaMutatedProjectionData { root in
    var records = try ianaRequireArray(root["records"])
    guard records.indices.contains(index) else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    var record = try ianaRequireObject(records[index])
    try mutate(&record)
    records[index] = record
    root["records"] = records
  }
}

private func ianaMutatedProjectionRecord(
  matchingRegistryID registryID: String,
  _ mutate: (inout [String: Any]) throws -> Void
) throws -> Data {
  try ianaMutatedProjectionData { root in
    var records = try ianaRequireArray(root["records"])
    guard
      let index = records.firstIndex(where: { value in
        guard let record = value as? [String: Any] else { return false }
        return record["registryId"] as? String == registryID
      })
    else {
      throw IANAAddressAssetTestError.invalidFixture
    }
    var record = try ianaRequireObject(records[index])
    try mutate(&record)
    records[index] = record
    root["records"] = records
  }
}

private func ianaExpectClassifierError(
  for data: Data,
  expected: AddressRegistryClassifierError,
  label: String = "projection mutation"
) throws {
  do {
    _ = try AddressRegistryClassifier(
      projectionLoader: { data },
      expectation: AddressRegistryProjectionExpectation(data: data)
    )
    Issue.record("Expected \(label) to fail closed.")
  } catch let error as AddressRegistryClassifierError {
    #expect(error == expected)
  } catch {
    Issue.record("Unexpected error category for \(label).")
  }
}
