import Foundation
import HezoLinkCore
import Testing

struct ConfidenceCategoryV1Tests {
  @Test func documentedAndFutureValuesPreserveTheOpenV1Contract() throws {
    let future = try ConfidenceCategoryV1(validating: "synthetic_confidence_v2")
    let lower = try ConfidenceCategoryV1(validating: "a")
    let upper = try ConfidenceCategoryV1(validating: "c" + String(repeating: "1", count: 127))

    requireConfidenceCategoryConformances(ConfidenceCategoryV1.low)
    #expect(ConfidenceCategoryV1.low.rawValue == "low")
    #expect(ConfidenceCategoryV1.medium.rawValue == "medium")
    #expect(ConfidenceCategoryV1.high.rawValue == "high")
    #expect(future.rawValue == "synthetic_confidence_v2")
    #expect(lower.rawValue.utf8.count == 1)
    #expect(upper.rawValue.utf8.count == 128)
    #expect(
      ConfidenceCategoryV1(rawValue: "another_future_confidence")?.rawValue
        == "another_future_confidence"
    )
  }

  @Test(
    "Canonical and forward-compatible values round-trip as exact JSON strings",
    arguments: [
      "low", "medium", "high", "synthetic_confidence_v2", "a",
      "c" + String(repeating: "1", count: 127),
    ]
  )
  func validValuesRoundTripExactly(rawValue: String) throws {
    let value = try ConfidenceCategoryV1(validating: rawValue)
    let encoded = try HezoJSON.makeEncoder().encode(value)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      ConfidenceCategoryV1.self,
      from: encoded
    )
    let expectedData = try JSONEncoder().encode(rawValue)

    #expect(encoded == expectedData)
    #expect(decoded == value)
    #expect(decoded.rawValue == rawValue)
  }

  @Test(
    "Invalid confidence strings fail with bounded construction errors",
    arguments: [
      ("", ContractValueError.empty),
      ("Uppercase", ContractValueError.invalidFormat),
      ("9leading", ContractValueError.invalidFormat),
      ("double__underscore", ContractValueError.invalidFormat),
      ("trailing_", ContractValueError.invalidFormat),
      ("contains-hyphen", ContractValueError.invalidFormat),
      ("nonascii_å", ContractValueError.invalidFormat),
      ("c" + String(repeating: "1", count: 128), ContractValueError.tooLong),
    ]
  )
  func invalidStringsFailConstructionExactly(testCase: (String, ContractValueError)) {
    let (candidate, expectedError) = testCase

    #expect(ConfidenceCategoryV1(rawValue: candidate) == nil)
    #expect(throws: expectedError) {
      try ConfidenceCategoryV1(validating: candidate)
    }
    if candidate.isEmpty == false {
      #expect(expectedError.description.contains(candidate) == false)
    }
  }

  @Test(
    "Invalid confidence strings decode with the exact content-free error",
    arguments: [
      "", "Uppercase", "9leading", "double__underscore", "trailing_", "contains-hyphen",
      "nonascii_å",
    ]
  )
  func invalidStringsFailDecodingExactly(candidate: String) throws {
    expectConfidenceCategoryDataCorrupted(
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
    expectConfidenceCategoryTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectConfidenceCategoryValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedConfidenceKeepsItsCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_CONFIDENCE_SENTINEL"
    let data = Data("{\"confidence\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(ConfidenceEnvelope.self, from: data)
      Issue.record("An invalid nested confidence category must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      #expect(context.debugDescription == "Invalid stable contract value.")
      #expect(context.codingPath.map(\.stringValue) == ["confidence"])
      #expect(context.underlyingError == nil)
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    } catch {
      Issue.record("Confidence-category decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeTypeAndWireBytes() throws {
    let canonical: ConfidenceCategoryV1 = .medium
    let compatibility: ConfidenceCategory = canonical
    let canonicalAgain: ConfidenceCategoryV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCompatibility = try JSONDecoder().decode(
      ConfidenceCategory.self,
      from: Data("\"synthetic_confidence_v2\"".utf8)
    )

    requireSameConfidenceCategoryType(ConfidenceCategory.self)
    #expect(canonicalAgain == canonical)
    #expect(canonicalData == Data("\"medium\"".utf8))
    #expect(compatibilityData == canonicalData)
    #expect(decodedCompatibility.rawValue == "synthetic_confidence_v2")
  }

  @Test func verdictUsesTheCanonicalConfidenceTypeWithoutGoldenWireDrift() throws {
    let verdict = try Verdict(
      label: .caution,
      recommendedAction: .warn,
      confidence: ConfidenceCategoryV1.high,
      evaluatedScope: .exactURL,
      reasons: VerdictReasons([])
    )
    let canonicalConfidence: ConfidenceCategoryV1 = verdict.confidence
    let encoded = try HezoJSON.makeEncoder().encode(verdict)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"confidence":"high","evaluated_scope":"exact_url","label":"caution","reasons":[],"recommended_action":"warn"}"#

    #expect(canonicalConfidence == .high)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let rawValues = ["low", "medium", "high", "synthetic_confidence_v2"]
    let results = try await withThrowingTaskGroup(of: String.self) { group in
      for rawValue in rawValues {
        for _ in 0..<32 {
          group.addTask {
            let value = try ConfidenceCategoryV1(validating: rawValue)
            let encoded = try HezoJSON.makeEncoder().encode(value)
            return try HezoJSON.makeResponseDecoder().decode(
              ConfidenceCategoryV1.self,
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

private struct ConfidenceEnvelope: Decodable {
  let confidence: ConfidenceCategoryV1
}

private func requireConfidenceCategoryConformances<Value>(_ value: Value)
where Value: RawRepresentable & Codable & Equatable & Hashable & Sendable, Value.RawValue == String
{
  _ = value
}

private func requireSameConfidenceCategoryType(_ type: ConfidenceCategoryV1.Type) {
  _ = type
}

private func expectConfidenceCategoryDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(ConfidenceCategoryV1.self, from: data)
    Issue.record("An invalid confidence category must be rejected.", sourceLocation: sourceLocation)
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
      "Confidence-category decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectConfidenceCategoryTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(ConfidenceCategoryV1.self, from: data)
    Issue.record(
      "A non-string confidence category must be rejected.", sourceLocation: sourceLocation)
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
      "Confidence-category decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectConfidenceCategoryValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(ConfidenceCategoryV1.self, from: data)
    Issue.record("A null confidence category must be rejected.", sourceLocation: sourceLocation)
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
      "Confidence-category decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
