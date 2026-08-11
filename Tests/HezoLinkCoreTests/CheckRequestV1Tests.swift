import Foundation
import Testing

@testable import HezoLinkCore

struct CheckRequestV1Tests {
  struct FixtureExpectation: Sendable {
    let relativePath: String
    let submittedURL: String
    let waitBudgetMilliseconds: Int
    let canonicalJSON: String
  }

  struct PortExpectation: Sendable {
    let rawURL: String
    let explicitPort: UInt16?
    let disposition: PortDisposition
  }

  @Test(
    "Encoder output and JSON object match every valid contract fixture",
    arguments: [
      SafeCase(
        "standard",
        payload: FixtureExpectation(
          relativePath: "packages/contracts/fixtures/check-request-v1/valid/standard.json",
          submittedURL: "https://example.test/path?opaque=value#route",
          waitBudgetMilliseconds: 1_200,
          canonicalJSON:
            #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://example.test/path?opaque=value#route","wait_budget_ms":1200}"#
        )
      ),
      SafeCase(
        "zero_wait_budget",
        payload: FixtureExpectation(
          relativePath: "packages/contracts/fixtures/check-request-v1/valid/zero-wait-budget.json",
          submittedURL: "http://zero-wait.example.test/",
          waitBudgetMilliseconds: 0,
          canonicalJSON:
            #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"http://zero-wait.example.test/","wait_budget_ms":0}"#
        )
      ),
      SafeCase(
        "maximum_wait_budget",
        payload: FixtureExpectation(
          relativePath:
            "packages/contracts/fixtures/check-request-v1/valid/maximum-wait-budget.json",
          submittedURL: "https://maximum-wait.example.test/",
          waitBudgetMilliseconds: Int(Int32.max),
          canonicalJSON:
            #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://maximum-wait.example.test/","wait_budget_ms":2147483647}"#
        )
      ),
    ]
  )
  func matchesValidFixture(testCase: SafeCase<FixtureExpectation>) throws {
    let expectation = testCase.payload
    let request = try makeRequest(
      rawURL: expectation.submittedURL,
      waitBudgetMilliseconds: expectation.waitBudgetMilliseconds
    )
    let encodedData = try HezoJSON.makeEncoder().encode(request)
    let encodedJSON = try #require(String(data: encodedData, encoding: .utf8))
    let fixtureData = try Data(
      contentsOf: checkRequestRepositoryRoot.appendingPathComponent(expectation.relativePath)
    )
    let encodedObject = try requireJSONObject(encodedData)
    let fixtureObject = try requireJSONObject(fixtureData)
    let canonicalFixtureData = try JSONSerialization.data(
      withJSONObject: fixtureObject,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let objectsMatch = NSDictionary(dictionary: encodedObject).isEqual(
      to: fixtureObject
    )

    #expect(encodedJSON == expectation.canonicalJSON)
    #expect(encodedData == canonicalFixtureData)
    #expect(objectsMatch, "The encoded object must equal the checked-in valid fixture.")
  }

  @Test func wireShapeContainsExactlyFiveFrozenMembers() throws {
    let request = try makeRequest(
      rawURL: "https://shape.test/path",
      waitBudgetMilliseconds: 1_200
    )
    let object = try requireJSONObject(HezoJSON.makeEncoder().encode(request))
    let expectedKeys: Set<String> = [
      "schema_version", "url", "analysis_profile", "wait_budget_ms",
      "reason_schema_version",
    ]
    let constantsMatch =
      object["schema_version"] as? Int == CheckRequestV1.schemaVersion
      && object["analysis_profile"] as? String == CheckRequestV1.analysisProfile
      && object["reason_schema_version"] as? Int == CheckRequestV1.reasonSchemaVersion
      && object["wait_budget_ms"] as? Int == request.waitBudgetMilliseconds
      && object["url"] as? String == "https://shape.test/path"

    #expect(Set(object.keys) == expectedKeys)
    #expect(constantsMatch)
    #expect(CheckRequestV1.schemaVersion == 1)
    #expect(CheckRequestV1.analysisProfile == "standard")
    #expect(CheckRequestV1.reasonSchemaVersion == 1)
    #expect(CheckRequestV1.maximumWaitBudgetMilliseconds == Int(Int32.max))
  }

  @Test func publicContractRemainsEncoderOnly() {
    #expect(isCheckRequestDecodable(CheckRequestV1.self) == false)
  }

  @Test(
    "Encoding retains raw case, escapes, duplicate query items, and empty markers",
    arguments: [
      SafeSensitiveValue(
        "case_escapes_duplicate_query",
        value: "HtTpS://MiXeD.TeSt/A%2fb?first=1&first=%2F&empty=#Route%2f"
      ),
      SafeSensitiveValue(
        "empty_query_and_fragment",
        value: "https://empty-markers.test/path?#"
      ),
    ]
  )
  func retainsExactSubmittedSpelling(testCase: SafeSensitiveValue) throws {
    let request = try makeRequest(rawURL: testCase.value, waitBudgetMilliseconds: 50)
    let object = try requireJSONObject(HezoJSON.makeEncoder().encode(request))

    #expect(object["url"] as? String == testCase.value)
  }

  @Test func rawUnicodeIDNIsEncodedInsteadOfASCIIHost() throws {
    let rawURL = "https://b\u{00FC}cher.test/path"
    let validatedURL = try requireValidatedURL(rawURL)
    let request = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: 50
    )
    let encodedData = try HezoJSON.makeEncoder().encode(request)
    let object = try requireJSONObject(encodedData)
    let encodedJSON = try #require(String(data: encodedData, encoding: .utf8))
    let rawSubmissionWasUsed =
      object["url"] as? String == rawURL
      && validatedURL.asciiHost == "xn--bcher-kva.test"
      && encodedJSON.contains(validatedURL.asciiHost) == false

    #expect(rawSubmissionWasUsed, "Encoding must never reconstruct a URL from parsed components.")
  }

