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
    #expect(info["version"] as? String == "1.2.0")
    #expect(try requireString(info["description"]).isEmpty == false)

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == ["CheckRequestV1", "ProblemV1", "VerdictReasonV1"])
    let checkRequest = try requireObject(schemas["CheckRequestV1"])
    #expect(Set(checkRequest.keys) == ["$ref"])
    #expect(checkRequest["$ref"] as? String == "./schemas/check-request-v1.schema.json")

    let problem = try requireObject(schemas["ProblemV1"])
    #expect(Set(problem.keys) == ["$ref"])
    #expect(problem["$ref"] as? String == "./schemas/problem-v1.schema.json")

    let verdictReason = try requireObject(schemas["VerdictReasonV1"])
    #expect(Set(verdictReason.keys) == ["$ref"])
    #expect(
      verdictReason["$ref"] as? String == "./schemas/verdict-reason-v1.schema.json"
    )

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

    let referencedVerdictReasonSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent("schemas/verdict-reason-v1.schema.json")
      .standardizedFileURL
    let verdictReasonSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/verdict-reason-v1.schema.json"
    ).standardizedFileURL
    #expect(referencedVerdictReasonSchemaURL == verdictReasonSchemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedVerdictReasonSchemaURL.path))

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

struct VerdictReasonContractAssetTests {
  @Test func schemaAndOpenAPIKeepTheFrozenVerdictReasonV1Surface() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject("packages/contracts/schemas/verdict-reason-v1.schema.json")

    let info = try requireObject(openAPI["info"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.2.0")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let components = try requireObject(openAPI["components"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == ["CheckRequestV1", "ProblemV1", "VerdictReasonV1"])
    let verdictReason = try requireObject(schemas["VerdictReasonV1"])
    #expect(Set(verdictReason.keys) == ["$ref"])
    #expect(
      verdictReason["$ref"] as? String == "./schemas/verdict-reason-v1.schema.json"
    )

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent("schemas/verdict-reason-v1.schema.json")
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/verdict-reason-v1.schema.json"
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
    #expect(schema["$id"] as? String == "urn:hezo-link:contract:verdict-reason:v1")
    #expect(schema["title"] as? String == "Hezo Link verdict reason V1")
    #expect(try requireString(schema["description"]).isEmpty == false)
    #expect(schema["type"] as? String == "object")
    #expect(try requireBool(schema["additionalProperties"]) == false)

    let expectedFields: Set<String> = [
      "code", "family", "severity", "summary_key", "observed_at", "freshness",
    ]
    let required = try requireStringArray(schema["required"])
    #expect(required.count == expectedFields.count)
    #expect(Set(required) == expectedFields)

    let properties = try requireObject(schema["properties"])
    #expect(Set(properties.keys) == expectedFields)
    for field in ["code", "family", "severity", "freshness"] {
      try expectStableVerdictReasonProperty(properties[field])
    }

    let summaryKey = try requireObject(properties["summary_key"])
    #expect(
      Set(summaryKey.keys)
        == ["type", "minLength", "maxLength", "pattern", "description"]
    )
    #expect(summaryKey["type"] as? String == "string")
    #expect(integerValue(summaryKey["minLength"]) == 1)
    #expect(integerValue(summaryKey["maxLength"]) == 256)
    #expect(summaryKey["pattern"] as? String == verdictReasonSummaryKeyPattern)
    #expect(try requireString(summaryKey["description"]).isEmpty == false)

