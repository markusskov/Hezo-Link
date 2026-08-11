import Foundation
import Testing

@testable import HezoLinkCore

struct ContractValueTests {
  @Test(
    "Forward-compatible contract values preserve valid wire values",
    arguments: [
      "a",
      "exact_url",
      "future_reason_2",
      "a" + String(repeating: "b", count: 127),
    ]
  )
  func validValuesRoundTrip(rawValue: String) throws {
    let value = try ReasonCode(validating: rawValue)
    let data = try HezoJSON.makeEncoder().encode(value)
    let decoded = try HezoJSON.makeResponseDecoder().decode(ReasonCode.self, from: data)

    #expect(decoded.rawValue == rawValue)
  }

  @Test(
    "Check-response statuses use only their exact wire strings",
    arguments: [
      (CheckResponseStatus.complete, "complete"),
      (CheckResponseStatus.pending, "pending"),
    ]
  )
  func checkResponseStatusesRoundTripExactly(
    testCase: (CheckResponseStatus, String)
  ) throws {
    let (status, expectedWireValue) = testCase
    let data = try HezoJSON.makeEncoder().encode(status)
    let encodedValue = try #require(String(data: data, encoding: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      CheckResponseStatus.self,
      from: data
    )

    #expect(encodedValue == "\"\(expectedWireValue)\"")
    #expect(decoded.rawValue == expectedWireValue)
  }

  @Test func checkResponseStatusCasesKeepTheirExactOrderAndSet() {
    let wireValues = CheckResponseStatus.allCases.map(\.rawValue)

    #expect(wireValues == ["complete", "pending"])
    #expect(Set(wireValues) == Set(["complete", "pending"]))
    #expect(wireValues.count == Set(wireValues).count)
  }

  @Test(
    "Check-response statuses reject aliases and other public vocabularies",
    arguments: [
      "completed",
      "analyzing",
      "accepted",
      "unknown",
      "retry",
      "Complete",
      "",
    ]
  )
  func checkResponseStatusesRejectOtherStrings(candidate: String) throws {
    #expect(CheckResponseStatus(rawValue: candidate) == nil)

    let data = try JSONEncoder().encode(candidate)
    expectCheckResponseStatusDecodeFailure(from: data, rejectedCandidate: candidate)
  }

  @Test(
    "Check-response statuses reject null and non-string JSON values",
    arguments: ["null", "200", "true", "{}", "[]"]
  )
  func checkResponseStatusesRejectWrongJSONTypes(json: String) throws {
    let data = try #require(json.data(using: .utf8))

    expectCheckResponseStatusDecodeFailure(from: data)
  }

  @Test func checkResponseStatusDecodeErrorsDoNotReflectRejectedContent() throws {
    let candidate = "PRIVATE_CHECK_RESPONSE_STATUS_SENTINEL"
    let data = try JSONEncoder().encode(candidate)

    expectCheckResponseStatusDecodeFailure(from: data, rejectedCandidate: candidate)
  }

  @Test(
    "Invalid stable values return the exact bounded error",
    arguments: [
      ("_leading", ContractValueError.invalidFormat),
      ("trailing_", ContractValueError.invalidFormat),
      ("double__underscore", ContractValueError.invalidFormat),
      ("Uppercase", ContractValueError.invalidFormat),
      ("9leading_digit", ContractValueError.invalidFormat),
      ("contains-hyphen", ContractValueError.invalidFormat),
      ("nonascii_å", ContractValueError.invalidFormat),
      (
        "a" + String(repeating: "b", count: 128),
        ContractValueError.tooLong
      ),
    ]
  )
  func invalidValuesAreRejected(testCase: (String, ContractValueError)) {
    let (rawValue, expectedError) = testCase

    #expect(throws: expectedError) {
      try ReasonCode(validating: rawValue)
    }
  }

  @Test func emptyValueHasSpecificBoundedError() {
    #expect(throws: ContractValueError.empty) {
      try ProblemCode(validating: "")
    }
  }

  @Test func everyDecoderOmitsRejectedCandidate() throws {
    let candidate = "AttackerSecretValue"
    let data = try #require("\"\(candidate)\"".data(using: .utf8))

    try expectDecodeErrorOmitsCandidate(ReasonCode.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ProblemCode.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ConfidenceCategory.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(EvaluatedScope.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ReasonFamily.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ReasonSeverity.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(FreshnessCategory.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(LocalizationKey.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(VerdictLabel.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(RecommendedAction.self, from: data, candidate: candidate)
  }

  @Test func localizationKeysHaveBoundedDotSeparatedGrammar() throws {
    let valid = try LocalizationKey(
      validating: "verdict.reason.brand_impersonation_unrelated_domain"
    )

    #expect(valid.rawValue == "verdict.reason.brand_impersonation_unrelated_domain")
    let maximumKey =
      "a" + String(repeating: "b", count: 127) + ".c"
      + String(repeating: "d", count: 126)
    let overlongKey =
      "a" + String(repeating: "b", count: 127) + ".c"
      + String(repeating: "d", count: 127)
    #expect(try LocalizationKey(validating: maximumKey).rawValue == maximumKey)
    #expect(throws: ContractValueError.empty) {
      try LocalizationKey(validating: "verdict..reason")
    }
    #expect(throws: ContractValueError.invalidFormat) {
      try LocalizationKey(validating: "verdict.Reason")
    }
    #expect(throws: ContractValueError.empty) {
      try LocalizationKey(validating: "")
    }
    #expect(throws: ContractValueError.tooLong) {
      try LocalizationKey(validating: overlongKey)
    }
  }

  @Test func rawRepresentableInitializersPreserveOnlyValidValues() {
    #expect(ReasonCode(rawValue: "valid_reason")?.rawValue == "valid_reason")
    #expect(ReasonCode(rawValue: "InvalidReason") == nil)
    #expect(LocalizationKey(rawValue: "verdict.reason")?.rawValue == "verdict.reason")
    #expect(LocalizationKey(rawValue: "verdict..reason") == nil)
  }

  @Test func knownAndFutureConfidenceValuesRemainDistinct() throws {
    let future = try ConfidenceCategory(validating: "very_high")

    #expect(ConfidenceCategory.low.rawValue == "low")
    #expect(ConfidenceCategory.medium.rawValue == "medium")
    #expect(ConfidenceCategory.high.rawValue == "high")
    #expect(future.rawValue == "very_high")
  }

  @Test func exactAndFutureEvaluatedScopesRemainDistinct() throws {
    let future = try EvaluatedScope(validating: "future_narrow_scope")

    #expect(EvaluatedScope.exactURL.rawValue == "exact_url")
    #expect(future.rawValue == "future_narrow_scope")
  }

  private func expectCheckResponseStatusDecodeFailure(
    from data: Data,
    rejectedCandidate: String? = nil
  ) {
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatus.self, from: data)
      Issue.record("Expected invalid check-response status to be rejected.")
    } catch let error as DecodingError {
      if let rejectedCandidate, rejectedCandidate.isEmpty == false {
        #expect(String(describing: error).contains(rejectedCandidate) == false)
        #expect(String(reflecting: error).contains(rejectedCandidate) == false)
      }
    } catch {
      Issue.record("Check-response status decoding used an unexpected error category.")
    }
  }

  private func expectDecodeErrorOmitsCandidate<Value: Decodable>(
    _ type: Value.Type,
    from data: Data,
    candidate: String
  ) throws {
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(type, from: data)
      Issue.record("Expected invalid contract value to be rejected.")
    } catch {
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    }
  }
}

