/// Constant replacement for URL-bearing values at ordinary logging boundaries.
///
/// This utility does not create a durable sanitized URL and makes no privacy-retention or
/// provider-canonicalization claim.
public enum LogSafeURLRedactor {
  /// The one bounded replacement used for every URL-bearing value.
  public static let replacement = "<redacted-url>"

  /// Replaces any untrusted URL string without inspecting or copying it into the result.
  /// - Parameter value: A URL-bearing value. Its contents are intentionally ignored.
  /// - Returns: `replacement` for every input.
  public static func redact(_ value: String) -> String {
    _ = value
    return replacement
  }

  /// Replaces a sensitive exact submission with the constant placeholder.
  /// - Parameter value: A sensitive submitted URL. Its contents are intentionally ignored.
  /// - Returns: `replacement` for every input.
  public static func redact(_ value: SubmittedURL) -> String {
    _ = value
    return replacement
  }

  /// Replaces a validated transient URL with the constant placeholder.
  /// - Parameter value: A validated transient URL. Its contents are intentionally ignored.
  /// - Returns: `replacement` for every input.
  public static func redact(_ value: ValidatedManualURL) -> String {
    _ = value
    return replacement
  }
}