    let observedAt = try requireObject(properties["observed_at"])
    #expect(Set(observedAt.keys) == ["type", "pattern", "format", "description"])
    #expect(observedAt["type"] as? String == "string")
    #expect(observedAt["pattern"] as? String == verdictReasonObservedAtPattern)
    #expect(observedAt["format"] as? String == "date-time")
    #expect(try requireString(observedAt["description"]).isEmpty == false)
  }

  @Test func manifestHasCompleteUniqueVerdictReasonFixtureCoverage() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/verdict-reason-v1/manifest.json"
    )
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "verdict-reason-v1")
    #expect(
      manifest["contract_schema"] as? String
        == "../../schemas/verdict-reason-v1.schema.json"
    )

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == expectedVerdictReasonFixturePaths.count)

    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == expectedVerdictReasonFixturePaths)
    #expect(
      Set(expectedVerdictReasonFailureKeywords.keys)
        == Set(ids).subtracting(
          ["valid-documented", "valid-forward-compatible", "valid-maximum-boundaries"]
        )
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(
      "packages/contracts/fixtures/verdict-reason-v1"
    ).standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = fixtureRoot.appendingPathComponent("manifest.json")
    let contractSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent("../../schemas/verdict-reason-v1.schema.json")
      .standardizedFileURL
    let expectedSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/verdict-reason-v1.schema.json"
    ).standardizedFileURL
    #expect(contractSchemaURL == expectedSchemaURL)
  }

  @Test func everyVerdictReasonFixtureMatchesItsDeclaredExpectation() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/verdict-reason-v1/manifest.json"
    )
    let cases = try requireObjectArray(manifest["cases"])
    let fixtureRoot = "packages/contracts/fixtures/verdict-reason-v1"
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadObject("\(fixtureRoot)/\(relativePath)")
      let failures = verdictReasonSchemaFailures(in: fixture)

      #expect(
        try verdictReasonFixtureMatchesExpectedPurpose(id: fixtureID, object: fixture),
        "Verdict Reason fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(
          Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"]
        )
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords: Set<String>
        if let keyword = fixtureCase["expected_failure_keyword"] {
          #expect(
            Set(fixtureCase.keys)
              == ["id", "path", "expected_schema_valid", "expected_failure_keyword"]
          )
          expectedKeywords = [try requireString(keyword)]
        } else {
          #expect(
            Set(fixtureCase.keys)
              == ["id", "path", "expected_schema_valid", "expected_failure_keywords"]
          )
          let keywords = try requireStringArray(fixtureCase["expected_failure_keywords"])
          #expect(keywords.isEmpty == false)
          #expect(Set(keywords).count == keywords.count)
          expectedKeywords = Set(keywords)
        }
        #expect(expectedKeywords == expectedVerdictReasonFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 3)
    #expect(invalidCount == 19)
  }

  @Test func validVerdictReasonFixturesRoundTripThroughTheSwiftReader() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/verdict-reason-v1/manifest.json"
    )
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let path = try requireString(fixtureCase["path"])
      let relativePath = "packages/contracts/fixtures/verdict-reason-v1/\(path)"
      let fixtureData = try loadData(relativePath)
      let fixtureObject = try loadObject(relativePath)
      let reason = try HezoJSON.makeResponseDecoder().decode(
        VerdictReason.self,
        from: fixtureData
      )
      let encodedData = try HezoJSON.makeEncoder().encode(reason)
      let encodedObject = try jsonObject(from: encodedData)

      #expect(NSDictionary(dictionary: encodedObject).isEqual(to: fixtureObject))
    }
  }

  @Test func invalidKnownVerdictReasonFieldsFailTheSwiftReader() throws {
    let manifest = try loadObject(
      "packages/contracts/fixtures/verdict-reason-v1/manifest.json"
    )
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
          VerdictReason.self,
          from: loadData("packages/contracts/fixtures/verdict-reason-v1/\(path)")
        )
        Issue.record("A declared invalid Verdict Reason V1 fixture was accepted: \(id)")
      } catch is DecodingError {
        // Expected. The safe fixture ID is enough context; never render the rejected payload.
      } catch {
        Issue.record("Verdict Reason V1 decoding used an unexpected error category: \(id)")
      }
    }
  }

  @Test func schemaStrictnessAndResponseReaderToleranceStayDistinctForVerdictReason() throws {
    let relativePath =
      "packages/contracts/fixtures/verdict-reason-v1/invalid/unknown-field.json"
    let fixture = try loadObject(relativePath)
    #expect(verdictReasonSchemaFailures(in: fixture) == ["additionalProperties"])

    let reason = try HezoJSON.makeResponseDecoder().decode(
      VerdictReason.self,
      from: loadData(relativePath)
    )
    let encoded = try HezoJSON.makeEncoder().encode(reason)
    let encodedObject = try jsonObject(from: encoded)
    #expect(encodedObject["future_optional"] == nil)
    #expect(reason.code.rawValue.isEmpty == false)
  }

  @Test(
    arguments: ["code", "family", "severity", "summary_key", "observed_at", "freshness"]
  )
  func readerErrorsDoNotReflectRejectedVerdictReasonContent(field: String) throws {
    var fixture = try loadObject(
      "packages/contracts/fixtures/verdict-reason-v1/valid/documented.json"
    )
    let rejectedCandidate = "PRIVATE_SENTINEL_\(field.uppercased())"
    fixture[field] = rejectedCandidate
    let data = try JSONSerialization.data(withJSONObject: fixture, options: [.sortedKeys])

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(VerdictReason.self, from: data)
      Issue.record("A privacy-canary Verdict Reason field was accepted: \(field)")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains(rejectedCandidate) == false)
      #expect(String(reflecting: error).contains(rejectedCandidate) == false)
    } catch {
      Issue.record("Verdict Reason privacy canary used an unexpected error category: \(field)")
    }
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

