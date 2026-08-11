import Foundation
import Testing

@testable import HezoLinkCore

struct URLPolicyPropertyTests {
  @Test func fixedSeedInputsHaveStableOverloadsAndIdempotentDecomposition() throws {
    var generator = URLPolicySplitMix64(seed: 0x4845_5A4F_4C49_4E4B)
    let validator = ManualURLInputValidator.isolatedTestFixture

    for iteration in 0..<2_048 {
      let input = makeGeneratedURL(using: &generator)
      try verifyUniversalProperties(
        input,
        validator: validator,
        caseID: "fixed-seed-\(iteration)"
      )
    }
  }

  @Test(
    "Single-axis percent, control, bracket, and address mutations fail closed",
    arguments: URLPolicyMutationFixtures.rejectedCases
  )
  func securityMutationsReject(testCase: SafeURLCase<ManualURLInputProblem>) {
    let outcome = ManualURLInputValidator.isolatedTestFixture.validate(testCase.input)
    guard case .rejected(let problem) = outcome else {
      Issue.record("The named security mutation must be rejected without revealing its payload.")
      return
    }

    #expect(problem == testCase.expected)
  }

  @Test(
    "Dotted IPv4 tails use one canonical hexadecimal IPv6 host",
    arguments: [
      SafeURLCase("compatible-tail", input: "http://[::127.0.0.1]", expected: "::7f00:1"),
      SafeURLCase(
        "expanded-tail",
        input: "http://[0:0:0:0:0:0:13.1.68.3]",
        expected: "::d01:4403"
      ),
    ]
  )
  func dottedIPv4TailsNormalizeToHexadecimal(testCase: SafeURLCase<String>) {
    guard
      case .accepted(let value) = ManualURLInputValidator.isolatedTestFixture.validate(
        testCase.input
      )
    else {
      Issue.record("The frozen dotted-tail IPv6 mutation must be accepted.")
      return
    }

    let matchesExpected =
      value.scheme == .http
      && value.asciiHost == testCase.expected
      && value.effectivePort == 80
    #expect(matchesExpected)
  }

