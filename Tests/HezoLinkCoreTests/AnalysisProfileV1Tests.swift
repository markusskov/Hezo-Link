import Foundation
import HezoLinkCore
import Testing

struct AnalysisProfileV1Tests {
  @Test func casesRawValuesOrderAndPublicConformancesAreExact() {
    let profiles = AnalysisProfileV1.allCases
    let wireValues = profiles.map(\.rawValue)
    let requestProfile: String = CheckRequestV1.analysisProfile

    #expect(profiles == [.standard])
    #expect(wireValues == ["standard"])
    #expect(Set(wireValues) == ["standard"])
    #expect(wireValues.count == Set(wireValues).count)
    #expect(requestProfile == AnalysisProfileV1.standard.rawValue)
    requireAnalysisProfileConformances(AnalysisProfileV1.standard)
  }

  @Test func canonicalProfileRoundTripsAsTheExactJSONString() throws {
    let profile = AnalysisProfileV1.standard
    let encoded = try HezoJSON.makeEncoder().encode(profile)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      AnalysisProfileV1.self,
      from: encoded
    )

    #expect(encoded == Data("\"standard\"".utf8))
    #expect(decoded == profile)
    #expect(decoded.rawValue == "standard")
  }

  @Test(
    "Aliases, casing variants, and unrelated profiles are rejected",
    arguments: [
      "fast",
      "quick",
      "full",
      "default",
      "STANDARD",
      "Standard",
      "standard ",
      " standard",
      "",
    ]
  )
  func invalidStringValuesAreRejected(candidate: String) throws {
    #expect(AnalysisProfileV1(rawValue: candidate) == nil)
    expectAnalysisProfileDataCorrupted(
      from: try JSONEncoder().encode(candidate),
      rejectedCandidate: candidate
    )
  }

  @Test(
    "Every non-string JSON shape is rejected with typeMismatch",
    arguments: [
      ("1", "Expected to decode String but found number instead."),
      ("1.5", "Expected to decode String but found number instead."),
      ("true", "Expected to decode String but found bool instead."),
      ("false", "Expected to decode String but found bool instead."),
      ("{}", "Expected to decode String but found a dictionary instead."),
      ("[]", "Expected to decode String but found an array instead."),
    ]
  )
  func wrongJSONTypesAreRejectedExactly(testCase: (String, String)) {
    expectAnalysisProfileTypeMismatch(
      from: Data(testCase.0.utf8),
      expectedDebugDescription: testCase.1
    )
  }

  @Test func nullIsRejectedWithValueNotFound() {
    expectAnalysisProfileValueNotFound(from: Data("null".utf8))
  }

  @Test func invalidNestedProfileKeepsItsWireCodingPathAndOmitsTheCandidate() {
    let candidate = "PRIVATE_ANALYSIS_PROFILE_SENTINEL"
    let data = Data("{\"analysis_profile\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(AnalysisProfileEnvelope.self, from: data)
      Issue.record("An invalid nested analysis profile must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid analysis profile.")
      #expect(context.codingPath.map(\.stringValue) == ["analysis_profile"])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    } catch {
      Issue.record("Analysis-profile decoding used an unexpected error category.")
    }
  }

  @Test func checkRequestUsesBothCanonicalPrimitivesWithoutGoldenWireDrift() throws {
    let rawURL = "https://192.0.2.1/path?opaque=value#route"
    let validatedURL = try requirePublicValidatedURL(rawURL)
    let request = try CheckRequestV1(
      validatedURL: validatedURL,
      waitBudgetMilliseconds: 1_200
    )
    let encoded = try HezoJSON.makeEncoder().encode(request)
    let wireValue = try #require(String(data: encoded, encoding: .utf8))
    let expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://192.0.2.1/path?opaque=value#route","wait_budget_ms":1200}"#
    let analysisProfile: String = CheckRequestV1.analysisProfile
    let reasonSchemaVersion: Int = CheckRequestV1.reasonSchemaVersion

    #expect(analysisProfile == AnalysisProfileV1.standard.rawValue)
    #expect(reasonSchemaVersion == ReasonSchemaVersionV1.v1.rawValue)
    #expect(wireValue == expected)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let expectedEncoding = Data("\"standard\"".utf8)
    let results = try await withThrowingTaskGroup(
      of: (AnalysisProfileV1, Data).self
    ) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(AnalysisProfileV1.standard)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            AnalysisProfileV1.self,
            from: encoded
          )
          return (decoded, encoded)
        }
      }

      var values: [(AnalysisProfileV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == .standard && $0.1 == expectedEncoding })
  }
}

private struct AnalysisProfileEnvelope: Decodable {
  let analysisProfile: AnalysisProfileV1

  private enum CodingKeys: String, CodingKey {
    case analysisProfile = "analysis_profile"
  }
}

private enum AnalysisProfileV1TestError: Error {
  case expectedAcceptedURL
}

private func requireAnalysisProfileConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String,
  Value.AllCases == [Value]
{
  _ = value
}

private func requirePublicValidatedURL(_ rawURL: String) throws -> ValidatedManualURL {
  guard case .accepted(let validatedURL) = ManualURLInputValidator().validate(rawURL) else {
    throw AnalysisProfileV1TestError.expectedAcceptedURL
  }
  return validatedURL
}

private func expectAnalysisProfileDataCorrupted(
  from data: Data,
  rejectedCandidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(AnalysisProfileV1.self, from: data)
    Issue.record("An invalid analysis profile must be rejected.", sourceLocation: sourceLocation)
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
        debugDescription: "Invalid analysis profile."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(
      renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 256 },
      sourceLocation: sourceLocation
    )
    #expect(context.debugDescription == "Invalid analysis profile.", sourceLocation: sourceLocation)
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
      "Analysis-profile decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectAnalysisProfileTypeMismatch(
  from data: Data,
  expectedDebugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(AnalysisProfileV1.self, from: data)
    Issue.record("A non-string analysis profile must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .typeMismatch(let type, let context) = error else {
      Issue.record(
        "Expected DecodingError.typeMismatch, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self), sourceLocation: sourceLocation)
    let expectedError = DecodingError.typeMismatch(
      String.self,
      DecodingError.Context(codingPath: [], debugDescription: expectedDebugDescription)
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
      "Analysis-profile decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectAnalysisProfileValueNotFound(
  from data: Data,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(AnalysisProfileV1.self, from: data)
    Issue.record("A null analysis profile must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .valueNotFound(let type, let context) = error else {
      Issue.record(
        "Expected DecodingError.valueNotFound, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self), sourceLocation: sourceLocation)
    let expectedDebugDescription = "Cannot get value of type String -- found null value instead"
    let expectedError = DecodingError.valueNotFound(
      String.self,
      DecodingError.Context(codingPath: [], debugDescription: expectedDebugDescription)
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
      "Analysis-profile decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
