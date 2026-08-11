import Foundation

/// The exact public verdict vocabulary.
public enum VerdictLabel: String, CaseIterable, Codable, Sendable {
  /// Hezo lacks sufficient current evidence or required analysis did not complete.
  case unknown

  /// The selected profile found no meaningful current danger; this is not a safety guarantee.
  case noKnownDanger = "no_known_danger"

  /// Corroborated evidence justifies caution.
  case caution

  /// Current evidence satisfies the Dangerous policy.
  case dangerous

  /// Decodes only the four canonical public labels without echoing an invalid candidate.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    guard let value = Self(rawValue: candidate) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid public verdict label."
      )
    }
    self = value
  }

  /// Encodes the canonical public wire value.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// The bounded action recommended to the user, independent of block eligibility.
public enum RecommendedAction: String, CaseIterable, Codable, Sendable {
  /// Proceed with ordinary care after a validated `no_known_danger` result.
  case allow

  /// Warn the user before they continue.
  case warn

  /// Recommend avoiding the target.
  case avoid

  /// Ask the user to retry because the result is incomplete or unavailable.
  case retry

  /// Decodes only the documented action values without echoing an invalid candidate.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    guard let value = Self(rawValue: candidate) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid recommended action."
      )
    }
    self = value
  }

  /// Encodes the canonical action wire value.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// A bounded, provenance-backed reason included in a public verdict.
public struct VerdictReason: Codable, Equatable, Sendable {
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

/// A bounded failure category for a public reason set.
public enum VerdictReasonsError: Error, Equatable, Sendable, CustomStringConvertible {
  /// More than five reasons were supplied.
  case tooManyReasons

  /// A log-safe description that contains no reason content.
  public var description: String {
    "Public verdict reason count exceeds the contract limit."
  }
}

/// Zero through five ordered public verdict reasons.
public struct VerdictReasons: Codable, Equatable, Sendable {
  /// The maximum number of reasons in a public verdict.
  public static let maximumCount = 5

  /// The validated ordered reasons.
  public let values: [VerdictReason]

  /// The number of reasons.
  public var count: Int {
    values.count
  }

  /// Creates a bounded reason set.
  public init(_ values: [VerdictReason]) throws {
    guard values.count <= Self.maximumCount else {
      throw VerdictReasonsError.tooManyReasons
    }
    self.values = values
  }

  /// Decodes at most five reasons without first allocating an unbounded array.
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var values: [VerdictReason] = []
    values.reserveCapacity(Self.maximumCount)

    while container.isAtEnd == false {
      guard values.count < Self.maximumCount else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Public verdict reason count exceeds the contract limit."
        )
      }
      values.append(try container.decode(VerdictReason.self))
    }

    self.values = values
  }

  /// Encodes the reason set as the public JSON array.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for value in values {
      try container.encode(value)
    }
  }
}
