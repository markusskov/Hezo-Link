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
    #expect(info["version"] as? String == "1.10.0")
    #expect(try requireString(info["description"]).isEmpty == false)

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(
      Set(schemas.keys)
        == [
          "CheckRequestV1", "RequestIDV1", "CanonicalInstantV1", "ProblemV1", "VerdictReasonV1",
          "VerdictLabelV1",
          "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1",
          "VerdictReasonsV1", "CheckResponseStatusV1", "CheckTokenV1",
          "PendingCheckResponseV1", "VerdictV1",
        ]
    )
    let checkRequest = try requireObject(schemas["CheckRequestV1"])
    #expect(Set(checkRequest.keys) == ["$ref"])
    #expect(checkRequest["$ref"] as? String == "./schemas/check-request-v1.schema.json")

    let requestID = try requireObject(schemas["RequestIDV1"])
    #expect(Set(requestID.keys) == ["$ref"])
    #expect(requestID["$ref"] as? String == requestIDOpenAPIReference)

    let problem = try requireObject(schemas["ProblemV1"])
    #expect(Set(problem.keys) == ["$ref"])
    #expect(problem["$ref"] as? String == "./schemas/problem-v1.schema.json")

    let verdictReason = try requireObject(schemas["VerdictReasonV1"])
    #expect(Set(verdictReason.keys) == ["$ref"])
    #expect(
      verdictReason["$ref"] as? String == "./schemas/verdict-reason-v1.schema.json"
    )

    let verdictLabel = try requireObject(schemas["VerdictLabelV1"])
    #expect(Set(verdictLabel.keys) == ["$ref"])
    #expect(verdictLabel["$ref"] as? String == "./schemas/verdict-label-v1.schema.json")

    let recommendedAction = try requireObject(schemas["RecommendedActionV1"])
    #expect(Set(recommendedAction.keys) == ["$ref"])
    #expect(
      recommendedAction["$ref"] as? String
        == "./schemas/recommended-action-v1.schema.json"
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

    let referencedRequestIDSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(requestIDOpenAPIReference)
      .standardizedFileURL
    let requestIDSchemaURL = repositoryRoot.appendingPathComponent(requestIDSchemaPath)
      .standardizedFileURL
    #expect(referencedRequestIDSchemaURL == requestIDSchemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedRequestIDSchemaURL.path))

    let referencedVerdictReasonSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent("schemas/verdict-reason-v1.schema.json")
      .standardizedFileURL
    let verdictReasonSchemaURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/schemas/verdict-reason-v1.schema.json"
    ).standardizedFileURL
    #expect(referencedVerdictReasonSchemaURL == verdictReasonSchemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedVerdictReasonSchemaURL.path))

    for path in [
      "verdict-label-v1.schema.json", "recommended-action-v1.schema.json",
      "confidence-category-v1.schema.json", "evaluated-scope-v1.schema.json",
      "verdict-reasons-v1.schema.json", "check-response-status-v1.schema.json",
      "check-token-v1.schema.json", "pending-check-response-v1.schema.json",
      "verdict-v1.schema.json",
    ] {
      let referencedPrimitiveSchemaURL = openAPIURL.deletingLastPathComponent()
        .appendingPathComponent("schemas/\(path)")
        .standardizedFileURL
      let primitiveSchemaURL = repositoryRoot.appendingPathComponent(
        "packages/contracts/schemas/\(path)"
      ).standardizedFileURL
      #expect(referencedPrimitiveSchemaURL == primitiveSchemaURL)
      #expect(FileManager.default.fileExists(atPath: referencedPrimitiveSchemaURL.path))
    }

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
    #expect(Set(requestID.keys) == ["$ref"])
    #expect(requestID["$ref"] as? String == requestIDSchemaID)

    let requestIDRegistry = try loadProblemSchemaRegistry()
    let resolvedRequestID = try resolveFrozenProblemRequestIDSchema(
      from: schema,
      registry: requestIDRegistry
    )
    #expect(resolvedRequestID["$id"] as? String == requestIDSchemaID)

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
    let schema = try loadObject("packages/contracts/schemas/problem-v1.schema.json")
    let registry = try loadProblemSchemaRegistry()
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
      let failures = try problemSchemaFailures(in: fixture, schema: schema, registry: registry)
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

  @Test func evaluatorRequiresTheExactRegisteredAbsoluteRequestIDReference() throws {
    let schema = try loadObject("packages/contracts/schemas/problem-v1.schema.json")
    let registry = try loadProblemSchemaRegistry()
    let fixture = try loadObject(
      "packages/contracts/fixtures/problem-v1/valid/non-retryable.json"
    )
    #expect(try problemSchemaFailures(in: fixture, schema: schema, registry: registry).isEmpty)

    var unresolvedSchema = schema
    var unresolvedProperties = try requireObject(unresolvedSchema["properties"])
    unresolvedProperties["request_id"] = [
      "$ref": "urn:hezo-link:contract:unregistered:v1"
    ]
    unresolvedSchema["properties"] = unresolvedProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenProblemRequestIDSchema(from: unresolvedSchema, registry: registry)
    }

    var relativeSchema = schema
    var relativeProperties = try requireObject(relativeSchema["properties"])
    relativeProperties["request_id"] = ["$ref": "./request-id-v1.schema.json"]
    relativeSchema["properties"] = relativeProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenProblemRequestIDSchema(from: relativeSchema, registry: registry)
    }

    let requestIDSchema = try #require(registry[requestIDSchemaID])
    var inlinedSchema = schema
    var inlinedProperties = try requireObject(inlinedSchema["properties"])
    inlinedProperties["request_id"] = requestIDSchema
    inlinedSchema["properties"] = inlinedProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenProblemRequestIDSchema(from: inlinedSchema, registry: registry)
    }

    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenProblemRequestIDSchema(from: schema, registry: [:])
    }

    var mismatchedRegistry = registry
    var mismatchedRequestIDSchema = requestIDSchema
    mismatchedRequestIDSchema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    mismatchedRegistry[requestIDSchemaID] = mismatchedRequestIDSchema
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenProblemRequestIDSchema(
        from: schema,
        registry: mismatchedRegistry
      )
    }
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

    let schema = try loadObject("packages/contracts/schemas/problem-v1.schema.json")
    let registry = try loadProblemSchemaRegistry()
    #expect(try problemSchemaFailures(in: fixture, schema: schema, registry: registry).isEmpty)
    let data = try JSONSerialization.data(withJSONObject: fixture, options: [.sortedKeys])
    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)
    }
  }

  @Test func schemaStrictnessAndResponseReaderToleranceStayDistinct() throws {
    let relativePath =
      "packages/contracts/fixtures/problem-v1/invalid/unknown-field.json"
    let fixture = try loadObject(relativePath)
    let schema = try loadObject("packages/contracts/schemas/problem-v1.schema.json")
    let registry = try loadProblemSchemaRegistry()
    #expect(
      try problemSchemaFailures(in: fixture, schema: schema, registry: registry)
        == ["additionalProperties"]
    )

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
    #expect(info["version"] as? String == "1.10.0")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let components = try requireObject(openAPI["components"])
    let schemas = try requireObject(components["schemas"])
    #expect(
      Set(schemas.keys)
        == [
          "CheckRequestV1", "RequestIDV1", "CanonicalInstantV1", "ProblemV1", "VerdictReasonV1",
          "VerdictLabelV1",
          "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1",
          "VerdictReasonsV1", "CheckResponseStatusV1", "CheckTokenV1",
          "PendingCheckResponseV1", "VerdictV1",
        ]
    )
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
    #expect(Set(observedAt.keys) == ["$ref"])
    #expect(observedAt["$ref"] as? String == canonicalInstantSchemaID)
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

struct VerdictPrimitiveContractAssetTests {
  @Test(arguments: VerdictPrimitiveContract.allCases)
  func schemaAndOpenAPIKeepEachFrozenPrimitiveSurface(
    primitive: VerdictPrimitiveContract
  ) throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(primitive.schemaPath)

    let info = try requireObject(openAPI["info"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.10.0")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let components = try requireObject(openAPI["components"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    let component = try requireObject(schemas[primitive.componentName])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == primitive.openAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(primitive.openAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(primitive.schemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "enum"])
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == primitive.schemaID)
    #expect(schema["title"] as? String == primitive.schemaTitle)
    #expect(schema["description"] as? String == primitive.schemaDescription)
    #expect(schema["type"] as? String == "string")
    #expect(try requireStringArray(schema["enum"]) == primitive.wireValues)
    if case .verdictLabel = primitive {
      #expect(VerdictLabelV1.allCases.map(\.rawValue) == primitive.wireValues)
    }
    if case .recommendedAction = primitive {
      #expect(RecommendedActionV1.allCases.map(\.rawValue) == primitive.wireValues)
    }
  }

  @Test(arguments: VerdictPrimitiveContract.allCases)
  func manifestHasCompleteUniquePrimitiveFixtureCoverage(
    primitive: VerdictPrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == primitive.contractName)
    #expect(manifest["contract_schema"] as? String == primitive.manifestSchemaReference)

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == primitive.expectedFixturePaths.count)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == primitive.expectedFixturePaths)
    #expect(Set(primitive.expectedFixturePayloads.keys) == Set(ids))
    #expect(
      Set(primitive.expectedFailureKeywords.keys)
        == Set(ids).subtracting(primitive.validFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(primitive.fixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(primitive.manifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(primitive.manifestSchemaReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(primitive.schemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test(arguments: VerdictPrimitiveContract.allCases)
  func everyPrimitiveFixtureMatchesItsDeclaredExpectation(
    primitive: VerdictPrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(primitive.fixtureRoot)/\(relativePath)")
      let payload = try primitiveFixturePayload(from: fixture)
      let failures = primitiveEnumSchemaFailures(
        in: payload,
        allowedValues: Set(primitive.wireValues)
      )

      #expect(
        payload == primitive.expectedFixturePayloads[fixtureID],
        "Primitive fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(primitive.validFixtureIDs.contains(fixtureID))
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
        #expect(expectedKeywords == primitive.expectedFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == primitive.validFixtureIDs.count)
    #expect(invalidCount == primitive.expectedFailureKeywords.count)
  }

  @Test(arguments: VerdictPrimitiveContract.allCases)
  func validPrimitiveFixturesRoundTripThroughTheSwiftReader(
    primitive: VerdictPrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(primitive.fixtureRoot)/\(path)"
      let fixtureData = try loadData(relativePath)
      let fixtureValue = try requirePrimitiveString(loadJSONValue(relativePath))

      let encodedData: Data
      switch primitive {
      case .verdictLabel:
        let canonical = try HezoJSON.makeResponseDecoder().decode(
          VerdictLabelV1.self,
          from: fixtureData
        )
        let compatibility: VerdictLabel = canonical
        let canonicalAgain: VerdictLabelV1 = compatibility
        let canonicalEncoded = try HezoJSON.makeEncoder().encode(canonical)
        let compatibilityEncoded = try HezoJSON.makeEncoder().encode(compatibility)
        let compatibilityDecoded = try HezoJSON.makeResponseDecoder().decode(
          VerdictLabel.self,
          from: compatibilityEncoded
        )

        #expect(canonical.rawValue == fixtureValue)
        #expect(canonicalAgain == canonical)
        #expect(compatibilityDecoded == canonical)
        #expect(compatibilityEncoded == canonicalEncoded)
        encodedData = canonicalEncoded
      case .recommendedAction:
        let canonical = try HezoJSON.makeResponseDecoder().decode(
          RecommendedActionV1.self,
          from: fixtureData
        )
        let compatibility: RecommendedAction = canonical
        let canonicalAgain: RecommendedActionV1 = compatibility
        let canonicalEncoded = try HezoJSON.makeEncoder().encode(canonical)
        let compatibilityEncoded = try HezoJSON.makeEncoder().encode(compatibility)
        let compatibilityDecoded = try HezoJSON.makeResponseDecoder().decode(
          RecommendedAction.self,
          from: compatibilityEncoded
        )

        #expect(canonical.rawValue == fixtureValue)
        #expect(canonicalAgain == canonical)
        #expect(compatibilityDecoded == canonical)
        #expect(compatibilityEncoded == canonicalEncoded)
        encodedData = canonicalEncoded
      }

      #expect(try requirePrimitiveString(jsonValue(from: encodedData)) == fixtureValue)
    }
  }

  @Test(arguments: VerdictPrimitiveContract.allCases)
  func invalidPrimitiveFixturesFailWithPrivacySafeErrors(
    primitive: VerdictPrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) == false {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(primitive.fixtureRoot)/\(path)"
      let data = try loadData(relativePath)
      let rejectedString = try? requirePrimitiveString(loadJSONValue(relativePath))

      do {
        try decodeVerdictPrimitive(primitive, from: data)
        Issue.record("A declared invalid primitive fixture was accepted: \(fixtureID)")
      } catch let error as DecodingError {
        if case .verdictLabel = primitive {
          let payload = try primitiveFixturePayload(from: loadJSONValue(relativePath))
          switch (payload, error) {
          case (.string, .dataCorrupted(let context)):
            #expect(context.codingPath.isEmpty)
            #expect(context.debugDescription == "Invalid public verdict label.")
            #expect(context.underlyingError == nil)
          case (.integer, .typeMismatch(let type, let context)):
            #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
            #expect(context.codingPath.isEmpty)
            #expect(
              context.debugDescription == "Expected to decode String but found number instead."
            )
            #expect(context.underlyingError == nil)
          case (.null, .valueNotFound(let type, let context)):
            #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
            #expect(context.codingPath.isEmpty)
            #expect(
              context.debugDescription
                == "Cannot get value of type String -- found null value instead"
            )
            #expect(context.underlyingError == nil)
          default:
            Issue.record("VerdictLabelV1 used the wrong DecodingError case: \(fixtureID)")
          }
        }
        if case .recommendedAction = primitive {
          let payload = try primitiveFixturePayload(from: loadJSONValue(relativePath))
          switch (payload, error) {
          case (.string, .dataCorrupted(let context)):
            #expect(context.codingPath.isEmpty)
            #expect(context.debugDescription == "Invalid recommended action.")
            #expect(context.underlyingError == nil)
          case (.integer, .typeMismatch(let type, let context)):
            #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
            #expect(context.codingPath.isEmpty)
            #expect(
              context.debugDescription == "Expected to decode String but found number instead."
            )
            #expect(context.underlyingError == nil)
          case (.null, .valueNotFound(let type, let context)):
            #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
            #expect(context.codingPath.isEmpty)
            #expect(
              context.debugDescription
                == "Cannot get value of type String -- found null value instead"
            )
            #expect(context.underlyingError == nil)
          default:
            Issue.record("RecommendedActionV1 used the wrong DecodingError case: \(fixtureID)")
          }
        }
        if let rejectedString, rejectedString.isEmpty == false {
          #expect(String(describing: error).contains(rejectedString) == false)
          #expect(String(reflecting: error).contains(rejectedString) == false)
        }
      } catch {
        Issue.record("Primitive decoding used an unexpected error category: \(fixtureID)")
      }
    }
  }

  @Test(arguments: VerdictPrimitiveContract.allCases)
  func rejectedPrimitiveCanaryIsNeverReflected(
    primitive: VerdictPrimitiveContract
  ) throws {
    let rejectedCandidate = "PRIVATE_SENTINEL_\(primitive.contractName.uppercased())"
    let data = try JSONEncoder().encode(rejectedCandidate)

    do {
      try decodeVerdictPrimitive(primitive, from: data)
      Issue.record("A privacy-canary primitive value was accepted: \(primitive.contractName)")
    } catch let error as DecodingError {
      if case .verdictLabel = primitive {
        guard case .dataCorrupted(let context) = error else {
          Issue.record("VerdictLabelV1 privacy canary used the wrong DecodingError case")
          return
        }
        #expect(context.codingPath.isEmpty)
        #expect(context.debugDescription == "Invalid public verdict label.")
        #expect(context.underlyingError == nil)
      }
      if case .recommendedAction = primitive {
        guard case .dataCorrupted(let context) = error else {
          Issue.record("RecommendedActionV1 privacy canary used the wrong DecodingError case")
          return
        }
        #expect(context.codingPath.isEmpty)
        #expect(context.debugDescription == "Invalid recommended action.")
        #expect(context.underlyingError == nil)
      }
      #expect(String(describing: error).contains(rejectedCandidate) == false)
      #expect(String(reflecting: error).contains(rejectedCandidate) == false)
    } catch {
      Issue.record("Primitive privacy canary used an unexpected error category")
    }
  }

  @Test func standalonePrimitiveValidityDoesNotAuthorizeACompleteVerdict() throws {
    let readmeData = try loadData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(verdictPrimitiveBoundarySentence))

    for primitive in VerdictPrimitiveContract.allCases {
      let schema = try loadObject(primitive.schemaPath)
      #expect(schema["type"] as? String == "string")
      #expect(schema["properties"] == nil)
      #expect(schema["required"] == nil)
      #expect(schema["allOf"] == nil)
      #expect(schema["anyOf"] == nil)
      #expect(schema["oneOf"] == nil)
    }

    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    // Pair coherence and evidence-bearing verdict authorization require a separate frozen envelope.
  }
}

