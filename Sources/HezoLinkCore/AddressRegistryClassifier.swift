import Foundation

/// The IP family used by a pinned address-registry classification.
public enum AddressRegistryIPFamily: Equatable, Hashable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// A four-byte IPv4 address.
  case ipv4

  /// A sixteen-byte IPv6 address.
  case ipv6

  /// A bounded description that never includes an address.
  public var description: String {
    switch self {
    case .ipv4:
      "IPv4 address family."
    case .ipv6:
      "IPv6 address family."
    }
  }

  /// A bounded debug description that never includes an address.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the bounded family description.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// A registry-derived address category.
///
/// These categories are offline classification candidates. None is a permission, safety,
/// ownership, route availability, or reachability decision.
public enum AddressRegistryCategory: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The address matches a pinned IANA special-purpose prefix.
  case specialPurpose

  /// The address is in an allocated or legacy IPv4 `/8` after special-purpose overlays.
  case allocatedOrLegacyIPv4

  /// The address is in IANA's IPv6 Global Unicast allocation after special-purpose overlays.
  case globalUnicastIPv6

  /// The address matches an explicit IPv4 or IPv6 multicast prefix.
  case multicast

  /// The address is in a broader address-space region reserved or otherwise non-global by type.
  case reserved

  /// No pinned broader address-space record covers the address.
  case unallocated

  /// A bounded description that never includes an address or registry-provided text.
  public var description: String {
    switch self {
    case .specialPurpose:
      "Special-purpose address category."
    case .allocatedOrLegacyIPv4:
      "Allocated-or-legacy IPv4 candidate category."
    case .globalUnicastIPv6:
      "Global-unicast IPv6 candidate category."
    case .multicast:
      "Multicast address category."
    case .reserved:
      "Reserved address-space category."
    case .unallocated:
      "Unallocated address-space category."
    }
  }

  /// A bounded debug description that never includes an address or registry-provided text.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the bounded category description.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// Exact provenance for one pinned public registry or policy-overlay source.
public struct AddressRegistrySource: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The stable source identifier in the pinned profile.
  public let identifier: String

  /// The source's exact pinned update date or normative RFC section.
  public let updated: String

  /// The public source URL recorded by the pinned profile.
  public let publicURL: String

  fileprivate init(identifier: String, updated: String, publicURL: String) {
    self.identifier = identifier
    self.updated = updated
    self.publicURL = publicURL
  }

  /// A constant description that does not render source fields.
  public var description: String {
    "Pinned address-registry source."
  }

  /// A constant debug description that does not render source fields.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the constant summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// The most-specific pinned record responsible for an IP classification.
public struct AddressRegistryMatch: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The canonical network prefix from the deterministic projection.
  public let prefix: String

  /// The public registry designation or policy-overlay name.
  public let name: String

  /// Exact public provenance for the matched record.
  public let source: AddressRegistrySource

  fileprivate init(prefix: String, name: String, source: AddressRegistrySource) {
    self.prefix = prefix
    self.name = name
    self.source = source
  }

  /// A constant description that does not render a prefix or registry-provided text.
  public var description: String {
    "Pinned address-registry match."
  }

  /// A constant debug description that does not render a prefix or registry-provided text.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the constant summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// A bounded offline classification for an already validated IP literal.
public struct AddressRegistryIPClassification: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The validated literal's IP family.
  public let family: AddressRegistryIPFamily

  /// The category selected by the pinned profile.
  public let category: AddressRegistryCategory

  /// The exact immutable profile revision used for this result.
  public let sourceRevision: String

  /// The most-specific responsible record, or `nil` for an unallocated address.
  public let match: AddressRegistryMatch?

  fileprivate init(
    family: AddressRegistryIPFamily,
    category: AddressRegistryCategory,
    sourceRevision: String,
    match: AddressRegistryMatch?
  ) {
    self.family = family
    self.category = category
    self.sourceRevision = sourceRevision
    self.match = match
  }

  /// A constant description that never includes the address or matched record.
  public var description: String {
    "Pinned IP address classification."
  }

  /// A constant debug description that never includes the address or matched record.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the constant summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// The result of applying the pinned address profile to an already validated host.
public enum AddressRegistryClassification: Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// Domain names are outside the address classifier's responsibility.
  case notApplicable

  /// The validated host is an IP literal with a pinned offline classification.
  case ip(AddressRegistryIPClassification)

  /// A bounded description that never includes the classified host.
  public var description: String {
    switch self {
    case .notApplicable:
      "Address classification is not applicable to a domain name."
    case .ip:
      "An IP literal has a pinned address classification."
    }
  }

  /// A bounded debug description that never includes the classified host.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the bounded summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// A bounded, content-free failure while loading the pinned address profile.
public enum AddressRegistryClassifierError: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable, LocalizedError
{
  /// The exact bundled projection could not be read.
  case projectionUnavailable

  /// The bundled byte count or SHA-256 digest did not match the compiled constants.
  case projectionIntegrityMismatch

  /// The projection was not strict JSON with the frozen V1 shape.
  case malformedProjection

  /// Required source or record coverage was missing.
  case incompleteProjection

  /// Projection fields contradicted each other or the frozen profile.
  case inconsistentProjection

