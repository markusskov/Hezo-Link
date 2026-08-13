import CoreFoundation
import Foundation
import Testing

@testable import HezoLinkCore

struct RequestIDContractAssetTests {
  @Test func schemaAndOpenAPIFreezeTheStandaloneRequestIDSurface() throws {
    let openAPI = try loadRequestIDObject(requestIDOpenAPIPath)
    let schema = try loadRequestIDObject(requestIDSchemaPath)

    #expect(
      Set(openAPI.keys)
        == ["openapi", "info", "jsonSchemaDialect", "paths", "components"]
    )
    #expect(openAPI["openapi"] as? String == "3.1.0")
    #expect(
      openAPI["jsonSchemaDialect"] as? String
        == "https://json-schema.org/draft/2020-12/schema"
    )
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let info = try requireRequestIDObject(openAPI["info"])
    #expect(Set(info.keys) == ["title", "version", "description"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.11.0")
    #expect(info["description"] as? String == requestIDOpenAPIDescription)

    let components = try requireRequestIDObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireRequestIDObject(components["schemas"])
    #expect(Set(schemas.keys) == requestIDExpectedOpenAPIComponents)
    #expect(schemas.count == 16)

    let component = try requireRequestIDObject(schemas["RequestIDV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == requestIDOpenAPIReference)

    let openAPIURL = requestIDRepositoryRoot.appendingPathComponent(requestIDOpenAPIPath)
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(requestIDOpenAPIReference)
      .standardizedFileURL
    let schemaURL = requestIDRepositoryRoot.appendingPathComponent(requestIDSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    try requireExactRequestIDSchemaSurface(schema)
    #expect(RequestIDV1.minimumByteCount == 1)
    #expect(RequestIDV1.maximumByteCount == 128)
  }

  @Test func bothParentContractsResolveTheExactAbsoluteRequestIDReference() throws {
    let requestIDSchema = try loadRequestIDObject(requestIDSchemaPath)
    let registry = [requestIDSchemaID: requestIDSchema]

    for parentPath in [requestIDProblemSchemaPath, requestIDPendingSchemaPath] {
      let parent = try loadRequestIDObject(parentPath)
      let properties = try requireRequestIDObject(parent["properties"])
      let referenceObject = try requireRequestIDObject(properties["request_id"])
      #expect(Set(referenceObject.keys) == ["$ref"])
      let reference = try requireRequestIDString(referenceObject["$ref"])
      #expect(reference == requestIDSchemaID)

      let resolved = try #require(registry[reference])
      try requireExactRequestIDSchemaSurface(resolved)
      #expect(resolved["$id"] as? String == reference)
    }
  }

  @Test func manifestPinsTheExactElevenCaseMapAndDiskInventory() throws {
    let manifest = try loadRequestIDObject(requestIDManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(requestIDIntegerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "request-id-v1")
    #expect(manifest["contract_schema"] as? String == requestIDManifestSchemaReference)

    let cases = try requireRequestIDObjectArray(manifest["cases"])
    #expect(cases.count == requestIDFixtureExpectations.count)
    #expect(cases.count == 11)

    for (fixtureCase, expectation) in zip(cases, requestIDFixtureExpectations) {
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
        #expect(
          fixtureCase["expected_failure_keyword"] as? String
            == expectation.failureKeywords[0]
        )
      } else {
        #expect(
          Set(fixtureCase.keys)
            == ["id", "path", "expected_schema_valid", "expected_failure_keywords"]
        )
        #expect(
          try requireRequestIDStringArray(fixtureCase["expected_failure_keywords"])
            == expectation.failureKeywords
        )
      }
    }

    let ids = try cases.map { try requireRequestIDString($0["id"]) }
    let paths = try cases.map { try requireRequestIDString($0["path"]) }
    #expect(ids == requestIDFixtureExpectations.map(\.id))
    #expect(Set(ids).count == ids.count)
    #expect(paths == requestIDFixtureExpectations.map(\.path))
    #expect(Set(paths).count == paths.count)

    let fixtureRoot = requestIDRepositoryRoot.appendingPathComponent(requestIDFixtureRoot)
      .standardizedFileURL
    #expect(try requestIDFixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = requestIDRepositoryRoot.appendingPathComponent(requestIDManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(requestIDManifestSchemaReference)
      .standardizedFileURL
    let schemaURL = requestIDRepositoryRoot.appendingPathComponent(requestIDSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyFixturePinsItsRawScalarBytesPurposeAndExactKeywordSet() throws {
    let schema = try loadRequestIDObject(requestIDSchemaPath)
    try requireExactRequestIDSchemaSurface(schema)

    for expectation in requestIDFixtureExpectations {
      let relativePath = "\(requestIDFixtureRoot)/\(expectation.path)"
      let data = try loadRequestIDData(relativePath)
      #expect(
        data == Data(expectation.rawJSON.utf8),
        "RequestID V1 raw fixture bytes drifted: \(expectation.id)"
      )

      let value = try requestIDJSONValue(from: data)
      #expect(
        expectation.payload.matches(value),
        "RequestID V1 fixture payload drifted: \(expectation.id)"
      )
      #expect(
        requestIDSchemaFailures(in: value) == Set(expectation.failureKeywords),
        "RequestID V1 schema keyword set drifted: \(expectation.id)"
      )
    }
  }

  @Test func independentEvaluatorRejectsAnyWidenedSchemaSurface() throws {
    let schema = try loadRequestIDObject(requestIDSchemaPath)
    try requireExactRequestIDSchemaSurface(schema)

    for mutation in RequestIDSchemaMutation.allCases {
      var mutated = schema
      mutation.apply(to: &mutated)
      #expect(throws: RequestIDContractAssetTestError.self) {
        try requireExactRequestIDSchemaSurface(mutated)
      }
    }
  }

  @Test func validFixturesRoundTripThroughTheSwiftValueWithoutWireDrift() throws {
    var validCount = 0

    for expectation in requestIDFixtureExpectations where expectation.expectedValid {
      validCount += 1
      let relativePath = "\(requestIDFixtureRoot)/\(expectation.path)"
      let expectedString = try expectation.payload.requireString()
      let decoded = try HezoJSON.makeResponseDecoder().decode(
        RequestIDV1.self,
        from: loadRequestIDData(relativePath)
      )
      let encoded = try HezoJSON.makeEncoder().encode(decoded)

      #expect(decoded.rawValue == expectedString)
      #expect(try RequestIDV1(validating: expectedString) == decoded)
      #expect(RequestIDV1(rawValue: expectedString) == decoded)
      #expect(encoded == Data(expectation.rawJSON.dropLast().utf8))
      #expect(try requestIDJSONValue(from: encoded) as? String == expectedString)
    }

    #expect(validCount == 3)
  }

  @Test func invalidFixturesFailSwiftDecodingAndNeverEchoRejectedStrings() throws {
    var invalidCount = 0

    for expectation in requestIDFixtureExpectations where expectation.expectedValid == false {
      invalidCount += 1
      let relativePath = "\(requestIDFixtureRoot)/\(expectation.path)"
      let data = try loadRequestIDData(relativePath)

      do {
        _ = try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: data)
        Issue.record("A declared invalid RequestID V1 fixture was accepted: \(expectation.id)")
      } catch let error as DecodingError {
        let renderings = requestIDErrorRenderings(error)
        #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 256 })
      } catch {
        Issue.record("RequestID V1 decoding used an unexpected error category: \(expectation.id)")
      }

      guard case .string(let candidate) = expectation.payload else {
        continue
      }
      let expectedError = try #require(expectation.validationError)
      #expect(throws: expectedError) {
        try RequestIDV1(validating: candidate)
      }
      #expect(RequestIDV1(rawValue: candidate) == nil)
    }

    #expect(invalidCount == 8)

    let privateCandidate = "PRIVATE_REQUEST_ID_FIXTURE_CANARY/67A9"
    let privateData = try JSONEncoder().encode(privateCandidate)
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(RequestIDV1.self, from: privateData)
      Issue.record("A private invalid RequestID V1 canary was accepted.")
    } catch let error as DecodingError {
      #expect(requestIDErrorRenderings(error).allSatisfy { $0.contains(privateCandidate) == false })
    } catch {
      Issue.record("Private RequestID V1 canary decoding used an unexpected error category.")
    }
  }

  @Test func SwiftDescriptionDebugReflectionAndErrorsStayRedacted() throws {
    let candidate = "PRIVATE_REQUEST_ID_CANARY_67A9"
    let value = try RequestIDV1(validating: candidate)
    let mirrorChildren = Array(value.customMirror.children)
    let valueRenderings =
      [
        value.description,
        value.debugDescription,
        String(describing: value),
        String(reflecting: value),
      ] + mirrorChildren.map { String(describing: $0.value) }

    #expect(valueRenderings.allSatisfy { $0.contains(candidate) == false })
    #expect(value.description == "<redacted-request-id>")
    #expect(value.debugDescription == value.description)
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(mirrorChildren.first?.value as? String == "<redacted-request-id>")

    for error in [
      RequestIDContractError.empty,
      RequestIDContractError.tooLong,
      RequestIDContractError.invalidFormat,
    ] {
      let renderings = requestIDErrorRenderings(error)
      #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
      #expect(renderings.allSatisfy { $0.contains(candidate) == false })
      #expect(error.debugDescription == error.description)
      #expect(error.errorDescription == error.description)
      #expect(Mirror(reflecting: error).children.isEmpty)
    }
  }

  @Test func contractDocumentationKeepsTheWireOnlyNonclaimsExplicit() throws {
    let readmeData = try loadRequestIDData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(requestIDGrammarSentence))
    #expect(readme.contains(requestIDNonclaimSentence))
    #expect(readme.contains(requestIDExplicitExclusionsSentence))

    let schema = try loadRequestIDObject(requestIDSchemaPath)
    #expect(schema["description"] as? String == requestIDSchemaDescription)

    let openAPI = try loadRequestIDObject(requestIDOpenAPIPath)
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
  }
}

