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
