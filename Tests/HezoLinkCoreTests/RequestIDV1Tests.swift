import Foundation
import Testing

@testable import HezoLinkCore

struct RequestIDV1Tests {
  @Test func constantsAndPublicConformancesAreExact() throws {
    let value = try RequestIDV1(validating: "request-id")

    #expect(RequestIDV1.minimumByteCount == 1)
    #expect(RequestIDV1.maximumByteCount == 128)
    requireRequestIDConformances(value)
  }

  @Test func exactLengthBoundariesAreEnforced() throws {
    let minimum = String(repeating: "A", count: RequestIDV1.minimumByteCount)
    let maximum = String(repeating: "z", count: RequestIDV1.maximumByteCount)

    #expect(try RequestIDV1(validating: minimum).rawValue == minimum)
    #expect(try RequestIDV1(validating: maximum).rawValue == maximum)
    #expect(throws: RequestIDContractError.empty) {
      try RequestIDV1(validating: "")
    }
    #expect(throws: RequestIDContractError.tooLong) {
      try RequestIDV1(validating: maximum + "0")
    }
  }

  @Test func everyPublishedAlphabetByteIsAccepted() throws {
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

    for character in alphabet {
      let candidate = String(character)
      #expect(try RequestIDV1(validating: candidate).rawValue == candidate)
    }
    #expect(try RequestIDV1(validating: alphabet).rawValue == alphabet)
  }

  @Test func everyOtherASCIIByteAndRepresentativeUnicodeAreRejected() {
    let allowedBytes = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-".utf8)

    for byte in UInt8.min...0x7F where allowedBytes.contains(byte) == false {
      let candidate = String(decoding: [byte], as: UTF8.self)
      if candidate.isEmpty {
        #expect(throws: RequestIDContractError.empty) {
          try RequestIDV1(validating: candidate)
        }
      } else {
        #expect(throws: RequestIDContractError.invalidFormat) {
          try RequestIDV1(validating: candidate)
        }
      }
    }

    for candidate in ["é", "😀", "Aé", "e\u{301}"] {
      #expect(throws: RequestIDContractError.invalidFormat) {
        try RequestIDV1(validating: candidate)
      }
    }
  }

  @Test func failableRawValueInitializerEqualityAndHashingUseExactWireBytes() throws {
    let first = try #require(RequestIDV1(rawValue: "Case-Sensitive_09"))
    let same = try RequestIDV1(validating: "Case-Sensitive_09")
    let differentCase = try RequestIDV1(validating: "case-Sensitive_09")

    #expect(first == same)
    #expect(first != differentCase)
    #expect(Set([first, same, differentCase]).count == 2)
    #expect(RequestIDV1(rawValue: "") == nil)
    #expect(RequestIDV1(rawValue: "request/id") == nil)
    #expect(RequestIDV1(rawValue: String(repeating: "a", count: 129)) == nil)
  }

  @Test func codableRoundTripPreservesExactWireBytes() throws {
    let candidate = "AZaz09_-request"
    let value = try RequestIDV1(validating: candidate)
    let encoded = try HezoJSON.makeEncoder().encode(value)
    let decoded = try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: encoded)

    #expect(String(data: encoded, encoding: .utf8) == "\"\(candidate)\"")
    #expect(decoded == value)
    #expect(decoded.rawValue == candidate)
  }

  @Test(
    "Decoding rejects invalid strings and every non-string JSON shape",
    arguments: [
      "\"\"",
      "\"request/id\"",
      "\"" + String(repeating: "a", count: 129) + "\"",
      "null",
      "42",
      "true",
      "{}",
      "[]",
    ]
  )
  func decodingRejectsInvalidValues(json: String) {
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: Data(json.utf8))
    }
  }

  @Test func descriptionDebugAndReflectionAreFixedRedactions() throws {
    let candidate = "PRIVATE_REQUEST_ID_CANARY_8f29"
    let value = try RequestIDV1(validating: candidate)
    let mirrorChildren = Array(value.customMirror.children)
    let renderings =
      [
        value.description,
        value.debugDescription,
        String(describing: value),
        String(reflecting: value),
      ] + mirrorChildren.map { String(describing: $0.value) }

    #expect(value.rawValue == candidate)
    #expect(value.description == "<redacted-request-id>")
    #expect(value.debugDescription == value.description)
    #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(mirrorChildren.first?.value as? String == "<redacted-request-id>")
  }

  @Test func validationAndDecodingErrorsAreBoundedAndPayloadFree() throws {
    let errors: [RequestIDContractError] = [.empty, .tooLong, .invalidFormat]

    for error in errors {
      let nsError = error as NSError
      let renderings = [
        error.description,
        error.debugDescription,
        error.localizedDescription,
        nsError.localizedDescription,
        String(reflecting: error),
        String(reflecting: nsError),
      ]

      #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
      #expect(error.debugDescription == error.description)
      #expect(error.errorDescription == error.description)
      #expect(Mirror(reflecting: error).children.isEmpty)
    }

    let candidate = "PRIVATE_INVALID_REQUEST_ID_CANARY/secret"
    let invalidJSON = try JSONEncoder().encode(candidate)
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: invalidJSON)
      Issue.record("An invalid decoded request identifier must be rejected.")
    } catch {
      let nsError = error as NSError
      let renderings = [
        String(describing: error),
        String(reflecting: error),
        error.localizedDescription,
        nsError.localizedDescription,
        String(reflecting: nsError),
      ]
      #expect(
        renderings.allSatisfy {
          $0.utf8.count <= 256 && $0.contains(candidate) == false
        }
      )
    }
  }

  @Test func bothEnvelopesAcceptAndEncodeTheSameRequestIdentifiers() throws {
    let candidates = [
      "A",
      "AZaz09_-",
      String(repeating: "R", count: RequestIDV1.maximumByteCount),
    ]

    for candidate in candidates {
      let problem = try makeRequestIDProblem(requestID: candidate)
      let pending = try makeRequestIDPendingResponse(requestID: candidate)
      let problemObject = try requireRequestIDJSONObject(
        HezoJSON.makeEncoder().encode(problem)
      )
      let pendingObject = try requireRequestIDJSONObject(
        HezoJSON.makeEncoder().encode(pending)
      )

      #expect(problem.requestID == candidate)
      #expect(pending.requestID == candidate)
      #expect(problemObject["request_id"] as? String == candidate)
      #expect(pendingObject["request_id"] as? String == candidate)
    }
  }

  @Test func bothEnvelopesPreserveTheirLegacyConstructionErrors() throws {
    let cases:
      [(
        candidate: String,
        requestIDError: RequestIDContractError,
        problemError: ProblemContractError,
        pendingError: PendingCheckResponseContractError
      )] = [
        ("", .empty, .emptyField, .emptyRequestID),
        (
          String(repeating: "a", count: RequestIDV1.maximumByteCount + 1),
          .tooLong,
          .fieldTooLong,
          .requestIDTooLong
        ),
        ("request/id", .invalidFormat, .invalidFieldFormat, .invalidRequestIDFormat),
        ("réquest", .invalidFormat, .invalidFieldFormat, .invalidRequestIDFormat),
      ]

    for testCase in cases {
      #expect(throws: testCase.requestIDError) {
        try RequestIDV1(validating: testCase.candidate)
      }
      #expect(throws: testCase.problemError) {
        try makeRequestIDProblem(requestID: testCase.candidate)
      }
      #expect(throws: testCase.pendingError) {
        try makeRequestIDPendingResponse(requestID: testCase.candidate)
      }
    }
  }

  @Test func bothEnvelopeDecodersKeepBoundedContentFreeFailures() throws {
    let candidate = "PRIVATE_ENVELOPE_REQUEST_ID_CANARY/secret"
    let problemData = try JSONSerialization.data(
      withJSONObject: [
        "type": "about:blank",
        "title": "Invalid request identifier",
        "status": 422,
        "code": "invalid_url",
        "detail": "Bounded detail.",
        "request_id": candidate,
        "retryable": false,
      ]
    )
    let pendingData = try JSONSerialization.data(
      withJSONObject: [
        "schema_version": 1,
        "status": "pending",
        "check_token": String(repeating: "A", count: 43),
        "retry_after_ms": 750,
        "expires_at": "2026-08-11T10:30:00Z",
        "request_id": candidate,
      ]
    )

    expectRequestIDEnvelopeDecodeFailure(Problem.self, from: problemData, candidate: candidate)
    expectRequestIDEnvelopeDecodeFailure(
      PendingCheckResponseV1.self,
      from: pendingData,
      candidate: candidate
    )
  }

  @Test func concurrentHashEncodeAndDecodeAreDeterministic() async throws {
    let value = try RequestIDV1(validating: "Concurrent_Request-ID_09")
    let expected = try HezoJSON.makeEncoder().encode(value)
    let results = try await withThrowingTaskGroup(of: (RequestIDV1, Data).self) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(value)
          let decoded = try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: encoded)
          return (decoded, encoded)
        }
      }

      var decodedValues = Set<RequestIDV1>()
      var encodedValues = Set<Data>()
      for try await (decoded, encoded) in group {
        decodedValues.insert(decoded)
        encodedValues.insert(encoded)
      }
      return (decodedValues, encodedValues)
    }

    #expect(results.0 == [value])
    #expect(results.1 == [expected])
  }
}

