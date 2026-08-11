import CryptoKit
import Foundation

/// The public-suffix-list section that supplied the prevailing rule.
public enum PublicSuffixRuleSection: CaseIterable, Equatable, Sendable {
  /// A rule maintained in the ICANN section of the pinned list.
  case icann

  /// A rule maintained in the PRIVATE section of the pinned list.
  case privateDomain

  /// The official implicit `*` rule used when no listed rule matches.
  case implicitDefault
}

/// A classified domain host under one pinned public-suffix-list revision.
///
/// This is a naming-boundary result only. It is not evidence of domain validity, ownership,
/// organization, reachability, trust, or safety.
public struct RegistrableDomainResult: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The lowercase ASCII public suffix selected by the prevailing rule.
  public let publicSuffixASCII: String

  /// The lowercase ASCII registrable domain, or `nil` when the host is itself a public suffix.
  public let registrableDomainASCII: String?

  /// The section that supplied the prevailing rule.
  public let section: PublicSuffixRuleSection

  /// The immutable upstream revision used for this classification.
  public let listRevision: String

  init(
    publicSuffixASCII: String,
    registrableDomainASCII: String?,
    section: PublicSuffixRuleSection,
    listRevision: String
  ) {
    self.publicSuffixASCII = publicSuffixASCII
    self.registrableDomainASCII = registrableDomainASCII
    self.section = section
    self.listRevision = listRevision
  }

  /// A constant log-safe description that never includes a host or suffix.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes a host or suffix.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing only the constant replacement.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }
}

/// The bounded outcome of registrable-domain classification.
public enum RegistrableDomainClassification: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// A domain name was classified under the pinned list.
  case classified(RegistrableDomainResult)

  /// The validated host is an IP literal, so public-suffix rules do not apply.
  case notApplicable

  /// A constant log-safe description that never includes a host or suffix.
  public var description: String {
    LogSafeURLRedactor.replacement
  }

  /// A constant log-safe debug description that never includes a host or suffix.
  public var debugDescription: String {
    LogSafeURLRedactor.replacement
  }

  /// A reflection surface containing only the constant replacement.
  public var customMirror: Mirror {
    Mirror(self, children: ["value": LogSafeURLRedactor.replacement])
  }
}

/// A bounded, content-free failure produced while loading the pinned list.
public enum RegistrableDomainClassifierError: Error, Equatable, Sendable,
  CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, LocalizedError
{
  /// The exact bundled snapshot could not be located or read.
  case resourceUnavailable

  /// The loaded bytes did not match and parse as the pinned snapshot.
  case invalidSnapshot

  /// A bounded description that never includes a path, rule, host, or underlying diagnostic.
  public var description: String {
    switch self {
    case .resourceUnavailable:
      "The bundled public-suffix snapshot is unavailable."
    case .invalidSnapshot:
      "The bundled public-suffix snapshot is invalid."
    }
  }

  /// A bounded debug description identical to `description`.
  public var debugDescription: String {
    description
  }

  /// A bounded localized description identical to `description`.
  public var errorDescription: String? {
    description
  }

  /// A reflection surface containing only the bounded error description.
  public var customMirror: Mirror {
    Mirror(self, children: ["problem": description])
  }
}

/// A pure classifier backed by one exact, bundled ICANN and PRIVATE public-suffix snapshot.
///
/// Initialization performs local bundle I/O and validates the immutable snapshot. Classification
/// thereafter is deterministic and performs no network, DNS, persistence, or other I/O.
public struct RegistrableDomainClassifier: Sendable {
  /// The upstream commit represented by every result.
  public static let listRevision = "e1b8015c3b2f0f4f8c18659c2480fc1a22c07b20"

  static let snapshotVersion = "2026-07-25_14-20-03_UTC"

  private static let resourceBaseName = "hezolink-public-suffix-list-e1b8015c"
  private static let resourceExtension = "dat"
  private static let resourceSubdirectory = "PublicSuffix"
  private static let expectedSnapshotByteCount = 332_855
  private static let expectedSnapshotSHA256 =
    "084a5674d77c1d14900b16da5fc8afee9765af2f00a638552a8c7aa18f44ae81"

