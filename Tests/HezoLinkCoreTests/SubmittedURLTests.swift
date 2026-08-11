import Testing

@testable import HezoLinkCore

struct SubmittedURLTests {
  @Test(
    "Submission preserves every deliberately supplied character",
    arguments: [
      SafeSensitiveValue(
        "mixed_case_escapes_query_fragment",
        value: "hTtPs://Example.COM/A%2fb?first=1&first=%2F&empty=#Route%2f"
      ),
      SafeSensitiveValue(
        "empty_query_and_fragment",
        value: "https://example.com/path?#"
      ),
      SafeSensitiveValue(
        "unicode_spelling",
        value: "https://b\u{00FC}cher.example/%E2%98%83?q=\u{00E9}#\u{96EA}"
      ),
    ]
  )
  func preservesExactRawValue(testCase: SafeSensitiveValue) throws {
    let submitted = try SubmittedURL(rawValue: testCase.value)
    let alias = try SubmittedURL(validating: testCase.value)
    let rawValueWasPreserved = submitted.rawValue == testCase.value
    let aliasWasEquivalent = alias == submitted

    #expect(rawValueWasPreserved, "The exact submission must survive unchanged.")
    #expect(aliasWasEquivalent, "Both validating initializers must enforce the same contract.")
  }

  @Test func acceptsExactly8192UTF8Bytes() throws {
    let rawValue = makeSensitiveValue(utf8ByteCount: SubmittedURL.maximumUTF8ByteCount)
    let submitted = try SubmittedURL(rawValue: rawValue)
    let acceptedExactBoundary =
      rawValue.utf8.count == SubmittedURL.maximumUTF8ByteCount
      && submitted.rawValue.utf8.count == SubmittedURL.maximumUTF8ByteCount

    #expect(acceptedExactBoundary, "The published 8 KiB boundary must be inclusive.")
  }

  @Test func rejectsExactly8193UTF8Bytes() {
    let rawValue = makeSensitiveValue(utf8ByteCount: SubmittedURL.maximumUTF8ByteCount + 1)
    var observedProblem: ManualURLInputProblem?

    do {
      _ = try SubmittedURL(rawValue: rawValue)
      Issue.record("Expected the over-limit submission to be rejected.")
    } catch let problem as ManualURLInputProblem {
      observedProblem = problem
    } catch {
      Issue.record("Expected a bounded manual-URL problem.")
    }

    #expect(
      observedProblem == .urlTooLong,
      "The first byte beyond the limit must have the specific bounded problem."
    )
  }

  @Test func limitCountsUTF8BytesInsteadOfCharacters() {
    let rawValue = String(
      repeating: "\u{00E9}",
      count: (SubmittedURL.maximumUTF8ByteCount / 2) + 1
    )
    let characterCountIsBelowByteLimit =
      rawValue.count < SubmittedURL.maximumUTF8ByteCount
      && rawValue.utf8.count > SubmittedURL.maximumUTF8ByteCount
    var observedProblem: ManualURLInputProblem?

    do {
      _ = try SubmittedURL(rawValue: rawValue)
      Issue.record("Expected the UTF-8 byte limit to reject the submission.")
    } catch let problem as ManualURLInputProblem {
      observedProblem = problem
    } catch {
      Issue.record("Expected a bounded manual-URL problem.")
    }

    #expect(characterCountIsBelowByteLimit, "The fixture must distinguish bytes from characters.")
    #expect(observedProblem == .urlTooLong)
  }

  @Test func descriptionsAreConstantAndDoNotRevealSubmittedContent() throws {
    let canary = "https://example.com/reset?token=URL_CANARY_9e4d#private"
    let submitted = try SubmittedURL(rawValue: canary)
    let renderedValues = [
      submitted.description,
      submitted.debugDescription,
      String(describing: submitted),
      String(reflecting: submitted),
    ]
    let everyValueIsConstant = renderedValues.allSatisfy {
      $0 == LogSafeURLRedactor.replacement && $0.contains(canary) == false
        && $0.contains("URL_CANARY_9e4d") == false
    }

    #expect(everyValueIsConstant, "Every ordinary rendering boundary must use the placeholder.")
  }

  private func makeSensitiveValue(utf8ByteCount targetCount: Int) -> String {
    let prefix = "https://example.com/"
    let remainingCount = targetCount - prefix.utf8.count
    let twoByteCharacterCount = remainingCount / 2
    let finalASCII = remainingCount.isMultiple(of: 2) ? "" : "a"
    return prefix + String(repeating: "\u{00E9}", count: twoByteCharacterCount) + finalASCII
  }
}
