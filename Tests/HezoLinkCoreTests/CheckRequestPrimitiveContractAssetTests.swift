import CoreFoundation
import CryptoKit
import Foundation
import HezoLinkCore
import Testing

struct CheckRequestPrimitiveContractAssetTests {
  @Test func schemasAndOpenAPIFreezeBothStandaloneSurfaces() throws {
    let analysisData = try primitiveLoadData(primitiveAnalysisSchemaPath)
    let versionData = try primitiveLoadData(primitiveVersionSchemaPath)
    let analysis = try primitiveRequireObject(primitiveJSONValue(from: analysisData))
    let version = try primitiveRequireObject(primitiveJSONValue(from: versionData))

    #expect(primitiveSHA256(analysisData) == primitiveAnalysisSchemaSHA256)
    #expect(primitiveSHA256(versionData) == primitiveVersionSchemaSHA256)
    try primitiveRequireExactAnalysisSchema(analysis)
    try primitiveRequireExactVersionSchema(version)

    let openAPIData = try primitiveLoadData(primitiveOpenAPIPath)
    let openAPI = try primitiveRequireObject(primitiveJSONValue(from: openAPIData))
    #expect(primitiveSHA256(openAPIData) == primitiveComponentDocumentDigest)
    #expect(Set(openAPI.keys) == ["openapi", "info", "jsonSchemaDialect", "paths", "components"])
    #expect(openAPI["openapi"] as? String == "3.1.0")
    #expect(
      openAPI["jsonSchemaDialect"] as? String
        == "https://json-schema.org/draft/2020-12/schema"
    )
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let info = try primitiveRequireObject(openAPI["info"])
    #expect(Set(info.keys) == ["title", "version", "description"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.11.0")
    #expect(info["description"] as? String == primitiveOpenAPIDescription)

    let components = try primitiveRequireObject(openAPI["components"])
    let schemas = try primitiveRequireObject(components["schemas"])
    #expect(Set(components.keys) == ["schemas"])
    #expect(Set(schemas.keys) == primitiveOpenAPIComponents)
    #expect(schemas.count == 16)
    try primitiveRequireOpenAPIReference(
      schemas["AnalysisProfileV1"], expected: primitiveAnalysisOpenAPIReference)
    try primitiveRequireOpenAPIReference(
      schemas["ReasonSchemaVersionV1"], expected: primitiveVersionOpenAPIReference)

