import Foundation
import HezoLinkCore
import Testing

struct VerdictV1Tests {
  @Test func publicSurfaceKeepsExactFiveFieldsAndConformances() throws {
    let verdict = try makeVerdict()
    let label: VerdictLabelV1 = verdict.label
    let recommendedAction: RecommendedActionV1 = verdict.recommendedAction
    let confidence: ConfidenceCategoryV1 = verdict.confidence
    let evaluatedScope: EvaluatedScopeV1 = verdict.evaluatedScope
    let reasons: VerdictReasonsV1 = verdict.reasons

    requireVerdictConformances(verdict)
    requireVerdictContractErrorConformances(VerdictContractError.incoherentLabelAndAction)
    #expect(label == .caution)
    #expect(recommendedAction == .warn)
    #expect(confidence == .high)
    #expect(evaluatedScope == .exactURL)
    #expect(reasons.count == 1)
  }

  @Test func verdictLabelActionPairMatrixIsExhaustive() {
    let pairKeys = verdictPairCases.map { testCase in
      "\(testCase.label.rawValue)|\(testCase.recommendedAction.rawValue)"
    }

    #expect(verdictPairCases.count == 16)
    #expect(Set(pairKeys).count == 16)
    #expect(verdictPairCases.filter(\.isAllowed).count == 5)
    #expect(verdictPairCases.filter { $0.isAllowed == false }.count == 11)
    #expect(Set(verdictPairCases.map(\.label)) == Set(VerdictLabelV1.allCases))
    #expect(
      Set(verdictPairCases.map(\.recommendedAction)) == Set(RecommendedActionV1.allCases)
    )
  }

  @Test(
    "Verdict construction and decoding enforce every label-action pair",
    arguments: verdictPairCases
  )
  func verdictLabelActionPairMatrix(testCase: VerdictPairCase) throws {
    let reasons = try VerdictReasonsV1([])
    let data = try makeVerdictData(
      label: testCase.label,
      recommendedAction: testCase.recommendedAction
    )

    if testCase.isAllowed {
      let verdict = try VerdictV1(
        label: testCase.label,
        recommendedAction: testCase.recommendedAction,
        confidence: .high,
        evaluatedScope: .exactURL,
        reasons: reasons
      )
      let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)

      #expect(verdict.label == testCase.label)
      #expect(verdict.recommendedAction == testCase.recommendedAction)
      #expect(decoded == verdict)
    } else {
      #expect(throws: VerdictContractError.incoherentLabelAndAction) {
        try VerdictV1(
          label: testCase.label,
          recommendedAction: testCase.recommendedAction,
          confidence: .high,
          evaluatedScope: .exactURL,
          reasons: reasons
        )
      }
      #expect(throws: DecodingError.self) {
        try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)
      }
    }
  }

  @Test func verdictMatchesExactFiveFieldGoldenWireContract() throws {
    let verdict = try makeVerdict()
    let data = try HezoJSON.makeEncoder().encode(verdict)
    let wireValue = try #require(String(data: data, encoding: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)

    #expect(wireValue == canonicalVerdictWire)
    #expect(data == Data(canonicalVerdictWire.utf8))
    #expect(decoded == verdict)
  }

  @Test func verdictReaderToleratesAndDropsAdditiveUnknownObjectFields() throws {
    let json =
      #"{"label":"unknown","recommended_action":"warn","confidence":"low","evaluated_scope":"exact_url","reasons":[],"future_optional":{"nested":true}}"#
    let data = try #require(json.data(using: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)
    let encoded = try HezoJSON.makeEncoder().encode(decoded)
    let encodedObject = try #require(
      JSONSerialization.jsonObject(with: encoded, options: [.fragmentsAllowed])
        as? [String: Any]
    )

    #expect(decoded.label == .unknown)
    #expect(decoded.recommendedAction == .warn)
    #expect(
      Set(encodedObject.keys)
        == ["label", "recommended_action", "confidence", "evaluated_scope", "reasons"]
    )
    #expect(encodedObject["future_optional"] == nil)
  }

  @Test func verdictPreservesBoundedReasonOrderAndDuplicates() throws {
    let firstReason = try makeReason()
    let secondReason = try makeReason(
      code: ReasonCode(validating: "synthetic_second_reason"),
      family: "synthetic_evidence",
      severity: "medium",
      summaryKey: "verdict.reason.synthetic_second_reason",
      observedAt: "2000-02-15T10:00:01Z",
      freshness: "recent"
    )
    let orderedReasons = [firstReason, secondReason, firstReason, secondReason, firstReason]
    let verdict = try makeVerdict(reasons: VerdictReasonsV1(orderedReasons))
    let data = try HezoJSON.makeEncoder().encode(verdict)
    let decoded = try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)

    #expect(decoded.reasons.count == 5)
    #expect(decoded.reasons.values == orderedReasons)
  }

  @Test func verdictRejectsSixReasonsDuringConstructionAndDecoding() throws {
    let reason = try makeReason()
    let sixReasons = Array(repeating: reason, count: 6)
    let encodedReasons = try HezoJSON.makeEncoder().encode(sixReasons)
    let reasonsValue = try JSONSerialization.jsonObject(
      with: encodedReasons,
      options: [.fragmentsAllowed]
    )
    let verdictData = try makeVerdictData(
      label: .caution,
      recommendedAction: .warn,
      reasons: reasonsValue
    )

    #expect(throws: VerdictReasonsError.tooManyReasons) {
      try VerdictReasonsV1(sixReasons)
    }
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: verdictData)
    }
  }

  @Test func verdictContractErrorsNeverReflectVerdictContent() throws {
    let confidenceCandidate = "private_confidence_sentinel"
    let scopeCandidate = "private_scope_sentinel"
    let reasonCandidate = "private_reason_sentinel"
    let summaryCandidate = "private.reason.sentinel"
    let reasons = try VerdictReasonsV1([
      makeReason(
        code: ReasonCode(validating: reasonCandidate),
        family: "private_family_sentinel",
        summaryKey: summaryCandidate
      )
    ])
    let candidates = [confidenceCandidate, scopeCandidate, reasonCandidate, summaryCandidate]

    do {
      _ = try VerdictV1(
        label: .dangerous,
        recommendedAction: .retry,
        confidence: ConfidenceCategoryV1(validating: confidenceCandidate),
        evaluatedScope: EvaluatedScopeV1(validating: scopeCandidate),
        reasons: reasons
      )
      Issue.record("Expected an incoherent verdict pair to be rejected.")
    } catch let error as VerdictContractError {
      #expect(error == .incoherentLabelAndAction)
      #expect(error.description == "Verdict label and recommended action are incoherent.")
      for candidate in candidates {
        #expect(String(describing: error).contains(candidate) == false)
        #expect(String(reflecting: error).contains(candidate) == false)
      }
    } catch {
      Issue.record("Verdict construction used an unexpected error category.")
    }

    let reasonObject: [String: Any] = [
      "code": reasonCandidate,
      "family": "private_family_sentinel",
      "severity": "high",
      "summary_key": summaryCandidate,
      "observed_at": "2000-02-15T10:00:00Z",
      "freshness": "current",
    ]
    let data = try makeVerdictData(
      label: .dangerous,
      recommendedAction: .retry,
      confidence: confidenceCandidate,
      evaluatedScope: scopeCandidate,
      reasons: [reasonObject]
    )

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(VerdictV1.self, from: data)
      Issue.record("Expected an incoherent encoded verdict pair to be rejected.")
    } catch let error as DecodingError {
      for candidate in candidates {
        #expect(String(describing: error).contains(candidate) == false)
        #expect(String(reflecting: error).contains(candidate) == false)
      }
    } catch {
      Issue.record("Verdict decoding used an unexpected error category.")
    }
  }

  @Test func nestedIncoherentPairKeepsCodingPathAndOmitsCandidates() {
    let confidenceCandidate = "private_nested_confidence_sentinel"
    let scopeCandidate = "private_nested_scope_sentinel"
    let reasonCandidate = "private_nested_reason_sentinel"
    let familyCandidate = "private_nested_family_sentinel"
    let summaryCandidate = "private.nested.summary.sentinel"
    let candidates = [
      confidenceCandidate,
      scopeCandidate,
      reasonCandidate,
      familyCandidate,
      summaryCandidate,
    ]
    let json =
      #"{"verdict":{"label":"dangerous","recommended_action":"retry","confidence":"\#(confidenceCandidate)","evaluated_scope":"\#(scopeCandidate)","reasons":[{"code":"\#(reasonCandidate)","family":"\#(familyCandidate)","severity":"high","summary_key":"\#(summaryCandidate)","observed_at":"2000-02-15T10:00:00Z","freshness":"current"}]}}"#

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(
        VerdictEnvelope.self,
        from: Data(json.utf8)
      )
      Issue.record("A nested incoherent verdict pair must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      let renderings = [String(describing: error), String(reflecting: error)]
      #expect(context.debugDescription == "Invalid public verdict value.")
      #expect(context.codingPath.map(\.stringValue) == ["verdict"])
      #expect(context.codingPath.map(\.intValue) == [nil])
      #expect(context.underlyingError == nil)
      for candidate in candidates {
        #expect(renderings.allSatisfy { $0.contains(candidate) == false })
      }
    } catch {
      Issue.record("Nested verdict decoding used an unexpected error category.")
    }
  }

  @Test func compatibilityAliasHasIdenticalTypeEncodingAndDecoding() throws {
    let canonical: VerdictV1 = try makeVerdict()
    let compatibility: Verdict = canonical
    let canonicalAgain: VerdictV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let decodedCanonical = try HezoJSON.makeResponseDecoder().decode(
      VerdictV1.self,
      from: compatibilityData
    )
    let decodedCompatibility = try HezoJSON.makeResponseDecoder().decode(
      Verdict.self,
      from: canonicalData
    )

    requireSameVerdictType(Verdict.self)
    #expect(canonicalAgain == canonical)
    #expect(canonicalData == Data(canonicalVerdictWire.utf8))
    #expect(compatibilityData == canonicalData)
    #expect(decodedCanonical == canonical)
    #expect(decodedCompatibility == canonical)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let verdict = try makeVerdict()
    let expectedData = Data(canonicalVerdictWire.utf8)
    let results = try await withThrowingTaskGroup(of: (VerdictV1, Data).self) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(verdict)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            VerdictV1.self,
            from: encoded
          )
          return (decoded, encoded)
        }
      }

      var values: [(VerdictV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == verdict && $0.1 == expectedData })
  }

  private func makeVerdict(
    label: VerdictLabelV1 = .caution,
    recommendedAction: RecommendedActionV1 = .warn,
    reasons: VerdictReasonsV1? = nil
  ) throws -> VerdictV1 {
    let boundedReasons: VerdictReasonsV1
    if let reasons {
      boundedReasons = reasons
    } else {
      boundedReasons = try VerdictReasonsV1([makeReason()])
    }

    return try VerdictV1(
      label: label,
      recommendedAction: recommendedAction,
      confidence: .high,
      evaluatedScope: .exactURL,
      reasons: boundedReasons
    )
  }

  private func makeVerdictData(
    label: VerdictLabelV1,
    recommendedAction: RecommendedActionV1,
    confidence: Any = "high",
    evaluatedScope: Any = "exact_url",
    reasons: Any = []
  ) throws -> Data {
    try JSONSerialization.data(
      withJSONObject: [
        "label": label.rawValue,
        "recommended_action": recommendedAction.rawValue,
        "confidence": confidence,
        "evaluated_scope": evaluatedScope,
        "reasons": reasons,
      ],
      options: [.sortedKeys]
    )
  }

  private func makeReason(
    code: ReasonCode = .brandImpersonationUnrelatedDomain,
    family: String = "identity_impersonation",
    severity: String = "high",
    summaryKey: String = "verdict.reason.brand_impersonation_unrelated_domain",
    observedAt: String = "2000-02-15T10:00:00Z",
    freshness: String = "current"
  ) throws -> VerdictReasonV1 {
    let observedAt = try #require(
      ISO8601DateFormatter().date(from: observedAt)
    )
    return try VerdictReasonV1(
      code: code,
      family: ReasonFamily(validating: family),
      severity: ReasonSeverity(validating: severity),
      summaryKey: LocalizationKey(validating: summaryKey),
      observedAt: observedAt,
      freshness: FreshnessCategory(validating: freshness)
    )
  }
}