  private let rules: RuleSet

  /// Loads and validates the exact bundled list.
  /// - Throws: A bounded `RegistrableDomainClassifierError` when the resource is unavailable or
  ///   its bytes, identity markers, section structure, or rules are invalid.
  public init() throws {
    try self.init(loadSnapshot: Self.bundledSnapshotData)
  }

  /// Classifies the domain host of an already validated manual URL.
  ///
  /// IP literals return `.notApplicable`. The result is a naming decomposition only and does not
  /// assert validity, ownership, organization, reachability, trust, or safety.
  public func classify(_ validatedURL: ValidatedManualURL) -> RegistrableDomainClassification {
    guard validatedURL.hostKind == .domainName else {
      return .notApplicable
    }
    return classifyCanonicalASCIIHost(validatedURL.asciiHost)
  }

  /// Loads bytes through an injected local loader for deterministic failure tests.
  init(loadSnapshot: @Sendable () throws -> Data) throws {
    let data: Data
    do {
      data = try loadSnapshot()
    } catch {
      throw RegistrableDomainClassifierError.resourceUnavailable
    }

    guard Self.hasPinnedDigest(data) else {
      throw RegistrableDomainClassifierError.invalidSnapshot
    }

    do {
      rules = try RuleSet(snapshotData: data)
    } catch {
      throw RegistrableDomainClassifierError.invalidSnapshot
    }
  }

  /// Returns the same package bytes consumed by the production initializer.
  static func bundledSnapshotDataForTesting() throws -> Data {
    try bundledSnapshotData()
  }

  /// Exercises the real matcher for an already canonical lowercase ASCII domain host.
  func classifyASCIIHostForTesting(_ asciiHost: String) -> RegistrableDomainClassification {
    classifyCanonicalASCIIHost(asciiHost)
  }

  private func classifyCanonicalASCIIHost(_ asciiHost: String)
    -> RegistrableDomainClassification
  {
    guard Self.isCanonicalASCIIHost(asciiHost) else {
      return .notApplicable
    }

    let labels = asciiHost.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    let match = rules.prevailingMatch(for: labels)
    let suffixStart = labels.count - match.publicSuffixLabelCount
    let publicSuffix = labels[suffixStart...].joined(separator: ".")
    let registrableDomain: String?
    if suffixStart > 0 {
      registrableDomain = labels[(suffixStart - 1)...].joined(separator: ".")
    } else {
      registrableDomain = nil
    }

    return .classified(
      RegistrableDomainResult(
        publicSuffixASCII: publicSuffix,
        registrableDomainASCII: registrableDomain,
        section: match.section,
        listRevision: Self.listRevision
      )
    )
  }

  private static func bundledSnapshotData() throws -> Data {
    guard let resourceURL = bundledSnapshotURL() else {
      throw RegistrableDomainClassifierError.resourceUnavailable
    }
    do {
      return try Data(contentsOf: resourceURL, options: .mappedIfSafe)
    } catch {
      throw RegistrableDomainClassifierError.resourceUnavailable
    }
  }

  private static func bundledSnapshotURL() -> URL? {
    #if SWIFT_PACKAGE
      let bundles = [Bundle.module]
    #else
      let bundles = [Bundle(for: RegistrableDomainBundleToken.self), Bundle.main]
    #endif

    for bundle in bundles {
      if let nested = bundle.url(
        forResource: resourceBaseName,
        withExtension: resourceExtension,
        subdirectory: resourceSubdirectory
      ) {
        return nested
      }
      if let flat = bundle.url(
        forResource: resourceBaseName,
        withExtension: resourceExtension
      ) {
        return flat
      }
    }
    return nil
  }

  private static func hasPinnedDigest(_ data: Data) -> Bool {
    guard data.count == expectedSnapshotByteCount else {
      return false
    }
    let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    return digest == expectedSnapshotSHA256
  }