private let verdictReasonStableValuePattern = "^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$"

private let verdictReasonSummaryKeyPattern =
  #"^(?=.{1,128}(?:\.|$))[a-z][a-z0-9]*(?:_[a-z0-9]+)*(?:\.(?=.{1,128}(?:\.|$))[a-z][a-z0-9]*(?:_[a-z0-9]+)*)*$"#

private let verdictReasonObservedAtPattern =
  "^[0-9]{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"

private let expectedVerdictReasonFixturePaths: [String: String] = [
  "valid-documented": "valid/documented.json",
  "valid-forward-compatible": "valid/forward-compatible.json",
  "valid-maximum-boundaries": "valid/maximum-boundaries.json",
  "reject-unknown-field": "invalid/unknown-field.json",
  "reject-missing-observed-at": "invalid/missing-observed-at.json",
  "reject-null-family": "invalid/null-family.json",
  "reject-wrong-type-severity": "invalid/wrong-type-severity.json",
  "reject-empty-code": "invalid/empty-code.json",
  "reject-code-uppercase": "invalid/code-uppercase.json",
  "reject-family-leading-digit": "invalid/family-leading-digit.json",
  "reject-severity-double-underscore": "invalid/severity-double-underscore.json",
  "reject-freshness-trailing-underscore": "invalid/freshness-trailing-underscore.json",
  "reject-oversized-code": "invalid/oversized-code.json",
  "reject-summary-key-double-dot": "invalid/summary-key-double-dot.json",
  "reject-summary-key-uppercase-segment": "invalid/summary-key-uppercase-segment.json",
  "reject-summary-key-oversized-segment": "invalid/summary-key-oversized-segment.json",
  "reject-summary-key-oversized-total": "invalid/summary-key-oversized-total.json",
  "reject-fractional-observed-at": "invalid/fractional-observed-at.json",
  "reject-offset-observed-at": "invalid/offset-observed-at.json",
  "reject-lowercase-z-observed-at": "invalid/lowercase-z-observed-at.json",
  "reject-impossible-observed-at": "invalid/impossible-observed-at.json",
  "reject-wrong-type-observed-at": "invalid/wrong-type-observed-at.json",
]

private let expectedVerdictReasonFailureKeywords: [String: Set<String>] = [
  "reject-unknown-field": ["additionalProperties"],
  "reject-missing-observed-at": ["required"],
  "reject-null-family": ["type"],
  "reject-wrong-type-severity": ["type"],
  "reject-empty-code": ["minLength", "pattern"],
  "reject-code-uppercase": ["pattern"],
  "reject-family-leading-digit": ["pattern"],
  "reject-severity-double-underscore": ["pattern"],
  "reject-freshness-trailing-underscore": ["pattern"],
  "reject-oversized-code": ["maxLength"],
  "reject-summary-key-double-dot": ["pattern"],
  "reject-summary-key-uppercase-segment": ["pattern"],
  "reject-summary-key-oversized-segment": ["pattern"],
  "reject-summary-key-oversized-total": ["maxLength"],
  "reject-fractional-observed-at": ["pattern"],
  "reject-offset-observed-at": ["pattern"],
  "reject-lowercase-z-observed-at": ["pattern"],
  "reject-impossible-observed-at": ["format"],
  "reject-wrong-type-observed-at": ["type"],
]

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

