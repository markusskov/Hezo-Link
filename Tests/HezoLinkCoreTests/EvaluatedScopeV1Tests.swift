import Foundation
import HezoLinkCore
import Testing

struct EvaluatedScopeV1Tests {
  @Test func documentedAndFutureValuesPreserveTheOpenV1Contract() throws {
    let future = try EvaluatedScopeV1(validating: "future_narrow_scope")
    let lower = try EvaluatedScopeV1(validating: "a")
    let upper = try EvaluatedScopeV1(validating: "s" + String(repeating: "1", count: 127))

    requireEvaluatedScopeConformances(EvaluatedScopeV1.exactURL)
    #expect(EvaluatedScopeV1.exactURL.rawValue == "exact_url")
    #expect(future.rawValue == "future_narrow_scope")
    #expect(lower.rawValue.utf8.count == 1)
    #expect(upper.rawValue.utf8.count == 128)
    #expect(EvaluatedScopeV1(rawValue: "another_future_scope")?.rawValue == "another_future_scope")
  }

  @Test(
    "Canonical and forward-compatible values round-trip as exact JSON strings",
    arguments: ["exact_url", "synthetic_scope_v2", "a", "s" + String(repeating: "1", count: 127)]
  )
  func validValuesRoundTripExactly(rawValue: String) throws {
    let value = try EvaluatedScopeV1(validating: rawValue)
    let encoded = try HezoJSON.makeEncoder().encode(value)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      EvaluatedScopeV1.self,
      from: encoded
    )
    let expectedData = try JSONEncoder().encode(rawValue)

