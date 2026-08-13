import Foundation
import HezoLinkCore
import Testing

struct VerdictReasonsV1Tests {
  @Test func publicSurfaceKeepsTheExactBoundAndConformances() throws {
    let reasons = try VerdictReasonsV1([])
    let values: [VerdictReasonV1] = reasons.values

    requireVerdictReasonsConformances(reasons)
    requireVerdictReasonsErrorConformances(VerdictReasonsError.tooManyReasons)
    #expect(VerdictReasonsV1.maximumCount == 5)
    #expect(values.isEmpty)
    #expect(reasons.count == 0)
  }

  @Test(
    "Every permitted count constructs and round-trips as the exact JSON array",
    arguments: Array(0...5)
  )
  func everyPermittedCountConstructsAndRoundTrips(count: Int) throws {
    let reason = try makeVerdictReasonsReason()
    let values = Array(repeating: reason, count: count)
    let reasons = try VerdictReasonsV1(values)
    let data = try HezoJSON.makeEncoder().encode(reasons)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasonsV1.self,
      from: data
    )
    let expectedWire =
      "[" + Array(repeating: canonicalVerdictReasonWire, count: count).joined(separator: ",") + "]"

    #expect(reasons.count == count)
    #expect(reasons.values == values)
    #expect(String(data: data, encoding: .utf8) == expectedWire)
    #expect(decoded == reasons)
  }

  @Test func orderAndDuplicatesArePreservedExactly() throws {
    let first = try makeVerdictReasonsReason()
    let second = try makeVerdictReasonsReason(
      code: "synthetic_second_reason",
      family: "synthetic_evidence",
      severity: "medium",
      summaryKey: "verdict.reason.synthetic_second_reason",
      observedAt: Date(timeIntervalSince1970: 950_608_801),
      freshness: "recent"
    )
    let values = [first, second, first, second, first]
    let reasons = try VerdictReasonsV1(values)
    let data = try HezoJSON.makeEncoder().encode(reasons)
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasonsV1.self,
      from: data
    )

    #expect(decoded.count == 5)
    #expect(decoded.values == values)
    #expect(decoded.values[0] == decoded.values[2])
    #expect(decoded.values[1] == decoded.values[3])
    #expect(
      decoded.values.map(\.code.rawValue) == [
        "brand_impersonation_unrelated_domain",
        "synthetic_second_reason",
        "brand_impersonation_unrelated_domain",
        "synthetic_second_reason",
        "brand_impersonation_unrelated_domain",
      ]
    )
  }

  @Test func sixthValueConstructionFailsWithTheExactPrivateError() throws {
    let privateCandidate = "private_sixth_reason_sentinel"
    let ordinary = try makeVerdictReasonsReason()
    let privateReason = try makeVerdictReasonsReason(code: privateCandidate)
    let values = Array(repeating: ordinary, count: 5) + [privateReason]

    do {
      _ = try VerdictReasonsV1(values)
      Issue.record("A sixth public verdict reason must be rejected.")
    } catch let error as VerdictReasonsError {
      #expect(error == .tooManyReasons)
      #expect(error.description == verdictReasonsLimitDescription)
      #expect(String(describing: error) == verdictReasonsLimitDescription)
      #expect(String(describing: error).contains(privateCandidate) == false)
      #expect(String(reflecting: error).contains(privateCandidate) == false)
    } catch {
      Issue.record("Verdict-reasons construction used an unexpected error category.")
    }
  }

  @Test func sixthItemFailsIncrementallyBeforeItsReasonIsDecoded() throws {
    let privateCandidate = "PRIVATE_SIXTH_OBSERVED_AT_SENTINEL"
    let data = try oversizedVerdictReasonsData(sixthObservedAt: privateCandidate)
    let audit = VerdictReasonsDateDecodeAudit()
    let decoder = auditedVerdictReasonsDecoder(audit: audit)

    do {
      _ = try decoder.decode(VerdictReasonsV1.self, from: data)
      Issue.record("A sixth encoded public verdict reason must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let candidates = audit.candidates
      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == verdictReasonsLimitDescription)
      #expect(context.codingPath.map(\.stringValue) == ["Index 5"])
      #expect(context.codingPath.map(\.intValue) == [5])
      #expect(context.underlyingError == nil)
      #expect(candidates.count == 5)
      #expect(candidates == Array(repeating: canonicalObservedAtWire, count: 5))
      #expect(candidates.contains(privateCandidate) == false)
      #expect(renderings.allSatisfy { $0.contains(privateCandidate) == false })
    } catch {
      Issue.record("Verdict-reasons decoding used an unexpected error category.")
    }
  }

  @Test func nestedSixthItemFailureKeepsTheExactCodingPath() throws {
    let privateCandidate = "PRIVATE_NESTED_SIXTH_REASON_SENTINEL"
    let data = try oversizedVerdictReasonsData(
      sixthObservedAt: privateCandidate,
      nested: true
    )

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(
        VerdictReasonsEnvelope.self,
        from: data
      )
      Issue.record("A nested sixth public verdict reason must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == verdictReasonsLimitDescription)
      #expect(context.codingPath.map(\.stringValue) == ["reasons", "Index 5"])
      #expect(context.codingPath.map(\.intValue) == [nil, 5])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(privateCandidate) == false })
    } catch {
      Issue.record("Nested verdict-reasons decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasHasTheSameCompileTimeTypeAndWireBytes() throws {
    let canonical: VerdictReasonsV1 = try VerdictReasonsV1([makeVerdictReasonsReason()])
    let compatibility: VerdictReasons = canonical
    let canonicalAgain: VerdictReasonsV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCompatibility = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasons.self,
      from: canonicalData
    )

    requireSameVerdictReasonsType(VerdictReasons.self)
    #expect(canonicalAgain == canonical)
    #expect(compatibilityData == canonicalData)
    #expect(decodedCompatibility == canonical)
    #expect(VerdictReasons.maximumCount == VerdictReasonsV1.maximumCount)
  }

  @Test func verdictUsesTheCanonicalCollectionWithoutGoldenWireDrift() throws {
    let reasons = try VerdictReasonsV1([makeVerdictReasonsReason()])
    let verdict = try Verdict(
      label: .caution,
      recommendedAction: .warn,
      confidence: .high,
      evaluatedScope: .exactURL,
      reasons: reasons
    )
    let canonicalReasons: VerdictReasonsV1 = verdict.reasons
    let data = try HezoJSON.makeEncoder().encode(verdict)
    let decoded = try HezoJSON.makeResponseDecoder().decode(Verdict.self, from: data)
    let expected =
      #"{"confidence":"high","evaluated_scope":"exact_url","label":"caution","reasons":[{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","freshness":"current","observed_at":"2000-02-15T10:00:00Z","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain"}],"recommended_action":"warn"}"#

    #expect(canonicalReasons == reasons)
    #expect(String(data: data, encoding: .utf8) == expected)
    #expect(decoded == verdict)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let reasons = try VerdictReasonsV1([
      makeVerdictReasonsReason(),
      makeVerdictReasonsReason(code: "synthetic_second_reason"),
      makeVerdictReasonsReason(),
    ])
    let expectedData = try HezoJSON.makeEncoder().encode(reasons)
    let results = try await withThrowingTaskGroup(of: (VerdictReasonsV1, Data).self) {
      group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(reasons)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            VerdictReasonsV1.self,
            from: encoded
          )
          return (decoded, encoded)
        }
      }

      var values: [(VerdictReasonsV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == reasons && $0.1 == expectedData })
  }
}