    let openAPIURL = primitiveRepositoryRoot.appendingPathComponent(primitiveOpenAPIPath)
    for (reference, schemaPath) in [
      (primitiveAnalysisOpenAPIReference, primitiveAnalysisSchemaPath),
      (primitiveVersionOpenAPIReference, primitiveVersionSchemaPath),
    ] {
      #expect(
        openAPIURL.deletingLastPathComponent().appendingPathComponent(reference)
          .standardizedFileURL
          == primitiveRepositoryRoot.appendingPathComponent(schemaPath).standardizedFileURL
      )
    }
  }

  @Test func manifestsPinEveryRawByteDigestKeywordAndHiddenAwareInventory() throws {
    try primitiveVerifyManifest(
      contract: .analysis,
      expectations: primitiveAnalysisFixtures,
      expectedManifestSHA256: primitiveAnalysisManifestSHA256
    )
    try primitiveVerifyManifest(
      contract: .version,
      expectations: primitiveVersionFixtures,
      expectedManifestSHA256: primitiveVersionManifestSHA256
    )
  }

  @Test func evaluatorsAndSchemaMutationsFreezeTheExactScalarLanguages() throws {
    #expect(primitiveAnalysisFailures(in: "standard").isEmpty)
    for value in ["", "fast", "Standard", "standard "] {
      #expect(primitiveAnalysisFailures(in: value) == ["const"])
    }
    for value: Any in [
      NSNumber(value: 1), NSNumber(value: true), NSNull(), [Any](), [String: Any](),
    ] {
      #expect(primitiveAnalysisFailures(in: value) == ["type", "const"])
    }

    for lexeme in ["1", "1.0", "1e0", "10e-1", "0.1e1", "100e-2"] {
      #expect(try primitiveVersionFailures(inJSONNumberLexeme: lexeme).isEmpty)
    }
    for lexeme in ["0", "2", "-1", "15e1", "150e-1"] {
      #expect(try primitiveVersionFailures(inJSONNumberLexeme: lexeme) == ["const"])
    }
    for lexeme in [
      "1.5", "1.000000000000000000001", "0.999999999999999999999",
    ] {
      #expect(
        try primitiveVersionFailures(inJSONNumberLexeme: lexeme) == ["type", "const"]
      )
    }
    for lexeme in ["", "+1", "01", "1.", ".1", "1e", "1e+", "--1", "NaN", "Infinity"] {
      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveVersionFailures(inJSONNumberLexeme: lexeme)
      }
    }
    for value: Any in ["1", NSNumber(value: true), NSNull(), [Any](), [String: Any]()] {
      #expect(primitiveVersionNonnumberFailures(in: value) == ["type", "const"])
    }

    let analysis = try primitiveLoadObject(primitiveAnalysisSchemaPath)
    let version = try primitiveLoadObject(primitiveVersionSchemaPath)
    for mutation in PrimitiveSchemaMutation.allCases {
      var mutatedAnalysis = analysis
      mutation.applyAnalysis(to: &mutatedAnalysis)
      #expect(throws: PrimitiveAssetError.self) {
        try primitiveRequireExactAnalysisSchema(mutatedAnalysis)
      }

      var mutatedVersion = version
      mutation.applyVersion(to: &mutatedVersion)
      #expect(throws: PrimitiveAssetError.self) {
        try primitiveRequireExactVersionSchema(mutatedVersion)
      }
    }
  }

  @Test func checkRequestUsesOnlyTheTwoExactRegisteredAbsoluteReferences() throws {
    let analysis = try primitiveLoadObject(primitiveAnalysisSchemaPath)
    let version = try primitiveLoadObject(primitiveVersionSchemaPath)
    let request = try primitiveLoadObject(primitiveCheckRequestSchemaPath)
    let registry = [primitiveAnalysisSchemaID: analysis, primitiveVersionSchemaID: version]

    let properties = try primitiveRequireObject(request["properties"])
    let consumers = [
      ("analysis_profile", primitiveAnalysisSchemaID),
      ("reason_schema_version", primitiveVersionSchemaID),
    ]
    for (field, identifier) in consumers {
      let reference = try primitiveRequireObject(properties[field])
      let resolved = try primitiveResolve(reference, identifier: identifier, registry: registry)
      #expect(resolved["$id"] as? String == identifier)

      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveResolve(
          ["$ref": "./relative.schema.json"], identifier: identifier,
          registry: registry)
      }
      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveResolve(
          ["$ref": identifier, "const": "widened"], identifier: identifier,
          registry: registry)
      }
      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveResolve(resolved, identifier: identifier, registry: registry)
      }
      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveResolve(reference, identifier: identifier, registry: [:])
      }

      var mismatchedRegistry = registry
      var mismatched = resolved
      mismatched["$id"] = "urn:hezo-link:contract:mismatched:v1"
      mismatchedRegistry[identifier] = mismatched
      #expect(throws: PrimitiveAssetError.self) {
        _ = try primitiveResolve(reference, identifier: identifier, registry: mismatchedRegistry)
      }
    }

    #expect(
      try primitiveReferenceLocationsOnDisk()
        == [
          "check-request-v1.schema.json#/properties/analysis_profile/$ref",
          "check-request-v1.schema.json#/properties/reason_schema_version/$ref",
        ]
    )
  }

  @Test func priorCheckRequestFixtureTreeAndDeclaredOutcomesRemainByteIdentical() throws {
    let root = primitiveRepositoryRoot.appendingPathComponent(primitivePriorFixtureRoot)
      .standardizedFileURL
    let paths = try primitiveRegularPaths(relativeTo: root).sorted()
    #expect(paths.count == 13)
    #expect(Set(paths) == Set(primitivePriorFixtureSHA256ByPath.keys))
    for path in paths {
      let expected = try #require(primitivePriorFixtureSHA256ByPath[path])
      #expect(primitiveSHA256(try Data(contentsOf: root.appendingPathComponent(path))) == expected)
    }
    #expect(
      try primitivePriorFixtureAggregate(paths: paths, root: root)
        == primitivePriorFixtureAggregateSHA256)
    #expect(
      try Data(contentsOf: root.appendingPathComponent("invalid/analysis-profile.json"))
        == Data(primitivePriorAnalysisInvalidRawJSON.utf8)
    )
    #expect(
      try Data(contentsOf: root.appendingPathComponent("invalid/reason-schema-version.json"))
        == Data(primitivePriorVersionInvalidRawJSON.utf8)
    )

    let manifest = try primitiveLoadObject("\(primitivePriorFixtureRoot)/manifest.json")
    let cases = try primitiveRequireObjectArray(manifest["cases"])
    #expect(cases.count == 12)
    #expect(cases.filter { $0["expected_schema_valid"] as? Bool == true }.count == 3)
    #expect(cases.filter { $0["expected_schema_valid"] as? Bool == false }.count == 9)

    let requestSchema = try primitiveLoadObject(primitiveCheckRequestSchemaPath)
    let registry = [
      primitiveAnalysisSchemaID: try primitiveLoadObject(primitiveAnalysisSchemaPath),
      primitiveVersionSchemaID: try primitiveLoadObject(primitiveVersionSchemaPath),
    ]
    for fixtureCase in cases {
      let path = try primitiveRequireString(fixtureCase["path"])
      let value = try primitiveRequireObject(
        primitiveJSONValue(from: primitiveLoadData("\(primitivePriorFixtureRoot)/\(path)"))
      )
      let declared = try primitiveDeclaredKeywords(in: fixtureCase)
      #expect(
        try primitiveCheckRequestFailures(in: value, schema: requestSchema, registry: registry)
          == declared,
        "Resolved CheckRequest V1 outcome drifted: \(path)"
      )
    }
  }

  @Test func publicSwiftSurfacesRoundTripAndRejectCandidatesWithoutDisclosure() throws {
    #expect(AnalysisProfileV1.allCases == [.standard])
    #expect(AnalysisProfileV1.standard.rawValue == "standard")
    #expect(ReasonSchemaVersionV1.allCases == [.v1])
    #expect(ReasonSchemaVersionV1.v1.rawValue == 1)
    primitiveRequireAnalysisConformances(AnalysisProfileV1.standard)
    primitiveRequireVersionConformances(ReasonSchemaVersionV1.v1)
    #expect(CheckRequestV1.analysisProfile == AnalysisProfileV1.standard.rawValue)
    #expect(CheckRequestV1.reasonSchemaVersion == ReasonSchemaVersionV1.v1.rawValue)

    #expect(
      try HezoJSON.makeEncoder().encode(AnalysisProfileV1.standard) == Data("\"standard\"".utf8))
    #expect(try HezoJSON.makeEncoder().encode(ReasonSchemaVersionV1.v1) == Data("1".utf8))
    #expect(
      try HezoJSON.makeResponseDecoder().decode(
        AnalysisProfileV1.self, from: Data("\"standard\"".utf8)) == .standard
    )

    let profileCanary = "PRIVATE_ANALYSIS_PROFILE_CANARY"
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(
        AnalysisProfileV1.self, from: try JSONEncoder().encode(profileCanary))
      Issue.record("An invalid analysis-profile privacy canary was accepted.")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.isEmpty)
      #expect(context.debugDescription == "Invalid analysis profile.")
      #expect(context.underlyingError == nil)
      #expect(String(describing: context).contains(profileCanary) == false)
      #expect(String(reflecting: context).contains(profileCanary) == false)
    } catch {
      Issue.record("AnalysisProfileV1 used an unexpected decode error category.")
    }

    for expectation in primitiveAnalysisFixtures where expectation.expectedValid == false {
      try primitiveVerifyProfileDecodeFailure(expectation)
    }
    // ReasonSchemaVersionV1 is deliberately encoder-only; inbound numeric-language validation
    // belongs to the standalone JSON Schema contract and its independent evaluator above.
  }

  @Test func documentationPinsSyntaxOnlyPurposeAndExplicitNonclaims() throws {
    let readmeData = try primitiveLoadData("packages/contracts/README.md")
    let APIData = try primitiveLoadData("docs/06-api-contracts.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    let API = try #require(String(data: APIData, encoding: .utf8))

    #expect(primitiveSHA256(readmeData) == primitiveReadmeSHA256)
    #expect(primitiveSHA256(APIData) == primitiveContractDocumentDigest)
    #expect(
      readme.contains(
        "The standalone primitive is assigned only to `CheckRequestV1.analysis_profile`"))
    #expect(readme.contains("does not authorize a `fast` profile"))
    #expect(readme.contains("two representative JSON spellings"))
    #expect(readme.contains("The Swift value is intentionally encoder-only"))
    #expect(readme.contains("inbound validation remains at the standalone JSON Schema boundary"))
    #expect(
      readme.contains("creates no relationship to the design-target `versions.reason_schema` field")
    )
    #expect(API.contains("using their absolute schema IDs"))
    #expect(API.contains("does not change the accepted Check Request V1 wire values"))
    #expect(API.contains("Its Swift value is intentionally encoder-only"))
    #expect(API.contains("Neither primitive authorizes or defines"))
  }
}