private enum RequestIDContractAssetTestError: Error {
  case invalidAsset
  case unreadableAsset
}

private struct RequestIDFixtureExpectation: Sendable {
  let id: String
  let path: String
  let rawJSON: String
  let payload: RequestIDFixturePayload
  let expectedValid: Bool
  let failureKeywords: [String]
  let validationError: RequestIDContractError?
}

private enum RequestIDFixturePayload: Sendable {
  case string(String)
  case null
  case boolean(Bool)

  func matches(_ value: Any) -> Bool {
    switch self {
    case .string(let expected):
      return value as? String == expected
    case .null:
      return value is NSNull
    case .boolean(let expected):
      guard let number = value as? NSNumber,
        CFGetTypeID(number) == CFBooleanGetTypeID()
      else {
        return false
      }
      return number.boolValue == expected
    }
  }

  func requireString() throws -> String {
    guard case .string(let value) = self else {
      throw RequestIDContractAssetTestError.invalidAsset
    }
    return value
  }
}

private enum RequestIDSchemaMutation: CaseIterable {
  case missingMinimum
  case widenedMaximum
  case optionalEmptyPattern
  case nonStringType
  case mismatchedIdentifier

  func apply(to schema: inout [String: Any]) {
    switch self {
    case .missingMinimum:
      schema.removeValue(forKey: "minLength")
    case .widenedMaximum:
      schema["maxLength"] = 129
    case .optionalEmptyPattern:
      schema["pattern"] = "^[A-Za-z0-9_-]*$"
    case .nonStringType:
      schema["type"] = ["string", "null"]
    case .mismatchedIdentifier:
      schema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    }
  }
}