private struct VerdictReasonsEnvelope: Decodable {
  let reasons: VerdictReasonsV1
}

private final class VerdictReasonsDateDecodeAudit: @unchecked Sendable {
  private let lock = NSLock()
  private var storedCandidates: [String] = []

  var candidates: [String] {
    lock.lock()
    defer { lock.unlock() }
    return storedCandidates
  }

  func record(_ candidate: String) {
    lock.lock()
    storedCandidates.append(candidate)
    lock.unlock()
  }
}

private func requireVerdictReasonsConformances<Value>(_ value: Value)
where Value: Codable & Equatable & Sendable {
  _ = value
}

private func requireVerdictReasonsErrorConformances<Value>(_ value: Value)
where Value: Error & Equatable & Sendable & CustomStringConvertible {
  _ = value
}

private func requireSameVerdictReasonsType(_ type: VerdictReasonsV1.Type) {
  _ = type
}

private func makeVerdictReasonsReason(
  code: String = "brand_impersonation_unrelated_domain",
  family: String = "identity_impersonation",
  severity: String = "high",
  summaryKey: String = "verdict.reason.brand_impersonation_unrelated_domain",
  observedAt: Date = Date(timeIntervalSince1970: 950_608_800),
  freshness: String = "current"
) throws -> VerdictReasonV1 {
  VerdictReasonV1(
    code: try ReasonCode(validating: code),
    family: try ReasonFamily(validating: family),
    severity: try ReasonSeverity(validating: severity),
    summaryKey: try LocalizationKey(validating: summaryKey),
    observedAt: observedAt,
    freshness: try FreshnessCategory(validating: freshness)
  )
}

private func oversizedVerdictReasonsData(
  sixthObservedAt: String,
  nested: Bool = false
) throws -> Data {
  let ordinaryReason: [String: Any] = [
    "code": "brand_impersonation_unrelated_domain",
    "family": "identity_impersonation",
    "severity": "high",
    "summary_key": "verdict.reason.brand_impersonation_unrelated_domain",
    "observed_at": canonicalObservedAtWire,
    "freshness": "current",
  ]
  var sixthReason = ordinaryReason
  sixthReason["observed_at"] = sixthObservedAt
  let reasons = Array(repeating: ordinaryReason, count: 5) + [sixthReason]
  let payload: Any = nested ? ["reasons": reasons] : reasons
  return try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
}

private func auditedVerdictReasonsDecoder(
  audit: VerdictReasonsDateDecodeAudit
) -> JSONDecoder {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    audit.record(candidate)
    return Date(timeIntervalSince1970: 950_608_800)
  }
  return decoder
}

private let verdictReasonsLimitDescription =
  "Public verdict reason count exceeds the contract limit."
private let canonicalObservedAtWire = "2000-02-15T10:00:00Z"
private let canonicalVerdictReasonWire =
  #"{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","freshness":"current","observed_at":"2000-02-15T10:00:00Z","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain"}"#