private enum PrimitiveAssetError: Error {
  case invalidAsset
  case unreadableAsset
}

private enum PrimitiveContract: Sendable {
  case analysis
  case version

  var name: String {
    switch self {
    case .analysis: "analysis-profile-v1"
    case .version: "reason-schema-version-v1"
    }
  }

  var schemaPath: String {
    switch self {
    case .analysis: primitiveAnalysisSchemaPath
    case .version: primitiveVersionSchemaPath
    }
  }

  var fixtureRoot: String {
    "packages/contracts/fixtures/\(name)"
  }

  var manifestPath: String {
    "\(fixtureRoot)/manifest.json"
  }

  var manifestSchemaReference: String {
    "../../schemas/\(name).schema.json"
  }

  func failures(in value: Any, rawJSON: String) throws -> Set<String> {
    switch self {
    case .analysis:
      return primitiveAnalysisFailures(in: value)
    case .version:
      guard let number = value as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID(),
        rawJSON.last == "\n"
      else {
        return primitiveVersionNonnumberFailures(in: value)
      }
      return try primitiveVersionFailures(inJSONNumberLexeme: String(rawJSON.dropLast()))
    }
  }
}

private struct PrimitiveFixtureExpectation: Sendable {
  let id: String
  let path: String
  let rawJSON: String
  let sha256: String
  let payload: PrimitivePayload
  let expectedValid: Bool
  let failureKeywords: [String]
}

private enum PrimitivePayload: Sendable {
  case string(String)
  case number(Double)
  case boolean(Bool)
  case null
  case array
  case object

  func matches(_ value: Any) -> Bool {
    switch self {
    case .string(let expected):
      return value as? String == expected
    case .number(let expected):
      guard let number = value as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID()
      else {
        return false
      }
      return number.doubleValue == expected
    case .boolean(let expected):
      guard let number = value as? NSNumber,
        CFGetTypeID(number) == CFBooleanGetTypeID()
      else {
        return false
      }
      return number.boolValue == expected
    case .null:
      return value is NSNull
    case .array:
      return (value as? [Any])?.isEmpty == true
    case .object:
      return (value as? [String: Any])?.isEmpty == true
    }
  }
}

/// Exact base-ten interpretation for the two JSON Schema predicates this fixture suite needs.
/// It intentionally avoids Foundation numeric conversion so arbitrary fractional tails cannot
/// round into the integer constant `1`.
private struct PrimitiveExactDecimal {
  let isInteger: Bool
  let isOne: Bool

  init?(_ lexeme: String) {
    let bytes = Array(lexeme.utf8)
    guard bytes.isEmpty == false else {
      return nil
    }

    var index = 0
    var isNegative = false
    if bytes[index] == 0x2D {
      isNegative = true
      index += 1
      guard index < bytes.count else {
        return nil
      }
    }

    var integerDigits = [UInt8]()
    if bytes[index] == 0x30 {
      integerDigits.append(bytes[index])
      index += 1
      if index < bytes.count, primitiveIsASCIIDigit(bytes[index]) {
        return nil
      }
    } else {
      guard (0x31...0x39).contains(bytes[index]) else {
        return nil
      }
      while index < bytes.count, primitiveIsASCIIDigit(bytes[index]) {
        integerDigits.append(bytes[index])
        index += 1
      }
    }

    var fractionalDigits = [UInt8]()
    if index < bytes.count, bytes[index] == 0x2E {
      index += 1
      guard index < bytes.count, primitiveIsASCIIDigit(bytes[index]) else {
        return nil
      }
      while index < bytes.count, primitiveIsASCIIDigit(bytes[index]) {
        fractionalDigits.append(bytes[index])
        index += 1
      }
    }

    var exponent = 0
    if index < bytes.count, bytes[index] == 0x65 || bytes[index] == 0x45 {
      index += 1
      guard index < bytes.count else {
        return nil
      }
      var exponentIsNegative = false
      if bytes[index] == 0x2B || bytes[index] == 0x2D {
        exponentIsNegative = bytes[index] == 0x2D
        index += 1
      }
      guard index < bytes.count, primitiveIsASCIIDigit(bytes[index]) else {
        return nil
      }

      let saturation = bytes.count + 1
      var magnitude = 0
      while index < bytes.count, primitiveIsASCIIDigit(bytes[index]) {
        let digit = Int(bytes[index] - 0x30)
        if magnitude > (saturation - digit) / 10 {
          magnitude = saturation
        } else {
          magnitude = min(saturation, magnitude * 10 + digit)
        }
        index += 1
      }
      exponent = exponentIsNegative ? -magnitude : magnitude
    }
    guard index == bytes.count else {
      return nil
    }

    let coefficient = integerDigits + fractionalDigits
    let normalized = Array(coefficient.drop { $0 == 0x30 })
    if normalized.isEmpty {
      isInteger = true
      isOne = false
      return
    }

    let scale = exponent - fractionalDigits.count
    if scale >= 0 {
      isInteger = true
    } else {
      let requiredZeroSuffix = -scale
      isInteger =
        requiredZeroSuffix <= normalized.count
        && normalized.suffix(requiredZeroSuffix).allSatisfy { $0 == 0x30 }
    }

    let trailingZeroCount = normalized.reversed().prefix { $0 == 0x30 }.count
    let reduced = normalized.dropLast(trailingZeroCount)
    isOne =
      isNegative == false
      && reduced.elementsEqual([0x31])
      && scale + trailingZeroCount == 0
  }
}

