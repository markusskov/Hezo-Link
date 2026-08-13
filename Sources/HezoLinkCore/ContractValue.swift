import Foundation

/// A bounded failure category for a stable wire-contract value.
///
/// The rejected value is intentionally absent so callers cannot accidentally log attacker-controlled input.
public enum ContractValueError: Error, Equatable, Sendable, CustomStringConvertible {
  /// The value was empty.
  case empty

  /// The value exceeded its defensive wire limit.
  case tooLong

  /// The value did not match the published grammar.
  case invalidFormat

  /// A log-safe description that never includes the rejected value.
  public var description: String {
    switch self {
    case .empty:
      "Stable contract value is empty."
    case .tooLong:
      "Stable contract value exceeds the local limit."
    case .invalidFormat:
      "Stable contract value has an invalid format."
    }
  }
}

enum StableContractValueValidator {
  static let maximumUTF8ByteCount = 128

  static func validate(_ rawValue: String) throws {
    guard rawValue.isEmpty == false else {
      throw ContractValueError.empty
    }

    guard rawValue.utf8.count <= maximumUTF8ByteCount else {
      throw ContractValueError.tooLong
    }

    let bytes = rawValue.utf8
    guard let first = bytes.first, isLowercaseASCII(first) else {
      throw ContractValueError.invalidFormat
    }

    var previousWasUnderscore = false
    for byte in bytes.dropFirst() {
      let isUnderscore = byte == 0x5F
      guard isLowercaseASCII(byte) || isASCIIDigit(byte) || isUnderscore else {
        throw ContractValueError.invalidFormat
      }
      guard previousWasUnderscore == false || isUnderscore == false else {
        throw ContractValueError.invalidFormat
      }
      previousWasUnderscore = isUnderscore
    }

    guard bytes.last != 0x5F else {
      throw ContractValueError.invalidFormat
    }
  }

  private static func isLowercaseASCII(_ byte: UInt8) -> Bool {
    (0x61...0x7A).contains(byte)
  }

  private static func isASCIIDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte)
  }
}

/// A marker that keeps stable values from different contract fields type-safe.
public protocol StableContractValueKind: Sendable {}

/// A forward-compatible, bounded lower-snake-case ASCII contract value.
public struct StableContractValue<Kind: StableContractValueKind>: RawRepresentable, Codable,
  Hashable, Sendable
{
  /// The validated wire value.
  public let rawValue: String

  fileprivate init(knownValid rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a validated contract value.
  /// - Parameter rawValue: Lower-snake-case ASCII of at most 128 UTF-8 bytes.
  public init(validating rawValue: String) throws {
    try StableContractValueValidator.validate(rawValue)
    self.rawValue = rawValue
  }

  /// Creates a contract value when the raw value is valid.
  public init?(rawValue: String) {
    guard (try? StableContractValueValidator.validate(rawValue)) != nil else {
      return nil
    }
    self.rawValue = rawValue
  }

  /// Decodes a value without echoing a rejected candidate in the error.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    do {
      try self.init(validating: candidate)
    } catch {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid stable contract value."
      )
    }
  }

  /// Encodes the exact validated wire value.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// The exact public check-response status vocabulary.
public enum CheckResponseStatus: String, CaseIterable, Codable, Sendable {
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
  public static let status = CheckResponseStatus.pending

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
      guard try container.decode(CheckResponseStatus.self, forKey: .status) == Self.status else {
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

/// Distinguishes reason-code values.
public enum ReasonCodeKind: StableContractValueKind {}

/// A forward-compatible reason code.
public typealias ReasonCode = StableContractValue<ReasonCodeKind>

/// Distinguishes problem-code values.
public enum ProblemCodeKind: StableContractValueKind {}

/// A forward-compatible public problem code.
public typealias ProblemCode = StableContractValue<ProblemCodeKind>

/// Distinguishes confidence-category values.
public enum ConfidenceCategoryKind: StableContractValueKind {}

/// A forward-compatible confidence category.
public typealias ConfidenceCategory = StableContractValue<ConfidenceCategoryKind>

/// Distinguishes evaluated-scope values.
public enum EvaluatedScopeKind: StableContractValueKind {}

/// A forward-compatible description of the evaluated scope.
public typealias EvaluatedScope = StableContractValue<EvaluatedScopeKind>

/// Distinguishes reason-family values.
public enum ReasonFamilyKind: StableContractValueKind {}

/// A forward-compatible reason family.
public typealias ReasonFamily = StableContractValue<ReasonFamilyKind>

/// Distinguishes reason-severity values.
public enum ReasonSeverityKind: StableContractValueKind {}

/// A forward-compatible reason severity.
public typealias ReasonSeverity = StableContractValue<ReasonSeverityKind>

/// Distinguishes freshness-category values.
public enum FreshnessCategoryKind: StableContractValueKind {}

/// A forward-compatible evidence-freshness category.
public typealias FreshnessCategory = StableContractValue<FreshnessCategoryKind>

public extension StableContractValue where Kind == ReasonCodeKind {
  /// The documented brand-impersonation example.
  static var brandImpersonationUnrelatedDomain: Self {
    Self(knownValid: "brand_impersonation_unrelated_domain")
  }
}

public extension StableContractValue where Kind == ProblemCodeKind {
  /// The submitted value is not a supported URL.
  static var invalidURL: Self {
    Self(knownValid: "invalid_url")
  }

  /// The operation cannot currently be accepted or represented.
  static var temporarilyUnavailable: Self {
    Self(knownValid: "temporarily_unavailable")
  }
}

public extension StableContractValue where Kind == ConfidenceCategoryKind {
  /// Low bounded confidence.
  static var low: Self {
    Self(knownValid: "low")
  }

  /// Medium bounded confidence.
  static var medium: Self {
    Self(knownValid: "medium")
  }

  /// High bounded confidence.
  static var high: Self {
    Self(knownValid: "high")
  }
}

public extension StableContractValue where Kind == EvaluatedScopeKind {
  /// The exact submitted URL was evaluated.
  static var exactURL: Self {
    Self(knownValid: "exact_url")
  }
}

/// A bounded dot-separated localization key whose segments use the stable-value grammar.
public struct LocalizationKey: RawRepresentable, Codable, Hashable, Sendable {
  /// The maximum encoded key length.
  public static let maximumUTF8ByteCount = 256

  /// The validated wire value.
  public let rawValue: String

  /// Creates a validated localization key.
  public init(validating rawValue: String) throws {
    guard rawValue.utf8.count <= Self.maximumUTF8ByteCount else {
      throw ContractValueError.tooLong
    }

    let segments = rawValue.split(separator: ".", omittingEmptySubsequences: false)
    guard segments.isEmpty == false else {
      throw ContractValueError.empty
    }

    for segment in segments {
      try StableContractValueValidator.validate(String(segment))
    }
    self.rawValue = rawValue
  }

  /// Creates a localization key when the raw value is valid.
  public init?(rawValue: String) {
    guard let value = try? Self(validating: rawValue) else {
      return nil
    }
    self = value
  }

  /// Decodes a key without echoing a rejected candidate in the error.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let candidate = try container.decode(String.self)
    do {
      try self.init(validating: candidate)
    } catch {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid localization key."
      )
    }
  }

  /// Encodes the exact validated key.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