struct CheckResponseStatusContractAssetTests {
  @Test func schemaAndOpenAPIKeepTheFrozenCheckResponseStatusV1Surface() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(checkResponseStatusSchemaPath)

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
    #expect(info["version"] as? String == "1.10.0")
    #expect(
      info["description"] as? String
        == "Reusable offline check-input, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
    )

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    let component = try requireObject(schemas["CheckResponseStatusV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == checkResponseStatusOpenAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(checkResponseStatusOpenAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(checkResponseStatusSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "enum"])
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == "urn:hezo-link:contract:check-response-status:v1")
    #expect(schema["title"] as? String == "Hezo Link check response status V1")
    #expect(
      schema["description"] as? String
        == "Exact standalone check-response status primitive. This value alone defines no endpoint, response branch, HTTP status, token, retry behavior, or check-response envelope."
    )
    #expect(schema["type"] as? String == "string")
    #expect(try requireStringArray(schema["enum"]) == checkResponseStatusWireValues)
    #expect(CheckResponseStatusV1.allCases.map(\.rawValue) == checkResponseStatusWireValues)
  }

  @Test func manifestHasCompleteUniqueCheckResponseStatusFixtureCoverage() throws {
    let manifest = try loadObject(checkResponseStatusManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "check-response-status-v1")
    #expect(manifest["contract_schema"] as? String == checkResponseStatusManifestSchemaReference)

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == checkResponseStatusFixturePaths.count)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == checkResponseStatusFixturePaths)
    #expect(Set(checkResponseStatusFixturePayloads.keys) == Set(ids))
    #expect(
      Set(checkResponseStatusFailureKeywords.keys)
        == Set(ids).subtracting(checkResponseStatusValidFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(checkResponseStatusFixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(checkResponseStatusManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(checkResponseStatusManifestSchemaReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(checkResponseStatusSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyFixtureMatchesItsExactScalarIntentAndKeywordSet() throws {
    let manifest = try loadObject(checkResponseStatusManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(checkResponseStatusFixtureRoot)/\(path)")
      let payload = try primitiveFixturePayload(from: fixture)
      let failures = primitiveEnumSchemaFailures(
        in: payload,
        allowedValues: Set(checkResponseStatusWireValues)
      )

      #expect(
        payload == checkResponseStatusFixturePayloads[fixtureID],
        "Check-response status fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(checkResponseStatusValidFixtureIDs.contains(fixtureID))
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords = try declaredFailureKeywords(in: fixtureCase)
        #expect(expectedKeywords == checkResponseStatusFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 2)
    #expect(invalidCount == 8)
  }

  @Test func validFixturesRoundTripThroughCanonicalReaderAndCompatibilityAlias() throws {
    let manifest = try loadObject(checkResponseStatusManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var decodedRawValues = Set<String>()

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(checkResponseStatusFixtureRoot)/\(path)"
      let fixtureValue = try requirePrimitiveString(loadJSONValue(relativePath))
      let canonical = try HezoJSON.makeResponseDecoder().decode(
        CheckResponseStatusV1.self,
        from: loadData(relativePath)
      )
      let compatibility: CheckResponseStatus = canonical
      let canonicalAgain: CheckResponseStatusV1 = compatibility
      let canonicalEncoded = try HezoJSON.makeEncoder().encode(canonical)
      let compatibilityEncoded = try HezoJSON.makeEncoder().encode(compatibility)
      let compatibilityDecoded = try HezoJSON.makeResponseDecoder().decode(
        CheckResponseStatus.self,
        from: compatibilityEncoded
      )

      #expect(canonical.rawValue == fixtureValue)
      #expect(canonicalAgain == canonical)
      #expect(compatibilityDecoded == canonical)
      #expect(compatibilityEncoded == canonicalEncoded)
      #expect(try requirePrimitiveString(jsonValue(from: canonicalEncoded)) == fixtureValue)
      decodedRawValues.insert(canonical.rawValue)
    }

    #expect(decodedRawValues == Set(checkResponseStatusWireValues))
  }

  @Test func invalidFixturesFailThroughTheSwiftReaderWithoutReflectingCandidates() throws {
    let manifest = try loadObject(checkResponseStatusManifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) == false {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(checkResponseStatusFixtureRoot)/\(path)"
      let data = try loadData(relativePath)
      let payload = try primitiveFixturePayload(from: loadJSONValue(relativePath))
      let rejectedString = try? requirePrimitiveString(loadJSONValue(relativePath))

      do {
        _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatusV1.self, from: data)
        Issue.record("A declared invalid check-response status fixture was accepted: \(fixtureID)")
      } catch let error as DecodingError {
        switch (payload, error) {
        case (.string, .dataCorrupted(let context)):
          #expect(context.codingPath.isEmpty)
          #expect(context.debugDescription == "Invalid check-response status.")
          #expect(context.underlyingError == nil)
        case (.integer, .typeMismatch(let type, let context)):
          #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
          #expect(context.codingPath.isEmpty)
          #expect(context.underlyingError == nil)
        case (.null, .valueNotFound(let type, let context)):
          #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
          #expect(context.codingPath.isEmpty)
          #expect(context.underlyingError == nil)
        default:
          Issue.record(
            "Check-response status decoding used the wrong DecodingError case: \(fixtureID)"
          )
        }
        if let rejectedString, rejectedString.isEmpty == false {
          #expect(String(describing: error).contains(rejectedString) == false)
          #expect(String(reflecting: error).contains(rejectedString) == false)
        }
      } catch {
        Issue.record(
          "Check-response status decoding used an unexpected error category: \(fixtureID)")
      }
    }
  }

  @Test func rejectedPrivacyCanaryIsNeverReflected() throws {
    let rejectedCandidate = "PRIVATE_SENTINEL_CHECK_RESPONSE_STATUS"
    let data = try JSONEncoder().encode(rejectedCandidate)

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(CheckResponseStatusV1.self, from: data)
      Issue.record("A privacy-canary check-response status was accepted")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Check-response status privacy canary used the wrong DecodingError case")
        return
      }
      #expect(context.codingPath.isEmpty)
      #expect(context.debugDescription == "Invalid check-response status.")
      #expect(context.underlyingError == nil)
      #expect(String(describing: error).contains(rejectedCandidate) == false)
      #expect(String(reflecting: error).contains(rejectedCandidate) == false)
    } catch {
      Issue.record("Check-response status privacy canary used an unexpected error category")
    }
  }

  @Test func standaloneStatusDoesNotAuthorizeAResponseBranchOrProtocolBehavior() throws {
    let readmeData = try loadData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(checkResponseStatusBoundarySentence))

    let schema = try loadObject(checkResponseStatusSchemaPath)
    #expect(schema["type"] as? String == "string")
    #expect(schema["properties"] == nil)
    #expect(schema["required"] == nil)
    #expect(schema["allOf"] == nil)
    #expect(schema["anyOf"] == nil)
    #expect(schema["oneOf"] == nil)

    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
    // Scalar validity proves no branch members, HTTP mapping, token, retry, polling, or envelope.
  }
}

struct PendingCheckResponseContractAssetTests {
  @Test func pendingCheckResponseBoundariesStayExplicit() throws {
    let readmeData = try loadData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(pendingCheckResponseBoundarySentence))

    let schema = try loadObject(pendingCheckResponseSchemaPath)
    let properties = try requireObject(schema["properties"])
    for unauthorizedField in [
      "verdict", "target", "analysis", "source_notices", "versions", "evaluated_at",
      "valid_until", "block_eligible",
    ] {
      #expect(properties[unauthorizedField] == nil)
    }

    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
  }

  @Test func schemaAndOpenAPIKeepTheFrozenPendingResponseSurfaceAndReference() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(pendingCheckResponseSchemaPath)

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
    #expect(info["version"] as? String == "1.10.0")
    #expect(
      info["description"] as? String
        == "Reusable offline check-input, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
    )

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    #expect(schemas.count == 14)
    let component = try requireObject(schemas["PendingCheckResponseV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == pendingCheckResponseOpenAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(pendingCheckResponseOpenAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(pendingCheckResponseSchemaPath)
      .standardizedFileURL
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
    #expect(schema["$id"] as? String == pendingCheckResponseSchemaID)
    #expect(schema["title"] as? String == "Hezo Link pending check response V1")
    #expect(try requireString(schema["description"]).isEmpty == false)
    #expect(schema["type"] as? String == "object")
    #expect(try requireBool(schema["additionalProperties"]) == false)
    #expect(try requireStringArray(schema["required"]) == pendingCheckResponseFields)

    let properties = try requireObject(schema["properties"])
    #expect(Set(properties.keys) == Set(pendingCheckResponseFields))
    try expectIntegerConstant(properties["schema_version"], constant: 1)

    let status = try requireObject(properties["status"])
    #expect(Set(status.keys) == ["$ref", "const"])
    #expect(status["$ref"] as? String == checkResponseStatusSchemaID)
    #expect(status["const"] as? String == "pending")

    let checkToken = try requireObject(properties["check_token"])
    #expect(Set(checkToken.keys) == ["$ref"])
    #expect(checkToken["$ref"] as? String == checkTokenSchemaID)

    let retryAfter = try requireObject(properties["retry_after_ms"])
    #expect(Set(retryAfter.keys) == ["type", "minimum", "maximum", "description"])
    #expect(retryAfter["type"] as? String == "integer")
    #expect(integerValue(retryAfter["minimum"]) == 1)
    #expect(integerValue(retryAfter["maximum"]) == 900_000)
    #expect(try requireString(retryAfter["description"]).isEmpty == false)

    let expiresAt = try requireObject(properties["expires_at"])
    #expect(Set(expiresAt.keys) == ["$ref"])
    #expect(expiresAt["$ref"] as? String == canonicalInstantSchemaID)

    let requestID = try requireObject(properties["request_id"])
    #expect(Set(requestID.keys) == ["$ref"])
    #expect(requestID["$ref"] as? String == requestIDSchemaID)

    let registry = try loadPendingCheckResponseSchemaRegistry()
    let resolvedStatus = try resolveFrozenPendingCheckResponseStatusSchema(
      from: schema,
      registry: registry
    )
    let resolvedCheckToken = try resolveFrozenPendingCheckResponseCheckTokenSchema(
      from: schema,
      registry: registry
    )
    let resolvedCanonicalInstant = try resolveFrozenPendingCheckResponseCanonicalInstantSchema(
      from: schema,
      registry: registry
    )
    let resolvedRequestID = try resolveFrozenPendingCheckResponseRequestIDSchema(
      from: schema,
      registry: registry
    )
    #expect(resolvedStatus["$id"] as? String == checkResponseStatusSchemaID)
    #expect(resolvedCheckToken["$id"] as? String == checkTokenSchemaID)
    #expect(resolvedCanonicalInstant["$id"] as? String == canonicalInstantSchemaID)
    #expect(resolvedRequestID["$id"] as? String == requestIDSchemaID)
    #expect(PendingCheckResponseV1.schemaVersion == 1)
    #expect(PendingCheckResponseV1.status == .pending)
    #expect(PendingCheckResponseV1.minimumRetryAfterMilliseconds == 1)
    #expect(PendingCheckResponseV1.maximumRetryAfterMilliseconds == 900_000)
    #expect(PendingCheckResponseV1.maximumRequestIDByteCount == 128)
    #expect(CheckTokenV1.encodedCharacterCount == 43)
    #expect(CheckTokenV1.decodedByteCount == 32)
  }

  @Test func manifestPinsTheExactUniqueFortySevenCaseMatrixAndDiskCoverage() throws {
    let manifest = try loadObject(pendingCheckResponseManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "pending-check-response-v1")
    #expect(manifest["contract_schema"] as? String == pendingCheckResponseManifestSchemaReference)

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == 47)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(ids == pendingCheckResponseFixtureIDsInOrder)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == pendingCheckResponseFixturePaths)
    #expect(Set(pendingCheckResponseFixturePaths.keys) == Set(ids))
    #expect(
      Set(pendingCheckResponseFailureKeywords.keys)
        == Set(ids).subtracting(pendingCheckResponseValidFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(pendingCheckResponseFixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(pendingCheckResponseManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(pendingCheckResponseManifestSchemaReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(pendingCheckResponseSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyFixtureMatchesItsExactPayloadPurposeAndKeywordSet() throws {
    let manifest = try loadObject(pendingCheckResponseManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let schema = try loadObject(pendingCheckResponseSchemaPath)
    let registry = try loadPendingCheckResponseSchemaRegistry()
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(pendingCheckResponseFixtureRoot)/\(path)")
      let expectedFixture = try expectedPendingCheckResponseFixture(id: fixtureID)
      let failures = try pendingCheckResponseSchemaFailures(
        in: fixture,
        schema: schema,
        registry: registry
      )

      #expect(
        try jsonValuesAreEqual(fixture, expectedFixture),
        "Pending Check Response V1 fixture payload drifted from its purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(pendingCheckResponseValidFixtureIDs.contains(fixtureID))
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords = try declaredFailureKeywords(in: fixtureCase)
        #expect(expectedKeywords == pendingCheckResponseFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 5)
    #expect(invalidCount == 42)
  }

  @Test func evaluatorRequiresTheExactRegisteredAbsoluteReferences() throws {
    let schema = try loadObject(pendingCheckResponseSchemaPath)
    let registry = try loadPendingCheckResponseSchemaRegistry()
    let fixture = try loadJSONValue(
      "\(pendingCheckResponseFixtureRoot)/valid/standard.json"
    )
    #expect(
      try pendingCheckResponseSchemaFailures(in: fixture, schema: schema, registry: registry)
        .isEmpty
    )

    var unresolvedSchema = schema
    var unresolvedProperties = try requireObject(unresolvedSchema["properties"])
    unresolvedProperties["status"] = [
      "$ref": "urn:hezo-link:contract:unregistered:v1", "const": "pending",
    ]
    unresolvedSchema["properties"] = unresolvedProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseStatusSchema(
        from: unresolvedSchema,
        registry: registry
      )
    }

    var relativeSchema = schema
    var relativeProperties = try requireObject(relativeSchema["properties"])
    relativeProperties["status"] = [
      "$ref": "./check-response-status-v1.schema.json", "const": "pending",
    ]
    relativeSchema["properties"] = relativeProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseStatusSchema(
        from: relativeSchema,
        registry: registry
      )
    }

    let statusSchema = try #require(registry[checkResponseStatusSchemaID])
    var inlinedSchema = schema
    var inlinedProperties = try requireObject(inlinedSchema["properties"])
    inlinedProperties["status"] = statusSchema
    inlinedSchema["properties"] = inlinedProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseStatusSchema(
        from: inlinedSchema,
        registry: registry
      )
    }

    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseStatusSchema(from: schema, registry: [:])
    }

    var mismatchedRegistry = registry
    var mismatchedStatusSchema = statusSchema
    mismatchedStatusSchema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    mismatchedRegistry[checkResponseStatusSchemaID] = mismatchedStatusSchema
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseStatusSchema(
        from: schema,
        registry: mismatchedRegistry
      )
    }

    var unresolvedRequestIDSchema = schema
    var unresolvedRequestIDProperties = try requireObject(
      unresolvedRequestIDSchema["properties"]
    )
    unresolvedRequestIDProperties["request_id"] = [
      "$ref": "urn:hezo-link:contract:unregistered:v1"
    ]
    unresolvedRequestIDSchema["properties"] = unresolvedRequestIDProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseRequestIDSchema(
        from: unresolvedRequestIDSchema,
        registry: registry
      )
    }

    var relativeRequestIDSchema = schema
    var relativeRequestIDProperties = try requireObject(relativeRequestIDSchema["properties"])
    relativeRequestIDProperties["request_id"] = ["$ref": "./request-id-v1.schema.json"]
    relativeRequestIDSchema["properties"] = relativeRequestIDProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseRequestIDSchema(
        from: relativeRequestIDSchema,
        registry: registry
      )
    }

    let requestIDSchema = try #require(registry[requestIDSchemaID])
    var inlinedRequestIDSchema = schema
    var inlinedRequestIDProperties = try requireObject(inlinedRequestIDSchema["properties"])
    inlinedRequestIDProperties["request_id"] = requestIDSchema
    inlinedRequestIDSchema["properties"] = inlinedRequestIDProperties
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseRequestIDSchema(
        from: inlinedRequestIDSchema,
        registry: registry
      )
    }

    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseRequestIDSchema(
        from: schema,
        registry: [checkResponseStatusSchemaID: statusSchema]
      )
    }

    var mismatchedRequestIDRegistry = registry
    var mismatchedRequestIDSchema = requestIDSchema
    mismatchedRequestIDSchema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    mismatchedRequestIDRegistry[requestIDSchemaID] = mismatchedRequestIDSchema
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckResponseRequestIDSchema(
        from: schema,
        registry: mismatchedRequestIDRegistry
      )
    }
  }

  @Test func allFiveValidFixturesDecodeAndReencodeWithoutWireDrift() throws {
    let manifest = try loadObject(pendingCheckResponseManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var decodedCount = 0

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      decodedCount += 1
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(pendingCheckResponseFixtureRoot)/\(path)"
      let fixture = try loadJSONValue(relativePath)
      let decoded = try HezoJSON.makeResponseDecoder().decode(
        PendingCheckResponseV1.self,
        from: loadData(relativePath)
      )
      let encoded = try HezoJSON.makeEncoder().encode(decoded)
      let encodedValue = try jsonValue(from: encoded)

      #expect(
        try jsonValuesAreEqual(encodedValue, fixture),
        "Pending Check Response V1 reader changed a valid fixture: \(fixtureID)"
      )
      #expect(Set(try requireObject(encodedValue).keys) == Set(pendingCheckResponseFields))
    }

    #expect(decodedCount == 5)
  }

  @Test func strictUnknownFieldFailsSchemaWhileSwiftReaderDropsIt() throws {
    let relativePath =
      "\(pendingCheckResponseFixtureRoot)/invalid/unknown-future-field.json"
    let schema = try loadObject(pendingCheckResponseSchemaPath)
    let registry = try loadPendingCheckResponseSchemaRegistry()
    let fixture = try loadJSONValue(relativePath)
    #expect(
      try pendingCheckResponseSchemaFailures(in: fixture, schema: schema, registry: registry)
        == ["additionalProperties"]
    )

    let decoded = try HezoJSON.makeResponseDecoder().decode(
      PendingCheckResponseV1.self,
      from: loadData(relativePath)
    )
    let encoded = try requireObject(jsonValue(from: HezoJSON.makeEncoder().encode(decoded)))
    var expectedKnownFields = try requireObject(fixture)
    expectedKnownFields.removeValue(forKey: "future_optional")
    #expect(encoded["future_optional"] == nil)
    #expect(try jsonValuesAreEqual(encoded, expectedKnownFields))
  }

  @Test func allEightKnownHybridAndEnforcementFixturesFailTheSwiftReader() throws {
    let manifest = try loadObject(pendingCheckResponseManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let selected = try cases.filter {
      pendingCheckResponseForbiddenFixtureIDs.contains(try requireString($0["id"]))
    }
    #expect(selected.count == 8)
    #expect(
      Set(try selected.map { try requireString($0["id"]) })
        == pendingCheckResponseForbiddenFixtureIDs)

    for fixtureCase in selected {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(pendingCheckResponseFixtureRoot)/\(path)"
      try expectPendingCheckResponseDecodeFailure(
        from: loadData(relativePath),
        fixtureID: fixtureID,
        privateCandidates: pendingCheckResponsePrivateCandidates(
          in: try loadJSONValue(relativePath)
        )
      )
    }
  }

  @Test func everyOtherInvalidFixtureFailsTheSwiftReaderSafely() throws {
    let manifest = try loadObject(pendingCheckResponseManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var testedCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      guard try requireBool(fixtureCase["expected_schema_valid"]) == false,
        fixtureID != "reject-unknown-future-field",
        pendingCheckResponseForbiddenFixtureIDs.contains(fixtureID) == false
      else {
        continue
      }
      testedCount += 1
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(pendingCheckResponseFixtureRoot)/\(path)"
      let fixture = try loadJSONValue(relativePath)
      try expectPendingCheckResponseDecodeFailure(
        from: loadData(relativePath),
        fixtureID: fixtureID,
        privateCandidates: pendingCheckResponsePrivateCandidates(in: fixture)
      )
    }

    #expect(testedCount == 33)
  }

  @Test func rejectedPrivacyCanariesNeverAppearInErrors() throws {
    let base = try requireObject(expectedPendingCheckResponseFixture(id: "valid-standard"))
    let canaries = [
      ("check_token", "PRIVATE_SENTINEL_PENDING_CHECK_TOKEN"),
      ("request_id", "PRIVATE_SENTINEL.PENDING.REQUEST"),
      ("expires_at", "PRIVATE_SENTINEL_PENDING_EXPIRY"),
      ("status", "PRIVATE_SENTINEL_PENDING_STATUS"),
      ("verdict", "PRIVATE_SENTINEL_PENDING_VERDICT"),
    ]

    for (field, candidate) in canaries {
      var payload = base
      payload[field] = candidate
      let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
      try expectPendingCheckResponseDecodeFailure(
        from: data,
        fixtureID: "privacy-canary-\(field)",
        privateCandidates: [candidate]
      )
    }

    let tokenCandidate = "PRIVATE_SENTINEL_DIRECT_TOKEN"
    do {
      _ = try CheckTokenV1(validating: tokenCandidate)
      Issue.record("A direct privacy-canary check token was accepted")
    } catch let error as CheckTokenContractError {
      #expect(String(describing: error).contains(tokenCandidate) == false)
      #expect(String(reflecting: error).contains(tokenCandidate) == false)
    } catch {
      Issue.record("Direct check-token validation used an unexpected error category")
    }
  }
}