private enum RequestIDV1TestError: Error {
  case expectedJSONObject
}

private func requireRequestIDConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String
{
  _ = value
}

private func makeRequestIDProblem(requestID: String) throws -> Problem {
  try Problem(
    type: "about:blank",
    title: "Invalid request identifier",
    status: 422,
    code: .invalidURL,
    detail: "Bounded detail.",
    requestID: requestID,
    retryable: false
  )
}

private func makeRequestIDPendingResponse(requestID: String) throws -> PendingCheckResponseV1 {
  try PendingCheckResponseV1(
    checkToken: CheckTokenV1(validating: String(repeating: "A", count: 43)),
    retryAfterMilliseconds: 750,
    expiresAt: Date(timeIntervalSince1970: 1_786_444_200),
    requestID: requestID
  )
}

private func requireRequestIDJSONObject(_ data: Data) throws -> [String: Any] {
  guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
    throw RequestIDV1TestError.expectedJSONObject
  }
  return object
}

private func expectRequestIDEnvelopeDecodeFailure<Value: Decodable>(
  _ type: Value.Type,
  from data: Data,
  candidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(type, from: data)
    Issue.record(
      "An invalid envelope request identifier must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    let renderings = [String(describing: error), String(reflecting: error)]
    #expect(
      renderings.allSatisfy {
        $0.utf8.count <= 256 && $0.contains(candidate) == false
      },
      sourceLocation: sourceLocation
    )
  } catch {
    Issue.record(
      "The envelope decoder used an unexpected error category.", sourceLocation: sourceLocation)
  }
}