private let requestIDRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let requestIDOpenAPIPath = "packages/contracts/openapi-components.json"
private let requestIDSchemaPath = "packages/contracts/schemas/request-id-v1.schema.json"
private let requestIDProblemSchemaPath = "packages/contracts/schemas/problem-v1.schema.json"
private let requestIDPendingSchemaPath =
  "packages/contracts/schemas/pending-check-response-v1.schema.json"
private let requestIDFixtureRoot = "packages/contracts/fixtures/request-id-v1"
private let requestIDManifestPath = "\(requestIDFixtureRoot)/manifest.json"
private let requestIDManifestSchemaReference = "../../schemas/request-id-v1.schema.json"
private let requestIDOpenAPIReference = "./schemas/request-id-v1.schema.json"
private let requestIDSchemaID = "urn:hezo-link:contract:request-id:v1"
private let requestIDPattern = "^[A-Za-z0-9_-]+$"
private let requestIDSchemaDescription =
  "Strict standalone bounded ASCII request identifier shape. This schema validates structure only and proves no entropy, authority, lifetime, retention or logging permission, or cross-plane identity."
private let requestIDOpenAPIDescription =
  "Reusable offline check-input, check-request leaf-primitive, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
private let requestIDGrammarSentence =
  "`RequestIDV1` is a string containing one through 128 ASCII letters, digits, `_`, or `-`. Its ASCII grammar makes the schema's code-point bounds equal its UTF-8 byte bounds. Problem V1 and Pending Check Response V1 use the same absolute standalone schema reference for their `request_id` member without widening this accepted language."
