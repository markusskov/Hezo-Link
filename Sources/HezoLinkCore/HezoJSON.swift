import Foundation

/// Creates fresh, concurrency-safe JSON coders for Hezo public contracts.
public enum HezoJSON {
  /// Creates a deterministic encoder using explicit keys and the authoritative proleptic-Gregorian
  /// mapping for canonical UTC whole-second instants.
  public static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      let seconds = date.timeIntervalSince1970
      guard seconds.isFinite, seconds == seconds.rounded(.towardZero) else {
        throw EncodingError.invalidValue(
          date,
          EncodingError.Context(
            codingPath: encoder.codingPath,
            debugDescription: "Contract instants require UTC whole-second precision."
          )
        )
      }

      let instant: CanonicalInstantV1
      do {
        instant = try CanonicalInstantV1(validating: date)
      } catch {
        throw EncodingError.invalidValue(
          date,
          EncodingError.Context(
            codingPath: encoder.codingPath,
            debugDescription: "Contract instant is outside the canonical UTC range."
          )
        )
      }

      try instant.encode(to: encoder)
    }
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return encoder
  }

  /// Creates a response decoder that validates values but tolerates additive unknown object fields.
  ///
  /// Server request validation remains schema-strict. Tolerance here lets older iOS clients read a
  /// response with a newly added optional field without weakening closed enums or field limits.
  public static func makeResponseDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let candidate = try container.decode(String.self)

      do {
        return try CanonicalInstantV1(validating: candidate).date
      } catch {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Invalid canonical UTC contract instant."
        )
      }
    }
    return decoder
  }
}