struct PendingCheckResponseV1Tests {
  @Test func validConstructionAndEncodingMatchFrozenWireContract() throws {
    let expiry = try canonicalPendingExpiry()
    let token = try CheckTokenV1(validating: canonicalPendingToken)
    let response = try PendingCheckResponseV1(
      checkToken: token,
      retryAfterMilliseconds: 750,
      expiresAt: expiry,
      requestID: "plane-local-random-id"
    )
    let data = try HezoJSON.makeEncoder().encode(response)
    let json = try #require(String(data: data, encoding: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      PendingCheckResponseV1.self,
      from: data
    )
    let expected =
      #"{"check_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","expires_at":"2026-08-11T10:30:00Z","request_id":"plane-local-random-id","retry_after_ms":750,"schema_version":1,"status":"pending"}"#

    #expect(response.checkToken == token)
    #expect(response.retryAfterMilliseconds == 750)
    #expect(response.expiresAt == expiry)
    #expect(response.requestID == "plane-local-random-id")
    #expect(json == expected)
    #expect(decoded == response)
  }

  @Test func encoderEmitsExactlySixFrozenMembers() throws {
    let response = try makePendingResponse()
    let data = try HezoJSON.makeEncoder().encode(response)
    let object = try requirePendingJSONObject(data)
    let expectedKeys: Set<String> = [
      "schema_version", "status", "check_token", "retry_after_ms", "expires_at",
      "request_id",
    ]

    #expect(Set(object.keys) == expectedKeys)
    #expect(object["schema_version"] as? Int == PendingCheckResponseV1.schemaVersion)
    #expect(object["status"] as? String == PendingCheckResponseV1.status.rawValue)
    #expect(object["check_token"] as? String == canonicalPendingToken)
    #expect(object["retry_after_ms"] as? Int == 750)
    #expect(object["expires_at"] as? String == canonicalPendingExpiryWireValue)
    #expect(object["request_id"] as? String == "plane-local-random-id")
  }

  @Test(
    "Canonical tokens cover both base64url alphabet extremes",
    arguments: [
      String(repeating: "A", count: CheckTokenV1.encodedCharacterCount),
      String(repeating: "_", count: CheckTokenV1.encodedCharacterCount - 1) + "8",
    ]
  )
  func canonicalTokenAlphabetBoundariesRoundTrip(candidate: String) throws {
    let token = try CheckTokenV1(validating: candidate)
    let data = try HezoJSON.makeEncoder().encode(token)
    let json = try #require(String(data: data, encoding: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: data)

    #expect(json == "\"\(candidate)\"")
    #expect(decoded == token)
  }

  @Test(
    "Every canonical final base64url character is admitted",
    arguments: ["A", "E", "I", "M", "Q", "U", "Y", "c", "g", "k", "o", "s", "w", "0", "4", "8"]
  )
  func canonicalTokenFinalCharactersAreAccepted(finalCharacter: String) throws {
    let candidate = String(repeating: "A", count: 42) + finalCharacter
    let token = try CheckTokenV1(validating: candidate)
    let data = try HezoJSON.makeEncoder().encode(token)

    #expect(try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: data) == token)
  }

  @Test(
    "Length, alphabet, padding, Unicode, and noncanonical tail mutations are rejected",
    arguments: [
      String(repeating: "A", count: 42),
      String(repeating: "A", count: 44),
      "+" + String(repeating: "A", count: 42),
      "/" + String(repeating: "A", count: 42),
      "=" + String(repeating: "A", count: 42),
      " " + String(repeating: "A", count: 42),
      String(repeating: "A", count: 42) + "é",
      String(canonicalPendingToken.dropLast()) + "9",
    ]
  )
  func tokenMutationsAreRejected(candidate: String) throws {
    #expect(throws: CheckTokenContractError.invalidFormat) {
      try CheckTokenV1(validating: candidate)
    }

    let data = try JSONEncoder().encode(candidate)
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: data)
    }
  }

  @Test(
    "Token decoding rejects non-string JSON values",
    arguments: ["null", "42", "true", "{}", "[]"]
  )
  func tokenDecoderRejectsWrongJSONTypes(json: String) {
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: Data(json.utf8))
    }
  }

  @Test func retryDelayAcceptsBothBoundariesAndRejectsAdjacentValues() throws {
    let token = try CheckTokenV1(validating: canonicalPendingToken)
    let expiry = try canonicalPendingExpiry()
    let minimum = try PendingCheckResponseV1(
      checkToken: token,
      retryAfterMilliseconds: PendingCheckResponseV1.minimumRetryAfterMilliseconds,
      expiresAt: expiry,
      requestID: "request-id"
    )
    let maximum = try PendingCheckResponseV1(
      checkToken: token,
      retryAfterMilliseconds: PendingCheckResponseV1.maximumRetryAfterMilliseconds,
      expiresAt: expiry,
      requestID: "request-id"
    )

    #expect(minimum.retryAfterMilliseconds == 1)
    #expect(maximum.retryAfterMilliseconds == 900_000)
    #expect(throws: PendingCheckResponseContractError.invalidRetryAfterMilliseconds) {
      try PendingCheckResponseV1(
        checkToken: token,
        retryAfterMilliseconds: 0,
        expiresAt: expiry,
        requestID: "request-id"
      )
    }
    #expect(throws: PendingCheckResponseContractError.invalidRetryAfterMilliseconds) {
      try PendingCheckResponseV1(
        checkToken: token,
        retryAfterMilliseconds: 900_001,
        expiresAt: expiry,
        requestID: "request-id"
      )
    }
  }

  @Test(
    "Retry decoding rejects adjacent, fractional, wrong-type, and null values",
    arguments: ["0", "900001", "750.5", "\"750\"", "null"]
  )
  func retryDelayDecoderRejectsInvalidValues(retryJSON: String) {
    let data = pendingResponseJSON(retryAfterMillisecondsJSON: retryJSON)

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    }
  }

  @Test func requestIdentifierAcceptsExactBoundariesAndRejectsInvalidValues() throws {
    let oneByte = try makePendingResponse(requestID: "A")
    let maximumValue = String(
      repeating: "a",
      count: PendingCheckResponseV1.maximumRequestIDByteCount
    )
    let maximum = try makePendingResponse(requestID: maximumValue)

    #expect(oneByte.requestID == "A")
    #expect(maximum.requestID == maximumValue)
    #expect(throws: PendingCheckResponseContractError.emptyRequestID) {
      try makePendingResponse(requestID: "")
    }
    #expect(throws: PendingCheckResponseContractError.requestIDTooLong) {
      try makePendingResponse(requestID: maximumValue + "a")
    }
    #expect(throws: PendingCheckResponseContractError.invalidRequestIDFormat) {
      try makePendingResponse(requestID: "request/id")
    }
    #expect(throws: PendingCheckResponseContractError.invalidRequestIDFormat) {
      try makePendingResponse(requestID: "réquest")
    }
    _ = try makePendingResponse(requestID: "AZaz09_-")
  }

  @Test(
    "Request-ID decoding revalidates content and type",
    arguments: [
      "\"\"",
      "\"request/id\"",
      "\"" + String(repeating: "a", count: 129) + "\"",
      "null",
      "42",
    ]
  )
  func requestIdentifierDecoderRejectsInvalidValues(requestIDJSON: String) {
    let data = pendingResponseJSON(requestIDJSON: requestIDJSON)

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    }
  }

  @Test(
    "Schema and status constants reject alternate values and types",
    arguments: [
      ("0", "\"pending\""),
      ("2", "\"pending\""),
      ("\"1\"", "\"pending\""),
      ("null", "\"pending\""),
      ("1", "\"complete\""),
      ("1", "\"future\""),
      ("1", "42"),
      ("1", "null"),
    ]
  )
  func schemaAndStatusFailuresAreRejected(testCase: (String, String)) {
    let data = pendingResponseJSON(
      schemaVersionJSON: testCase.0,
      statusJSON: testCase.1
    )

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    }
  }

  @Test(
    "Every known completed-only key is rejected even when null",
    arguments: [
      "verdict", "target", "analysis", "source_notices", "versions", "evaluated_at",
      "valid_until", "block_eligible",
    ]
  )
  func completedOnlyKeysAreRejectedWhenPresent(key: String) {
    let data = pendingResponseJSON(additionalMember: "\"\(key)\":null")

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    }
  }

  @Test func genuinelyUnknownAdditiveFieldsAreAcceptedAndDropped() throws {
    let data = pendingResponseJSON(
      additionalMember: "\"future_optional\":{\"nested\":[true,null]}"
    )
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      PendingCheckResponseV1.self,
      from: data
    )
    let encoded = try HezoJSON.makeEncoder().encode(decoded)
    let object = try requirePendingJSONObject(encoded)
    let expected = try makePendingResponse()

    #expect(decoded == expected)
    #expect(object["future_optional"] == nil)
    #expect(Set(object.keys).count == 6)
  }

  @Test(
    "HezoJSON rejects noncanonical pending expiry spellings",
    arguments: [
      "\"2026-08-11T10:30:00.000Z\"",
      "\"2026-08-11T12:30:00+02:00\"",
      "\"2026-08-11t10:30:00z\"",
      "\"0000-01-01T00:00:00Z\"",
      "1786444200",
    ]
  )
  func decoderRequiresCanonicalExpiry(expiryJSON: String) {
    let data = pendingResponseJSON(expiresAtJSON: expiryJSON)

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    }
  }

  @Test func constructorRejectsNoncanonicalExpiryValues() throws {
    let token = try CheckTokenV1(validating: canonicalPendingToken)

    #expect(throws: PendingCheckResponseContractError.invalidExpiry) {
      try PendingCheckResponseV1(
        checkToken: token,
        retryAfterMilliseconds: 750,
        expiresAt: Date(timeIntervalSince1970: 1_786_444_200.5),
        requestID: "request-id"
      )
    }
    #expect(throws: PendingCheckResponseContractError.invalidExpiry) {
      try PendingCheckResponseV1(
        checkToken: token,
        retryAfterMilliseconds: 750,
        expiresAt: Date(timeIntervalSince1970: .greatestFiniteMagnitude),
        requestID: "request-id"
      )
    }
  }

  @Test func descriptionsDebugReflectionAndErrorsOmitPrivacyCanaries() throws {
    let token = try CheckTokenV1(validating: privacyPendingToken)
    let response = try makePendingResponse(
      token: token,
      requestID: privacyPendingRequestID
    )
    let tokenMirror = Array(token.customMirror.children)
    let responseMirror = Array(response.customMirror.children)
    let encodedJSON = try #require(
      String(data: HezoJSON.makeEncoder().encode(response), encoding: .utf8)
    )
    let safeRenderings =
      [
        token.description,
        token.debugDescription,
        String(describing: token),
        String(reflecting: token),
        response.description,
        response.debugDescription,
        String(describing: response),
        String(reflecting: response),
      ] + tokenMirror.map { String(describing: $0.value) }
      + responseMirror.map { String(describing: $0.value) }

    #expect(encodedJSON.contains(privacyPendingToken))
    #expect(encodedJSON.contains(privacyPendingRequestID))
    #expect(
      safeRenderings.allSatisfy {
        $0.contains(privacyPendingToken) == false
          && $0.contains(privacyPendingRequestID) == false
      }
    )
    #expect(tokenMirror.count == 1)
    #expect(tokenMirror.first?.label == "value")
    #expect(responseMirror.count == 1)
    #expect(responseMirror.first?.label == "value")

    let invalidTokenCandidate = "PRIVATE_INVALID_CHECK_TOKEN_CANARY"
    do {
      _ = try CheckTokenV1(validating: invalidTokenCandidate)
      Issue.record("An invalid token candidate must be rejected.")
    } catch {
      expectErrorOmitsPendingCanaries(
        error,
        canaries: [invalidTokenCandidate, privacyPendingToken, privacyPendingRequestID]
      )
    }

    let invalidRequestID = privacyPendingRequestID + "/secret"
    do {
      _ = try makePendingResponse(token: token, requestID: invalidRequestID)
      Issue.record("An invalid request identifier must be rejected.")
    } catch {
      expectErrorOmitsPendingCanaries(
        error,
        canaries: [invalidRequestID, privacyPendingToken, privacyPendingRequestID]
      )
    }

    let decoderCandidate = "PRIVATE_DECODER_TOKEN_CANARY"
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(
        PendingCheckResponseV1.self,
        from: pendingResponseJSON(checkTokenJSON: "\"\(decoderCandidate)\"")
      )
      Issue.record("An invalid decoded token must be rejected.")
    } catch {
      expectErrorOmitsPendingCanaries(error, canaries: [decoderCandidate])
    }
  }

  @Test func everyConstructionErrorHasFiniteLocalizedRendering() {
    let errors: [PendingCheckResponseContractError] = [
      .invalidRetryAfterMilliseconds,
      .invalidExpiry,
      .emptyRequestID,
      .requestIDTooLong,
      .invalidRequestIDFormat,
    ]

    for error in errors {
      let renderings = pendingErrorRenderings(error)
      #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
      #expect(error.errorDescription == error.description)
    }

    let tokenError = CheckTokenContractError.invalidFormat
    #expect(
      pendingErrorRenderings(tokenError).allSatisfy {
        $0.isEmpty == false && $0.utf8.count <= 128
      }
    )
    #expect(tokenError.errorDescription == tokenError.description)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let response = try makePendingResponse()
    let expected = try HezoJSON.makeEncoder().encode(response)
    let encodings = try await withThrowingTaskGroup(of: Data.self) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(response)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            PendingCheckResponseV1.self,
            from: encoded
          )
          return try HezoJSON.makeEncoder().encode(decoded)
        }
      }

      var values = Set<Data>()
      for try await value in group {
        values.insert(value)
      }
      return values
    }

    #expect(encodings == [expected])
  }
}

