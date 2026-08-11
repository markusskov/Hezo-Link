/// An accepted web scheme under the local manual-input syntax profile.
public enum WebScheme: String, CaseIterable, Equatable, Sendable {
  /// Unencrypted HTTP syntax. Later destination and transport policy remains separate.
  case http

  /// HTTPS syntax. Acceptance here is not a safety or reachability claim.
  case https

  /// The scheme-default effective port.
  public var defaultPort: UInt16 {
    switch self {
    case .http:
      80
    case .https:
      443
    }
  }
}

/// Whether a parsed port is in the current conservative manual-analysis allowlist.
public enum PortDisposition: String, CaseIterable, Equatable, Sendable {
  /// The effective port is currently supported.
  case supported

  /// The URL is syntactically valid, but the effective port is not currently supported.
  case unsupported
}

/// A syntax-validated, transient decomposition of one exact manual URL submission.
///
/// This is not a navigation capability, destination-eligibility decision, durable sanitized URL,
/// or provider/enforcement canonical form. It performs no DNS or network work.
public struct ValidatedManualURL: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The syntax/preflight profile that produced this value.
  public let syntaxProfileVersion: UInt

  /// The original exact sensitive submission.
  public let submittedURL: SubmittedURL

  /// The normalized HTTP(S) scheme.
  public let scheme: WebScheme

  /// The lowercase ASCII IDN form or validated ASCII IP literal, without IPv6 brackets.
  public let asciiHost: String

  /// The explicitly supplied numeric port, or `nil` when the scheme default applies.
  public let explicitPort: UInt16?

  /// The explicit port or the scheme-default port when none was supplied.
  public let effectivePort: UInt16

  /// Whether the effective port is in the current `{80, 443}` allowlist.
  public let portDisposition: PortDisposition

  /// The raw percent-encoded path spelling retained for transient analysis.
  public let rawPercentEncodedPath: String

  /// The raw percent-encoded query spelling, including order and duplicate keys but not `?`.
  public let rawPercentEncodedQuery: String?

  /// The raw percent-encoded fragment spelling but not `#`.
  public let rawPercentEncodedFragment: String?

  init(
    syntaxProfileVersion: UInt,
    submittedURL: SubmittedURL,
    scheme: WebScheme,
    asciiHost: String,
    explicitPort: UInt16?,
    effectivePort: UInt16,
    portDisposition: PortDisposition,
    rawPercentEncodedPath: String,
    rawPercentEncodedQuery: String?,
    rawPercentEncodedFragment: String?
  ) {
    self.syntaxProfileVersion = syntaxProfileVersion
    self.submittedURL = submittedURL
    self.scheme = scheme
    self.asciiHost = asciiHost
    self.explicitPort = explicitPort
    self.effectivePort = effectivePort
    self.portDisposition = portDisposition
    self.rawPercentEncodedPath = rawPercentEncodedPath
    self.rawPercentEncodedQuery = rawPercentEncodedQuery
    self.rawPercentEncodedFragment = rawPercentEncodedFragment
  }

  /// A constant log-safe description that never includes URL components.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes URL components.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing only the constant replacement.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }
}
