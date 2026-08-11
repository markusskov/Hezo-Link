import CoreFoundation
import Foundation
import Testing

struct CheckRequestContractAssetTests {
  @Test func contractDocumentsKeepTheFrozenShapeAndReference() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject("packages/contracts/schemas/check-request-v1.schema.json")

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

    let info = try requireObject(openAPI["info"])
    #expect(Set(info.keys) == ["title", "version", "description"])
    #expect(info["title"] as? String == "Hezo Link check-input components")
    #expect(info["version"] as? String == "1.0.0")
    #expect(try requireString(info["description"]).isEmpty == false)

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == ["CheckRequestV1"])
    let checkRequest = try requireObject(schemas["CheckRequestV1"])
    #expect(Set(checkRequest.keys) == ["$ref"])
    #expect(checkRequest["$ref"] as? String == "./schemas/check-request-v1.schema.json")

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent("schemas/check-request-v1.schema.json")
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/check-request-v1.schema.json"
    ).standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(
      Set(schema.keys)
        == [
          "$schema", "$id", "title", "description", "type", "additionalProperties",
          "required", "properties",
        ]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == "urn:hezo-link:contract:check-request:v1")
    #expect(schema["title"] as? String == "Hezo Link check request V1")
    #expect(try requireString(schema["description"]).isEmpty == false)
    #expect(schema["type"] as? String == "object")
    #expect(try requireBool(schema["additionalProperties"]) == false)

    let expectedProperties: Set<String> = [
      "schema_version", "url", "analysis_profile", "wait_budget_ms",
      "reason_schema_version",
    ]
    let required = try requireStringArray(schema["required"])
    #expect(required.count == expectedProperties.count)
    #expect(Set(required) == expectedProperties)

    let properties = try requireObject(schema["properties"])
    #expect(Set(properties.keys) == expectedProperties)
    try expectIntegerConstant(properties["schema_version"], constant: 1)
    try expectIntegerConstant(properties["reason_schema_version"], constant: 1)

    let analysisProfile = try requireObject(properties["analysis_profile"])
    #expect(Set(analysisProfile.keys) == ["type", "const"])
    #expect(analysisProfile["type"] as? String == "string")
    #expect(analysisProfile["const"] as? String == "standard")

    let waitBudget = try requireObject(properties["wait_budget_ms"])
    #expect(Set(waitBudget.keys) == ["type", "minimum", "maximum", "description"])
    #expect(waitBudget["type"] as? String == "integer")
    #expect(integerValue(waitBudget["minimum"]) == 0)
    #expect(integerValue(waitBudget["maximum"]) == 2_147_483_647)
    #expect(try requireString(waitBudget["description"]).isEmpty == false)

    let url = try requireObject(properties["url"])
    #expect(
      Set(url.keys) == ["type", "minLength", "maxLength", "pattern", "description"]
    )
    #expect(url["type"] as? String == "string")
    #expect(integerValue(url["minLength"]) == 1)
    #expect(integerValue(url["maxLength"]) == 8_192)
    #expect(url["pattern"] as? String == "^[Hh][Tt][Tt][Pp][Ss]?://")
    #expect(try requireString(url["description"]).isEmpty == false)
  }

  @Test func manifestHasCompleteUniqueFixtureCoverage() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/check-request-v1/manifest.json"
    )
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "check-request-v1")
    #expect(manifest["contract_schema"] as? String == "../../schemas/check-request-v1.schema.json")

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == 12)

    let expectedIDs: Set<String> = [
      "valid-standard",
      "valid-zero-wait-budget",
      "valid-maximum-wait-budget",
      "reject-unknown-field",
      "reject-missing-url",
      "reject-schema-version",
      "reject-analysis-profile",
      "reject-negative-wait-budget",
      "reject-fractional-wait-budget",
      "reject-oversized-wait-budget",
      "reject-reason-schema-version",
      "reject-non-http-url",
    ]
    let expectedPaths: Set<String> = [
      "valid/standard.json",
      "valid/zero-wait-budget.json",
      "valid/maximum-wait-budget.json",
      "invalid/unknown-field.json",
      "invalid/missing-url.json",
      "invalid/schema-version.json",
      "invalid/analysis-profile.json",
      "invalid/negative-wait-budget.json",
      "invalid/fractional-wait-budget.json",
      "invalid/oversized-wait-budget.json",
      "invalid/reason-schema-version.json",
      "invalid/non-http-url.json",
    ]
    let ids = try cases.map { try requireString($0["id"]) }
    let paths = try cases.map { try requireString($0["path"]) }
    #expect(Set(ids) == expectedIDs)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths) == expectedPaths)
    #expect(Set(paths).count == paths.count)

    let fixtureRoot = repositoryRoot.appendingPathComponent(
      "packages/contracts/fixtures/check-request-v1"
    ).standardizedFileURL
    let listedFixtureURLs = paths.map {
      fixtureRoot.appendingPathComponent($0).standardizedFileURL
    }
    #expect(
      listedFixtureURLs.allSatisfy {
        $0.path.hasPrefix(fixtureRoot.path + "/")
          && FileManager.default.fileExists(atPath: $0.path)
      }
    )
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == expectedPaths)

    let manifestURL = fixtureRoot.appendingPathComponent("manifest.json")
    let contractSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent("../../schemas/check-request-v1.schema.json")
      .standardizedFileURL
    let expectedSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/check-request-v1.schema.json"
    ).standardizedFileURL
    #expect(contractSchemaURL == expectedSchemaURL)
  }

  @Test func everyFixtureMatchesItsDeclaredSchemaExpectation() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/check-request-v1/manifest.json"
    )
    let cases = try requireObjectArray(manifest["cases"])
    let fixtureRoot = "packages/contracts/fixtures/check-request-v1"
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let allowedKeys: Set<String> = [
        "id", "path", "expected_schema_valid", "expected_failure_keyword",
      ]
      #expect(Set(fixtureCase.keys).isSubset(of: allowedKeys))
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadObject("\(fixtureRoot)/\(relativePath)")
      let failures = checkRequestSchemaFailures(in: fixture)
      let fixturePayloadMatchesPurpose = try fixtureMatchesExpectedPurpose(
        id: fixtureID,
        object: fixture
      )
      #expect(fixturePayloadMatchesPurpose)

      if expectedValid {
        validCount += 1
        #expect(fixtureCase["expected_failure_keyword"] == nil)
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeyword = try requireString(fixtureCase["expected_failure_keyword"])
        #expect(failures == [expectedKeyword])
      }
    }

    #expect(validCount == 3)
    #expect(invalidCount == 9)
  }
}

