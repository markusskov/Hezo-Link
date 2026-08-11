import Foundation
import Testing

@testable import HezoLinkCore

struct URLPolicyIDNAOracleTests {
  private static let corpusPath =
    "packages/url-policy-oracles/upstream/unicode/IdnaTestV2-17.0.0.txt"

  @Test func everyUnicode17ToASCIINCaseIsParsedAndEnforcedFailClosed() throws {
    try verifyURLPolicyOraclePackage()
    let cases = try loadURLPolicyIDNACases(Self.corpusPath)
    try #require(cases.count == 6_391)
    try #require(Set(cases.map(\.lineNumber)).count == cases.count)

    let validator = ManualURLInputValidator.isolatedTestFixture
    var invalidCaseCount = 0
    var invalidRejectionCount = 0
    var acceptedValidCaseCount = 0
    var acceptedValidAgreementCount = 0

    for testCase in cases {
      let input = "https://\(testCase.source).idna.test/oracle?raw=1#fragment"
      let outcome = validator.validate(input)

      if testCase.expectsToASCIIRejection {
        invalidCaseCount += 1
        guard case .rejected = outcome else {
          Issue.record(
            "Unicode 17 invalid toASCII-N input was accepted at source line \(testCase.lineNumber)."
          )
          continue
        }
        invalidRejectionCount += 1
        continue
      }

      guard case .accepted(let value) = outcome else {
        continue
      }
      acceptedValidCaseCount += 1
      let expectedHost = "\(testCase.expectedASCII).idna.test".lowercased()
      let agreesWithOracle =
        value.scheme == .https
        && value.asciiHost == expectedHost
        && value.effectivePort == 443
        && value.rawPercentEncodedPath == "/oracle"
        && value.rawPercentEncodedQuery == "raw=1"
        && value.rawPercentEncodedFragment == "fragment"
        && value.submittedURL.rawValue.utf8.elementsEqual(input.utf8)
      if agreesWithOracle {
        acceptedValidAgreementCount += 1
      } else {
        Issue.record(
          "Accepted Unicode 17 input disagreed with toASCII-N at source line \(testCase.lineNumber)."
        )
      }
    }

    #expect(invalidCaseCount == 5_842)
    #expect(invalidRejectionCount == 5_842)
    #expect(acceptedValidCaseCount == 276)
    #expect(acceptedValidAgreementCount == 276)
  }

  @Test func frozenPositiveAndNegativeIDNAAnchorsCannotDisappearOrChangeMeaning() throws {
    try verifyURLPolicyOraclePackage()
    let cases = try loadURLPolicyIDNACases(Self.corpusPath)
    let validator = ManualURLInputValidator.isolatedTestFixture
    let positiveAnchors = [
      IDNAAnchor(id: "ascii-case-fold", rawSource: "fass.de", expectedASCII: "fass.de"),
      IDNAAnchor(id: "sharp-s", rawSource: "faß.de", expectedASCII: "xn--fa-hia.de"),
      IDNAAnchor(
        id: "latin-punycode",
        rawSource: "Bücher.de",
        expectedASCII: "xn--bcher-kva.de"
      ),
      IDNAAnchor(
        id: "cjk-punycode",
        rawSource: "日本語.jp",
        expectedASCII: "xn--wgv71a119e.jp"
      ),
    ]
    let negativeAnchors = [
      IDNANegativeAnchor(id: "empty", rawSource: "\"\""),
      IDNANegativeAnchor(id: "root-dot", rawSource: "."),
      IDNANegativeAnchor(id: "empty-interior-label", rawSource: "a..b"),
      IDNANegativeAnchor(id: "empty-punycode", rawSource: "xn--"),
      IDNANegativeAnchor(id: "v2-double-hyphen", rawSource: "a.bc--de.f"),
      IDNANegativeAnchor(
        id: "v3-punycode-trailing-hyphen",
        rawSource: "xn--ej0b.xn----d87b"
      ),
      IDNANegativeAnchor(id: "unpaired-surrogate", rawSource: "a\\uD900z"),
    ]

    for anchor in positiveAnchors {
      let matches = cases.filter { $0.rawSource == anchor.rawSource }
      let testCase = try #require(matches.first, "Missing frozen IDNA anchor \(anchor.id).")
      try #require(matches.count == 1, "Duplicate frozen IDNA anchor \(anchor.id).")
      try #require(testCase.expectsToASCIIRejection == false)
      try #require(testCase.expectedASCII == anchor.expectedASCII)
      let input = "https://\(testCase.source).idna.test/oracle"
      guard case .accepted(let value) = validator.validate(input) else {
        Issue.record("Frozen positive IDNA anchor \(anchor.id) was rejected.")
        continue
      }
      #expect(value.asciiHost == "\(anchor.expectedASCII).idna.test")
    }

    for anchor in negativeAnchors {
      let matches = cases.filter { $0.rawSource == anchor.rawSource }
      let testCase = try #require(matches.first, "Missing frozen IDNA anchor \(anchor.id).")
      try #require(matches.count == 1, "Duplicate frozen IDNA anchor \(anchor.id).")
      try #require(testCase.expectsToASCIIRejection)
      let input = "https://\(testCase.source).idna.test/oracle"
      guard case .rejected = validator.validate(input) else {
        Issue.record("Frozen negative IDNA anchor \(anchor.id) was accepted.")
        continue
      }
    }
  }
}