struct VerdictSupportingStablePrimitiveContractAssetTests {
  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func schemaAndOpenAPIKeepEachFrozenStablePrimitiveSurface(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(primitive.schemaPath)

    let info = try requireObject(openAPI["info"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.10.0")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let components = try requireObject(openAPI["components"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    let component = try requireObject(schemas[primitive.componentName])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == primitive.openAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(primitive.openAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(primitive.schemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(
      Set(schema.keys)
        == [
          "$schema", "$id", "title", "description", "type", "minLength", "maxLength",
          "pattern",
        ]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == primitive.schemaID)
    #expect(schema["title"] as? String == primitive.schemaTitle)
    #expect(schema["description"] as? String == primitive.schemaDescription)
    #expect(schema["type"] as? String == "string")
    #expect(integerValue(schema["minLength"]) == 1)
    #expect(integerValue(schema["maxLength"]) == 128)
    #expect(schema["pattern"] as? String == verdictReasonStableValuePattern)
  }

  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func manifestHasCompleteUniqueStablePrimitiveFixtureCoverage(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == primitive.contractName)
    #expect(manifest["contract_schema"] as? String == primitive.manifestSchemaReference)

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == primitive.expectedFixturePaths.count)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == primitive.expectedFixturePaths)
    #expect(Set(primitive.expectedFixturePayloads.keys) == Set(ids))
    #expect(
      Set(primitive.expectedFailureKeywords.keys)
        == Set(ids).subtracting(primitive.validFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(primitive.fixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(primitive.manifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(primitive.manifestSchemaReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(primitive.schemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func everyStablePrimitiveFixtureMatchesItsExactIntentAndKeywordSet(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(primitive.fixtureRoot)/\(relativePath)")
      let payload = try primitiveFixturePayload(from: fixture)
      let failures = stableStringSchemaFailures(in: payload)

      #expect(
        payload == primitive.expectedFixturePayloads[fixtureID],
        "Stable primitive fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(primitive.validFixtureIDs.contains(fixtureID))
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords = try declaredFailureKeywords(in: fixtureCase)
        #expect(expectedKeywords == primitive.expectedFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == primitive.validFixtureIDs.count)
    #expect(invalidCount == primitive.expectedFailureKeywords.count)
  }

  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func validStablePrimitiveFixturesRoundTripThroughTheSwiftReader(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(primitive.fixtureRoot)/\(path)"
      let fixtureValue = try requirePrimitiveString(loadJSONValue(relativePath))
      let (decodedValue, encodedData) = try roundTripSupportingStablePrimitive(
        primitive,
        data: loadData(relativePath)
      )

      #expect(decodedValue == fixtureValue)
      #expect(try requirePrimitiveString(jsonValue(from: encodedData)) == fixtureValue)
    }
  }

  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func invalidStablePrimitiveFixturesFailWithPrivacySafeErrors(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let manifest = try loadObject(primitive.manifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) == false {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(primitive.fixtureRoot)/\(path)"
      let data = try loadData(relativePath)
      let rejectedString = try? requirePrimitiveString(loadJSONValue(relativePath))

      do {
        _ = try roundTripSupportingStablePrimitive(primitive, data: data)
        Issue.record("A declared invalid stable primitive fixture was accepted: \(fixtureID)")
      } catch let error as DecodingError {
        if let rejectedString, rejectedString.isEmpty == false {
          #expect(String(describing: error).contains(rejectedString) == false)
          #expect(String(reflecting: error).contains(rejectedString) == false)
        }
      } catch {
        Issue.record("Stable primitive decoding used an unexpected error category: \(fixtureID)")
      }
    }
  }

  @Test(arguments: VerdictSupportingStablePrimitiveContract.allCases)
  func rejectedStablePrimitiveCanaryIsNeverReflected(
    primitive: VerdictSupportingStablePrimitiveContract
  ) throws {
    let rejectedCandidate = "PRIVATE_SENTINEL_\(primitive.contractName.uppercased())"
    let data = try JSONEncoder().encode(rejectedCandidate)

    do {
      _ = try roundTripSupportingStablePrimitive(primitive, data: data)
      Issue.record("A privacy-canary stable primitive was accepted: \(primitive.contractName)")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains(rejectedCandidate) == false)
      #expect(String(reflecting: error).contains(rejectedCandidate) == false)
    } catch {
      Issue.record("Stable primitive privacy canary used an unexpected error category")
    }
  }
}

struct VerdictReasonsContractAssetTests {
  @Test func schemaAndOpenAPIKeepTheFrozenVerdictReasonsV1SurfaceAndReference() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(verdictReasonsSchemaPath)

    let info = try requireObject(openAPI["info"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.10.0")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let components = try requireObject(openAPI["components"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    let component = try requireObject(schemas["VerdictReasonsV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == verdictReasonsOpenAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(verdictReasonsOpenAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(verdictReasonsSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(
      Set(schema.keys)
        == [
          "$schema", "$id", "title", "description", "type", "minItems", "maxItems", "items",
        ]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == verdictReasonsSchemaID)
    #expect(schema["title"] as? String == "Hezo Link verdict reasons V1")
    #expect(
      schema["description"] as? String
        == "Ordered zero-through-five array of strict Verdict Reason V1 items. Duplicate items remain structurally valid; this primitive does not define a complete verdict."
    )
    #expect(schema["type"] as? String == "array")
    #expect(integerValue(schema["minItems"]) == 0)
    #expect(integerValue(schema["maxItems"]) == 5)
    let items = try requireObject(schema["items"])
    #expect(Set(items.keys) == ["$ref"])
    #expect(items["$ref"] as? String == verdictReasonSchemaID)

    let reasonSchema = try loadObject("packages/contracts/schemas/verdict-reason-v1.schema.json")
    #expect(reasonSchema["$id"] as? String == verdictReasonSchemaID)
    _ = try resolveFrozenVerdictReasonSchema(
      from: schema,
      registry: [verdictReasonSchemaID: reasonSchema]
    )
  }

  @Test func manifestHasCompleteUniqueVerdictReasonsFixtureCoverage() throws {
    let manifest = try loadObject(verdictReasonsManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "verdict-reasons-v1")
    #expect(
      manifest["contract_schema"] as? String
        == "../../schemas/verdict-reasons-v1.schema.json"
    )

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == expectedVerdictReasonsFixturePaths.count)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == expectedVerdictReasonsFixturePaths)
    #expect(
      Set(expectedVerdictReasonsFailureKeywords.keys)
        == Set(ids).subtracting(expectedValidVerdictReasonsFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(verdictReasonsFixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(verdictReasonsManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent("../../schemas/verdict-reasons-v1.schema.json")
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(verdictReasonsSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyVerdictReasonsFixtureMatchesItsExactIntentAndKeywordSet() throws {
    let manifest = try loadObject(verdictReasonsManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let schema = try loadObject(verdictReasonsSchemaPath)
    let reasonSchema = try loadObject("packages/contracts/schemas/verdict-reason-v1.schema.json")
    let registry = [verdictReasonSchemaID: reasonSchema]
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let relativePath = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(verdictReasonsFixtureRoot)/\(relativePath)")
      let expectedFixture = try expectedVerdictReasonsFixture(id: fixtureID)
      let failures = try verdictReasonsSchemaFailures(
        in: fixture,
        schema: schema,
        registry: registry
      )

      #expect(
        try jsonValuesAreEqual(fixture, expectedFixture),
        "Verdict Reasons fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(expectedValidVerdictReasonsFixtureIDs.contains(fixtureID))
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords = try declaredFailureKeywords(in: fixtureCase)
        #expect(expectedKeywords == expectedVerdictReasonsFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 7)
    #expect(invalidCount == 7)
    let countFixtures = try (0...5).map { count in
      try requireJSONArray(
        expectedVerdictReasonsFixture(id: "valid-\(verdictReasonCountName(count))")
      )
      .count
    }
    #expect(countFixtures == Array(0...5))
  }

  @Test func evaluatorRequiresTheExactRegisteredAbsoluteVerdictReasonReference() throws {
    let schema = try loadObject(verdictReasonsSchemaPath)
    let reasonSchema = try loadObject("packages/contracts/schemas/verdict-reason-v1.schema.json")
    let fixture = try loadJSONValue(
      "packages/contracts/fixtures/verdict-reasons-v1/valid/one.json"
    )

    var unresolvedSchema = schema
    unresolvedSchema["items"] = ["$ref": "urn:hezo-link:contract:unregistered-reason:v1"]
    #expect(throws: ContractAssetTestError.self) {
      _ = try verdictReasonsSchemaFailures(
        in: fixture,
        schema: unresolvedSchema,
        registry: [verdictReasonSchemaID: reasonSchema]
      )
    }

    var inlinedSchema = schema
    inlinedSchema["items"] = reasonSchema
    #expect(throws: ContractAssetTestError.self) {
      _ = try verdictReasonsSchemaFailures(
        in: fixture,
        schema: inlinedSchema,
        registry: [verdictReasonSchemaID: reasonSchema]
      )
    }

    var mismatchedReasonSchema = reasonSchema
    mismatchedReasonSchema["$id"] = "urn:hezo-link:contract:mismatched-reason:v1"
    #expect(throws: ContractAssetTestError.self) {
      _ = try verdictReasonsSchemaFailures(
        in: fixture,
        schema: schema,
        registry: [verdictReasonSchemaID: mismatchedReasonSchema]
      )
    }
  }

  @Test func validVerdictReasonsFixturesRoundTripWithCountOrderAndDuplicatesPreserved() throws {
    let manifest = try loadObject(verdictReasonsManifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(verdictReasonsFixtureRoot)/\(path)"
      let fixture = try loadJSONValue(relativePath)
      let fixtureArray = try requireJSONArray(fixture)
      let decoded = try HezoJSON.makeResponseDecoder().decode(
        VerdictReasons.self,
        from: loadData(relativePath)
      )
      let encoded = try HezoJSON.makeEncoder().encode(decoded)
      let encodedValue = try jsonValue(from: encoded)
      let expectedCodes = try fixtureArray.map { item in
        try requireString(requireObject(item)["code"])
      }

      #expect(decoded.count == fixtureArray.count)
      #expect(decoded.values.map { $0.code.rawValue } == expectedCodes)
      #expect(
        try jsonValuesAreEqual(encodedValue, fixture),
        "Verdict Reasons reader changed count, item order, or payload: \(fixtureID)"
      )
    }

    let duplicateData = try loadData(
      "packages/contracts/fixtures/verdict-reasons-v1/valid/duplicate-items.json"
    )
    let duplicates = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasons.self,
      from: duplicateData
    )
    #expect(duplicates.count == 2)
    #expect(duplicates.values[0] == duplicates.values[1])
  }

  @Test func invalidKnownVerdictReasonsFixturesFailTheSwiftReader() throws {
    let manifest = try loadObject(verdictReasonsManifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases {
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixtureID = try requireString(fixtureCase["id"])
      guard expectedValid == false, fixtureID != "reject-item-unknown-field" else {
        continue
      }
      let path = try requireString(fixtureCase["path"])
      do {
        _ = try HezoJSON.makeResponseDecoder().decode(
          VerdictReasons.self,
          from: loadData("\(verdictReasonsFixtureRoot)/\(path)")
        )
        Issue.record("A declared invalid Verdict Reasons V1 fixture was accepted: \(fixtureID)")
      } catch is DecodingError {
        // Expected. The safe fixture ID is enough context; never render the rejected payload.
      } catch {
        Issue.record("Verdict Reasons V1 decoding used an unexpected error category: \(fixtureID)")
      }
    }
  }

  @Test func strictUnknownItemFieldAndTolerantSwiftReaderStayDistinct() throws {
    let relativePath =
      "packages/contracts/fixtures/verdict-reasons-v1/invalid/item-unknown-field.json"
    let fixture = try loadJSONValue(relativePath)
    let schema = try loadObject(verdictReasonsSchemaPath)
    let reasonSchema = try loadObject("packages/contracts/schemas/verdict-reason-v1.schema.json")
    #expect(
      try verdictReasonsSchemaFailures(
        in: fixture,
        schema: schema,
        registry: [verdictReasonSchemaID: reasonSchema]
      ) == ["additionalProperties"]
    )

    let decoded = try HezoJSON.makeResponseDecoder().decode(
      VerdictReasons.self,
      from: loadData(relativePath)
    )
    #expect(decoded.count == 1)
    let encoded = try HezoJSON.makeEncoder().encode(decoded)
    let encodedItems = try requireJSONArray(jsonValue(from: encoded))
    let encodedItem = try requireObject(encodedItems[0])
    #expect(encodedItem["future_optional"] == nil)
    #expect(
      try jsonValuesAreEqual(encodedItem, expectedSyntheticVerdictReason(1))
    )
  }

  @Test func readerErrorsDoNotReflectRejectedNestedOrSixthReasonContent() throws {
    let nestedCandidate = "PRIVATE_SENTINEL_NESTED_REASON"
    var invalidNestedReason = try expectedSyntheticVerdictReason(1)
    invalidNestedReason["code"] = nestedCandidate
    try expectVerdictReasonsDecodeErrorOmitsCandidate(
      [invalidNestedReason],
      candidate: nestedCandidate
    )

    let sixthCandidate = "PRIVATE_SENTINEL_SIXTH_REASON"
    var sixthReason = try expectedSyntheticVerdictReason(6)
    sixthReason["code"] = sixthCandidate
    var tooManyReasons = try (1...5).map(expectedSyntheticVerdictReason)
    tooManyReasons.append(sixthReason)
    try expectVerdictReasonsDecodeErrorOmitsCandidate(
      tooManyReasons,
      candidate: sixthCandidate
    )
  }

  @Test func supportingPrimitiveValidityDoesNotAuthorizeVerdictOrResponseSemantics() throws {
    let readmeData = try loadData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(verdictSupportingPrimitiveBoundarySentence))
    #expect(readme.contains(evaluatedScopeDocumentationBoundarySentence))
    let evaluatedScope = VerdictSupportingStablePrimitiveContract.evaluatedScope
    #expect(
      evaluatedScope.expectedFixturePayloads.filter { key, _ in
        key.hasPrefix("valid-documented-")
      } == ["valid-documented-exact-url": .string("exact_url")]
    )

    for primitive in VerdictSupportingStablePrimitiveContract.allCases {
      let schema = try loadObject(primitive.schemaPath)
      #expect(schema["type"] as? String == "string")
      #expect(schema["enum"] == nil)
      #expect(schema["const"] == nil)
      #expect(schema["properties"] == nil)
      #expect(schema["required"] == nil)
      #expect(schema["allOf"] == nil)
      #expect(schema["anyOf"] == nil)
      #expect(schema["oneOf"] == nil)
    }

    let reasonsSchema = try loadObject(verdictReasonsSchemaPath)
    #expect(reasonsSchema["type"] as? String == "array")
    #expect(reasonsSchema["properties"] == nil)
    #expect(reasonsSchema["uniqueItems"] == nil)
    #expect(reasonsSchema["contains"] == nil)
    #expect(reasonsSchema["allOf"] == nil)
    #expect(reasonsSchema["anyOf"] == nil)
    #expect(reasonsSchema["oneOf"] == nil)

    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
    // Pair coherence, canonical Verdict authorization, and a complete response stay out of scope.
  }
}

struct VerdictContractAssetTests {
  @Test func schemaAndOpenAPIKeepTheFrozenVerdictV1SurfaceAndReferences() throws {
    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    let schema = try loadObject(verdictSchemaPath)

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
    #expect(info["version"] as? String == "1.10.0")
    #expect(
      info["description"] as? String
        == "Reusable offline check-input, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
    )

