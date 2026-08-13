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

/// Distinguishes evaluated-scope values.
public enum EvaluatedScopeKind: StableContractValueKind {}

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
