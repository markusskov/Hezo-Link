import Foundation

/// The exact public verdict vocabulary.
public enum VerdictLabelV1: String, CaseIterable, Codable, Sendable {
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

/// The source-compatible spelling of the public verdict vocabulary.
public typealias VerdictLabel = VerdictLabelV1