struct URLPolicyWPTOracleTests {
  private static let corpusPath =
    "packages/url-policy-oracles/upstream/wpt/urltestdata-eb7aa8a1.json"

  @Test func everyAbsoluteHTTPWPTCaseFailsClosedOrMatchesSecurityComponents() throws {
    try verifyURLPolicyOraclePackage()
    let corpus = try loadURLPolicyWPTCorpus(Self.corpusPath)
    try #require(corpus.comments.count == 113)
    try #require(corpus.cases.count == 891)
    try #require(corpus.comments.count + corpus.cases.count == 1_004)
    try #require(Set(corpus.cases.map(\.sourceIndex)).count == corpus.cases.count)

    let absoluteCases = corpus.cases.filter { isAbsoluteWPTWebURL($0.input) }
    try #require(absoluteCases.count == 390)
    try #require(absoluteCases.filter(\.expectsFailure).count == 198)
    try #require(absoluteCases.filter { $0.expectsFailure == false }.count == 192)
    let validator = ManualURLInputValidator()
    var counts = WPTObservationCounts()

    for testCase in absoluteCases {
      counts.record(try observeWPTCase(testCase, validator: validator))
    }

    #expect(counts.invalidRejections == 198)
    #expect(counts.acceptedValid == 17)
    #expect(counts.agreedValid == 17)
  }

