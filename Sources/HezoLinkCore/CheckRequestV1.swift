import Foundation

/// A bounded failure produced while constructing a V1 check request.
///
/// Cases intentionally carry no submitted content, so ordinary error rendering cannot expose a
/// URL or other attacker-controlled value.
public enum CheckRequestContractError: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, LocalizedError
{
  /// The completion-wait hint is outside the nonnegative signed 32-bit range.
  case invalidWaitBudget

  /// A bounded, content-free description of the contract failure.
  public var description: String {
    "The check wait budget is outside the contract range."
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

/// The strict encoder-only V1 request for one deliberate manual URL check.
///
/// The validated submission remains private and transient. Encoding is the only public boundary
/// that reveals the exact submitted URL; descriptions, debug output, and reflection are redacted.
public struct CheckRequestV1: Encodable, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The frozen check-request wire schema version.
  public static let schemaVersion = 1

  /// The only analysis profile supported by this V1 request.
  public static let analysisProfile = "standard"

  /// The frozen verdict-reason schema version requested by this client.
  public static let reasonSchemaVersion = 1

  /// The largest completion-wait hint representable by the public contract.
  public static let maximumWaitBudgetMilliseconds = Int(Int32.max)

  /// The requested completion-wait hint in milliseconds.
  public let waitBudgetMilliseconds: Int

  private let submittedURL: SubmittedURL

  private enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case url
    case analysisProfile = "analysis_profile"
    case waitBudgetMilliseconds = "wait_budget_ms"
    case reasonSchemaVersion = "reason_schema_version"
  }

  /// Creates a request from an already validated exact submission and a bounded wait hint.
  /// - Parameters:
  ///   - validatedURL: An accepted local manual-URL value whose exact submission will be encoded.
  ///   - waitBudgetMilliseconds: A nonnegative signed 32-bit completion-wait hint.
  /// - Throws: `CheckRequestContractError.invalidWaitBudget` when the hint is out of range.
  public init(
    validatedURL: ValidatedManualURL,
    waitBudgetMilliseconds: Int
  ) throws {
    guard (0...Self.maximumWaitBudgetMilliseconds).contains(waitBudgetMilliseconds) else {
      throw CheckRequestContractError.invalidWaitBudget
    }

    submittedURL = validatedURL.submittedURL
    self.waitBudgetMilliseconds = waitBudgetMilliseconds
  }

  /// Encodes exactly the five frozen V1 request members.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(Self.schemaVersion, forKey: .schemaVersion)
    try container.encode(submittedURL.rawValue, forKey: .url)
    try container.encode(Self.analysisProfile, forKey: .analysisProfile)
    try container.encode(waitBudgetMilliseconds, forKey: .waitBudgetMilliseconds)
    try container.encode(Self.reasonSchemaVersion, forKey: .reasonSchemaVersion)
  }

  /// A constant log-safe description that never includes submitted content.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes submitted content.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing exactly one constant, non-sensitive child.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }
}
