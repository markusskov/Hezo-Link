import Foundation

/// Creates fresh, concurrency-safe JSON coders for Hezo public contracts.
public enum HezoJSON {
  /// Creates a deterministic encoder using explicit keys and canonical UTC whole-second instants.
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

      let formatter = canonicalUTCFormatter()
      let candidate = formatter.string(from: date)
      guard candidate.utf8.count == 20, let roundTrip = formatter.date(from: candidate),
        roundTrip == date
      else {
        throw EncodingError.invalidValue(
          date,
          EncodingError.Context(
            codingPath: encoder.codingPath,
            debugDescription: "Contract instant is outside the canonical UTC range."
          )
        )
      }

      var container = encoder.singleValueContainer()
      try container.encode(candidate)
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
      let formatter = canonicalUTCFormatter()

      guard candidate.utf8.count == 20, candidate.last == "Z",
        let date = formatter.date(from: candidate), formatter.string(from: date) == candidate
      else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Invalid canonical UTC contract instant."
        )
      }
      return date
    }
    return decoder
  }

  private static func canonicalUTCFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }
}