private func primitiveIsASCIIDigit(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte)
}

private enum PrimitiveSchemaMutation: CaseIterable {
  case missingConstant
  case wrongType
  case wrongConstant
  case mismatchedIdentifier
  case changedDescription
  case addedKeyword

  func applyAnalysis(to schema: inout [String: Any]) {
    switch self {
    case .missingConstant:
      schema.removeValue(forKey: "const")
    case .wrongType:
      schema["type"] = ["string", "null"]
    case .wrongConstant:
      schema["const"] = "fast"
    case .mismatchedIdentifier:
      schema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    case .changedDescription:
      schema["description"] = "Widened analysis-profile claim."
    case .addedKeyword:
      schema["enum"] = ["standard"]
    }
  }

  func applyVersion(to schema: inout [String: Any]) {
    switch self {
    case .missingConstant:
      schema.removeValue(forKey: "const")
    case .wrongType:
      schema["type"] = "number"
    case .wrongConstant:
      schema["const"] = 2
    case .mismatchedIdentifier:
      schema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    case .changedDescription:
      schema["description"] = "Widened reason-schema-version claim."
    case .addedKeyword:
      schema["minimum"] = 1
    }
  }
}

private let primitiveRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let primitiveAnalysisSchemaPath =
  "packages/contracts/schemas/analysis-profile-v1.schema.json"
private let primitiveVersionSchemaPath =
  "packages/contracts/schemas/reason-schema-version-v1.schema.json"
private let primitiveCheckRequestSchemaPath =
  "packages/contracts/schemas/check-request-v1.schema.json"
private let primitiveOpenAPIPath = "packages/contracts/openapi-components.json"
private let primitivePriorFixtureRoot = "packages/contracts/fixtures/check-request-v1"
private let primitiveAnalysisSchemaID = "urn:hezo-link:contract:analysis-profile:v1"
private let primitiveVersionSchemaID = "urn:hezo-link:contract:reason-schema-version:v1"
private let primitiveAnalysisOpenAPIReference = "./schemas/analysis-profile-v1.schema.json"
private let primitiveVersionOpenAPIReference = "./schemas/reason-schema-version-v1.schema.json"
private let primitiveAnalysisSchemaSHA256 =
  "f877bbd9bef241d475b675eea06eb602ddd3c8f3a1d1b418f8fb0451e76517ef"
private let primitiveVersionSchemaSHA256 =
  "a9eca940f74e53747352203965de59332129a3affd882b858c89c7fc235cc668"
private let primitiveAnalysisManifestSHA256 =
  "7d29f05dda71e9d3ea4d8491ef713709b70c47dbe0a2933d678324d227451cf1"
private let primitiveVersionManifestSHA256 =
  "512ec7992bbeedf72d68d9a32b36d5e3ab4a7c6d44e9bb97d5357d283a37884f"
private let primitiveComponentDocumentDigest =
  "ab9ecb02ee6049ef09ae1f0aa8a060e8767f296e82c5e4fa8dc164232a8ab2dd"
private let primitiveReadmeSHA256 =
  "3418142aea7a06ac775f1f2243e6820b2c6c73572eab55e61360d13fc25379ed"
private let primitiveContractDocumentDigest =
  "9640fe17077659ee8e5a13b04f469e41a942e98f9c23454713742b0f17ef2e71"
private let primitiveAnalysisSchemaDescription =
  "Exact standalone CheckRequestV1 analysis-profile primitive. This value is assigned only to CheckRequestV1.analysis_profile and defines no completed-response analysis, completeness, collector set, fast profile, negotiation, policy, runtime, network, or persistence behavior."
private let primitiveVersionSchemaDescription =
  "Exact standalone CheckRequestV1 reason-schema-version primitive. This value is assigned only to CheckRequestV1.reason_schema_version and defines no completed-response versions member, reason vocabulary, negotiation, completeness, collector set, profile, policy, runtime, network, or persistence behavior."
private let primitiveOpenAPIDescription =
  "Reusable offline check-input, check-request leaf-primitive, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."

private let primitiveOpenAPIComponents: Set<String> = [
  "CheckRequestV1", "AnalysisProfileV1", "ReasonSchemaVersionV1", "RequestIDV1",
  "CheckTokenV1", "CanonicalInstantV1", "ProblemV1", "VerdictReasonV1", "VerdictLabelV1",
  "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1", "VerdictReasonsV1",
  "CheckResponseStatusV1", "PendingCheckResponseV1", "VerdictV1",
]

private let primitiveAnalysisFixtures: [PrimitiveFixtureExpectation] = [
  primitiveFixture(
    "valid-standard", "valid/standard.json", "\"standard\"\n",
    "38e4b16fcc811b134faad031ab516abbf3349d87f1e6ae4ab17ac04cc5da0213",
    .string("standard"), true),
  primitiveFixture(
    "reject-fast", "invalid/fast.json", "\"fast\"\n",
    "043407466ad7b201398096c4eeb52df5e2b40095c9a17f5ca901e9e0b01da625",
    .string("fast"), false, ["const"]),
  primitiveFixture(
    "reject-uppercase", "invalid/uppercase.json", "\"Standard\"\n",
    "c8cb1a3bab3e40df15b2a7b7ca6a64ba0be9c75e7ccd44306f4aee8282f85424",
    .string("Standard"), false, ["const"]),
  primitiveFixture(
    "reject-empty", "invalid/empty.json", "\"\"\n",
    "bd85bcdb8d4e613a79cb62d0903946ad10c83e63dc75f67614c159c0dbf4d184",
    .string(""), false, ["const"]),
  primitiveFixture(
    "reject-integer", "invalid/integer.json", "1\n",
    "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
    .number(1), false, ["type", "const"]),
  primitiveFixture(
    "reject-boolean", "invalid/boolean.json", "true\n",
    "a17fcf0a2f50e2d495e4f90ce263410edc183add6c62699a2facbccf60410f74",
    .boolean(true), false, ["type", "const"]),
  primitiveFixture(
    "reject-null", "invalid/null.json", "null\n",
    "38e0b9de817f645c4bec37c0d4a3e58baecccb040f5718dc069a72c7385a0bed",
    .null, false, ["type", "const"]),
  primitiveFixture(
    "reject-array", "invalid/array.json", "[]\n",
    "37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570",
    .array, false, ["type", "const"]),
  primitiveFixture(
    "reject-object", "invalid/object.json", "{}\n",
    "ca3d163bab055381827226140568f3bef7eaac187cebd76878e0b63e9e442356",
    .object, false, ["type", "const"]),
]