  /// A bounded description that never includes a file path, parser diagnostic, or record field.
  public var description: String {
    switch self {
    case .projectionUnavailable:
      "The pinned address profile is unavailable."
    case .projectionIntegrityMismatch:
      "The pinned address profile failed its integrity check."
    case .malformedProjection:
      "The pinned address profile is malformed."
    case .incompleteProjection:
      "The pinned address profile is incomplete."
    case .inconsistentProjection:
      "The pinned address profile is inconsistent."
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

  /// A reflection surface containing only the bounded description.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }
}

/// Integrity values supplied alongside an internal projection loader.
///
/// Tests can construct an expectation for a deterministic mutation without weakening production's
/// exact compiled byte-count and digest checks.
struct AddressRegistryProjectionExpectation: Equatable, Sendable {
  let byteCount: Int
  let sha256: String

  init(data: Data) {
    byteCount = data.count
    sha256 = AddressRegistrySHA256.hexDigest(data)
  }

  init(byteCount: Int, sha256: String) {
    self.byteCount = byteCount
    self.sha256 = sha256
  }
}

/// A pure, immutable classifier backed by a reviewed offline IANA address profile.
///
/// Construction verifies one exact bundled projection. Classification accepts only invariant-
/// preserving validated host values and performs no parsing, DNS, network, persistence, logging,
/// or policy enforcement. Candidate categories must still pass later environment and egress policy.
public struct AddressRegistryClassifier: Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The exact public profile revision carried by every IP result.
  public static let profileRevision = "iana-address-profile-v1"

  /// The exact SHA-256 digest of the bundled deterministic projection.
  public static let projectionSHA256 =
    "9697f3b6da69ec68fea355c7f6bb0ae95151125fedb8c363e72d1cd7844af0be"

  /// The exact bundled projection byte count.
  public static let projectionByteCount = 118_651

  private static let bundledExpectation = AddressRegistryProjectionExpectation(
    byteCount: projectionByteCount,
    sha256: projectionSHA256
  )

  private static let bundledDatabase:
    Result<AddressRegistryDatabase, AddressRegistryClassifierError> = {
      do {
        let data = try bundledProjectionData()
        return .success(try validatedDatabase(from: data, expectation: bundledExpectation))
      } catch let error as AddressRegistryClassifierError {
        return .failure(error)
      } catch {
        return .failure(.projectionUnavailable)
      }
    }()

  private let database: AddressRegistryDatabase

  /// Loads and verifies the exact bundled projection once per process.
  public init() throws {
    database = try Self.bundledDatabase.get()
  }

  /// Loads and verifies a deterministic injected projection without storing the loader.
  init(
    projectionLoader: () throws -> Data,
    expectation: AddressRegistryProjectionExpectation
  ) throws {
    let data: Data
    do {
      data = try projectionLoader()
    } catch {
      throw AddressRegistryClassifierError.projectionUnavailable
    }
    database = try Self.validatedDatabase(from: data, expectation: expectation)
  }

  /// Classifies an invariant-preserving validated host without reparsing its text spelling.
  public func classify(_ host: ValidatedURLHost) -> AddressRegistryClassification {
    switch host.kind {
    case .domainName:
      return .notApplicable
    case .ipv4Literal:
      guard let bytes = host.packedAddressBytes, bytes.count == 4 else {
        preconditionFailure("A validated IPv4 host violated its internal byte invariant.")
      }
      return .ip(classify(bytes: bytes, family: .ipv4))
    case .ipv6Literal:
      guard let bytes = host.packedAddressBytes, bytes.count == 16 else {
        preconditionFailure("A validated IPv6 host violated its internal byte invariant.")
      }
      return .ip(classify(bytes: bytes, family: .ipv6))
    }
  }

  /// Classifies the host of an already validated manual URL.
  public func classify(_ validatedURL: ValidatedManualURL) -> AddressRegistryClassification {
    classify(validatedURL.host)
  }

  /// A constant description that does not render loaded records or classified values.
  public var description: String {
    "Pinned offline address-registry classifier."
  }

  /// A constant debug description that does not render loaded records or classified values.
  public var debugDescription: String {
    description
  }

  /// A reflection surface containing only the constant summary.
  public var customMirror: Mirror {
    Mirror(self, children: ["summary": description])
  }

  private func classify(
    bytes: [UInt8],
    family: AddressRegistryIPFamily
  ) -> AddressRegistryIPClassification {
    let selectedRecord =
      database.longestMatch(for: bytes, family: family, layer: .specialPurpose)
      ?? database.longestMatch(for: bytes, family: family, layer: .multicastOverlay)
      ?? database.longestMatch(for: bytes, family: family, layer: .addressSpace)

    return AddressRegistryIPClassification(
      family: family,
      category: selectedRecord?.category ?? .unallocated,
      sourceRevision: Self.profileRevision,
      match: selectedRecord?.match
    )
  }
}

private enum AddressRegistryRecordLayer: Equatable, Sendable {
  case specialPurpose
  case multicastOverlay
  case addressSpace
}

private struct AddressRegistryRecord: Equatable, Sendable {
  let family: AddressRegistryIPFamily
  let layer: AddressRegistryRecordLayer
  let prefixLength: Int
  let networkBytes: [UInt8]
  let category: AddressRegistryCategory
  let match: AddressRegistryMatch

  func contains(_ addressBytes: [UInt8]) -> Bool {
    guard addressBytes.count == networkBytes.count else { return false }

    let wholeByteCount = prefixLength / 8
    if wholeByteCount > 0,
      addressBytes[..<wholeByteCount] != networkBytes[..<wholeByteCount]
    {
      return false
    }

    let remainingBitCount = prefixLength % 8
    guard remainingBitCount > 0 else { return true }
    let mask = UInt8.max << UInt8(8 - remainingBitCount)
    return addressBytes[wholeByteCount] & mask == networkBytes[wholeByteCount] & mask
  }
}

private struct AddressRegistryDatabase: Sendable {
  let records: [AddressRegistryRecord]

  func longestMatch(
    for bytes: [UInt8],
    family: AddressRegistryIPFamily,
    layer: AddressRegistryRecordLayer
  ) -> AddressRegistryRecord? {
    var selected: AddressRegistryRecord?

    for record in records
    where record.family == family && record.layer == layer && record.contains(bytes) {
      if record.prefixLength > (selected?.prefixLength ?? -1) {
        selected = record
      }
    }

    return selected
  }
}

private final class AddressRegistryResourceBundleToken {}

private extension AddressRegistryClassifier {
  static func bundledProjectionData() throws -> Data {
    #if SWIFT_PACKAGE
      let bundle = Bundle.module
    #else
      let bundle = Bundle(for: AddressRegistryResourceBundleToken.self)
    #endif

    guard
      let resourceURL = bundle.url(
        forResource: "iana-address-profile-v1",
        withExtension: "json",
        subdirectory: "AddressRegistry"
      )
    else {
      throw AddressRegistryClassifierError.projectionUnavailable
    }

    do {
      return try Data(contentsOf: resourceURL, options: [.mappedIfSafe])
    } catch {
      throw AddressRegistryClassifierError.projectionUnavailable
    }
  }

  static func validatedDatabase(
    from data: Data,
    expectation: AddressRegistryProjectionExpectation
  ) throws -> AddressRegistryDatabase {
    guard data.count == expectation.byteCount,
      AddressRegistrySHA256.hexDigest(data) == expectation.sha256
    else {
      throw AddressRegistryClassifierError.projectionIntegrityMismatch
    }

    do {
      try AddressRegistryStrictJSONValidator.validate(data)
    } catch {
      throw AddressRegistryClassifierError.malformedProjection
    }

    let projection: AddressRegistryProjection
    do {
      projection = try JSONDecoder().decode(AddressRegistryProjection.self, from: data)
    } catch {
      throw AddressRegistryClassifierError.malformedProjection
    }

    return try AddressRegistryProjectionValidator.validate(projection)
  }
}

private enum AddressRegistryStrictJSONFailure: Error {
  case invalidJSON
}

/// A bounded lexical preflight that rejects duplicate object keys before Foundation decoding.
///
/// `JSONDecoder` does not promise duplicate-key rejection. Decoding each key spelling as an
/// isolated JSON string ensures raw and escaped spellings of the same key compare identically.
private enum AddressRegistryStrictJSONValidator {
  private static let maximumDataByteCount = 256_000
  private static let maximumDepth = 32
  private static let maximumContainerElementCount = 1_024
  private static let maximumStringByteCount = 4_096