private enum ContractAssetTestError: Error {
  case invalidAsset
  case unreadableAsset
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func loadObject(_ relativePath: String) throws -> [String: Any] {
  let data: Data
  do {
    data = try Data(contentsOf: repositoryRoot.appendingPathComponent(relativePath))
  } catch {
    throw ContractAssetTestError.unreadableAsset
  }

  do {
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ContractAssetTestError.invalidAsset
    }
    return object
  } catch is ContractAssetTestError {
    throw ContractAssetTestError.invalidAsset
  } catch {
    throw ContractAssetTestError.invalidAsset
  }
}

private func requireObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw ContractAssetTestError.invalidAsset
  }
  return object
}

private func requireObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let objects = value as? [[String: Any]] else {
    throw ContractAssetTestError.invalidAsset
  }
  return objects
}

private func requireStringArray(_ value: Any?) throws -> [String] {
  guard let strings = value as? [String] else {
    throw ContractAssetTestError.invalidAsset
  }
  return strings
}

private func requireString(_ value: Any?) throws -> String {
  guard let string = value as? String else {
    throw ContractAssetTestError.invalidAsset
  }
  return string
}

private func requireBool(_ value: Any?) throws -> Bool {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) == CFBooleanGetTypeID()
  else {
    throw ContractAssetTestError.invalidAsset
  }
  return number.boolValue
}

private func expectIntegerConstant(_ value: Any?, constant: Int64) throws {
  let object = try requireObject(value)
  #expect(Set(object.keys) == ["type", "const"])
  #expect(object["type"] as? String == "integer")
  #expect(integerValue(object["const"]) == constant)
}

private func integerValue(_ value: Any?) -> Int64? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID(),
    number.doubleValue.isFinite,
    number.doubleValue.rounded(.towardZero) == number.doubleValue
  else {
    return nil
  }
  return number.int64Value
}

