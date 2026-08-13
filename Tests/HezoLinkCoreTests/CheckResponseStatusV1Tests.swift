import Foundation
import HezoLinkCore
import Testing

struct CheckResponseStatusV1Tests {
  @Test func casesRawValuesOrderAndPublicConformancesAreExact() {
    let statuses = CheckResponseStatusV1.allCases
    let wireValues = statuses.map(\.rawValue)

    #expect(statuses == [.complete, .pending])
    #expect(wireValues == ["complete", "pending"])
    #expect(Set(wireValues) == ["complete", "pending"])
    #expect(wireValues.count == Set(wireValues).count)
    requireCheckResponseStatusConformances(CheckResponseStatusV1.complete)
  }

  @Test(
    "Canonical statuses round-trip as exact JSON strings",
    arguments: [
      (CheckResponseStatusV1.complete, "complete"),
      (CheckResponseStatusV1.pending, "pending"),
    ]
  )
  func canonicalStatusesRoundTripExactly(
    testCase: (CheckResponseStatusV1, String)
  ) throws {
    let (status, expectedWireValue) = testCase
    let encoded = try HezoJSON.makeEncoder().encode(status)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      CheckResponseStatusV1.self,
      from: encoded
    )

    #expect(String(data: encoded, encoding: .utf8) == "\"\(expectedWireValue)\"")
    #expect(decoded == status)
    #expect(decoded.rawValue == expectedWireValue)
  }

  @Test(
    "Every frozen alias and unrelated public vocabulary is rejected",
    arguments: [
      "completed",
      "analyzing",
      "accepted",
      "unknown",
      "retry",
      "COMPLETE",
      "Complete",
      "Pending",
      "",
    ]
  )
  func aliasesAndOtherStringsAreRejected(candidate: String) throws {
    #expect(CheckResponseStatusV1(rawValue: candidate) == nil)

    expectCheckResponseStatusDataCorrupted(
      from: try JSONEncoder().encode(candidate),
      rejectedCandidate: candidate
    )
  }

  @Test(
    "Every non-string JSON shape is rejected with typeMismatch",
    arguments: [
      ("202", "Expected to decode String but found number instead."),
      ("42.5", "Expected to decode String but found number instead."),
      ("true", "Expected to decode String but found bool instead."),
      ("false", "Expected to decode String but found bool instead."),
      ("{}", "Expected to decode String but found a dictionary instead."),
      ("[]", "Expected to decode String but found an array instead."),
    ]
  )
  func wrongJSONTypesAreRejectedExactly(testCase: (String, String)) {
    expectCheckResponseStatusTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectCheckResponseStatusValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedStatusKeepsItsCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_CHECK_RESPONSE_STATUS_SENTINEL"
    let data = Data("{\"status\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(CheckResponseStatusEnvelope.self, from: data)
      Issue.record("An invalid nested check-response status must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid check-response status.")
      #expect(context.codingPath.map(\.stringValue) == ["status"])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    } catch {
      Issue.record("Check-response status decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeType() throws {
    let canonical: CheckResponseStatusV1 = .complete
    let compatibility: CheckResponseStatus = canonical
    let canonicalAgain: CheckResponseStatusV1 = compatibility
    let decodedCompatibility = try JSONDecoder().decode(
      CheckResponseStatus.self,
      from: Data("\"pending\"".utf8)
    )

    requireSameCheckResponseStatusType(CheckResponseStatus.self)
    #expect(canonicalAgain == canonical)
    #expect(decodedCompatibility == CheckResponseStatusV1.pending)
    #expect(CheckResponseStatus.allCases == CheckResponseStatusV1.allCases)
  }

  @Test func pendingResponseUsesTheCanonicalStatusWithoutWireDrift() throws {
    let response = try PendingCheckResponseV1(
      checkToken: CheckTokenV1(
        validating: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
      ),
      retryAfterMilliseconds: 750,
      expiresAt: Date(timeIntervalSince1970: 1_786_444_200),
      requestID: "plane-local-random-id"
    )
    let encoded = try HezoJSON.makeEncoder().encode(response)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"check_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","expires_at":"2026-08-11T10:30:00Z","request_id":"plane-local-random-id","retry_after_ms":750,"schema_version":1,"status":"pending"}"#
    let status: CheckResponseStatusV1 = PendingCheckResponseV1.status

    #expect(status == .pending)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let expectedEncodings: [CheckResponseStatusV1: Data] = [
      .complete: Data("\"complete\"".utf8),
      .pending: Data("\"pending\"".utf8),
    ]
    let results = try await withThrowingTaskGroup(
      of: (CheckResponseStatusV1, Data).self
    ) { group in
      for status in CheckResponseStatusV1.allCases {
        for _ in 0..<32 {
          group.addTask {
            let encoded = try HezoJSON.makeEncoder().encode(status)
            let decoded = try HezoJSON.makeResponseDecoder().decode(
              CheckResponseStatusV1.self,
              from: encoded
            )
            return (decoded, encoded)
          }
        }
      }

      var values: [(CheckResponseStatusV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.1 == expectedEncodings[$0.0] })
    #expect(Set(results.map(\.0)) == Set(CheckResponseStatusV1.allCases))
  }
}

