import Foundation
import Testing

@testable import HezoLinkCore

struct AddressRegistryClassifierTests {
  @Test(
    "Every pinned source produces its exact category and bounded provenance",
    arguments: addressRegistrySourceCases
  )
  func classifiesEveryPinnedSource(testCase: AddressRegistryClassificationCase) throws {
    let classifier = try AddressRegistryClassifier()
    let host = try #require(testCase.host.makeValidatedHost())
    guard case .ip(let result) = classifier.classify(host) else {
      Issue.record("A validated IP fixture must produce an IP classification.")
      return
    }
    let match = try #require(result.match)

    let matchesExpectedFixture =
      result.family == testCase.family
      && result.category == testCase.category
      && result.sourceRevision == AddressRegistryClassifier.profileRevision
      && match.prefix == testCase.prefix
      && match.name == testCase.name
      && match.source.identifier == testCase.source.identifier
      && match.source.updated == testCase.source.updated
      && match.source.publicURL == testCase.source.publicURL
    #expect(
      matchesExpectedFixture,
      "Pinned source classification must match its content-free case identifier."
    )
  }

  @Test(
    "Most-specific special-purpose records override broader registry space",
    arguments: addressRegistryLongestPrefixCases
  )
  func longestSpecialPurposePrefixWins(testCase: AddressRegistryClassificationCase) throws {
    let classifier = try AddressRegistryClassifier()
    let host = try #require(testCase.host.makeValidatedHost())
    guard case .ip(let result) = classifier.classify(host) else {
      Issue.record("A validated IP fixture must produce an IP classification.")
      return
    }
    let match = try #require(result.match)

    let matchesExpectedFixture =
      result.category == .specialPurpose
      && match.prefix == testCase.prefix
      && match.name == testCase.name
      && match.source.identifier == testCase.source.identifier
    #expect(
      matchesExpectedFixture,
      "Longest-prefix classification must match its content-free case identifier."
    )
  }

  @Test(
    "Special, multicast, and broad-space boundaries retain adjacent distinctions",
    arguments: addressRegistryBoundaryCases
  )
  func classifiesBoundariesAndAdjacentAddresses(
    testCase: AddressRegistryBoundaryCase
  ) throws {
    let classifier = try AddressRegistryClassifier()
    let host = try #require(testCase.host.makeValidatedHost())
    guard case .ip(let result) = classifier.classify(host) else {
      Issue.record("A validated IP boundary fixture must produce an IP classification.")
      return
    }
    let match = try #require(result.match)

    let matchesExpectedFixture =
      result.family == testCase.family
      && result.category == testCase.category
      && match.prefix == testCase.prefix
      && match.source.identifier == testCase.sourceIdentifier
    #expect(
      matchesExpectedFixture,
      "Boundary classification must match its content-free case identifier."
    )
  }

  @Test func domainHostsAreNotApplicable() throws {
    let classifier = try AddressRegistryClassifier()
    let host = try #require(
      ValidatedURLHost(domainNameASCIIValue: "address-classifier.test")
    )

    #expect(classifier.classify(host) == .notApplicable)
  }

  @Test func validatedManualURLConvenienceUsesTheSameHostClassification() throws {
    let classifier = try AddressRegistryClassifier()
    guard
      case .accepted(let validatedURL) = ManualURLInputValidator.isolatedTestFixture.validate(
        "https://[2001:db8::1]/path"
      )
    else {
      Issue.record("The reserved IPv6 fixture must pass local syntax validation.")
      return
    }

    #expect(classifier.classify(validatedURL) == classifier.classify(validatedURL.host))
  }

  @Test func ipv4MappedIPv6IsNormalizedBeforeClassification() throws {
    let host = try #require(
      ValidatedURLHost(
        ipv6PackedAddressBytes: [
          0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0xFF, 0xFF, 192, 0, 2, 1,
        ]
      )
    )
    let classifier = try AddressRegistryClassifier()
    guard case .ip(let result) = classifier.classify(host) else {
      Issue.record("The normalized mapped fixture must produce an IP classification.")
      return
    }
    let match = try #require(result.match)

    let matchesExpectedFixture =
      host.kind == .ipv4Literal
      && host.packedAddressBytes == [192, 0, 2, 1]
      && result.family == .ipv4
      && result.category == .specialPurpose
      && match.prefix == "192.0.2.0/24"
    #expect(
      matchesExpectedFixture,
      "Mapped-address normalization must match its content-free fixture expectation."
    )
  }

  @Test func closedCategoryVocabularyIncludesTheExplicitNoMatchDefault() {
    let categories: [AddressRegistryCategory] = [
      .specialPurpose,
      .allocatedOrLegacyIPv4,
      .globalUnicastIPv6,
      .multicast,
      .reserved,
      .unallocated,
    ]

    #expect(categories.map(addressRegistryCategoryMarker) == [0, 1, 2, 3, 4, 5])
    #expect(
      categories.allSatisfy {
        $0.description.isEmpty == false && $0.description.utf8.count <= 64
      }
    )
  }

  @Test func bundledProfileExposesAndVerifiesExactIntegrityConstants() throws {
    let projectionData = try addressRegistryProjectionData()

    #expect(AddressRegistryClassifier.profileRevision == "iana-address-profile-v1")
    #expect(AddressRegistryClassifier.projectionByteCount == 118_651)
    #expect(
      AddressRegistryClassifier.projectionSHA256
        == "9697f3b6da69ec68fea355c7f6bb0ae95151125fedb8c363e72d1cd7844af0be"
    )
    #expect(projectionData.count == AddressRegistryClassifier.projectionByteCount)
    #expect(
      AddressRegistryProjectionExpectation(data: projectionData).sha256
        == AddressRegistryClassifier.projectionSHA256
    )
    #expect(throws: Never.self) {
      _ = try AddressRegistryClassifier()
    }
  }

  @Test func loaderFailureIsBoundedAndDoesNotFallback() {
    #expect(throws: AddressRegistryClassifierError.projectionUnavailable) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { throw AddressRegistryClassifierTestError.loaderUnavailable },
        expectation: addressRegistryBundledExpectation
      )
    }
  }

  @Test func corruptBytesFailExactIntegrityBeforeDecoding() throws {
    var corruptData = try addressRegistryProjectionData()
    corruptData[corruptData.startIndex] ^= 0x01

    #expect(throws: AddressRegistryClassifierError.projectionIntegrityMismatch) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { corruptData },
        expectation: addressRegistryBundledExpectation
      )
    }
  }

  @Test func truncatedIntegrityValidFixtureFailsAsMalformed() throws {
    let projectionData = try addressRegistryProjectionData()
    let truncatedData = Data(projectionData.prefix(projectionData.count / 2))

    #expect(throws: AddressRegistryClassifierError.malformedProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { truncatedData },
        expectation: AddressRegistryProjectionExpectation(data: truncatedData)
      )
    }
  }

  @Test func missingRecordFailsAsIncompleteInsteadOfProducingAResult() throws {
    let missingRecordData = try mutatedAddressRegistryProjection { object in
      var records = try requireAddressRegistryRecords(object)
      records.removeLast()
      object["records"] = records
    }

    #expect(throws: AddressRegistryClassifierError.incompleteProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { missingRecordData },
        expectation: AddressRegistryProjectionExpectation(data: missingRecordData)
      )
    }
  }

  @Test func duplicateRecordFailsAsInconsistentInsteadOfBeingDeduplicated() throws {
    let duplicateRecordData = try mutatedAddressRegistryProjection { object in
      var records = try requireAddressRegistryRecords(object)
      guard records.count >= 2 else {
        throw AddressRegistryClassifierTestError.invalidProjection
      }
      records[1] = records[0]
      object["records"] = records
    }

    #expect(throws: AddressRegistryClassifierError.inconsistentProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { duplicateRecordData },
        expectation: AddressRegistryProjectionExpectation(data: duplicateRecordData)
      )
    }
  }

  @Test func addressSpacePartitionsRejectGapsAndOverlaps() throws {
    let ipv4GapData = try mutatedAddressRegistryProjection { object in
      try mutateAddressSpacePrefix(
        in: &object,
        registryID: "iana-ipv4-address-space",
        sourceRecordIndex: 1,
        prefixLength: 9
      )
    }
    let ipv6GapData = try mutatedAddressRegistryProjection { object in
      try mutateAddressSpacePrefix(
        in: &object,
        registryID: "iana-ipv6-address-space",
        sourceRecordIndex: 0,
        prefixLength: 9
      )
    }
    let ipv6OverlapData = try mutatedAddressRegistryProjection { object in
      try mutateAddressSpacePrefix(
        in: &object,
        registryID: "iana-ipv6-address-space",
        sourceRecordIndex: 0,
        prefixLength: 7
      )
    }

    #expect(throws: AddressRegistryClassifierError.incompleteProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { ipv4GapData },
        expectation: AddressRegistryProjectionExpectation(data: ipv4GapData)
      )
    }
    #expect(throws: AddressRegistryClassifierError.incompleteProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { ipv6GapData },
        expectation: AddressRegistryProjectionExpectation(data: ipv6GapData)
      )
    }
    #expect(throws: AddressRegistryClassifierError.inconsistentProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { ipv6OverlapData },
        expectation: AddressRegistryProjectionExpectation(data: ipv6OverlapData)
      )
    }
  }

  @Test func escapeEquivalentDuplicateJSONKeyFailsBeforeFoundationDecoding() throws {
    let projectionData = try addressRegistryProjectionData()
    var projection = try #require(String(data: projectionData, encoding: .utf8))
    let original = "  \"schemaVersion\": 1,\n"
    let replacement =
      "  \"schemaVersion\": 1,\n  \"\\u0073chemaVersion\": 1,\n"
    guard let range = projection.range(of: original) else {
      throw AddressRegistryClassifierTestError.invalidProjection
    }
    projection.replaceSubrange(range, with: replacement)
    let duplicateKeyData = Data(projection.utf8)

    #expect(throws: AddressRegistryClassifierError.malformedProjection) {
      _ = try AddressRegistryClassifier(
        projectionLoader: { duplicateKeyData },
        expectation: AddressRegistryProjectionExpectation(data: duplicateKeyData)
      )
    }
  }

  @Test func descriptionsErrorsAndReflectionDoNotRevealCandidateOrRegistryFields() throws {
    let classifier = try AddressRegistryClassifier()
    let host = try #require(
      ValidatedURLHost(ipv4PackedAddressBytes: [203, 0, 113, 77])
    )
    let classification = classifier.classify(host)
    guard case .ip(let result) = classification else {
      Issue.record("The reserved canary must produce an IP classification.")
      return
    }
    let match = try #require(result.match)
    let errors: [AddressRegistryClassifierError] = [
      .projectionUnavailable,
      .projectionIntegrityMismatch,
      .malformedProjection,
      .incompleteProjection,
      .inconsistentProjection,
    ]
    var renderings =
      addressRegistryRenderings(classifier)
      + addressRegistryRenderings(classification)
      + addressRegistryRenderings(result)
      + addressRegistryRenderings(match)
      + addressRegistryRenderings(match.source)
      + addressRegistryRenderings(result.family)
      + addressRegistryRenderings(result.category)
    for error in errors {
      renderings += addressRegistryRenderings(error)
      renderings += addressRegistryRenderings(error as NSError)
      #expect(error.errorDescription == error.description)
    }

    let forbiddenValues = [
      host.asciiValue,
      match.prefix,
      match.name,
      match.source.identifier,
      match.source.updated,
      match.source.publicURL,
    ]
    let renderingsAreBoundedAndContentFree = renderings.allSatisfy { rendering in
      rendering.isEmpty == false
        && rendering.utf8.count <= 128
        && forbiddenValues.allSatisfy { rendering.contains($0) == false }
    }

    #expect(
      renderingsAreBoundedAndContentFree,
      "Ordinary classifier diagnostics must omit candidate and registry fields."
    )
  }

  @Test(
    "Environment-controlled deterministic address-classifier campaign",
    .timeLimit(.minutes(11))
  )
  func environmentControlledCampaign() throws {
    let duration = try #require(addressRegistryCampaignDuration())
    let oracle = try AddressRegistryCampaignOracle(data: addressRegistryProjectionData())
    let classifier = try AddressRegistryClassifier()
    let repeatClassifier = try AddressRegistryClassifier()
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: duration)
    var generator = AddressRegistryCampaignGenerator(seed: addressRegistryCampaignPublicSeed)
    var repeatGenerator = AddressRegistryCampaignGenerator(
      seed: addressRegistryCampaignPublicSeed
    )
    var iteration = 0

    repeat {
      let family: AddressRegistryIPFamily = iteration.isMultiple(of: 2) ? .ipv4 : .ipv6
      let bytes = addressRegistryCampaignBytes(family: family, using: &generator)
      let repeatedBytes = addressRegistryCampaignBytes(
        family: family,
        using: &repeatGenerator
      )
      guard bytes == repeatedBytes else {
        Issue.record("The public campaign seed must produce repeatable bytes.")
        return
      }

      let testHost: AddressRegistryTestHost =
        family == .ipv4 ? .ipv4(bytes) : .ipv6(bytes)
      let host = try #require(testHost.makeValidatedHost())
      let classification = classifier.classify(host)
      let repeatedClassification = repeatClassifier.classify(host)
      guard case .ip(let result) = classification else {
        Issue.record("A generated IP fixture must produce an IP classification.")
        return
      }
      let expected = oracle.expectedMatch(for: bytes, family: family)
      let invariantsHold =
        classification == repeatedClassification
        && result.family == family
        && result.category == (expected?.category ?? .unallocated)
        && result.sourceRevision == AddressRegistryClassifier.profileRevision
        && (result.match == nil) == (result.category == .unallocated)
        && addressRegistryCampaignMatch(result.match, equals: expected)
        && addressRegistryCampaignDiagnosticsAreContentFree(
          classifier: classifier,
          host: host,
          classification: classification,
          result: result
        )
      guard invariantsHold else {
        let familyLabel = family == .ipv4 ? "IPv4" : "IPv6"
        Issue.record(
          "Address-classifier campaign invariants failed for \(familyLabel) iteration \(iteration)."
        )
        return
      }

      iteration += 1
    } while iteration < 128 || clock.now < deadline

    #expect(iteration >= 128)
  }

  @Test(
    "Address-classifier campaign rejects invalid duration values",
    arguments: ["", " ", "invalid", "nan", "inf", "-1", "0", "0.009", "600.001"]
  )
  func campaignDurationRejectsInvalidValues(rawSeconds: String) {
    #expect(addressRegistryCampaignDuration(rawSeconds: rawSeconds) == nil)
  }

  @Test func campaignOraclePreservesIPv4MappedIPv6PrefixFamily() throws {
    let oracle = try AddressRegistryCampaignOracle(data: addressRegistryProjectionData())
    let mappedRecord = try #require(
      oracle.records.first {
        $0.family == .ipv6 && $0.name == "IPv4-mapped Address"
      }
    )

    #expect(mappedRecord.prefix == "::ffff:0:0/96")
    #expect(mappedRecord.category == .specialPurpose)
  }

  @Test func concurrentConstructionAndClassificationMatchSerialResults() async throws {
    let hosts = try addressRegistryConcurrentHosts.map { testHost in
      try #require(testHost.makeValidatedHost())
    }
    let classifier = try AddressRegistryClassifier()
    let expected = hosts.map(classifier.classify)

    let concurrentResults = try await withThrowingTaskGroup(
      of: AddressRegistryIndexedClassification.self
    ) { group in
      for iteration in 0..<32 {
        for (hostIndex, host) in hosts.enumerated() {
          group.addTask {
            let localClassifier = try AddressRegistryClassifier()
            return AddressRegistryIndexedClassification(
              iteration: iteration,
              hostIndex: hostIndex,
              classification: localClassifier.classify(host)
            )
          }
        }
      }

      var values: [AddressRegistryIndexedClassification] = []
      values.reserveCapacity(32 * hosts.count)
      for try await value in group {
        values.append(value)
      }
      return values
    }

    let resultsMatch = concurrentResults.allSatisfy { indexedResult in
      indexedResult.classification == expected[indexedResult.hostIndex]
    }
    #expect(concurrentResults.count == 32 * hosts.count)
    #expect(resultsMatch, "Concurrent classification must match the fixed serial baseline.")
  }
}