private func fixturePathsOnDisk(relativeTo fixtureRoot: URL) throws -> Set<String> {
  var paths = Set<String>()
  for directory in ["valid", "invalid"] {
    let directoryURL = fixtureRoot.appendingPathComponent(directory)
    guard
      let enumerator = FileManager.default.enumerator(
        at: directoryURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else {
      throw ContractAssetTestError.unreadableAsset
    }
    for case let url as URL in enumerator where url.pathExtension == "json" {
      let relativeStart = directoryURL.path.count + 1
      let nestedPath = String(url.path.dropFirst(relativeStart))
      paths.insert("\(directory)/\(nestedPath)")
    }
  }
  return paths
}

private func fixtureMatchesExpectedPurpose(
  id: String,
  object: [String: Any]
) throws -> Bool {
  let expected: String
  switch id {
  case "valid-standard":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://example.test/path?opaque=value#route","wait_budget_ms":1200}"#
  case "valid-zero-wait-budget":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"http://zero-wait.example.test/","wait_budget_ms":0}"#
  case "valid-maximum-wait-budget":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://maximum-wait.example.test/","wait_budget_ms":2147483647}"#
  case "reject-unknown-field":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"source_application":"synthetic","url":"https://unknown-field.example.test/","wait_budget_ms":1200}"#
  case "reject-missing-url":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"wait_budget_ms":1200}"#
  case "reject-schema-version":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":2,"url":"https://schema-version.example.test/","wait_budget_ms":1200}"#
  case "reject-analysis-profile":
    expected =
      #"{"analysis_profile":"fast","reason_schema_version":1,"schema_version":1,"url":"https://analysis-profile.example.test/","wait_budget_ms":1200}"#
  case "reject-negative-wait-budget":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://negative-wait.example.test/","wait_budget_ms":-1}"#
  case "reject-fractional-wait-budget":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://fractional-wait.example.test/","wait_budget_ms":1.5}"#
  case "reject-oversized-wait-budget":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"https://oversized-wait.example.test/","wait_budget_ms":2147483648}"#
  case "reject-reason-schema-version":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":2,"schema_version":1,"url":"https://reason-schema-version.example.test/","wait_budget_ms":1200}"#
  case "reject-non-http-url":
    expected =
      #"{"analysis_profile":"standard","reason_schema_version":1,"schema_version":1,"url":"ftp://non-http.example.test/resource","wait_budget_ms":1200}"#
  default:
    throw ContractAssetTestError.invalidAsset
  }

  let data: Data
  do {
    data = try JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  } catch {
    throw ContractAssetTestError.invalidAsset
  }
  guard let actual = String(data: data, encoding: .utf8) else {
    throw ContractAssetTestError.invalidAsset
  }
  return actual == expected
}

// This is intentionally an independent evaluator for the frozen Check Request V1 subset, not a
// general JSON Schema Draft 2020-12 implementation.
private func checkRequestSchemaFailures(in object: [String: Any]) -> Set<String> {
  let expectedKeys: Set<String> = [
    "schema_version", "url", "analysis_profile", "wait_budget_ms",
    "reason_schema_version",
  ]
  var failures = Set<String>()

  if Set(object.keys).subtracting(expectedKeys).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if expectedKeys.subtracting(object.keys).isEmpty == false {
    failures.insert("required")
  }

  checkIntegerConstant(object["schema_version"], constant: 1, failures: &failures)
  checkStringConstant(object["analysis_profile"], constant: "standard", failures: &failures)
  checkWaitBudget(object["wait_budget_ms"], failures: &failures)
  checkIntegerConstant(object["reason_schema_version"], constant: 1, failures: &failures)
  checkURL(object["url"], failures: &failures)
  return failures
}

private func checkIntegerConstant(
  _ value: Any?,
  constant: Int64,
  failures: inout Set<String>
) {
  guard let integer = integerValue(value) else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if integer != constant {
    failures.insert("const")
  }
}

private func checkStringConstant(
  _ value: Any?,
  constant: String,
  failures: inout Set<String>
) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string != constant {
    failures.insert("const")
  }
}

private func checkWaitBudget(_ value: Any?, failures: inout Set<String>) {
  guard let integer = integerValue(value) else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if integer < 0 {
    failures.insert("minimum")
  }
  if integer > 2_147_483_647 {
    failures.insert("maximum")
  }
}

private func checkURL(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > 8_192 {
    failures.insert("maxLength")
  }
  if string.range(of: "^[Hh][Tt][Tt][Pp][Ss]?://", options: .regularExpression) == nil {
    failures.insert("pattern")
  }
}