  @Test func frozenPositiveAndNegativeWPTAnchorsCannotDisappearOrChangeMeaning() throws {
    try verifyURLPolicyOraclePackage()
    let corpus = try loadURLPolicyWPTCorpus(Self.corpusPath)
    let validator = ManualURLInputValidator()
    let positiveAnchors = [
      WPTPositiveAnchor(
        id: "ordinary-domain",
        input: "http://www.google.com",
        scheme: .http,
        host: "www.google.com",
        effectivePort: 80
      ),
      WPTPositiveAnchor(
        id: "non-reserved-domain",
        input: "http://www.example2.com",
        scheme: .http,
        host: "www.example2.com",
        effectivePort: 80
      ),
      WPTPositiveAnchor(
        id: "canonical-ipv4",
        input: "http://1.2.3.4/",
        scheme: .http,
        host: "1.2.3.4",
        effectivePort: 80
      ),
      WPTPositiveAnchor(
        id: "explicit-port",
        input: "http://127.0.0.1:10100/relative_import.html",
        scheme: .http,
        host: "127.0.0.1",
        effectivePort: 10_100
      ),
      WPTPositiveAnchor(
        id: "dotted-tail-ipv6",
        input: "http://[::127.0.0.1]",
        scheme: .http,
        host: "::7f00:1",
        effectivePort: 80
      ),
    ]
    let negativeAnchors = [
      WPTNegativeAnchor(id: "text-port", input: "http://f:b/c"),
      WPTNegativeAnchor(id: "extra-ipv6-port", input: "http://[1::2]:3:4"),
      WPTNegativeAnchor(id: "unbracketed-ipv6", input: "http://2001::1"),
      WPTNegativeAnchor(id: "malformed-percent-host", input: "http://%25"),
      WPTNegativeAnchor(id: "numeric-final-label", input: "http://foo.09"),
      WPTNegativeAnchor(id: "empty-hex-final-label", input: "http://foo.0x"),
    ]

    for anchor in positiveAnchors {
      let matches = corpus.cases.filter { $0.input == anchor.input }
      let testCase = try #require(matches.first, "Missing frozen WPT anchor \(anchor.id).")
      try #require(matches.count == 1, "Duplicate frozen WPT anchor \(anchor.id).")
      try #require(testCase.expectsFailure == false)
      guard case .accepted(let value) = validator.validate(anchor.input) else {
        Issue.record("Frozen positive WPT anchor \(anchor.id) was rejected.")
        continue
      }
      let matchesExpected =
        value.scheme == anchor.scheme
        && value.asciiHost == anchor.host
        && value.effectivePort == anchor.effectivePort
      #expect(matchesExpected, "Frozen positive WPT anchor \(anchor.id) changed meaning.")
    }

    for anchor in negativeAnchors {
      let matches = corpus.cases.filter { $0.input == anchor.input }
      let testCase = try #require(matches.first, "Missing frozen WPT anchor \(anchor.id).")
      try #require(matches.count == 1, "Duplicate frozen WPT anchor \(anchor.id).")
      try #require(testCase.expectsFailure)
      guard case .rejected = validator.validate(anchor.input) else {
        Issue.record("Frozen negative WPT anchor \(anchor.id) was accepted.")
        continue
      }
    }
  }
}

struct URLPolicyRFCAddressOracleTests {
  private static let fixturePath =
    "packages/url-policy-oracles/cases/address-policy-cases-v1.json"

  @Test func everyRFCAddressPayloadCaseExecutesExactlyOnce() throws {
    try verifyURLPolicyOraclePackage()
    let fixture = try loadURLPolicyAddressFixture(Self.fixturePath)
    let expectedCategoryCounts = [
      "canonical-ipv4": 3,
      "alternate-ipv4-rejection": 12,
      "ipv6-rfc5952-normalization": 7,
      "ipv4-mapped-ipv6": 3,
      "nat64": 2,
      "6to4": 2,
      "teredo": 2,
      "malformed-ipv6-rejection": 8,
      "zone-identifier-rejection": 3,
    ]
    let expectedIDs = Set((1...42).map { String(format: "ADDR-%03d", $0) })

    try verifyAddressFixtureMetadata(
      fixture,
      expectedCategoryCounts: expectedCategoryCounts,
      expectedIDs: expectedIDs
    )

    let validator = ManualURLInputValidator()
    var executedIDs: Set<String> = []
    for testCase in fixture.cases {
      try #require(executedIDs.insert(testCase.id).inserted)
      try #require(testCase.rfcReferences.isEmpty == false)
      try #require(testCase.rationale.isEmpty == false)
      try verifyAddressCase(testCase, validator: validator)
    }

    #expect(executedIDs == expectedIDs)
  }
}

private struct WPTObservationCounts {
  var invalidRejections = 0
  var acceptedValid = 0
  var agreedValid = 0

  mutating func record(_ observation: WPTObservationCounts) {
    invalidRejections += observation.invalidRejections
    acceptedValid += observation.acceptedValid
    agreedValid += observation.agreedValid
  }
}

