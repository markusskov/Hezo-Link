import Darwin
import Foundation

/// The bounded outcome of local manual URL syntax validation.
///
/// This value is safe to render: neither case description exposes the associated submission.
public enum ManualURLInputValidation: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The exact submission passed this local syntax profile.
  case accepted(ValidatedManualURL)

  /// The submission failed with a finite, content-free problem.
  case rejected(ManualURLInputProblem)

  /// A bounded log-safe summary that omits the submission and all parsed components.
  public var description: String {
    switch self {
    case .accepted:
      "Manual URL validation accepted."
    case .rejected(let problem):
      "Manual URL validation rejected: \(problem.code.rawValue)."
    }
  }

  /// A bounded log-safe debug summary identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the bounded summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// A pure, offline validator for one deliberately submitted manual URL.
///
/// This is a conservative syntax preflight. It is not a provider canonicalizer, DNS or address
/// classifier, navigation capability, destination-safety result, or durable URL representation.
public struct ManualURLInputValidator: Sendable {
  /// The public syntax profile carried by every accepted value.
  public static let syntaxProfileVersion: UInt = 1

  /// The IANA Special-Use Domain Names registry revision pinned by profile 1.
  public static let specialUseDomainRegistryRevision = "2026-05-22"

  private enum SpecialUsePolicy: Sendable {
    case production
    case isolatedTestFixture
  }

  private static let supportedPorts: Set<UInt16> = [80, 443]

  // Pinned from the IANA Special-Use Domain Names registry last updated 2026-05-22. The IANA
  // designation applies to each listed name and all of its subdomains. The isolated fixture mode
  // below exempts only `.test`; it does not widen any other special-use name.
  static let specialUseDomainSuffixes = [
    "alt",
    "6tisch.arpa",
    "eap.arpa",
    "eap-noob.arpa",
    "home.arpa",
    "10.in-addr.arpa",
    "254.169.in-addr.arpa",
    "16.172.in-addr.arpa",
    "17.172.in-addr.arpa",
    "18.172.in-addr.arpa",
    "19.172.in-addr.arpa",
    "20.172.in-addr.arpa",
    "21.172.in-addr.arpa",
    "22.172.in-addr.arpa",
    "23.172.in-addr.arpa",
    "24.172.in-addr.arpa",
    "25.172.in-addr.arpa",
    "26.172.in-addr.arpa",
    "27.172.in-addr.arpa",
    "28.172.in-addr.arpa",
    "29.172.in-addr.arpa",
    "30.172.in-addr.arpa",
    "31.172.in-addr.arpa",
    "170.0.0.192.in-addr.arpa",
    "171.0.0.192.in-addr.arpa",
    "168.192.in-addr.arpa",
    "8.e.f.ip6.arpa",
    "9.e.f.ip6.arpa",
    "a.e.f.ip6.arpa",
    "b.e.f.ip6.arpa",
    "ipv4only.arpa",
    "resolver.arpa",
    "service.arpa",
    "example",
    "example.com",
    "example.net",
    "example.org",
    "invalid",
    "local",
    "localhost",
    "onion",
    "test",
  ]

  private let specialUsePolicy: SpecialUsePolicy

  /// Creates the production syntax preflight. Special-use fixture names are rejected.
  public init() {
    specialUsePolicy = .production
  }

  private init(specialUsePolicy: SpecialUsePolicy) {
    self.specialUsePolicy = specialUsePolicy
  }

  /// Creates the internal offline-fixture profile. Only `.test` names are exempted.
  static var isolatedTestFixture: Self {
    Self(specialUsePolicy: .isolatedTestFixture)
  }

  /// Validates an exact string after enforcing the UTF-8 size limit before all syntax work.
  public func validate(_ rawValue: String) -> ManualURLInputValidation {
    do {
      return validate(try SubmittedURL(rawValue: rawValue))
    } catch let problem as ManualURLInputProblem {
      return .rejected(problem)
    } catch {
      return .rejected(.invalidURL)
    }
  }