private func verdictReasonFixtureMatchesExpectedPurpose(
  id: String,
  object: [String: Any]
) throws -> Bool {
  let expected: [String: Any]
  switch id {
  case "valid-documented":
    expected = expectedVerdictReasonFixture()
  case "valid-forward-compatible":
    expected = expectedVerdictReasonFixture(
      code: "synthetic_signal_v2",
      family: "future_analysis",
      severity: "advisory",
      summaryKey: "verdict.reason.synthetic_signal_v2",
      observedAt: "2001-01-01T00:00:00Z",
      freshness: "recently_observed"
    )
  case "valid-maximum-boundaries":
    expected = expectedVerdictReasonFixture(
      code: String(repeating: "a", count: 128),
      family: String(repeating: "b", count: 128),
      severity: String(repeating: "c", count: 128),
      summaryKey: String(repeating: "d", count: 128) + "."
        + String(repeating: "e", count: 127),
      observedAt: "2000-02-29T23:59:59Z",
      freshness: String(repeating: "f", count: 128)
    )
  case "reject-unknown-field":
    expected = expectedVerdictReasonFixture(additionalProperties: ["future_optional": true])
  case "reject-missing-observed-at":
    expected = expectedVerdictReasonFixture(omittedProperties: ["observed_at"])
  case "reject-null-family":
    expected = expectedVerdictReasonFixture(family: NSNull())
  case "reject-wrong-type-severity":
    expected = expectedVerdictReasonFixture(severity: 1)
  case "reject-empty-code":
    expected = expectedVerdictReasonFixture(code: "")
  case "reject-code-uppercase":
    expected = expectedVerdictReasonFixture(code: "Brand_impersonation")
  case "reject-family-leading-digit":
    expected = expectedVerdictReasonFixture(family: "1identity_impersonation")
  case "reject-severity-double-underscore":
    expected = expectedVerdictReasonFixture(severity: "very__high")
  case "reject-freshness-trailing-underscore":
    expected = expectedVerdictReasonFixture(freshness: "current_")
  case "reject-oversized-code":
    expected = expectedVerdictReasonFixture(code: String(repeating: "a", count: 129))
  case "reject-summary-key-double-dot":
    expected = expectedVerdictReasonFixture(summaryKey: "verdict..reason")
  case "reject-summary-key-uppercase-segment":
    expected = expectedVerdictReasonFixture(summaryKey: "verdict.Reason.signal")
  case "reject-summary-key-oversized-segment":
    expected = expectedVerdictReasonFixture(
      summaryKey: String(repeating: "a", count: 129) + ".reason"
    )
  case "reject-summary-key-oversized-total":
    expected = expectedVerdictReasonFixture(
      summaryKey: String(repeating: "a", count: 128) + "."
        + String(repeating: "b", count: 128)
    )
  case "reject-fractional-observed-at":
    expected = expectedVerdictReasonFixture(observedAt: "2000-02-29T23:59:59.001Z")
  case "reject-offset-observed-at":
    expected = expectedVerdictReasonFixture(observedAt: "2000-03-01T00:59:59+01:00")
  case "reject-lowercase-z-observed-at":
    expected = expectedVerdictReasonFixture(observedAt: "2000-02-29T23:59:59z")
  case "reject-impossible-observed-at":
    expected = expectedVerdictReasonFixture(observedAt: "2001-02-29T23:59:59Z")
  case "reject-wrong-type-observed-at":
    expected = expectedVerdictReasonFixture(observedAt: 946_684_800)
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

private func expectedVerdictReasonFixture(
  code: Any = "brand_impersonation_unrelated_domain",
  family: Any = "identity_impersonation",
  severity: Any = "high",
  summaryKey: Any = "verdict.reason.brand_impersonation_unrelated_domain",
  observedAt: Any = "2026-08-11T10:15:00Z",
  freshness: Any = "current",
  additionalProperties: [String: Any] = [:],
  omittedProperties: Set<String> = []
) -> [String: Any] {
  var object: [String: Any] = [
    "code": code,
    "family": family,
    "severity": severity,
    "summary_key": summaryKey,
    "observed_at": observedAt,
    "freshness": freshness,
  ]
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

private func expectStableVerdictReasonProperty(_ value: Any?) throws {
  let property = try requireObject(value)
  #expect(
    Set(property.keys) == ["type", "minLength", "maxLength", "pattern", "description"]
  )
  #expect(property["type"] as? String == "string")
  #expect(integerValue(property["minLength"]) == 1)
  #expect(integerValue(property["maxLength"]) == 128)
  #expect(property["pattern"] as? String == verdictReasonStableValuePattern)
  #expect(try requireString(property["description"]).isEmpty == false)
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

// This is intentionally an independent evaluator for the frozen Verdict Reason V1 subset, not a
// general JSON Schema Draft 2020-12 or RFC 3339 implementation.
private func verdictReasonSchemaFailures(in object: [String: Any]) -> Set<String> {
  let expectedKeys: Set<String> = [
    "code", "family", "severity", "summary_key", "observed_at", "freshness",
  ]
  var failures = Set<String>()

  if Set(object.keys).subtracting(expectedKeys).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if expectedKeys.subtracting(object.keys).isEmpty == false {
    failures.insert("required")
  }

  for field in ["code", "family", "severity", "freshness"] {
    checkVerdictReasonStableValue(object[field], failures: &failures)
  }
  checkVerdictReasonSummaryKey(object["summary_key"], failures: &failures)
  checkVerdictReasonObservedAt(object["observed_at"], failures: &failures)
  return failures
}

private func checkVerdictReasonStableValue(
  _ value: Any?,
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
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
  }
  if isValidVerdictReasonStableValue(string) == false {
    failures.insert("pattern")
  }
}

private func isValidVerdictReasonStableValue(_ value: String) -> Bool {
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

private func checkVerdictReasonSummaryKey(
  _ value: Any?,
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
  if string.unicodeScalars.count > 256 {
    failures.insert("maxLength")
  }
  let segments = string.split(separator: ".", omittingEmptySubsequences: false)
  if segments.isEmpty
    || segments.contains(where: {
      $0.utf8.count > 128 || isValidVerdictReasonStableValue(String($0)) == false
    })
  {
    failures.insert("pattern")
  }
}

private func checkVerdictReasonObservedAt(
  _ value: Any?,
  failures: inout Set<String>
) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }

  if string.range(of: verdictReasonObservedAtPattern, options: .regularExpression) == nil {
    failures.insert("pattern")
  }
  if isRealVerdictReasonDateTime(string) == false {
    failures.insert("format")
  }
}

private func isRealVerdictReasonDateTime(_ value: String) -> Bool {
  let pattern =
    #"^([0-9]{4})-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(?:\.[0-9]+)?(?:[Zz]|[+-](?:[01][0-9]|2[0-3]):[0-5][0-9])$"#
  guard let expression = try? NSRegularExpression(pattern: pattern) else {
    return false
  }
  let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
  guard let match = expression.firstMatch(in: value, range: fullRange), match.range == fullRange,
    let year = integerCapture(1, from: match, in: value),
    let month = integerCapture(2, from: match, in: value),
    let day = integerCapture(3, from: match, in: value)
  else {
    return false
  }

  let maximumDay: Int
  switch month {
  case 2:
    let isLeapYear =
      year.isMultiple(of: 400)
      || (year.isMultiple(of: 4) && year.isMultiple(of: 100) == false)
    maximumDay = isLeapYear ? 29 : 28
  case 4, 6, 9, 11:
    maximumDay = 30
  default:
    maximumDay = 31
  }
  return (1...maximumDay).contains(day)
}

private func integerCapture(
  _ index: Int,
  from match: NSTextCheckingResult,
  in value: String
) -> Int? {
  guard let range = Range(match.range(at: index), in: value) else {
    return nil
  }
  return Int(value[range])
}