    let components = try requireObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireObject(components["schemas"])
    #expect(Set(schemas.keys) == expectedOpenAPIComponentNames)
    let component = try requireObject(schemas["VerdictV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == verdictOpenAPIReference)

    let openAPIURL = repositoryRoot.appendingPathComponent(
      "packages/contracts/openapi-components.json"
    )
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(verdictOpenAPIReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(verdictSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    #expect(
      Set(schema.keys)
        == [
          "$schema", "$id", "title", "description", "type", "additionalProperties",
          "required", "properties", "oneOf",
        ]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == verdictSchemaID)
    #expect(schema["title"] as? String == "Hezo Link verdict V1")
    #expect(
      schema["description"] as? String
        == "Strict standalone public Verdict V1 object with bounded supporting values and an exact label/action coherence matrix. It does not authorize a complete check response or automatic blocking."
    )
    #expect(schema["type"] as? String == "object")
    #expect(try requireBool(schema["additionalProperties"]) == false)
    #expect(
      try requireStringArray(schema["required"])
        == ["label", "recommended_action", "confidence", "evaluated_scope", "reasons"]
    )
    #expect(
      try jsonValuesAreEqual(
        requireJSONArray(schema["oneOf"]),
        expectedVerdictCoherenceBranches()
      )
    )
    _ = try resolveFrozenVerdictSchemas(
      from: schema,
      registry: loadVerdictSchemaRegistry()
    )
  }

  @Test func manifestHasCompleteUniqueVerdictFixtureCoverage() throws {
    let manifest = try loadObject(verdictManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(integerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "verdict-v1")
    #expect(manifest["contract_schema"] as? String == verdictManifestSchemaReference)

    let cases = try requireObjectArray(manifest["cases"])
    #expect(cases.count == 27)
    let pairs = try cases.map { fixtureCase in
      (try requireString(fixtureCase["id"]), try requireString(fixtureCase["path"]))
    }
    let ids = pairs.map(\.0)
    let paths = pairs.map(\.1)
    #expect(Set(ids).count == ids.count)
    #expect(Set(paths).count == paths.count)
    #expect(Dictionary(uniqueKeysWithValues: pairs) == expectedVerdictFixturePaths)
    #expect(
      Set(expectedVerdictFailureKeywords.keys)
        == Set(ids).subtracting(expectedValidVerdictFixtureIDs)
    )

    let fixtureRoot = repositoryRoot.appendingPathComponent(verdictFixtureRoot)
      .standardizedFileURL
    #expect(try fixturePathsOnDisk(relativeTo: fixtureRoot) == Set(paths))

    let manifestURL = repositoryRoot.appendingPathComponent(verdictManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(verdictManifestSchemaReference)
      .standardizedFileURL
    let schemaURL = repositoryRoot.appendingPathComponent(verdictSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyVerdictFixtureMatchesItsExactIntentAndKeywordSet() throws {
    let manifest = try loadObject(verdictManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let schema = try loadObject(verdictSchemaPath)
    let registry = try loadVerdictSchemaRegistry()
    var validCount = 0
    var invalidCount = 0

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let expectedValid = try requireBool(fixtureCase["expected_schema_valid"])
      let fixture = try loadJSONValue("\(verdictFixtureRoot)/\(path)")
      let expectedFixture = try expectedVerdictFixture(id: fixtureID)
      let failures = try verdictSchemaFailures(
        in: fixture,
        schema: schema,
        registry: registry
      )

      #expect(
        try jsonValuesAreEqual(fixture, expectedFixture),
        "Verdict V1 fixture payload drifted from its declared purpose: \(fixtureID)"
      )

      if expectedValid {
        validCount += 1
        #expect(Set(fixtureCase.keys) == ["id", "path", "expected_schema_valid"])
        #expect(expectedValidVerdictFixtureIDs.contains(fixtureID))
        #expect(failures.isEmpty)
      } else {
        invalidCount += 1
        let expectedKeywords = try declaredFailureKeywords(in: fixtureCase)
        #expect(expectedKeywords == expectedVerdictFailureKeywords[fixtureID])
        #expect(failures == expectedKeywords)
      }
    }

    #expect(validCount == 5)
    #expect(invalidCount == 22)
  }

  @Test func fixtureMatrixCoversEveryLabelActionCombinationExactlyOnce() throws {
    let manifest = try loadObject(verdictManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let matrixCases = try cases.filter { fixtureCase in
      let fixtureID = try requireString(fixtureCase["id"])
      return fixtureID.hasPrefix("valid-") || fixtureID.hasPrefix("reject-pair-")
    }
    var actualPairs = Set<String>()
    var validPairs = Set<String>()
    var invalidPairs = Set<String>()

    for fixtureCase in matrixCases {
      let path = try requireString(fixtureCase["path"])
      let fixture = try loadObject("\(verdictFixtureRoot)/\(path)")
      let pair =
        "\(try requireString(fixture["label"]))|\(try requireString(fixture["recommended_action"]))"
      #expect(actualPairs.insert(pair).inserted)
      if try requireBool(fixtureCase["expected_schema_valid"]) {
        validPairs.insert(pair)
      } else {
        invalidPairs.insert(pair)
      }
    }

    let labels = ["unknown", "no_known_danger", "caution", "dangerous"]
    let actions = ["allow", "warn", "avoid", "retry"]
    let completeCartesianProduct = Set(
      labels.flatMap { label in
        actions.map { action in "\(label)|\(action)" }
      })
    #expect(actualPairs == completeCartesianProduct)
    #expect(
      validPairs
        == [
          "unknown|warn", "unknown|retry", "no_known_danger|allow", "caution|warn",
          "dangerous|avoid",
        ]
    )
    #expect(invalidPairs == completeCartesianProduct.subtracting(validPairs))
    #expect(validPairs.count == 5)
    #expect(invalidPairs.count == 11)
  }

  @Test func evaluatorRequiresEveryExactRegisteredReachableReference() throws {
    let schema = try loadObject(verdictSchemaPath)
    let registry = try loadVerdictSchemaRegistry()
    let references = [
      "label": verdictLabelSchemaID,
      "recommended_action": recommendedActionSchemaID,
      "confidence": confidenceCategorySchemaID,
      "evaluated_scope": evaluatedScopeSchemaID,
      "reasons": verdictReasonsSchemaID,
    ]

    for (field, reference) in references {
      guard let referencedSchema = registry[reference] else {
        throw ContractAssetTestError.invalidAsset
      }
      var unresolvedSchema = schema
      var unresolvedProperties = try requireObject(unresolvedSchema["properties"])
      unresolvedProperties[field] = ["$ref": "urn:hezo-link:contract:unregistered:v1"]
      unresolvedSchema["properties"] = unresolvedProperties
      #expect(throws: ContractAssetTestError.self) {
        _ = try resolveFrozenVerdictSchemas(from: unresolvedSchema, registry: registry)
      }

      var inlinedSchema = schema
      var inlinedProperties = try requireObject(inlinedSchema["properties"])
      inlinedProperties[field] = referencedSchema
      inlinedSchema["properties"] = inlinedProperties
      #expect(throws: ContractAssetTestError.self) {
        _ = try resolveFrozenVerdictSchemas(from: inlinedSchema, registry: registry)
      }

      var mismatchedRegistry = registry
      var mismatchedReferencedSchema = referencedSchema
      mismatchedReferencedSchema["$id"] = "urn:hezo-link:contract:mismatched:v1"
      mismatchedRegistry[reference] = mismatchedReferencedSchema
      #expect(throws: ContractAssetTestError.self) {
        _ = try resolveFrozenVerdictSchemas(from: schema, registry: mismatchedRegistry)
      }
    }

    var missingNestedReasonRegistry = registry
    missingNestedReasonRegistry.removeValue(forKey: verdictReasonSchemaID)
    #expect(throws: ContractAssetTestError.self) {
      _ = try resolveFrozenVerdictSchemas(
        from: schema,
        registry: missingNestedReasonRegistry
      )
    }
  }

  @Test func validFixturesRoundTripWithoutChangingPairsReasonOrderOrDuplicates() throws {
    let manifest = try loadObject(verdictManifestPath)
    let cases = try requireObjectArray(manifest["cases"])

    for fixtureCase in cases where try requireBool(fixtureCase["expected_schema_valid"]) {
      let fixtureID = try requireString(fixtureCase["id"])
      let path = try requireString(fixtureCase["path"])
      let relativePath = "\(verdictFixtureRoot)/\(path)"
      let fixture = try loadJSONValue(relativePath)
      let decoded = try HezoJSON.makeResponseDecoder().decode(
        Verdict.self,
        from: loadData(relativePath)
      )
      let encoded = try HezoJSON.makeEncoder().encode(decoded)

      #expect(
        try jsonValuesAreEqual(jsonValue(from: encoded), fixture),
        "Verdict V1 reader changed a valid fixture: \(fixtureID)"
      )
      if fixtureID == "valid-unknown-warn" {
        #expect(decoded.confidence.rawValue == "synthetic_confidence_v2")
        #expect(decoded.evaluatedScope.rawValue == "synthetic_scope_v2")
      }
      if fixtureID == "valid-caution-warn" {
        #expect(
          decoded.reasons.values.map { $0.code.rawValue }
            == [
              "synthetic_reason_two", "synthetic_reason_one", "synthetic_reason_two",
              "synthetic_reason_three",
            ]
        )
        #expect(decoded.reasons.values[0] == decoded.reasons.values[2])
      }
      if fixtureID == "valid-dangerous-avoid" {
        #expect(decoded.reasons.count == 5)
      }
    }
  }

  @Test func everyInvalidKnownFieldAndPairFailsTheSwiftReader() throws {
    let manifest = try loadObject(verdictManifestPath)
    let cases = try requireObjectArray(manifest["cases"])
    let toleratedStrictOnlyFixtureIDs: Set<String> = [
      "reject-block-eligible-field", "reject-reason-unknown-field",
    ]

    for fixtureCase in cases {
      let fixtureID = try requireString(fixtureCase["id"])
      guard try requireBool(fixtureCase["expected_schema_valid"]) == false,
        toleratedStrictOnlyFixtureIDs.contains(fixtureID) == false
      else {
        continue
      }
      let path = try requireString(fixtureCase["path"])
      do {
        _ = try HezoJSON.makeResponseDecoder().decode(
          Verdict.self,
          from: loadData("\(verdictFixtureRoot)/\(path)")
        )
        Issue.record("A declared invalid Verdict V1 fixture was accepted: \(fixtureID)")
      } catch is DecodingError {
        // Expected. The safe fixture ID is sufficient; never render the rejected payload.
      } catch {
        Issue.record("Verdict V1 decoding used an unexpected error category: \(fixtureID)")
      }
    }
  }

  @Test func strictUnknownMembersAndTolerantSwiftReaderStayDistinct() throws {
    let schema = try loadObject(verdictSchemaPath)
    let registry = try loadVerdictSchemaRegistry()
    let outerPath = "\(verdictFixtureRoot)/invalid/block-eligible-field.json"
    let nestedPath = "\(verdictFixtureRoot)/invalid/reason-unknown-field.json"

    for path in [outerPath, nestedPath] {
      #expect(
        try verdictSchemaFailures(
          in: loadJSONValue(path),
          schema: schema,
          registry: registry
        ) == ["additionalProperties"]
      )
    }

    let outer = try HezoJSON.makeResponseDecoder().decode(
      Verdict.self,
      from: loadData(outerPath)
    )
    let outerEncoded = try requireObject(jsonValue(from: HezoJSON.makeEncoder().encode(outer)))
    #expect(outerEncoded["block_eligible"] == nil)

    let nested = try HezoJSON.makeResponseDecoder().decode(
      Verdict.self,
      from: loadData(nestedPath)
    )
    let nestedEncoded = try requireObject(jsonValue(from: HezoJSON.makeEncoder().encode(nested)))
    let encodedReasons = try requireJSONArray(nestedEncoded["reasons"])
    let encodedReason = try requireObject(encodedReasons[0])
    #expect(encodedReason["future_optional"] == nil)
  }

  @Test func SwiftConstructorEnforcesExactlyTheFrozenFiveOfSixteenPairs() throws {
    let confidence = ConfidenceCategory.medium
    let evaluatedScope = EvaluatedScope.exactURL
    let reasons = try VerdictReasons([])
    let validPairs: Set<String> = [
      "unknown|warn", "unknown|retry", "no_known_danger|allow", "caution|warn",
      "dangerous|avoid",
    ]
    var acceptedCount = 0
    var rejectedCount = 0

    for labelValue in ["unknown", "no_known_danger", "caution", "dangerous"] {
      for actionValue in ["allow", "warn", "avoid", "retry"] {
        let label = try #require(VerdictLabel(rawValue: labelValue))
        let action = try #require(RecommendedAction(rawValue: actionValue))
        let pair = "\(labelValue)|\(actionValue)"
        do {
          _ = try Verdict(
            label: label,
            recommendedAction: action,
            confidence: confidence,
            evaluatedScope: evaluatedScope,
            reasons: reasons
          )
          if validPairs.contains(pair) {
            acceptedCount += 1
          } else {
            Issue.record("The Swift Verdict constructor accepted a disallowed pair")
          }
        } catch VerdictContractError.incoherentLabelAndAction {
          if validPairs.contains(pair) {
            Issue.record("The Swift Verdict constructor rejected an allowed pair")
          } else {
            rejectedCount += 1
          }
        } catch {
          Issue.record("The Swift Verdict constructor used an unexpected error category")
        }
      }
    }

    #expect(acceptedCount == 5)
    #expect(rejectedCount == 11)
    #expect(
      VerdictContractError.incoherentLabelAndAction.description
        == "Verdict label and recommended action are incoherent."
    )
  }

  @Test func readerErrorsNeverReflectVerdictPrivacyCanaries() throws {
    let confidenceCandidate = "PRIVATE_SENTINEL_VERDICT_CONFIDENCE"
    let invalidConfidence = expectedVerdictFixture(
      label: "caution",
      action: "warn",
      confidence: confidenceCandidate
    )
    try expectVerdictDecodeErrorOmitsCandidate(
      invalidConfidence,
      candidate: confidenceCandidate
    )

    let nestedCandidate = "PRIVATE_SENTINEL_VERDICT_REASON"
    var invalidReason = try expectedSyntheticVerdictReason(1)
    invalidReason["code"] = nestedCandidate
    try expectVerdictDecodeErrorOmitsCandidate(
      expectedVerdictFixture(label: "caution", action: "warn", reasons: [invalidReason]),
      candidate: nestedCandidate
    )

    let sixthCandidate = "PRIVATE_SENTINEL_SIXTH_VERDICT_REASON"
    var sixthReason = try expectedSyntheticVerdictReason(6)
    sixthReason["code"] = sixthCandidate
    var sixReasons = try expectedSyntheticVerdictReasons(count: 5)
    sixReasons.append(sixthReason)
    try expectVerdictDecodeErrorOmitsCandidate(
      expectedVerdictFixture(label: "dangerous", action: "avoid", reasons: sixReasons),
      candidate: sixthCandidate
    )
  }

  @Test func structuralVerdictValidityAuthorizesNoResponseOrEnforcementSemantics() throws {
    let readmeData = try loadData("packages/contracts/README.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    #expect(readme.contains(verdictBoundarySentence))

    let schema = try loadObject(verdictSchemaPath)
    let properties = try requireObject(schema["properties"])
    #expect(
      Set(properties.keys)
        == ["label", "recommended_action", "confidence", "evaluated_scope", "reasons"]
    )
    for unauthorizedField in [
      "status", "check_token", "target", "analysis", "source_notices", "versions",
      "evaluated_at", "valid_until", "block_eligible",
    ] {
      #expect(properties[unauthorizedField] == nil)
    }

    let openAPI = try loadObject("packages/contracts/openapi-components.json")
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
    // Pair coherence alone proves neither completed-response admission nor block eligibility.
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

private let expectedOpenAPIComponentNames: Set<String> = [
  "CheckRequestV1", "RequestIDV1", "CanonicalInstantV1", "ProblemV1", "VerdictReasonV1",
  "VerdictLabelV1",
  "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1",
  "VerdictReasonsV1", "CheckResponseStatusV1", "CheckTokenV1", "PendingCheckResponseV1",
  "VerdictV1",
]

private let requestIDSchemaPath = "packages/contracts/schemas/request-id-v1.schema.json"
private let requestIDOpenAPIReference = "./schemas/request-id-v1.schema.json"
private let requestIDSchemaID = "urn:hezo-link:contract:request-id:v1"
private let requestIDPattern = "^[A-Za-z0-9_-]+$"

private let verdictPrimitiveBoundarySentence =
  "These standalone primitives validate individual wire values only. They neither define label/action pair coherence nor authorize a complete verdict or check-response envelope."

private let checkResponseStatusSchemaPath =
  "packages/contracts/schemas/check-response-status-v1.schema.json"
private let checkResponseStatusOpenAPIReference =
  "./schemas/check-response-status-v1.schema.json"
private let checkResponseStatusFixtureRoot =
  "packages/contracts/fixtures/check-response-status-v1"
private let checkResponseStatusManifestPath =
  "\(checkResponseStatusFixtureRoot)/manifest.json"
private let checkResponseStatusManifestSchemaReference =
  "../../schemas/check-response-status-v1.schema.json"
private let checkResponseStatusWireValues = ["complete", "pending"]
private let checkResponseStatusValidFixtureIDs: Set<String> = [
  "valid-complete", "valid-pending",
]
private let checkResponseStatusFixturePaths = [
  "valid-complete": "valid/complete.json",
  "valid-pending": "valid/pending.json",
  "reject-alias-completed": "invalid/alias-completed.json",
  "reject-conceptual-analyzing": "invalid/conceptual-analyzing.json",
  "reject-verdict-unknown": "invalid/verdict-unknown.json",
  "reject-report-accepted": "invalid/report-accepted.json",
  "reject-uppercase": "invalid/uppercase.json",
  "reject-empty": "invalid/empty.json",
  "reject-http-status-202": "invalid/http-status-202.json",
  "reject-null": "invalid/null.json",
]
private let checkResponseStatusFixturePayloads: [String: PrimitiveFixturePayload] = [
  "valid-complete": .string("complete"),
  "valid-pending": .string("pending"),
  "reject-alias-completed": .string("completed"),
  "reject-conceptual-analyzing": .string("analyzing"),
  "reject-verdict-unknown": .string("unknown"),
  "reject-report-accepted": .string("accepted"),
  "reject-uppercase": .string("COMPLETE"),
  "reject-empty": .string(""),
  "reject-http-status-202": .integer(202),
  "reject-null": .null,
]
private let checkResponseStatusFailureKeywords: [String: Set<String>] = [
  "reject-alias-completed": ["enum"],
  "reject-conceptual-analyzing": ["enum"],
  "reject-verdict-unknown": ["enum"],
  "reject-report-accepted": ["enum"],
  "reject-uppercase": ["enum"],
  "reject-empty": ["enum"],
  "reject-http-status-202": ["type", "enum"],
  "reject-null": ["type", "enum"],
]
private let checkResponseStatusBoundarySentence =
  "This primitive validates one check-response status value only. It defines no endpoint, response branch, HTTP status, token or capability, retry or polling behavior, completion guarantee, or check-response envelope."

private let checkResponseStatusSchemaID =
  "urn:hezo-link:contract:check-response-status:v1"
private let checkTokenSchemaPath = "packages/contracts/schemas/check-token-v1.schema.json"
private let checkTokenSchemaID = "urn:hezo-link:contract:check-token:v1"
private let canonicalInstantSchemaPath =
  "packages/contracts/schemas/canonical-instant-v1.schema.json"
private let canonicalInstantSchemaID = "urn:hezo-link:contract:canonical-instant:v1"
private let canonicalInstantPattern =
  "^(?!0000-)[0-9]{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"
private let pendingCheckResponseSchemaPath =
  "packages/contracts/schemas/pending-check-response-v1.schema.json"
private let pendingCheckResponseOpenAPIReference =
  "./schemas/pending-check-response-v1.schema.json"
private let pendingCheckResponseSchemaID =
  "urn:hezo-link:contract:pending-check-response:v1"
private let pendingCheckResponseFixtureRoot =
  "packages/contracts/fixtures/pending-check-response-v1"
private let pendingCheckResponseManifestPath =
  "\(pendingCheckResponseFixtureRoot)/manifest.json"
private let pendingCheckResponseManifestSchemaReference =
  "../../schemas/pending-check-response-v1.schema.json"
private let pendingCheckResponseFields = [
  "schema_version", "status", "check_token", "retry_after_ms", "expires_at", "request_id",
]
private let pendingCheckTokenPattern = "^[A-Za-z0-9_-]{42}[AEIMQUYcgkosw048]$"
private let pendingCheckExpiresAtPattern = canonicalInstantPattern
private let pendingCheckDefaultToken = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
private let pendingCheckDefaultExpiry = "2000-01-01T00:15:00Z"
private let pendingCheckResponseValidFixtureIDs: Set<String> = [
  "valid-standard",
  "valid-retry-after-ms-lower-boundary",
  "valid-retry-after-ms-upper-boundary",
  "valid-request-id-upper-boundary",
  "valid-canonical-token-controls",
]
private let pendingCheckResponseForbiddenFixtureIDs: Set<String> = [
  "reject-forbidden-verdict",
  "reject-forbidden-target",
  "reject-forbidden-analysis",
  "reject-forbidden-source-notices",
  "reject-forbidden-versions",
  "reject-forbidden-evaluated-at",
  "reject-forbidden-valid-until",
  "reject-forbidden-block-eligible",
]
private let pendingCheckResponseFixtureIDsInOrder = [
  "valid-standard",
  "valid-retry-after-ms-lower-boundary",
  "valid-retry-after-ms-upper-boundary",
  "valid-request-id-upper-boundary",
  "valid-canonical-token-controls",
  "reject-missing-schema-version",
  "reject-missing-status",
  "reject-missing-check-token",
  "reject-missing-retry-after-ms",
  "reject-missing-expires-at",
  "reject-missing-request-id",
  "reject-schema-version-mismatch",
  "reject-status-complete",
  "reject-status-invalid",
  "reject-check-token-short",
  "reject-check-token-long",
  "reject-check-token-invalid-character",
  "reject-check-token-noncanonical-final-character",
  "reject-check-token-null",
  "reject-check-token-wrong-type",
  "reject-retry-after-ms-zero",
  "reject-retry-after-ms-above-maximum",
  "reject-retry-after-ms-fractional",
  "reject-retry-after-ms-null",
  "reject-retry-after-ms-wrong-type",
  "reject-expires-at-fractional",
  "reject-expires-at-offset",
  "reject-expires-at-impossible",
  "reject-expires-at-lowercase-z",
  "reject-expires-at-year-zero",
  "reject-expires-at-null",
  "reject-expires-at-wrong-type",
  "reject-request-id-empty",
  "reject-request-id-invalid-character",
  "reject-request-id-oversized",
  "reject-request-id-null",
  "reject-request-id-wrong-type",
  "reject-wrong-top-level-type",
  "reject-unknown-future-field",
  "reject-forbidden-verdict",
  "reject-forbidden-target",
  "reject-forbidden-analysis",
  "reject-forbidden-source-notices",
  "reject-forbidden-versions",
  "reject-forbidden-evaluated-at",
  "reject-forbidden-valid-until",
  "reject-forbidden-block-eligible",
]
private let pendingCheckResponseFixturePaths: [String: String] = [
  "valid-standard": "valid/standard.json",
  "valid-retry-after-ms-lower-boundary": "valid/retry-after-ms-lower-boundary.json",
  "valid-retry-after-ms-upper-boundary": "valid/retry-after-ms-upper-boundary.json",
  "valid-request-id-upper-boundary": "valid/request-id-upper-boundary.json",
  "valid-canonical-token-controls": "valid/canonical-token-controls.json",
  "reject-missing-schema-version": "invalid/missing-schema-version.json",
  "reject-missing-status": "invalid/missing-status.json",
  "reject-missing-check-token": "invalid/missing-check-token.json",
  "reject-missing-retry-after-ms": "invalid/missing-retry-after-ms.json",
  "reject-missing-expires-at": "invalid/missing-expires-at.json",
  "reject-missing-request-id": "invalid/missing-request-id.json",
  "reject-schema-version-mismatch": "invalid/schema-version-mismatch.json",
  "reject-status-complete": "invalid/status-complete.json",
  "reject-status-invalid": "invalid/status-invalid.json",
  "reject-check-token-short": "invalid/check-token-short.json",
  "reject-check-token-long": "invalid/check-token-long.json",
  "reject-check-token-invalid-character": "invalid/check-token-invalid-character.json",
  "reject-check-token-noncanonical-final-character":
    "invalid/check-token-noncanonical-final-character.json",
  "reject-check-token-null": "invalid/check-token-null.json",
  "reject-check-token-wrong-type": "invalid/check-token-wrong-type.json",
  "reject-retry-after-ms-zero": "invalid/retry-after-ms-zero.json",
  "reject-retry-after-ms-above-maximum": "invalid/retry-after-ms-above-maximum.json",
  "reject-retry-after-ms-fractional": "invalid/retry-after-ms-fractional.json",
  "reject-retry-after-ms-null": "invalid/retry-after-ms-null.json",
  "reject-retry-after-ms-wrong-type": "invalid/retry-after-ms-wrong-type.json",
  "reject-expires-at-fractional": "invalid/expires-at-fractional.json",
  "reject-expires-at-offset": "invalid/expires-at-offset.json",
  "reject-expires-at-impossible": "invalid/expires-at-impossible.json",
  "reject-expires-at-lowercase-z": "invalid/expires-at-lowercase-z.json",
  "reject-expires-at-year-zero": "invalid/expires-at-year-zero.json",
  "reject-expires-at-null": "invalid/expires-at-null.json",
  "reject-expires-at-wrong-type": "invalid/expires-at-wrong-type.json",
  "reject-request-id-empty": "invalid/request-id-empty.json",
  "reject-request-id-invalid-character": "invalid/request-id-invalid-character.json",
  "reject-request-id-oversized": "invalid/request-id-oversized.json",
  "reject-request-id-null": "invalid/request-id-null.json",
  "reject-request-id-wrong-type": "invalid/request-id-wrong-type.json",
  "reject-wrong-top-level-type": "invalid/wrong-top-level-type.json",
  "reject-unknown-future-field": "invalid/unknown-future-field.json",
  "reject-forbidden-verdict": "invalid/forbidden-verdict.json",
  "reject-forbidden-target": "invalid/forbidden-target.json",
  "reject-forbidden-analysis": "invalid/forbidden-analysis.json",
  "reject-forbidden-source-notices": "invalid/forbidden-source-notices.json",
  "reject-forbidden-versions": "invalid/forbidden-versions.json",
  "reject-forbidden-evaluated-at": "invalid/forbidden-evaluated-at.json",
  "reject-forbidden-valid-until": "invalid/forbidden-valid-until.json",
  "reject-forbidden-block-eligible": "invalid/forbidden-block-eligible.json",
]
private let pendingCheckResponseFailureKeywords: [String: Set<String>] = [
  "reject-missing-schema-version": ["required"],
  "reject-missing-status": ["required"],
  "reject-missing-check-token": ["required"],
  "reject-missing-retry-after-ms": ["required"],
  "reject-missing-expires-at": ["required"],
  "reject-missing-request-id": ["required"],
  "reject-schema-version-mismatch": ["const"],
  "reject-status-complete": ["const"],
  "reject-status-invalid": ["enum", "const"],
  "reject-check-token-short": ["minLength", "pattern"],
  "reject-check-token-long": ["maxLength", "pattern"],
  "reject-check-token-invalid-character": ["pattern"],
  "reject-check-token-noncanonical-final-character": ["pattern"],
  "reject-check-token-null": ["type"],
  "reject-check-token-wrong-type": ["type"],
  "reject-retry-after-ms-zero": ["minimum"],
  "reject-retry-after-ms-above-maximum": ["maximum"],
  "reject-retry-after-ms-fractional": ["type"],
  "reject-retry-after-ms-null": ["type"],
  "reject-retry-after-ms-wrong-type": ["type"],
  "reject-expires-at-fractional": ["pattern"],
  "reject-expires-at-offset": ["pattern"],
  "reject-expires-at-impossible": ["format"],
  "reject-expires-at-lowercase-z": ["pattern"],
  "reject-expires-at-year-zero": ["pattern"],
  "reject-expires-at-null": ["type"],
  "reject-expires-at-wrong-type": ["type"],
  "reject-request-id-empty": ["minLength", "pattern"],
  "reject-request-id-invalid-character": ["pattern"],
  "reject-request-id-oversized": ["maxLength"],
  "reject-request-id-null": ["type"],
  "reject-request-id-wrong-type": ["type"],
  "reject-wrong-top-level-type": ["type"],
  "reject-unknown-future-field": ["additionalProperties"],
  "reject-forbidden-verdict": ["additionalProperties"],
  "reject-forbidden-target": ["additionalProperties"],
  "reject-forbidden-analysis": ["additionalProperties"],
  "reject-forbidden-source-notices": ["additionalProperties"],
  "reject-forbidden-versions": ["additionalProperties"],
  "reject-forbidden-evaluated-at": ["additionalProperties"],
  "reject-forbidden-valid-until": ["additionalProperties"],
  "reject-forbidden-block-eligible": ["additionalProperties"],
]
private let pendingCheckResponseBoundarySentence =
  "Unknown fields are rejected by the strict published schema. A specifically designated Swift Pending Check Response V1 reader may discard genuinely additive unknown response members for forward compatibility, but it must continue to require and validate every known member exactly. It must reject any payload containing the known hybrid-envelope keys `verdict`, `target`, `analysis`, `source_notices`, `versions`, `evaluated_at`, `valid_until`, or `block_eligible`; those members cannot be treated as harmless future additions. This tolerant client boundary does not widen the public schema or make an unknown member meaningful."

enum PrimitiveFixturePayload: Equatable, Sendable {
  case string(String)
  case integer(Int64)
  case null
}

enum VerdictPrimitiveContract: CaseIterable, Sendable {
  case verdictLabel
  case recommendedAction

  var contractName: String {
    switch self {
    case .verdictLabel: "verdict-label-v1"
    case .recommendedAction: "recommended-action-v1"
    }
  }

  var componentName: String {
    switch self {
    case .verdictLabel: "VerdictLabelV1"
    case .recommendedAction: "RecommendedActionV1"
    }
  }

  var schemaPath: String {
    "packages/contracts/schemas/\(contractName).schema.json"
  }

  var openAPIReference: String {
    "./schemas/\(contractName).schema.json"
  }

  var schemaID: String {
    "urn:hezo-link:contract:\(contractName.dropLast(3)):v1"
  }

  var schemaTitle: String {
    switch self {
    case .verdictLabel: "Hezo Link verdict label V1"
    case .recommendedAction: "Hezo Link recommended action V1"
    }
  }

  var schemaDescription: String {
    switch self {
    case .verdictLabel:
      "Exact public verdict-label primitive. This standalone value does not authorize label/action coherence or a complete verdict or check response."
    case .recommendedAction:
      "Exact public recommended-action primitive. This standalone value does not authorize label/action coherence or a complete verdict or check response."
    }
  }

  var wireValues: [String] {
    switch self {
    case .verdictLabel: ["unknown", "no_known_danger", "caution", "dangerous"]
    case .recommendedAction: ["allow", "warn", "avoid", "retry"]
    }
  }

  var fixtureRoot: String {
    "packages/contracts/fixtures/\(contractName)"
  }

  var manifestPath: String {
    "\(fixtureRoot)/manifest.json"
  }

  var manifestSchemaReference: String {
    "../../schemas/\(contractName).schema.json"
  }

  var validFixtureIDs: Set<String> {
    switch self {
    case .verdictLabel:
      ["valid-unknown", "valid-no-known-danger", "valid-caution", "valid-dangerous"]
    case .recommendedAction:
      ["valid-allow", "valid-warn", "valid-avoid", "valid-retry"]
    }
  }

  var expectedFixturePaths: [String: String] {
    switch self {
    case .verdictLabel:
      [
        "valid-unknown": "valid/unknown.json",
        "valid-no-known-danger": "valid/no-known-danger.json",
        "valid-caution": "valid/caution.json",
        "valid-dangerous": "valid/dangerous.json",
        "reject-alias-safe": "invalid/alias-safe.json",
        "reject-alias-likely-safe": "invalid/alias-likely-safe.json",
        "reject-alias-allow": "invalid/alias-allow.json",
        "reject-alias-warn": "invalid/alias-warn.json",
        "reject-alias-block": "invalid/alias-block.json",
        "reject-alias-malicious": "invalid/alias-malicious.json",
        "reject-alias-suspicious": "invalid/alias-suspicious.json",
        "reject-wrong-type": "invalid/wrong-type.json",
        "reject-null": "invalid/null.json",
        "reject-empty": "invalid/empty.json",
        "reject-uppercase": "invalid/uppercase.json",
        "reject-unrecognized": "invalid/unrecognized.json",
      ]
    case .recommendedAction:
      [
        "valid-allow": "valid/allow.json",
        "valid-warn": "valid/warn.json",
        "valid-avoid": "valid/avoid.json",
        "valid-retry": "valid/retry.json",
        "reject-alias-proceed": "invalid/alias-proceed.json",
        "reject-alias-block": "invalid/alias-block.json",
        "reject-cross-vocabulary-unknown": "invalid/cross-vocabulary-unknown.json",
        "reject-wrong-type": "invalid/wrong-type.json",
        "reject-null": "invalid/null.json",
        "reject-empty": "invalid/empty.json",
        "reject-uppercase": "invalid/uppercase.json",
        "reject-unrecognized": "invalid/unrecognized.json",
      ]
    }
  }

  var expectedFailureKeywords: [String: Set<String>] {
    switch self {
    case .verdictLabel:
      [
        "reject-alias-safe": ["enum"],
        "reject-alias-likely-safe": ["enum"],
        "reject-alias-allow": ["enum"],
        "reject-alias-warn": ["enum"],
        "reject-alias-block": ["enum"],
        "reject-alias-malicious": ["enum"],
        "reject-alias-suspicious": ["enum"],
        "reject-wrong-type": ["type", "enum"],
        "reject-null": ["type", "enum"],
        "reject-empty": ["enum"],
        "reject-uppercase": ["enum"],
        "reject-unrecognized": ["enum"],
      ]
    case .recommendedAction:
      [
        "reject-alias-proceed": ["enum"],
        "reject-alias-block": ["enum"],
        "reject-cross-vocabulary-unknown": ["enum"],
        "reject-wrong-type": ["type", "enum"],
        "reject-null": ["type", "enum"],
        "reject-empty": ["enum"],
        "reject-uppercase": ["enum"],
        "reject-unrecognized": ["enum"],
      ]
    }
  }

  var expectedFixturePayloads: [String: PrimitiveFixturePayload] {
    switch self {
    case .verdictLabel:
      [
        "valid-unknown": .string("unknown"),
        "valid-no-known-danger": .string("no_known_danger"),
        "valid-caution": .string("caution"),
        "valid-dangerous": .string("dangerous"),
        "reject-alias-safe": .string("safe"),
        "reject-alias-likely-safe": .string("likely_safe"),
        "reject-alias-allow": .string("allow"),
        "reject-alias-warn": .string("warn"),
        "reject-alias-block": .string("block"),
        "reject-alias-malicious": .string("malicious"),
        "reject-alias-suspicious": .string("suspicious"),
        "reject-wrong-type": .integer(1),
        "reject-null": .null,
        "reject-empty": .string(""),
        "reject-uppercase": .string("DANGEROUS"),
        "reject-unrecognized": .string("future_label"),
      ]
    case .recommendedAction:
      [
        "valid-allow": .string("allow"),
        "valid-warn": .string("warn"),
        "valid-avoid": .string("avoid"),
        "valid-retry": .string("retry"),
        "reject-alias-proceed": .string("proceed"),
        "reject-alias-block": .string("block"),
        "reject-cross-vocabulary-unknown": .string("unknown"),
        "reject-wrong-type": .integer(1),
        "reject-null": .null,
        "reject-empty": .string(""),
        "reject-uppercase": .string("ALLOW"),
        "reject-unrecognized": .string("future_action"),
      ]
    }
  }
}

enum VerdictSupportingStablePrimitiveContract: CaseIterable, Sendable {
  case confidenceCategory
  case evaluatedScope

  var contractName: String {
    switch self {
    case .confidenceCategory: "confidence-category-v1"
    case .evaluatedScope: "evaluated-scope-v1"
    }
  }

  var componentName: String {
    switch self {
    case .confidenceCategory: "ConfidenceCategoryV1"
    case .evaluatedScope: "EvaluatedScopeV1"
    }
  }

  var schemaPath: String {
    "packages/contracts/schemas/\(contractName).schema.json"
  }

  var openAPIReference: String {
    "./schemas/\(contractName).schema.json"
  }

  var schemaID: String {
    switch self {
    case .confidenceCategory: "urn:hezo-link:contract:confidence-category:v1"
    case .evaluatedScope: "urn:hezo-link:contract:evaluated-scope:v1"
    }
  }

  var schemaTitle: String {
    switch self {
    case .confidenceCategory: "Hezo Link confidence category V1"
    case .evaluatedScope: "Hezo Link evaluated scope V1"
    }
  }

  var schemaDescription: String {
    switch self {
    case .confidenceCategory:
      "Forward-compatible bounded confidence-category primitive using the stable-value grammar. It is not a score, probability, or complete verdict."
    case .evaluatedScope:
      "Forward-compatible bounded evaluated-scope primitive using the stable-value grammar. It does not authorize a coverage or verdict claim."
    }
  }

  var fixtureRoot: String {
    "packages/contracts/fixtures/\(contractName)"
  }

  var manifestPath: String {
    "\(fixtureRoot)/manifest.json"
  }

  var manifestSchemaReference: String {
    "../../schemas/\(contractName).schema.json"
  }

  var validFixtureIDs: Set<String> {
    switch self {
    case .confidenceCategory:
      [
        "valid-documented-low", "valid-documented-medium", "valid-documented-high",
        "valid-forward-compatible", "valid-lower-boundary", "valid-upper-boundary",
      ]
    case .evaluatedScope:
      [
        "valid-documented-exact-url", "valid-forward-compatible", "valid-lower-boundary",
        "valid-upper-boundary",
      ]
    }
  }

  var expectedFixturePaths: [String: String] {
    switch self {
    case .confidenceCategory:
      [
        "valid-documented-low": "valid/documented-low.json",
        "valid-documented-medium": "valid/documented-medium.json",
        "valid-documented-high": "valid/documented-high.json",
        "valid-forward-compatible": "valid/forward-compatible.json",
        "valid-lower-boundary": "valid/lower-boundary.json",
        "valid-upper-boundary": "valid/upper-boundary.json",
        "reject-wrong-type": "invalid/wrong-type.json",
        "reject-null": "invalid/null.json",
        "reject-empty": "invalid/empty.json",
        "reject-uppercase": "invalid/uppercase.json",
        "reject-leading-digit": "invalid/leading-digit.json",
        "reject-double-underscore": "invalid/double-underscore.json",
        "reject-trailing-underscore": "invalid/trailing-underscore.json",
        "reject-hyphen": "invalid/hyphen.json",
        "reject-non-ascii": "invalid/non-ascii.json",
        "reject-oversized": "invalid/oversized.json",
      ]
    case .evaluatedScope:
      [
        "valid-documented-exact-url": "valid/documented-exact-url.json",
        "valid-forward-compatible": "valid/forward-compatible.json",
        "valid-lower-boundary": "valid/lower-boundary.json",
        "valid-upper-boundary": "valid/upper-boundary.json",
        "reject-wrong-type": "invalid/wrong-type.json",
        "reject-null": "invalid/null.json",
        "reject-empty": "invalid/empty.json",
        "reject-uppercase": "invalid/uppercase.json",
        "reject-leading-digit": "invalid/leading-digit.json",
        "reject-double-underscore": "invalid/double-underscore.json",
        "reject-trailing-underscore": "invalid/trailing-underscore.json",
        "reject-hyphen": "invalid/hyphen.json",
        "reject-non-ascii": "invalid/non-ascii.json",
        "reject-oversized": "invalid/oversized.json",
      ]
    }
  }

  var expectedFailureKeywords: [String: Set<String>] {
    [
      "reject-wrong-type": ["type"],
      "reject-null": ["type"],
      "reject-empty": ["minLength", "pattern"],
      "reject-uppercase": ["pattern"],
      "reject-leading-digit": ["pattern"],
      "reject-double-underscore": ["pattern"],
      "reject-trailing-underscore": ["pattern"],
      "reject-hyphen": ["pattern"],
      "reject-non-ascii": ["pattern"],
      "reject-oversized": ["maxLength"],
    ]
  }

  var expectedFixturePayloads: [String: PrimitiveFixturePayload] {
    switch self {
    case .confidenceCategory:
      [
        "valid-documented-low": .string("low"),
        "valid-documented-medium": .string("medium"),
        "valid-documented-high": .string("high"),
        "valid-forward-compatible": .string("synthetic_future_v2"),
        "valid-lower-boundary": .string("a"),
        "valid-upper-boundary": .string(String(repeating: "z", count: 128)),
        "reject-wrong-type": .integer(1),
        "reject-null": .null,
        "reject-empty": .string(""),
        "reject-uppercase": .string("High"),
        "reject-leading-digit": .string("1high"),
        "reject-double-underscore": .string("very__high"),
        "reject-trailing-underscore": .string("high_"),
        "reject-hyphen": .string("very-high"),
        "reject-non-ascii": .string("høy"),
        "reject-oversized": .string(String(repeating: "a", count: 129)),
      ]
    case .evaluatedScope:
      [
        "valid-documented-exact-url": .string("exact_url"),
        "valid-forward-compatible": .string("synthetic_scope_v2"),
        "valid-lower-boundary": .string("a"),
        "valid-upper-boundary": .string(String(repeating: "z", count: 128)),
        "reject-wrong-type": .integer(1),
        "reject-null": .null,
        "reject-empty": .string(""),
        "reject-uppercase": .string("Exact_url"),
        "reject-leading-digit": .string("1exact_url"),
        "reject-double-underscore": .string("exact__url"),
        "reject-trailing-underscore": .string("exact_url_"),
        "reject-hyphen": .string("exact-url"),
        "reject-non-ascii": .string("eksakt_område"),
        "reject-oversized": .string(String(repeating: "a", count: 129)),
      ]
    }
  }
}

private let verdictSupportingPrimitiveBoundarySentence =
  "These supporting primitives validate bounded wire values and an ordered reason collection only. They do not define verdict label/action coherence, a canonical Verdict object, or an evidence-bearing complete check-response envelope."

private let evaluatedScopeDocumentationBoundarySentence =
  "`exact_url` is the only documented public V1 scope here. Other grammar-valid synthetic fixtures prove additive parsing behavior without publishing another scope meaning."

private let verdictReasonsSchemaPath =
  "packages/contracts/schemas/verdict-reasons-v1.schema.json"
private let verdictReasonsOpenAPIReference =
  "./schemas/verdict-reasons-v1.schema.json"
private let verdictReasonSchemaID = "urn:hezo-link:contract:verdict-reason:v1"
private let verdictReasonsSchemaID = "urn:hezo-link:contract:verdict-reasons:v1"
private let verdictReasonsFixtureRoot = "packages/contracts/fixtures/verdict-reasons-v1"
private let verdictReasonsManifestPath = "\(verdictReasonsFixtureRoot)/manifest.json"

private let verdictSchemaPath = "packages/contracts/schemas/verdict-v1.schema.json"
private let verdictOpenAPIReference = "./schemas/verdict-v1.schema.json"
private let verdictSchemaID = "urn:hezo-link:contract:verdict:v1"
private let verdictFixtureRoot = "packages/contracts/fixtures/verdict-v1"
private let verdictManifestPath = "\(verdictFixtureRoot)/manifest.json"
private let verdictManifestSchemaReference = "../../schemas/verdict-v1.schema.json"
private let verdictLabelSchemaID = "urn:hezo-link:contract:verdict-label:v1"
private let recommendedActionSchemaID =
  "urn:hezo-link:contract:recommended-action:v1"
private let confidenceCategorySchemaID =
  "urn:hezo-link:contract:confidence-category:v1"
private let evaluatedScopeSchemaID = "urn:hezo-link:contract:evaluated-scope:v1"

private let expectedValidVerdictFixtureIDs: Set<String> = [
  "valid-unknown-warn", "valid-unknown-retry", "valid-no-known-danger-allow",
  "valid-caution-warn", "valid-dangerous-avoid",
]

private let expectedVerdictFixturePaths: [String: String] = [
  "valid-unknown-warn": "valid/unknown-warn.json",
  "valid-unknown-retry": "valid/unknown-retry.json",
  "valid-no-known-danger-allow": "valid/no-known-danger-allow.json",
  "valid-caution-warn": "valid/caution-warn.json",
  "valid-dangerous-avoid": "valid/dangerous-avoid.json",
  "reject-pair-unknown-allow": "invalid/pair-unknown-allow.json",
  "reject-pair-unknown-avoid": "invalid/pair-unknown-avoid.json",
  "reject-pair-no-known-danger-warn": "invalid/pair-no-known-danger-warn.json",
  "reject-pair-no-known-danger-avoid": "invalid/pair-no-known-danger-avoid.json",
  "reject-pair-no-known-danger-retry": "invalid/pair-no-known-danger-retry.json",
  "reject-pair-caution-allow": "invalid/pair-caution-allow.json",
  "reject-pair-caution-avoid": "invalid/pair-caution-avoid.json",
  "reject-pair-caution-retry": "invalid/pair-caution-retry.json",
  "reject-pair-dangerous-allow": "invalid/pair-dangerous-allow.json",
  "reject-pair-dangerous-warn": "invalid/pair-dangerous-warn.json",
  "reject-pair-dangerous-retry": "invalid/pair-dangerous-retry.json",
  "reject-block-eligible-field": "invalid/block-eligible-field.json",
  "reject-missing-reasons": "invalid/missing-reasons.json",
  "reject-wrong-top-level-type": "invalid/wrong-top-level-type.json",
  "reject-label-alias-safe": "invalid/label-alias-safe.json",
  "reject-action-alias-block": "invalid/action-alias-block.json",
  "reject-confidence-uppercase": "invalid/confidence-uppercase.json",
  "reject-evaluated-scope-uppercase": "invalid/evaluated-scope-uppercase.json",
  "reject-null-reasons": "invalid/null-reasons.json",
  "reject-too-many-reasons": "invalid/too-many-reasons.json",
  "reject-invalid-reason-code": "invalid/invalid-reason-code.json",
  "reject-reason-unknown-field": "invalid/reason-unknown-field.json",
]

private let expectedVerdictFailureKeywords: [String: Set<String>] = [
  "reject-pair-unknown-allow": ["enum", "const", "oneOf"],
  "reject-pair-unknown-avoid": ["enum", "const", "oneOf"],
  "reject-pair-no-known-danger-warn": ["const", "oneOf"],
  "reject-pair-no-known-danger-avoid": ["enum", "const", "oneOf"],
  "reject-pair-no-known-danger-retry": ["const", "oneOf"],
  "reject-pair-caution-allow": ["enum", "const", "oneOf"],
  "reject-pair-caution-avoid": ["enum", "const", "oneOf"],
  "reject-pair-caution-retry": ["const", "oneOf"],
  "reject-pair-dangerous-allow": ["enum", "const", "oneOf"],
  "reject-pair-dangerous-warn": ["const", "oneOf"],
  "reject-pair-dangerous-retry": ["const", "oneOf"],
  "reject-block-eligible-field": ["additionalProperties"],
  "reject-missing-reasons": ["required"],
  "reject-wrong-top-level-type": ["type", "oneOf"],
  "reject-label-alias-safe": ["enum", "const", "oneOf"],
  "reject-action-alias-block": ["enum", "const", "oneOf"],
  "reject-confidence-uppercase": ["pattern"],
  "reject-evaluated-scope-uppercase": ["pattern"],
  "reject-null-reasons": ["type"],
  "reject-too-many-reasons": ["maxItems"],
  "reject-invalid-reason-code": ["pattern"],
  "reject-reason-unknown-field": ["additionalProperties"],
]

private let verdictBoundarySentence =
  "This object validates bounded structure and label/action coherence only. It defines or authorizes no endpoint, HTTP behavior, check-response envelope, check token, target or display value, analysis-completeness or freshness decision, unavailable-collector state, source notice, version set, response lifetime, automatic block eligibility, or other enforcement decision. In particular, a structurally valid `no_known_danger`/`allow` value cannot authorize completed-response serialization without the selected profile's completeness and freshness requirements, and `dangerous`/`avoid` never implies block eligibility."

private let expectedValidVerdictReasonsFixtureIDs: Set<String> = [
  "valid-zero", "valid-one", "valid-two", "valid-three", "valid-four", "valid-five",
  "valid-duplicate-items",
]

private let expectedVerdictReasonsFixturePaths: [String: String] = [
  "valid-zero": "valid/zero.json",
  "valid-one": "valid/one.json",
  "valid-two": "valid/two.json",
  "valid-three": "valid/three.json",
  "valid-four": "valid/four.json",
  "valid-five": "valid/five.json",
  "valid-duplicate-items": "valid/duplicate-items.json",
  "reject-too-many": "invalid/too-many.json",
  "reject-wrong-top-level-type": "invalid/wrong-top-level-type.json",
  "reject-null": "invalid/null.json",
  "reject-wrong-item-type": "invalid/wrong-item-type.json",
  "reject-invalid-item-code": "invalid/invalid-item-code.json",
  "reject-item-unknown-field": "invalid/item-unknown-field.json",
  "reject-item-missing-observed-at": "invalid/item-missing-observed-at.json",
]

private let expectedVerdictReasonsFailureKeywords: [String: Set<String>] = [
  "reject-too-many": ["maxItems"],
  "reject-wrong-top-level-type": ["type"],
  "reject-null": ["type"],
  "reject-wrong-item-type": ["type"],
  "reject-invalid-item-code": ["pattern"],
  "reject-item-unknown-field": ["additionalProperties"],
  "reject-item-missing-observed-at": ["required"],
]

private let verdictReasonStableValuePattern = "^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$"

private let verdictReasonSummaryKeyPattern =
  #"^(?=.{1,128}(?:\.|$))[a-z][a-z0-9]*(?:_[a-z0-9]+)*(?:\.(?=.{1,128}(?:\.|$))[a-z][a-z0-9]*(?:_[a-z0-9]+)*)*$"#

private let verdictReasonObservedAtPattern = canonicalInstantPattern

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

private func declaredFailureKeywords(
  in fixtureCase: [String: Any]
) throws -> Set<String> {
  if let keyword = fixtureCase["expected_failure_keyword"] {
    guard
      Set(fixtureCase.keys)
        == ["id", "path", "expected_schema_valid", "expected_failure_keyword"]
    else {
      throw ContractAssetTestError.invalidAsset
    }
    return [try requireString(keyword)]
  }

  guard
    Set(fixtureCase.keys)
      == ["id", "path", "expected_schema_valid", "expected_failure_keywords"]
  else {
    throw ContractAssetTestError.invalidAsset
  }
  let keywords = try requireStringArray(fixtureCase["expected_failure_keywords"])
  guard keywords.isEmpty == false, Set(keywords).count == keywords.count else {
    throw ContractAssetTestError.invalidAsset
  }
  return Set(keywords)
}

// This independently evaluates only the frozen bounded stable-string subset used by the two
// supporting scalar schemas; it is not a general JSON Schema implementation.
private func stableStringSchemaFailures(
  in payload: PrimitiveFixturePayload
) -> Set<String> {
  switch payload {
  case .string(let value):
    var failures = Set<String>()
    if value.unicodeScalars.isEmpty {
      failures.insert("minLength")
    }
    if value.unicodeScalars.count > 128 {
      failures.insert("maxLength")
    }
    if isValidVerdictReasonStableValue(value) == false {
      failures.insert("pattern")
    }
    return failures
  case .integer, .null:
    return ["type"]
  }
}

private func roundTripSupportingStablePrimitive(
  _ primitive: VerdictSupportingStablePrimitiveContract,
  data: Data
) throws -> (decodedValue: String, encodedData: Data) {
  switch primitive {
  case .confidenceCategory:
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      ConfidenceCategory.self,
      from: data
    )
    return (decoded.rawValue, try HezoJSON.makeEncoder().encode(decoded))
  case .evaluatedScope:
    let decoded = try HezoJSON.makeResponseDecoder().decode(
      EvaluatedScope.self,
      from: data
    )
    return (decoded.rawValue, try HezoJSON.makeEncoder().encode(decoded))
  }
}