struct AddressRegistrySourceExpectation: Sendable {
  let identifier: String
  let updated: String
  let publicURL: String
}

struct AddressRegistryClassificationCase: Sendable, CustomTestStringConvertible {
  let id: String
  let host: AddressRegistryTestHost
  let family: AddressRegistryIPFamily
  let category: AddressRegistryCategory
  let prefix: String
  let name: String
  let source: AddressRegistrySourceExpectation

  var testDescription: String { id }
}

struct AddressRegistryBoundaryCase: Sendable, CustomTestStringConvertible {
  let id: String
  let host: AddressRegistryTestHost
  let family: AddressRegistryIPFamily
  let category: AddressRegistryCategory
  let prefix: String
  let sourceIdentifier: String

  var testDescription: String { id }
}

enum AddressRegistryTestHost: Sendable {
  case ipv4([UInt8])
  case ipv6([UInt8])

  func makeValidatedHost() -> ValidatedURLHost? {
    switch self {
    case .ipv4(let bytes):
      ValidatedURLHost(ipv4PackedAddressBytes: bytes)
    case .ipv6(let bytes):
      ValidatedURLHost(ipv6PackedAddressBytes: bytes)
    }
  }
}

private struct AddressRegistryIndexedClassification: Sendable {
  let iteration: Int
  let hostIndex: Int
  let classification: AddressRegistryClassification
}

