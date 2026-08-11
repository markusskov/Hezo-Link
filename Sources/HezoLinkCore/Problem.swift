import Darwin
import Foundation

/// A bounded failure category for a public problem value.
public enum ProblemContractError: Error, Equatable, Sendable, CustomStringConvertible {
  /// A required text field was empty.
  case emptyField

  /// A text field exceeded its published UTF-8 limit.
  case fieldTooLong

  /// A text field contained a control character or an invalid request-ID character.
  case invalidFieldFormat

  /// The status was outside the HTTP error range.
  case invalidStatus

  /// The retry delay was negative or exceeded the public limit.
  case invalidRetryDelay

  /// A retry delay was supplied for a non-retryable problem.
  case retryDelayNotAllowed

  /// A log-safe description that never contains field content.
  public var description: String {
    switch self {
    case .emptyField:
      "A required problem field is empty."
    case .fieldTooLong:
      "A problem field exceeds its contract limit."
    case .invalidFieldFormat:
      "A problem field has an invalid format."
    case .invalidStatus:
      "Problem status is outside the HTTP error range."
    case .invalidRetryDelay:
      "Problem retry delay is outside the contract range."
    case .retryDelayNotAllowed:
      "A non-retryable problem cannot include a retry delay."
    }
  }
}

/// A bounded RFC 3986 URI reference used as an RFC 9457 problem type.
public struct ProblemType: RawRepresentable, Codable, Hashable, Sendable {
  /// The maximum UTF-8 byte length of a problem type.
  public static let maximumUTF8ByteCount = 256

  /// The validated wire value.
  public let rawValue: String

  /// Creates a validated ASCII URI reference.
  public init(validating rawValue: String) throws {
    guard rawValue.isEmpty == false else {
      throw ProblemContractError.emptyField
    }
    guard rawValue.utf8.count <= Self.maximumUTF8ByteCount else {
      throw ProblemContractError.fieldTooLong
    }
    guard Self.isValidURIReference(rawValue) else {
      throw ProblemContractError.invalidFieldFormat
    }
    self.rawValue = rawValue
  }

  /// Creates a problem type when the raw value is valid.
  public init?(rawValue: String) {
    guard let value = try? Self(validating: rawValue) else {
      return nil
    }
    self = value
  }

