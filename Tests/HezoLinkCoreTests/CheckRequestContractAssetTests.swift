import CoreFoundation
import Darwin
import Foundation
import Testing

@testable import HezoLinkCore

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
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.1.0")
    #expect(try requireString(info["description"]).isEmpty == false)

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == ["CheckRequestV1", "ProblemV1"])
    let checkRequest = try requireObject(schemas["CheckRequestV1"])
    #expect(Set(checkRequest.keys) == ["$ref"])
    #expect(checkRequest["$ref"] as? String == "./schemas/check-request-v1.schema.json")

    let problem = try requireObject(schemas["ProblemV1"])
    #expect(Set(problem.keys) == ["$ref"])
    #expect(problem["$ref"] as? String == "./schemas/problem-v1.schema.json")

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

    let referencedProblemSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent("schemas/problem-v1.schema.json")
      .standardizedFileURL
    let problemSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/problem-v1.schema.json"
    ).standardizedFileURL
    #expect(referencedProblemSchemaURL == problemSchemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedProblemSchemaURL.path))

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

struct ProblemContractAssetTests {
  @Test func schemaKeepsTheFrozenProblemV1Surface() throws {
    let schema = try loadObject("packages/contracts/schemas/problem-v1.schema.json")

    #expect(
      Set(schema.keys)
        == [
          "$schema", "$id", "title", "description", "type", "additionalProperties",
          "required", "properties", "dependentSchemas",
        ]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == "urn:hezo-link:contract:problem:v1")
    #expect(schema["title"] as? String == "Hezo Link problem V1")
    #expect(try requireString(schema["description"]).isEmpty == false)
    #expect(schema["type"] as? String == "object")
    #expect(try requireBool(schema["additionalProperties"]) == false)

    let requiredFields: Set<String> = [
      "type", "title", "status", "code", "detail", "request_id", "retryable",
    ]
    let allFields = requiredFields.union(["retry_after_seconds"])
    let required = try requireStringArray(schema["required"])
    #expect(required.count == requiredFields.count)
    #expect(Set(required) == requiredFields)

    let properties = try requireObject(schema["properties"])
    #expect(Set(properties.keys) == allFields)