  /// Validates a previously bounded exact submission without performing I/O.
  public func validate(_ submittedURL: SubmittedURL) -> ManualURLInputValidation {
    guard let validated = validatedURL(from: submittedURL) else {
      return .rejected(problemForScheme(in: submittedURL.rawValue))
    }
    return .accepted(validated)
  }

  private func validatedURL(from submittedURL: SubmittedURL) -> ValidatedManualURL? {
    let rawValue = submittedURL.rawValue
    guard hasSafeRawCharacters(rawValue), hasValidPercentEscapes(rawValue) else {
      return nil
    }

    guard let schemeDelimiter = rawValue.firstIndex(of: ":") else {
      return nil
    }
    let rawScheme = String(rawValue[..<schemeDelimiter])
    guard isValidScheme(rawScheme), let scheme = WebScheme(rawValue: rawScheme.lowercased()) else {
      return nil
    }

    let afterScheme = rawValue.index(after: schemeDelimiter)
    guard rawValue[afterScheme...].hasPrefix("//") else {
      return nil
    }
    let authorityStart = rawValue.index(afterScheme, offsetBy: 2)
    let authorityEnd =
      rawValue[authorityStart...].firstIndex { character in
        character == "/" || character == "?" || character == "#"
      } ?? rawValue.endIndex
    let rawAuthority = String(rawValue[authorityStart..<authorityEnd])
    guard let authority = parseAuthority(rawAuthority) else {
      return nil
    }

    guard isHostAllowed(authority.asciiHost, isIPLiteral: authority.isIPLiteral) else {
      return nil
    }

    let suffix = String(rawValue[authorityEnd...])
    guard
      strictURLParses(
        scheme: scheme,
        authority: authority,
        suffix: suffix
      )
    else {
      return nil
    }

    let components = rawComponents(in: suffix)
    let effectivePort = authority.explicitPort ?? scheme.defaultPort
    return ValidatedManualURL(
      syntaxProfileVersion: Self.syntaxProfileVersion,
      submittedURL: submittedURL,
      scheme: scheme,
      asciiHost: authority.asciiHost,
      explicitPort: authority.explicitPort,
      effectivePort: effectivePort,
      portDisposition: Self.supportedPorts.contains(effectivePort) ? .supported : .unsupported,
      rawPercentEncodedPath: components.path,
      rawPercentEncodedQuery: components.query,
      rawPercentEncodedFragment: components.fragment
    )
  }

  private func problemForScheme(in rawValue: String) -> ManualURLInputProblem {
    guard hasSafeRawCharacters(rawValue), hasValidPercentEscapes(rawValue),
      let delimiter = rawValue.firstIndex(of: ":")
    else {
      return .invalidURL
    }

    let candidate = String(rawValue[..<delimiter])
    guard isValidScheme(candidate) else {
      return .invalidURL
    }
    return WebScheme(rawValue: candidate.lowercased()) == nil ? .unsupportedScheme : .invalidURL
  }

  private struct ParsedAuthority {
    let asciiHost: String
    let explicitPort: UInt16?
    let isIPLiteral: Bool

    var strictURLAuthority: String {
      let host = isIPLiteral && asciiHost.contains(":") ? "[\(asciiHost)]" : asciiHost
      if let explicitPort {
        return "\(host):\(explicitPort)"
      }
      return host
    }
  }