  static func validate(_ data: Data) throws {
    guard data.count <= maximumDataByteCount else {
      throw AddressRegistryStrictJSONFailure.invalidJSON
    }
    var scanner = Scanner(bytes: Array(data))
    try scanner.validate()
  }

  private struct Scanner {
    let bytes: [UInt8]
    var index = 0

    mutating func validate() throws {
      skipWhitespace()
      try parseValue(depth: 0)
      skipWhitespace()
      guard index == bytes.count else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
    }

    private mutating func parseValue(depth: Int) throws {
      guard index < bytes.count else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }

      switch bytes[index] {
      case 0x7B:
        try parseObject(depth: depth)
      case 0x5B:
        try parseArray(depth: depth)
      case 0x22:
        _ = try parseString(decode: false)
      case 0x74:
        try consumeLiteral([0x74, 0x72, 0x75, 0x65])
      case 0x66:
        try consumeLiteral([0x66, 0x61, 0x6C, 0x73, 0x65])
      case 0x6E:
        try consumeLiteral([0x6E, 0x75, 0x6C, 0x6C])
      case 0x2D, 0x30...0x39:
        try parseNumber()
      default:
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
    }

    private mutating func parseObject(depth: Int) throws {
      guard depth < AddressRegistryStrictJSONValidator.maximumDepth else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
      index += 1
      skipWhitespace()
      if consume(0x7D) { return }

      var keys = Set<String>()
      var memberCount = 0
      while true {
        memberCount += 1
        guard memberCount <= AddressRegistryStrictJSONValidator.maximumContainerElementCount,
          let key = try parseString(decode: true),
          keys.insert(key).inserted
        else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }

        skipWhitespace()
        guard consume(0x3A) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        skipWhitespace()
        try parseValue(depth: depth + 1)
        skipWhitespace()

        if consume(0x7D) { return }
        guard consume(0x2C) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        skipWhitespace()
      }
    }

    private mutating func parseArray(depth: Int) throws {
      guard depth < AddressRegistryStrictJSONValidator.maximumDepth else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
      index += 1
      skipWhitespace()
      if consume(0x5D) { return }

      var elementCount = 0
      while true {
        elementCount += 1
        guard elementCount <= AddressRegistryStrictJSONValidator.maximumContainerElementCount else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        try parseValue(depth: depth + 1)
        skipWhitespace()

        if consume(0x5D) { return }
        guard consume(0x2C) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        skipWhitespace()
      }
    }

    private mutating func parseString(decode: Bool) throws -> String? {
      guard consume(0x22) else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
      let encodedStart = index - 1
      var encodedByteCount = 1

      while index < bytes.count {
        encodedByteCount += 1
        guard encodedByteCount <= AddressRegistryStrictJSONValidator.maximumStringByteCount else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }

        let byte = bytes[index]
        index += 1
        switch byte {
        case 0x22:
          guard decode else { return nil }
          do {
            return try JSONDecoder().decode(
              String.self,
              from: Data(bytes[encodedStart..<index])
            )
          } catch {
            throw AddressRegistryStrictJSONFailure.invalidJSON
          }

        case 0x5C:
          guard index < bytes.count else {
            throw AddressRegistryStrictJSONFailure.invalidJSON
          }
          encodedByteCount += 1
          let escape = bytes[index]
          index += 1
          if escape == 0x75 {
            guard index + 4 <= bytes.count,
              bytes[index..<(index + 4)].allSatisfy(isHexDigit)
            else {
              throw AddressRegistryStrictJSONFailure.invalidJSON
            }
            index += 4
            encodedByteCount += 4
          } else {
            guard [0x22, 0x2F, 0x5C, 0x62, 0x66, 0x6E, 0x72, 0x74].contains(escape) else {
              throw AddressRegistryStrictJSONFailure.invalidJSON
            }
          }

        case 0x00...0x1F:
          throw AddressRegistryStrictJSONFailure.invalidJSON

        default:
          continue
        }
      }

      throw AddressRegistryStrictJSONFailure.invalidJSON
    }

    private mutating func parseNumber() throws {
      _ = consume(0x2D)
      guard index < bytes.count else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }

      if consume(0x30) {
        guard index == bytes.count || isDecimalDigit(bytes[index]) == false else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
      } else {
        guard index < bytes.count, (0x31...0x39).contains(bytes[index]) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        index += 1
        consumeDecimalDigits()
      }

      if consume(0x2E) {
        guard index < bytes.count, isDecimalDigit(bytes[index]) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        consumeDecimalDigits()
      }

      if index < bytes.count, bytes[index] == 0x65 || bytes[index] == 0x45 {
        index += 1
        if index < bytes.count, bytes[index] == 0x2B || bytes[index] == 0x2D {
          index += 1
        }
        guard index < bytes.count, isDecimalDigit(bytes[index]) else {
          throw AddressRegistryStrictJSONFailure.invalidJSON
        }
        consumeDecimalDigits()
      }
    }

    private mutating func consumeDecimalDigits() {
      while index < bytes.count, isDecimalDigit(bytes[index]) {
        index += 1
      }
    }

    private mutating func consumeLiteral(_ literal: [UInt8]) throws {
      guard index + literal.count <= bytes.count,
        Array(bytes[index..<(index + literal.count)]) == literal
      else {
        throw AddressRegistryStrictJSONFailure.invalidJSON
      }
      index += literal.count
    }

    private mutating func skipWhitespace() {
      while index < bytes.count, [0x09, 0x0A, 0x0D, 0x20].contains(bytes[index]) {
        index += 1
      }
    }

    private mutating func consume(_ byte: UInt8) -> Bool {
      guard index < bytes.count, bytes[index] == byte else { return false }
      index += 1
      return true
    }

    private func isDecimalDigit(_ byte: UInt8) -> Bool {
      (0x30...0x39).contains(byte)
    }

    private func isHexDigit(_ byte: UInt8) -> Bool {
      (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
        || (0x61...0x66).contains(byte)
    }
  }
}

private enum AddressRegistryProjectionFamily: String, Decodable, Equatable, Sendable {
  case ipv4
  case ipv6