private let requestIDNonclaimSentence =
  "`RequestIDV1` is a strict standalone bounded ASCII shape only. Acceptance proves no entropy, uniqueness, authority, lifetime, retention or logging permission, or cross-plane identity."
private let requestIDExplicitExclusionsSentence =
  "These artifacts contain only request, check-request analysis-profile and reason-schema-version, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, verdict-reason, and standalone verdict-supporting shapes with reserved or synthetic examples. They define no endpoint, deployment, HTTP or polling behavior, token or request-ID issuance or entropy proof, authority, profile negotiation, collector set, completeness, clock, freshness, TTL, lifetime, retention or logging permission, storage, persistence, network or other I/O behavior, cross-plane identity, complete check-response envelope, completed-response analysis or versions object, completed-response or report semantics, automatic block eligibility, or unrelated product data. All fixture hosts use the reserved `.test` namespace and are intended for offline validation only."

private let requestIDExpectedOpenAPIComponents: Set<String> = [
  "CheckRequestV1", "AnalysisProfileV1", "ReasonSchemaVersionV1", "RequestIDV1",
  "CanonicalInstantV1", "ProblemV1", "VerdictReasonV1", "VerdictLabelV1",
  "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1", "VerdictReasonsV1",
  "CheckResponseStatusV1", "CheckTokenV1", "PendingCheckResponseV1", "VerdictV1",
]

private let requestIDFixtureExpectations: [RequestIDFixtureExpectation] = [
  RequestIDFixtureExpectation(
    id: "valid-lower-boundary",
    path: "valid/lower-boundary.json",
    rawJSON: "\"a\"\n",
    payload: .string("a"),
    expectedValid: true,
    failureKeywords: [],
    validationError: nil
  ),
  RequestIDFixtureExpectation(
    id: "valid-upper-boundary",
    path: "valid/upper-boundary.json",
    rawJSON: "\"\(String(repeating: "R", count: 128))\"\n",
    payload: .string(String(repeating: "R", count: 128)),
    expectedValid: true,
    failureKeywords: [],
    validationError: nil
  ),
  RequestIDFixtureExpectation(
    id: "valid-complete-alphabet",
    path: "valid/complete-alphabet.json",
    rawJSON: "\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-\"\n",
    payload: .string("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"),
    expectedValid: true,
    failureKeywords: [],
    validationError: nil
  ),
  RequestIDFixtureExpectation(
    id: "reject-empty",
    path: "invalid/empty.json",
    rawJSON: "\"\"\n",
    payload: .string(""),
    expectedValid: false,
    failureKeywords: ["minLength", "pattern"],
    validationError: .empty
  ),
  RequestIDFixtureExpectation(
    id: "reject-oversized",
    path: "invalid/oversized.json",
    rawJSON: "\"\(String(repeating: "R", count: 129))\"\n",
    payload: .string(String(repeating: "R", count: 129)),
    expectedValid: false,
    failureKeywords: ["maxLength"],
    validationError: .tooLong
  ),
  RequestIDFixtureExpectation(
    id: "reject-punctuation",
    path: "invalid/punctuation.json",
    rawJSON: "\"request.id\"\n",
    payload: .string("request.id"),
    expectedValid: false,
    failureKeywords: ["pattern"],
    validationError: .invalidFormat
  ),
  RequestIDFixtureExpectation(
    id: "reject-whitespace",
    path: "invalid/whitespace.json",
    rawJSON: "\"request id\"\n",
    payload: .string("request id"),
    expectedValid: false,
    failureKeywords: ["pattern"],
    validationError: .invalidFormat
  ),
  RequestIDFixtureExpectation(
    id: "reject-control",
    path: "invalid/control.json",
    rawJSON: "\"request\\u0000id\"\n",
    payload: .string("request\u{0000}id"),
    expectedValid: false,
    failureKeywords: ["pattern"],
    validationError: .invalidFormat
  ),
  RequestIDFixtureExpectation(
    id: "reject-non-ascii",
    path: "invalid/non-ascii.json",
    rawJSON: "\"request-é\"\n",
    payload: .string("request-é"),
    expectedValid: false,
    failureKeywords: ["pattern"],
    validationError: .invalidFormat
  ),
  RequestIDFixtureExpectation(
    id: "reject-null",
    path: "invalid/null.json",
    rawJSON: "null\n",
    payload: .null,
    expectedValid: false,
    failureKeywords: ["type"],
    validationError: nil
  ),
  RequestIDFixtureExpectation(
    id: "reject-wrong-type",
    path: "invalid/wrong-type.json",
    rawJSON: "true\n",
    payload: .boolean(true),
    expectedValid: false,
    failureKeywords: ["type"],
    validationError: nil
  ),
]