  private func parseAuthority(_ rawAuthority: String) -> ParsedAuthority? {
    guard rawAuthority.isEmpty == false, rawAuthority.contains("@") == false else {
      return nil
    }

    if rawAuthority.hasPrefix("[") {
      guard let closingBracket = rawAuthority.firstIndex(of: "]"),
        closingBracket != rawAuthority.startIndex
      else {
        return nil
      }
      let afterBracket = rawAuthority.index(after: closingBracket)
      let remainder = String(rawAuthority[afterBracket...])
      guard rawAuthority[afterBracket...].contains("[") == false,
        rawAuthority[afterBracket...].contains("]") == false,
        remainder.isEmpty || remainder.hasPrefix(":")
      else {
        return nil
      }

      let hostStart = rawAuthority.index(after: rawAuthority.startIndex)
      let rawHost = String(rawAuthority[hostStart..<closingBracket])
      guard rawHost.contains("%") == false,
        let asciiHost = normalizedHost(rawHost, isBracketedIPLiteral: true)
      else {
        return nil
      }
      let port = remainder.isEmpty ? nil : parsePort(String(remainder.dropFirst()))
      guard remainder.isEmpty || port != nil else {
        return nil
      }
      return ParsedAuthority(asciiHost: asciiHost, explicitPort: port, isIPLiteral: true)
    }

    guard rawAuthority.contains("[") == false, rawAuthority.contains("]") == false else {
      return nil
    }
    let colonCount = rawAuthority.reduce(into: 0) { count, character in
      if character == ":" {
        count += 1
      }
    }
    guard colonCount <= 1 else {
      return nil
    }

    let rawHost: String
    let explicitPort: UInt16?
    if let colon = rawAuthority.lastIndex(of: ":") {
      rawHost = String(rawAuthority[..<colon])
      explicitPort = parsePort(String(rawAuthority[rawAuthority.index(after: colon)...]))
      guard explicitPort != nil else {
        return nil
      }
    } else {
      rawHost = rawAuthority
      explicitPort = nil
    }

    guard rawHost.isEmpty == false, rawHost.contains("%") == false,
      rawHost.hasSuffix(".") == false,
      let asciiHost = normalizedHost(rawHost, isBracketedIPLiteral: false)
    else {
      return nil
    }

    if asciiHost.utf8.allSatisfy({ byte in (0x30...0x39).contains(byte) || byte == 0x2E }) {
      guard rawHost == asciiHost, isCanonicalIPv4(asciiHost) else {
        return nil
      }
      return ParsedAuthority(
        asciiHost: asciiHost,
        explicitPort: explicitPort,
        isIPLiteral: true
      )
    }

    guard resemblesAlternateIPv4(asciiHost) == false, isValidDNSHost(asciiHost) else {
      return nil
    }
    return ParsedAuthority(asciiHost: asciiHost, explicitPort: explicitPort, isIPLiteral: false)
  }

  private func normalizedHost(_ rawHost: String, isBracketedIPLiteral: Bool) -> String? {
    guard rawHost.precomposedStringWithCanonicalMapping.utf8.elementsEqual(rawHost.utf8),
      rawHost.precomposedStringWithCompatibilityMapping.utf8.elementsEqual(rawHost.utf8),
      rawHost.unicodeScalars.allSatisfy(Self.isAllowedRawHostScalar),
      rawHost.unicodeScalars.contains(where: Self.isUnicodeDotVariant) == false
    else {
      return nil
    }

    if isBracketedIPLiteral {
      return normalizedIPv6Host(rawHost)
    }

    guard let url = URL(string: "https://\(rawHost)"),
      URLComponents(url: url, resolvingAgainstBaseURL: false)?.host != nil,
      let host = url.host
    else {
      return nil
    }
    let normalized = host.lowercased()
    guard normalized.isEmpty == false,
      normalized.utf8.allSatisfy({ $0 < 0x80 }),
      normalized.contains(":") == false
    else {
      return nil
    }
    return normalized
  }

