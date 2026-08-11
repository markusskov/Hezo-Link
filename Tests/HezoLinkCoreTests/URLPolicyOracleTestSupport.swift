import CoreFoundation
import Foundation

enum URLPolicyOracleTestError: Error {
  case invalidFixture
  case unreadableFixture
}

let urlPolicyOracleRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

// This evaluator is deliberately limited to the assertion vocabulary frozen by the two
// URL-policy oracle schemas. It rejects an unknown schema keyword instead of silently widening
// its behavior, and it is not a general JSON Schema Draft 2020-12 implementation. Expanding the
// schema vocabulary requires an explicit evaluator change or selected strict validation tooling.
struct URLPolicyOracleFrozenSchemaEvaluator {
  private let rootSchema: [String: Any]

  init(schema: [String: Any]) throws {
    try Self.verifyFrozenVocabulary(in: schema, rootSchema: schema)
    rootSchema = schema
  }

  func validates(_ instance: Any) throws -> Bool {
    try validate(instance, against: rootSchema)
  }

  private func validate(_ instance: Any, against schema: Any) throws -> Bool {
    if let booleanSchema = oracleJSONBoolean(schema) {
      return booleanSchema
    }
    guard let object = schema as? [String: Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    if let reference = object["$ref"] as? String {
      let referencedSchema = try Self.resolve(reference, in: rootSchema)
      guard try validate(instance, against: referencedSchema) else {
        return false
      }
    }
    if let typeName = object["type"] as? String,
      oracleJSONValue(instance, matchesType: typeName) == false
    {
      return false
    }
    if let constant = object["const"], oracleJSONValuesEqual(instance, constant) == false {
      return false
    }
    if let choices = object["enum"] as? [Any],
      choices.contains(where: { oracleJSONValuesEqual(instance, $0) }) == false
    {
      return false
    }
    if try validateStringAssertions(instance, schema: object) == false {
      return false
    }
    if validateNumericAssertions(instance, schema: object) == false {
      return false
    }
    if try validateObjectAssertions(instance, schema: object) == false {
      return false
    }
    if try validateArrayAssertions(instance, schema: object) == false {
      return false
    }
    if let schemas = object["allOf"] as? [Any] {
      for nestedSchema in schemas where try validate(instance, against: nestedSchema) == false {
        return false
      }
    }
    if let schemas = object["oneOf"] as? [Any] {
      var matchCount = 0
      for nestedSchema in schemas where try validate(instance, against: nestedSchema) {
        matchCount += 1
      }
      guard matchCount == 1 else {
        return false
      }
    }
    if let condition = object["if"], try validate(instance, against: condition),
      let consequence = object["then"],
      try validate(instance, against: consequence) == false
    {
      return false
    }
    return true
  }

  private func validateStringAssertions(
    _ instance: Any,
    schema: [String: Any]
  ) throws -> Bool {
    guard let string = instance as? String else {
      return true
    }
    let length = string.unicodeScalars.count
    if let minimumLength = oracleJSONInteger(schema["minLength"]), length < minimumLength {
      return false
    }
    if let maximumLength = oracleJSONInteger(schema["maxLength"]), length > maximumLength {
      return false
    }
    if let pattern = schema["pattern"] as? String {
      let expression: NSRegularExpression
      do {
        expression = try NSRegularExpression(pattern: pattern)
      } catch {
        throw URLPolicyOracleTestError.invalidFixture
      }
      let range = NSRange(string.startIndex..<string.endIndex, in: string)
      if expression.firstMatch(in: string, range: range) == nil {
        return false
      }
    }
    return true
  }

  private func validateNumericAssertions(
    _ instance: Any,
    schema: [String: Any]
  ) -> Bool {
    guard let number = oracleJSONNumber(instance) else {
      return true
    }
    if let minimum = oracleJSONNumber(schema["minimum"]),
      number.doubleValue < minimum.doubleValue
    {
      return false
    }
    return true
  }

  private func validateObjectAssertions(
    _ instance: Any,
    schema: [String: Any]
  ) throws -> Bool {
    guard let instanceObject = instance as? [String: Any] else {
      return true
    }
    if let required = schema["required"] as? [String],
      required.contains(where: { instanceObject[$0] == nil })
    {
      return false
    }

    let properties = schema["properties"] as? [String: Any] ?? [:]
    for (name, propertySchema) in properties {
      guard let value = instanceObject[name] else {
        continue
      }
      guard try validate(value, against: propertySchema) else {
        return false
      }
    }
    if oracleJSONBoolean(schema["additionalProperties"]) == false,
      Set(instanceObject.keys).subtracting(properties.keys).isEmpty == false
    {
      return false
    }
    return true
  }

  private func validateArrayAssertions(
    _ instance: Any,
    schema: [String: Any]
  ) throws -> Bool {
    guard let array = instance as? [Any] else {
      return true
    }
    if let minimumItems = oracleJSONInteger(schema["minItems"]), array.count < minimumItems {
      return false
    }
    if let maximumItems = oracleJSONInteger(schema["maxItems"]), array.count > maximumItems {
      return false
    }
    if oracleJSONBoolean(schema["uniqueItems"]) == true,
      oracleJSONArrayHasDuplicates(array)
    {
      return false
    }

    let prefixSchemas = schema["prefixItems"] as? [Any] ?? []
    for index in 0..<min(array.count, prefixSchemas.count) {
      guard try validate(array[index], against: prefixSchemas[index]) else {
        return false
      }
    }
    if let itemsSchema = schema["items"], array.count > prefixSchemas.count {
      for index in prefixSchemas.count..<array.count {
        guard try validate(array[index], against: itemsSchema) else {
          return false
        }
      }
    }
    return true
  }

  private static func verifyFrozenVocabulary(
    in schema: Any,
    rootSchema: [String: Any]
  ) throws {
    if oracleJSONBoolean(schema) != nil {
      return
    }
    guard let object = schema as? [String: Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    let supportedKeywords: Set<String> = [
      "$defs", "$id", "$ref", "$schema", "additionalProperties", "allOf", "const",
      "description", "enum", "if", "items", "maxItems", "maxLength", "minItems",
      "minimum", "minLength", "oneOf", "pattern", "prefixItems", "properties", "required",
      "then", "title", "type", "uniqueItems",
    ]
    guard Set(object.keys).subtracting(supportedKeywords).isEmpty else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    try verifyMetadata(in: object, rootSchema: rootSchema)
    try verifyReference(in: object, rootSchema: rootSchema)
    try verifyTypeKeyword(in: object)
    try verifyObjectKeywords(in: object, rootSchema: rootSchema)
    try verifyArrayKeywords(in: object, rootSchema: rootSchema)
    try verifyCompositionKeywords(in: object, rootSchema: rootSchema)
    try verifyScalarKeywords(in: object)
  }

  private static func verifyMetadata(
    in schema: [String: Any],
    rootSchema: [String: Any]
  ) throws {
    for keyword in ["$id", "$schema", "description", "title"] {
      if let value = schema[keyword], (value is String) == false {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    if let definitions = schema["$defs"] {
      guard let definitionObject = definitions as? [String: Any] else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      for definition in definitionObject.values {
        try verifyFrozenVocabulary(in: definition, rootSchema: rootSchema)
      }
    }
  }

  private static func verifyReference(
    in schema: [String: Any],
    rootSchema: [String: Any]
  ) throws {
    guard let rawReference = schema["$ref"] else {
      return
    }
    guard let reference = rawReference as? String else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    _ = try resolve(reference, in: rootSchema)
  }

  private static func verifyTypeKeyword(in schema: [String: Any]) throws {
    guard let rawType = schema["type"] else {
      return
    }
    let supportedTypes: Set<String> = [
      "array", "boolean", "integer", "null", "number", "object", "string",
    ]
    guard let typeName = rawType as? String, supportedTypes.contains(typeName) else {
      throw URLPolicyOracleTestError.invalidFixture
    }
  }

  private static func verifyObjectKeywords(
    in schema: [String: Any],
    rootSchema: [String: Any]
  ) throws {
    if let properties = schema["properties"] {
      guard let propertyObject = properties as? [String: Any] else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      for propertySchema in propertyObject.values {
        try verifyFrozenVocabulary(in: propertySchema, rootSchema: rootSchema)
      }
    }
    if let required = schema["required"] {
      guard let names = required as? [String], Set(names).count == names.count else {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    if let additionalProperties = schema["additionalProperties"],
      oracleJSONBoolean(additionalProperties) == nil
    {
      throw URLPolicyOracleTestError.invalidFixture
    }
  }

  private static func verifyArrayKeywords(
    in schema: [String: Any],
    rootSchema: [String: Any]
  ) throws {
    for keyword in ["minItems", "maxItems"] {
      if let value = schema[keyword],
        (oracleJSONInteger(value) ?? -1) < 0
      {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    if let uniqueItems = schema["uniqueItems"], oracleJSONBoolean(uniqueItems) == nil {
      throw URLPolicyOracleTestError.invalidFixture
    }
    if let items = schema["items"] {
      try verifyFrozenVocabulary(in: items, rootSchema: rootSchema)
    }
    if let prefixItems = schema["prefixItems"] {
      guard let schemas = prefixItems as? [Any] else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      for nestedSchema in schemas {
        try verifyFrozenVocabulary(in: nestedSchema, rootSchema: rootSchema)
      }
    }
  }

  private static func verifyCompositionKeywords(
    in schema: [String: Any],
    rootSchema: [String: Any]
  ) throws {
    for keyword in ["allOf", "oneOf"] {
      guard let rawSchemas = schema[keyword] else {
        continue
      }
      guard let schemas = rawSchemas as? [Any], schemas.isEmpty == false else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      for nestedSchema in schemas {
        try verifyFrozenVocabulary(in: nestedSchema, rootSchema: rootSchema)
      }
    }
    for keyword in ["if", "then"] {
      if let nestedSchema = schema[keyword] {
        try verifyFrozenVocabulary(in: nestedSchema, rootSchema: rootSchema)
      }
    }
  }

  private static func verifyScalarKeywords(in schema: [String: Any]) throws {
    if let choices = schema["enum"] {
      guard let values = choices as? [Any], values.isEmpty == false,
        oracleJSONArrayHasDuplicates(values) == false
      else {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    if let pattern = schema["pattern"] {
      guard let expression = pattern as? String else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      do {
        _ = try NSRegularExpression(pattern: expression)
      } catch {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    if let minimum = schema["minimum"], oracleJSONNumber(minimum) == nil {
      throw URLPolicyOracleTestError.invalidFixture
    }
    for keyword in ["minLength", "maxLength"] {
      if let value = schema[keyword],
        (oracleJSONInteger(value) ?? -1) < 0
      {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
  }

  private static func resolve(_ reference: String, in rootSchema: [String: Any]) throws -> Any {
    guard reference.hasPrefix("#"),
      let decodedFragment = String(reference.dropFirst()).removingPercentEncoding
    else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    guard decodedFragment.isEmpty == false else {
      return rootSchema
    }
    guard decodedFragment.hasPrefix("/") else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    var value: Any = rootSchema
    for rawToken in decodedFragment.dropFirst().split(
      separator: "/",
      omittingEmptySubsequences: false
    ) {
      let token = try decodeJSONPointerToken(String(rawToken))
      if let object = value as? [String: Any], let nestedValue = object[token] {
        value = nestedValue
      } else if let array = value as? [Any], let index = Int(token), array.indices.contains(index) {
        value = array[index]
      } else {
        throw URLPolicyOracleTestError.invalidFixture
      }
    }
    return value
  }

  private static func decodeJSONPointerToken(_ token: String) throws -> String {
    let scalars = Array(token.unicodeScalars)
    var result = String.UnicodeScalarView()
    var index = 0
    while index < scalars.count {
      guard scalars[index] == "~" else {
        result.append(scalars[index])
        index += 1
        continue
      }
      guard index + 1 < scalars.count else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      switch scalars[index + 1] {
      case "0":
        result.append("~")
      case "1":
        result.append("/")
      default:
        throw URLPolicyOracleTestError.invalidFixture
      }
      index += 2
    }
    return String(result)
  }
}

private func oracleJSONValue(_ value: Any, matchesType typeName: String) -> Bool {
  switch typeName {
  case "array":
    value is [Any]
  case "boolean":
    oracleJSONBoolean(value) != nil
  case "integer":
    oracleJSONInteger(value) != nil
  case "null":
    value is NSNull
  case "number":
    oracleJSONNumber(value) != nil
  case "object":
    value is [String: Any]
  case "string":
    value is String
  default:
    false
  }
}

private func oracleJSONBoolean(_ value: Any?) -> Bool? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) == CFBooleanGetTypeID()
  else {
    return nil
  }
  return number.boolValue
}

private func oracleJSONNumber(_ value: Any?) -> NSNumber? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID(),
    number.doubleValue.isFinite
  else {
    return nil
  }
  return number
}

private func oracleJSONInteger(_ value: Any?) -> Int? {
  guard let number = oracleJSONNumber(value),
    number.doubleValue.rounded(.towardZero) == number.doubleValue,
    let integer = Int(exactly: number.int64Value)
  else {
    return nil
  }
  return integer
}

private func oracleJSONArrayHasDuplicates(_ values: [Any]) -> Bool {
  for leftIndex in values.indices {
    for rightIndex in values.index(after: leftIndex)..<values.endIndex
    where oracleJSONValuesEqual(values[leftIndex], values[rightIndex]) {
      return true
    }
  }
  return false
}

private func oracleJSONValuesEqual(_ left: Any, _ right: Any) -> Bool {
  if left is NSNull || right is NSNull {
    return left is NSNull && right is NSNull
  }
  if let leftBoolean = oracleJSONBoolean(left), let rightBoolean = oracleJSONBoolean(right) {
    return leftBoolean == rightBoolean
  }
  if oracleJSONBoolean(left) != nil || oracleJSONBoolean(right) != nil {
    return false
  }
  if let leftNumber = oracleJSONNumber(left), let rightNumber = oracleJSONNumber(right) {
    return leftNumber.doubleValue == rightNumber.doubleValue
  }
  if let leftString = left as? String, let rightString = right as? String {
    return leftString.unicodeScalars.elementsEqual(rightString.unicodeScalars)
  }
  if let leftArray = left as? [Any], let rightArray = right as? [Any] {
    return leftArray.count == rightArray.count
      && zip(leftArray, rightArray).allSatisfy {
        oracleJSONValuesEqual($0.0, $0.1)
      }
  }
  if let leftObject = left as? [String: Any], let rightObject = right as? [String: Any] {
    guard Set(leftObject.keys) == Set(rightObject.keys) else {
      return false
    }
    return leftObject.allSatisfy { key, value in
      guard let rightValue = rightObject[key] else {
        return false
      }
      return oracleJSONValuesEqual(value, rightValue)
    }
  }
  return false
}

struct URLPolicyIDNACase: Sendable {
  let lineNumber: Int
  let rawSource: String
  let source: String
  let expectedASCII: String
  let toASCIIStatus: [String]

  var expectsToASCIIRejection: Bool {
    toASCIIStatus.isEmpty == false
  }
}

struct URLPolicyWPTCase: Sendable {
  let sourceIndex: Int
  let input: String
  let expectsFailure: Bool
  let protocolName: String?
  let hostname: String?
  let port: String?
  let hasObjectComment: Bool
}

struct URLPolicyWPTCorpus: Sendable {
  let comments: [String]
  let cases: [URLPolicyWPTCase]
}

struct URLPolicyAddressFixture: Decodable, Sendable {
  let schemaVersion: Int
  let fixtureId: String
  let policyScope: String
  let safety: Safety
  let categoryCounts: [String: Int]
  let cases: [Case]

  struct Safety: Decodable, Sendable {
    let executionBoundary: String
    let networkAccessPermitted: Bool
    let operationalUsePermitted: Bool
    let inputOrigin: String
    let addressPolicy: String
    let containsCapturedInputs: Bool
    let containsOperationalInputs: Bool
    let containsPotentiallyResolvableNames: Bool
    let containsSecrets: Bool
  }

  struct Case: Decodable, Sendable {
    let id: String
    let category: String
    let inputURL: String
    let expected: Expected
    let rfcReferences: [RFCReference]
    let rationale: String
  }

  struct Expected: Decodable, Sendable {
    let outcome: String
    let normalizedHost: String?
    let addressFamily: String?
    let mechanism: String?
    let normalizationBasis: String?
    let isIPLiteral: Bool?
    let reason: String?
  }

  struct RFCReference: Decodable, Sendable {
    let document: String
    let section: String
    let url: String
  }
}

func loadURLPolicyIDNACases(_ relativePath: String) throws -> [URLPolicyIDNACase] {
  let contents = try loadURLPolicyOracleString(relativePath)
  var cases: [URLPolicyIDNACase] = []

  for (offset, completeLine) in contents.split(
    separator: "\n",
    omittingEmptySubsequences: false
  ).enumerated() {
    let lineNumber = offset + 1
    let line = String(completeLine)
    let content = line.firstIndex(of: "#").map { String(line[..<$0]) } ?? line
    guard content.trimmingCharacters(in: .whitespaces).isEmpty == false else {
      continue
    }

    let columns = content.split(separator: ";", omittingEmptySubsequences: false).map {
      String($0).trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
    }
    guard columns.count == 7 else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    let source = try decodeIDNAEscapes(in: columns[0])
    let unicodeResult = columns[1].isEmpty ? source : try decodeIDNAEscapes(in: columns[1])
    let unicodeStatus = try parseIDNAStatus(columns[2])
    let asciiResult = columns[3].isEmpty ? unicodeResult : try decodeIDNAEscapes(in: columns[3])
    let asciiStatus = columns[4].isEmpty ? unicodeStatus : try parseIDNAStatus(columns[4])

    cases.append(
      URLPolicyIDNACase(
        lineNumber: lineNumber,
        rawSource: columns[0],
        source: source,
        expectedASCII: asciiResult,
        toASCIIStatus: asciiStatus
      )
    )
  }

  return cases
}

func loadURLPolicyWPTCorpus(_ relativePath: String) throws -> URLPolicyWPTCorpus {
  let data = try loadURLPolicyOracleData(relativePath)
  let root: [Any]
  do {
    guard let value = try JSONSerialization.jsonObject(with: data) as? [Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    root = value
  } catch is URLPolicyOracleTestError {
    throw URLPolicyOracleTestError.invalidFixture
  } catch {
    throw URLPolicyOracleTestError.invalidFixture
  }

  var comments: [String] = []
  var cases: [URLPolicyWPTCase] = []
  for (index, value) in root.enumerated() {
    if let comment = value as? String {
      comments.append(comment)
      continue
    }
    guard let object = value as? [String: Any], let input = object["input"] as? String else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    let failure: Bool
    if let rawFailure = object["failure"] {
      guard let bool = rawFailure as? Bool else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      failure = bool
    } else {
      failure = false
    }
    if let comment = object["comment"], (comment is String) == false {
      throw URLPolicyOracleTestError.invalidFixture
    }

    cases.append(
      URLPolicyWPTCase(
        sourceIndex: index,
        input: input,
        expectsFailure: failure,
        protocolName: object["protocol"] as? String,
        hostname: object["hostname"] as? String,
        port: object["port"] as? String,
        hasObjectComment: object["comment"] != nil
      )
    )
  }

  return URLPolicyWPTCorpus(comments: comments, cases: cases)
}

func loadURLPolicyAddressFixture(_ relativePath: String) throws -> URLPolicyAddressFixture {
  let data = try loadURLPolicyOracleData(relativePath)
  do {
    return try JSONDecoder().decode(URLPolicyAddressFixture.self, from: data)
  } catch {
    throw URLPolicyOracleTestError.invalidFixture
  }
}

func isAbsoluteWPTWebURL(_ input: String) -> Bool {
  let withoutParserWhitespace = input.filter { character in
    character != "\t" && character != "\r" && character != "\n"
  }
  let trimmed = withoutParserWhitespace.trimmingCharacters(
    in: CharacterSet(
      charactersIn:
        "\u{0000}\u{0001}\u{0002}\u{0003}\u{0004}\u{0005}\u{0006}\u{0007}\u{0008}\u{0009}\u{000A}\u{000B}\u{000C}\u{000D}\u{000E}\u{000F}\u{0010}\u{0011}\u{0012}\u{0013}\u{0014}\u{0015}\u{0016}\u{0017}\u{0018}\u{0019}\u{001A}\u{001B}\u{001C}\u{001D}\u{001E}\u{001F} "
    )
  )
  let lowered = trimmed.lowercased()
  return lowered.hasPrefix("http:") || lowered.hasPrefix("https:")
}

private func loadURLPolicyOracleData(_ relativePath: String) throws -> Data {
  let url = urlPolicyOracleRepositoryRoot.appendingPathComponent(relativePath).standardizedFileURL
  guard url.path.hasPrefix(urlPolicyOracleRepositoryRoot.path + "/") else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  do {
    return try Data(contentsOf: url, options: [.mappedIfSafe])
  } catch {
    throw URLPolicyOracleTestError.unreadableFixture
  }
}

private func loadURLPolicyOracleString(_ relativePath: String) throws -> String {
  let data = try loadURLPolicyOracleData(relativePath)
  guard let value = String(data: data, encoding: .utf8) else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  return value
}

private func parseIDNAStatus(_ rawValue: String) throws -> [String] {
  guard rawValue.isEmpty == false else {
    return []
  }
  guard rawValue.hasPrefix("["), rawValue.hasSuffix("]") else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  let inner = rawValue.dropFirst().dropLast()
    .trimmingCharacters(in: .whitespaces)
  guard inner.isEmpty == false else {
    return []
  }
  let values = inner.split(separator: ",", omittingEmptySubsequences: false).map {
    String($0).trimmingCharacters(in: .whitespaces)
  }
  guard
    values.allSatisfy({ value in
      value.isEmpty == false
        && value.utf8.allSatisfy { byte in
          (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte) || byte == 0x5F
        }
    })
  else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  return values
}

private func decodeIDNAEscapes(in rawValue: String) throws -> String {
  guard rawValue != "\"\"" else {
    return ""
  }

  let scalars = Array(rawValue.unicodeScalars)
  var result = String.UnicodeScalarView()
  var index = 0
  while index < scalars.count {
    guard scalars[index] == "\\" else {
      result.append(scalars[index])
      index += 1
      continue
    }
    guard index + 1 < scalars.count else {
      throw URLPolicyOracleTestError.invalidFixture
    }

    if scalars[index + 1] == "u" {
      let (codeUnit, nextIndex) = try parseFourDigitEscape(scalars, at: index)
      if (0xD800...0xDBFF).contains(codeUnit),
        nextIndex + 5 < scalars.count,
        scalars[nextIndex] == "\\",
        scalars[nextIndex + 1] == "u"
      {
        let (lowSurrogate, afterLowSurrogate) = try parseFourDigitEscape(
          scalars,
          at: nextIndex
        )
        if (0xDC00...0xDFFF).contains(lowSurrogate) {
          let high = UInt32(codeUnit - 0xD800)
          let low = UInt32(lowSurrogate - 0xDC00)
          guard let scalar = Unicode.Scalar(0x1_0000 + (high << 10) + low) else {
            throw URLPolicyOracleTestError.invalidFixture
          }
          result.append(scalar)
          index = afterLowSurrogate
          continue
        }
      }

      if (0xD800...0xDFFF).contains(codeUnit) {
        result.append("\u{FFFD}")
      } else {
        guard let scalar = Unicode.Scalar(UInt32(codeUnit)) else {
          throw URLPolicyOracleTestError.invalidFixture
        }
        result.append(scalar)
      }
      index = nextIndex
      continue
    }

    if scalars[index + 1] == "x" {
      guard index + 3 < scalars.count, scalars[index + 2] == "{" else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      var cursor = index + 3
      var hexDigits = ""
      while cursor < scalars.count, scalars[cursor] != "}" {
        hexDigits.unicodeScalars.append(scalars[cursor])
        cursor += 1
      }
      guard cursor < scalars.count, hexDigits.isEmpty == false,
        let scalarValue = UInt32(hexDigits, radix: 16),
        let scalar = Unicode.Scalar(scalarValue)
      else {
        throw URLPolicyOracleTestError.invalidFixture
      }
      result.append(scalar)
      index = cursor + 1
      continue
    }

    throw URLPolicyOracleTestError.invalidFixture
  }

  return String(result)
}

private func parseFourDigitEscape(
  _ scalars: [Unicode.Scalar],
  at index: Int
) throws -> (UInt16, Int) {
  guard index + 5 < scalars.count, scalars[index] == "\\", scalars[index + 1] == "u" else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  let digits = String(String.UnicodeScalarView(scalars[(index + 2)...(index + 5)]))
  guard let value = UInt16(digits, radix: 16) else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  return (value, index + 6)
}