private struct AddressRegistryCampaignProjection: Decodable {
  let sourceRegistries: [Source]
  let policyOverlays: [Overlay]
  let records: [Record]

  struct Source: Decodable {
    let id: String
    let kind: String
    let revision: String
    let sourceURL: String
  }

  struct Overlay: Decodable {
    let id: String
    let revision: String
    let sourceURL: String
  }

  struct Record: Decodable {
    let registryID: String
    let family: String
    let prefixLength: Int
    let networkBytesHex: String
    let name: String
    let status: String?

    private enum CodingKeys: String, CodingKey {
      case registryID = "registryId"
      case family
      case prefixLength
      case networkBytesHex
      case name
      case status
    }
  }
}

private struct AddressRegistryCampaignOracle {
  struct Record {
    let family: AddressRegistryIPFamily
    let layer: Int
    let prefixLength: Int
    let networkBytes: [UInt8]
    let category: AddressRegistryCategory
    let prefix: String
    let name: String
    let source: AddressRegistrySourceExpectation
  }

  let records: [Record]

  init(data: Data) throws {
    let projection = try JSONDecoder().decode(AddressRegistryCampaignProjection.self, from: data)
    records = try projection.records.map { projectedRecord in
      let source = projection.sourceRegistries.first { $0.id == projectedRecord.registryID }
      let overlay = projection.policyOverlays.first { $0.id == projectedRecord.registryID }
      guard (source == nil) != (overlay == nil),
        let family = addressRegistryCampaignFamily(projectedRecord.family),
        let networkBytes = addressRegistryCampaignHexBytes(projectedRecord.networkBytesHex),
        let prefix = addressRegistryCampaignRenderPrefix(
          family: family,
          networkBytes: networkBytes,
          prefixLength: projectedRecord.prefixLength
        )
      else {
        throw AddressRegistryClassifierTestError.invalidProjection
      }

      let layer: Int
      let category: AddressRegistryCategory
      if source?.kind == "special-purpose" {
        layer = 0
        category = .specialPurpose
      } else if overlay != nil {
        layer = 1
        category = .multicast
      } else if source?.kind == "address-space" {
        layer = 2
        category = try addressRegistryCampaignAddressSpaceCategory(projectedRecord)
      } else {
        throw AddressRegistryClassifierTestError.invalidProjection
      }

      return Record(
        family: family,
        layer: layer,
        prefixLength: projectedRecord.prefixLength,
        networkBytes: networkBytes,
        category: category,
        prefix: prefix,
        name: projectedRecord.name,
        source: AddressRegistrySourceExpectation(
          identifier: source?.id ?? overlay?.id ?? "",
          updated: source?.revision ?? overlay?.revision ?? "",
          publicURL: source?.sourceURL ?? overlay?.sourceURL ?? ""
        )
      )
    }
  }