  @Test func exactUTF8BoundariesHoldAcrossASCIIAndMultibyteFamilies() throws {
    let validator = ManualURLInputValidator.isolatedTestFixture
    let limit = SubmittedURL.maximumUTF8ByteCount
    let asciiPrefix = "https://boundary.test/"
    let exactASCII = asciiPrefix + String(repeating: "a", count: limit - asciiPrefix.utf8.count)
    let overASCII = exactASCII + "a"

    let encodedUnit = "%C3%A9"
    let encodedPrefix = "https://boundary.test/"
    let encodedUnitCount = (limit - encodedPrefix.utf8.count) / encodedUnit.utf8.count
    let encodedRemainder =
      limit - encodedPrefix.utf8.count - (encodedUnitCount * encodedUnit.utf8.count)
    let exactEncoded =
      encodedPrefix
      + String(repeating: encodedUnit, count: encodedUnitCount)
      + String(repeating: "a", count: encodedRemainder)

    let multibytePrefix = "https://boundary.test/"
    let multibyteCount = ((limit - multibytePrefix.utf8.count) / 2) + 1
    let overMultibyte = multibytePrefix + String(repeating: "\u{00E9}", count: multibyteCount)

    try #require(exactASCII.utf8.count == limit)
    try #require(exactEncoded.utf8.count == limit)
    try #require(overASCII.utf8.count == limit + 1)
    try #require(overMultibyte.utf8.count > limit)

    guard case .accepted(let asciiValue) = validator.validate(exactASCII) else {
      Issue.record("An exact-limit ASCII URL must be accepted.")
      return
    }
    guard case .accepted(let encodedValue) = validator.validate(exactEncoded) else {
      Issue.record("An exact-limit percent-encoded UTF-8 URL must be accepted.")
      return
    }

    #expect(asciiValue.submittedURL.rawValue.utf8.count == limit)
    #expect(encodedValue.submittedURL.rawValue.utf8.count == limit)
    expectRejection(validator.validate(overASCII), expected: .urlTooLong)
    expectRejection(validator.validate(overMultibyte), expected: .urlTooLong)

    #expect(throws: ManualURLInputProblem.urlTooLong) {
      try SubmittedURL(rawValue: overASCII)
    }
    #expect(throws: ManualURLInputProblem.urlTooLong) {
      try SubmittedURL(validating: overMultibyte)
    }
  }

  @Test func rawQueryAndFragmentMarkersSurviveGeneratedAcceptedInputs() throws {
    var generator = URLPolicySplitMix64(seed: 0x5155_4552_5946_5241)
    let validator = ManualURLInputValidator.isolatedTestFixture

    for iteration in 0..<512 {
      let token = generator.nextASCIIIdentifier(length: 12)
      let query = "first=\(iteration)&first=%2F&empty=&token=\(token)"
      let fragment = "fragment-%23-\(token)"
      let input = "https://preserve.test/A%2fb?\(query)#\(fragment)"
      guard case .accepted(let value) = validator.validate(input) else {
        Issue.record("A generated raw-component preservation case must be accepted.")
        return
      }

      let componentsMatch =
        value.submittedURL.rawValue.utf8.elementsEqual(input.utf8)
        && value.rawPercentEncodedPath == "/A%2fb"
        && value.rawPercentEncodedQuery == query
        && value.rawPercentEncodedFragment == fragment
      #expect(
        componentsMatch,
        "Generated query and fragment spelling must remain byte-exact at iteration \(iteration)."
      )
    }
  }

  @Test func acceptedAndRejectedCanariesNeverReachOrdinaryRenderingSurfaces() throws {
    let acceptedCanary = "PROPERTY_ACCEPTED_CANARY_46A7"
    let rejectedCanary = "PROPERTY_REJECTED_CANARY_82D1"
    let validator = ManualURLInputValidator.isolatedTestFixture
    let accepted = validator.validate(
      "https://redaction.test/path?secret=\(acceptedCanary)#\(acceptedCanary)"
    )
    let rejected = validator.validate(
      "https://user:\(rejectedCanary)@redaction.test/"
    )

    guard case .accepted(let acceptedValue) = accepted,
      case .rejected(let rejectedProblem) = rejected
    else {
      Issue.record("Redaction canary preconditions must produce one accepted and one rejected URL.")
      return
    }

    let acceptedRenderings =
      renderings(of: accepted)
      + renderings(of: acceptedValue)
      + renderings(of: acceptedValue.submittedURL)
      + [
        LogSafeURLRedactor.redact(acceptedValue),
        LogSafeURLRedactor.redact(acceptedValue.submittedURL),
        LogSafeURLRedactor.redact(acceptedValue.submittedURL.rawValue),
      ]
    let rejectedRenderings =
      renderings(of: rejected)
      + renderings(of: rejectedProblem)
      + renderings(of: rejectedProblem as NSError)
    let renderingsAreSafe =
      acceptedRenderings.allSatisfy { $0.contains(acceptedCanary) == false }
      && rejectedRenderings.allSatisfy { $0.contains(rejectedCanary) == false }
      && acceptedRenderings.contains(LogSafeURLRedactor.replacement)

    #expect(renderingsAreSafe, "Descriptions, errors, logs, and reflection must omit canaries.")
  }

  @Test func concurrentGeneratedValidationMatchesSerialResults() async {
    var generator = URLPolicySplitMix64(seed: 0x434F_4E43_5552_5245)
    let inputs = (0..<512).map { _ in makeGeneratedURL(using: &generator) }
    let validator = ManualURLInputValidator.isolatedTestFixture
    let expected = inputs.map(validator.validate)

    let indexedOutcomes = await withTaskGroup(of: URLPolicyIndexedOutcome.self) { group in
      for (index, input) in inputs.enumerated() {
        group.addTask {
          URLPolicyIndexedOutcome(index: index, outcome: validator.validate(input))
        }
      }

      var outcomes: [URLPolicyIndexedOutcome] = []
      outcomes.reserveCapacity(inputs.count)
      for await outcome in group {
        outcomes.append(outcome)
      }
      return outcomes.sorted { $0.index < $1.index }
    }

    let countMatches = indexedOutcomes.count == expected.count
    let resultsMatch =
      countMatches
      && indexedOutcomes.enumerated().allSatisfy { index, indexedOutcome in
        indexedOutcome.index == index && indexedOutcome.outcome == expected[index]
      }
    #expect(countMatches)
    #expect(resultsMatch, "Concurrent validation must match the fixed serial baseline.")
  }

  @Test(
    "Environment-controlled deterministic URL campaign",
    .timeLimit(.minutes(11))
  )
  func environmentControlledCampaign() throws {
    let duration = try #require(urlPolicyCampaignDuration())
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: duration)
    let validator = ManualURLInputValidator.isolatedTestFixture
    var generator = URLPolicySplitMix64(seed: 0x4655_5A5A_5F55_524C)
    var iteration = 0

    repeat {
      for _ in 0..<128 {
        let input = makeGeneratedURL(using: &generator)
        try verifyUniversalProperties(
          input,
          validator: validator,
          caseID: "campaign-\(iteration)"
        )
        iteration += 1
      }
    } while clock.now < deadline

    #expect(iteration >= 128)
  }

  private func verifyUniversalProperties(
    _ input: String,
    validator: ManualURLInputValidator,
    caseID: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let first = validator.validate(input)
    let second = validator.validate(input)
    guard validationsAreIdempotent(first, second, caseID: caseID, at: sourceLocation) else {
      return
    }
    guard
      try validationOverloadsAgree(
        input,
        outcome: first,
        validator: validator,
        caseID: caseID,
        at: sourceLocation
      )
    else {
      return
    }

    switch first {
    case .accepted(let value):
      guard
        acceptedPropertiesHold(
          value,
          input: input,
          outcome: first,
          validator: validator,
          caseID: caseID,
          at: sourceLocation
        )
      else {
        return
      }

    case .rejected(let problem):
      guard rejectionRenderingIsBounded(problem, at: sourceLocation) else {
        return
      }
    }

    verifyStringRedaction(input, caseID: caseID, at: sourceLocation)
  }

  private func validationsAreIdempotent(
    _ first: ManualURLInputValidation,
    _ second: ManualURLInputValidation,
    caseID: String,
    at sourceLocation: SourceLocation
  ) -> Bool {
    guard first == second else {
      Issue.record(
        "Validation was not idempotent for safe case ID \(caseID).",
        sourceLocation: sourceLocation
      )
      return false
    }
    return true
  }

  private func validationOverloadsAgree(
    _ input: String,
    outcome: ManualURLInputValidation,
    validator: ManualURLInputValidator,
    caseID: String,
    at sourceLocation: SourceLocation
  ) throws -> Bool {
    guard input.utf8.count <= SubmittedURL.maximumUTF8ByteCount else {
      guard case .rejected(.urlTooLong) = outcome else {
        Issue.record(
          "An over-limit generated input did not fail first at the size boundary.",
          sourceLocation: sourceLocation
        )
        return false
      }
      return true
    }

    let submitted = try SubmittedURL(rawValue: input)
    guard validator.validate(submitted) == outcome else {
      Issue.record(
        "Validation overloads disagreed for safe case ID \(caseID).",
        sourceLocation: sourceLocation
      )
      return false
    }
    return true
  }

  private func acceptedPropertiesHold(
    _ value: ValidatedManualURL,
    input: String,
    outcome: ManualURLInputValidation,
    validator: ManualURLInputValidator,
    caseID: String,
    at sourceLocation: SourceLocation
  ) -> Bool {
    guard let rawComponents = rawComponents(of: input) else {
      Issue.record(
        "Accepted input lacked independently extractable raw components.",
        sourceLocation: sourceLocation
      )
      return false
    }
    let invariantsHold =
      value.syntaxProfileVersion == ManualURLInputValidator.syntaxProfileVersion
      && value.submittedURL.rawValue.utf8.elementsEqual(input.utf8)
      && value.asciiHost.utf8.allSatisfy { $0 < 0x80 }
      && value.asciiHost == value.asciiHost.lowercased()
      && value.effectivePort == (value.explicitPort ?? value.scheme.defaultPort)
      && value.rawPercentEncodedPath == rawComponents.path
      && value.rawPercentEncodedQuery == rawComponents.query
      && value.rawPercentEncodedFragment == rawComponents.fragment
      && value.description == LogSafeURLRedactor.replacement
      && value.debugDescription == LogSafeURLRedactor.replacement
      && LogSafeURLRedactor.redact(value) == LogSafeURLRedactor.replacement
    guard invariantsHold else {
      Issue.record(
        "Accepted-value invariants failed for safe case ID \(caseID).",
        sourceLocation: sourceLocation
      )
      return false
    }
    guard validator.validate(value.submittedURL) == outcome else {
      Issue.record(
        "Revalidating the accepted submission changed its decomposition.",
        sourceLocation: sourceLocation
      )
      return false
    }
    return true
  }

  private func rejectionRenderingIsBounded(
    _ problem: ManualURLInputProblem,
    at sourceLocation: SourceLocation
  ) -> Bool {
    let renderingIsBounded =
      problem.description.utf8.count <= 64
      && problem.debugDescription == problem.description
      && problem.errorDescription == problem.description
    guard renderingIsBounded else {
      Issue.record(
        "A generated rejection escaped the finite bounded error contract.",
        sourceLocation: sourceLocation
      )
      return false
    }
    return true
  }

  private func verifyStringRedaction(
    _ input: String,
    caseID: String,
    at sourceLocation: SourceLocation
  ) {
    guard LogSafeURLRedactor.redact(input) == LogSafeURLRedactor.replacement else {
      Issue.record(
        "String redaction changed for safe case ID \(caseID).",
        sourceLocation: sourceLocation
      )
      return
    }
  }

  private func expectRejection(
    _ outcome: ManualURLInputValidation,
    expected: ManualURLInputProblem,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    guard case .rejected(let problem) = outcome else {
      Issue.record(
        "Expected the byte-boundary input to be rejected.",
        sourceLocation: sourceLocation
      )
      return
    }
    #expect(problem == expected, sourceLocation: sourceLocation)
  }
}