private func observeWPTCase(
  _ testCase: URLPolicyWPTCase,
  validator: ManualURLInputValidator
) throws -> WPTObservationCounts {
  let outcome = validator.validate(testCase.input)
  if testCase.expectsFailure {
    guard case .rejected = outcome else {
      Issue.record(
        "WPT-invalid absolute HTTP(S) input was accepted at corpus index \(testCase.sourceIndex)."
      )
      return WPTObservationCounts()
    }
    return WPTObservationCounts(invalidRejections: 1)
  }

  guard case .accepted(let value) = outcome else {
    return WPTObservationCounts()
  }
  let expectedScheme = try #require(
    webScheme(forWPTProtocol: testCase.protocolName),
    "Accepted WPT case lacks a web protocol at corpus index \(testCase.sourceIndex)."
  )
  let expectedHost = try #require(
    normalizedWPTHostname(testCase.hostname),
    "Accepted WPT case lacks a hostname at corpus index \(testCase.sourceIndex)."
  )
  let expectedPort = try #require(
    effectiveWPTPort(testCase.port, scheme: expectedScheme),
    "Accepted WPT case has an invalid port at corpus index \(testCase.sourceIndex)."
  )
  let rawComponents = try #require(
    rawOracleComponents(of: testCase.input),
    "Accepted WPT case lacks raw components at corpus index \(testCase.sourceIndex)."
  )
  let agreesWithOracle =
    value.scheme == expectedScheme
    && value.asciiHost == expectedHost
    && value.effectivePort == expectedPort
    && value.submittedURL.rawValue.utf8.elementsEqual(testCase.input.utf8)
    && value.rawPercentEncodedPath == rawComponents.path
    && value.rawPercentEncodedQuery == rawComponents.query
    && value.rawPercentEncodedFragment == rawComponents.fragment
  guard agreesWithOracle else {
    Issue.record(
      "Accepted WPT input disagreed on scheme, host, port, or raw components at corpus index \(testCase.sourceIndex)."
    )
    return WPTObservationCounts(acceptedValid: 1)
  }
  return WPTObservationCounts(acceptedValid: 1, agreedValid: 1)
}

private func verifyAddressFixtureMetadata(
  _ fixture: URLPolicyAddressFixture,
  expectedCategoryCounts: [String: Int],
  expectedIDs: Set<String>
) throws {
  try #require(fixture.schemaVersion == 1)
  try #require(ManualURLInputValidator.syntaxProfileVersion == 2)
  try #require(fixture.fixtureId == "hezo-url-address-policy-v1")
  try #require(fixture.policyScope == "manual-url-syntax-profile-2-address-literals")
  try #require(fixture.safety.executionBoundary == "offline-only")
  try #require(fixture.safety.networkAccessPermitted == false)
  try #require(fixture.safety.operationalUsePermitted == false)
  try #require(fixture.safety.containsCapturedInputs == false)
  try #require(fixture.safety.containsOperationalInputs == false)
  try #require(fixture.safety.containsPotentiallyResolvableNames == false)
  try #require(fixture.safety.containsSecrets == false)
  try #require(fixture.categoryCounts == expectedCategoryCounts)
  try #require(fixture.cases.count == 42)
  try #require(Set(fixture.cases.map(\.id)) == expectedIDs)
  try #require(Set(fixture.cases.map(\.id)).count == fixture.cases.count)
  try #require(fixture.cases.filter { $0.expected.outcome == "accepted" }.count == 18)
  try #require(fixture.cases.filter { $0.expected.outcome == "rejected" }.count == 24)
  try #require(
    Dictionary(grouping: fixture.cases, by: \.category).mapValues(\.count)
      == expectedCategoryCounts
  )
}

private func verifyAddressCase(
  _ testCase: URLPolicyAddressFixture.Case,
  validator: ManualURLInputValidator
) throws {
  let outcome = validator.validate(testCase.inputURL)
  switch testCase.expected.outcome {
  case "accepted":
    try verifyAcceptedAddressCase(testCase, outcome: outcome)
  case "rejected":
    try verifyRejectedAddressCase(testCase, outcome: outcome)
  default:
    Issue.record("RFC address case \(testCase.id) has an unknown expected outcome.")
  }
}