  /// Decodes a type without echoing a rejected candidate in the error.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    do {
      try self.init(validating: candidate)
    } catch {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid problem-type URI reference."
      )
    }
  }

  /// Encodes the exact validated URI reference.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  private static func isValidURIReference(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard bytes.allSatisfy(isAllowedURIByte), hasValidPercentEscapes(bytes),
      hasValidIPLiteral(bytes)
    else {
      return false
    }

    let firstDelimiterIndex =
      bytes.firstIndex { byte in
        byte == 0x2F || byte == 0x3F || byte == 0x23
      } ?? bytes.endIndex
    if let colonIndex = bytes[..<firstDelimiterIndex].firstIndex(of: 0x3A) {
      guard isValidScheme(bytes[..<colonIndex]) else {
        return false
      }
    }

    return URL(string: value, encodingInvalidCharacters: false) != nil
  }

  private static func hasValidIPLiteral(_ bytes: [UInt8]) -> Bool {
    let openings = bytes.indices.filter { bytes[$0] == 0x5B }
    let closings = bytes.indices.filter { bytes[$0] == 0x5D }
    guard openings.count == closings.count else {
      return false
    }
    guard let open = openings.first, let close = closings.first else {
      return true
    }
    guard openings.count == 1, open < close, close > open + 1 else {
      return false
    }

    let firstDelimiter =
      bytes.firstIndex { byte in byte == 0x2F || byte == 0x3F || byte == 0x23 }
      ?? bytes.endIndex
    let referenceStart: Int
    if let colon = bytes[..<firstDelimiter].firstIndex(of: 0x3A) {
      referenceStart = colon + 1
    } else {
      referenceStart = bytes.startIndex
    }
    guard referenceStart + 1 < bytes.endIndex,
      bytes[referenceStart] == 0x2F,
      bytes[referenceStart + 1] == 0x2F
    else {
      return false
    }

    let authorityStart = referenceStart + 2
    let authorityEnd =
      bytes[authorityStart...].firstIndex { byte in
        byte == 0x2F || byte == 0x3F || byte == 0x23
      } ?? bytes.endIndex
    guard open >= authorityStart, close < authorityEnd else {
      return false
    }
    let beforeLiteral = bytes[authorityStart..<open]
    guard beforeLiteral.isEmpty || beforeLiteral.last == 0x40 else {
      return false
    }
    if close + 1 < authorityEnd {
      let port = bytes[(close + 1)..<authorityEnd]
      guard port.first == 0x3A,
        port.dropFirst().allSatisfy({ (0x30...0x39).contains($0) })
      else {
        return false
      }
    }

    let literal = String(decoding: bytes[(open + 1)..<close], as: UTF8.self)
    return isIPv6Address(literal) || isIPvFuture(literal)
  }

  private static func isIPv6Address(_ value: String) -> Bool {
    var address = in6_addr()
    return value.withCString { inet_pton(AF_INET6, $0, &address) } == 1
  }

  private static func isIPvFuture(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard let first = bytes.first, first == 0x56 || first == 0x76,
      let dot = bytes.dropFirst().firstIndex(of: 0x2E),
      dot > 1,
      dot + 1 < bytes.endIndex,
      bytes[1..<dot].allSatisfy(isHexDigit)
    else {
      return false
    }
    return bytes[(dot + 1)...].allSatisfy(isIPvFutureAddressByte)
  }

  private static func isIPvFutureAddressByte(_ byte: UInt8) -> Bool {
    isASCIIAlpha(byte) || (0x30...0x39).contains(byte)
      || [
        0x21, 0x24, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x3A,
        0x3B, 0x3D, 0x5F, 0x7E,
      ].contains(byte)
  }

  private static func isAllowedURIByte(_ byte: UInt8) -> Bool {
    switch byte {
    case 0x21, 0x23...0x3B, 0x3D, 0x3F...0x5B, 0x5D, 0x5F, 0x61...0x7A, 0x7E:
      true
    default:
      false
    }
  }

  private static func hasValidPercentEscapes(_ bytes: [UInt8]) -> Bool {
    var index = bytes.startIndex
    while index < bytes.endIndex {
      guard bytes[index] == 0x25 else {
        index += 1
        continue
      }
      guard index + 2 < bytes.endIndex,
        isHexDigit(bytes[index + 1]),
        isHexDigit(bytes[index + 2])
      else {
        return false
      }
      index += 3
    }
    return true
  }

  private static func isValidScheme(_ bytes: ArraySlice<UInt8>) -> Bool {
    guard let first = bytes.first, isASCIIAlpha(first) else {
      return false
    }
    return bytes.dropFirst().allSatisfy { byte in
      isASCIIAlpha(byte) || (0x30...0x39).contains(byte) || byte == 0x2B || byte == 0x2D
        || byte == 0x2E
    }
  }

  private static func isASCIIAlpha(_ byte: UInt8) -> Bool {
    (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
  }

  private static func isHexDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }
}