  @Test(
    "HTTP, explicit 443, and syntactically valid unsupported ports remain encodable",
    arguments: [
      SafeCase(
        "http",
        payload: PortExpectation(
          rawURL: "http://ports.test/path",
          explicitPort: nil,
          disposition: .supported
        )
      ),
      SafeCase(
        "explicit_443",
        payload: PortExpectation(
          rawURL: "https://ports.test:443/path",
          explicitPort: 443,
          disposition: .supported
        )
      ),
      SafeCase(
        "unsupported_81",
        payload: PortExpectation(
          rawURL: "https://ports.test:81/path",
          explicitPort: 81,
          disposition: .unsupported
        )
      ),
    ]
  )
  func acceptedPortSyntaxEncodes(testCase: SafeCase<PortExpectation>) throws {
    let expectation = testCase.payload
    let validatedURL = try requireValidatedURL(expectation.rawURL)
    let request = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: 50
    )
    let object = try requireJSONObject(HezoJSON.makeEncoder().encode(request))
    let validationMatches =
      validatedURL.explicitPort == expectation.explicitPort
      && validatedURL.portDisposition == expectation.disposition

    #expect(validationMatches)
    #expect(object["url"] as? String == expectation.rawURL)
  }

  @Test func waitBudgetAcceptsBothBoundariesAndRejectsAdjacentValues() throws {
    let validatedURL = try requireValidatedURL("https://wait-budget.test/")
    let minimum = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: 0
    )
    let maximum = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: CheckRequestV1.maximumWaitBudgetMilliseconds
    )

    #expect(minimum.waitBudgetMilliseconds == 0)
    #expect(
      maximum.waitBudgetMilliseconds == CheckRequestV1.maximumWaitBudgetMilliseconds
    )
    #expect(throws: CheckRequestContractError.invalidWaitBudget) {
      try CheckRequestV1(validatedURL: validatedURL, waitBudgetMilliseconds: -1)
    }
    #expect(throws: CheckRequestContractError.invalidWaitBudget) {
      try CheckRequestV1(
        validatedURL: validatedURL,
        waitBudgetMilliseconds: CheckRequestV1.maximumWaitBudgetMilliseconds + 1
      )
    }
  }

  @Test func exact8192ByteSubmissionValidatesAndEncodes() throws {
    let rawURL = makeMaximumLengthURL()
    let request = try makeRequest(rawURL: rawURL, waitBudgetMilliseconds: 50)
    let object = try requireJSONObject(HezoJSON.makeEncoder().encode(request))
    let encodedURL = try #require(object["url"] as? String)

    #expect(rawURL.utf8.count == SubmittedURL.maximumUTF8ByteCount)
    #expect(encodedURL == rawURL)
    #expect(encodedURL.utf8.count == SubmittedURL.maximumUTF8ByteCount)
  }

  @Test func overLimitInputsCannotReachRequestConstruction() {
    let prefix = "https://over-limit.test/"
    let asciiOverLimit =
      prefix
      + String(
        repeating: "a",
        count: SubmittedURL.maximumUTF8ByteCount - prefix.utf8.count + 1
      )
    let multibyteOverLimit =
      prefix
      + String(
        repeating: "\u{00E9}",
        count: ((SubmittedURL.maximumUTF8ByteCount - prefix.utf8.count) / 2) + 1
      )
    let fixtures = [asciiOverLimit, multibyteOverLimit]

    #expect(asciiOverLimit.utf8.count == SubmittedURL.maximumUTF8ByteCount + 1)
    #expect(multibyteOverLimit.count < SubmittedURL.maximumUTF8ByteCount)
    #expect(multibyteOverLimit.utf8.count > SubmittedURL.maximumUTF8ByteCount)

    for fixture in fixtures {
      guard
        case .rejected(let problem) =
          ManualURLInputValidator.isolatedTestFixture.validate(fixture)
      else {
        Issue.record(
          "An over-limit input must not produce the validated value required by a request.")
        continue
      }
      #expect(problem == .urlTooLong)
    }
  }

  @Test(
    "Unsupported schemes, user information, controls, and ambiguous hosts fail validation",
    arguments: [
      SafeURLCase<ManualURLInputProblem>(
        "unsupported_scheme",
        input: "ftp://invalid-request.test/resource",
        expected: .unsupportedScheme
      ),
      SafeURLCase(
        "user_information",
        input: "https://user:password@invalid-request.test/",
        expected: .invalidURL
      ),
      SafeURLCase(
        "control_character",
        input: "https://invalid-request.test/path\nnext",
        expected: .invalidURL
      ),
      SafeURLCase(
        "ambiguous_ipv4",
        input: "http://127.1/",
        expected: .invalidURL
      ),
    ]
  )
  func invalidURLInputsNeverProduceARequestValue(
    testCase: SafeURLCase<ManualURLInputProblem>
  ) {
    let outcome = ManualURLInputValidator.isolatedTestFixture.validate(testCase.input)
    guard case .rejected(let problem) = outcome else {
      Issue.record(
        "Rejected URL syntax must not produce the validated value required by a request.")
      return
    }

    #expect(problem == testCase.expected)
  }

  @Test func onlyEncodingMayRevealTheSubmittedCanary() throws {
    let canary = "CHECK_REQUEST_CANARY_6d29"
    let rawURL = "https://canary.test/path?token=\(canary)#private"
    let validatedURL = try requireValidatedURL(rawURL)
    let request = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: 50
    )
    let encodedData = try HezoJSON.makeEncoder().encode(request)
    let encodedObject = try requireJSONObject(encodedData)
    let encodedURL = try #require(encodedObject["url"] as? String)
    let encodedJSON = try #require(String(data: encodedData, encoding: .utf8))
    let mirrorChildren = Array(request.customMirror.children)
    let requestRenderings =
      [
        request.description,
        request.debugDescription,
        String(describing: request),
        String(reflecting: request),
      ] + mirrorChildren.map { String(describing: $0.value) }

    var observedError: CheckRequestContractError?
    do {
      _ = try CheckRequestV1(validatedURL: validatedURL, waitBudgetMilliseconds: -1)
      Issue.record("An invalid wait budget must fail request construction.")
    } catch let error as CheckRequestContractError {
      observedError = error
    } catch {
      Issue.record("Request construction must use its bounded contract error.")
    }
    let contractError = try #require(observedError)
    let errorRenderings = [
      contractError.description,
      contractError.debugDescription,
      contractError.errorDescription ?? "",
      contractError.localizedDescription,
      String(describing: contractError),
      String(reflecting: contractError),
      (contractError as NSError).localizedDescription,
      String(reflecting: contractError as NSError),
    ]
    let requestRenderingsAreRedacted = requestRenderings.allSatisfy {
      $0 == LogSafeURLRedactor.replacement && $0.contains(canary) == false
    }
    let errorRenderingsAreBoundedAndContentFree = errorRenderings.allSatisfy {
      $0.utf8.count <= 128 && $0.contains(canary) == false && $0.contains(rawURL) == false
    }

    #expect(encodedURL == rawURL && encodedJSON.contains(canary))
    #expect(requestRenderingsAreRedacted)
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(errorRenderingsAreBoundedAndContentFree)
    #expect(contractError == .invalidWaitBudget)
  }

  @Test func repeatedEncodingIsDeterministic() throws {
    let request = try makeRequest(
      rawURL: "https://deterministic.test/path?one=1&one=%2F#fragment",
      waitBudgetMilliseconds: 1_200
    )
    var encodings = Set<Data>()

    for _ in 0..<64 {
      encodings.insert(try HezoJSON.makeEncoder().encode(request))
    }

    #expect(encodings.count == 1)
  }
}

