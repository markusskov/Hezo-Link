import Foundation

/// A bounded, provenance-backed reason included in a public verdict.
public struct VerdictReasonV1: Codable, Equatable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case code
    case family
    case severity
    case summaryKey = "summary_key"
    case observedAt = "observed_at"
    case freshness
  }

  /// The stable, forward-compatible reason code.
  public let code: ReasonCode

  /// The bounded evidence family.
  public let family: ReasonFamily

  /// The bounded reason severity.
  public let severity: ReasonSeverity

  /// The localization key for approved user-facing copy.
  public let summaryKey: LocalizationKey

  /// The time the supporting fact was observed, at canonical UTC whole-second precision.
  public let observedAt: Date

  /// The bounded evidence-freshness category.
  public let freshness: FreshnessCategory

  /// Creates a bounded public verdict reason.
  public init(
    code: ReasonCode,
    family: ReasonFamily,
    severity: ReasonSeverity,
    summaryKey: LocalizationKey,
    observedAt: Date,
    freshness: FreshnessCategory
  ) {
    self.code = code
    self.family = family
    self.severity = severity
    self.summaryKey = summaryKey
    self.observedAt = observedAt
    self.freshness = freshness
  }
}

/// The source-compatible spelling of the public verdict reason.
public typealias VerdictReason = VerdictReasonV1