private func expectedVerdictReasonsFixture(id: String) throws -> Any {
  switch id {
  case "valid-zero":
    return try expectedSyntheticVerdictReasons(count: 0)
  case "valid-one":
    return try expectedSyntheticVerdictReasons(count: 1)
  case "valid-two":
    return try expectedSyntheticVerdictReasons(count: 2)
  case "valid-three":
    return try expectedSyntheticVerdictReasons(count: 3)
  case "valid-four":
    return try expectedSyntheticVerdictReasons(count: 4)
  case "valid-five":
    return try expectedSyntheticVerdictReasons(count: 5)
  case "valid-duplicate-items":
    let reason = try expectedSyntheticVerdictReason(1)
    return [reason, reason]
  case "reject-too-many":
    return try expectedSyntheticVerdictReasons(count: 6)
  case "reject-wrong-top-level-type":
    return [String: Any]()
  case "reject-null":
    return NSNull()
  case "reject-wrong-item-type":
    return [1]
  case "reject-invalid-item-code":
    var reason = try expectedSyntheticVerdictReason(1)
    reason["code"] = "Synthetic_reason_one"
    return [reason]
  case "reject-item-unknown-field":
    var reason = try expectedSyntheticVerdictReason(1)
    reason["future_optional"] = true
    return [reason]
  case "reject-item-missing-observed-at":
    var reason = try expectedSyntheticVerdictReason(1)
    reason.removeValue(forKey: "observed_at")
    return [reason]
  default:
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectedVerdictFixture(id: String) throws -> Any {
  switch id {
  case "valid-unknown-warn":
    return expectedVerdictFixture(
      label: "unknown",
      action: "warn",
      confidence: "synthetic_confidence_v2",
      evaluatedScope: "synthetic_scope_v2"
    )
  case "valid-unknown-retry":
    return expectedVerdictFixture(
      label: "unknown",
      action: "retry",
      confidence: "low"
    )
  case "valid-no-known-danger-allow":
    return expectedVerdictFixture(
      label: "no_known_danger",
      action: "allow",
      confidence: "high"
    )
  case "valid-caution-warn":
    return try expectedVerdictFixture(
      label: "caution",
      action: "warn",
      reasons: [
        expectedSyntheticVerdictReason(2), expectedSyntheticVerdictReason(1),
        expectedSyntheticVerdictReason(2), expectedSyntheticVerdictReason(3),
      ]
    )
  case "valid-dangerous-avoid":
    return try expectedVerdictFixture(
      label: "dangerous",
      action: "avoid",
      confidence: "high",
      reasons: expectedSyntheticVerdictReasons(count: 5)
    )
  case "reject-pair-unknown-allow":
    return expectedVerdictFixture(label: "unknown", action: "allow")
  case "reject-pair-unknown-avoid":
    return expectedVerdictFixture(label: "unknown", action: "avoid")
  case "reject-pair-no-known-danger-warn":
    return expectedVerdictFixture(label: "no_known_danger", action: "warn")
  case "reject-pair-no-known-danger-avoid":
    return expectedVerdictFixture(label: "no_known_danger", action: "avoid")
  case "reject-pair-no-known-danger-retry":
    return expectedVerdictFixture(label: "no_known_danger", action: "retry")
  case "reject-pair-caution-allow":
    return expectedVerdictFixture(label: "caution", action: "allow")
  case "reject-pair-caution-avoid":
    return expectedVerdictFixture(label: "caution", action: "avoid")
  case "reject-pair-caution-retry":
    return expectedVerdictFixture(label: "caution", action: "retry")
  case "reject-pair-dangerous-allow":
    return expectedVerdictFixture(label: "dangerous", action: "allow")
  case "reject-pair-dangerous-warn":
    return expectedVerdictFixture(label: "dangerous", action: "warn")
  case "reject-pair-dangerous-retry":
    return expectedVerdictFixture(label: "dangerous", action: "retry")
  case "reject-block-eligible-field":
    return expectedVerdictFixture(
      label: "dangerous",
      action: "avoid",
      confidence: "high",
      additionalProperties: ["block_eligible": true]
    )
  case "reject-missing-reasons":
    return expectedVerdictFixture(
      label: "caution",
      action: "warn",
      omittedProperties: ["reasons"]
    )
  case "reject-wrong-top-level-type":
    return [Any]()
  case "reject-label-alias-safe":
    return expectedVerdictFixture(
      label: "safe",
      action: "allow",
      confidence: "high"
    )
  case "reject-action-alias-block":
    return expectedVerdictFixture(
      label: "dangerous",
      action: "block",
      confidence: "high"
    )
  case "reject-confidence-uppercase":
    return expectedVerdictFixture(label: "caution", action: "warn", confidence: "High")
  case "reject-evaluated-scope-uppercase":
    return expectedVerdictFixture(
      label: "caution",
      action: "warn",
      evaluatedScope: "Exact_url"
    )
  case "reject-null-reasons":
    return expectedVerdictFixture(label: "caution", action: "warn", reasons: NSNull())
  case "reject-too-many-reasons":
    return try expectedVerdictFixture(
      label: "caution",
      action: "warn",
      reasons: expectedSyntheticVerdictReasons(count: 6)
    )
  case "reject-invalid-reason-code":
    var reason = try expectedSyntheticVerdictReason(1)
    reason["code"] = "Synthetic_reason"
    return expectedVerdictFixture(label: "caution", action: "warn", reasons: [reason])
  case "reject-reason-unknown-field":
    var reason = try expectedSyntheticVerdictReason(1)
    reason["future_optional"] = true
    return expectedVerdictFixture(label: "caution", action: "warn", reasons: [reason])
  default:
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectedVerdictFixture(
  label: Any,
  action: Any,
  confidence: Any = "medium",
  evaluatedScope: Any = "exact_url",
  reasons: Any = [Any](),
  additionalProperties: [String: Any] = [:],
  omittedProperties: Set<String> = []
) -> [String: Any] {
  var object: [String: Any] = [
    "label": label,
    "recommended_action": action,
    "confidence": confidence,
    "evaluated_scope": evaluatedScope,
    "reasons": reasons,
  ]
  object.merge(additionalProperties) { _, newValue in newValue }
  for property in omittedProperties {
    object.removeValue(forKey: property)
  }
  return object
}

private func expectedSyntheticVerdictReasons(count: Int) throws -> [[String: Any]] {
  guard (0...6).contains(count) else {
    throw ContractAssetTestError.invalidAsset
  }
  return try (0..<count).map { index in
    try expectedSyntheticVerdictReason(index + 1)
  }
}

private func expectedSyntheticVerdictReason(_ ordinal: Int) throws -> [String: Any] {
  let suffix: String
  let severity: String
  let freshness: String
  switch ordinal {
  case 1:
    (suffix, severity, freshness) = ("one", "low", "current")
  case 2:
    (suffix, severity, freshness) = ("two", "medium", "recent")
  case 3:
    (suffix, severity, freshness) = ("three", "high", "current")
  case 4:
    (suffix, severity, freshness) = ("four", "advisory", "stale")
  case 5:
    (suffix, severity, freshness) = ("five", "informational", "historical")
  case 6:
    (suffix, severity, freshness) = ("six", "experimental", "archived")
  default:
    throw ContractAssetTestError.invalidAsset
  }

  return [
    "code": "synthetic_reason_\(suffix)",
    "family": "synthetic_evidence",
    "severity": severity,
    "summary_key": "verdict.reason.synthetic_reason_\(suffix)",
    "observed_at": "2000-01-01T00:00:0\(ordinal)Z",
    "freshness": freshness,
  ]
}

private func verdictReasonCountName(_ count: Int) throws -> String {
  switch count {
  case 0: "zero"
  case 1: "one"
  case 2: "two"
  case 3: "three"
  case 4: "four"
  case 5: "five"
  default: throw ContractAssetTestError.invalidAsset
  }
}

private func jsonValuesAreEqual(_ lhs: Any, _ rhs: Any) throws -> Bool {
  do {
    let options: JSONSerialization.WritingOptions = [
      .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed,
    ]
    let lhsData = try JSONSerialization.data(withJSONObject: lhs, options: options)
    let rhsData = try JSONSerialization.data(withJSONObject: rhs, options: options)
    return lhsData == rhsData
  } catch {
    throw ContractAssetTestError.invalidAsset
  }
}

private struct FrozenVerdictSchemas {
  let label: [String: Any]
  let recommendedAction: [String: Any]
  let confidence: [String: Any]
  let evaluatedScope: [String: Any]
  let reasons: [String: Any]
}

private func loadVerdictSchemaRegistry() throws -> [String: [String: Any]] {
  let paths = [
    "packages/contracts/schemas/verdict-label-v1.schema.json",
    "packages/contracts/schemas/recommended-action-v1.schema.json",
    "packages/contracts/schemas/confidence-category-v1.schema.json",
    "packages/contracts/schemas/evaluated-scope-v1.schema.json",
    "packages/contracts/schemas/verdict-reasons-v1.schema.json",
    "packages/contracts/schemas/verdict-reason-v1.schema.json",
  ]
  var registry: [String: [String: Any]] = [:]
  for path in paths {
    let schema = try loadObject(path)
    let schemaID = try requireString(schema["$id"])
    guard registry.updateValue(schema, forKey: schemaID) == nil else {
      throw ContractAssetTestError.invalidAsset
    }
  }
  return registry
}

private func resolveFrozenVerdictSchemas(
  from schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> FrozenVerdictSchemas {
  let expectedReferences = [
    "label": verdictLabelSchemaID,
    "recommended_action": recommendedActionSchemaID,
    "confidence": confidenceCategorySchemaID,
    "evaluated_scope": evaluatedScopeSchemaID,
    "reasons": verdictReasonsSchemaID,
  ]
  let properties = try requireObject(schema["properties"])
  guard Set(properties.keys) == Set(expectedReferences.keys) else {
    throw ContractAssetTestError.invalidAsset
  }

  var resolved: [String: [String: Any]] = [:]
  for (field, expectedReference) in expectedReferences {
    let property = try requireObject(properties[field])
    guard Set(property.keys) == ["$ref"],
      property["$ref"] as? String == expectedReference,
      let referencedSchema = registry[expectedReference],
      referencedSchema["$id"] as? String == expectedReference
    else {
      throw ContractAssetTestError.invalidAsset
    }
    resolved[field] = referencedSchema
  }

  let label = try requireObject(resolved["label"])
  let recommendedAction = try requireObject(resolved["recommended_action"])
  let confidence = try requireObject(resolved["confidence"])
  let evaluatedScope = try requireObject(resolved["evaluated_scope"])
  let reasons = try requireObject(resolved["reasons"])
  try requireFrozenStringEnumSurface(
    label,
    schemaID: verdictLabelSchemaID,
    values: ["unknown", "no_known_danger", "caution", "dangerous"]
  )
  try requireFrozenStringEnumSurface(
    recommendedAction,
    schemaID: recommendedActionSchemaID,
    values: ["allow", "warn", "avoid", "retry"]
  )
  try requireFrozenStableStringSurface(confidence, schemaID: confidenceCategorySchemaID)
  try requireFrozenStableStringSurface(evaluatedScope, schemaID: evaluatedScopeSchemaID)
  guard reasons["$id"] as? String == verdictReasonsSchemaID,
    reasons["type"] as? String == "array",
    integerValue(reasons["minItems"]) == 0,
    integerValue(reasons["maxItems"]) == 5
  else {
    throw ContractAssetTestError.invalidAsset
  }
  _ = try resolveFrozenVerdictReasonSchema(from: reasons, registry: registry)

  return FrozenVerdictSchemas(
    label: label,
    recommendedAction: recommendedAction,
    confidence: confidence,
    evaluatedScope: evaluatedScope,
    reasons: reasons
  )
}

private func requireFrozenStringEnumSurface(
  _ schema: [String: Any],
  schemaID: String,
  values: [String]
) throws {
  guard Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "enum"],
    schema["$id"] as? String == schemaID,
    schema["type"] as? String == "string",
    try requireStringArray(schema["enum"]) == values
  else {
    throw ContractAssetTestError.invalidAsset
  }
}

private func requireFrozenStableStringSurface(
  _ schema: [String: Any],
  schemaID: String
) throws {
  guard
    Set(schema.keys)
      == [
        "$schema", "$id", "title", "description", "type", "minLength", "maxLength",
        "pattern",
      ],
    schema["$id"] as? String == schemaID,
    schema["type"] as? String == "string",
    integerValue(schema["minLength"]) == 1,
    integerValue(schema["maxLength"]) == 128,
    schema["pattern"] as? String == verdictReasonStableValuePattern
  else {
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectedVerdictCoherenceBranches() -> [[String: Any]] {
  [
    [
      "properties": [
        "label": ["const": "unknown"],
        "recommended_action": ["enum": ["warn", "retry"]],
      ]
    ],
    [
      "properties": [
        "label": ["const": "no_known_danger"],
        "recommended_action": ["const": "allow"],
      ]
    ],
    [
      "properties": [
        "label": ["const": "caution"],
        "recommended_action": ["const": "warn"],
      ]
    ],
    [
      "properties": [
        "label": ["const": "dangerous"],
        "recommended_action": ["const": "avoid"],
      ]
    ],
  ]
}

// This evaluator implements only the exact frozen Verdict V1 object, referenced primitive, and
// coherence-branch surfaces. It deliberately rejects missing registrations and inline substitutes.
private func verdictSchemaFailures(
  in value: Any,
  schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> Set<String> {
  guard
    Set(schema.keys)
      == [
        "$schema", "$id", "title", "description", "type", "additionalProperties",
        "required", "properties", "oneOf",
      ],
    schema["$id"] as? String == verdictSchemaID,
    schema["type"] as? String == "object",
    try requireBool(schema["additionalProperties"]) == false,
    try requireStringArray(schema["required"])
      == ["label", "recommended_action", "confidence", "evaluated_scope", "reasons"],
    try jsonValuesAreEqual(
      requireJSONArray(schema["oneOf"]),
      expectedVerdictCoherenceBranches()
    )
  else {
    throw ContractAssetTestError.invalidAsset
  }
  let resolved = try resolveFrozenVerdictSchemas(from: schema, registry: registry)
  var failures = try verdictCoherenceFailures(in: value, schema: schema)

  guard let object = value as? [String: Any] else {
    failures.insert("type")
    return failures
  }

  let requiredFields: Set<String> = [
    "label", "recommended_action", "confidence", "evaluated_scope", "reasons",
  ]
  if requiredFields.isSubset(of: Set(object.keys)) == false {
    failures.insert("required")
  }
  if Set(object.keys).subtracting(requiredFields).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if let label = object["label"] {
    failures.formUnion(
      frozenStringEnumFailures(
        in: label,
        allowedValues: try requireStringArray(resolved.label["enum"])
      )
    )
  }
  if let action = object["recommended_action"] {
    failures.formUnion(
      frozenStringEnumFailures(
        in: action,
        allowedValues: try requireStringArray(resolved.recommendedAction["enum"])
      )
    )
  }
  if let confidence = object["confidence"] {
    failures.formUnion(frozenStableStringFailures(in: confidence))
  }
  if let evaluatedScope = object["evaluated_scope"] {
    failures.formUnion(frozenStableStringFailures(in: evaluatedScope))
  }
  if let reasons = object["reasons"] {
    failures.formUnion(
      try verdictReasonsSchemaFailures(in: reasons, schema: resolved.reasons, registry: registry)
    )
  }
  return failures
}

private func verdictCoherenceFailures(
  in value: Any,
  schema: [String: Any]
) throws -> Set<String> {
  let branches = try requireObjectArray(schema["oneOf"])
  guard try jsonValuesAreEqual(branches, expectedVerdictCoherenceBranches()) else {
    throw ContractAssetTestError.invalidAsset
  }
  guard let object = value as? [String: Any] else {
    return ["oneOf"]
  }

  var matchingBranchCount = 0
  var branchFailures = Set<String>()
  for branch in branches {
    guard Set(branch.keys) == ["properties"] else {
      throw ContractAssetTestError.invalidAsset
    }
    let properties = try requireObject(branch["properties"])
    guard Set(properties.keys) == ["label", "recommended_action"] else {
      throw ContractAssetTestError.invalidAsset
    }
    var failures = Set<String>()
    for field in ["label", "recommended_action"] {
      guard let candidate = object[field] else {
        continue
      }
      let constraint = try requireObject(properties[field])
      if let constant = constraint["const"] {
        guard Set(constraint.keys) == ["const"] else {
          throw ContractAssetTestError.invalidAsset
        }
        if try jsonValuesAreEqual(candidate, constant) == false {
          failures.insert("const")
        }
      } else {
        guard Set(constraint.keys) == ["enum"] else {
          throw ContractAssetTestError.invalidAsset
        }
        let allowedValues = try requireStringArray(constraint["enum"])
        guard let candidate = candidate as? String, allowedValues.contains(candidate) else {
          failures.insert("enum")
          continue
        }
      }
    }
    if failures.isEmpty {
      matchingBranchCount += 1
    }
    branchFailures.formUnion(failures)
  }

  guard matchingBranchCount == 1 else {
    branchFailures.insert("oneOf")
    return branchFailures
  }
  return []
}

private func frozenStringEnumFailures(
  in value: Any,
  allowedValues: [String]
) -> Set<String> {
  guard let string = value as? String else {
    return ["type", "enum"]
  }
  return allowedValues.contains(string) ? [] : ["enum"]
}

private func frozenStableStringFailures(in value: Any) -> Set<String> {
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
  if isValidVerdictReasonStableValue(string) == false {
    failures.insert("pattern")
  }
  return failures
}

private func requireJSONArray(_ value: Any?) throws -> [Any] {
  guard let array = value as? [Any] else {
    throw ContractAssetTestError.invalidAsset
  }
  return array
}

// This evaluator deliberately resolves the collection's absolute Verdict Reason V1 reference
// from a caller-supplied registry. Unknown references and inline substitutes are asset errors.
private func verdictReasonsSchemaFailures(
  in value: Any,
  schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> Set<String> {
  _ = try resolveFrozenVerdictReasonSchema(from: schema, registry: registry)
  guard schema["type"] as? String == "array",
    integerValue(schema["minItems"]) == 0,
    integerValue(schema["maxItems"]) == 5
  else {
    throw ContractAssetTestError.invalidAsset
  }

  guard let items = value as? [Any] else {
    return ["type"]
  }

  var failures = Set<String>()
  if items.isEmpty {
    // The exact lower boundary is zero, so the empty collection is valid.
  }
  if items.count > 5 {
    failures.insert("maxItems")
  }
  for item in items {
    guard let reason = item as? [String: Any] else {
      failures.insert("type")
      continue
    }
    failures.formUnion(verdictReasonSchemaFailures(in: reason))
  }
  return failures
}

private func resolveFrozenVerdictReasonSchema(
  from collectionSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let items = try requireObject(collectionSchema["items"])
  guard Set(items.keys) == ["$ref"],
    let reference = items["$ref"] as? String,
    reference == verdictReasonSchemaID,
    let resolvedSchema = registry[reference],
    resolvedSchema["$id"] as? String == reference
  else {
    throw ContractAssetTestError.invalidAsset
  }
  try requireFrozenVerdictReasonEvaluatorSurface(resolvedSchema)
  return resolvedSchema
}

private func requireFrozenVerdictReasonEvaluatorSurface(
  _ schema: [String: Any]
) throws {
  let expectedFields: Set<String> = [
    "code", "family", "severity", "summary_key", "observed_at", "freshness",
  ]
  guard schema["$id"] as? String == verdictReasonSchemaID,
    schema["type"] as? String == "object",
    try requireBool(schema["additionalProperties"]) == false
  else {
    throw ContractAssetTestError.invalidAsset
  }
  let required = try requireStringArray(schema["required"])
  guard required.count == expectedFields.count, Set(required) == expectedFields else {
    throw ContractAssetTestError.invalidAsset
  }
  let properties = try requireObject(schema["properties"])
  guard Set(properties.keys) == expectedFields else {
    throw ContractAssetTestError.invalidAsset
  }

  for field in ["code", "family", "severity", "freshness"] {
    let property = try requireObject(properties[field])
    guard property["type"] as? String == "string",
      integerValue(property["minLength"]) == 1,
      integerValue(property["maxLength"]) == 128,
      property["pattern"] as? String == verdictReasonStableValuePattern
    else {
      throw ContractAssetTestError.invalidAsset
    }
  }

  let summaryKey = try requireObject(properties["summary_key"])
  guard summaryKey["type"] as? String == "string",
    integerValue(summaryKey["minLength"]) == 1,
    integerValue(summaryKey["maxLength"]) == 256,
    summaryKey["pattern"] as? String == verdictReasonSummaryKeyPattern
  else {
    throw ContractAssetTestError.invalidAsset
  }

  let observedAt = try requireObject(properties["observed_at"])
  guard Set(observedAt.keys) == ["$ref"],
    observedAt["$ref"] as? String == canonicalInstantSchemaID
  else {
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectVerdictReasonsDecodeErrorOmitsCandidate(
  _ payload: Any,
  candidate: String
) throws {
  let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(VerdictReasons.self, from: data)
    Issue.record("A Verdict Reasons privacy canary was accepted")
  } catch let error as DecodingError {
    #expect(String(describing: error).contains(candidate) == false)
    #expect(String(reflecting: error).contains(candidate) == false)
  } catch {
    Issue.record("Verdict Reasons privacy canary used an unexpected error category")
  }
}

private func expectVerdictDecodeErrorOmitsCandidate(
  _ payload: Any,
  candidate: String
) throws {
  let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(Verdict.self, from: data)
    Issue.record("A Verdict V1 privacy canary was accepted")
  } catch let error as DecodingError {
    #expect(String(describing: error).contains(candidate) == false)
    #expect(String(reflecting: error).contains(candidate) == false)
  } catch {
    Issue.record("Verdict V1 privacy canary used an unexpected error category")
  }
}

private func loadJSONValue(_ relativePath: String) throws -> Any {
  try jsonValue(from: loadData(relativePath))
}

private func jsonValue(from data: Data) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  } catch {
    throw ContractAssetTestError.invalidAsset
  }
}

private func primitiveFixturePayload(from value: Any) throws -> PrimitiveFixturePayload {
  if let string = value as? String {
    return .string(string)
  }
  if value is NSNull {
    return .null
  }
  if let integer = integerValue(value) {
    return .integer(integer)
  }
  throw ContractAssetTestError.invalidAsset
}

private func requirePrimitiveString(_ value: Any) throws -> String {
  guard let string = value as? String else {
    throw ContractAssetTestError.invalidAsset
  }
  return string
}

// This independently evaluates only the frozen scalar string-enum vocabulary used by these
// fixtures; it is not a general JSON Schema implementation.
private func primitiveEnumSchemaFailures(
  in payload: PrimitiveFixturePayload,
  allowedValues: Set<String>
) -> Set<String> {
  switch payload {
  case .string(let value):
    allowedValues.contains(value) ? [] : ["enum"]
  case .integer, .null:
    ["type", "enum"]
  }
}

private func decodeVerdictPrimitive(
  _ primitive: VerdictPrimitiveContract,
  from data: Data
) throws {
  switch primitive {
  case .verdictLabel:
    _ = try HezoJSON.makeResponseDecoder().decode(VerdictLabelV1.self, from: data)
  case .recommendedAction:
    _ = try HezoJSON.makeResponseDecoder().decode(RecommendedActionV1.self, from: data)
  }
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

private func expectedPendingCheckResponseFixture(id: String) throws -> Any {
  switch id {
  case "valid-standard":
    return expectedPendingCheckResponseObject(requestID: "synthetic-request-001")
  case "valid-retry-after-ms-lower-boundary":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: 1,
      requestID: "synthetic-retry-lower"
    )
  case "valid-retry-after-ms-upper-boundary":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: 900_000,
      requestID: "synthetic-retry-upper"
    )
  case "valid-request-id-upper-boundary":
    return expectedPendingCheckResponseObject(requestID: String(repeating: "R", count: 128))
  case "valid-canonical-token-controls":
    return expectedPendingCheckResponseObject(
      checkToken: "-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_8",
      requestID: "synthetic-token-controls"
    )
  case "reject-missing-schema-version":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-missing-schema-version",
      omittedProperties: ["schema_version"]
    )
  case "reject-missing-status":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-missing-status",
      omittedProperties: ["status"]
    )
  case "reject-missing-check-token":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-missing-check-token",
      omittedProperties: ["check_token"]
    )
  case "reject-missing-retry-after-ms":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-missing-retry",
      omittedProperties: ["retry_after_ms"]
    )
  case "reject-missing-expires-at":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-missing-expiry",
      omittedProperties: ["expires_at"]
    )
  case "reject-missing-request-id":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-omitted-request",
      omittedProperties: ["request_id"]
    )
  case "reject-schema-version-mismatch":
    return expectedPendingCheckResponseObject(
      schemaVersion: 2,
      requestID: "synthetic-schema-mismatch"
    )
  case "reject-status-complete":
    return expectedPendingCheckResponseObject(
      status: "complete",
      requestID: "synthetic-complete-status"
    )
  case "reject-status-invalid":
    return expectedPendingCheckResponseObject(
      status: "waiting",
      requestID: "synthetic-invalid-status"
    )
  case "reject-check-token-short":
    return expectedPendingCheckResponseObject(
      checkToken: String(repeating: "A", count: 42),
      requestID: "synthetic-token-short"
    )
  case "reject-check-token-long":
    return expectedPendingCheckResponseObject(
      checkToken: String(repeating: "A", count: 44),
      requestID: "synthetic-token-long"
    )
  case "reject-check-token-invalid-character":
    return expectedPendingCheckResponseObject(
      checkToken: "+" + String(repeating: "A", count: 42),
      requestID: "synthetic-token-character"
    )
  case "reject-check-token-noncanonical-final-character":
    return expectedPendingCheckResponseObject(
      checkToken: String(repeating: "A", count: 42) + "B",
      requestID: "synthetic-token-final"
    )
  case "reject-check-token-null":
    return expectedPendingCheckResponseObject(
      checkToken: NSNull(),
      requestID: "synthetic-token-null"
    )
  case "reject-check-token-wrong-type":
    return expectedPendingCheckResponseObject(
      checkToken: 32,
      requestID: "synthetic-token-type"
    )
  case "reject-retry-after-ms-zero":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: 0,
      requestID: "synthetic-retry-zero"
    )
  case "reject-retry-after-ms-above-maximum":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: 900_001,
      requestID: "synthetic-retry-above-max"
    )
  case "reject-retry-after-ms-fractional":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: 750.5,
      requestID: "synthetic-retry-fraction"
    )
  case "reject-retry-after-ms-null":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: NSNull(),
      requestID: "synthetic-retry-null"
    )
  case "reject-retry-after-ms-wrong-type":
    return expectedPendingCheckResponseObject(
      retryAfterMilliseconds: "750",
      requestID: "synthetic-retry-type"
    )
  case "reject-expires-at-fractional":
    return expectedPendingCheckResponseObject(
      expiresAt: "2000-01-01T00:15:00.000Z",
      requestID: "synthetic-expiry-fraction"
    )
  case "reject-expires-at-offset":
    return expectedPendingCheckResponseObject(
      expiresAt: "2000-01-01T01:15:00+01:00",
      requestID: "synthetic-expiry-offset"
    )
  case "reject-expires-at-impossible":
    return expectedPendingCheckResponseObject(
      expiresAt: "2000-02-30T00:15:00Z",
      requestID: "synthetic-expiry-impossible"
    )
  case "reject-expires-at-lowercase-z":
    return expectedPendingCheckResponseObject(
      expiresAt: "2000-01-01T00:15:00z",
      requestID: "synthetic-expiry-lowercase"
    )
  case "reject-expires-at-year-zero":
    return expectedPendingCheckResponseObject(
      expiresAt: "0000-01-01T00:00:00Z",
      requestID: "synthetic-request-001"
    )
  case "reject-expires-at-null":
    return expectedPendingCheckResponseObject(
      expiresAt: NSNull(),
      requestID: "synthetic-expiry-null"
    )
  case "reject-expires-at-wrong-type":
    return expectedPendingCheckResponseObject(
      expiresAt: 946_685_700,
      requestID: "synthetic-expiry-type"
    )
  case "reject-request-id-empty":
    return expectedPendingCheckResponseObject(requestID: "")
  case "reject-request-id-invalid-character":
    return expectedPendingCheckResponseObject(requestID: "synthetic.request")
  case "reject-request-id-oversized":
    return expectedPendingCheckResponseObject(requestID: String(repeating: "R", count: 129))
  case "reject-request-id-null":
    return expectedPendingCheckResponseObject(requestID: NSNull())
  case "reject-request-id-wrong-type":
    return expectedPendingCheckResponseObject(requestID: true)
  case "reject-wrong-top-level-type":
    return [Any]()
  case "reject-unknown-future-field":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-future-field",
      additionalProperties: ["future_optional": "synthetic-additive-value"]
    )
  case "reject-forbidden-verdict":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-verdict",
      additionalProperties: ["verdict": [String: Any]()]
    )
  case "reject-forbidden-target":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-target",
      additionalProperties: ["target": "synthetic-target"]
    )
  case "reject-forbidden-analysis":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-analysis",
      additionalProperties: ["analysis": [String: Any]()]
    )
  case "reject-forbidden-source-notices":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-notices",
      additionalProperties: ["source_notices": [Any]()]
    )
  case "reject-forbidden-versions":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-versions",
      additionalProperties: ["versions": [String: Any]()]
    )
  case "reject-forbidden-evaluated-at":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-evaluated",
      additionalProperties: ["evaluated_at": "2000-01-01T00:00:00Z"]
    )
  case "reject-forbidden-valid-until":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-validity",
      additionalProperties: ["valid_until": "2000-01-01T01:00:00Z"]
    )
  case "reject-forbidden-block-eligible":
    return expectedPendingCheckResponseObject(
      requestID: "synthetic-forbidden-block",
      additionalProperties: ["block_eligible": false]
    )
  default:
    throw ContractAssetTestError.invalidAsset
  }
}