  func expectedMatch(
    for bytes: [UInt8],
    family: AddressRegistryIPFamily
  ) -> Record? {
    let matching = records.filter {
      $0.family == family
        && addressRegistryCampaignPrefixContains(
          address: bytes,
          network: $0.networkBytes,
          prefixLength: $0.prefixLength
        )
    }
    for layer in 0...2 {
      if let selected = matching.filter({ $0.layer == layer }).max(by: {
        $0.prefixLength < $1.prefixLength
      }) {
        return selected
      }
    }
    return nil
  }
}

private struct AddressRegistryCampaignGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }
}

private enum AddressRegistryClassifierTestError: Error {
  case invalidProjection
  case loaderUnavailable
}

private let ipv4SpecialSource = AddressRegistrySourceExpectation(
  identifier: "iana-ipv4-special-purpose",
  updated: "2025-10-09",
  publicURL:
    "https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xml"
)

private let ipv6SpecialSource = AddressRegistrySourceExpectation(
  identifier: "iana-ipv6-special-purpose",
  updated: "2025-10-09",
  publicURL:
    "https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xml"
)

private let ipv4AddressSpaceSource = AddressRegistrySourceExpectation(
  identifier: "iana-ipv4-address-space",
  updated: "2025-10-10",
  publicURL: "https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml"
)

