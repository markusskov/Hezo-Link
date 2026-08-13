import Foundation

/// The exact public V1 analysis-profile vocabulary.
public enum AnalysisProfileV1: String, CaseIterable, Codable, Sendable {
  /// The standard manual-check analysis profile.
  case standard

  /// Decodes only the canonical public profile without echoing an invalid candidate.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    guard let value = Self(rawValue: candidate) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid analysis profile."
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