  var publicValue: AddressRegistryIPFamily {
    switch self {
    case .ipv4:
      .ipv4
    case .ipv6:
      .ipv6
    }
  }

  var byteCount: Int {
    switch self {
    case .ipv4:
      4
    case .ipv6:
      16
    }
  }

  var maximumPrefixLength: Int {
    byteCount * 8
  }

  var sortOrder: Int {
    switch self {
    case .ipv4:
      0
    case .ipv6:
      1
    }
  }
}

private enum AddressRegistryProjectionSourceKind: String, Decodable, Equatable, Sendable {
  case specialPurpose = "special-purpose"
  case addressSpace = "address-space"
}

private enum AddressRegistryProjectionFlagValue: String, Decodable, Equatable, Sendable {
  case `true`
  case `false`
  case notApplicable = "not-applicable"
  case unspecified
}

private enum AddressRegistryProjectionDecodingFailure: Error {
  case invalidKeys
}

private struct AddressRegistryProjectionAnyKey: CodingKey {
  let stringValue: String
  let intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  init?(intValue: Int) {
    stringValue = String(intValue)
    self.intValue = intValue
  }
}

private func requireExactProjectionKeys<Key>(
  _ decoder: Decoder,
  _: Key.Type
) throws where Key: CodingKey & CaseIterable {
  let container = try decoder.container(keyedBy: AddressRegistryProjectionAnyKey.self)
  let actualKeys = container.allKeys.map(\.stringValue).sorted()
  let expectedKeys = Key.allCases.map(\.stringValue).sorted()
  guard actualKeys == expectedKeys else {
    throw AddressRegistryProjectionDecodingFailure.invalidKeys
  }
}

private struct AddressRegistryProjection: Decodable, Sendable {
  let schemaVersion: Int
  let profileID: String
  let profileVersion: String
  let projectionAlgorithmVersion: Int
  let purpose: String
  let sourceRegistries: [AddressRegistryProjectionSource]
  let policyOverlays: [AddressRegistryProjectionOverlay]
  let counts: AddressRegistryProjectionCounts
  let records: [AddressRegistryProjectionRecord]

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion
    case profileID = "profileId"
    case profileVersion
    case projectionAlgorithmVersion
    case purpose
    case sourceRegistries
    case policyOverlays
    case counts
    case records
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    profileID = try container.decode(String.self, forKey: .profileID)
    profileVersion = try container.decode(String.self, forKey: .profileVersion)
    projectionAlgorithmVersion = try container.decode(
      Int.self,
      forKey: .projectionAlgorithmVersion
    )
    purpose = try container.decode(String.self, forKey: .purpose)
    sourceRegistries = try container.decode(
      [AddressRegistryProjectionSource].self,
      forKey: .sourceRegistries
    )
    policyOverlays = try container.decode(
      [AddressRegistryProjectionOverlay].self,
      forKey: .policyOverlays
    )
    counts = try container.decode(AddressRegistryProjectionCounts.self, forKey: .counts)
    records = try container.decode([AddressRegistryProjectionRecord].self, forKey: .records)
  }
}

private struct AddressRegistryProjectionSource: Decodable, Equatable, Sendable {
  let id: String
  let family: AddressRegistryProjectionFamily
  let kind: AddressRegistryProjectionSourceKind
  let revision: String
  let sourceURL: String
  let snapshotPath: String
  let snapshotSHA256: String
  let sourceRecordCount: Int
  let projectedRecordCount: Int

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case family
    case kind
    case revision
    case sourceURL
    case snapshotPath
    case snapshotSHA256 = "snapshotSha256"
    case sourceRecordCount
    case projectedRecordCount
  }

  init(
    id: String,
    family: AddressRegistryProjectionFamily,
    kind: AddressRegistryProjectionSourceKind,
    revision: String,
    sourceURL: String,
    snapshotPath: String,
    snapshotSHA256: String,
    sourceRecordCount: Int,
    projectedRecordCount: Int
  ) {
    self.id = id
    self.family = family
    self.kind = kind
    self.revision = revision
    self.sourceURL = sourceURL
    self.snapshotPath = snapshotPath
    self.snapshotSHA256 = snapshotSHA256
    self.sourceRecordCount = sourceRecordCount
    self.projectedRecordCount = projectedRecordCount
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    family = try container.decode(AddressRegistryProjectionFamily.self, forKey: .family)
    kind = try container.decode(AddressRegistryProjectionSourceKind.self, forKey: .kind)
    revision = try container.decode(String.self, forKey: .revision)
    sourceURL = try container.decode(String.self, forKey: .sourceURL)
    snapshotPath = try container.decode(String.self, forKey: .snapshotPath)
    snapshotSHA256 = try container.decode(String.self, forKey: .snapshotSHA256)
    sourceRecordCount = try container.decode(Int.self, forKey: .sourceRecordCount)
    projectedRecordCount = try container.decode(Int.self, forKey: .projectedRecordCount)
  }
}

private struct AddressRegistryProjectionOverlay: Decodable, Equatable, Sendable {
  let id: String
  let family: AddressRegistryProjectionFamily
  let revision: String
  let sourceURL: String
  let prefix: String

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case family
    case revision
    case sourceURL
    case prefix
  }

  init(
    id: String,
    family: AddressRegistryProjectionFamily,
    revision: String,
    sourceURL: String,
    prefix: String
  ) {
    self.id = id
    self.family = family
    self.revision = revision
    self.sourceURL = sourceURL
    self.prefix = prefix
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    family = try container.decode(AddressRegistryProjectionFamily.self, forKey: .family)
    revision = try container.decode(String.self, forKey: .revision)
    sourceURL = try container.decode(String.self, forKey: .sourceURL)
    prefix = try container.decode(String.self, forKey: .prefix)
  }
}

private struct AddressRegistryProjectionCounts: Decodable, Equatable, Sendable {
  let sourceRegistryCount: Int
  let policyOverlayCount: Int
  let recordCount: Int
  let familyRecords: AddressRegistryProjectionFamilyCounts
  let registryRecords: [String: Int]

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case sourceRegistryCount
    case policyOverlayCount
    case recordCount
    case familyRecords
    case registryRecords
  }

  init(
    sourceRegistryCount: Int,
    policyOverlayCount: Int,
    recordCount: Int,
    familyRecords: AddressRegistryProjectionFamilyCounts,
    registryRecords: [String: Int]
  ) {
    self.sourceRegistryCount = sourceRegistryCount
    self.policyOverlayCount = policyOverlayCount
    self.recordCount = recordCount
    self.familyRecords = familyRecords
    self.registryRecords = registryRecords
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    sourceRegistryCount = try container.decode(Int.self, forKey: .sourceRegistryCount)
    policyOverlayCount = try container.decode(Int.self, forKey: .policyOverlayCount)
    recordCount = try container.decode(Int.self, forKey: .recordCount)
    familyRecords = try container.decode(
      AddressRegistryProjectionFamilyCounts.self,
      forKey: .familyRecords
    )
    registryRecords = try container.decode([String: Int].self, forKey: .registryRecords)
  }
}