private let ipv6AddressSpaceSource = AddressRegistrySourceExpectation(
  identifier: "iana-ipv6-address-space",
  updated: "2025-10-23",
  publicURL: "https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml"
)

private let ipv4MulticastSource = AddressRegistrySourceExpectation(
  identifier: "hezo-ipv4-multicast-overlay",
  updated: "RFC 1112, Section 4",
  publicURL: "https://www.rfc-editor.org/rfc/rfc1112.html#section-4"
)

private let ipv6MulticastSource = AddressRegistrySourceExpectation(
  identifier: "hezo-ipv6-multicast-overlay",
  updated: "RFC 4291, Section 2.7",
  publicURL: "https://www.rfc-editor.org/rfc/rfc4291.html#section-2.7"
)

private let addressRegistrySourceCases: [AddressRegistryClassificationCase] = [
  AddressRegistryClassificationCase(
    id: "ipv4-special-purpose",
    host: .ipv4([192, 0, 2, 1]),
    family: .ipv4,
    category: .specialPurpose,
    prefix: "192.0.2.0/24",
    name: "Documentation (TEST-NET-1)",
    source: ipv4SpecialSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv6-special-purpose",
    host: .ipv6(ipv6Words(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)),
    family: .ipv6,
    category: .specialPurpose,
    prefix: "2001:db8::/32",
    name: "Documentation",
    source: ipv6SpecialSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv4-address-space",
    host: .ipv4([8, 8, 8, 8]),
    family: .ipv4,
    category: .allocatedOrLegacyIPv4,
    prefix: "8.0.0.0/8",
    name: "Administered by ARIN",
    source: ipv4AddressSpaceSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv6-global-unicast-address-space",
    host: .ipv6(ipv6Words(0x2606, 0x4700, 0, 0, 0, 0, 0, 1)),
    family: .ipv6,
    category: .globalUnicastIPv6,
    prefix: "2000::/3",
    name: "Global Unicast",
    source: ipv6AddressSpaceSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv4-multicast-overlay",
    host: .ipv4([224, 0, 0, 1]),
    family: .ipv4,
    category: .multicast,
    prefix: "224.0.0.0/4",
    name: "Multicast",
    source: ipv4MulticastSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv6-multicast-overlay",
    host: .ipv6(ipv6Words(0xFF02, 0, 0, 0, 0, 0, 0, 1)),
    family: .ipv6,
    category: .multicast,
    prefix: "ff00::/8",
    name: "Multicast",
    source: ipv6MulticastSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv6-reserved-address-space",
    host: .ipv6(ipv6Words(0x4000, 0, 0, 0, 0, 0, 0, 1)),
    family: .ipv6,
    category: .reserved,
    prefix: "4000::/3",
    name: "Reserved by IETF",
    source: ipv6AddressSpaceSource
  ),
]

private let addressRegistryLongestPrefixCases: [AddressRegistryClassificationCase] = [
  AddressRegistryClassificationCase(
    id: "ipv4-globally-reachable-special-32",
    host: .ipv4([192, 0, 0, 9]),
    family: .ipv4,
    category: .specialPurpose,
    prefix: "192.0.0.9/32",
    name: "Port Control Protocol Anycast",
    source: ipv4SpecialSource
  ),
  AddressRegistryClassificationCase(
    id: "ipv6-globally-reachable-special-128",
    host: .ipv6(ipv6Words(0x2001, 1, 0, 0, 0, 0, 0, 1)),
    family: .ipv6,
    category: .specialPurpose,
    prefix: "2001:1::1/128",
    name: "Port Control Protocol Anycast",
    source: ipv6SpecialSource
  ),
]