/// A public RFC 9457-style problem value with bounded, stable contract fields.
public struct Problem: Codable, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  private enum CodingKeys: String, CodingKey {
    case type
    case title
    case status
    case code
    case detail
    case requestID = "request_id"
    case retryable
    case retryAfterSeconds = "retry_after_seconds"
  }

  /// The maximum UTF-8 byte length of a problem type.
  public static let maximumTypeUTF8ByteCount = ProblemType.maximumUTF8ByteCount

  /// The maximum UTF-8 byte length of a problem title.
  public static let maximumTitleUTF8ByteCount = 128

  /// The maximum UTF-8 byte length of problem detail.
  public static let maximumDetailUTF8ByteCount = 512

  /// The maximum ASCII byte length of a plane-local request identifier.
  public static let maximumRequestIDByteCount = 128

  /// The maximum public retry delay.
  public static let maximumRetryAfterSeconds = 86_400

  /// The problem-type URI as supplied by the API contract.
  public let type: ProblemType

  /// The bounded, approved title.
  public let title: String

  /// The HTTP status represented by the problem.
  public let status: Int

  /// The stable, forward-compatible machine code.
  public let code: ProblemCode

  /// Bounded user-facing detail. This value must never be an exception string or request echo.
  public let detail: String

  /// A plane-local, short-lived request identifier.
  public let requestID: String

  /// Whether the operation may succeed when retried.
  public let retryable: Bool

  /// An optional bounded retry delay in seconds.
  public let retryAfterSeconds: Int?

  /// Creates a validated public problem value.
  public init(
    type: String,
    title: String,
    status: Int,
    code: ProblemCode,
    detail: String,
    requestID: String,
    retryable: Bool,
    retryAfterSeconds: Int? = nil
  ) throws {
    let validatedType = try ProblemType(validating: type)
    try Self.validateText(title, maximumUTF8ByteCount: Self.maximumTitleUTF8ByteCount)
    try Self.validateText(detail, maximumUTF8ByteCount: Self.maximumDetailUTF8ByteCount)
    try Self.validateRequestID(requestID)

    guard (400...599).contains(status) else {
      throw ProblemContractError.invalidStatus
    }

    if let retryAfterSeconds {
      guard (0...Self.maximumRetryAfterSeconds).contains(retryAfterSeconds) else {
        throw ProblemContractError.invalidRetryDelay
      }
      guard retryable else {
        throw ProblemContractError.retryDelayNotAllowed
      }
    }

    self.type = validatedType
    self.title = title
    self.status = status
    self.code = code
    self.detail = detail
    self.requestID = requestID
    self.retryable = retryable
    self.retryAfterSeconds = retryAfterSeconds
  }

  /// Decodes and validates every public problem invariant.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let retryAfterSeconds: Int?
    if container.contains(.retryAfterSeconds) {
      retryAfterSeconds = try container.decode(Int.self, forKey: .retryAfterSeconds)
    } else {
      retryAfterSeconds = nil
    }
    do {
      try self.init(
        type: container.decode(String.self, forKey: .type),
        title: container.decode(String.self, forKey: .title),
        status: container.decode(Int.self, forKey: .status),
        code: container.decode(ProblemCode.self, forKey: .code),
        detail: container.decode(String.self, forKey: .detail),
        requestID: container.decode(String.self, forKey: .requestID),
        retryable: container.decode(Bool.self, forKey: .retryable),
        retryAfterSeconds: retryAfterSeconds
      )
    } catch let error as DecodingError {
      throw error
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid public problem value."
        )
      )
    }
  }

  /// A log-safe summary that omits type, title, detail, and request identifier.
  public var description: String {
    "Problem(status: \(status), code: \(code.rawValue), retryable: \(retryable))"
  }

  /// A log-safe debug summary identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A bounded reflection surface that omits type, title, detail, and request identifier.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": description])
  }

  private static func validateText(_ value: String, maximumUTF8ByteCount: Int) throws {
    guard value.isEmpty == false else {
      throw ProblemContractError.emptyField
    }
    guard value.utf8.count <= maximumUTF8ByteCount else {
      throw ProblemContractError.fieldTooLong
    }
    guard value.unicodeScalars.allSatisfy({ CharacterSet.controlCharacters.contains($0) == false })
    else {
      throw ProblemContractError.invalidFieldFormat
    }
  }

  private static func validateRequestID(_ value: String) throws {
    guard value.isEmpty == false else {
      throw ProblemContractError.emptyField
    }
    guard value.utf8.count <= maximumRequestIDByteCount else {
      throw ProblemContractError.fieldTooLong
    }
    guard value.utf8.allSatisfy(isRequestIDByte) else {
      throw ProblemContractError.invalidFieldFormat
    }
  }

  private static func isRequestIDByte(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
      || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
  }
}
