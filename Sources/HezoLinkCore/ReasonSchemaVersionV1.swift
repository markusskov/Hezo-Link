/// The exact public V1 verdict-reason schema-version vocabulary.
///
/// This value is encoder-only because `CheckRequestV1` is encoder-only. `Codable` cannot guarantee
/// schema-exact arbitrary-precision JSON numeric equality across decoders. This package selects no
/// strict inbound numeric decoder, so inbound validation remains at the standalone JSON Schema
/// boundary.
public enum ReasonSchemaVersionV1: Int, CaseIterable, Encodable, Sendable {
  /// The first frozen public verdict-reason schema.
  case v1 = 1

  /// Encodes the canonical public wire value.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