private enum PendingCheckResponseTestError: Error {
  case expectedJSONObject
}

private let canonicalPendingToken = String(repeating: "A", count: 43)
private let privacyPendingToken = String(repeating: "_", count: 42) + "8"
private let privacyPendingRequestID = "PRIVATE_REQUEST_ID_CANARY_8f29"
private let canonicalPendingExpiryWireValue = "2026-08-11T10:30:00Z"

private func canonicalPendingExpiry() throws -> Date {
  try HezoJSON.makeResponseDecoder().decode(
    Date.self,
    from: Data("\"\(canonicalPendingExpiryWireValue)\"".utf8)
  )
}

private func makePendingResponse(
  token: CheckTokenV1? = nil,
  retryAfterMilliseconds: Int = 750,
  expiresAt: Date? = nil,
  requestID: String = "plane-local-random-id"
) throws -> PendingCheckResponseV1 {
  try PendingCheckResponseV1(
    checkToken: token ?? CheckTokenV1(validating: canonicalPendingToken),
    retryAfterMilliseconds: retryAfterMilliseconds,
    expiresAt: expiresAt ?? canonicalPendingExpiry(),
    requestID: requestID
  )
}

private func pendingResponseJSON(
  schemaVersionJSON: String = "1",
  statusJSON: String = "\"pending\"",
  checkTokenJSON: String = "\"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"",
  retryAfterMillisecondsJSON: String = "750",
  expiresAtJSON: String = "\"2026-08-11T10:30:00Z\"",
  requestIDJSON: String = "\"plane-local-random-id\"",
  additionalMember: String? = nil
) -> Data {
  var members = [
    "\"schema_version\":\(schemaVersionJSON)",
    "\"status\":\(statusJSON)",
    "\"check_token\":\(checkTokenJSON)",
    "\"retry_after_ms\":\(retryAfterMillisecondsJSON)",
    "\"expires_at\":\(expiresAtJSON)",
    "\"request_id\":\(requestIDJSON)",
  ]
  if let additionalMember {
    members.append(additionalMember)
  }
  return Data("{\(members.joined(separator: ","))}".utf8)
}

private func requirePendingJSONObject(_ data: Data) throws -> [String: Any] {
  guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw PendingCheckResponseTestError.expectedJSONObject
  }
  return object
}

private func expectErrorOmitsPendingCanaries(
  _ error: any Error,
  canaries: [String],
  sourceLocation: SourceLocation = #_sourceLocation
) {
  let renderings = pendingErrorRenderings(error)
  #expect(
    renderings.allSatisfy { rendering in
      rendering.utf8.count <= 256
        && canaries.allSatisfy { rendering.contains($0) == false }
    },
    sourceLocation: sourceLocation
  )
}

private func pendingErrorRenderings(_ error: any Error) -> [String] {
  let nsError = error as NSError
  return [
    String(describing: error),
    String(reflecting: error),
    error.localizedDescription,
    nsError.localizedDescription,
    String(reflecting: nsError),
  ]
}
