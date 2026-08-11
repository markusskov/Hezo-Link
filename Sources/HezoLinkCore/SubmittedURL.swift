/// A bounded, sensitive URL exactly as deliberately submitted by the user.
///
/// The value is not trimmed, decoded, or normalized. Callers may use `rawValue` only at an
/// approved transient-analysis boundary; ordinary descriptions and debug output are always
/// redacted.
public struct SubmittedURL: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The maximum accepted size before any URL parsing takes place.
  public static let maximumUTF8ByteCount = 8 * 1_024

  /// The exact submitted value, including original case, escapes, query, and fragment.
  public let rawValue: String

  /// Creates a sensitive submission after enforcing the pre-parse byte limit.
  /// - Parameter rawValue: The exact deliberate submission.
  /// - Throws: `ManualURLInputProblem.urlTooLong` when the UTF-8 representation exceeds 8 KiB.
  public init(rawValue: String) throws {
    guard rawValue.utf8.count <= Self.maximumUTF8ByteCount else {
      throw ManualURLInputProblem.urlTooLong
    }
    self.rawValue = rawValue
  }

  /// Creates a sensitive submission after enforcing the pre-parse byte limit.
  /// - Parameter rawValue: The exact deliberate submission.
  /// - Throws: `ManualURLInputProblem.urlTooLong` when the UTF-8 representation exceeds 8 KiB.
  public init(validating rawValue: String) throws {
    try self.init(rawValue: rawValue)
  }

  /// A constant log-safe description that never includes submitted content.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes submitted content.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing only the constant replacement.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }
}