private struct AddressRegistryProjectionFamilyCounts: Decodable, Equatable, Sendable {
  let ipv4: Int
  let ipv6: Int

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case ipv4
    case ipv6
  }

  init(ipv4: Int, ipv6: Int) {
    self.ipv4 = ipv4
    self.ipv6 = ipv6
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    ipv4 = try container.decode(Int.self, forKey: .ipv4)
    ipv6 = try container.decode(Int.self, forKey: .ipv6)
  }
}

private struct AddressRegistryProjectionFlags: Decodable, Equatable, Sendable {
  let source: AddressRegistryProjectionFlagValue
  let destination: AddressRegistryProjectionFlagValue
  let forwardable: AddressRegistryProjectionFlagValue
  let globallyReachable: AddressRegistryProjectionFlagValue
  let reservedByProtocol: AddressRegistryProjectionFlagValue

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case source
    case destination
    case forwardable
    case globallyReachable
    case reservedByProtocol
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    source = try container.decode(AddressRegistryProjectionFlagValue.self, forKey: .source)
    destination = try container.decode(
      AddressRegistryProjectionFlagValue.self,
      forKey: .destination
    )
    forwardable = try container.decode(
      AddressRegistryProjectionFlagValue.self,
      forKey: .forwardable
    )
    globallyReachable = try container.decode(
      AddressRegistryProjectionFlagValue.self,
      forKey: .globallyReachable
    )
    reservedByProtocol = try container.decode(
      AddressRegistryProjectionFlagValue.self,
      forKey: .reservedByProtocol
    )
  }
}

private struct AddressRegistryProjectionRecord: Decodable, Equatable, Sendable {
  let registryID: String
  let sourceRecordIndex: Int?
  let family: AddressRegistryProjectionFamily
  let prefixLength: Int
  let networkBytesHex: String
  let name: String
  let status: String?
  let allocationDate: String?
  let terminationDate: String?
  let flags: AddressRegistryProjectionFlags?

  private enum CodingKeys: String, CodingKey, CaseIterable {
    case registryID = "registryId"
    case sourceRecordIndex
    case family
    case prefixLength
    case networkBytesHex
    case name
    case status
    case allocationDate
    case terminationDate
    case flags
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try requireExactProjectionKeys(decoder, CodingKeys.self)
    registryID = try container.decode(String.self, forKey: .registryID)
    sourceRecordIndex = try container.decodeIfPresent(Int.self, forKey: .sourceRecordIndex)
    family = try container.decode(AddressRegistryProjectionFamily.self, forKey: .family)
    prefixLength = try container.decode(Int.self, forKey: .prefixLength)
    networkBytesHex = try container.decode(String.self, forKey: .networkBytesHex)
    name = try container.decode(String.self, forKey: .name)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    allocationDate = try container.decodeIfPresent(String.self, forKey: .allocationDate)
    terminationDate = try container.decodeIfPresent(String.self, forKey: .terminationDate)
    flags = try container.decodeIfPresent(AddressRegistryProjectionFlags.self, forKey: .flags)
  }
}

private enum AddressRegistryProjectionContract {
  static let schemaVersion = 1
  static let profileID = "iana-address-profile-v1"
  static let profileVersion = "iana-2025-10-23-hezo-overlay-v1"
  static let projectionAlgorithmVersion = 1
  static let purpose = "offline-address-classification"

  static let sources = [
    AddressRegistryProjectionSource(
      id: "iana-ipv4-special-purpose",
      family: .ipv4,
      kind: .specialPurpose,
      revision: "2025-10-09",
      sourceURL:
        "https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xml",
      snapshotPath: "upstream/iana/iana-ipv4-special-registry-2025-10-09.xml",
      snapshotSHA256: "cf24e11f41b7d42c68debe2d18b97cac815084ec413ebb3b244f704028a16f20",
      sourceRecordCount: 25,
      projectedRecordCount: 26
    ),
    AddressRegistryProjectionSource(
      id: "iana-ipv6-special-purpose",
      family: .ipv6,
      kind: .specialPurpose,
      revision: "2025-10-09",
      sourceURL:
        "https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xml",
      snapshotPath: "upstream/iana/iana-ipv6-special-registry-2025-10-09.xml",
      snapshotSHA256: "c17f4380ba84fb2160dae82ebfd8bd155a5853cfab624ed3a9fd251638a8be02",
      sourceRecordCount: 25,
      projectedRecordCount: 25
    ),
    AddressRegistryProjectionSource(
      id: "iana-ipv4-address-space",
      family: .ipv4,
      kind: .addressSpace,
      revision: "2025-10-10",
      sourceURL: "https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xml",
      snapshotPath: "upstream/iana/ipv4-address-space-2025-10-10.xml",
      snapshotSHA256: "8ca3774374c81e4a673bb12d0eb415e7ac9970c6f5a6ceb14106de64b2cb3dcd",
      sourceRecordCount: 256,
      projectedRecordCount: 256
    ),
    AddressRegistryProjectionSource(
      id: "iana-ipv6-address-space",
      family: .ipv6,
      kind: .addressSpace,
      revision: "2025-10-23",
      sourceURL: "https://www.iana.org/assignments/ipv6-address-space/ipv6-address-space.xml",
      snapshotPath: "upstream/iana/ipv6-address-space-2025-10-23.xml",
      snapshotSHA256: "15481d1e549b481f3bd0321c5cd2c0327a00cbd3d5a6fc35fc7b53b51e70b1cb",
      sourceRecordCount: 20,
      projectedRecordCount: 20
    ),
  ]

  static let overlays = [
    AddressRegistryProjectionOverlay(
      id: "hezo-ipv4-multicast-overlay",
      family: .ipv4,
      revision: "RFC 1112, Section 4",
      sourceURL: "https://www.rfc-editor.org/rfc/rfc1112.html#section-4",
      prefix: "224.0.0.0/4"
    ),
    AddressRegistryProjectionOverlay(
      id: "hezo-ipv6-multicast-overlay",
      family: .ipv6,
      revision: "RFC 4291, Section 2.7",
      sourceURL: "https://www.rfc-editor.org/rfc/rfc4291.html#section-2.7",
      prefix: "ff00::/8"
    ),
  ]