private enum CheckRequestV1TestError: Error {
  case expectedAcceptedURL
  case expectedJSONObject
}

private let checkRequestRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func makeRequest(
  rawURL: String,
  waitBudgetMilliseconds: Int
) throws -> CheckRequestV1 {
  try CheckRequestV1(
    validatedURL: requireValidatedURL(rawURL),
    waitBudgetMilliseconds: waitBudgetMilliseconds
  )
}

private func requireValidatedURL(_ rawURL: String) throws -> ValidatedManualURL {
  guard
    case .accepted(let validatedURL) =
      ManualURLInputValidator.isolatedTestFixture.validate(rawURL)
  else {
    throw CheckRequestV1TestError.expectedAcceptedURL
  }
  return validatedURL
}

private func requireJSONObject(_ data: Data) throws -> [String: Any] {
  guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw CheckRequestV1TestError.expectedJSONObject
  }
  return object
}

private func makeMaximumLengthURL() -> String {
  let prefix = "https://maximum-length.test/"
  return prefix
    + String(
      repeating: "a",
      count: SubmittedURL.maximumUTF8ByteCount - prefix.utf8.count
    )
}

private func isCheckRequestDecodable<Value>(_: Value.Type) -> Bool {
  false
}

private func isCheckRequestDecodable<Value: Decodable>(_: Value.Type) -> Bool {
  true
}