    let type = try requireObject(properties["type"])
    #expect(
      Set(type.keys)
        == ["type", "minLength", "maxLength", "pattern", "format", "description"]
    )
    #expect(type["type"] as? String == "string")
    #expect(integerValue(type["minLength"]) == 1)
    #expect(integerValue(type["maxLength"]) == 256)
    #expect(type["format"] as? String == "uri-reference")
    #expect(type["pattern"] as? String == #"^[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]*$"#)

    try expectBoundedTextProperty(
      properties["title"],
      maximumLength: 128,
      expectedPattern: "^[^\\p{Cc}\\p{Cf}]*$"
    )
    try expectBoundedTextProperty(
      properties["detail"],
      maximumLength: 512,
      expectedPattern: "^[^\\p{Cc}\\p{Cf}]*$"
    )

    let status = try requireObject(properties["status"])
    #expect(Set(status.keys) == ["type", "minimum", "maximum"])
    #expect(status["type"] as? String == "integer")
    #expect(integerValue(status["minimum"]) == 400)
    #expect(integerValue(status["maximum"]) == 599)

    let code = try requireObject(properties["code"])
    #expect(Set(code.keys) == ["type", "minLength", "maxLength", "pattern", "description"])
    #expect(code["type"] as? String == "string")
    #expect(integerValue(code["minLength"]) == 1)
    #expect(integerValue(code["maxLength"]) == 128)
    #expect(code["pattern"] as? String == "^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$")

    let requestID = try requireObject(properties["request_id"])
    #expect(
      Set(requestID.keys) == ["type", "minLength", "maxLength", "pattern", "description"]
    )
    #expect(requestID["type"] as? String == "string")
    #expect(integerValue(requestID["minLength"]) == 1)
    #expect(integerValue(requestID["maxLength"]) == 128)
    #expect(requestID["pattern"] as? String == "^[A-Za-z0-9_-]*$")

    let retryable = try requireObject(properties["retryable"])
    #expect(Set(retryable.keys) == ["type"])
    #expect(retryable["type"] as? String == "boolean")

    let retryAfter = try requireObject(properties["retry_after_seconds"])
    #expect(Set(retryAfter.keys) == ["type", "minimum", "maximum", "description"])
    #expect(retryAfter["type"] as? String == "integer")
    #expect(integerValue(retryAfter["minimum"]) == 0)
    #expect(integerValue(retryAfter["maximum"]) == 86_400)

    let dependencies = try requireObject(schema["dependentSchemas"])
    #expect(Set(dependencies.keys) == ["retry_after_seconds"])
    let retryRule = try requireObject(dependencies["retry_after_seconds"])
    #expect(Set(retryRule.keys) == ["properties"])
    let consequenceProperties = try requireObject(retryRule["properties"])
    #expect(Set(consequenceProperties.keys) == ["retryable"])
    let retryableConsequence = try requireObject(consequenceProperties["retryable"])
    #expect(Set(retryableConsequence.keys) == ["const"])
    #expect(try requireBool(retryableConsequence["const"]))
  }

  @Test func manifestHasCompleteUniqueProblemFixtureCoverage() throws {
    let manifest = try loadObject("packages/contracts/fixtures/problem-v1/manifest.json")
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "problem-v1")
    #expect(manifest["contract_schema"] as? String == "../../schemas/problem-v1.schema.json")

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == expectedProblemFixturePaths.count)

    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == expectedProblemFixturePaths)

    let fixtureRoot = repositoryRoot.appendingPathComponent(
      "packages/contracts/fixtures/problem-v1"
    ).standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = fixtureRoot.appendingPathComponent("manifest.json")
    let contractSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent("../../schemas/problem-v1.schema.json")
      .standardizedFileURL
    let expectedSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/problem-v1.schema.json"
    ).standardizedFileURL
    #expect(contractSchemaURL == expectedSchemaURL)
  }

  @Test func everyProblemFixtureMatchesItsDeclaredExpectation() throws {
    let manifest = try loadObject("packages/contracts/fixtures/problem-v1/manifest.json")
    let cases = try requireObjectArray(manifest["cases"])
    let fixtureRoot = "packages/contracts/fixtures/problem-v1"
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let allowedKeys: Set<String> = [
        "id", "path", "expected_schema_valid", "expected_failure_keyword",
        "expected_failure_keywords",
      ]
      #expect(Set(fixtureCase.keys).isSubset(of: allowedKeys))
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadObject("\(fixtureRoot)/\(relativePath)")
      let failures = problemSchemaFailures(in: fixture)
      #expect(
        try problemFixtureMatchesExpectedPurpose(id: fixtureID, object: fixture),
        "Problem fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(fixtureCase["expected_failure_keyword"] == nil)
        #expect(fixtureCase["expected_failure_keywords"] == nil)
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords: Set<String>
        if let keyword = fixtureCase["expected_failure_keyword"] {
          expectedKeywords = [try requireString(keyword)]
          #expect(fixtureCase["expected_failure_keywords"] == nil)
        } else {
          let keywords = try requireStringArray(fixtureCase["expected_failure_keywords"])
          #expect(keywords.isEmpty == false)
          #expect(Set(keywords).count == keywords.count)
          expectedKeywords = Set(keywords)
        }
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 5)
    #expect(invalidCount == 28)
  }

  @Test func validProblemFixturesRoundTripThroughTheSwiftReader() throws {
    let manifest = try loadObject("packages/contracts/fixtures/problem-v1/manifest.json")
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let path = try requireString(fixtureCase["path"])
      let relativePath = "packages/contracts/fixtures/problem-v1/\(path)"
      let fixtureData = try loadData(relativePath)
      let fixtureObject = try loadObject(relativePath)
      let problem = try HezoJSON.makeResponseDecoder().decode(Problem.self, from: fixtureData)
      let encodedData = try HezoJSON.makeEncoder().encode(problem)
      let encodedObject = try jsonObject(from: encodedData)

      #expect(NSDictionary(dictionary: encodedObject).isEqual(to: fixtureObject))
    }
  }

  @Test func invalidKnownProblemFieldsFailTheSwiftReaderWithoutContentEcho() throws {
    let manifest = try loadObject("packages/contracts/fixtures/problem-v1/manifest.json")
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases {
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let id = try requireString(fixtureCase["id"])
      guard expectedValid == false, id != "reject-unknown-field" else {
        continue
      }
      let path = try requireString(fixtureCase["path"])
      do {
        _ = try HezoJSON.makeResponseDecoder().decode(
          Problem.self,
          from: loadData("packages/contracts/fixtures/problem-v1/\(path)")
        )
        Issue.record("A declared invalid Problem V1 fixture was accepted: \(id)")
      } catch is DecodingError {
        // Expected. The safe fixture ID is enough context; never render the rejected payload.
      } catch {
        Issue.record("Problem V1 decoding used an unexpected error category: \(id)")
      }
    }
  }

  @Test(
    arguments: [
      ("title", Problem.maximumTitleUTF8ByteCount),
      ("detail", Problem.maximumDetailUTF8ByteCount),
    ]
  )
  func SwiftReaderAddsTheDocumentedUTF8ByteLimit(
    field: String,
    maximumUTF8ByteCount: Int
  ) throws {
    let relativePath = "packages/contracts/fixtures/problem-v1/valid/non-retryable.json"
    var fixture = try loadObject(relativePath)
    fixture[field] = String(repeating: "é", count: maximumUTF8ByteCount)

    #expect(problemSchemaFailures(in: fixture).isEmpty)
    let data = try JSONSerialization.data(withJSONObject: fixture, options: [.sortedKeys])
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)
    }
  }

  @Test func schemaStrictnessAndResponseReaderToleranceStayDistinct() throws {
    let relativePath =
      "packages/contracts/fixtures/problem-v1/invalid/unknown-field.json"
    let fixture = try loadObject(relativePath)
    #expect(problemSchemaFailures(in: fixture) == ["additionalProperties"])

    let problem = try HezoJSON.makeResponseDecoder().decode(
      Problem.self,
      from: loadData(relativePath)
    )
    #expect(problem.type.rawValue.isEmpty == false)
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

private let expectedProblemFixturePaths: [String: String] = [
  "valid-non-retryable": "valid/non-retryable.json",
  "valid-retryable-with-delay": "valid/retryable-with-delay.json",
  "valid-retryable-without-delay": "valid/retryable-without-delay.json",
  "valid-lower-boundaries": "valid/lower-boundaries.json",
  "valid-upper-numeric-boundaries": "valid/upper-numeric-boundaries.json",
  "reject-unknown-field": "invalid/unknown-field.json",
  "reject-missing-detail": "invalid/missing-detail.json",
  "reject-empty-type": "invalid/empty-type.json",
  "reject-malformed-type": "invalid/malformed-type.json",
  "reject-malformed-structure-type": "invalid/malformed-structure-type.json",
  "reject-invalid-ip-literal": "invalid/invalid-ip-literal.json",
  "reject-non-ascii-type": "invalid/non-ascii-type.json",
  "reject-oversized-type": "invalid/oversized-type.json",
  "reject-empty-title": "invalid/empty-title.json",
  "reject-title-control": "invalid/title-control.json",
  "reject-oversized-title": "invalid/oversized-title.json",
  "reject-status-below-range": "invalid/status-below-range.json",
  "reject-status-above-range": "invalid/status-above-range.json",
  "reject-fractional-status": "invalid/fractional-status.json",
  "reject-code-grammar": "invalid/code-grammar.json",
  "reject-oversized-code": "invalid/oversized-code.json",
  "reject-empty-detail": "invalid/empty-detail.json",
  "reject-detail-control": "invalid/detail-control.json",
  "reject-oversized-detail": "invalid/oversized-detail.json",
  "reject-empty-request-id": "invalid/empty-request-id.json",
  "reject-request-id-character": "invalid/request-id-character.json",
  "reject-oversized-request-id": "invalid/oversized-request-id.json",
  "reject-retry-delay-on-non-retryable": "invalid/retry-delay-on-non-retryable.json",
  "reject-negative-retry-delay": "invalid/negative-retry-delay.json",
  "reject-oversized-retry-delay": "invalid/oversized-retry-delay.json",
  "reject-fractional-retry-delay": "invalid/fractional-retry-delay.json",
  "reject-null-retry-delay": "invalid/null-retry-delay.json",
  "reject-retryable-type": "invalid/retryable-type.json",
]

private func problemFixtureMatchesExpectedPurpose(
  id: String,
  object: [String: Any]
) throws -> Bool {
  let expected: [String: Any]
  switch id {
  case "valid-non-retryable":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-url",
      title: "Invalid URL",
      status: 422,
      code: "invalid_url",
      detail: "The submitted value is not a supported HTTP or HTTPS URL.",
      requestID: "fixture-request-01",
      retryable: false
    )
  case "valid-retryable-with-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/temporarily-unavailable",
      title: "Temporarily unavailable",
      status: 503,
      code: "temporarily_unavailable",
      detail: "Please try again later.",
      requestID: "fixture-request-02",
      retryable: true,
      retryAfterSeconds: 30
    )
  case "valid-retryable-without-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/analysis-capacity-unavailable",
      title: "Analysis capacity unavailable",
      status: 503,
      code: "analysis_capacity_unavailable",
      detail: "The check cannot be accepted right now.",
      requestID: "fixture-request-03",
      retryable: true
    )
  case "valid-lower-boundaries":
    expected = expectedProblemFixture(
      type: "a",
      title: "a",
      status: 400,
      code: "a",
      detail: "a",
      requestID: "a",
      retryable: true,
      retryAfterSeconds: 0
    )
  case "valid-upper-numeric-boundaries":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/upper-boundaries",
      title: "Upper numeric boundaries",
      status: 599,
      code: "future_problem_2",
      detail: "Synthetic upper numeric-boundary example.",
      requestID: "fixture-request-upper",
      retryable: true,
      retryAfterSeconds: 86_400
    )
  case "reject-unknown-field":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-url",
      title: "Invalid URL",
      code: "invalid_url",
      requestID: "fixture-request-unknown",
      additionalProperties: ["debug_context": "not allowed"]
    )
  case "reject-missing-detail":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-url",
      title: "Invalid URL",
      code: "invalid_url",
      requestID: "fixture-request-missing",
      omittedProperties: ["detail"]
    )
  case "reject-empty-type":
    expected = expectedProblemFixture(
      type: "",
      title: "Invalid problem type",
      requestID: "fixture-request-empty-type"
    )
  case "reject-malformed-type":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/%ZZ",
      title: "Invalid problem type",
      requestID: "fixture-request-malformed-type"
    )
  case "reject-malformed-structure-type":
    expected = expectedProblemFixture(
      type: "[",
      title: "Invalid problem type",
      requestID: "fixture-request-malformed-structure"
    )
  case "reject-invalid-ip-literal":
    expected = expectedProblemFixture(
      type: "//[a]/",
      title: "Invalid problem type",
      requestID: "fixture-request-invalid-ip-literal"
    )
  case "reject-non-ascii-type":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/å",
      title: "Invalid problem type",
      requestID: "fixture-request-type-non-ascii"
    )
  case "reject-oversized-type":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/" + String(repeating: "a", count: 230),
      title: "Oversized problem type",
      requestID: "fixture-request-type-long"
    )
  case "reject-empty-title":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-title",
      title: "",
      requestID: "fixture-request-empty-title"
    )
  case "reject-title-control":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-title",
      title: "Unsafe\nTitle",
      requestID: "fixture-request-title-control"
    )
  case "reject-oversized-title":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-title",
      title: String(repeating: "a", count: 129),
      requestID: "fixture-request-title-long"
    )
  case "reject-status-below-range":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-status",
      title: "Invalid status",
      status: 399,
      requestID: "fixture-request-status-low"
    )
  case "reject-status-above-range":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-status",
      title: "Invalid status",
      status: 600,
      requestID: "fixture-request-status-high"
    )
  case "reject-fractional-status":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-status",
      title: "Invalid status",
      status: 422.5,
      requestID: "fixture-request-status-fractional"
    )
  case "reject-code-grammar":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-code",
      title: "Invalid code",
      code: "double__underscore",
      requestID: "fixture-request-code-grammar"
    )
  case "reject-oversized-code":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-code",
      title: "Invalid code",
      code: String(repeating: "a", count: 129),
      requestID: "fixture-request-code-long"
    )
  case "reject-empty-detail":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-detail",
      title: "Invalid detail",
      detail: "",
      requestID: "fixture-request-empty-detail"
    )
  case "reject-detail-control":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-detail",
      title: "Invalid detail",
      detail: "Unsafe\ndetail.",
      requestID: "fixture-request-detail-control"
    )
  case "reject-oversized-detail":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-detail",
      title: "Invalid detail",
      detail: String(repeating: "a", count: 529),
      requestID: "fixture-request-detail-long"
    )
  case "reject-empty-request-id":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-request-id",
      title: "Invalid request ID",
      requestID: ""
    )
  case "reject-request-id-character":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-request-id",
      title: "Invalid request ID",
      requestID: "fixture/request/id"
    )
  case "reject-oversized-request-id":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-request-id",
      title: "Invalid request ID",
      requestID: String(repeating: "a", count: 129)
    )
  case "reject-retry-delay-on-non-retryable":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retry-delay",
      title: "Invalid retry delay",
      requestID: "fixture-request-retry-not-allowed",
      retryAfterSeconds: 30
    )
  case "reject-negative-retry-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retry-delay",
      title: "Invalid retry delay",
      requestID: "fixture-request-retry-negative",
      retryable: true,
      retryAfterSeconds: -1
    )
  case "reject-oversized-retry-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retry-delay",
      title: "Invalid retry delay",
      requestID: "fixture-request-retry-high",
      retryable: true,
      retryAfterSeconds: 86_401
    )
  case "reject-fractional-retry-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retry-delay",
      title: "Invalid retry delay",
      requestID: "fixture-request-retry-fractional",
      retryable: true,
      retryAfterSeconds: 1.5
    )
  case "reject-null-retry-delay":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retry-delay",
      title: "Invalid retry delay",
      requestID: "fixture-request-null-retry-delay",
      retryable: true,
      retryAfterSeconds: NSNull()
    )
  case "reject-retryable-type":
    expected = expectedProblemFixture(
      type: "https://errors.example.test/invalid-retryable",
      title: "Invalid retryable value",
      requestID: "fixture-request-retryable-type",
      retryable: "false"
    )
  default:
    throw ContractAssetTestError.invalidAsset
  }

  do {
    let options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
    let actualData = try JSONSerialization.data(withJSONObject: object, options: options)
    let expectedData = try JSONSerialization.data(withJSONObject: expected, options: options)
    return actualData == expectedData
  } catch {
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectedProblemFixture(
  type: String,
  title: String,
  status: Any = 422,
  code: String = "invalid_request",
  detail: String = "Synthetic invalid fixture.",
  requestID: String,
  retryable: Any = false,
  retryAfterSeconds: Any? = nil,
  additionalProperties: [String: Any] = [:],
  omittedProperties: Set<String> = []
) -> [String: Any] {
  var object: [String: Any] = [
    "type": type,
    "title": title,
    "status": status,
    "code": code,
    "detail": detail,
    "request_id": requestID,
    "retryable": retryable,
  ]
  if let retryAfterSeconds {
    object["retry_after_seconds"] = retryAfterSeconds
  }
  object.merge(additionalProperties) { _, newValue in newValue }
  for property in omittedProperties {
    object.removeValue(forKey: property)
  }
  return object
}

private func loadObject(_ relativePath: String) throws -> [String: Any] {
  let data = try loadData(relativePath)

  return try jsonObject(from: data)
}

private func loadData(_ relativePath: String) throws -> Data {
  do {
    return try Data(contentsOf: repositoryRoot.appendingPathComponent(relativePath))
  } catch {
    throw ContractAssetTestError.unreadableAsset
  }
}

private func jsonObject(from data: Data) throws -> [String: Any] {
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

private func expectBoundedTextProperty(
  _ value: Any?,
  maximumLength: Int64,
  expectedPattern: String
) throws {
  let property = try requireObject(value)
  #expect(
    Set(property.keys) == ["type", "minLength", "maxLength", "pattern", "description"]
  )
  #expect(property["type"] as? String == "string")
  #expect(integerValue(property["minLength"]) == 1)
  #expect(integerValue(property["maxLength"]) == maximumLength)
  #expect(property["pattern"] as? String == expectedPattern)
}

// This is intentionally an independent evaluator for the frozen Problem V1 subset, not a
// general JSON Schema Draft 2020-12 or RFC 3986 implementation.
private func problemSchemaFailures(in object: [String: Any]) -> Set<String> {
  let requiredKeys: Set<String> = [
    "type", "title", "status", "code", "detail", "request_id", "retryable",
  ]
  let allowedKeys = requiredKeys.union(["retry_after_seconds"])
  var failures = Set<String>()

  if Set(object.keys).subtracting(allowedKeys).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if requiredKeys.subtracting(object.keys).isEmpty == false {
    failures.insert("required")
  }

  checkProblemType(object["type"], failures: &failures)
  checkProblemText(object["title"], maximumLength: 128, failures: &failures)
  checkProblemStatus(object["status"], failures: &failures)
  checkProblemCode(object["code"], failures: &failures)
  checkProblemText(object["detail"], maximumLength: 512, failures: &failures)
  checkProblemRequestID(object["request_id"], failures: &failures)
  checkProblemRetryable(object["retryable"], failures: &failures)
  checkProblemRetryDelay(
    object["retry_after_seconds"],
    retryable: object["retryable"],
    failures: &failures
  )
  return failures
}

private func checkProblemType(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
    return
  }
  if string.unicodeScalars.count > Problem.maximumTypeUTF8ByteCount {
    failures.insert("maxLength")
    return
  }
  if string.utf8.allSatisfy(isAllowedProblemTypePatternByte) == false {
    failures.insert("pattern")
  }
  if isValidProblemTypeURIReference(string) == false {
    failures.insert("format")
  }
}