private func expectedPendingCheckResponseObject(
  schemaVersion: Any = 1,
  status: Any = "pending",
  checkToken: Any = pendingCheckDefaultToken,
  retryAfterMilliseconds: Any = 750,
  expiresAt: Any = pendingCheckDefaultExpiry,
  requestID: Any,
  additionalProperties: [String: Any] = [:],
  omittedProperties: Set<String> = []
) -> [String: Any] {
  var object: [String: Any] = [
    "schema_version": schemaVersion,
    "status": status,
    "check_token": checkToken,
    "retry_after_ms": retryAfterMilliseconds,
    "expires_at": expiresAt,
    "request_id": requestID,
  ]
  object.merge(additionalProperties) { _, newValue in newValue }
  for property in omittedProperties {
    object.removeValue(forKey: property)
  }
  return object
}

private func loadPendingCheckResponseSchemaRegistry() throws -> [String: [String: Any]] {
  [
    checkResponseStatusSchemaID: try loadObject(checkResponseStatusSchemaPath),
    checkTokenSchemaID: try loadObject(checkTokenSchemaPath),
    canonicalInstantSchemaID: try loadObject(canonicalInstantSchemaPath),
    requestIDSchemaID: try loadObject(requestIDSchemaPath),
  ]
}

private func resolveFrozenPendingCheckResponseStatusSchema(
  from pendingSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireObject(pendingSchema["properties"])
  let status = try requireObject(properties["status"])
  guard Set(status.keys) == ["$ref", "const"],
    let reference = status["$ref"] as? String,
    reference == checkResponseStatusSchemaID,
    status["const"] as? String == "pending",
    let resolved = registry[reference],
    resolved["$id"] as? String == reference
  else {
    throw ContractAssetTestError.invalidAsset
  }
  try requireFrozenPendingCheckResponseStatusEvaluatorSurface(resolved)
  return resolved
}