private struct URLPolicyIndexedOutcome: Sendable {
  let index: Int
  let outcome: ManualURLInputValidation
}

private struct URLPolicySplitMix64: Sendable {
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

  mutating func nextIndex(upperBound: Int) -> Int {
    precondition(upperBound > 0)
    return Int(next() % UInt64(upperBound))
  }

  mutating func nextASCIIIdentifier(length: Int) -> String {
    let alphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789".utf8)
    let bytes = (0..<length).map { _ in alphabet[nextIndex(upperBound: alphabet.count)] }
    return String(decoding: bytes, as: UTF8.self)
  }
}

private enum URLPolicyMutationFixtures {
  static let rejectedCases: [SafeURLCase<ManualURLInputProblem>] = {
    var cases: [SafeURLCase<ManualURLInputProblem>] = [
      SafeURLCase("percent-short", input: "https://mutation.test/%", expected: .invalidURL),
      SafeURLCase("percent-nonhex-high", input: "https://mutation.test/%G0", expected: .invalidURL),
      SafeURLCase("percent-nonhex-low", input: "https://mutation.test/%0G", expected: .invalidURL),
      SafeURLCase("percent-nul", input: "https://mutation.test/%00", expected: .invalidURL),
      SafeURLCase("percent-cr", input: "https://mutation.test/%0D", expected: .invalidURL),
      SafeURLCase("percent-lf", input: "https://mutation.test/%0A", expected: .invalidURL),
      SafeURLCase("percent-backslash", input: "https://mutation.test/%5C", expected: .invalidURL),
      SafeURLCase("percent-overlong", input: "https://mutation.test/%C0%AF", expected: .invalidURL),
      SafeURLCase(
        "bracket-missing-close", input: "https://[2001:db8::1/oracle", expected: .invalidURL),
      SafeURLCase(
        "bracket-extra-close", input: "https://[2001:db8::1]]/oracle", expected: .invalidURL),
      SafeURLCase("bracket-nested", input: "https://[[2001:db8::1]]/oracle", expected: .invalidURL),
      SafeURLCase("bracket-empty", input: "https://[]/oracle", expected: .invalidURL),
      SafeURLCase("bracketed-ipv4", input: "https://[192.0.2.1]/oracle", expected: .invalidURL),
      SafeURLCase("ipv6-unbracketed", input: "https://2001:db8::1/oracle", expected: .invalidURL),
      SafeURLCase("ipv6-zone-raw", input: "https://[fe80::1%en0]/oracle", expected: .invalidURL),
      SafeURLCase(
        "ipv6-zone-encoded", input: "https://[fe80::1%25en0]/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-leading-zero", input: "https://192.0.2.01/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-short", input: "https://192.0.513/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-integer", input: "https://3221225985/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-hex", input: "https://0xc0000201/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-octal", input: "https://0300.0000.0002.0001/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-signed", input: "https://+192.0.2.1/oracle", expected: .invalidURL),
      SafeURLCase("ipv4-overflow", input: "https://256.0.2.1/oracle", expected: .invalidURL),
      SafeURLCase("numeric-final-label", input: "http://foo.09/oracle", expected: .invalidURL),
      SafeURLCase(
        "empty-hex-final-label", input: "http://foo.0x/oracle", expected: .invalidURL),
      SafeURLCase(
        "whatwg-zero-hex-host", input: "https://0x.0x.0/oracle", expected: .invalidURL),
      SafeURLCase(
        "idna-v2-double-hyphen", input: "https://a.bc--de.f/oracle", expected: .invalidURL),
      SafeURLCase(
        "idna-v3-punycode-trailing-hyphen",
        input: "https://xn--ej0b.xn----d87b/oracle",
        expected: .invalidURL
      ),
      SafeURLCase(
        "ipv6-five-digit-hextet",
        input: "https://[2001:db8::00000]/oracle",
        expected: .invalidURL
      ),
    ]

    for scalarValue in 0...0x1F {
      guard let scalar = Unicode.Scalar(scalarValue) else {
        preconditionFailure("The fixed control-scalar range must be representable.")
      }
      cases.append(
        SafeURLCase(
          "raw-control-\(scalarValue)",
          input: "https://mutation.test/a\(Character(scalar))b",
          expected: .invalidURL
        )
      )
    }
    cases.append(
      SafeURLCase(
        "raw-control-127",
        input: "https://mutation.test/a\u{7F}b",
        expected: .invalidURL
      )
    )
    return cases
  }()
}