private func isValidProblemTypeURIReference(_ value: String) -> Bool {
  let bytes = Array(value.utf8)
  guard bytes.allSatisfy(isAllowedProblemTypePatternByte) else {
    return false
  }
  var index = bytes.startIndex
  while index < bytes.endIndex {
    guard bytes[index] == 0x25 else {
      index += 1
      continue
    }
    guard index + 2 < bytes.endIndex,
      isASCIIHexDigit(bytes[index + 1]),
      isASCIIHexDigit(bytes[index + 2])
    else {
      return false
    }
    index += 3
  }
  guard hasValidProblemTypeBracketPlacement(bytes) else {
    return false
  }

  let firstPathDelimiter =
    bytes.firstIndex { byte in byte == 0x2F || byte == 0x3F || byte == 0x23 }
    ?? bytes.endIndex
  guard let colon = bytes[..<firstPathDelimiter].firstIndex(of: 0x3A) else {
    return true
  }
  let scheme = bytes[..<colon]
  guard let first = scheme.first, isASCIIAlpha(first) else {
    return false
  }
  return scheme.dropFirst().allSatisfy { byte in
    isASCIIAlpha(byte) || (0x30...0x39).contains(byte)
      || byte == 0x2B || byte == 0x2D || byte == 0x2E
  }
}