private struct VerdictEnvelope: Decodable {
  let verdict: VerdictV1
}

private func requireVerdictConformances<Value>(_ value: Value)
where Value: Codable & Equatable & Sendable {
  _ = value
}

private func requireVerdictContractErrorConformances<Value>(_ value: Value)
where Value: Error & Equatable & Sendable & CustomStringConvertible {
  _ = value
}

private func requireSameVerdictType(_ type: VerdictV1.Type) {
  _ = type
}

struct VerdictPairCase: Sendable {
  let label: VerdictLabelV1
  let recommendedAction: RecommendedActionV1
  let isAllowed: Bool
}

let verdictPairCases: [VerdictPairCase] = [
  VerdictPairCase(label: .unknown, recommendedAction: .allow, isAllowed: false),
  VerdictPairCase(label: .unknown, recommendedAction: .warn, isAllowed: true),
  VerdictPairCase(label: .unknown, recommendedAction: .avoid, isAllowed: false),
  VerdictPairCase(label: .unknown, recommendedAction: .retry, isAllowed: true),
  VerdictPairCase(label: .noKnownDanger, recommendedAction: .allow, isAllowed: true),
  VerdictPairCase(label: .noKnownDanger, recommendedAction: .warn, isAllowed: false),
  VerdictPairCase(label: .noKnownDanger, recommendedAction: .avoid, isAllowed: false),
  VerdictPairCase(label: .noKnownDanger, recommendedAction: .retry, isAllowed: false),
  VerdictPairCase(label: .caution, recommendedAction: .allow, isAllowed: false),
  VerdictPairCase(label: .caution, recommendedAction: .warn, isAllowed: true),
  VerdictPairCase(label: .caution, recommendedAction: .avoid, isAllowed: false),
  VerdictPairCase(label: .caution, recommendedAction: .retry, isAllowed: false),
  VerdictPairCase(label: .dangerous, recommendedAction: .allow, isAllowed: false),
  VerdictPairCase(label: .dangerous, recommendedAction: .warn, isAllowed: false),
  VerdictPairCase(label: .dangerous, recommendedAction: .avoid, isAllowed: true),
  VerdictPairCase(label: .dangerous, recommendedAction: .retry, isAllowed: false),
]

private let canonicalVerdictWire =
  #"{"confidence":"high","evaluated_scope":"exact_url","label":"caution","reasons":[{"code":"brand_impersonation_unrelated_domain","family":"identity_impersonation","freshness":"current","observed_at":"2000-02-15T10:00:00Z","severity":"high","summary_key":"verdict.reason.brand_impersonation_unrelated_domain"}],"recommended_action":"warn"}"#