private struct CheckResponseStatusEnvelope: Decodable {
  let status: CheckResponseStatusV1
}

private func requireCheckResponseStatusConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String,
  Value.AllCases == [Value]
{
  _ = value
}

private func requireSameCheckResponseStatusType(_ type: CheckResponseStatusV1.Type) {
  _ = type
}

private func expectCheckResponseStatusDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatusV1.self, from: data)
    Issue.record(
      "An invalid check-response status must be rejected.",
      sourceLocation: sourceLocation
    )
  } catch let error as DecodingError {
    guard case .dataCorrupted(let context) = error else {
      Issue.record(
        "Expected DecodingError.dataCorrupted, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    let expectedError = DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: [],
        debugDescription: "Invalid check-response status."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(
      context.debugDescription == "Invalid check-response status.",
      sourceLocation: sourceLocation
    )
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
    if rejectedCandidate.isEmpty == false {
      #expect(
        renderings.allSatisfy { $0.contains(rejectedCandidate) == false },
        sourceLocation: sourceLocation
      )
    }
  } catch {
    Issue.record(
      "Check-response status decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectCheckResponseStatusTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatusV1.self, from: data)
    Issue.record(
      "A non-string check-response status must be rejected.",
      sourceLocation: sourceLocation
    )
  } catch let error as DecodingError {
    guard case .typeMismatch(let type, let context) = error else {
      Issue.record(
        "Expected DecodingError.typeMismatch, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    #expect(
      ObjectIdentifier(type) == ObjectIdentifier(String.self),
      sourceLocation: sourceLocation
    )
    let expectedError = DecodingError.typeMismatch(
      String.self,
      DecodingError.Context(
        codingPath: [],
        debugDescription: expectedDebugDescription
      )
    )
    #expect(
      [String(describing: error), String(reflecting: error)]
        == [String(describing: expectedError), String(reflecting: expectedError)],
      sourceLocation: sourceLocation
    )
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.debugDescription == expectedDebugDescription, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
  } catch {
    Issue.record(
      "Check-response status decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectCheckResponseStatusValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatusV1.self, from: data)
    Issue.record(
      "A null check-response status must be rejected.",
      sourceLocation: sourceLocation
    )
  } catch let error as DecodingError {
    guard case .valueNotFound(let type, let context) = error else {
      Issue.record(
        "Expected DecodingError.valueNotFound, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    #expect(
      ObjectIdentifier(type) == ObjectIdentifier(String.self),
      sourceLocation: sourceLocation
    )
    let expectedDebugDescription =
      "Cannot get value of type String -- found null value instead"
    let expectedError = DecodingError.valueNotFound(
      String.self,
      DecodingError.Context(
        codingPath: [],
        debugDescription: expectedDebugDescription
      )
    )
    #expect(
      [String(describing: error), String(reflecting: error)]
        == [String(describing: expectedError), String(reflecting: expectedError)],
      sourceLocation: sourceLocation
    )
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.debugDescription == expectedDebugDescription, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
  } catch {
    Issue.record(
      "Check-response status decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