private func verifyAcceptedAddressCase(
  _ testCase: URLPolicyAddressFixture.Case,
  outcome: ManualURLInputValidation
) throws {
  let normalizedHost = try #require(testCase.expected.normalizedHost)
  try #require(testCase.expected.addressFamily != nil)
  try #require(testCase.expected.mechanism != nil)
  try #require(
    expectedNormalizationBasis(for: testCase) == testCase.expected.normalizationBasis
  )
  try #require(testCase.expected.isIPLiteral == true)
  try #require(testCase.expected.reason == nil)
  guard case .accepted(let value) = outcome else {
    Issue.record("RFC address case \(testCase.id) was unexpectedly rejected.")
    return
  }
  let matchesExpected =
    value.syntaxProfileVersion == 2
    && value.scheme == .https
    && value.asciiHost == normalizedHost
    && value.explicitPort == nil
    && value.effectivePort == 443
    && value.rawPercentEncodedPath == "/oracle"
    && value.rawPercentEncodedQuery == nil
    && value.rawPercentEncodedFragment == nil
    && value.submittedURL.rawValue.utf8.elementsEqual(testCase.inputURL.utf8)
  #expect(matchesExpected, "RFC address case \(testCase.id) changed decomposition.")
}

private func verifyRejectedAddressCase(
  _ testCase: URLPolicyAddressFixture.Case,
  outcome: ManualURLInputValidation
) throws {
  try #require(testCase.expected.reason != nil)
  try #require(testCase.expected.normalizedHost == nil)
  try #require(testCase.expected.normalizationBasis == nil)
  guard case .rejected(let problem) = outcome else {
    Issue.record("RFC address case \(testCase.id) was unexpectedly accepted.")
    return
  }
  #expect(problem == .invalidURL)
}

private func expectedNormalizationBasis(
  for testCase: URLPolicyAddressFixture.Case
) -> String? {
  switch testCase.category {
  case "canonical-ipv4":
    "rfc3986-ipv4"
  case "ipv4-mapped-ipv6":
    "hezo-profile-2-ipv4-mapped-policy-identity"
  case "nat64":
    "hezo-profile-2-ipv6-rendering"
  case "ipv6-rfc5952-normalization", "6to4", "teredo":
    "rfc5952-ipv6"
  default:
    nil
  }
}

private struct IDNAAnchor: Sendable {
  let id: String
  let rawSource: String
  let expectedASCII: String
}

private struct IDNANegativeAnchor: Sendable {
  let id: String
  let rawSource: String
}

private struct WPTPositiveAnchor: Sendable {
  let id: String
  let input: String
  let scheme: WebScheme
  let host: String
  let effectivePort: UInt16
}

private struct WPTNegativeAnchor: Sendable {
  let id: String
  let input: String
}

private func webScheme(forWPTProtocol protocolName: String?) -> WebScheme? {
  switch protocolName {
  case "http:":
    .http
  case "https:":
    .https
  default:
    nil
  }
}

private func normalizedWPTHostname(_ hostname: String?) -> String? {
  guard let hostname, hostname.isEmpty == false else {
    return nil
  }
  if hostname.hasPrefix("["), hostname.hasSuffix("]") {
    return String(hostname.dropFirst().dropLast()).lowercased()
  }
  return hostname.lowercased()
}

private func effectiveWPTPort(_ rawPort: String?, scheme: WebScheme) -> UInt16? {
  guard let rawPort else {
    return nil
  }
  if rawPort.isEmpty {
    return scheme.defaultPort
  }
  return UInt16(rawPort)
}

private func rawOracleComponents(
  of input: String
) -> (path: String, query: String?, fragment: String?)? {
  guard let schemeDelimiter = input.firstIndex(of: ":") else {
    return nil
  }
  let afterScheme = input.index(after: schemeDelimiter)
  guard input[afterScheme...].hasPrefix("//") else {
    return nil
  }
  let authorityStart = input.index(afterScheme, offsetBy: 2)
  let authorityEnd =
    input[authorityStart...].firstIndex { character in
      character == "/" || character == "?" || character == "#"
    } ?? input.endIndex
  let suffix = String(input[authorityEnd...])
  let fragmentDelimiter = suffix.firstIndex(of: "#")
  let beforeFragment = fragmentDelimiter.map { String(suffix[..<$0]) } ?? suffix
  let fragment = fragmentDelimiter.map { String(suffix[suffix.index(after: $0)...]) }
  let queryDelimiter = beforeFragment.firstIndex(of: "?")
  let path = queryDelimiter.map { String(beforeFragment[..<$0]) } ?? beforeFragment
  let query = queryDelimiter.map {
    String(beforeFragment[beforeFragment.index(after: $0)...])
  }
  return (path, query, fragment)
}