  private func normalizedIPv6Host(_ rawHost: String) -> String? {
    if rawHost.contains(".") {
      guard let finalColon = rawHost.lastIndex(of: ":"),
        isCanonicalIPv4(String(rawHost[rawHost.index(after: finalColon)...]))
      else {
        return nil
      }
    }

    var address = in6_addr()
    guard rawHost.withCString({ inet_pton(AF_INET6, $0, &address) }) == 1 else {
      return nil
    }

    let bytes = withUnsafeBytes(of: address) { Array($0) }
    let isIPv4Mapped =
      bytes[0..<10].allSatisfy { $0 == 0 }
      && bytes[10] == 0xFF && bytes[11] == 0xFF
    if isIPv4Mapped {
      return "\(bytes[12]).\(bytes[13]).\(bytes[14]).\(bytes[15])"
    }

    var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
    let rendered = withUnsafePointer(to: &address) { pointer in
      inet_ntop(AF_INET6, pointer, &buffer, socklen_t(INET6_ADDRSTRLEN))
    }
    guard rendered != nil else {
      return nil
    }
    let utf8 = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
    return String(decoding: utf8, as: UTF8.self).lowercased()
  }

  private func parsePort(_ rawPort: String) -> UInt16? {
    guard rawPort.isEmpty == false,
      rawPort.utf8.allSatisfy({ (0x30...0x39).contains($0) }),
      (rawPort.count == 1 || rawPort.first != "0"),
      let port = UInt16(rawPort),
      port > 0
    else {
      return nil
    }
    return port
  }

  private func isHostAllowed(_ host: String, isIPLiteral: Bool) -> Bool {
    guard isIPLiteral == false else {
      return true
    }
    if specialUsePolicy == .isolatedTestFixture, matchesDomain(host, suffix: "test") {
      return true
    }
    if Self.specialUseDomainSuffixes.contains(where: { matchesDomain(host, suffix: $0) }) {
      return false
    }
    if matchesDomain(host, suffix: "internal") || host == "metadata.google.internal" {
      return false
    }
    return true
  }

  private func matchesDomain(_ host: String, suffix: String) -> Bool {
    host == suffix || host.hasSuffix(".\(suffix)")
  }

  private func strictURLParses(
    scheme: WebScheme,
    authority: ParsedAuthority,
    suffix: String
  ) -> Bool {
    let candidate = "\(scheme.rawValue)://\(authority.strictURLAuthority)\(suffix)"
    guard let url = URL(string: candidate, encodingInvalidCharacters: false),
      url.scheme == scheme.rawValue,
      url.user == nil,
      url.password == nil,
      url.port == authority.explicitPort.map(Int.init),
      let parsedHost = url.host?.lowercased(),
      parsedHost == authority.asciiHost
    else {
      return false
    }
    return true
  }

  private func rawComponents(in suffix: String) -> (
    path: String, query: String?, fragment: String?
  ) {
    let fragmentDelimiter = suffix.firstIndex(of: "#")
    let beforeFragment = fragmentDelimiter.map { String(suffix[..<$0]) } ?? suffix
    let fragment = fragmentDelimiter.map { String(suffix[suffix.index(after: $0)...]) }
    let queryDelimiter = beforeFragment.firstIndex(of: "?")
    let path = queryDelimiter.map { String(beforeFragment[..<$0]) } ?? beforeFragment
    let query = queryDelimiter.map { String(beforeFragment[beforeFragment.index(after: $0)...]) }
    return (path, query, fragment)
  }

  private func hasSafeRawCharacters(_ value: String) -> Bool {
    value.isEmpty == false
      && value.contains("\\") == false
      && value.unicodeScalars.allSatisfy { scalar in
        CharacterSet.controlCharacters.contains(scalar) == false
          && CharacterSet.whitespacesAndNewlines.contains(scalar) == false
      }
  }

  private func hasValidPercentEscapes(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    var decodedBytes: [UInt8] = []
    decodedBytes.reserveCapacity(bytes.count)
    var index = bytes.startIndex
    while index < bytes.endIndex {
      guard bytes[index] == 0x25 else {
        decodedBytes.append(bytes[index])
        index += 1
        continue
      }
      guard index + 2 < bytes.endIndex,
        isASCIIHexDigit(bytes[index + 1]),
        isASCIIHexDigit(bytes[index + 2])
      else {
        return false
      }
      guard let decodedByte = decodedHexByte(bytes[index + 1], bytes[index + 2]) else {
        return false
      }
      decodedBytes.append(decodedByte)
      index += 3
    }
    guard let decoded = String(bytes: decodedBytes, encoding: .utf8) else {
      return false
    }
    return decoded.unicodeScalars.allSatisfy { scalar in
      CharacterSet.controlCharacters.contains(scalar) == false
        && CharacterSet.newlines.contains(scalar) == false
        && scalar.value != 0x5C
    }
  }