private let addressRegistryBoundaryCases: [AddressRegistryBoundaryCase] = [
  AddressRegistryBoundaryCase(
    id: "before-ipv4-shared-space",
    host: .ipv4([100, 63, 255, 255]),
    family: .ipv4,
    category: .allocatedOrLegacyIPv4,
    prefix: "100.0.0.0/8",
    sourceIdentifier: "iana-ipv4-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "first-ipv4-shared-space",
    host: .ipv4([100, 64, 0, 0]),
    family: .ipv4,
    category: .specialPurpose,
    prefix: "100.64.0.0/10",
    sourceIdentifier: "iana-ipv4-special-purpose"
  ),
  AddressRegistryBoundaryCase(
    id: "last-ipv4-shared-space",
    host: .ipv4([100, 127, 255, 255]),
    family: .ipv4,
    category: .specialPurpose,
    prefix: "100.64.0.0/10",
    sourceIdentifier: "iana-ipv4-special-purpose"
  ),
  AddressRegistryBoundaryCase(
    id: "after-ipv4-shared-space",
    host: .ipv4([100, 128, 0, 0]),
    family: .ipv4,
    category: .allocatedOrLegacyIPv4,
    prefix: "100.0.0.0/8",
    sourceIdentifier: "iana-ipv4-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "before-ipv4-multicast",
    host: .ipv4([223, 255, 255, 255]),
    family: .ipv4,
    category: .allocatedOrLegacyIPv4,
    prefix: "223.0.0.0/8",
    sourceIdentifier: "iana-ipv4-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "first-ipv4-multicast",
    host: .ipv4([224, 0, 0, 0]),
    family: .ipv4,
    category: .multicast,
    prefix: "224.0.0.0/4",
    sourceIdentifier: "hezo-ipv4-multicast-overlay"
  ),
  AddressRegistryBoundaryCase(
    id: "last-ipv4-multicast",
    host: .ipv4([239, 255, 255, 255]),
    family: .ipv4,
    category: .multicast,
    prefix: "224.0.0.0/4",
    sourceIdentifier: "hezo-ipv4-multicast-overlay"
  ),
  AddressRegistryBoundaryCase(
    id: "after-ipv4-multicast",
    host: .ipv4([240, 0, 0, 0]),
    family: .ipv4,
    category: .specialPurpose,
    prefix: "240.0.0.0/4",
    sourceIdentifier: "iana-ipv4-special-purpose"
  ),
  AddressRegistryBoundaryCase(
    id: "before-ipv6-documentation",
    host: .ipv6(ipv6Words(0x2001, 0x0DB7, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF)),
    family: .ipv6,
    category: .globalUnicastIPv6,
    prefix: "2000::/3",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "first-ipv6-documentation",
    host: .ipv6(ipv6Words(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 0)),
    family: .ipv6,
    category: .specialPurpose,
    prefix: "2001:db8::/32",
    sourceIdentifier: "iana-ipv6-special-purpose"
  ),
  AddressRegistryBoundaryCase(
    id: "last-ipv6-documentation",
    host: .ipv6(
      ipv6Words(0x2001, 0x0DB8, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF)
    ),
    family: .ipv6,
    category: .specialPurpose,
    prefix: "2001:db8::/32",
    sourceIdentifier: "iana-ipv6-special-purpose"
  ),
  AddressRegistryBoundaryCase(
    id: "after-ipv6-documentation",
    host: .ipv6(ipv6Words(0x2001, 0x0DB9, 0, 0, 0, 0, 0, 0)),
    family: .ipv6,
    category: .globalUnicastIPv6,
    prefix: "2000::/3",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "before-ipv6-global-unicast",
    host: .ipv6(
      ipv6Words(0x1FFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF)
    ),
    family: .ipv6,
    category: .reserved,
    prefix: "1000::/4",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "first-ipv6-global-unicast",
    host: .ipv6(ipv6Words(0x2000, 0, 0, 0, 0, 0, 0, 0)),
    family: .ipv6,
    category: .globalUnicastIPv6,
    prefix: "2000::/3",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "last-ipv6-global-unicast",
    host: .ipv6(
      ipv6Words(0x3FFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF)
    ),
    family: .ipv6,
    category: .globalUnicastIPv6,
    prefix: "2000::/3",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "after-ipv6-global-unicast",
    host: .ipv6(ipv6Words(0x4000, 0, 0, 0, 0, 0, 0, 0)),
    family: .ipv6,
    category: .reserved,
    prefix: "4000::/3",
    sourceIdentifier: "iana-ipv6-address-space"
  ),
  AddressRegistryBoundaryCase(
    id: "first-ipv6-multicast",
    host: .ipv6(ipv6Words(0xFF00, 0, 0, 0, 0, 0, 0, 0)),
    family: .ipv6,
    category: .multicast,
    prefix: "ff00::/8",
    sourceIdentifier: "hezo-ipv6-multicast-overlay"
  ),
  AddressRegistryBoundaryCase(
    id: "last-ipv6-multicast",
    host: .ipv6(
      ipv6Words(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF)
    ),
    family: .ipv6,
    category: .multicast,
    prefix: "ff00::/8",
    sourceIdentifier: "hezo-ipv6-multicast-overlay"
  ),
]

private let addressRegistryConcurrentHosts: [AddressRegistryTestHost] = [
  .ipv4([8, 8, 8, 8]),
  .ipv4([10, 0, 0, 1]),
  .ipv4([224, 0, 0, 1]),
  .ipv6(ipv6Words(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)),
  .ipv6(ipv6Words(0x2606, 0x4700, 0, 0, 0, 0, 0, 1)),
  .ipv6(ipv6Words(0x4000, 0, 0, 0, 0, 0, 0, 1)),
  .ipv6(ipv6Words(0xFF02, 0, 0, 0, 0, 0, 0, 1)),
]

private let addressRegistryBundledExpectation = AddressRegistryProjectionExpectation(
  byteCount: AddressRegistryClassifier.projectionByteCount,
  sha256: AddressRegistryClassifier.projectionSHA256
)