private let primitiveVersionFixtures: [PrimitiveFixtureExpectation] = [
  primitiveFixture(
    "valid-one", "valid/one.json", "1\n",
    "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
    .number(1), true),
  primitiveFixture(
    "valid-equivalent-decimal", "valid/equivalent-decimal.json", "1.0\n",
    "5717e7c840171019a4eeab5b79a7f894a4986eaff93d04ec5b12c9a189f594bf",
    .number(1), true),
  primitiveFixture(
    "reject-zero", "invalid/zero.json", "0\n",
    "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    .number(0), false, ["const"]),
  primitiveFixture(
    "reject-next-version", "invalid/next-version.json", "2\n",
    "53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3",
    .number(2), false, ["const"]),
  primitiveFixture(
    "reject-negative", "invalid/negative.json", "-1\n",
    "ee3aa64bb94a50845d5024cd4bd20202a4567aed5cd5328c0d97e9920775fc28",
    .number(-1), false, ["const"]),
  primitiveFixture(
    "reject-fractional", "invalid/fractional.json", "1.5\n",
    "03c76d47c407b24353b3121bd96490373bd6c5de05f6b3d32bd420c4810f1160",
    .number(1.5), false, ["type", "const"]),
  primitiveFixture(
    "reject-string", "invalid/string.json", "\"1\"\n",
    "ee0ce7db9ce2f1d4d2e01f0e96d73fa2399a99d825d8a9898947539a8d8e1742",
    .string("1"), false, ["type", "const"]),
  primitiveFixture(
    "reject-boolean", "invalid/boolean.json", "true\n",
    "a17fcf0a2f50e2d495e4f90ce263410edc183add6c62699a2facbccf60410f74",
    .boolean(true), false, ["type", "const"]),
  primitiveFixture(
    "reject-null", "invalid/null.json", "null\n",
    "38e0b9de817f645c4bec37c0d4a3e58baecccb040f5718dc069a72c7385a0bed",
    .null, false, ["type", "const"]),
  primitiveFixture(
    "reject-array", "invalid/array.json", "[]\n",
    "37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570",
    .array, false, ["type", "const"]),
  primitiveFixture(
    "reject-object", "invalid/object.json", "{}\n",
    "ca3d163bab055381827226140568f3bef7eaac187cebd76878e0b63e9e442356",
    .object, false, ["type", "const"]),
]

private let primitivePriorFixtureAggregateSHA256 =
  "45c53d5c5ae3f4092726eaf96fcb55d790ff4da28d7757ea62892edf415852fc"
private let primitivePriorAnalysisInvalidRawJSON = """
  {
    "schema_version": 1,
    "url": "https://analysis-profile.example.test/",
    "analysis_profile": "fast",
    "wait_budget_ms": 1200,
    "reason_schema_version": 1
  }

  """
private let primitivePriorVersionInvalidRawJSON = """
  {
    "schema_version": 1,
    "url": "https://reason-schema-version.example.test/",
    "analysis_profile": "standard",
    "wait_budget_ms": 1200,
    "reason_schema_version": 2
  }

  """

private let primitivePriorFixtureSHA256ByPath: [String: String] = [
  "invalid/analysis-profile.json":
    "7c398d6f387f1f99ab300a18fdc7b65f0f965b1f6acf3335b242ddd6e7b569de",
  "invalid/fractional-wait-budget.json":
    "d52f215c3cc8e240dad4f76ddf9d9323d1df8775b4461f6fe0fd5b51cb9b50c6",
  "invalid/missing-url.json":
    "833e7aea054b4cc1bc149a9c0f1a8602a32092bbcaab6d6cefb903e4baa4bc39",
  "invalid/negative-wait-budget.json":
    "4795e81957225d8b1631e0481a9063eb744e446f115235c26d2ce75f8854ef32",
  "invalid/non-http-url.json":
    "91eb962543d4b3224b61958ab2f1edfb501e00d9a07f341f616424a301b3a5f9",
  "invalid/oversized-wait-budget.json":
    "69bb9313ead070a8723f9b1fa88a882ccb4e164db4edc40a73e79b20b1cd0ab8",
  "invalid/reason-schema-version.json":
    "8224f73362469065a0df21d8f3d54083dcf8ecad93cd96f16537a297e096431b",
  "invalid/schema-version.json":
    "d8927929bb6333404a38264939a1658b8862a4656a97277ae4686a8f4373c142",
  "invalid/unknown-field.json":
    "1c7efe30dc909267e99386be4d969e842e2496fae3a7530c4d8e27aa39bc9323",
  "manifest.json":
    "2c5fc55fe241410d394f90362f68b04c4ba7c7e568efb4e890ee37372101fd4c",
  "valid/maximum-wait-budget.json":
    "be37c5a4c9f6581867c3358757805fab2e473e53f068115a426283a3c311fdd6",
  "valid/standard.json":
    "8eff12946ed0a4f4547beeb013a16ae698a5ae058c7ba115c475d4ac1c7aec15",
  "valid/zero-wait-budget.json":
    "81d1b6bdc68926381bb817fa38ce0e48aebdabb70b49e6449bdfcb767c2233c4",
]

private func primitiveFixture(
  _ id: String,
  _ path: String,
  _ rawJSON: String,
  _ sha256: String,
  _ payload: PrimitivePayload,
  _ expectedValid: Bool,
  _ failureKeywords: [String] = []
) -> PrimitiveFixtureExpectation {
  PrimitiveFixtureExpectation(
    id: id,
    path: path,
    rawJSON: rawJSON,
    sha256: sha256,
    payload: payload,
    expectedValid: expectedValid,
    failureKeywords: failureKeywords
  )
}

private func primitiveVerifyManifest(
  contract: PrimitiveContract,
  expectations: [PrimitiveFixtureExpectation],
  expectedManifestSHA256: String
) throws {
  let manifestData = try primitiveLoadData(contract.manifestPath)
  let manifest = try primitiveRequireObject(primitiveJSONValue(from: manifestData))
  #expect(primitiveSHA256(manifestData) == expectedManifestSHA256)
  #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
  #expect(primitiveInteger(manifest["schema_version"]) == 1)
  #expect(manifest["contract"] as? String == contract.name)
  #expect(manifest["contract_schema"] as? String == contract.manifestSchemaReference)

  let cases = try primitiveRequireObjectArray(manifest["cases"])
  #expect(cases.count == expectations.count)
  #expect(Set(cases.compactMap { $0["id"] as? String }).count == expectations.count)

  for (fixtureCase, expectation) in zip(cases, expectations) {
    #expect(fixtureCase["id"] as? String == expectation.id)
    #expect(fixtureCase["path"] as? String == expectation.path)
    #expect(fixtureCase["expected_schema_valid"] as? Bool == expectation.expectedValid)
    if expectation.expectedValid {
      #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
    } else if expectation.failureKeywords.count == 1 {
      #expect(
        Set(fixtureCase.keys)
          == ["id", "path", "expected_schema_valid", "expected_failure_keyword"]
      )
      #expect(fixtureCase["expected_failure_keyword"] as? String == expectation.failureKeywords[0])
    } else {
      #expect(
        Set(fixtureCase.keys)
          == ["id", "path", "expected_schema_valid", "expected_failure_keywords"]
      )
      #expect(
        try primitiveRequireStringArray(fixtureCase["expected_failure_keywords"])
          == expectation.failureKeywords
      )
    }

    let data = try primitiveLoadData("\(contract.fixtureRoot)/\(expectation.path)")
    #expect(data == Data(expectation.rawJSON.utf8), "Raw bytes drifted: \(expectation.id)")
    #expect(primitiveSHA256(data) == expectation.sha256, "Digest drifted: \(expectation.id)")
    let value = try primitiveJSONValue(from: data)
    #expect(expectation.payload.matches(value), "Payload purpose drifted: \(expectation.id)")
    #expect(
      try contract.failures(in: value, rawJSON: expectation.rawJSON)
        == Set(expectation.failureKeywords),
      "Failure keywords drifted: \(expectation.id)"
    )
  }

  let root = primitiveRepositoryRoot.appendingPathComponent(contract.fixtureRoot)
    .standardizedFileURL
  #expect(
    try primitiveRegularPaths(relativeTo: root)
      == Set(expectations.map(\.path) + ["manifest.json"])
  )
  #expect(
    primitiveRepositoryRoot.appendingPathComponent(contract.manifestPath)
      .deletingLastPathComponent().appendingPathComponent(contract.manifestSchemaReference)
      .standardizedFileURL
      == primitiveRepositoryRoot.appendingPathComponent(contract.schemaPath).standardizedFileURL
  )
}