private func hasValidProblemTypeBracketPlacement(_ bytes: [UInt8]) -> Bool {
  let opening = bytes.indices.filter { bytes[$0] == 0x5B }
  let closing = bytes.indices.filter { bytes[$0] == 0x5D }
  guard opening.count == closing.count else {
    return false
  }
  guard let open = opening.first, let close = closing.first else {
    return true
  }
  guard opening.count == 1, open < close, close > open + 1 else {
    return false
  }
  guard open >= 2, bytes[(open - 2)..<open].elementsEqual([0x2F, 0x2F]) else {
    return false
  }
  if close + 1 < bytes.endIndex {
    guard [0x2F, 0x3A, 0x3F, 0x23].contains(bytes[close + 1]) else {
      return false
    }
  }
  let literal = String(decoding: bytes[(open + 1)..<close], as: UTF8.self)
  return isProblemFixtureIPv6Address(literal) || isProblemFixtureIPvFuture(literal)
}

private func isProblemFixtureIPv6Address(_ value: String) -> Bool {
  var address = in6_addr()
  return value.withCString { inet_pton(AF_INET6, $0, &address) } == 1
}

private func isProblemFixtureIPvFuture(_ value: String) -> Bool {
  let bytes = Array(value.utf8)
  guard let first = bytes.first, first == 0x56 || first == 0x76,
    let dot = bytes.dropFirst().firstIndex(of: 0x2E),
    dot > 1,
    dot + 1 < bytes.endIndex,
    bytes[1..<dot].allSatisfy(isASCIIHexDigit)
  else {
    return false
  }
  return bytes[(dot + 1)...].allSatisfy(isProblemFixtureIPvFutureAddressByte)
}