private let addressRegistryCampaignPublicSeed: UInt64 = 0x4144_4452_5F46_555A

private let addressRegistryRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func ipv6Words(
  _ word0: UInt16,
  _ word1: UInt16,
  _ word2: UInt16,
  _ word3: UInt16,
  _ word4: UInt16,
  _ word5: UInt16,
  _ word6: UInt16,
  _ word7: UInt16
) -> [UInt8] {
  [word0, word1, word2, word3, word4, word5, word6, word7].flatMap { word in
    [UInt8(word >> 8), UInt8(word & 0xFF)]
  }
}

private func addressRegistryCategoryMarker(_ category: AddressRegistryCategory) -> Int {
  switch category {
  case .specialPurpose:
    0
  case .allocatedOrLegacyIPv4:
    1
  case .globalUnicastIPv6:
    2
  case .multicast:
    3
  case .reserved:
    4
  case .unallocated:
    5
  }
}

private func addressRegistryProjectionData() throws -> Data {
  try Data(
    contentsOf: addressRegistryRepositoryRoot.appendingPathComponent(
      "Sources/HezoLinkCore/Resources/AddressRegistry/iana-address-profile-v1.json"
    )
  )
}

private func addressRegistryCampaignDuration() -> Duration? {
  let rawSeconds =
    ProcessInfo.processInfo.environment["HEZOLINK_ADDRESS_FUZZ_SECONDS"] ?? "0.2"
  return addressRegistryCampaignDuration(rawSeconds: rawSeconds)
}

private func addressRegistryCampaignDuration(rawSeconds: String) -> Duration? {
  guard let seconds = Double(rawSeconds), seconds.isFinite, (0.01...600).contains(seconds)
  else {
    return nil
  }
  return .milliseconds(Int64((seconds * 1_000).rounded(.up)))
}

private func addressRegistryCampaignBytes(
  family: AddressRegistryIPFamily,
  using generator: inout AddressRegistryCampaignGenerator
) -> [UInt8] {
  let byteCount = family == .ipv4 ? 4 : 16
  var result: [UInt8] = []
  result.reserveCapacity(byteCount)
  while result.count < byteCount {
    var value = generator.next()
    for _ in 0..<8 where result.count < byteCount {
      result.append(UInt8(truncatingIfNeeded: value))
      value >>= 8
    }
  }

  if family == .ipv6,
    result[0..<10].allSatisfy({ $0 == 0 }),
    result[10] == 0xFF,
    result[11] == 0xFF
  {
    result[0] = 1
  }
  return result
}

private func addressRegistryCampaignFamily(_ value: String) -> AddressRegistryIPFamily? {
  switch value {
  case "ipv4":
    .ipv4
  case "ipv6":
    .ipv6
  default:
    nil
  }
}

private func addressRegistryCampaignAddressSpaceCategory(
  _ record: AddressRegistryCampaignProjection.Record
) throws -> AddressRegistryCategory {
  switch record.family {
  case "ipv4":
    switch record.status {
    case "ALLOCATED", "LEGACY":
      return .allocatedOrLegacyIPv4
    case "RESERVED":
      return .reserved
    default:
      throw AddressRegistryClassifierTestError.invalidProjection
    }
  case "ipv6":
    switch record.name {
    case "Global Unicast":
      return .globalUnicastIPv6
    case "Multicast":
      return .multicast
    case "Reserved by IETF", "Unique Local Unicast", "Link-Scoped Unicast":
      return .reserved
    default:
      throw AddressRegistryClassifierTestError.invalidProjection
    }
  default:
    throw AddressRegistryClassifierTestError.invalidProjection
  }
}

private func addressRegistryCampaignHexBytes(_ value: String) -> [UInt8]? {
  let encoded = Array(value.utf8)
  guard encoded.isEmpty == false, encoded.count.isMultiple(of: 2) else { return nil }
  var result: [UInt8] = []
  result.reserveCapacity(encoded.count / 2)
  for index in stride(from: 0, to: encoded.count, by: 2) {
    guard let high = addressRegistryCampaignHexNibble(encoded[index]),
      let low = addressRegistryCampaignHexNibble(encoded[index + 1])
    else {
      return nil
    }
    result.append((high << 4) | low)
  }
  return result
}

private func addressRegistryCampaignHexNibble(_ value: UInt8) -> UInt8? {
  switch value {
  case 0x30...0x39:
    value - 0x30
  case 0x61...0x66:
    value - 0x61 + 10
  default:
    nil
  }
}

private func addressRegistryCampaignRenderPrefix(
  family: AddressRegistryIPFamily,
  networkBytes: [UInt8],
  prefixLength: Int
) -> String? {
  let address: String
  switch family {
  case .ipv4:
    guard networkBytes.count == 4, (0...32).contains(prefixLength) else { return nil }
    address = networkBytes.map(String.init).joined(separator: ".")
  case .ipv6:
    guard networkBytes.count == 16, (0...128).contains(prefixLength) else { return nil }
    address = addressRegistryCampaignRenderIPv6(networkBytes)
  }
  return "\(address)/\(prefixLength)"
}

