import Foundation

/// The exact public V1 check-response status vocabulary.
public enum CheckResponseStatusV1: String, CaseIterable, Codable, Sendable {
  /// The check has reached its completed state.
  case complete

  /// The check remains in progress.
  case pending

  /// Decodes only the canonical public statuses without echoing an invalid candidate.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    guard let value = Self(rawValue: candidate) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid check-response status."
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

/// The source-compatible spelling of `CheckResponseStatusV1` used before V1 extraction.
public typealias CheckResponseStatus = CheckResponseStatusV1