  private func isValidScheme(_ value: String) -> Bool {
    let bytes = value.utf8
    guard let first = bytes.first, isASCIIAlpha(first) else {
      return false
    }
    return bytes.dropFirst().allSatisfy { byte in
      isASCIIAlpha(byte) || (0x30...0x39).contains(byte) || byte == 0x2B || byte == 0x2D
        || byte == 0x2E
    }
  }

  private func isCanonicalIPv4(_ host: String) -> Bool {
    let components = host.split(separator: ".", omittingEmptySubsequences: false)
    guard components.count == 4 else {
      return false
    }
    return components.allSatisfy { component in
      guard component.isEmpty == false,
        component.utf8.allSatisfy({ (0x30...0x39).contains($0) }),
        (component.count == 1 || component.first != "0"),
        let value = UInt8(component)
      else {
        return false
      }
      return String(value) == component
    }
  }

  private func resemblesAlternateIPv4(_ host: String) -> Bool {
    let labels = host.split(separator: ".", omittingEmptySubsequences: false)
    guard labels.isEmpty == false else {
      return false
    }
    return labels.allSatisfy { label in
      let lowercased = label.lowercased()
      if lowercased.hasPrefix("0x") {
        let remainder = lowercased.dropFirst(2)
        return remainder.isEmpty == false && remainder.utf8.allSatisfy(isASCIIHexDigit)
      }
      return label.isEmpty == false
        && label.utf8.allSatisfy({ (0x30...0x39).contains($0) })
    }
  }

  private func isValidDNSHost(_ host: String) -> Bool {
    guard host.utf8.count <= 253 else {
      return false
    }
    let labels = host.split(separator: ".", omittingEmptySubsequences: false)
    guard labels.count >= 2 else {
      return false
    }
    return labels.allSatisfy { label in
      guard (1...63).contains(label.utf8.count),
        let first = label.utf8.first,
        let last = label.utf8.last,
        isASCIIAlphaNumeric(first),
        isASCIIAlphaNumeric(last)
      else {
        return false
      }
      return label.utf8.allSatisfy { byte in
        isASCIIAlphaNumeric(byte) || byte == 0x2D
      }
    }
  }

  private func isASCIIAlpha(_ byte: UInt8) -> Bool {
    (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
  }

  private func isASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
    isASCIIAlpha(byte) || (0x30...0x39).contains(byte)
  }

  private func isASCIIHexDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }

  private func decodedHexByte(_ high: UInt8, _ low: UInt8) -> UInt8? {
    guard let highValue = hexValue(high), let lowValue = hexValue(low) else {
      return nil
    }
    return (highValue << 4) | lowValue
  }

  private func hexValue(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x30...0x39:
      byte - 0x30
    case 0x41...0x46:
      byte - 0x41 + 10
    case 0x61...0x66:
      byte - 0x61 + 10
    default:
      nil
    }
  }

  private static func isUnicodeDotVariant(_ scalar: Unicode.Scalar) -> Bool {
    scalar.value == 0x3002 || scalar.value == 0xFF0E || scalar.value == 0xFF61
  }

  private static func isAllowedRawHostScalar(_ scalar: Unicode.Scalar) -> Bool {
    guard scalar.isASCII == false else {
      return true
    }
    guard scalar.properties.isDefaultIgnorableCodePoint == false else {
      return false
    }
    switch scalar.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
      .nonspacingMark, .spacingMark, .decimalNumber:
      return true
    default:
      return false
    }
  }
}
