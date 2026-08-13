import Foundation
import HezoLinkCore
import Testing

struct VerdictLabelV1Tests {
  @Test func casesRawValuesOrderAndPublicConformancesAreExact() {
    let labels = VerdictLabelV1.allCases
    let wireValues = labels.map(\.rawValue)

    #expect(labels == [.unknown, .noKnownDanger, .caution, .dangerous])
    #expect(wireValues == ["unknown", "no_known_danger", "caution", "dangerous"])
    #expect(Set(wireValues) == ["unknown", "no_known_danger", "caution", "dangerous"])
    #expect(wireValues.count == Set(wireValues).count)
    requireVerdictLabelConformances(VerdictLabelV1.unknown)
  }

  @Test(
    "Canonical verdict labels round-trip as exact JSON strings",
    arguments: [
      (VerdictLabelV1.unknown, "unknown"),
      (VerdictLabelV1.noKnownDanger, "no_known_danger"),
      (VerdictLabelV1.caution, "caution"),
      (VerdictLabelV1.dangerous, "dangerous"),
    ]
  )
  func canonicalLabelsRoundTripExactly(
    testCase: (VerdictLabelV1, String)
  ) throws {
    let (label, expectedWireValue) = testCase
    let encoded = try HezoJSON.makeEncoder().encode(label)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      VerdictLabelV1.self,
      from: encoded
    )

    #expect(String(data: encoded, encoding: .utf8) == "\"\(expectedWireValue)\"")
    #expect(decoded == label)
    #expect(decoded.rawValue == expectedWireValue)
  }

  @Test(
    "Every frozen alias and unrecognized label is rejected",
    arguments: [
      "safe",
      "likely_safe",
      "allow",
      "warn",
      "block",
      "malicious",
      "suspicious",
      "",
      "DANGEROUS",
      "future_label",
    ]
  )
  func aliasesAndOtherStringsAreRejected(candidate: String) throws {
    #expect(VerdictLabelV1(rawValue: candidate) == nil)

    expectVerdictLabelDataCorrupted(
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
    expectVerdictLabelTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectVerdictLabelValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedLabelKeepsItsCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_VERDICT_LABEL_SENTINEL"
    let data = Data("{\"label\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(VerdictLabelEnvelope.self, from: data)
      Issue.record("An invalid nested verdict label must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid public verdict label.")
      #expect(context.codingPath.map(\.stringValue) == ["label"])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    } catch {
      Issue.record("Verdict-label decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeType() throws {
    let canonical: VerdictLabelV1 = .caution
    let compatibility: VerdictLabel = canonical
    let canonicalAgain: VerdictLabelV1 = compatibility
    let decodedCompatibility = try JSONDecoder().decode(
      VerdictLabel.self,
      from: Data("\"dangerous\"".utf8)
    )

    requireSameVerdictLabelType(VerdictLabel.self)
    #expect(canonicalAgain == canonical)
    #expect(decodedCompatibility == VerdictLabelV1.dangerous)
    #expect(VerdictLabel.allCases == VerdictLabelV1.allCases)
  }

  @Test func verdictUsesTheCanonicalLabelTypeWithoutWireDrift() throws {
    let verdict = try Verdict(
      label: VerdictLabelV1.unknown,
      recommendedAction: .warn,
      confidence: .low,
      evaluatedScope: .exactURL,
      reasons: VerdictReasons([])
    )
    let canonicalLabel: VerdictLabelV1 = verdict.label
    let encoded = try HezoJSON.makeEncoder().encode(verdict)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"confidence":"low","evaluated_scope":"exact_url","label":"unknown","reasons":[],"recommended_action":"warn"}"#

    #expect(canonicalLabel == .unknown)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let expectedEncodings: [VerdictLabelV1: Data] = [
      .unknown: Data("\"unknown\"".utf8),
      .noKnownDanger: Data("\"no_known_danger\"".utf8),
      .caution: Data("\"caution\"".utf8),
      .dangerous: Data("\"dangerous\"".utf8),
    ]
    let results = try await withThrowingTaskGroup(
      of: (VerdictLabelV1, Data).self
    ) { group in
      for label in VerdictLabelV1.allCases {
        for _ in 0..<32 {
          group.addTask {
            let encoded = try HezoJSON.makeEncoder().encode(label)
            let decoded = try HezoJSON.makeResponseDecoder().decode(
              VerdictLabelV1.self,
              from: encoded
            )
            return (decoded, encoded)
          }
        }
      }

      var values: [(VerdictLabelV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 128)
    #expect(results.allSatisfy { $0.1 == expectedEncodings[$0.0] })
    #expect(Set(results.map(\.0)) == Set(VerdictLabelV1.allCases))
  }
}

private struct VerdictLabelEnvelope: Decodable {
  let label: VerdictLabelV1
}

private func requireVerdictLabelConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String,
  Value.AllCases == [Value]
{
  _ = value
}

private func requireSameVerdictLabelType(_ type: VerdictLabelV1.Type) {
  _ = type
}

private func expectVerdictLabelDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(VerdictLabelV1.self, from: data)
    Issue.record(
      "An invalid verdict label must be rejected.",
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
        debugDescription: "Invalid public verdict label."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(
      context.debugDescription == "Invalid public verdict label.",
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
      "Verdict-label decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectVerdictLabelTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(VerdictLabelV1.self, from: data)
    Issue.record(
      "A non-string verdict label must be rejected.",
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
      "Verdict-label decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectVerdictLabelValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(VerdictLabelV1.self, from: data)
    Issue.record(
      "A null verdict label must be rejected.",
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
      "Verdict-label decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