private func isProblemFixtureIPvFutureAddressByte(_ byte: UInt8) -> Bool {
  isASCIIAlpha(byte) || (0x30...0x39).contains(byte)
    || [
      0x21, 0x24, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x3A,
      0x3B, 0x3D, 0x5F, 0x7E,
    ].contains(byte)
}

private func isASCIIAlpha(_ byte: UInt8) -> Bool {
  (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
}

private func isASCIIHexDigit(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
    || (0x61...0x66).contains(byte)
}

private func isAllowedProblemTypePatternByte(_ byte: UInt8) -> Bool {
  switch byte {
  case 0x21, 0x23...0x3B, 0x3D, 0x3F...0x5B, 0x5D, 0x5F, 0x61...0x7A, 0x7E:
    true
  default:
    false
  }
}

private func checkProblemText(
  _ value: Any?,
  maximumLength: Int,
  failures: inout Set<String>
) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > maximumLength {
    failures.insert("maxLength")
  }
  if string.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) {
    failures.insert("pattern")
  }
}

private func checkProblemStatus(_ value: Any?, failures: inout Set<String>) {
  guard let integer = integerValue(value) else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if integer < 400 {
    failures.insert("minimum")
  }
  if integer > 599 {
    failures.insert("maximum")
  }
}

private func checkProblemCode(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
    return
  }
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
    return
  }
  if isValidProblemCode(string) == false {
    failures.insert("pattern")
  }
}

