import Foundation
import Testing

@testable import HezoLinkCore

struct VerdictTests {
  @Test(
    "Verdict labels use the exact public wire vocabulary",
    arguments: [
      (VerdictLabel.unknown, "unknown"),
      (VerdictLabel.noKnownDanger, "no_known_danger"),
      (VerdictLabel.caution, "caution"),
      (VerdictLabel.dangerous, "dangerous"),
    ]
  )
  func verdictLabelWireValue(testCase: (VerdictLabel, String)) throws {
    let (label, expectedWireValue) = testCase
    let data = try HezoJSON.makeEncoder().encode(label)
    let wireValue = try HezoJSON.makeResponseDecoder().decode(String.self, from: data)
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictLabel.self, from: data)

    #expect(wireValue == expectedWireValue)
    #expect(decoded == label)
  }

  @Test(
    "Verdict label aliases and internal labels are rejected",
    arguments: ["safe", "likely_safe", "allow", "warn", "block", "malicious", "suspicious"]
  )
  func invalidVerdictLabelsAreRejected(rawValue: String) throws {
    let data = try #require("\"\(rawValue)\"".data(using: .utf8))

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(VerdictLabel.self, from: data)
    }
  }

  @Test(
    "Recommended actions use the documented wire values",
    arguments: [
      (RecommendedAction.allow, "allow"),
      (RecommendedAction.warn, "warn"),
      (RecommendedAction.avoid, "avoid"),
      (RecommendedAction.retry, "retry"),
    ]
  )
  func recommendedActionRoundTrip(testCase: (RecommendedAction, String)) throws {
    let (action, expectedWireValue) = testCase
    let data = try HezoJSON.makeEncoder().encode(action)
    let wireValue = try HezoJSON.makeResponseDecoder().decode(String.self, from: data)
    let decoded = try HezoJSON.makeResponseDecoder().decode(RecommendedAction.self, from: data)

    #expect(wireValue == expectedWireValue)
    #expect(decoded == action)
  }

  @Test func verdictReasonMatchesGoldenWireContract() throws {
    let reason = try makeReason()
    let data = try HezoJSON.makeEncoder().encode(reason)
    let wireValue = try #require(String(data: data, encoding: .utf8))
    let expected =
      #"{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","freshness":"current","observed_at":"2000-02-15T10:00:00Z","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain"}"#
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictReason.self, from: data)

    #expect(wireValue == expected)
    #expect(decoded == reason)
  }

  @Test func verdictReasonReaderToleratesAdditiveUnknownField() throws {
    let json =
      #"{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain","observed_at":"2000-02-15T10:00:00Z","freshness":"current","future_optional":true}"#
    let data = try #require(json.data(using: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictReason.self, from: data)

    #expect(decoded.code == .brandImpersonationUnrelatedDomain)
  }

  @Test func verdictReasonSetEnforcesFiveItemLimitDuringConstructionAndDecoding() throws {
    let reason = try makeReason()
    let fiveReasons = Array(repeating: reason, count: 5)
    let sixReasons = Array(repeating: reason, count: 6)
    let bounded = try VerdictReasons(fiveReasons)
    let boundedData = try HezoJSON.makeEncoder().encode(bounded)
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictReasons.self, from: boundedData)
    let oversizedData = try HezoJSON.makeEncoder().encode(sixReasons)

    #expect(bounded.count == 5)
    #expect(decoded.values == fiveReasons)
    #expect(throws: VerdictReasonsError.tooManyReasons) {
      try VerdictReasons(sixReasons)
    }
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(VerdictReasons.self, from: oversizedData)
    }
  }

  @Test func timestampsRequireCanonicalUTCWholeSecondPrecision() throws {
    let fractionalDate = Date(timeIntervalSince1970: 951_091_200.5)
    let outOfRangeDate = Date(timeIntervalSince1970: 253_402_300_800)
    let fractionalJSON = #""2000-02-15T10:00:00.500Z""#
    let offsetJSON = #""2000-02-15T11:00:00+01:00""#
    let impossibleJSON = #""2000-02-30T10:00:00Z""#

    #expect(throws: EncodingError.self) {
      try HezoJSON.makeEncoder().encode(fractionalDate)
    }
    #expect(throws: EncodingError.self) {
      try HezoJSON.makeEncoder().encode(outOfRangeDate)
    }

    for json in [fractionalJSON, offsetJSON, impossibleJSON] {
      let data = try #require(json.data(using: .utf8))
      #expect(throws: DecodingError.self) {
        try HezoJSON.makeResponseDecoder().decode(Date.self, from: data)
      }
    }
  }

  private func makeReason() throws -> VerdictReason {
    let observedAt = try #require(
      ISO8601DateFormatter().date(from: "2000-02-15T10:00:00Z")
    )
    return try VerdictReason(
      code: .brandImpersonationUnrelatedDomain,
      family: ReasonFamily(validating: "identity_impersonation"),
      severity: ReasonSeverity(validating: "high"),
      summaryKey: LocalizationKey(
        validating: "verdict.reason.brand_impersonation_unrelated_domain"
      ),
      observedAt: observedAt,
      freshness: FreshnessCategory(validating: "current")
    )
  }
}