private func primitiveRequireExactAnalysisSchema(_ schema: [String: Any]) throws {
  guard
    Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "const"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == primitiveAnalysisSchemaID,
    schema["title"] as? String == "Hezo Link analysis profile V1",
    schema["description"] as? String == primitiveAnalysisSchemaDescription,
    schema["type"] as? String == "string",
    schema["const"] as? String == "standard"
  else {
    throw PrimitiveAssetError.invalidAsset
  }
}

private func primitiveRequireExactVersionSchema(_ schema: [String: Any]) throws {
  guard
    Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "const"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == primitiveVersionSchemaID,
    schema["title"] as? String == "Hezo Link reason schema version V1",
    schema["description"] as? String == primitiveVersionSchemaDescription,
    schema["type"] as? String == "integer",
    primitiveInteger(schema["const"]) == 1
  else {
    throw PrimitiveAssetError.invalidAsset
  }
}

private func primitiveRequireOpenAPIReference(_ value: Any?, expected: String) throws {
  let object = try primitiveRequireObject(value)
  guard Set(object.keys) == ["$ref"], object["$ref"] as? String == expected else {
    throw PrimitiveAssetError.invalidAsset
  }
}

private func primitiveAnalysisFailures(in value: Any) -> Set<String> {
  var failures = Set<String>()
  guard let string = value as? String else {
    return ["type", "const"]
  }
  if string != "standard" {
    failures.insert("const")
  }
  return failures
}

private func primitiveVersionFailures(inJSONNumberLexeme lexeme: String) throws -> Set<String> {
  guard let decimal = PrimitiveExactDecimal(lexeme) else {
    throw PrimitiveAssetError.invalidAsset
  }
  var failures = Set<String>()
  if decimal.isInteger == false {
    failures.insert("type")
  }
  if decimal.isOne == false {
    failures.insert("const")
  }
  return failures
}

private func primitiveVersionNonnumberFailures(in value: Any) -> Set<String> {
  _ = value
  return ["type", "const"]
}