  static let counts = AddressRegistryProjectionCounts(
    sourceRegistryCount: 4,
    policyOverlayCount: 2,
    recordCount: 329,
    familyRecords: AddressRegistryProjectionFamilyCounts(ipv4: 283, ipv6: 46),
    registryRecords: [
      "iana-ipv4-special-purpose": 26,
      "iana-ipv6-special-purpose": 25,
      "iana-ipv4-address-space": 256,
      "iana-ipv6-address-space": 20,
      "hezo-ipv4-multicast-overlay": 1,
      "hezo-ipv6-multicast-overlay": 1,
    ]
  )
}

private enum AddressRegistryProjectionValidator {
  static func validate(_ projection: AddressRegistryProjection) throws
    -> AddressRegistryDatabase
  {
    try validateHeader(projection)
    try validateCoverageDeclarations(projection)

    let sourceByID = Dictionary(
      uniqueKeysWithValues: projection.sourceRegistries.map { ($0.id, $0) }
    )
    let overlayByID = Dictionary(
      uniqueKeysWithValues: projection.policyOverlays.map { ($0.id, $0) }
    )
    let publicSourceByID = Dictionary(
      uniqueKeysWithValues:
        projection.sourceRegistries.map {
          (
            $0.id,
            AddressRegistrySource(
              identifier: $0.id,
              updated: $0.revision,
              publicURL: $0.sourceURL
            )
          )
        }
        + projection.policyOverlays.map {
          (
            $0.id,
            AddressRegistrySource(
              identifier: $0.id,
              updated: $0.revision,
              publicURL: $0.sourceURL
            )
          )
        }
    )

    var actualRegistryCounts: [String: Int] = [:]
    var actualIPv4Count = 0
    var actualIPv6Count = 0
    var sourceIndexCounts: [String: [Int: Int]] = [:]
    var recordIdentities = Set<String>()
    var records: [AddressRegistryRecord] = []
    records.reserveCapacity(AddressRegistryProjectionContract.counts.recordCount)

    for (index, projectedRecord) in projection.records.enumerated() {
      if index > 0,
        projectionRecordPrecedes(projectedRecord, projection.records[index - 1])
      {
        throw AddressRegistryClassifierError.inconsistentProjection
      }

      let identity = [
        projectedRecord.registryID,
        projectedRecord.family.rawValue,
        String(projectedRecord.prefixLength),
        projectedRecord.networkBytesHex,
      ].joined(separator: "|")
      guard recordIdentities.insert(identity).inserted else {
        throw AddressRegistryClassifierError.inconsistentProjection
      }

      actualRegistryCounts[projectedRecord.registryID, default: 0] += 1
      switch projectedRecord.family {
      case .ipv4:
        actualIPv4Count += 1
      case .ipv6:
        actualIPv6Count += 1
      }

      if let sourceRecordIndex = projectedRecord.sourceRecordIndex {
        sourceIndexCounts[projectedRecord.registryID, default: [:]][
          sourceRecordIndex,
          default: 0
        ] += 1
      }

      records.append(
        try validatedRecord(
          projectedRecord,
          source: sourceByID[projectedRecord.registryID],
          overlay: overlayByID[projectedRecord.registryID],
          publicSource: publicSourceByID[projectedRecord.registryID]
        )
      )
    }

    guard actualRegistryCounts == AddressRegistryProjectionContract.counts.registryRecords,
      actualIPv4Count == AddressRegistryProjectionContract.counts.familyRecords.ipv4,
      actualIPv6Count == AddressRegistryProjectionContract.counts.familyRecords.ipv6
    else {
      throw AddressRegistryClassifierError.incompleteProjection
    }

    for source in projection.sourceRegistries {
      var expectedIndexCounts = Dictionary(
        uniqueKeysWithValues: (0..<source.sourceRecordCount).map { ($0, 1) }
      )
      if source.id == "iana-ipv4-special-purpose" {
        expectedIndexCounts[12] = 2
      }
      guard sourceIndexCounts[source.id] == expectedIndexCounts else {
        throw AddressRegistryClassifierError.incompleteProjection
      }
    }

    try validateAddressSpacePartition(records, family: .ipv4, byteCount: 4)
    try validateAddressSpacePartition(records, family: .ipv6, byteCount: 16)

    return AddressRegistryDatabase(records: records)
  }

  private static func validateAddressSpacePartition(
    _ records: [AddressRegistryRecord],
    family: AddressRegistryIPFamily,
    byteCount: Int
  ) throws {
    let addressSpaceRecords =
      records
      .filter { $0.family == family && $0.layer == .addressSpace }
      .sorted { lhs, rhs in
        lhs.networkBytes.lexicographicallyPrecedes(rhs.networkBytes)
      }
    var expectedStart: [UInt8]? = Array(repeating: 0, count: byteCount)

    for record in addressSpaceRecords {
      guard let currentExpectedStart = expectedStart else {
        throw AddressRegistryClassifierError.inconsistentProjection
      }
      guard record.networkBytes == currentExpectedStart else {
        if record.networkBytes.lexicographicallyPrecedes(currentExpectedStart) {
          throw AddressRegistryClassifierError.inconsistentProjection
        }
        throw AddressRegistryClassifierError.incompleteProjection
      }
      expectedStart = firstAddressAfterPrefix(
        record.networkBytes,
        prefixLength: record.prefixLength
      )
    }

    guard expectedStart == nil else {
      throw AddressRegistryClassifierError.incompleteProjection
    }
  }

  private static func firstAddressAfterPrefix(
    _ networkBytes: [UInt8],
    prefixLength: Int
  ) -> [UInt8]? {
    var lastAddress = networkBytes
    let wholeByteCount = prefixLength / 8
    let remainingBitCount = prefixLength % 8

    if remainingBitCount > 0 {
      lastAddress[wholeByteCount] |= UInt8.max >> UInt8(remainingBitCount)
    }
    let trailingStart = wholeByteCount + (remainingBitCount > 0 ? 1 : 0)
    if trailingStart < lastAddress.count {
      for index in trailingStart..<lastAddress.count {
        lastAddress[index] = .max
      }
    }

    for index in lastAddress.indices.reversed() {
      if lastAddress[index] == .max {
        lastAddress[index] = 0
      } else {
        lastAddress[index] += 1
        return lastAddress
      }
    }
    return nil
  }

  private static func validateHeader(_ projection: AddressRegistryProjection) throws {
    guard projection.schemaVersion == AddressRegistryProjectionContract.schemaVersion,
      projection.profileID == AddressRegistryProjectionContract.profileID,
      projection.profileVersion == AddressRegistryProjectionContract.profileVersion,
      projection.projectionAlgorithmVersion
        == AddressRegistryProjectionContract.projectionAlgorithmVersion,
      projection.purpose == AddressRegistryProjectionContract.purpose
    else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }

    guard projection.sourceRegistries.count >= AddressRegistryProjectionContract.sources.count,
      projection.policyOverlays.count >= AddressRegistryProjectionContract.overlays.count
    else {
      throw AddressRegistryClassifierError.incompleteProjection
    }

    guard projection.sourceRegistries == AddressRegistryProjectionContract.sources,
      projection.policyOverlays == AddressRegistryProjectionContract.overlays
    else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }
  }

  private static func validateCoverageDeclarations(
    _ projection: AddressRegistryProjection
  ) throws {
    guard projection.records.count >= AddressRegistryProjectionContract.counts.recordCount,
      projection.counts.recordCount >= AddressRegistryProjectionContract.counts.recordCount
    else {
      throw AddressRegistryClassifierError.incompleteProjection
    }

    guard projection.counts == AddressRegistryProjectionContract.counts,
      projection.records.count == AddressRegistryProjectionContract.counts.recordCount
    else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }
  }

  private static func validatedRecord(
    _ record: AddressRegistryProjectionRecord,
    source: AddressRegistryProjectionSource?,
    overlay: AddressRegistryProjectionOverlay?,
    publicSource: AddressRegistrySource?
  ) throws -> AddressRegistryRecord {
    guard (source == nil) != (overlay == nil), let publicSource else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }

    guard (1...256).contains(record.name.utf8.count),
      record.name.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value != 0x7F }),
      (0...record.family.maximumPrefixLength).contains(record.prefixLength),
      let networkBytes = decodeLowercaseHex(record.networkBytesHex),
      networkBytes.count == record.family.byteCount,
      isCanonicalNetwork(networkBytes, prefixLength: record.prefixLength),
      isValidRegistryMonth(record.allocationDate),
      isValidRegistryMonth(record.terminationDate)
    else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }

    let prefix = renderPrefix(
      family: record.family,
      networkBytes: networkBytes,
      prefixLength: record.prefixLength
    )

    let layer: AddressRegistryRecordLayer
    let category: AddressRegistryCategory

    if let source {
      guard source.family == record.family,
        let sourceRecordIndex = record.sourceRecordIndex,
        (0..<source.sourceRecordCount).contains(sourceRecordIndex)
      else {
        throw AddressRegistryClassifierError.inconsistentProjection
      }

      switch source.kind {
      case .specialPurpose:
        guard record.flags != nil, record.status == nil else {
          throw AddressRegistryClassifierError.inconsistentProjection
        }
        layer = .specialPurpose
        category = .specialPurpose

      case .addressSpace:
        guard record.flags == nil else {
          throw AddressRegistryClassifierError.inconsistentProjection
        }
        layer = .addressSpace
        category = try addressSpaceCategory(for: record, source: source)
      }
    } else if let overlay {
      guard overlay.family == record.family,
        overlay.prefix == prefix,
        record.sourceRecordIndex == nil,
        record.name == "Multicast",
        record.status == "POLICY-OVERLAY",
        record.allocationDate == nil,
        record.terminationDate == nil,
        record.flags == nil
      else {
        throw AddressRegistryClassifierError.inconsistentProjection
      }
      layer = .multicastOverlay
      category = .multicast
    } else {
      throw AddressRegistryClassifierError.inconsistentProjection
    }

    return AddressRegistryRecord(
      family: record.family.publicValue,
      layer: layer,
      prefixLength: record.prefixLength,
      networkBytes: networkBytes,
      category: category,
      match: AddressRegistryMatch(prefix: prefix, name: record.name, source: publicSource)
    )
  }

  private static func addressSpaceCategory(
    for record: AddressRegistryProjectionRecord,
    source: AddressRegistryProjectionSource
  ) throws -> AddressRegistryCategory {
    switch source.family {
    case .ipv4:
      switch record.status {
      case "ALLOCATED", "LEGACY":
        return .allocatedOrLegacyIPv4
      case "RESERVED":
        return .reserved
      default:
        throw AddressRegistryClassifierError.inconsistentProjection
      }

    case .ipv6:
      guard record.status == nil else {
        throw AddressRegistryClassifierError.inconsistentProjection
      }
      switch record.name {
      case "Global Unicast":
        return .globalUnicastIPv6
      case "Multicast":
        return .multicast
      case "Reserved by IETF", "Unique Local Unicast", "Link-Scoped Unicast":
        return .reserved
      default:
        throw AddressRegistryClassifierError.inconsistentProjection
      }
    }
  }

  private static func decodeLowercaseHex(_ value: String) -> [UInt8]? {
    guard value.utf8.count.isMultiple(of: 2), value.isEmpty == false else { return nil }
    let scalars = Array(value.utf8)
    var bytes: [UInt8] = []
    bytes.reserveCapacity(scalars.count / 2)

    for index in stride(from: 0, to: scalars.count, by: 2) {
      guard let high = lowercaseHexValue(scalars[index]),
        let low = lowercaseHexValue(scalars[index + 1])
      else {
        return nil
      }
      bytes.append((high << 4) | low)
    }

    return bytes
  }

  private static func lowercaseHexValue(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x30...0x39:
      byte - 0x30
    case 0x61...0x66:
      byte - 0x61 + 10
    default:
      nil
    }
  }

  private static func isCanonicalNetwork(_ bytes: [UInt8], prefixLength: Int) -> Bool {
    let wholeByteCount = prefixLength / 8
    let remainingBitCount = prefixLength % 8

    if remainingBitCount > 0 {
      let hostMask = UInt8.max >> UInt8(remainingBitCount)
      guard bytes[wholeByteCount] & hostMask == 0 else { return false }
    }

    let trailingStart = wholeByteCount + (remainingBitCount > 0 ? 1 : 0)
    return bytes[trailingStart...].allSatisfy { $0 == 0 }
  }

  private static func isValidRegistryMonth(_ value: String?) -> Bool {
    guard let value else { return true }
    let bytes = Array(value.utf8)
    guard bytes.count == 7, bytes[4] == 0x2D else { return false }
    guard
      bytes.enumerated().allSatisfy({ index, byte in
        index == 4 || (0x30...0x39).contains(byte)
      })
    else {
      return false
    }

    guard let year = Int(value.prefix(4)), year >= 1900,
      let month = Int(value.suffix(2)), (1...12).contains(month)
    else {
      return false
    }
    return true
  }

  private static func renderPrefix(
    family: AddressRegistryProjectionFamily,
    networkBytes: [UInt8],
    prefixLength: Int
  ) -> String {
    let address: String
    switch family {
    case .ipv4:
      address = networkBytes.map(String.init).joined(separator: ".")
    case .ipv6:
      address = renderIPv6(networkBytes)
    }
    return "\(address)/\(prefixLength)"
  }

  private static func renderIPv6(_ bytes: [UInt8]) -> String {
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
    if prefix.isEmpty, suffix.isEmpty { return "::" }
    if prefix.isEmpty { return "::\(suffix)" }
    if suffix.isEmpty { return "\(prefix)::" }
    return "\(prefix)::\(suffix)"
  }

  private static func projectionRecordPrecedes(
    _ lhs: AddressRegistryProjectionRecord,
    _ rhs: AddressRegistryProjectionRecord
  ) -> Bool {
    if lhs.family.sortOrder != rhs.family.sortOrder {
      return lhs.family.sortOrder < rhs.family.sortOrder
    }
    if lhs.networkBytesHex != rhs.networkBytesHex {
      return lhs.networkBytesHex < rhs.networkBytesHex
    }
    if lhs.prefixLength != rhs.prefixLength {
      return lhs.prefixLength > rhs.prefixLength
    }
    if lhs.registryID != rhs.registryID {
      return lhs.registryID < rhs.registryID
    }

    let lhsIndex = lhs.sourceRecordIndex ?? -1
    let rhsIndex = rhs.sourceRecordIndex ?? -1
    if lhsIndex != rhsIndex {
      return lhsIndex < rhsIndex
    }
    return lhs.name < rhs.name
  }
}

