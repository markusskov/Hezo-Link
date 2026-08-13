import Foundation
import HezoLinkCore
import Testing

struct RecommendedActionV1Tests {
  @Test func casesRawValuesOrderAndPublicConformancesAreExact() {
    let actions = RecommendedActionV1.allCases
    let wireValues = actions.map(\.rawValue)

    #expect(actions == [.allow, .warn, .avoid, .retry])
    #expect(wireValues == ["allow", "warn", "avoid", "retry"])
    #expect(Set(wireValues) == ["allow", "warn", "avoid", "retry"])
    #expect(wireValues.count == Set(wireValues).count)
    requireRecommendedActionConformances(RecommendedActionV1.allow)
  }

  @Test(
    "Canonical recommended actions round-trip as exact JSON strings",
    arguments: [
      (RecommendedActionV1.allow, "allow"),
      (RecommendedActionV1.warn, "warn"),
      (RecommendedActionV1.avoid, "avoid"),
      (RecommendedActionV1.retry, "retry"),
    ]
  )
  func canonicalActionsRoundTripExactly(
    testCase: (RecommendedActionV1, String)
  ) throws {
    let (action, expectedWireValue) = testCase
    let encoded = try HezoJSON.makeEncoder().encode(action)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      RecommendedActionV1.self,
      from: encoded
    )

    #expect(String(data: encoded, encoding: .utf8) == "\"\(expectedWireValue)\"")
    #expect(decoded == action)
    #expect(decoded.rawValue == expectedWireValue)
  }

  @Test(
    "Every frozen alias and unrelated vocabulary is rejected",
    arguments: [
      "proceed",
      "block",
      "unknown",
      "no_known_danger",
      "caution",
      "dangerous",
      "safe",
      "likely_safe",
      "malicious",
      "suspicious",
      "",
      "ALLOW",
      "future_action",
    ]
  )
  func aliasesAndOtherStringsAreRejected(candidate: String) throws {
    #expect(RecommendedActionV1(rawValue: candidate) == nil)

    expectRecommendedActionDataCorrupted(
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
    expectRecommendedActionTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectRecommendedActionValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedActionKeepsItsCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_RECOMMENDED_ACTION_SENTINEL"
    let data = Data("{\"recommended_action\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(RecommendedActionEnvelope.self, from: data)
      Issue.record("An invalid nested recommended action must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid recommended action.")
      #expect(context.codingPath.map(\.stringValue) == ["recommended_action"])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    } catch {
      Issue.record("Recommended-action decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeTypeAndWireBytes() throws {
    let canonical: RecommendedActionV1 = .warn
    let compatibility: RecommendedAction = canonical
    let canonicalAgain: RecommendedActionV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCompatibility = try JSONDecoder().decode(
      RecommendedAction.self,
      from: Data("\"avoid\"".utf8)
    )

    requireSameRecommendedActionType(RecommendedAction.self)
    #expect(canonicalAgain == canonical)
    #expect(canonicalData == Data("\"warn\"".utf8))
    #expect(compatibilityData == canonicalData)
    #expect(decodedCompatibility == RecommendedActionV1.avoid)
    #expect(RecommendedAction.allCases == RecommendedActionV1.allCases)
  }

  @Test func verdictUsesTheCanonicalActionTypeWithoutGoldenWireDrift() throws {
    let verdict = try Verdict(
      label: .caution,
      recommendedAction: RecommendedActionV1.warn,
      confidence: .high,
      evaluatedScope: .exactURL,
      reasons: VerdictReasons([])
    )
    let canonicalAction: RecommendedActionV1 = verdict.recommendedAction
    let encoded = try HezoJSON.makeEncoder().encode(verdict)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"confidence":"high","evaluated_scope":"exact_url","label":"caution","reasons":[],"recommended_action":"warn"}"#

    #expect(canonicalAction == .warn)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let expectedEncodings: [RecommendedActionV1: Data] = [
      .allow: Data("\"allow\"".utf8),
      .warn: Data("\"warn\"".utf8),
      .avoid: Data("\"avoid\"".utf8),
      .retry: Data("\"retry\"".utf8),
    ]
    let results = try await withThrowingTaskGroup(
      of: (RecommendedActionV1, Data).self
    ) { group in
      for action in RecommendedActionV1.allCases {
        for _ in 0..<32 {
          group.addTask {
            let encoded = try HezoJSON.makeEncoder().encode(action)
            let decoded = try HezoJSON.makeResponseDecoder().decode(
              RecommendedActionV1.self,
              from: encoded
            )
            return (decoded, encoded)
          }
        }
      }

      var values: [(RecommendedActionV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 128)
    #expect(results.allSatisfy { $0.1 == expectedEncodings[$0.0] })
    #expect(Set(results.map(\.0)) == Set(RecommendedActionV1.allCases))
  }
}

private struct RecommendedActionEnvelope: Decodable {
  private enum CodingKeys: String, CodingKey {
    case recommendedAction = "recommended_action"
  }

  let recommendedAction: RecommendedActionV1
}

private func requireRecommendedActionConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String,
  Value.AllCases == [Value]
{
  _ = value
}

private func requireSameRecommendedActionType(_ type: RecommendedActionV1.Type) {
  _ = type
}

private func expectRecommendedActionDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(RecommendedActionV1.self, from: data)
    Issue.record(
      "An invalid recommended action must be rejected.",
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
        debugDescription: "Invalid recommended action."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(
      context.debugDescription == "Invalid recommended action.",
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
      "Recommended-action decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectRecommendedActionTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(RecommendedActionV1.self, from: data)
    Issue.record(
      "A non-string recommended action must be rejected.",
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
      "Recommended-action decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectRecommendedActionValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(RecommendedActionV1.self, from: data)
    Issue.record(
      "A null recommended action must be rejected.",
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
      "Recommended-action decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