    #expect(encoded == expectedData)
    #expect(decoded == value)
    #expect(decoded.rawValue == rawValue)
  }

  @Test(
    "Invalid stable-scope strings fail with bounded construction errors",
    arguments: [
      ("", ContractValueError.empty),
      ("Uppercase", ContractValueError.invalidFormat),
      ("9leading", ContractValueError.invalidFormat),
      ("double__underscore", ContractValueError.invalidFormat),
      ("trailing_", ContractValueError.invalidFormat),
      ("contains-hyphen", ContractValueError.invalidFormat),
      ("nonascii_å", ContractValueError.invalidFormat),
      ("s" + String(repeating: "1", count: 128), ContractValueError.tooLong),
    ]
  )
  func invalidStringsFailConstructionExactly(testCase: (String, ContractValueError)) {
    let (candidate, expectedError) = testCase

    #expect(EvaluatedScopeV1(rawValue: candidate) == nil)
    #expect(throws: expectedError) {
      try EvaluatedScopeV1(validating: candidate)
    }
    if candidate.isEmpty == false {
      #expect(expectedError.description.contains(candidate) == false)
    }
  }

  @Test(
    "Invalid scope strings decode with the exact content-free error",
    arguments: [
      "", "Uppercase", "9leading", "double__underscore", "trailing_", "contains-hyphen",
      "nonascii_å",
    ]
  )
  func invalidStringsFailDecodingExactly(candidate: String) throws {
    expectEvaluatedScopeDataCorrupted(
      from: try JSONEncoder().encode(candidate),
      rejectedCandidate: candidate
    )
  }

  @Test(
    "Every non-string JSON shape is rejected with typeMismatch",
    arguments: [
      ("1", "Expected to decode String but found number instead."),
      ("42.5", "Expected to decode String but found number instead."),
      ("true", "Expected to decode String but found bool instead."),
      ("false", "Expected to decode String but found bool instead."),
      ("{}", "Expected to decode String but found a dictionary instead."),
      ("[]", "Expected to decode String but found an array instead."),
    ]
  )
  func wrongJSONTypesAreRejectedExactly(testCase: (String, String)) {
    expectEvaluatedScopeTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectEvaluatedScopeValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedScopeKeepsItsCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_EVALUATED_SCOPE_SENTINEL"
    let data = Data("{\"evaluated_scope\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(EvaluatedScopeEnvelope.self, from: data)
      Issue.record("An invalid nested evaluated scope must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      #expect(context.debugDescription == "Invalid stable contract value.")
      #expect(context.codingPath.map(\.stringValue) == ["evaluated_scope"])
      #expect(context.underlyingError == nil)
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    } catch {
      Issue.record("Evaluated-scope decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeTypeAndWireBytes() throws {
    let canonical: EvaluatedScopeV1 = .exactURL
    let compatibility: EvaluatedScope = canonical
    let canonicalAgain: EvaluatedScopeV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCompatibility = try JSONDecoder().decode(
      EvaluatedScope.self,
      from: Data("\"future_narrow_scope\"".utf8)
    )

    requireSameEvaluatedScopeType(EvaluatedScope.self)
    #expect(canonicalAgain == canonical)
    #expect(canonicalData == Data("\"exact_url\"".utf8))
    #expect(compatibilityData == canonicalData)
    #expect(decodedCompatibility.rawValue == "future_narrow_scope")
  }

  @Test func verdictUsesTheCanonicalScopeTypeWithoutGoldenWireDrift() throws {
    let verdict = try Verdict(
      label: .caution,
      recommendedAction: .warn,
      confidence: .high,
      evaluatedScope: EvaluatedScopeV1.exactURL,
      reasons: VerdictReasons([])
    )
    let canonicalScope: EvaluatedScopeV1 = verdict.evaluatedScope
    let encoded = try HezoJSON.makeEncoder().encode(verdict)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"confidence":"high","evaluated_scope":"exact_url","label":"caution","reasons":[],"recommended_action":"warn"}"#

    #expect(canonicalScope == .exactURL)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let rawValues = ["exact_url", "synthetic_scope_v2", "a", "future_narrow_scope"]
    let results = try await withThrowingTaskGroup(of: String.self) { group in
      for rawValue in rawValues {
        for _ in 0..<32 {
          group.addTask {
            let value = try EvaluatedScopeV1(validating: rawValue)
            let encoded = try HezoJSON.makeEncoder().encode(value)
            return try HezoJSON.makeResponseDecoder().decode(
              EvaluatedScopeV1.self,
              from: encoded
            ).rawValue
          }
        }
      }

      var values: [String] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 128)
    #expect(Set(results) == Set(rawValues))
    for rawValue in rawValues {
      #expect(results.filter { $0 == rawValue }.count == 32)
    }
  }
}

private struct EvaluatedScopeEnvelope: Decodable {
  private enum CodingKeys: String, CodingKey {
    case evaluatedScope = "evaluated_scope"
  }

  let evaluatedScope: EvaluatedScopeV1
}

private func requireEvaluatedScopeConformances<Value>(_ value: Value)
where Value: RawRepresentable & Codable & Equatable & Hashable & Sendable, Value.RawValue == String
{
  _ = value
}

private func requireSameEvaluatedScopeType(_ type: EvaluatedScopeV1.Type) {
  _ = type
}

private func expectEvaluatedScopeDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(EvaluatedScopeV1.self, from: data)
    Issue.record("An invalid evaluated scope must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .dataCorrupted(let context) = error else {
      Issue.record("Expected DecodingError.dataCorrupted.", sourceLocation: sourceLocation)
      return
    }
    let expectedError = DecodingError.dataCorrupted(
      .init(codingPath: [], debugDescription: "Invalid stable contract value.")
    )
    #expect(
      [String(describing: error), String(reflecting: error)]
        == [String(describing: expectedError), String(reflecting: expectedError)],
      sourceLocation: sourceLocation
    )
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(
      context.debugDescription == "Invalid stable contract value.", sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
    if rejectedCandidate.isEmpty == false {
      #expect(
        String(describing: error).contains(rejectedCandidate) == false,
        sourceLocation: sourceLocation)
      #expect(
        String(reflecting: error).contains(rejectedCandidate) == false,
        sourceLocation: sourceLocation)
    }
  } catch {
    Issue.record(
      "Evaluated-scope decoding used an unexpected error category.", sourceLocation: sourceLocation)
  }
}

private func expectEvaluatedScopeTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(EvaluatedScopeV1.self, from: data)
    Issue.record("A non-string evaluated scope must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .typeMismatch(let type, let context) = error else {
      Issue.record("Expected DecodingError.typeMismatch.", sourceLocation: sourceLocation)
      return
    }
    #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self), sourceLocation: sourceLocation)
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.debugDescription == expectedDebugDescription, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
  } catch {
    Issue.record(
      "Evaluated-scope decoding used an unexpected error category.", sourceLocation: sourceLocation)
  }
}

private func expectEvaluatedScopeValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(EvaluatedScopeV1.self, from: data)
    Issue.record("A null evaluated scope must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .valueNotFound(let type, let context) = error else {
      Issue.record("Expected DecodingError.valueNotFound.", sourceLocation: sourceLocation)
      return
    }
    #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self), sourceLocation: sourceLocation)
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(
      context.debugDescription == "Cannot get value of type String -- found null value instead",
      sourceLocation: sourceLocation
    )
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
  } catch {
    Issue.record(
      "Evaluated-scope decoding used an unexpected error category.", sourceLocation: sourceLocation)
  }
}
