import Testing

@testable import HezoLinkCore

struct LogSafeURLRedactorTests {
  @Test func replacementIsTheOneDocumentedBoundedConstant() {
    #expect(LogSafeURLRedactor.replacement == "<redacted-url>")
    #expect(LogSafeURLRedactor.replacement.utf8.count == 14)
  }

  @Test(
    "Every untrusted string receives the same replacement",
    arguments: [
      SafeSensitiveValue("empty", value: ""),
      SafeSensitiveValue("ordinary", value: "https://example.com/path"),
      SafeSensitiveValue(
        "credentials_and_canary",
        value: "https://user:password@example.com/?token=REDACTOR_CANARY_24bf#private"
      ),
      SafeSensitiveValue("controls", value: "https://example.com/\0\r\n"),
    ]
  )
  func stringRedactionIsConstant(testCase: SafeSensitiveValue) {
    let redacted = LogSafeURLRedactor.redact(testCase.value)
    let resultIsSafe =
      redacted == LogSafeURLRedactor.replacement
      && (testCase.value.isEmpty || redacted.contains(testCase.value) == false)

    #expect(resultIsSafe, "String redaction must ignore the supplied value completely.")
  }

  @Test func typedValuesAndDescriptionsUseTheSameReplacement() throws {
    let canary = "REDACTOR_TYPED_CANARY_a879"
    let submitted = try SubmittedURL(
      rawValue: "https://example.com/path?token=\(canary)#private"
    )
    let host = try #require(ValidatedURLHost(domainNameASCIIValue: "example.com"))
    let validated = ValidatedManualURL(
      syntaxProfileVersion: 1,
      submittedURL: submitted,
      scheme: .https,
      host: host,
      explicitPort: nil,
      effectivePort: 443,
      portDisposition: .supported,
      rawPercentEncodedPath: "/path",
      rawPercentEncodedQuery: "token=\(canary)",
      rawPercentEncodedFragment: "private"
    )
    let renderedValues = [
      LogSafeURLRedactor.redact(submitted),
      LogSafeURLRedactor.redact(validated),
      submitted.description,
      submitted.debugDescription,
      validated.description,
      validated.debugDescription,
      String(describing: submitted),
      String(reflecting: submitted),
      String(describing: validated),
      String(reflecting: validated),
    ]
    let everyValueIsSafe = renderedValues.allSatisfy {
      $0 == LogSafeURLRedactor.replacement && $0.contains(canary) == false
    }
    let mirrors = [Mirror(reflecting: submitted), Mirror(reflecting: validated)]
    let reflectedValues = mirrors.flatMap { mirror in
      mirror.children.compactMap { $0.value as? String }
    }
    let reflectionsAreSafe =
      mirrors.allSatisfy { $0.children.count == 1 }
      && reflectedValues.count == 2
      && reflectedValues.allSatisfy {
        $0 == LogSafeURLRedactor.replacement && $0.contains(canary) == false
      }

    #expect(everyValueIsSafe, "Typed URL values must share the constant redaction boundary.")
    #expect(reflectionsAreSafe, "Custom reflection must expose only the constant replacement.")
  }

  @Test func redactionDoesNotDependOnInputLengthOrShape() {
    let values = [
      "a",
      String(repeating: "a", count: SubmittedURL.maximumUTF8ByteCount),
      String(repeating: "\u{1F4A5}", count: 2_049),
    ]
    let outputs = values.map(LogSafeURLRedactor.redact)
    let outputsAreIdentical = outputs.allSatisfy { $0 == LogSafeURLRedactor.replacement }

    #expect(outputsAreIdentical, "Redaction must not parse, truncate, or copy the input.")
  }
}
