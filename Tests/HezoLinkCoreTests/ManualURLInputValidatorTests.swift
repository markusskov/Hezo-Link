import Testing

@testable import HezoLinkCore

struct ManualURLInputValidatorTests {
  struct AcceptedExpectation: Sendable {
    let scheme: WebScheme
    let host: String
    let explicitPort: UInt16?
    let effectivePort: UInt16
    let portDisposition: PortDisposition
    let path: String
    let query: String?
    let fragment: String?
  }

  @Test(
    "Fixture profile accepts bounded HTTP(S) syntax without rewriting transient components",
    arguments: [
      SafeURLCase(
        "http_default",
        input: "http://basic.test",
        expected: AcceptedExpectation(
          scheme: .http,
          host: "basic.test",
          explicitPort: nil,
          effectivePort: 80,
          portDisposition: .supported,
          path: "",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "https_raw_components",
        input: "https://query.test/A%2fb?first=1&first=%2F&empty=#Route%2f",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "query.test",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/A%2fb",
          query: "first=1&first=%2F&empty=",
          fragment: "Route%2f"
        )
      ),
      SafeURLCase(
        "valid_percent_encoded_utf8_and_space",
        input: "https://query.test/%C3%A9%20value",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "query.test",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/%C3%A9%20value",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "mixed_case_and_empty_markers",
        input: "HtTpS://MiXeD.TeSt/path?#",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "mixed.test",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/path",
          query: "",
          fragment: ""
        )
      ),
      SafeURLCase(
        "unicode_idn",
        input: "https://b\u{00FC}cher.test/path",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "xn--bcher-kva.test",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/path",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "canonical_ipv4_syntax",
        input: "http://192.0.2.1/",
        expected: AcceptedExpectation(
          scheme: .http,
          host: "192.0.2.1",
          explicitPort: nil,
          effectivePort: 80,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "canonical_ipv6_syntax",
        input: "https://[2001:db8::1]/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "2001:db8::1",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "expanded_ipv6_syntax",
        input: "https://[2001:0db8:0:0:0:0:0:1]/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "2001:db8::1",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "ipv4_mapped_ipv6_syntax",
        input: "https://[::ffff:192.0.2.1]/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "192.0.2.1",
          explicitPort: nil,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "explicit_default_port",
        input: "https://port.test:443/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "port.test",
          explicitPort: 443,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "cross_scheme_supported_port",
        input: "http://port.test:443/",
        expected: AcceptedExpectation(
          scheme: .http,
          host: "port.test",
          explicitPort: 443,
          effectivePort: 443,
          portDisposition: .supported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "unsupported_valid_port",
        input: "https://port.test:81/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "port.test",
          explicitPort: 81,
          effectivePort: 81,
          portDisposition: .unsupported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "maximum_valid_port",
        input: "https://port.test:65535/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "port.test",
          explicitPort: 65_535,
          effectivePort: 65_535,
          portDisposition: .unsupported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
      SafeURLCase(
        "minimum_valid_port",
        input: "https://port.test:1/",
        expected: AcceptedExpectation(
          scheme: .https,
          host: "port.test",
          explicitPort: 1,
          effectivePort: 1,
          portDisposition: .unsupported,
          path: "/",
          query: nil,
          fragment: nil
        )
      ),
    ]
  )
  func acceptedSyntax(testCase: SafeURLCase<AcceptedExpectation>) {
    let outcome = ManualURLInputValidator.isolatedTestFixture.validate(testCase.input)
    guard case .accepted(let value) = outcome else {
      Issue.record("Expected the fixture-profile URL syntax to be accepted.")
      return
    }

    let expected = testCase.expected
    let componentsMatch =
      value.scheme == expected.scheme
      && value.asciiHost == expected.host
      && value.explicitPort == expected.explicitPort
      && value.effectivePort == expected.effectivePort
      && value.portDisposition == expected.portDisposition
      && value.rawPercentEncodedPath == expected.path
      && value.rawPercentEncodedQuery == expected.query
      && value.rawPercentEncodedFragment == expected.fragment
      && value.syntaxProfileVersion == ManualURLInputValidator.syntaxProfileVersion
      && value.submittedURL.rawValue == testCase.input

    #expect(componentsMatch, "Accepted syntax must preserve the frozen transient decomposition.")
  }

  @Test(
    "Every syntactically present non-web scheme has the bounded unsupported-scheme result",
    arguments: [
      SafeURLCase<ManualURLInputProblem>(
        "ftp", input: "ftp://scheme.test/", expected: .unsupportedScheme),
      SafeURLCase("file", input: "file:///tmp/a", expected: .unsupportedScheme),
      SafeURLCase("data", input: "data:text/plain,a", expected: .unsupportedScheme),
      SafeURLCase("blob", input: "blob:https://scheme.test/id", expected: .unsupportedScheme),
      SafeURLCase("javascript", input: "javascript:alert(1)", expected: .unsupportedScheme),
      SafeURLCase("gopher", input: "gopher://scheme.test/", expected: .unsupportedScheme),
      SafeURLCase("dict", input: "dict://scheme.test/", expected: .unsupportedScheme),
      SafeURLCase("smb", input: "smb://scheme.test/share", expected: .unsupportedScheme),
      SafeURLCase("unix", input: "unix:///socket", expected: .unsupportedScheme),
      SafeURLCase("mixed_case_ftp", input: "FtP://scheme.test/", expected: .unsupportedScheme),
    ]
  )
  func unsupportedSchemes(testCase: SafeURLCase<ManualURLInputProblem>) {
    expectRejection(
      ManualURLInputValidator.isolatedTestFixture.validate(testCase.input),
      expected: testCase.expected
    )
  }

  @Test(
    "Malformed, ambiguous, credential-bearing, and alternate-address inputs fail closed",
    arguments: [
      SafeURLCase<ManualURLInputProblem>("empty", input: "", expected: .invalidURL),
      SafeURLCase("spaces", input: "   ", expected: .invalidURL),
      SafeURLCase("relative", input: "//host.test/path", expected: .invalidURL),
      SafeURLCase("scheme_starts_digit", input: "1https://host.test/", expected: .invalidURL),
      SafeURLCase("scheme_invalid_character", input: "ht*tp://host.test/", expected: .invalidURL),
      SafeURLCase("missing_authority_slash", input: "https:/host.test", expected: .invalidURL),
      SafeURLCase("missing_host", input: "https://", expected: .invalidURL),
      SafeURLCase("triple_slash", input: "https:///path", expected: .invalidURL),
      SafeURLCase("encoded_scheme_delimiter", input: "https%3A//host.test", expected: .invalidURL),
      SafeURLCase("raw_space", input: "https://host.test/a b", expected: .invalidURL),
      SafeURLCase("raw_unicode_path", input: "https://host.test/é", expected: .invalidURL),
      SafeURLCase("backslash", input: "https://host.test\\evil", expected: .invalidURL),
      SafeURLCase("nul", input: "https://host.test/\0", expected: .invalidURL),
      SafeURLCase("cr", input: "https://host.test/\r", expected: .invalidURL),
      SafeURLCase("lf", input: "https://host.test/\n", expected: .invalidURL),
      SafeURLCase("tab", input: "https://host.test/\t", expected: .invalidURL),
      SafeURLCase("del", input: "https://host.test/\u{7F}", expected: .invalidURL),
      SafeURLCase("malformed_percent_short", input: "https://host.test/%", expected: .invalidURL),
      SafeURLCase("malformed_percent_hex", input: "https://host.test/%GG", expected: .invalidURL),
      SafeURLCase("encoded_nul", input: "https://host.test/%00", expected: .invalidURL),
      SafeURLCase("encoded_cr", input: "https://host.test/%0D", expected: .invalidURL),
      SafeURLCase("encoded_lf", input: "https://host.test/%0a", expected: .invalidURL),
      SafeURLCase(
        "invalid_utf8_overlong", input: "https://host.test/%C0%AF", expected: .invalidURL),
      SafeURLCase(
        "invalid_utf8_surrogate", input: "https://host.test/%ED%A0%80", expected: .invalidURL),
      SafeURLCase("invalid_utf8_byte", input: "https://host.test/%FF", expected: .invalidURL),
      SafeURLCase("encoded_c1_control", input: "https://host.test/%C2%85", expected: .invalidURL),
      SafeURLCase(
        "encoded_line_separator", input: "https://host.test/%E2%80%A8", expected: .invalidURL),
      SafeURLCase("encoded_backslash_upper", input: "https://host.test/%5C", expected: .invalidURL),
      SafeURLCase("encoded_backslash_lower", input: "https://host.test/%5c", expected: .invalidURL),
      SafeURLCase("username", input: "https://user@host.test/", expected: .invalidURL),
      SafeURLCase("password", input: "https://user:password@host.test/", expected: .invalidURL),
      SafeURLCase("empty_user", input: "https://@host.test/", expected: .invalidURL),
      SafeURLCase("encoded_user", input: "https://us%65r:secret@host.test/", expected: .invalidURL),
      SafeURLCase(
        "host_at_confusion", input: "https://host.test@evil.test/", expected: .invalidURL),
      SafeURLCase("double_at", input: "https://user@host.test@evil.test/", expected: .invalidURL),
      SafeURLCase("single_label", input: "https://singlelabel/", expected: .invalidURL),
      SafeURLCase("empty_label", input: "https://a..test/", expected: .invalidURL),
      SafeURLCase("leading_hyphen", input: "https://-a.test/", expected: .invalidURL),
      SafeURLCase("underscore", input: "https://a_b.test/", expected: .invalidURL),
      SafeURLCase("trailing_dot", input: "https://host.test./", expected: .invalidURL),
      SafeURLCase("unicode_dot", input: "https://host\u{3002}test/", expected: .invalidURL),
      SafeURLCase(
        "unicode_fullwidth_dot", input: "https://host\u{FF0E}test/", expected: .invalidURL),
      SafeURLCase(
        "unicode_halfwidth_dot", input: "https://host\u{FF61}test/", expected: .invalidURL),
      SafeURLCase(
        "unicode_fullwidth_percent", input: "https://host％32.test/", expected: .invalidURL),
      SafeURLCase(
        "unicode_fullwidth_percent_ipv4", input: "https://％31％32％37.0.0.1/",
        expected: .invalidURL),
      SafeURLCase("unicode_fullwidth_letter", input: "https://ｈost.test/", expected: .invalidURL),
      SafeURLCase(
        "unicode_decomposed_host", input: "https://bu\u{0308}cher.test/", expected: .invalidURL),
      SafeURLCase("emoji_host", input: "https://💩.test/", expected: .invalidURL),
      SafeURLCase(
        "variation_selector_host", input: "https://a\u{FE0F}b.test/", expected: .invalidURL),
      SafeURLCase(
        "combining_grapheme_joiner_host", input: "https://a\u{034F}b.test/", expected: .invalidURL),
      SafeURLCase("invalid_punycode", input: "https://xn--.test/", expected: .invalidURL),
      SafeURLCase(
        "percent_encoded_host_letter", input: "https://h%6Fst.test/", expected: .invalidURL),
      SafeURLCase("percent_encoded_host_dot", input: "https://host%2Etest/", expected: .invalidURL),
      SafeURLCase("integer_ipv4", input: "http://2130706433/", expected: .invalidURL),
      SafeURLCase("hex_ipv4", input: "http://0x7f000001/", expected: .invalidURL),
      SafeURLCase("dotted_hex_ipv4", input: "http://0x7f.0.0.1/", expected: .invalidURL),
      SafeURLCase("octal_ipv4", input: "http://0177.0.0.1/", expected: .invalidURL),
      SafeURLCase("short_ipv4", input: "http://127.1/", expected: .invalidURL),
      SafeURLCase("overflow_ipv4", input: "http://999.0.0.1/", expected: .invalidURL),
      SafeURLCase("signed_ipv4", input: "http://+127.0.0.1/", expected: .invalidURL),
      SafeURLCase(
        "fullwidth_ipv4_digits", input: "http://１２７.0.0.1/", expected: .invalidURL),
      SafeURLCase("ipv6_unbracketed", input: "http://2001:db8::1/", expected: .invalidURL),
      SafeURLCase("ipv6_zone", input: "http://[fe80::1%25en0]/", expected: .invalidURL),
      SafeURLCase("bracketed_ipv4", input: "http://[192.0.2.1]/", expected: .invalidURL),
      SafeURLCase("bracketed_non_ip", input: "http://[not-v6]/", expected: .invalidURL),
      SafeURLCase(
        "ipv6_ipv4_tail_octal", input: "http://[::ffff:0177.0.0.1]/", expected: .invalidURL),
      SafeURLCase(
        "ipv6_ipv4_tail_leading_zero", input: "http://[2001:db8::192.0.2.01]/",
        expected: .invalidURL),
      SafeURLCase(
        "ipv6_ipv4_tail_hex", input: "http://[::ffff:0x7f.0.0.1]/", expected: .invalidURL),
      SafeURLCase("ipv6_bad_bracket", input: "http://[2001:db8::1/", expected: .invalidURL),
      SafeURLCase("ipv6_extra_bracket", input: "http://[2001:db8::1]]/", expected: .invalidURL),
      SafeURLCase("stray_closing_bracket", input: "http://host].test/", expected: .invalidURL),
      SafeURLCase("ipv6_text_port", input: "http://[2001:db8::1]:abc/", expected: .invalidURL),
      SafeURLCase("empty_port", input: "https://host.test:/", expected: .invalidURL),
      SafeURLCase("zero_port", input: "https://host.test:0/", expected: .invalidURL),
      SafeURLCase("leading_zero_port", input: "https://host.test:0443/", expected: .invalidURL),
      SafeURLCase("signed_port", input: "https://host.test:+443/", expected: .invalidURL),
      SafeURLCase("negative_port", input: "https://host.test:-1/", expected: .invalidURL),
      SafeURLCase("text_port", input: "https://host.test:abc/", expected: .invalidURL),
      SafeURLCase("overflow_port", input: "https://host.test:65536/", expected: .invalidURL),
    ]
  )
  func rejectedSyntax(testCase: SafeURLCase<ManualURLInputProblem>) {
    expectRejection(
      ManualURLInputValidator.isolatedTestFixture.validate(testCase.input),
      expected: testCase.expected
    )
  }

  @Test(
    "Production profile rejects special-use and organization-local names",
    arguments: [
      SafeSensitiveValue("test", value: "https://host.test/"),
      SafeSensitiveValue("alt", value: "https://host.alt/"),
      SafeSensitiveValue("example", value: "https://host.example/"),
      SafeSensitiveValue("example_com", value: "https://example.com/"),
      SafeSensitiveValue("invalid", value: "https://host.invalid/"),
      SafeSensitiveValue("local", value: "https://host.local/"),
      SafeSensitiveValue("localhost", value: "https://host.localhost/"),
      SafeSensitiveValue("onion", value: "https://host.onion/"),
      SafeSensitiveValue("home_arpa", value: "https://host.home.arpa/"),
      SafeSensitiveValue("resolver_arpa", value: "https://host.resolver.arpa/"),
      SafeSensitiveValue("internal", value: "https://host.internal/"),
      SafeSensitiveValue("metadata", value: "https://metadata.google.internal/"),
    ]
  )
  func productionRejectsSpecialUse(testCase: SafeSensitiveValue) {
    expectRejection(ManualURLInputValidator().validate(testCase.value), expected: .invalidURL)
  }

  @Test func ordinaryProductionSyntaxIsAcceptedWithoutNetwork() {
    let outcome = ManualURLInputValidator().validate("https://www.iana.org/domains/reserved")
    guard case .accepted(let value) = outcome else {
      Issue.record("An ordinary multi-label production hostname must pass syntax preflight.")
      return
    }

    #expect(value.scheme == .https)
    #expect(value.asciiHost == "www.iana.org")
    #expect(value.rawPercentEncodedPath == "/domains/reserved")
    #expect(value.portDisposition == .supported)
  }

  @Test func pinnedSpecialUseRegistryIsCompleteAndRejectedInProduction() {
    let expectedSuffixes = [
      "alt",
      "6tisch.arpa",
      "eap.arpa",
      "eap-noob.arpa",
      "home.arpa",
      "10.in-addr.arpa",
      "254.169.in-addr.arpa",
      "16.172.in-addr.arpa",
      "17.172.in-addr.arpa",
      "18.172.in-addr.arpa",
      "19.172.in-addr.arpa",
      "20.172.in-addr.arpa",
      "21.172.in-addr.arpa",
      "22.172.in-addr.arpa",
      "23.172.in-addr.arpa",
      "24.172.in-addr.arpa",
      "25.172.in-addr.arpa",
      "26.172.in-addr.arpa",
      "27.172.in-addr.arpa",
      "28.172.in-addr.arpa",
      "29.172.in-addr.arpa",
      "30.172.in-addr.arpa",
      "31.172.in-addr.arpa",
      "170.0.0.192.in-addr.arpa",
      "171.0.0.192.in-addr.arpa",
      "168.192.in-addr.arpa",
      "8.e.f.ip6.arpa",
      "9.e.f.ip6.arpa",
      "a.e.f.ip6.arpa",
      "b.e.f.ip6.arpa",
      "ipv4only.arpa",
      "resolver.arpa",
      "service.arpa",
      "example",
      "example.com",
      "example.net",
      "example.org",
      "invalid",
      "local",
      "localhost",
      "onion",
      "test",
    ]
    #expect(ManualURLInputValidator.specialUseDomainSuffixes == expectedSuffixes)

    let validator = ManualURLInputValidator()
    for suffix in expectedSuffixes {
      expectRejection(validator.validate("https://fixture.\(suffix)/"), expected: .invalidURL)
    }
  }

  @Test func fixtureExceptionIsNarrowAndVersioned() {
    let testOutcome = ManualURLInputValidator.isolatedTestFixture.validate("https://only.test/")
    let otherReservedOutcome = ManualURLInputValidator.isolatedTestFixture.validate(
      "https://example.com/"
    )

    guard case .accepted(let value) = testOutcome else {
      Issue.record("The isolated fixture profile must accept only the reserved .test namespace.")
      return
    }
    let profileIsPinned =
      value.syntaxProfileVersion == 2
      && ManualURLInputValidator.specialUseDomainRegistryRevision == "2026-05-22"
    #expect(profileIsPinned, "Accepted values must identify the frozen syntax policy.")
    expectRejection(otherReservedOutcome, expected: .invalidURL)
  }

  @Test func dnsLabelAndHostLengthBoundariesAreExact() {
    let label63 = String(repeating: "a", count: 63)
    let label64 = String(repeating: "a", count: 64)
    let host253 = [label63, label63, label63, String(repeating: "a", count: 56), "test"]
      .joined(separator: ".")
    let host254 = [label63, label63, label63, String(repeating: "a", count: 57), "test"]
      .joined(separator: ".")
    let validator = ManualURLInputValidator.isolatedTestFixture

    guard case .accepted(let value) = validator.validate("https://\(host253)/") else {
      Issue.record("A 253-byte host with labels at or below 63 bytes must pass syntax preflight.")
      return
    }
    #expect(value.asciiHost.utf8.count == 253)
    expectRejection(validator.validate("https://\(host254)/"), expected: .invalidURL)
    expectRejection(validator.validate("https://\(label64).test/"), expected: .invalidURL)
  }

  @Test func sizeLimitPrecedesSchemeAndPercentParsing() {
    let prefix = "ftp://host.test/%"
    let overlong =
      prefix
      + String(
        repeating: "a",
        count: SubmittedURL.maximumUTF8ByteCount - prefix.utf8.count + 1
      )
    expectRejection(ManualURLInputValidator().validate(overlong), expected: .urlTooLong)
  }

  @Test func maximumSizeCanPassEndToEndSyntaxValidation() {
    let prefix = "https://maximum.test/"
    let rawValue =
      prefix
      + String(
        repeating: "a",
        count: SubmittedURL.maximumUTF8ByteCount - prefix.utf8.count
      )
    let outcome = ManualURLInputValidator.isolatedTestFixture.validate(rawValue)
    guard case .accepted(let value) = outcome else {
      Issue.record("A syntactically valid URL at the exact byte cap must pass preflight.")
      return
    }
    #expect(value.submittedURL.rawValue.utf8.count == SubmittedURL.maximumUTF8ByteCount)
  }

  @Test func boundedSubmissionOverloadMatchesStringOverload() throws {
    let rawValue = "https://overload.test/path?one=1#fragment"
    let submitted = try SubmittedURL(rawValue: rawValue)
    let validator = ManualURLInputValidator.isolatedTestFixture

    #expect(validator.validate(rawValue) == validator.validate(submitted))
  }

  @Test func validationDescriptionsAndReflectionExcludeAcceptedAndRejectedCanaries() {
    let acceptedCanary = "ACCEPTED_URL_CANARY_27c9"
    let rejectedCanary = "REJECTED_URL_CANARY_8aa2"
    let accepted = ManualURLInputValidator.isolatedTestFixture.validate(
      "https://host.test/path?token=\(acceptedCanary)#private"
    )
    let rejected = ManualURLInputValidator().validate(
      "https://user:\(rejectedCanary)@host.test/"
    )
    let rendered = [accepted, rejected].flatMap { outcome in
      [
        outcome.description,
        outcome.debugDescription,
        String(describing: outcome),
        String(reflecting: outcome),
      ] + outcome.customMirror.children.map { String(describing: $0.value) }
    }
    let allRenderingsAreSafe = rendered.allSatisfy { value in
      value.contains(acceptedCanary) == false && value.contains(rejectedCanary) == false
    }

    #expect(allRenderingsAreSafe, "Validation diagnostics must never reveal submitted content.")
  }

  @Test func concurrentValidationIsDeterministic() async {
    let validator = ManualURLInputValidator.isolatedTestFixture
    let input = "https://deterministic.test/path?one=1&one=%2F#fragment"
    let expected = validator.validate(input)
    let outcomes = await withTaskGroup(of: ManualURLInputValidation.self) { group in
      for _ in 0..<64 {
        group.addTask {
          validator.validate(input)
        }
      }
      var values: [ManualURLInputValidation] = []
      for await value in group {
        values.append(value)
      }
      return values
    }

    #expect(outcomes.count == 64)
    #expect(outcomes.allSatisfy { $0 == expected })
  }

  private func expectRejection(
    _ outcome: ManualURLInputValidation,
    expected: ManualURLInputProblem
  ) {
    guard case .rejected(let problem) = outcome else {
      Issue.record("Expected the URL input to be rejected by the bounded syntax profile.")
      return
    }
    #expect(problem == expected, "Rejected syntax must map to its exact bounded problem.")
  }
}
