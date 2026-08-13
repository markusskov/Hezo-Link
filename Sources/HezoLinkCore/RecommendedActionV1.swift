import Foundation

/// The bounded action recommended to the user, independent of block eligibility.
public enum RecommendedActionV1: String, CaseIterable, Codable, Sendable {
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

/// The source-compatible spelling of the public recommended-action vocabulary.
public typealias RecommendedAction = RecommendedActionV1