private func isValidProblemCode(_ value: String) -> Bool {
  let bytes = value.utf8
  guard let first = bytes.first, (0x61...0x7A).contains(first) else {
    return false
  }

  var previousWasUnderscore = false
  for byte in bytes.dropFirst() {
    let isUnderscore = byte == 0x5F
    guard (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte) || isUnderscore,
      previousWasUnderscore == false || isUnderscore == false
    else {
      return false
    }
    previousWasUnderscore = isUnderscore
  }
  return bytes.last != 0x5F
}

private func checkProblemRequestID(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
    return
  }
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
    return
  }
  if string.utf8.allSatisfy(isAllowedRequestIDByte) == false {
    failures.insert("pattern")
  }
}

private func isAllowedRequestIDByte(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
    || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
}

private func checkProblemRetryable(_ value: Any?, failures: inout Set<String>) {
  guard let number = value as? NSNumber else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if CFGetTypeID(number) != CFBooleanGetTypeID() {
    failures.insert("type")
  }
}

private func checkProblemRetryDelay(
  _ value: Any?,
  retryable: Any?,
  failures: inout Set<String>
) {
  guard value != nil else {
    return
  }
  guard let integer = integerValue(value) else {
    failures.insert("type")
    return
  }
  if integer < 0 {
    failures.insert("minimum")
  }
  if integer > Problem.maximumRetryAfterSeconds {
    failures.insert("maximum")
  }
  if (try? requireBool(retryable)) != true {
    failures.insert("const")
  }
}