private func requireFrozenPendingCheckResponseStatusEvaluatorSurface(
  _ schema: [String: Any]
) throws {
  guard
    Set(schema.keys) == ["$schema", "$id", "title", "description", "type", "enum"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == checkResponseStatusSchemaID,
    schema["type"] as? String == "string",
    try requireStringArray(schema["enum"]) == checkResponseStatusWireValues
  else {
    throw ContractAssetTestError.invalidAsset
  }
}

private func resolveFrozenPendingCheckResponseRequestIDSchema(
  from pendingSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireObject(pendingSchema["properties"])
  return try resolveFrozenRequestIDSchema(from: properties["request_id"], registry: registry)
}

private func resolveFrozenPendingCheckResponseCheckTokenSchema(
  from pendingSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireObject(pendingSchema["properties"])
  let referenceObject = try requireObject(properties["check_token"])
  guard Set(referenceObject.keys) == ["$ref"],
    let reference = referenceObject["$ref"] as? String,
    reference == checkTokenSchemaID,
    let resolved = registry[reference],
    resolved["$id"] as? String == reference,
    resolved["type"] as? String == "string",
    integerValue(resolved["minLength"]) == 43,
    integerValue(resolved["maxLength"]) == 43,
    resolved["pattern"] as? String == pendingCheckTokenPattern
  else {
    throw ContractAssetTestError.invalidAsset
  }
  return resolved
}

private func resolveFrozenPendingCheckResponseCanonicalInstantSchema(
  from pendingSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireObject(pendingSchema["properties"])
  let referenceObject = try requireObject(properties["expires_at"])
  guard Set(referenceObject.keys) == ["$ref"],
    let reference = referenceObject["$ref"] as? String,
    reference == canonicalInstantSchemaID,
    let resolved = registry[reference],
    Set(resolved.keys) == ["$schema", "$id", "title", "description", "type", "pattern", "format"],
    resolved["$id"] as? String == reference,
    resolved["type"] as? String == "string",
    resolved["pattern"] as? String == canonicalInstantPattern,
    resolved["format"] as? String == "date-time"
  else {
    throw ContractAssetTestError.invalidAsset
  }
  return resolved
}

private func requireFrozenPendingCheckResponseEvaluatorSurface(
  _ schema: [String: Any],
  registry: [String: [String: Any]]
) throws {
  guard schema["$id"] as? String == pendingCheckResponseSchemaID,
    schema["type"] as? String == "object",
    try requireBool(schema["additionalProperties"]) == false,
    try requireStringArray(schema["required"]) == pendingCheckResponseFields
  else {
    throw ContractAssetTestError.invalidAsset
  }
  let properties = try requireObject(schema["properties"])
  guard Set(properties.keys) == Set(pendingCheckResponseFields) else {
    throw ContractAssetTestError.invalidAsset
  }

  let schemaVersion = try requireObject(properties["schema_version"])
  guard Set(schemaVersion.keys) == ["type", "const"],
    schemaVersion["type"] as? String == "integer",
    integerValue(schemaVersion["const"]) == 1
  else {
    throw ContractAssetTestError.invalidAsset
  }
  _ = try resolveFrozenPendingCheckResponseStatusSchema(from: schema, registry: registry)

  _ = try resolveFrozenPendingCheckResponseCheckTokenSchema(from: schema, registry: registry)

  _ = try resolveFrozenPendingCheckResponseCanonicalInstantSchema(
    from: schema,
    registry: registry
  )

  let retryAfter = try requireObject(properties["retry_after_ms"])
  guard retryAfter["type"] as? String == "integer",
    integerValue(retryAfter["minimum"]) == 1,
    integerValue(retryAfter["maximum"]) == 900_000
  else {
    throw ContractAssetTestError.invalidAsset
  }

  _ = try resolveFrozenPendingCheckResponseRequestIDSchema(from: schema, registry: registry)
}

// This independently evaluates only the frozen Pending Check Response V1 subset after resolving
// its absolute status, check-token, and request-ID schema references from the supplied registry.
// It is not a general JSON Schema Draft 2020-12 or RFC 3339 implementation.
private func pendingCheckResponseSchemaFailures(
  in value: Any,
  schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> Set<String> {
  try requireFrozenPendingCheckResponseEvaluatorSurface(schema, registry: registry)
  return pendingCheckResponseSchemaFailures(in: value)
}

// This independently evaluates only the frozen Pending Check Response V1 structure; it is not a
// general JSON Schema Draft 2020-12 or RFC 3339 implementation.
private func pendingCheckResponseSchemaFailures(in value: Any) -> Set<String> {
  guard let object = value as? [String: Any] else {
    return ["type"]
  }

  let requiredKeys: Set<String> = [
    "schema_version", "status", "check_token", "retry_after_ms", "expires_at",
    "request_id",
  ]
  var failures = Set<String>()

  if Set(object.keys).subtracting(requiredKeys).isEmpty == false {
    failures.insert("additionalProperties")
  }
  if requiredKeys.subtracting(object.keys).isEmpty == false {
    failures.insert("required")
  }

  checkIntegerConstant(object["schema_version"], constant: 1, failures: &failures)
  checkPendingCheckResponseStatus(object["status"], failures: &failures)
  checkPendingCheckToken(object["check_token"], failures: &failures)
  checkPendingRetryAfterMilliseconds(object["retry_after_ms"], failures: &failures)
  checkPendingExpiresAt(object["expires_at"], failures: &failures)
  checkPendingRequestID(object["request_id"], failures: &failures)
  return failures
}

private func checkPendingCheckResponseStatus(
  _ value: Any?,
  failures: inout Set<String>
) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if checkResponseStatusWireValues.contains(string) == false {
    failures.insert("enum")
  }
  if string != CheckResponseStatus.pending.rawValue {
    failures.insert("const")
  }
}

private func checkPendingCheckToken(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.count < CheckTokenV1.encodedCharacterCount {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > CheckTokenV1.encodedCharacterCount {
    failures.insert("maxLength")
  }
  if isValidPendingCheckToken(string) == false {
    failures.insert("pattern")
  }
}

private func isValidPendingCheckToken(_ value: String) -> Bool {
  let bytes = Array(value.utf8)
  guard bytes.count == CheckTokenV1.encodedCharacterCount else {
    return false
  }
  guard bytes.dropLast().allSatisfy(isAllowedPendingCheckTokenByte) else {
    return false
  }
  guard let finalByte = bytes.last else {
    return false
  }
  return [
    0x41, 0x45, 0x49, 0x4D, 0x51, 0x55, 0x59, 0x63, 0x67, 0x6B, 0x6F, 0x73, 0x77, 0x30, 0x34, 0x38,
  ]
  .contains(finalByte)
}

private func isAllowedPendingCheckTokenByte(_ byte: UInt8) -> Bool {
  (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
    || (0x30...0x39).contains(byte) || byte == 0x2D || byte == 0x5F
}

private func checkPendingRetryAfterMilliseconds(
  _ value: Any?,
  failures: inout Set<String>
) {
  guard let integer = integerValue(value) else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if integer < 1 {
    failures.insert("minimum")
  }
  if integer > 900_000 {
    failures.insert("maximum")
  }
}

private func checkPendingExpiresAt(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }

  let pattern =
    #"^(?!0000-)[0-9]{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"#
  if string.range(of: pattern, options: .regularExpression) == nil {
    failures.insert("pattern")
    return
  }
  if isRealPendingExpiryDateTime(string) == false {
    failures.insert("format")
  }
}

private func isRealPendingExpiryDateTime(_ value: String) -> Bool {
  let pattern =
    #"^([0-9]{4})-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"#
  guard let expression = try? NSRegularExpression(pattern: pattern) else {
    return false
  }
  let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
  guard let match = expression.firstMatch(in: value, range: fullRange), match.range == fullRange,
    let year = integerCapture(1, from: match, in: value),
    let month = integerCapture(2, from: match, in: value),
    let day = integerCapture(3, from: match, in: value),
    year >= 1
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

private func checkPendingRequestID(_ value: Any?, failures: inout Set<String>) {
  guard let string = value as? String else {
    if value != nil {
      failures.insert("type")
    }
    return
  }
  if string.unicodeScalars.isEmpty {
    failures.insert("minLength")
    failures.insert("pattern")
  }
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
  }
  if string.utf8.allSatisfy(isAllowedRequestIDByte) == false {
    failures.insert("pattern")
  }
}

private func pendingCheckResponsePrivateCandidates(in value: Any) -> [String] {
  guard let object = value as? [String: Any] else {
    return []
  }
  return ["check_token", "request_id"].compactMap { field in
    guard let candidate = object[field] as? String, candidate.isEmpty == false else {
      return nil
    }
    return candidate
  }
}

private func expectPendingCheckResponseDecodeFailure(
  from data: Data,
  fixtureID: String,
  privateCandidates: [String]
) throws {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(PendingCheckResponseV1.self, from: data)
    Issue.record("A declared invalid pending check response was accepted: \(fixtureID)")
  } catch let error as DecodingError {
    for candidate in privateCandidates where candidate.isEmpty == false {
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    }
  } catch {
    Issue.record("Pending check response decoding used an unexpected error category: \(fixtureID)")
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

private func loadProblemSchemaRegistry() throws -> [String: [String: Any]] {
  [requestIDSchemaID: try loadObject(requestIDSchemaPath)]
}

private func resolveFrozenProblemRequestIDSchema(
  from problemSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireObject(problemSchema["properties"])
  return try resolveFrozenRequestIDSchema(from: properties["request_id"], registry: registry)
}

private func resolveFrozenRequestIDSchema(
  from referenceValue: Any?,
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let referenceObject = try requireObject(referenceValue)
  guard Set(referenceObject.keys) == ["$ref"],
    let reference = referenceObject["$ref"] as? String,
    reference == requestIDSchemaID,
    let resolved = registry[reference],
    resolved["$id"] as? String == reference
  else {
    throw ContractAssetTestError.invalidAsset
  }
  try requireFrozenRequestIDEvaluatorSurface(resolved)
  return resolved
}

private func requireFrozenRequestIDEvaluatorSurface(_ schema: [String: Any]) throws {
  guard
    Set(schema.keys)
      == ["$schema", "$id", "title", "description", "type", "minLength", "maxLength", "pattern"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == requestIDSchemaID,
    schema["title"] as? String == "Hezo Link request ID V1",
    try requireString(schema["description"]).isEmpty == false,
    schema["type"] as? String == "string",
    integerValue(schema["minLength"]) == 1,
    integerValue(schema["maxLength"]) == 128,
    schema["pattern"] as? String == requestIDPattern
  else {
    throw ContractAssetTestError.invalidAsset
  }
}

private func requireFrozenProblemEvaluatorSurface(
  _ schema: [String: Any],
  registry: [String: [String: Any]]
) throws {
  let expectedFields: Set<String> = [
    "type", "title", "status", "code", "detail", "request_id", "retryable",
  ]
  guard schema["$id"] as? String == "urn:hezo-link:contract:problem:v1",
    schema["type"] as? String == "object",
    try requireBool(schema["additionalProperties"]) == false,
    Set(try requireStringArray(schema["required"])) == expectedFields
  else {
    throw ContractAssetTestError.invalidAsset
  }
  let properties = try requireObject(schema["properties"])
  guard Set(properties.keys) == expectedFields.union(["retry_after_seconds"]) else {
    throw ContractAssetTestError.invalidAsset
  }
  _ = try resolveFrozenProblemRequestIDSchema(from: schema, registry: registry)
}

private func problemSchemaFailures(
  in object: [String: Any],
  schema: [String: Any],
  registry: [String: [String: Any]]
) throws -> Set<String> {
  try requireFrozenProblemEvaluatorSurface(schema, registry: registry)
  return problemSchemaFailures(in: object)
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
    failures.insert("pattern")
  }
  if string.unicodeScalars.count > 128 {
    failures.insert("maxLength")
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