  fileprivate static func isCanonicalASCIIHost(_ host: String) -> Bool {
    guard host.isEmpty == false,
      host.utf8.count <= 253,
      host == host.lowercased(),
      host.utf8.allSatisfy({ $0 < 0x80 })
    else {
      return false
    }

    let labels = host.split(separator: ".", omittingEmptySubsequences: false)
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

  private static func isASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x61...0x7A).contains(byte)
  }
}

private final class RegistrableDomainBundleToken {}

private struct RuleSet: Sendable {
  private static let versionLine = "// VERSION: \(RegistrableDomainClassifier.snapshotVersion)"
  private static let commitLine = "// COMMIT: \(RegistrableDomainClassifier.listRevision)"
  private static let beginICANN = "// ===BEGIN ICANN DOMAINS==="
  private static let endICANN = "// ===END ICANN DOMAINS==="
  private static let beginPrivate = "// ===BEGIN PRIVATE DOMAINS==="
  private static let endPrivate = "// ===END PRIVATE DOMAINS==="

  private let exactRules: [String: PublicSuffixRuleSection]
  private let wildcardRules: [String: PublicSuffixRuleSection]
  private let exceptionRules: [String: PublicSuffixRuleSection]

  init(snapshotData: Data) throws {
    guard snapshotData.last == 0x0A,
      snapshotData.contains(0x00) == false,
      snapshotData.contains(0x0D) == false,
      let snapshot = String(data: snapshotData, encoding: .utf8)
    else {
      throw SnapshotParseError.invalid
    }

    var state = ParseState.preamble
    var sawVersion = false
    var sawCommit = false
    var exact: [String: PublicSuffixRuleSection] = [:]
    var wildcard: [String: PublicSuffixRuleSection] = [:]
    var exception: [String: PublicSuffixRuleSection] = [:]

    for lineSlice in snapshot.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = String(lineSlice)

      switch line {
      case Self.versionLine:
        guard state == .preamble, sawVersion == false else {
          throw SnapshotParseError.invalid
        }
        sawVersion = true
        continue
      case Self.commitLine:
        guard state == .preamble, sawCommit == false else {
          throw SnapshotParseError.invalid
        }
        sawCommit = true
        continue
      case Self.beginICANN:
        guard state == .preamble, sawVersion, sawCommit else {
          throw SnapshotParseError.invalid
        }
        state = .icann
        continue
      case Self.endICANN:
        guard state == .icann else {
          throw SnapshotParseError.invalid
        }
        state = .betweenSections
        continue
      case Self.beginPrivate:
        guard state == .betweenSections else {
          throw SnapshotParseError.invalid
        }
        state = .privateDomains
        continue
      case Self.endPrivate:
        guard state == .privateDomains else {
          throw SnapshotParseError.invalid
        }
        state = .complete
        continue
      default:
        break
      }

      if line.hasPrefix("// VERSION:") || line.hasPrefix("// COMMIT:") {
        throw SnapshotParseError.invalid
      }
      if line.isEmpty || line.hasPrefix("//") {
        continue
      }

      let section: PublicSuffixRuleSection
      switch state {
      case .icann:
        section = .icann
      case .privateDomains:
        section = .privateDomain
      case .preamble, .betweenSections, .complete:
        throw SnapshotParseError.invalid
      }

      let parsedRule = try Self.parseRule(line, section: section)
      switch parsedRule.kind {
      case .exact:
        guard exact.updateValue(parsedRule.section, forKey: parsedRule.asciiBody) == nil else {
          throw SnapshotParseError.invalid
        }
      case .wildcard:
        guard wildcard.updateValue(parsedRule.section, forKey: parsedRule.asciiBody) == nil else {
          throw SnapshotParseError.invalid
        }
      case .exception:
        guard exception.updateValue(parsedRule.section, forKey: parsedRule.asciiBody) == nil else {
          throw SnapshotParseError.invalid
        }
      }
    }

    guard state == .complete,
      sawVersion,
      sawCommit,
      exact.isEmpty == false,
      wildcard.isEmpty == false,
      exception.isEmpty == false,
      exact.values.contains(.icann),
      exact.values.contains(.privateDomain)
    else {
      throw SnapshotParseError.invalid
    }

