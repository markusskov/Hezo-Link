import Foundation

/// A bounded failure category for a structurally coherent public verdict.
public enum VerdictContractError: Error, Equatable, Sendable, CustomStringConvertible {
  /// The public label and recommended action are not an allowed pair.
  case incoherentLabelAndAction

  /// A log-safe description that contains no verdict content.
  public var description: String {
    "Verdict label and recommended action are incoherent."
  }
}

/// A structurally coherent public verdict value with bounded contract fields.
public struct Verdict: Codable, Equatable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case label
    case recommendedAction = "recommended_action"
    case confidence
    case evaluatedScope = "evaluated_scope"
    case reasons
  }

  /// The canonical public verdict label.
  public let label: VerdictLabelV1

  /// The bounded action recommended to the user.
  public let recommendedAction: RecommendedActionV1

  /// The bounded, forward-compatible confidence category.
  public let confidence: ConfidenceCategoryV1

  /// The bounded, forward-compatible evaluated scope.
  public let evaluatedScope: EvaluatedScopeV1

  /// Zero through five ordered public reasons.
  public let reasons: VerdictReasonsV1

  /// Creates a verdict whose label and recommended action satisfy the public pair contract.
  public init(
    label: VerdictLabelV1,
    recommendedAction: RecommendedActionV1,
    confidence: ConfidenceCategoryV1,
    evaluatedScope: EvaluatedScopeV1,
    reasons: VerdictReasonsV1
  ) throws {
    guard Self.isAllowed(label: label, recommendedAction: recommendedAction) else {
      throw VerdictContractError.incoherentLabelAndAction
    }

    self.label = label
    self.recommendedAction = recommendedAction
    self.confidence = confidence
    self.evaluatedScope = evaluatedScope
    self.reasons = reasons
  }

  /// Decodes and validates every structural public-verdict invariant.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let label = try container.decode(VerdictLabelV1.self, forKey: .label)
    let recommendedAction = try container.decode(
      RecommendedActionV1.self,
      forKey: .recommendedAction
    )
    let confidence = try container.decode(ConfidenceCategoryV1.self, forKey: .confidence)
    let evaluatedScope = try container.decode(EvaluatedScopeV1.self, forKey: .evaluatedScope)
    let reasons = try container.decode(VerdictReasonsV1.self, forKey: .reasons)

    do {
      try self.init(
        label: label,
        recommendedAction: recommendedAction,
        confidence: confidence,
        evaluatedScope: evaluatedScope,
        reasons: reasons
      )
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid public verdict value."
        )
      )
    }
  }

  /// Encodes exactly the five structural public-verdict fields.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(label, forKey: .label)
    try container.encode(recommendedAction, forKey: .recommendedAction)
    try container.encode(confidence, forKey: .confidence)
    try container.encode(evaluatedScope, forKey: .evaluatedScope)
    try container.encode(reasons, forKey: .reasons)
  }

  private static func isAllowed(
    label: VerdictLabelV1,
    recommendedAction: RecommendedActionV1
  ) -> Bool {
    switch (label, recommendedAction) {
    case (.unknown, .warn), (.unknown, .retry), (.noKnownDanger, .allow),
      (.caution, .warn), (.dangerous, .avoid):
      true
    default:
      false
    }
  }
}