private func requireExactRequestIDSchemaSurface(_ schema: [String: Any]) throws {
  guard
    Set(schema.keys)
      == ["$schema", "$id", "title", "description", "type", "minLength", "maxLength", "pattern"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == requestIDSchemaID,
    schema["title"] as? String == "Hezo Link request ID V1",
    schema["description"] as? String == requestIDSchemaDescription,
    schema["type"] as? String == "string",
    requestIDIntegerValue(schema["minLength"]) == 1,
    requestIDIntegerValue(schema["maxLength"]) == 128,
    schema["pattern"] as? String == requestIDPattern
  else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
}

// This intentionally evaluates only the frozen RequestID V1 scalar grammar. It is independent of
// JSON Schema tooling and is not a general Draft 2020-12 evaluator.
private func requestIDSchemaFailures(in value: Any) -> Set<String> {
  guard let string = value as? String else {
    return ["type"]
  }

  var failures = Set<String>()
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
  }
  if string.isEmpty || string.utf8.allSatisfy(isAllowedRequestIDContractByte) == false {
    failures.insert("pattern")
  }
  return failures
}

private func isAllowedRequestIDContractByte(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
    || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
}

private func loadRequestIDObject(_ relativePath: String) throws -> [String: Any] {
  try requireRequestIDObject(requestIDJSONValue(from: loadRequestIDData(relativePath)))
}

private func loadRequestIDData(_ relativePath: String) throws -> Data {
  let url = requestIDRepositoryRoot.appendingPathComponent(relativePath).standardizedFileURL
  guard url.path.hasPrefix(requestIDRepositoryRoot.path + "/") else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
  do {
    return try Data(contentsOf: url)
  } catch {
    throw RequestIDContractAssetTestError.unreadableAsset
  }
}

private func requestIDJSONValue(from data: Data) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  } catch {
    throw RequestIDContractAssetTestError.invalidAsset
  }
}

private func requireRequestIDObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
  return object
}

private func requireRequestIDObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let objects = value as? [[String: Any]] else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
  return objects
}

private func requireRequestIDString(_ value: Any?) throws -> String {
  guard let string = value as? String else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
  return string
}

private func requireRequestIDStringArray(_ value: Any?) throws -> [String] {
  guard let strings = value as? [String] else {
    throw RequestIDContractAssetTestError.invalidAsset
  }
  return strings
}

private func requestIDIntegerValue(_ value: Any?) -> Int64? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID()
  else {
    return nil
  }
  let integer = number.int64Value
  return number.doubleValue == Double(integer) ? integer : nil
}

private func requestIDFixturePathsOnDisk(relativeTo fixtureRoot: URL) throws -> Set<String> {
  guard
    let enumerator = FileManager.default.enumerator(
      at: fixtureRoot,
      includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
  else {
    throw RequestIDContractAssetTestError.unreadableAsset
  }

  var paths = Set<String>()
  for case let fileURL as URL in enumerator {
    let values = try fileURL.resourceValues(
      forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
    guard values.isSymbolicLink == false else {
      throw RequestIDContractAssetTestError.invalidAsset
    }
    guard values.isRegularFile == true, fileURL.lastPathComponent != "manifest.json" else {
      continue
    }
    guard fileURL.path.hasPrefix(fixtureRoot.path + "/") else {
      throw RequestIDContractAssetTestError.invalidAsset
    }
    paths.insert(String(fileURL.path.dropFirst(fixtureRoot.path.count + 1)))
  }
  return paths
}

private func requestIDErrorRenderings(_ error: any Error) -> [String] {
  let nsError = error as NSError
  return [
    String(describing: error),
    String(reflecting: error),
    error.localizedDescription,
    nsError.localizedDescription,
  ]
}