private func primitiveCheckRequestFailures(
  in value: [String: Any],
  schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> Set<String> {
  guard
    schema["$id"] as? String == "urn:hezo-link:contract:check-request:v1",
    schema["type"] as? String == "object",
    schema["additionalProperties"] as? Bool == false
  else {
    throw PrimitiveAssetError.invalidAsset
  }

  let properties = try primitiveRequireObject(schema["properties"])
  let required = Set(try primitiveRequireStringArray(schema["required"]))
  guard
    required
      == [
        "schema_version", "url", "analysis_profile", "wait_budget_ms",
        "reason_schema_version",
      ],
    Set(properties.keys) == required
  else {
    throw PrimitiveAssetError.invalidAsset
  }

  var failures = Set<String>()
  if Set(value.keys).subtracting(properties.keys).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if required.subtracting(value.keys).isEmpty == false {
    failures.insert("required")
  }

  if let candidate = value["schema_version"] {
    let fieldSchema = try primitiveRequireObject(properties["schema_version"])
    try primitiveRequireIntegerSchema(fieldSchema, constant: 1)
    failures.formUnion(primitiveIntegerConstantFailures(in: candidate, constant: 1))
  }
  if let candidate = value["url"] {
    let fieldSchema = try primitiveRequireObject(properties["url"])
    failures.formUnion(try primitiveURLFailures(in: candidate, schema: fieldSchema))
  }
  if let candidate = value["analysis_profile"] {
    let reference = try primitiveRequireObject(properties["analysis_profile"])
    let resolved = try primitiveResolve(
      reference,
      identifier: primitiveAnalysisSchemaID,
      registry: registry
    )
    try primitiveRequireExactAnalysisSchema(resolved)
    failures.formUnion(primitiveAnalysisFailures(in: candidate))
  }
  if let candidate = value["wait_budget_ms"] {
    let fieldSchema = try primitiveRequireObject(properties["wait_budget_ms"])
    failures.formUnion(try primitiveWaitBudgetFailures(in: candidate, schema: fieldSchema))
  }
  if let candidate = value["reason_schema_version"] {
    let reference = try primitiveRequireObject(properties["reason_schema_version"])
    let resolved = try primitiveResolve(
      reference,
      identifier: primitiveVersionSchemaID,
      registry: registry
    )
    try primitiveRequireExactVersionSchema(resolved)
    // These parent fixtures are individually byte-pinned and contain unambiguous integer tokens.
    // Arbitrary-precision scalar semantics are covered by the exact lexical evaluator above.
    failures.formUnion(primitiveIntegerConstantFailures(in: candidate, constant: 1))
  }
  return failures
}

private func primitiveRequireIntegerSchema(
  _ schema: [String: Any],
  constant: Int64
) throws {
  guard
    Set(schema.keys) == ["type", "const"],
    schema["type"] as? String == "integer",
    primitiveInteger(schema["const"]) == constant
  else {
    throw PrimitiveAssetError.invalidAsset
  }
}

private func primitiveIntegerConstantFailures(
  in value: Any,
  constant: Int64
) -> Set<String> {
  guard let integer = primitiveInteger(value) else {
    return ["type", "const"]
  }
  return integer == constant ? [] : ["const"]
}

private func primitiveURLFailures(
  in value: Any,
  schema: [String: Any]
) throws -> Set<String> {
  guard
    Set(schema.keys)
      == ["type", "minLength", "maxLength", "pattern", "description"],
    schema["type"] as? String == "string",
    primitiveInteger(schema["minLength"]) == 1,
    primitiveInteger(schema["maxLength"]) == 8_192,
    schema["pattern"] as? String == "^[Hh][Tt][Tt][Pp][Ss]?://",
    schema["description"] as? String
      == "Exact deliberate submission. Do not normalize or strip query or fragment. In addition to this code-point bound, reject values over 8192 UTF-8 bytes and apply the documented semantic URL policy."
  else {
    throw PrimitiveAssetError.invalidAsset
  }
  guard let string = value as? String else {
    return ["type"]
  }
  var failures = Set<String>()
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > 8_192 {
    failures.insert("maxLength")
  }
  if string.range(of: "^[Hh][Tt][Tt][Pp][Ss]?://", options: .regularExpression) == nil {
    failures.insert("pattern")
  }
  return failures
}

private func primitiveWaitBudgetFailures(
  in value: Any,
  schema: [String: Any]
) throws -> Set<String> {
  guard
    Set(schema.keys) == ["type", "minimum", "maximum", "description"],
    schema["type"] as? String == "integer",
    primitiveInteger(schema["minimum"]) == 0,
    primitiveInteger(schema["maximum"]) == 2_147_483_647,
    schema["description"] as? String
      == "Nonnegative signed 32-bit completion-wait hint, not a completion promise."
  else {
    throw PrimitiveAssetError.invalidAsset
  }
  guard let integer = primitiveInteger(value) else {
    return ["type"]
  }
  var failures = Set<String>()
  if integer < 0 {
    failures.insert("minimum")
  }
  if integer > 2_147_483_647 {
    failures.insert("maximum")
  }
  return failures
}

private func primitiveResolve(
  _ reference: [String: Any],
  identifier: String,
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  guard
    identifier.hasPrefix("urn:hezo-link:contract:"),
    Set(reference.keys) == ["$ref"],
    reference["$ref"] as? String == identifier,
    let resolved = registry[identifier],
    resolved["$id"] as? String == identifier
  else {
    throw PrimitiveAssetError.invalidAsset
  }
  return resolved
}

private func primitiveReferenceLocationsOnDisk() throws -> [String] {
  let schemaRoot =
    primitiveRepositoryRoot
    .appendingPathComponent("packages/contracts/schemas")
    .standardizedFileURL
  return try primitiveRegularPaths(relativeTo: schemaRoot)
    .filter { $0.hasSuffix(".schema.json") }
    .sorted()
    .flatMap { relativePath in
      let schema = try primitiveLoadObject("packages/contracts/schemas/\(relativePath)")
      return primitiveReferencePointers(in: schema).map { pointer in
        "\(relativePath)#\(pointer)"
      }
    }
}

private func primitiveReferencePointers(
  in value: Any,
  pointer: String = ""
) -> [String] {
  if let object = value as? [String: Any] {
    return object.keys.sorted().flatMap { key -> [String] in
      guard let child = object[key] else {
        return []
      }
      let childPointer = "\(pointer)/\(primitivePointerSegment(key))"
      var pointers = [String]()
      if key == "$ref",
        let reference = child as? String,
        reference == primitiveAnalysisSchemaID || reference == primitiveVersionSchemaID
      {
        pointers.append(childPointer)
      }
      pointers.append(contentsOf: primitiveReferencePointers(in: child, pointer: childPointer))
      return pointers
    }
  }
  if let array = value as? [Any] {
    return array.enumerated().flatMap { index, child in
      primitiveReferencePointers(in: child, pointer: "\(pointer)/\(index)")
    }
  }
  return []
}

private func primitivePointerSegment(_ value: String) -> String {
  value.replacingOccurrences(of: "~", with: "~0")
    .replacingOccurrences(of: "/", with: "~1")
}

private func primitivePriorFixtureAggregate(paths: [String], root: URL) throws -> String {
  var aggregate = SHA256()
  for path in paths {
    let data = try Data(contentsOf: root.appendingPathComponent(path))
    let record = "\(primitiveSHA256(data))  \(primitivePriorFixtureRoot)/\(path)\n"
    aggregate.update(data: Data(record.utf8))
  }
  return primitiveHex(aggregate.finalize())
}

private func primitiveDeclaredKeywords(in fixtureCase: [String: Any]) throws -> Set<String> {
  guard let expectedValid = fixtureCase["expected_schema_valid"] as? Bool else {
    throw PrimitiveAssetError.invalidAsset
  }
  if expectedValid {
    guard
      fixtureCase["expected_failure_keyword"] == nil,
      fixtureCase["expected_failure_keywords"] == nil
    else {
      throw PrimitiveAssetError.invalidAsset
    }
    return []
  }
  if let keyword = fixtureCase["expected_failure_keyword"] as? String {
    guard fixtureCase["expected_failure_keywords"] == nil else {
      throw PrimitiveAssetError.invalidAsset
    }
    return [keyword]
  }
  return Set(try primitiveRequireStringArray(fixtureCase["expected_failure_keywords"]))
}

private func primitiveLoadObject(_ path: String) throws -> [String: Any] {
  try primitiveRequireObject(primitiveJSONValue(from: primitiveLoadData(path)))
}

private func primitiveLoadData(_ path: String) throws -> Data {
  let URL = primitiveRepositoryRoot.appendingPathComponent(path).standardizedFileURL
  guard URL.path.hasPrefix(primitiveRepositoryRoot.path + "/") else {
    throw PrimitiveAssetError.unreadableAsset
  }
  do {
    return try Data(contentsOf: URL)
  } catch {
    throw PrimitiveAssetError.unreadableAsset
  }
}

private func primitiveJSONValue(from data: Data) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  } catch {
    throw PrimitiveAssetError.invalidAsset
  }
}

