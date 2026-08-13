import Foundation

/// A bounded construction failure for a V1 pending check response.
///
/// Cases intentionally carry no submitted content, so error rendering cannot expose a request
/// identifier or token.
public enum PendingCheckResponseContractError: Error, Equatable, Sendable,
  CustomStringConvertible, CustomDebugStringConvertible, LocalizedError
{
  /// The retry hint was outside the published positive range.
  case invalidRetryAfterMilliseconds

  /// The expiry was not representable as a canonical whole-second UTC instant.
  case invalidExpiry

  /// The request identifier was empty.
  case emptyRequestID

  /// The request identifier exceeded its published ASCII limit.
  case requestIDTooLong

  /// The request identifier did not match its published ASCII grammar.
  case invalidRequestIDFormat

  /// A bounded, content-free description of the response failure.
  public var description: String {
    switch self {
    case .invalidRetryAfterMilliseconds:
      "The pending-check retry delay is outside the contract range."
    case .invalidExpiry:
      "The pending-check expiry is outside the canonical contract range."
    case .emptyRequestID:
      "The pending-check request identifier is empty."
    case .requestIDTooLong:
      "The pending-check request identifier exceeds the contract limit."
    case .invalidRequestIDFormat:
      "The pending-check request identifier has an invalid format."
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

/// The offline, wire-exact V1 response for a check that has not completed.
///
/// Unknown additive response members are tolerated while completed-response members are rejected
/// explicitly, including when their JSON value is `null`.
public struct PendingCheckResponseV1: Codable, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The frozen pending-response wire schema version.
  public static let schemaVersion = 1

  /// The only status admitted by this response envelope.
  public static let status = CheckResponseStatusV1.pending

  /// The smallest admitted retry hint.
  public static let minimumRetryAfterMilliseconds = 1

  /// The largest admitted retry hint.
  public static let maximumRetryAfterMilliseconds = 900_000

  /// The maximum ASCII byte length of a plane-local request identifier.
  public static let maximumRequestIDByteCount = RequestIDV1.maximumByteCount

  /// The opaque token field carried by the wire response.
  public let checkToken: CheckTokenV1

  /// The server retry hint in milliseconds.
  public let retryAfterMilliseconds: Int

  /// The canonical absolute expiry field, without runtime TTL semantics.
  public let expiresAt: Date

  /// A bounded plane-local request identifier.
  public let requestID: String

  private let requestIDValue: RequestIDV1

  private static let descriptionValue = "Pending check response."

  private enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case status
    case checkToken = "check_token"
    case retryAfterMilliseconds = "retry_after_ms"
    case expiresAt = "expires_at"
    case requestID = "request_id"
    case verdict
    case target
    case analysis
    case sourceNotices = "source_notices"
    case versions
    case evaluatedAt = "evaluated_at"
    case validUntil = "valid_until"
    case blockEligible = "block_eligible"
  }

  private enum DecodingFailure: Error {
    case invalidEnvelope
  }

  /// Creates a validated pending response without applying clock or TTL policy.
  public init(
    checkToken: CheckTokenV1,
    retryAfterMilliseconds: Int,
    expiresAt: Date,
    requestID: String
  ) throws {
    guard
      (Self.minimumRetryAfterMilliseconds...Self.maximumRetryAfterMilliseconds)
        .contains(retryAfterMilliseconds)
    else {
      throw PendingCheckResponseContractError.invalidRetryAfterMilliseconds
    }
    do {
      _ = try HezoJSON.makeEncoder().encode(expiresAt)
    } catch {
      throw PendingCheckResponseContractError.invalidExpiry
    }
    let validatedRequestID = try Self.validatedRequestIDForCompatibility(requestID)

    self.checkToken = checkToken
    self.retryAfterMilliseconds = retryAfterMilliseconds
    self.expiresAt = expiresAt
    self.requestID = requestID
    self.requestIDValue = validatedRequestID
  }

  /// Decodes the exact pending envelope while dropping genuinely unknown additive fields.
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let completedOnlyKeys: [CodingKeys] = [
        .verdict,
        .target,
        .analysis,
        .sourceNotices,
        .versions,
        .evaluatedAt,
        .validUntil,
        .blockEligible,
      ]
      guard completedOnlyKeys.allSatisfy({ container.contains($0) == false }) else {
        throw DecodingFailure.invalidEnvelope
      }
      guard try container.decode(Int.self, forKey: .schemaVersion) == Self.schemaVersion else {
        throw DecodingFailure.invalidEnvelope
      }
      guard try container.decode(CheckResponseStatusV1.self, forKey: .status) == Self.status else {
        throw DecodingFailure.invalidEnvelope
      }

      try self.init(
        checkToken: container.decode(CheckTokenV1.self, forKey: .checkToken),
        retryAfterMilliseconds: container.decode(Int.self, forKey: .retryAfterMilliseconds),
        expiresAt: container.decode(Date.self, forKey: .expiresAt),
        requestID: container.decode(String.self, forKey: .requestID)
      )
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid V1 pending check response."
        )
      )
    }
  }

  /// Encodes exactly the six frozen V1 pending-response members.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(Self.schemaVersion, forKey: .schemaVersion)
    try container.encode(Self.status, forKey: .status)
    try container.encode(checkToken, forKey: .checkToken)
    try container.encode(retryAfterMilliseconds, forKey: .retryAfterMilliseconds)
    try container.encode(expiresAt, forKey: .expiresAt)
    try container.encode(requestIDValue, forKey: .requestID)
  }

  /// A fixed summary that omits the token and request identifier.
  public var description: String {
    Self.descriptionValue
  }

  /// A fixed debug summary identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing exactly one fixed, non-sensitive child.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": Self.descriptionValue])
  }

  private static func validatedRequestIDForCompatibility(_ value: String) throws -> RequestIDV1 {
    do {
      return try RequestIDV1(validating: value)
    } catch RequestIDContractError.empty {
      throw PendingCheckResponseContractError.emptyRequestID
    } catch RequestIDContractError.tooLong {
      throw PendingCheckResponseContractError.requestIDTooLong
    } catch RequestIDContractError.invalidFormat {
      throw PendingCheckResponseContractError.invalidRequestIDFormat
    }
  }
}
