import Foundation

/// A bounded validation failure for a V1 request identifier.
///
/// Cases intentionally carry no submitted content so ordinary error rendering cannot expose a
/// rejected request identifier.
public enum RequestIDContractError: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, LocalizedError
{
  /// The candidate was empty.
  case empty

  /// The candidate exceeded the published ASCII byte limit.
  case tooLong

  /// The candidate contained a byte outside the published ASCII alphabet.
  case invalidFormat

  /// A bounded, content-free description of the validation failure.
  public var description: String {
    switch self {
    case .empty:
      "The request identifier is empty."
    case .tooLong:
      "The request identifier exceeds the contract limit."
    case .invalidFormat:
      "The request identifier has an invalid format."
    }
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

/// An opaque, plane-local request identifier with the shared V1 wire grammar.
///
/// This type validates only the wire shape. It makes no claim about randomness, uniqueness,
/// authenticity, lifetime, persistence, or which producer is authorized to mint a value.
public struct RequestIDV1: RawRepresentable, Codable, Equatable, Hashable, Sendable,
  CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
{
  /// The smallest admitted ASCII byte length.
  public static let minimumByteCount = 1

  /// The largest admitted ASCII byte length.
  public static let maximumByteCount = 128

  private static let redaction = "<redacted-request-id>"

  /// The exact validated wire value.
  public let rawValue: String

  /// Creates a request identifier from its exact V1 wire value.
  ///
  /// - Parameter rawValue: One through 128 ASCII letters, digits, underscores, or hyphens.
  /// - Throws: A payload-free `RequestIDContractError` when the candidate is invalid.
  public init(validating rawValue: String) throws {
    guard rawValue.isEmpty == false else {
      throw RequestIDContractError.empty
    }
    guard rawValue.utf8.count <= Self.maximumByteCount else {
      throw RequestIDContractError.tooLong
    }
    guard rawValue.utf8.allSatisfy(Self.isAllowedByte) else {
      throw RequestIDContractError.invalidFormat
    }

    self.rawValue = rawValue
  }

  /// Creates a request identifier when the raw value matches the exact V1 wire grammar.
  public init?(rawValue: String) {
    guard let value = try? Self(validating: rawValue) else {
      return nil
    }
    self = value
  }

  /// Decodes and validates a request identifier without echoing rejected content.
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      try self.init(validating: container.decode(String.self))
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid V1 request identifier."
        )
      )
    }
  }

  /// Encodes the exact validated request identifier at the explicit wire boundary.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  /// A fixed redaction that never includes the request identifier.
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

  private static func isAllowedByte(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
      || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
  }
}
