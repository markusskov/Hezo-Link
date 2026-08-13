import Foundation

/// A bounded failure produced while validating an opaque V1 check token.
///
/// The rejected candidate is intentionally absent so ordinary error rendering cannot expose an
/// opaque token value.
public enum CheckTokenContractError: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, LocalizedError
{
  /// The candidate was not the canonical 32-byte V1 token encoding.
  case invalidFormat

  /// A bounded, content-free description of the token failure.
  public var description: String {
    "The check token has an invalid format."
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

/// An opaque, canonical unpadded base64url token field for a V1 check.
///
/// Encoding is the only public boundary that reveals the token. Descriptions, debug output, and
/// reflection remain redacted.
public struct CheckTokenV1: Codable, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The exact encoded length of a canonical V1 token.
  public static let encodedCharacterCount = 43

  /// The exact decoded length of a V1 token.
  public static let decodedByteCount = 32

  private static let redaction = "<redacted-check-token>"

  private let encodedValue: String

  /// Creates an opaque token from its canonical unpadded base64url encoding.
  /// - Parameter encodedValue: Exactly 43 ASCII base64url characters encoding 32 bytes.
  /// - Throws: `CheckTokenContractError.invalidFormat` for every noncanonical candidate.
  public init(validating encodedValue: String) throws {
    let bytes = Array(encodedValue.utf8)
    guard bytes.count == Self.encodedCharacterCount,
      bytes.allSatisfy(Self.isBase64URLByte),
      let finalByte = bytes.last,
      Self.isCanonicalFinalByte(finalByte)
    else {
      throw CheckTokenContractError.invalidFormat
    }

    let paddedBase64 =
      encodedValue
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/") + "="
    guard let decoded = Data(base64Encoded: paddedBase64),
      decoded.count == Self.decodedByteCount,
      Self.canonicalEncoding(of: decoded) == encodedValue
    else {
      throw CheckTokenContractError.invalidFormat
    }

    self.encodedValue = encodedValue
  }

  /// Decodes only the canonical token representation without echoing a rejected candidate.
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      try self.init(validating: container.decode(String.self))
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid V1 check token."
        )
      )
    }
  }

  /// Encodes the exact validated token only at the explicit wire boundary.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(encodedValue)
  }

  /// A fixed redaction that never includes the opaque token value.
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

  private static func isBase64URLByte(_ byte: UInt8) -> Bool {
    base64URLIndex(of: byte) != nil
  }

  private static func isCanonicalFinalByte(_ byte: UInt8) -> Bool {
    guard let index = base64URLIndex(of: byte) else {
      return false
    }
    return index.isMultiple(of: 4)
  }

  private static func base64URLIndex(of byte: UInt8) -> UInt8? {
    switch byte {
    case 0x41...0x5A:
      byte - 0x41
    case 0x61...0x7A:
      byte - 0x61 + 26
    case 0x30...0x39:
      byte - 0x30 + 52
    case 0x2D:
      62
    case 0x5F:
      63
    default:
      nil
    }
  }

  private static func canonicalEncoding(of data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