private enum AddressRegistrySHA256 {
  private static let initialState: [UInt32] = [
    0x6A09_E667, 0xBB67_AE85, 0x3C6E_F372, 0xA54F_F53A,
    0x510E_527F, 0x9B05_688C, 0x1F83_D9AB, 0x5BE0_CD19,
  ]

  private static let roundConstants: [UInt32] = [
    0x428A_2F98, 0x7137_4491, 0xB5C0_FBCF, 0xE9B5_DBA5,
    0x3956_C25B, 0x59F1_11F1, 0x923F_82A4, 0xAB1C_5ED5,
    0xD807_AA98, 0x1283_5B01, 0x2431_85BE, 0x550C_7DC3,
    0x72BE_5D74, 0x80DE_B1FE, 0x9BDC_06A7, 0xC19B_F174,
    0xE49B_69C1, 0xEFBE_4786, 0x0FC1_9DC6, 0x240C_A1CC,
    0x2DE9_2C6F, 0x4A74_84AA, 0x5CB0_A9DC, 0x76F9_88DA,
    0x983E_5152, 0xA831_C66D, 0xB003_27C8, 0xBF59_7FC7,
    0xC6E0_0BF3, 0xD5A7_9147, 0x06CA_6351, 0x1429_2967,
    0x27B7_0A85, 0x2E1B_2138, 0x4D2C_6DFC, 0x5338_0D13,
    0x650A_7354, 0x766A_0ABB, 0x81C2_C92E, 0x9272_2C85,
    0xA2BF_E8A1, 0xA81A_664B, 0xC24B_8B70, 0xC76C_51A3,
    0xD192_E819, 0xD699_0624, 0xF40E_3585, 0x106A_A070,
    0x19A4_C116, 0x1E37_6C08, 0x2748_774C, 0x34B0_BCB5,
    0x391C_0CB3, 0x4ED8_AA4A, 0x5B9C_CA4F, 0x682E_6FF3,
    0x748F_82EE, 0x78A5_636F, 0x84C8_7814, 0x8CC7_0208,
    0x90BE_FFFA, 0xA450_6CEB, 0xBEF9_A3F7, 0xC671_78F2,
  ]

  static func hexDigest(_ data: Data) -> String {
    digest(data).map { String(format: "%02x", $0) }.joined()
  }

  private static func digest(_ data: Data) -> [UInt8] {
    var message = Array(data)
    let bitLength = UInt64(message.count) * 8
    message.append(0x80)
    while message.count % 64 != 56 {
      message.append(0)
    }
    message.append(contentsOf: withUnsafeBytes(of: bitLength.bigEndian, Array.init))

    var state = initialState
    var schedule = [UInt32](repeating: 0, count: 64)

    for chunkStart in stride(from: 0, to: message.count, by: 64) {
      for index in 0..<16 {
        let offset = chunkStart + (index * 4)
        schedule[index] =
          (UInt32(message[offset]) << 24)
          | (UInt32(message[offset + 1]) << 16)
          | (UInt32(message[offset + 2]) << 8)
          | UInt32(message[offset + 3])
      }

      for index in 16..<64 {
        let value15 = schedule[index - 15]
        let value2 = schedule[index - 2]
        let smallSigma0 =
          value15.rotatedRight(by: 7) ^ value15.rotatedRight(by: 18) ^ (value15 >> 3)
        let smallSigma1 =
          value2.rotatedRight(by: 17) ^ value2.rotatedRight(by: 19) ^ (value2 >> 10)
        schedule[index] =
          schedule[index - 16] &+ smallSigma0 &+ schedule[index - 7] &+ smallSigma1
      }

      var a = state[0]
      var b = state[1]
      var c = state[2]
      var d = state[3]
      var e = state[4]
      var f = state[5]
      var g = state[6]
      var h = state[7]

      for index in 0..<64 {
        let bigSigma1 = e.rotatedRight(by: 6) ^ e.rotatedRight(by: 11) ^ e.rotatedRight(by: 25)
        let choose = (e & f) ^ ((~e) & g)
        let temporary1 = h &+ bigSigma1 &+ choose &+ roundConstants[index] &+ schedule[index]
        let bigSigma0 = a.rotatedRight(by: 2) ^ a.rotatedRight(by: 13) ^ a.rotatedRight(by: 22)
        let majority = (a & b) ^ (a & c) ^ (b & c)
        let temporary2 = bigSigma0 &+ majority

        h = g
        g = f
        f = e
        e = d &+ temporary1
        d = c
        c = b
        b = a
        a = temporary1 &+ temporary2
      }

      state[0] &+= a
      state[1] &+= b
      state[2] &+= c
      state[3] &+= d
      state[4] &+= e
      state[5] &+= f
      state[6] &+= g
      state[7] &+= h
    }

    return state.flatMap { word in
      let bigEndianWord = word.bigEndian
      return withUnsafeBytes(of: bigEndianWord, Array.init)
    }
  }
}

private extension UInt32 {
  func rotatedRight(by amount: UInt32) -> UInt32 {
    (self >> amount) | (self << (32 - amount))
  }
}
