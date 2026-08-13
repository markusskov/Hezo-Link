import Foundation
import Testing

@testable import HezoLinkCore

struct ContractValueTests {
  @Test(
    "Forward-compatible contract values preserve valid wire values",
    arguments: [
      "a",
      "exact_url",
      "future_reason_2",
      "a" + String(repeating: "b", count: 127),
    ]
  )
  func validValuesRoundTrip(rawValue: String) throws {
    let value = try ReasonCode(validating: rawValue)
    let data = try HezoJSON.makeEncoder().encode(value)
    let decoded = try HezoJSON.makeResponseDecoder().decode(ReasonCode.self, from: data)

    #expect(decoded.rawValue == rawValue)
  }

  @Test(
    "Invalid stable values return the exact bounded error",
    arguments: [
      ("_leading", ContractValueError.invalidFormat),
      ("trailing_", ContractValueError.invalidFormat),
      ("double__underscore", ContractValueError.invalidFormat),
      ("Uppercase", ContractValueError.invalidFormat),
      ("9leading_digit", ContractValueError.invalidFormat),
      ("contains-hyphen", ContractValueError.invalidFormat),
      ("nonascii_å", ContractValueError.invalidFormat),
      (
        "a" + String(repeating: "b", count: 128),
        ContractValueError.tooLong
      ),
    ]
  )
  func invalidValuesAreRejected(testCase: (String, ContractValueError)) {
    let (rawValue, expectedError) = testCase

    #expect(throws: expectedError) {
      try ReasonCode(validating: rawValue)
    }
  }

  @Test func emptyValueHasSpecificBoundedError() {
    #expect(throws: ContractValueError.empty) {
      try ProblemCode(validating: "")
    }
  }

  @Test func everyDecoderOmitsRejectedCandidate() throws {
    let candidate = "AttackerSecretValue"
    let data = try #require("\"\(candidate)\"".data(using: .utf8))

    try expectDecodeErrorOmitsCandidate(ReasonCode.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ProblemCode.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ConfidenceCategory.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(EvaluatedScope.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ReasonFamily.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(ReasonSeverity.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(FreshnessCategory.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(LocalizationKey.self, from: data, candidate: candidate)
    try expectDecodeErrorOmitsCandidate(RecommendedAction.self, from: data, candidate: candidate)
  }

  @Test func localizationKeysHaveBoundedDotSeparatedGrammar() throws {
    let valid = try LocalizationKey(
      validating: "verdict.reason.brand_impersonation_unrelated_domain"
    )

    #expect(valid.rawValue == "verdict.reason.brand_impersonation_unrelated_domain")
    let maximumKey =
      "a" + String(repeating: "b", count: 127) + ".c"
      + String(repeating: "d", count: 126)
    let overlongKey =
      "a" + String(repeating: "b", count: 127) + ".c"
      + String(repeating: "d", count: 127)
    #expect(try LocalizationKey(validating: maximumKey).rawValue == maximumKey)
    #expect(throws: ContractValueError.empty) {
      try LocalizationKey(validating: "verdict..reason")
    }
    #expect(throws: ContractValueError.invalidFormat) {
      try LocalizationKey(validating: "verdict.Reason")
    }
    #expect(throws: ContractValueError.empty) {
      try LocalizationKey(validating: "")
    }
    #expect(throws: ContractValueError.tooLong) {
      try LocalizationKey(validating: overlongKey)
    }
  }

  @Test func rawRepresentableInitializersPreserveOnlyValidValues() {
    #expect(ReasonCode(rawValue: "valid_reason")?.rawValue == "valid_reason")
    #expect(ReasonCode(rawValue: "InvalidReason") == nil)
    #expect(LocalizationKey(rawValue: "verdict.reason")?.rawValue == "verdict.reason")
    #expect(LocalizationKey(rawValue: "verdict..reason") == nil)
  }

  @Test func knownAndFutureConfidenceValuesRemainDistinct() throws {
    let future = try ConfidenceCategory(validating: "very_high")

    #expect(ConfidenceCategory.low.rawValue == "low")
    #expect(ConfidenceCategory.medium.rawValue == "medium")
    #expect(ConfidenceCategory.high.rawValue == "high")
    #expect(future.rawValue == "very_high")
  }

  @Test func exactAndFutureEvaluatedScopesRemainDistinct() throws {
    let future = try EvaluatedScope(validating: "future_narrow_scope")

    #expect(EvaluatedScope.exactURL.rawValue == "exact_url")
    #expect(future.rawValue == "future_narrow_scope")
  }

  private func expectDecodeErrorOmitsCandidate<Value: Decodable>(
    _ type: Value.Type,
    from data: Data,
    candidate: String
  ) throws {
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(type, from: data)
      Issue.record("Expected invalid contract value to be rejected.")
    } catch {
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    }
  }
}
