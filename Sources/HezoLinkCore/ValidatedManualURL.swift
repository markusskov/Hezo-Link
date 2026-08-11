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

/// A normalized host produced by manual URL validation.
///
/// The value preserves the relationship between an IP literal's canonical ASCII spelling and its
/// packed address bytes. It is not a DNS result, destination-eligibility decision, or safety claim.
public struct ValidatedURLHost: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The normalized host category.
  public enum Kind: CaseIterable, Equatable, Sendable {
    /// A lowercase ASCII domain name, including an IDN's ASCII form.
    case domainName

    /// A canonical dotted-decimal IPv4 literal.
    case ipv4Literal

    /// A canonical RFC 5952 IPv6 literal without brackets.
    case ipv6Literal
  }

  /// The lowercase ASCII domain name or canonical IP literal, without IPv6 brackets.
  public let asciiValue: String

  /// Whether `asciiValue` is a domain name, IPv4 literal, or IPv6 literal.
  public let kind: Kind

  /// The four IPv4 or sixteen IPv6 network-order bytes, or `nil` for a domain name.
  let packedAddressBytes: [UInt8]?

  init?(domainNameASCIIValue asciiValue: String) {
    let labels = asciiValue.split(separator: ".", omittingEmptySubsequences: false)
    guard asciiValue.utf8.count <= 253,
      labels.count >= 2,
      labels.allSatisfy(Self.isValidDomainLabel),
      let finalLabel = labels.last,
      Self.isIPv4CandidateFinalLabel(finalLabel) == false
    else {
      return nil
    }

    self.asciiValue = asciiValue
    kind = .domainName
    packedAddressBytes = nil
  }

  init?(ipv4PackedAddressBytes: [UInt8]) {
    guard ipv4PackedAddressBytes.count == 4 else {
      return nil
    }

    asciiValue = ipv4PackedAddressBytes.map(String.init).joined(separator: ".")
    kind = .ipv4Literal
    packedAddressBytes = ipv4PackedAddressBytes
  }

  init?(ipv6PackedAddressBytes: [UInt8]) {
    guard ipv6PackedAddressBytes.count == 16 else {
      return nil
    }

    let isIPv4Mapped =
      ipv6PackedAddressBytes[0..<10].allSatisfy { $0 == 0 }
      && ipv6PackedAddressBytes[10] == 0xFF && ipv6PackedAddressBytes[11] == 0xFF
    if isIPv4Mapped {
      guard
        let ipv4Host = Self(
          ipv4PackedAddressBytes: Array(ipv6PackedAddressBytes[12...15])
        )
      else {
        return nil
      }
      self = ipv4Host
      return
    }

    asciiValue = Self.renderRFC5952IPv6(ipv6PackedAddressBytes)
    kind = .ipv6Literal
    packedAddressBytes = ipv6PackedAddressBytes
  }

  /// A constant log-safe description that never includes the host or address bytes.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes the host or address bytes.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing only the constant replacement.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }

  private static func isValidDomainLabel(_ label: Substring) -> Bool {
    let bytes = Array(label.utf8)
    guard (1...63).contains(bytes.count),
      let first = bytes.first,
      let last = bytes.last,
      isLowercaseASCIIAlphaNumeric(first),
      isLowercaseASCIIAlphaNumeric(last),
      bytes.allSatisfy({ isLowercaseASCIIAlphaNumeric($0) || $0 == 0x2D })
    else {
      return false
    }

    guard bytes.count >= 4, bytes[2] == 0x2D, bytes[3] == 0x2D else {
      return true
    }
    return bytes.count > 4
      && bytes[0] == 0x78
      && bytes[1] == 0x6E
      && bytes[4] != 0x2D
  }

  private static func isIPv4CandidateFinalLabel(_ label: Substring) -> Bool {
    let bytes = Array(label.utf8)
    return bytes.allSatisfy { (0x30...0x39).contains($0) }
      || (bytes.count >= 2 && bytes[0] == 0x30 && bytes[1] == 0x78)
  }

  private static func isLowercaseASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
    (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
  }

  private static func renderRFC5952IPv6(_ bytes: [UInt8]) -> String {
    let words = stride(from: 0, to: bytes.count, by: 2).map { index in
      (UInt16(bytes[index]) << 8) | UInt16(bytes[index + 1])
    }

    var bestStart: Int?
    var bestLength = 0
    var index = 0
    while index < words.count {
      guard words[index] == 0 else {
        index += 1
        continue
      }
      let runStart = index
      while index < words.count, words[index] == 0 {
        index += 1
      }
      let runLength = index - runStart
      if runLength >= 2, runLength > bestLength {
        bestStart = runStart
        bestLength = runLength
      }
    }

    guard let bestStart else {
      return words.map { String($0, radix: 16) }.joined(separator: ":")
    }
    let prefix = words[..<bestStart].map { String($0, radix: 16) }.joined(separator: ":")
    let suffixStart = bestStart + bestLength
    let suffix = words[suffixStart...].map { String($0, radix: 16) }.joined(separator: ":")
    if prefix.isEmpty, suffix.isEmpty {
      return "::"
    }
    if prefix.isEmpty {
      return "::\(suffix)"
    }
    if suffix.isEmpty {
      return "\(prefix)::"
    }
    return "\(prefix)::\(suffix)"
  }
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

  /// The normalized domain name or IP literal.
  public let host: ValidatedURLHost

  /// The lowercase ASCII IDN form or validated ASCII IP literal, without IPv6 brackets.
  public var asciiHost: String {
    host.asciiValue
  }

  /// Whether `asciiHost` is a domain name, IPv4 literal, or IPv6 literal.
  public var hostKind: ValidatedURLHost.Kind {
    host.kind
  }

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
    host: ValidatedURLHost,
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
    self.host = host
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