    exactRules = exact
    wildcardRules = wildcard
    exceptionRules = exception
  }

  func prevailingMatch(for labels: [String]) -> PrevailingMatch {
    var longestException: PrevailingMatch?
    var longestListedRule: PrevailingMatch?

    for index in labels.indices {
      let candidate = labels[index...].joined(separator: ".")
      let candidateLabelCount = labels.count - index

      if let section = exceptionRules[candidate] {
        let match = PrevailingMatch(
          publicSuffixLabelCount: candidateLabelCount - 1,
          matchedRuleLabelCount: candidateLabelCount,
          section: section,
          precedence: .exception
        )
        longestException = Self.longer(match, than: longestException)
      }

      if let section = exactRules[candidate] {
        let match = PrevailingMatch(
          publicSuffixLabelCount: candidateLabelCount,
          matchedRuleLabelCount: candidateLabelCount,
          section: section,
          precedence: .exact
        )
        longestListedRule = Self.longer(match, than: longestListedRule)
      }

      if index > labels.startIndex, let section = wildcardRules[candidate] {
        let match = PrevailingMatch(
          publicSuffixLabelCount: candidateLabelCount + 1,
          matchedRuleLabelCount: candidateLabelCount + 1,
          section: section,
          precedence: .wildcard
        )
        longestListedRule = Self.longer(match, than: longestListedRule)
      }
    }

    if let longestException {
      return longestException
    }
    if let longestListedRule {
      return longestListedRule
    }
    return PrevailingMatch(
      publicSuffixLabelCount: 1,
      matchedRuleLabelCount: 1,
      section: .implicitDefault,
      precedence: .implicitDefault
    )
  }

  private static func parseRule(
    _ line: String,
    section: PublicSuffixRuleSection
  ) throws -> ParsedRule {
    guard line == line.trimmingCharacters(in: .whitespacesAndNewlines) else {
      throw SnapshotParseError.invalid
    }

    let kind: RuleKind
    let rawBody: String
    if line.hasPrefix("!") {
      kind = .exception
      rawBody = String(line.dropFirst())
    } else if line.hasPrefix("*.") {
      kind = .wildcard
      rawBody = String(line.dropFirst(2))
    } else {
      kind = .exact
      rawBody = line
    }

    guard rawBody.isEmpty == false,
      rawBody.contains("!") == false,
      rawBody.contains("*") == false,
      rawBody.hasPrefix(".") == false,
      rawBody.hasSuffix(".") == false,
      let asciiBody = ManualURLInputValidator.normalizedDomainNameASCII(rawBody),
      RegistrableDomainClassifier.isCanonicalASCIIHost(asciiBody)
    else {
      throw SnapshotParseError.invalid
    }

    if kind == .exception,
      asciiBody.split(separator: ".", omittingEmptySubsequences: false).count < 2
    {
      throw SnapshotParseError.invalid
    }

    return ParsedRule(kind: kind, asciiBody: asciiBody, section: section)
  }

  private static func longer(_ candidate: PrevailingMatch, than current: PrevailingMatch?)
    -> PrevailingMatch
  {
    guard let current else {
      return candidate
    }
    if candidate.matchedRuleLabelCount != current.matchedRuleLabelCount {
      return candidate.matchedRuleLabelCount > current.matchedRuleLabelCount ? candidate : current
    }
    return candidate.precedence.rawValue > current.precedence.rawValue ? candidate : current
  }
}

private enum ParseState: Equatable {
  case preamble
  case icann
  case betweenSections
  case privateDomains
  case complete
}

private enum RuleKind: Equatable {
  case exact
  case wildcard
  case exception
}

private struct ParsedRule {
  let kind: RuleKind
  let asciiBody: String
  let section: PublicSuffixRuleSection
}

private struct PrevailingMatch {
  enum Precedence: Int {
    case implicitDefault
    case wildcard
    case exact
    case exception
  }

  let publicSuffixLabelCount: Int
  let matchedRuleLabelCount: Int
  let section: PublicSuffixRuleSection
  let precedence: Precedence
}

private enum SnapshotParseError: Error {
  case invalid
}
