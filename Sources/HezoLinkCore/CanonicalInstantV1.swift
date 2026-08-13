import Foundation

/// A bounded failure produced while validating a canonical V1 contract instant.
///
/// The rejected value is intentionally absent so ordinary error rendering cannot expose submitted
/// content or an exact instant.
public enum CanonicalInstantContractError: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, LocalizedError
{
  /// The value was not an exact canonical UTC whole-second instant in the V1 range.
  case invalidValue

  /// A bounded, content-free description of the validation failure.
  public var description: String {
    "The canonical instant has an invalid value."
  }

  /// A bounded, content-free debug description identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A bounded, content-free localized description identical to `description`.
  public var errorDescription: String? {
    description
  }
}

/// A canonical UTC whole-second contract instant in proleptic-Gregorian years 0001 through 9999.
///
/// This value validates only syntax and calendar reality. It does not read a clock or define
/// freshness, lifetime, expiry, retention, scheduling, persistence, or network behavior. Encoding
/// and explicit `date` access are the deliberate boundaries that reveal the instant; ordinary
/// rendering is redacted.
public struct CanonicalInstantV1: Codable, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The exact UTF-8 byte length of every V1 canonical instant.
  public static let wireByteCount = 20

  private static let redaction = "<redacted-canonical-instant>"

  private let wireValue: String

  /// The validated absolute instant using the contract's proleptic-Gregorian civil-date mapping.
  public let date: Date

  /// Creates an instant from its exact `YYYY-MM-DDTHH:mm:ssZ` V1 wire value.
  ///
  /// - Throws: `CanonicalInstantContractError.invalidValue` when the value is noncanonical,
  ///   outside years 0001 through 9999, or not a real calendar instant.
  public init(validating wireValue: String) throws {
    let bytes = Array(wireValue.utf8)
    guard let components = Self.parse(bytes) else {
      throw CanonicalInstantContractError.invalidValue
    }

    self.wireValue = wireValue
    self.date = Date(timeIntervalSince1970: TimeInterval(Self.unixSeconds(for: components)))
  }

  /// Creates an instant from an exact UTC whole-second `Date` in the V1 range.
  ///
  /// - Throws: `CanonicalInstantContractError.invalidValue` when the date is non-finite,
  ///   fractional, or outside the representable V1 range.
  public init(validating date: Date) throws {
    let seconds = date.timeIntervalSince1970
    guard seconds.isFinite, seconds == seconds.rounded(.towardZero),
      let wholeSeconds = Int64(exactly: seconds),
      let components = Self.components(fromUnixSeconds: wholeSeconds)
    else {
      throw CanonicalInstantContractError.invalidValue
    }

    self.wireValue = Self.wireValue(for: components)
    self.date = date
  }

  /// Decodes only an exact canonical instant without echoing a rejected candidate.
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      try self.init(validating: container.decode(String.self))
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid V1 canonical instant."
        )
      )
    }
  }

  /// Encodes the exact validated instant at the explicit wire boundary.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wireValue)
  }

  /// A fixed redaction that never includes the exact instant.
  public var description: String {
    Self.redaction
  }

  /// A fixed redaction identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing exactly one fixed, non-sensitive child.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": Self.redaction])
  }

  private static func parse(_ bytes: [UInt8]) -> Components? {
    guard bytes.count == wireByteCount,
      bytes[4] == 0x2D, bytes[7] == 0x2D, bytes[10] == 0x54,
      bytes[13] == 0x3A, bytes[16] == 0x3A, bytes[19] == 0x5A,
      let year = decimal(bytes, positions: 0..<4),
      let month = decimal(bytes, positions: 5..<7),
      let day = decimal(bytes, positions: 8..<10),
      let hour = decimal(bytes, positions: 11..<13),
      let minute = decimal(bytes, positions: 14..<16),
      let second = decimal(bytes, positions: 17..<19),
      (1...9999).contains(year),
      (1...12).contains(month),
      (1...daysInMonth(month, year: year)).contains(day),
      (0...23).contains(hour),
      (0...59).contains(minute),
      (0...59).contains(second)
    else {
      return nil
    }

    return Components(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second
    )
  }

  private static func decimal(_ bytes: [UInt8], positions: Range<Int>) -> Int? {
    var value = 0
    for position in positions {
      let byte = bytes[position]
      guard (0x30...0x39).contains(byte) else {
        return nil
      }
      value = value * 10 + Int(byte - 0x30)
    }
    return value
  }

  private static func daysInMonth(_ month: Int, year: Int) -> Int {
    switch month {
    case 2:
      isLeapYear(year) ? 29 : 28
    case 4, 6, 9, 11:
      30
    default:
      31
    }
  }

  private static func isLeapYear(_ year: Int) -> Bool {
    year.isMultiple(of: 400)
      || (year.isMultiple(of: 4) && year.isMultiple(of: 100) == false)
  }

  private static func unixSeconds(for components: Components) -> Int64 {
    let days = daysSinceUnixEpoch(
      year: Int64(components.year),
      month: Int64(components.month),
      day: Int64(components.day)
    )
    let secondsWithinDay =
      Int64(components.hour) * 3_600 + Int64(components.minute) * 60
      + Int64(components.second)
    return days * 86_400 + secondsWithinDay
  }

  /// Converts a proleptic-Gregorian civil date to its day offset from 1970-01-01.
  private static func daysSinceUnixEpoch(year: Int64, month: Int64, day: Int64) -> Int64 {
    let adjustedYear = year - (month <= 2 ? 1 : 0)
    let era = adjustedYear / 400
    let yearOfEra = adjustedYear - era * 400
    let adjustedMonth = month + (month > 2 ? -3 : 9)
    let dayOfYear = (153 * adjustedMonth + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
  }

  private static func components(fromUnixSeconds seconds: Int64) -> Components? {
    var day = seconds / 86_400
    var secondsWithinDay = seconds % 86_400
    if secondsWithinDay < 0 {
      day -= 1
      secondsWithinDay += 86_400
    }

    let zeroBasedDay = day + 719_468
    let era = zeroBasedDay >= 0 ? zeroBasedDay / 146_097 : (zeroBasedDay - 146_096) / 146_097
    let dayOfEra = zeroBasedDay - era * 146_097
    let yearOfEra =
      (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
    var year = yearOfEra + era * 400
    let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    let monthPosition = (5 * dayOfYear + 2) / 153
    let civilDay = dayOfYear - (153 * monthPosition + 2) / 5 + 1
    let civilMonth = monthPosition + (monthPosition < 10 ? 3 : -9)
    year += civilMonth <= 2 ? 1 : 0

    guard (1...9999).contains(year) else {
      return nil
    }

    let hour = secondsWithinDay / 3_600
    let minute = (secondsWithinDay % 3_600) / 60
    let second = secondsWithinDay % 60
    return Components(
      year: Int(year),
      month: Int(civilMonth),
      day: Int(civilDay),
      hour: Int(hour),
      minute: Int(minute),
      second: Int(second)
    )
  }

  private static func wireValue(for components: Components) -> String {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(wireByteCount)
    appendDecimal(components.year, width: 4, to: &bytes)
    bytes.append(0x2D)
    appendDecimal(components.month, width: 2, to: &bytes)
    bytes.append(0x2D)
    appendDecimal(components.day, width: 2, to: &bytes)
    bytes.append(0x54)
    appendDecimal(components.hour, width: 2, to: &bytes)
    bytes.append(0x3A)
    appendDecimal(components.minute, width: 2, to: &bytes)
    bytes.append(0x3A)
    appendDecimal(components.second, width: 2, to: &bytes)
    bytes.append(0x5A)
    return String(decoding: bytes, as: UTF8.self)
  }

  private static func appendDecimal(_ value: Int, width: Int, to bytes: inout [UInt8]) {
    var divisor = 1
    for _ in 1..<width {
      divisor *= 10
    }
    var remainder = value
    for _ in 0..<width {
      bytes.append(UInt8(remainder / divisor) + 0x30)
      remainder %= divisor
      divisor = max(divisor / 10, 1)
    }
  }

  private struct Components {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int
  }
}