private func makeGeneratedURL(using generator: inout URLPolicySplitMix64) -> String {
  let scheme = generator.nextIndex(upperBound: 2) == 0 ? "http" : "https"
  let host = "h\(generator.nextASCIIIdentifier(length: 10)).test"
  let pathSegments = ["a", "A%2fb", "%C3%A9", "%252F", "dot..segment", "empty-"]
  let path = "/\(pathSegments[generator.nextIndex(upperBound: pathSegments.count)])"
  let token = generator.nextASCIIIdentifier(length: 16)
  let query = "first=\(generator.next() % 10_000)&first=%2F&token=\(token)"
  let fragment = "route-%23-\(token)"
  let base = "\(scheme)://\(host)\(path)?\(query)#\(fragment)"

  switch generator.nextIndex(upperBound: 14) {
  case 0:
    return base
  case 1:
    return "\(scheme.uppercased())://\(host.uppercased())\(path)?\(query)#\(fragment)"
  case 2:
    return
      "\(scheme)://\(host):\([1, 80, 81, 443, 65_535][generator.nextIndex(upperBound: 5)])\(path)?\(query)#\(fragment)"
  case 3:
    return base + "%"
  case 4:
    return base + "%00"
  case 5:
    return "\(scheme)://\(host)\\confusion"
  case 6:
    return "\(scheme)://user:\(token)@\(host)/"
  case 7:
    return "http://192.0.2.0\(generator.nextIndex(upperBound: 10))/"
  case 8:
    return "http://0xC00002\(String(generator.next() % 256, radix: 16))/"
  case 9:
    return "https://[2001:db8::\(generator.next() % 65_536)]\(path)?\(query)#\(fragment)"
  case 10:
    return "https://[2001:db8::\(generator.next() % 65_536)\(path)?\(query)#\(fragment)"
  case 11:
    return "https://b\u{00FC}cher.test\(path)?\(query)#\(fragment)"
  case 12:
    return String(repeating: "a", count: SubmittedURL.maximumUTF8ByteCount + 1)
  default:
    return "ftp://\(host)/\(token)"
  }
}

private func rawComponents(of input: String) -> (path: String, query: String?, fragment: String?)? {
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

private func renderings<T>(of value: T) -> [String] {
  [
    String(describing: value),
    String(reflecting: value),
  ] + Mirror(reflecting: value).children.map { String(describing: $0.value) }
}

private func urlPolicyCampaignDuration() -> Duration? {
  let environment = ProcessInfo.processInfo.environment
  let rawSeconds = environment["HEZOLINK_URL_FUZZ_SECONDS"] ?? "0.2"
  guard let seconds = Double(rawSeconds), seconds.isFinite, (0.01...600).contains(seconds)
  else {
    return nil
  }
  return .milliseconds(Int64((seconds * 1_000).rounded(.up)))
}
