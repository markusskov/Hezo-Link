import Foundation
import HezoLinkCore
import Testing

struct VerdictReasonV1Tests {
  @Test func publicSurfacePreservesAllSixFieldsConformancesAndDateAPI() throws {
    let reason = try makeVerdictReasonV1()
    let observedAt: Date = reason.observedAt

    requireVerdictReasonConformances(reason)
    #expect(reason.code == .brandImpersonationUnrelatedDomain)
    #expect(reason.family.rawValue == "identity_impersonation")
    #expect(reason.severity.rawValue == "high")
    #expect(reason.summaryKey.rawValue == "verdict.reason.brand_impersonation_unrelated_domain")
    #expect(observedAt == Date(timeIntervalSince1970: 950_608_800))
    #expect(reason.freshness.rawValue == "current")
  }

  @Test func exactSixFieldGoldenWireRoundTrips() throws {
    let reason = try makeVerdictReasonV1()
    let data = try HezoJSON.makeEncoder().encode(reason)
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictReasonV1.self, from: data)
    let expected =
      #"{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","freshness":"current","observed_at":"2000-02-15T10:00:00Z","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain"}"#

    #expect(String(data: data, encoding: .utf8) == expected)
    #expect(decoded == reason)
  }

  @Test func readerToleratesAndDropsAnAdditiveUnknownMember() throws {
    let json =
      #"{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain","observed_at":"2000-02-15T10:00:00Z","freshness":"current","future_optional":{"nested":true}}"#
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasonV1.self,
      from: Data(json.utf8)
    )
    let encoded = try HezoJSON.makeEncoder().encode(decoded)
    let object = try #require(
      JSONSerialization.jsonObject(with: encoded, options: [.fragmentsAllowed])
        as? [String: Any]
    )

    #expect(decoded.code == .brandImpersonationUnrelatedDomain)
    #expect(
      Set(object.keys)
        == ["code", "family", "severity", "summary_key", "observed_at", "freshness"]
    )
    #expect(object["future_optional"] == nil)
  }

  @Test func observedAtRetainsDateConstructionAndCanonicalWireBehavior() throws {
    let fractionalDate = Date(timeIntervalSince1970: 951_091_200.5)
    let reason = try makeVerdictReasonV1(observedAt: fractionalDate)

    #expect(reason.observedAt == fractionalDate)
    do {
      _ = try HezoJSON.makeEncoder().encode(reason)
      Issue.record("A fractional observed_at must be rejected at the wire boundary.")
    } catch let error as EncodingError {
      guard case .invalidValue(_, let context) = error else {
        Issue.record("Expected EncodingError.invalidValue.")
        return
      }

      #expect(context.debugDescription == "Contract instants require UTC whole-second precision.")
      #expect(context.codingPath.map(\.stringValue) == ["observed_at"])
      #expect(context.underlyingError == nil)
    } catch {
      Issue.record("Observed-at encoding used an unexpected error category.")
    }
  }

  @Test(
    "Invalid nested observed_at values keep their coding path and omit rejected content",
    arguments: [
      "2000-02-15T10:00:00.500Z",
      "2000-02-15T11:00:00+01:00",
      "2000-02-30T10:00:00Z",
      "PRIVATE_OBSERVED_AT_SENTINEL",
    ]
  )
  func invalidNestedObservedAtIsCanonicalPathAwareAndPrivate(candidate: String) throws {
    let data = try nestedVerdictReasonData(observedAt: candidate)

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(VerdictReasonEnvelope.self, from: data)
      Issue.record("A noncanonical nested observed_at must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid canonical UTC contract instant.")
      #expect(context.codingPath.map(\.stringValue) == ["reason", "observed_at"])
      #expect(context.underlyingError == nil)
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    } catch {
      Issue.record("Observed-at decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasIsTheSameCompileTimeTypeAndWireBytes() throws {
    let canonical: VerdictReasonV1 = try makeVerdictReasonV1()
    let compatibility: VerdictReason = canonical
    let canonicalAgain: VerdictReasonV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCompatibility = try HezoJSON.makeResponseDecoder().decode(
      VerdictReason.self,
      from: canonicalData
    )

    requireSameVerdictReasonType(VerdictReason.self)
    #expect(canonicalAgain == canonical)
    #expect(compatibilityData == canonicalData)
    #expect(decodedCompatibility == canonical)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let reason = try makeVerdictReasonV1()
    let expectedData = try HezoJSON.makeEncoder().encode(reason)
    let results = try await withThrowingTaskGroup(of: (VerdictReasonV1, Data).self) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(reason)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            VerdictReasonV1.self,
            from: encoded
          )
          return (decoded, encoded)
        }
      }

      var values: [(VerdictReasonV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == reason && $0.1 == expectedData })
  }
}

private struct VerdictReasonEnvelope: Decodable {
  let reason: VerdictReasonV1
}

private func requireVerdictReasonConformances<Value>(_ value: Value)
where Value: Codable & Equatable & Sendable {
  _ = value
}

private func requireSameVerdictReasonType(_ type: VerdictReasonV1.Type) {
  _ = type
}

private func makeVerdictReasonV1(
  observedAt: Date = Date(timeIntervalSince1970: 950_608_800)
) throws -> VerdictReasonV1 {
  VerdictReasonV1(
    code: .brandImpersonationUnrelatedDomain,
    family: try ReasonFamily(validating: "identity_impersonation"),
    severity: try ReasonSeverity(validating: "high"),
    summaryKey: try LocalizationKey(
      validating: "verdict.reason.brand_impersonation_unrelated_domain"
    ),
    observedAt: observedAt,
    freshness: try FreshnessCategory(validating: "current")
  )
}

private func nestedVerdictReasonData(observedAt: String) throws -> Data {
  try JSONSerialization.data(
    withJSONObject: [
      "reason": [
        "code": "brand_impersonation_unrelated_domain",
        "family": "identity_impersonation",
        "severity": "high",
        "summary_key": "verdict.reason.brand_impersonation_unrelated_domain",
        "observed_at": observedAt,
        "freshness": "current",
      ]
    ],
    options: [.sortedKeys]
  )
}