private func primitiveRequireObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw PrimitiveAssetError.invalidAsset
  }
  return object
}

private func primitiveRequireObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let array = value as? [[String: Any]] else {
    throw PrimitiveAssetError.invalidAsset
  }
  return array
}

private func primitiveRequireString(_ value: Any?) throws -> String {
  guard let string = value as? String else {
    throw PrimitiveAssetError.invalidAsset
  }
  return string
}

private func primitiveRequireStringArray(_ value: Any?) throws -> [String] {
  guard let array = value as? [String] else {
    throw PrimitiveAssetError.invalidAsset
  }
  return array
}

private func primitiveInteger(_ value: Any?) -> Int64? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID()
  else {
    return nil
  }
  let double = number.doubleValue
  guard double.isFinite, double.rounded(.towardZero) == double else {
    return nil
  }
  return Int64(exactly: double)
}

private func primitiveRegularPaths(relativeTo root: URL) throws -> Set<String> {
  let rootValues = try root.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
  guard rootValues.isDirectory == true, rootValues.isSymbolicLink == false,
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
      options: []
    )
  else {
    throw PrimitiveAssetError.unreadableAsset
  }

  var paths = Set<String>()
  for case let URL as URL in enumerator {
    let values = try URL.resourceValues(
      forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
    )
    guard values.isSymbolicLink == false else {
      throw PrimitiveAssetError.invalidAsset
    }
    if values.isDirectory == true {
      continue
    }
    guard values.isRegularFile == true, URL.path.hasPrefix(root.path + "/") else {
      throw PrimitiveAssetError.invalidAsset
    }
    paths.insert(String(URL.path.dropFirst(root.path.count + 1)))
  }
  return paths
}

private func primitiveSHA256(_ data: Data) -> String {
  primitiveHex(SHA256.hash(data: data))
}

private func primitiveHex<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
  bytes.map { String(format: "%02x", $0) }.joined()
}

private func primitiveRequireAnalysisConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Codable & Equatable & Hashable & Sendable,
  Value.RawValue == String
{
  _ = value
}

private func primitiveRequireVersionConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Encodable & Equatable & Hashable & Sendable,
  Value.RawValue == Int
{
  _ = value
}

private func primitiveVerifyProfileDecodeFailure(
  _ expectation: PrimitiveFixtureExpectation
) throws {
  let data = try primitiveLoadData(
    "packages/contracts/fixtures/analysis-profile-v1/\(expectation.path)"
  )
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(AnalysisProfileV1.self, from: data)
    Issue.record("Invalid analysis-profile fixture was accepted: \(expectation.id)")
  } catch let error as DecodingError {
    let context: DecodingError.Context
    switch (expectation.payload, error) {
    case (.string, .dataCorrupted(let decodedContext)):
      context = decodedContext
      #expect(context.debugDescription == "Invalid analysis profile.")
    case (.number, .typeMismatch(let type, let decodedContext)):
      context = decodedContext
      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(context.debugDescription == "Expected to decode String but found number instead.")
    case (.boolean, .typeMismatch(let type, let decodedContext)):
      context = decodedContext
      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(context.debugDescription == "Expected to decode String but found bool instead.")
    case (.array, .typeMismatch(let type, let decodedContext)):
      context = decodedContext
      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(context.debugDescription == "Expected to decode String but found an array instead.")
    case (.object, .typeMismatch(let type, let decodedContext)):
      context = decodedContext
      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(
        context.debugDescription == "Expected to decode String but found a dictionary instead.")
    case (.null, .valueNotFound(let type, let decodedContext)):
      context = decodedContext
      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(
        context.debugDescription
          == "Cannot get value of type String -- found null value instead"
      )
    default:
      Issue.record("Unexpected AnalysisProfileV1 error category: \(expectation.id)")
      return
    }
    #expect(context.codingPath.isEmpty)
    #expect(context.underlyingError == nil)
    let renderings = [String(describing: error), String(reflecting: error)]
    #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 512 })
    if case .string(let candidate) = expectation.payload, candidate.isEmpty == false {
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    }
  } catch {
    Issue.record("Unexpected AnalysisProfileV1 error type: \(expectation.id)")
  }
}