private func addressRegistryCampaignRenderIPv6(_ bytes: [UInt8]) -> String {
  let words = stride(from: 0, to: bytes.count, by: 2).map { index in
    (UInt16(bytes[index]) << 8) | UInt16(bytes[index + 1])
  }
  var longestZeroRunStart: Int?
  var longestZeroRunLength = 0
  var index = 0
  while index < words.count {
    guard words[index] == 0 else {
      index += 1
      continue
    }
    let runStart = index
    while index < words.count, words[index] == 0 {
      index += 1
    }
    let runLength = index - runStart
    if runLength >= 2, runLength > longestZeroRunLength {
      longestZeroRunStart = runStart
      longestZeroRunLength = runLength
    }
  }

  guard let longestZeroRunStart else {
    return words.map { String($0, radix: 16) }.joined(separator: ":")
  }
  let prefix = words[..<longestZeroRunStart]
    .map { String($0, radix: 16) }
    .joined(separator: ":")
  let suffixStart = longestZeroRunStart + longestZeroRunLength
  let suffix = words[suffixStart...]
    .map { String($0, radix: 16) }
    .joined(separator: ":")
  if prefix.isEmpty, suffix.isEmpty { return "::" }
  if prefix.isEmpty { return "::\(suffix)" }
  if suffix.isEmpty { return "\(prefix)::" }
  return "\(prefix)::\(suffix)"
}

private func addressRegistryCampaignPrefixContains(
  address: [UInt8],
  network: [UInt8],
  prefixLength: Int
) -> Bool {
  guard address.count == network.count, (0...(network.count * 8)).contains(prefixLength) else {
    return false
  }
  let wholeBytes = prefixLength / 8
  if wholeBytes > 0, address[..<wholeBytes] != network[..<wholeBytes] { return false }
  let remainingBits = prefixLength % 8
  guard remainingBits > 0 else { return true }
  let mask = UInt8.max << UInt8(8 - remainingBits)
  return address[wholeBytes] & mask == network[wholeBytes] & mask
}

private func addressRegistryCampaignMatch(
  _ actual: AddressRegistryMatch?,
  equals expected: AddressRegistryCampaignOracle.Record?
) -> Bool {
  switch (actual, expected) {
  case (nil, nil):
    return true
  case (.some(let actual), .some(let expected)):
    return actual.prefix == expected.prefix
      && actual.name == expected.name
      && actual.source.identifier == expected.source.identifier
      && actual.source.updated == expected.source.updated
      && actual.source.publicURL == expected.source.publicURL
  default:
    return false
  }
}

private func addressRegistryCampaignDiagnosticsAreContentFree(
  classifier: AddressRegistryClassifier,
  host: ValidatedURLHost,
  classification: AddressRegistryClassification,
  result: AddressRegistryIPClassification
) -> Bool {
  guard
    addressRegistryCampaignHasExactRendering(
      classifier,
      expected: "Pinned offline address-registry classifier."
    ),
    addressRegistryCampaignHasExactRendering(
      host,
      expected: LogSafeURLRedactor.replacement
    ),
    addressRegistryCampaignHasExactRendering(
      classification,
      expected: "An IP literal has a pinned address classification."
    ),
    addressRegistryCampaignHasExactRendering(
      result,
      expected: "Pinned IP address classification."
    ),
    addressRegistryCampaignHasExactRendering(
      result.family,
      expected: result.family.description
    ),
    addressRegistryCampaignHasExactRendering(
      result.category,
      expected: result.category.description
    )
  else {
    return false
  }

  guard let match = result.match else { return true }
  return addressRegistryCampaignHasExactRendering(
    match,
    expected: "Pinned address-registry match."
  )
    && addressRegistryCampaignHasExactRendering(
      match.source,
      expected: "Pinned address-registry source."
    )
}

private func addressRegistryCampaignHasExactRendering<T>(
  _ value: T,
  expected: String
) -> Bool {
  addressRegistryRenderings(value) == Array(repeating: expected, count: 3)
}

private func mutatedAddressRegistryProjection(
  _ mutation: (inout [String: Any]) throws -> Void
) throws -> Data {
  let data = try addressRegistryProjectionData()
  guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw AddressRegistryClassifierTestError.invalidProjection
  }
  try mutation(&object)
  return try JSONSerialization.data(
    withJSONObject: object,
    options: [.sortedKeys, .withoutEscapingSlashes]
  )
}

private func requireAddressRegistryRecords(_ object: [String: Any]) throws -> [[String: Any]] {
  guard let records = object["records"] as? [[String: Any]] else {
    throw AddressRegistryClassifierTestError.invalidProjection
  }
  return records
}

private func mutateAddressSpacePrefix(
  in object: inout [String: Any],
  registryID: String,
  sourceRecordIndex: Int,
  prefixLength: Int
) throws {
  var records = try requireAddressRegistryRecords(object)
  guard
    let recordIndex = records.firstIndex(where: { record in
      record["registryId"] as? String == registryID
        && record["sourceRecordIndex"] as? Int == sourceRecordIndex
    })
  else {
    throw AddressRegistryClassifierTestError.invalidProjection
  }
  records[recordIndex]["prefixLength"] = prefixLength
  object["records"] = records
}

private func addressRegistryRenderings<T>(_ value: T) -> [String] {
  [
    String(describing: value),
    String(reflecting: value),
  ] + Mirror(reflecting: value).children.map { String(describing: $0.value) }
}
