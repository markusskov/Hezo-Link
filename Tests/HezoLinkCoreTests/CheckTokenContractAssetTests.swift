import CoreFoundation
import CryptoKit
import Foundation
import Testing

@testable import HezoLinkCore

struct CheckTokenContractAssetTests {
  @Test func schemaAndOpenAPIFreezeTheStandaloneCheckTokenSurface() throws {
    let openAPI = try loadCheckTokenObject(checkTokenOpenAPIPath)
    let schema = try loadCheckTokenObject(checkTokenSchemaPath)

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

    let info = try requireCheckTokenObject(openAPI["info"])
    #expect(Set(info.keys) == ["title", "version", "description"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.9.0")
    #expect(info["description"] as? String == checkTokenOpenAPIDescription)

    let components = try requireCheckTokenObject(openAPI["components"])
    #expect(Set(components.keys) == ["schemas"])
    let schemas = try requireCheckTokenObject(components["schemas"])
    #expect(Set(schemas.keys) == checkTokenExpectedOpenAPIComponents)
    #expect(schemas.count == 13)

    let component = try requireCheckTokenObject(schemas["CheckTokenV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == checkTokenOpenAPIReference)

    let openAPIURL = checkTokenRepositoryRoot.appendingPathComponent(checkTokenOpenAPIPath)
    let referencedSchemaURL = openAPIURL.deletingLastPathComponent()
      .appendingPathComponent(checkTokenOpenAPIReference)
      .standardizedFileURL
    let schemaURL = checkTokenRepositoryRoot.appendingPathComponent(checkTokenSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
    #expect(FileManager.default.fileExists(atPath: referencedSchemaURL.path))

    try requireExactCheckTokenSchemaSurface(schema)
    #expect(CheckTokenV1.encodedCharacterCount == 43)
    #expect(CheckTokenV1.decodedByteCount == 32)
  }

  @Test func pendingUsesTheExactAbsoluteReferenceAndOnlyPendingConsumesIt() throws {
    let pendingSchema = try loadCheckTokenObject(checkTokenPendingSchemaPath)
    let checkTokenSchema = try loadCheckTokenObject(checkTokenSchemaPath)
    let registry = [checkTokenSchemaID: checkTokenSchema]

    let resolved = try resolveFrozenPendingCheckToken(
      from: pendingSchema,
      registry: registry
    )
    #expect(resolved["$id"] as? String == checkTokenSchemaID)

    var unknownReference = pendingSchema
    var unknownProperties = try requireCheckTokenObject(unknownReference["properties"])
    unknownProperties["check_token"] = ["$ref": "urn:hezo-link:contract:unknown:v1"]
    unknownReference["properties"] = unknownProperties
    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(from: unknownReference, registry: registry)
    }

    var relativeReference = pendingSchema
    var relativeProperties = try requireCheckTokenObject(relativeReference["properties"])
    relativeProperties["check_token"] = ["$ref": "./check-token-v1.schema.json"]
    relativeReference["properties"] = relativeProperties
    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(from: relativeReference, registry: registry)
    }

    var inlinedReference = pendingSchema
    var inlinedProperties = try requireCheckTokenObject(inlinedReference["properties"])
    inlinedProperties["check_token"] = checkTokenSchema
    inlinedReference["properties"] = inlinedProperties
    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(from: inlinedReference, registry: registry)
    }

    var siblingReference = pendingSchema
    var siblingProperties = try requireCheckTokenObject(siblingReference["properties"])
    siblingProperties["check_token"] = [
      "$ref": checkTokenSchemaID,
      "description": "Unauthorized local widening.",
    ]
    siblingReference["properties"] = siblingProperties
    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(from: siblingReference, registry: registry)
    }

    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(from: pendingSchema, registry: [:])
    }

    var mismatchedRegistry = registry
    var mismatchedSchema = checkTokenSchema
    mismatchedSchema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    mismatchedRegistry[checkTokenSchemaID] = mismatchedSchema
    #expect(throws: CheckTokenContractAssetTestError.self) {
      _ = try resolveFrozenPendingCheckToken(
        from: pendingSchema,
        registry: mismatchedRegistry
      )
    }

    #expect(
      try checkTokenReferenceLocationsOnDisk()
        == [
          "pending-check-response-v1.schema.json#/properties/check_token/$ref"
        ]
    )
  }

  @Test func manifestPinsTheExactTwelveCaseMapAndHiddenAwareDiskInventory() throws {
    let manifest = try loadCheckTokenObject(checkTokenManifestPath)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(checkTokenIntegerValue(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "check-token-v1")
    #expect(manifest["contract_schema"] as? String == checkTokenManifestSchemaReference)
    #expect(
      checkTokenSHA256(try loadCheckTokenData(checkTokenManifestPath))
        == standaloneManifestSHA256
    )

    let cases = try requireCheckTokenObjectArray(manifest["cases"])
    #expect(cases.count == checkTokenFixtureExpectations.count)
    #expect(cases.count == 12)

    for (fixtureCase, expectation) in zip(cases, checkTokenFixtureExpectations) {
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
          try requireCheckTokenStringArray(fixtureCase["expected_failure_keywords"])
            == expectation.failureKeywords
        )
      }
    }

    let ids = try cases.map { try requireCheckTokenString($0["id"]) }
    let paths = try cases.map { try requireCheckTokenString($0["path"]) }
    #expect(ids == checkTokenFixtureExpectations.map(\.id))
    #expect(Set(ids).count == ids.count)
    #expect(paths == checkTokenFixtureExpectations.map(\.path))
    #expect(Set(paths).count == paths.count)

    let fixtureRoot = checkTokenRepositoryRoot.appendingPathComponent(checkTokenFixtureRoot)
      .standardizedFileURL
    #expect(
      try checkTokenRegularFilePathsOnDisk(relativeTo: fixtureRoot)
        == Set(paths).union(["manifest.json"])
    )

    let manifestURL = checkTokenRepositoryRoot.appendingPathComponent(checkTokenManifestPath)
    let referencedSchemaURL = manifestURL.deletingLastPathComponent()
      .appendingPathComponent(checkTokenManifestSchemaReference)
      .standardizedFileURL
    let schemaURL = checkTokenRepositoryRoot.appendingPathComponent(checkTokenSchemaPath)
      .standardizedFileURL
    #expect(referencedSchemaURL == schemaURL)
  }

  @Test func everyFixturePinsItsRawScalarBytesPurposeAndExactKeywordSet() throws {
    let schema = try loadCheckTokenObject(checkTokenSchemaPath)
    try requireExactCheckTokenSchemaSurface(schema)

    for expectation in checkTokenFixtureExpectations {
      let relativePath = "\(checkTokenFixtureRoot)/\(expectation.path)"
      let data = try loadCheckTokenData(relativePath)
      #expect(
        data == Data(expectation.rawJSON.utf8),
        "CheckToken V1 raw fixture bytes drifted: \(expectation.id)"
      )
      #expect(
        checkTokenSHA256(data) == expectation.sha256,
        "CheckToken V1 raw fixture digest drifted: \(expectation.id)"
      )

      let value = try checkTokenJSONValue(from: data)
      #expect(
        expectation.payload.matches(value),
        "CheckToken V1 fixture payload drifted: \(expectation.id)"
      )
      #expect(
        checkTokenSchemaFailures(in: value) == Set(expectation.failureKeywords),
        "CheckToken V1 schema keyword set drifted: \(expectation.id)"
      )
    }
  }

  @Test func independentEvaluatorRejectsAnyWidenedSchemaSurface() throws {
    let schema = try loadCheckTokenObject(checkTokenSchemaPath)
    try requireExactCheckTokenSchemaSurface(schema)

    for mutation in CheckTokenSchemaMutation.allCases {
      var mutated = schema
      mutation.apply(to: &mutated)
      #expect(throws: CheckTokenContractAssetTestError.self) {
        try requireExactCheckTokenSchemaSurface(mutated)
      }
    }
  }

  @Test func validFixturesRoundTripThroughSwiftWithoutWireDrift() throws {
    var validCount = 0

    for expectation in checkTokenFixtureExpectations where expectation.expectedValid {
      validCount += 1
      let relativePath = "\(checkTokenFixtureRoot)/\(expectation.path)"
      let expectedString = try expectation.payload.requireString()
      let decoded = try HezoJSON.makeResponseDecoder().decode(
        CheckTokenV1.self,
        from: loadCheckTokenData(relativePath)
      )
      let direct = try CheckTokenV1(validating: expectedString)
      let encoded = try HezoJSON.makeEncoder().encode(decoded)

      #expect(decoded == direct)
      #expect(encoded == Data(expectation.rawJSON.dropLast().utf8))
      #expect(try checkTokenJSONValue(from: encoded) as? String == expectedString)
    }

    #expect(validCount == 2)
  }

  @Test func invalidFixturesFailSwiftValidationWithoutEchoingRejectedStrings() throws {
    var invalidCount = 0

    for expectation in checkTokenFixtureExpectations where expectation.expectedValid == false {
      invalidCount += 1
      let relativePath = "\(checkTokenFixtureRoot)/\(expectation.path)"
      let data = try loadCheckTokenData(relativePath)

      do {
        _ = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: data)
        Issue.record("A declared invalid CheckToken V1 fixture was accepted: \(expectation.id)")
      } catch let error as DecodingError {
        if case .dataCorrupted(let context) = error {
          #expect(context.debugDescription == "Invalid V1 check token.")
          #expect(context.codingPath.isEmpty)
        } else {
          Issue.record(
            "CheckToken V1 decoding used a non-data-corrupted error: \(expectation.id)"
          )
        }
        let renderings = checkTokenErrorRenderings(error)
        #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 256 })
        if case .string(let rejectedCandidate) = expectation.payload {
          #expect(renderings.allSatisfy { $0.contains(rejectedCandidate) == false })
        }
      } catch {
        Issue.record("CheckToken V1 decoding used an unexpected error category: \(expectation.id)")
      }

      guard case .string(let candidate) = expectation.payload else {
        continue
      }
      #expect(throws: CheckTokenContractError.invalidFormat) {
        try CheckTokenV1(validating: candidate)
      }
    }

    #expect(invalidCount == 10)

    let privateCandidate = "PRIVATE_CHECK_TOKEN_FIXTURE_CANARY/67A9"
    let privateData = try JSONEncoder().encode(privateCandidate)
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: privateData)
      Issue.record("A private invalid CheckToken V1 canary was accepted.")
    } catch let error as DecodingError {
      #expect(
        checkTokenErrorRenderings(error).allSatisfy { $0.contains(privateCandidate) == false })
    } catch {
      Issue.record("Private CheckToken V1 canary decoding used an unexpected error category.")
    }
  }

  @Test func SwiftDescriptionsDebugReflectionAndErrorsStayRedacted() throws {
    let candidate = checkTokenAlternating
    let value = try CheckTokenV1(validating: candidate)
    let mirrorChildren = Array(value.customMirror.children)
    let valueRenderings =
      [
        value.description,
        value.debugDescription,
        String(describing: value),
        String(reflecting: value),
      ] + mirrorChildren.map { String(describing: $0.value) }

    #expect(valueRenderings.allSatisfy { $0.contains(candidate) == false })
    #expect(value.description == "<redacted-check-token>")
    #expect(value.debugDescription == value.description)
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(mirrorChildren.first?.value as? String == "<redacted-check-token>")

    let error = CheckTokenContractError.invalidFormat
    let renderings = checkTokenErrorRenderings(error)
    #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
    #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    #expect(error.debugDescription == error.description)
    #expect(error.errorDescription == error.description)
    #expect(Mirror(reflecting: error).children.isEmpty)
  }

  @Test func allFortySevenPendingFixturesAndManifestRemainByteIdentical() throws {
    let pendingFixtureRoot =
      checkTokenRepositoryRoot
      .appendingPathComponent(checkTokenPendingFixtureRoot)
      .standardizedFileURL
    let onDisk = try checkTokenRegularFilePathsOnDisk(relativeTo: pendingFixtureRoot)

    #expect(pendingCheckTokenAssetSHA256ByPath.count == 48)
    #expect(pendingCheckTokenAssetSHA256ByPath.keys.filter { $0 != "manifest.json" }.count == 47)
    #expect(onDisk == Set(pendingCheckTokenAssetSHA256ByPath.keys))

    for (path, expectedDigest) in pendingCheckTokenAssetSHA256ByPath {
      let data = try loadCheckTokenData("\(checkTokenPendingFixtureRoot)/\(path)")
      #expect(
        checkTokenSHA256(data) == expectedDigest,
        "Pending Check Response V1 frozen bytes drifted: \(path)"
      )
    }

    let manifest = try loadCheckTokenObject(
      "\(checkTokenPendingFixtureRoot)/manifest.json"
    )
    #expect(try requireCheckTokenObjectArray(manifest["cases"]).count == 47)
  }

  @Test func documentationKeepsSyntaxPurposeAndNonclaimsExplicit() throws {
    let readme = try requireCheckTokenUTF8("packages/contracts/README.md")
    #expect(readme.contains(checkTokenREADMEGrammarSentence))
    #expect(readme.contains(checkTokenREADMEPurposeSentence))
    #expect(readme.contains(checkTokenREADMENonclaimsSentence))
    #expect(readme.contains(checkTokenExplicitExclusionsSentence))

    let APIContracts = try requireCheckTokenUTF8("docs/06-api-contracts.md")
    #expect(APIContracts.contains(checkTokenAPIPurposeSentence))
    #expect(APIContracts.contains(checkTokenAPINonclaimsSentence))
    #expect(APIContracts.contains(checkTokenAPINoninterchangeabilitySentence))

    let schema = try loadCheckTokenObject(checkTokenSchemaPath)
    #expect(schema["description"] as? String == checkTokenSchemaDescription)

    let openAPI = try loadCheckTokenObject(checkTokenOpenAPIPath)
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)
  }
}

private enum CheckTokenContractAssetTestError: Error {
  case invalidAsset
  case unreadableAsset
}

private struct CheckTokenFixtureExpectation: Sendable {
  let id: String
  let path: String
  let rawJSON: String
  let sha256: String
  let payload: CheckTokenFixturePayload
  let expectedValid: Bool
  let failureKeywords: [String]
}

private enum CheckTokenFixturePayload: Sendable {
  case string(String)
  case null
  case integer(Int64)

  func matches(_ value: Any) -> Bool {
    switch self {
    case .string(let expected):
      value as? String == expected
    case .null:
      value is NSNull
    case .integer(let expected):
      checkTokenIntegerValue(value) == expected
    }
  }

  func requireString() throws -> String {
    guard case .string(let value) = self else {
      throw CheckTokenContractAssetTestError.invalidAsset
    }
    return value
  }
}

private enum CheckTokenSchemaMutation: CaseIterable {
  case missingMinimum
  case widenedMaximum
  case relaxedPattern
  case nonStringType
  case mismatchedIdentifier
  case changedDescription

  func apply(to schema: inout [String: Any]) {
    switch self {
    case .missingMinimum:
      schema.removeValue(forKey: "minLength")
    case .widenedMaximum:
      schema["maxLength"] = 44
    case .relaxedPattern:
      schema["pattern"] = "^[A-Za-z0-9_-]{43}$"
    case .nonStringType:
      schema["type"] = ["string", "null"]
    case .mismatchedIdentifier:
      schema["$id"] = "urn:hezo-link:contract:mismatched:v1"
    case .changedDescription:
      schema["description"] = "Widened contract claim."
    }
  }
}

private let checkTokenRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let checkTokenOpenAPIPath = "packages/contracts/openapi-components.json"
private let checkTokenSchemaPath = "packages/contracts/schemas/check-token-v1.schema.json"
private let checkTokenPendingSchemaPath =
  "packages/contracts/schemas/pending-check-response-v1.schema.json"
private let checkTokenFixtureRoot = "packages/contracts/fixtures/check-token-v1"
private let checkTokenManifestPath = "\(checkTokenFixtureRoot)/manifest.json"
private let checkTokenPendingFixtureRoot =
  "packages/contracts/fixtures/pending-check-response-v1"
private let checkTokenManifestSchemaReference = "../../schemas/check-token-v1.schema.json"
private let checkTokenOpenAPIReference = "./schemas/check-token-v1.schema.json"
private let checkTokenSchemaID = "urn:hezo-link:contract:check-token:v1"
private let checkTokenPattern = "^[A-Za-z0-9_-]{42}[AEIMQUYcgkosw048]$"
private let checkTokenAllZero = String(repeating: "A", count: 43)
private let checkTokenAlternating = "-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_8"
private let standaloneManifestSHA256 =
  "9e2cfa9888cb7d85df6dd68786a6b368f839196f281e67fb11e851e5412d08a2"
private let checkTokenSchemaDescription =
  "Strict standalone canonical unpadded base64url shape for one Check Token V1 representing exactly 32 bytes. This schema validates syntax only and proves no entropy, randomness, uniqueness, secrecy, issuance, ownership, authority, purpose, lifetime, retention, logging permission, storage, replay resistance, or relationship to another token."
private let checkTokenOpenAPIDescription =
  "Reusable offline check-input, request-ID, check-token, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
private let checkTokenREADMEGrammarSentence =
  "`CheckTokenV1` is the canonical unpadded base64url encoding of exactly 32 bytes: exactly 43 ASCII characters, with letters, digits, `_`, or `-` in the first 42 positions and one of `AEIMQUYcgkosw048` in the final position so the unused base64 bits are zero. A conforming semantic decoder must decode exactly 32 bytes and re-encode to the identical text. The two valid fixtures are intentionally obvious, low-entropy public controls and are forbidden for operational use."
private let checkTokenREADMEPurposeSentence =
  "The current executable contract assigns this standalone scalar only to `PendingCheckResponseV1.check_token`. Sharing this syntax does not authorize its use by the proposed completed-check or report envelopes, and it does not define any endpoint or runtime. A `CheckTokenV1` is not interchangeable with an MPD presence or withdrawal token, a request ID, an idempotency key, an integrity capability, or any other token or identifier. Equal bytes establish no identity, continuity, or relationship across purposes."
private let checkTokenREADMENonclaimsSentence =
  "Acceptance proves syntax only. It proves no producer entropy, randomness, uniqueness, secrecy, issuance, authenticity, ownership, authority, purpose, lifetime, expiry, retention or logging permission, digesting, storage, replay resistance, report linkage, polling behavior, authentication, or network behavior."
private let checkTokenAPIPurposeSentence =
  "`CheckTokenV1` is currently assigned only to `PendingCheckResponseV1.check_token`. This extraction shares its syntax without approving the proposed completed-check or report envelopes as additional consumers and without defining an endpoint or runtime behavior."
private let checkTokenAPINonclaimsSentence =
  "This is a syntax contract and a purpose boundary, not proof of producer behavior. Conformance proves no entropy, randomness, uniqueness, secrecy, issuance, authenticity, ownership, authority, lifetime, expiry, retention or logging permission, digesting, storage, replay resistance, report linkage, polling behavior, authentication, or network behavior. It does not authorize accepting a token at any endpoint."
private let checkTokenAPINoninterchangeabilitySentence =
  "A `CheckTokenV1` is not interchangeable with an MPD presence or withdrawal token, request ID, idempotency key, report receipt, deletion capability, integrity capability, or any other token or identifier. Matching bytes establish no identity, continuity, linkage, or authority across purposes."
private let checkTokenExplicitExclusionsSentence =
  "These artifacts contain only request, request-ID, check-token, problem, check-response-status, pending-check-response, verdict, verdict-reason, and standalone verdict-supporting shapes with reserved or synthetic examples. They define no endpoint, deployment, HTTP or polling behavior, token or request-ID issuance or entropy proof, authority, lifetime, retention or logging permission, storage, network or other I/O behavior, cross-plane identity, complete check-response envelope, automatic block eligibility, or unrelated product data. All fixture hosts use the reserved `.test` namespace and are intended for offline validation only."

private let checkTokenExpectedOpenAPIComponents: Set<String> = [
  "CheckRequestV1", "RequestIDV1", "CheckTokenV1", "ProblemV1", "VerdictReasonV1",
  "VerdictLabelV1", "RecommendedActionV1", "ConfidenceCategoryV1", "EvaluatedScopeV1",
  "VerdictReasonsV1", "CheckResponseStatusV1", "PendingCheckResponseV1", "VerdictV1",
]

private let checkTokenFixtureExpectations: [CheckTokenFixtureExpectation] = [
  CheckTokenFixtureExpectation(
    id: "valid-all-zero",
    path: "valid/all-zero.json",
    rawJSON: "\"\(checkTokenAllZero)\"\n",
    sha256: "bb8009bdc6a93da1574fdcc59da340f090236d308d5d5d20624e2518c56769f3",
    payload: .string(checkTokenAllZero),
    expectedValid: true,
    failureKeywords: []
  ),
  CheckTokenFixtureExpectation(
    id: "valid-alternating",
    path: "valid/alternating.json",
    rawJSON: "\"\(checkTokenAlternating)\"\n",
    sha256: "bb33d303b63db1d676d927b3e538836b9ca566cc3c8b16a984e180c91d560c90",
    payload: .string(checkTokenAlternating),
    expectedValid: true,
    failureKeywords: []
  ),
  CheckTokenFixtureExpectation(
    id: "reject-short",
    path: "invalid/short.json",
    rawJSON: "\"\(String(repeating: "A", count: 42))\"\n",
    sha256: "0e517f90ad27423cd94edbc01012bf87b38eef87de8b8209ff80a70c195aa347",
    payload: .string(String(repeating: "A", count: 42)),
    expectedValid: false,
    failureKeywords: ["minLength", "pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-long",
    path: "invalid/long.json",
    rawJSON: "\"\(String(repeating: "A", count: 44))\"\n",
    sha256: "051b6ff8ed660ef7774e7ce1ffc18b23ab44462ad8757810bda1dbd96ee3b2ba",
    payload: .string(String(repeating: "A", count: 44)),
    expectedValid: false,
    failureKeywords: ["maxLength", "pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-invalid-character",
    path: "invalid/invalid-character.json",
    rawJSON: "\"+\(String(repeating: "A", count: 42))\"\n",
    sha256: "b6bd1c836e13f604bffcf7e10255be436e77c2733924adbb7114339f896c8df1",
    payload: .string("+" + String(repeating: "A", count: 42)),
    expectedValid: false,
    failureKeywords: ["pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-padded",
    path: "invalid/padded.json",
    rawJSON: "\"\(String(repeating: "A", count: 43))=\"\n",
    sha256: "1b6149b8d0e5c3c2aa5ca677672ec55980250f7997a6ac8162cecd377b579327",
    payload: .string(String(repeating: "A", count: 43) + "="),
    expectedValid: false,
    failureKeywords: ["maxLength", "pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-noncanonical-final-character",
    path: "invalid/noncanonical-final-character.json",
    rawJSON: "\"\(String(repeating: "A", count: 42))B\"\n",
    sha256: "1863c41749ecc042a91a5686dea39a5113a8cd6377364742e29403f47d07c711",
    payload: .string(String(repeating: "A", count: 42) + "B"),
    expectedValid: false,
    failureKeywords: ["pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-whitespace",
    path: "invalid/whitespace.json",
    rawJSON: "\"\(String(repeating: "A", count: 42)) \"\n",
    sha256: "3fd96ab5471ce06b351070b9a1c0163bf1996450124b26cdceecebcbef5c9dc2",
    payload: .string(String(repeating: "A", count: 42) + " "),
    expectedValid: false,
    failureKeywords: ["pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-control",
    path: "invalid/control.json",
    rawJSON: "\"\(String(repeating: "A", count: 42))\\u0000\"\n",
    sha256: "17c83c32569d29fd3db6337d7aef8407df1c2090a2b16e16c31668c7e0352783",
    payload: .string(String(repeating: "A", count: 42) + "\u{0000}"),
    expectedValid: false,
    failureKeywords: ["pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-non-ascii",
    path: "invalid/non-ascii.json",
    rawJSON: "\"\(String(repeating: "A", count: 42))é\"\n",
    sha256: "91792f43ae1a14a81f4617561040fbba94c97eb12705e2a390ccdbcd7c2145bf",
    payload: .string(String(repeating: "A", count: 42) + "é"),
    expectedValid: false,
    failureKeywords: ["pattern"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-null",
    path: "invalid/null.json",
    rawJSON: "null\n",
    sha256: "38e0b9de817f645c4bec37c0d4a3e58baecccb040f5718dc069a72c7385a0bed",
    payload: .null,
    expectedValid: false,
    failureKeywords: ["type"]
  ),
  CheckTokenFixtureExpectation(
    id: "reject-wrong-type",
    path: "invalid/wrong-type.json",
    rawJSON: "32\n",
    sha256: "2115cdb6bfcfb008eb2bab2bb79347cb064a48e4e7c4115ccbe4469c787bb6c4",
    payload: .integer(32),
    expectedValid: false,
    failureKeywords: ["type"]
  ),
]

private let pendingCheckTokenAssetSHA256ByPath: [String: String] = [
  "invalid/check-token-invalid-character.json":
    "bd243a921355bffe0bbbbb01f58f64d75cdc905257c264938b745db9315d8a35",
  "invalid/check-token-long.json":
    "9da29624e91a3363189f4a4e1404d725c4ee9b8b6e57c000b08325404c8afc64",
  "invalid/check-token-noncanonical-final-character.json":
    "8e7cbb8f7e1fcdd6f5226eb0f5b056d3c77b108ace25656915b6391b36f27ebf",
  "invalid/check-token-null.json":
    "8675fd646538ca2e44736acddabe75e0d4bbb63f127fd8adb7b88b9d131788ec",
  "invalid/check-token-short.json":
    "c727695440e558bf5f852524323f49711980d71c60b005bbf0c10d19ca4dfca0",
  "invalid/check-token-wrong-type.json":
    "dfd28369472a857d4b038b07eac1c0200ff60d0f39fdcc1e1927c87321c26702",
  "invalid/expires-at-fractional.json":
    "87e1dde4635b0f3847d9f239a53c6e225a4410bceed42a21e0b89155df4d5f58",
  "invalid/expires-at-impossible.json":
    "9f6a015a4e04d80927125d6059342d69c04279fb99c9c5d238a71c782f1b2799",
  "invalid/expires-at-lowercase-z.json":
    "dedefe4a847c46e7acca64c199734e7fc02aa476f51b02bffd37e25dc105857f",
  "invalid/expires-at-null.json":
    "9f5a3de1e105da727b1d470872e303ba90656dde81f1041c6f940fc302b46ef4",
  "invalid/expires-at-offset.json":
    "1c9c17ac5728310dac0aac9c1421c0639b341b5c659fbdb113375a53d177dd3d",
  "invalid/expires-at-wrong-type.json":
    "819ae30de1469e42e7b0e25e2ca0c364d6e7a9ef242f4b249dcdccd308d82561",
  "invalid/expires-at-year-zero.json":
    "c67bedc227ae76d9bff04f59c96729d0dacac3a4945d00d13b951b947a162948",
  "invalid/forbidden-analysis.json":
    "ed45546310dc7962bb5c8c887ebe9d78740395fb7d06fc92174d4c3242f73fdc",
  "invalid/forbidden-block-eligible.json":
    "01e21b1f40655462b27e714d221fc0d5cb068fa6b5f1d7f6a59002fa279468a8",
  "invalid/forbidden-evaluated-at.json":
    "7ad37bd61c8434a868de8ffadb4fadd020aebb5ad13344bb1be6ae9ed5afc45a",
  "invalid/forbidden-source-notices.json":
    "fd46c094713fdb51fa6d374c4b3e9caa0c6493b1d86189bdb466eedbc99440a7",
  "invalid/forbidden-target.json":
    "6eec1accf742efa6a894c88847c3984cdf97afa4352f04e4299536d0a8291912",
  "invalid/forbidden-valid-until.json":
    "154874c050800ca9b3b169630ee66174572fe4a2ab34b7e0876ea82f12ff2d64",
  "invalid/forbidden-verdict.json":
    "2ac45acc31498ab0881468412d6f1e4e7c18ca65a332c5b401358a50eac72dd1",
  "invalid/forbidden-versions.json":
    "0a8d8819cfc2d61db34bd2f8d19002d1c1c4cfd5b5781df93dcd45d709c6d5b4",
  "invalid/missing-check-token.json":
    "f06693dd9531f2ae0b7292847fd7a1b4b0fbb33e10b2d3e8a284b8c101f6978e",
  "invalid/missing-expires-at.json":
    "c24310bed4301b6894b719d9d13a6c9187adf5fdb36802e8819d64f81f403442",
  "invalid/missing-request-id.json":
    "27e8ec8dd3d9fd7ece3be2ca72d687a82104274553a38cb9be300bea1799319e",
  "invalid/missing-retry-after-ms.json":
    "3643b71be99f8d5df72b69ea03d5c3d99a332a9e2f33924c752ca4f0c187fe50",
  "invalid/missing-schema-version.json":
    "9e8ccf93963d3fc1c8c2bdafe4588080378e6660c149648faed55895077765ed",
  "invalid/missing-status.json": "fce843f7bafc3ab2c75b4071446dd282be5a5ed14a90a9c3e038a8b5dbffeb3a",
  "invalid/request-id-empty.json":
    "a205b3cbd0467f26fb81a95afdb25133397c9892ba1d9c4093063e59c1227713",
  "invalid/request-id-invalid-character.json":
    "5190dd01729b69169202c0de0261e8beab45394d3c90f19b49e316de24921597",
  "invalid/request-id-null.json":
    "4f9dd27fbe05b7fabeae7d2c2678b9af00f2804d59f35c0dd8246751a6e8d173",
  "invalid/request-id-oversized.json":
    "657dfcc7524e8f03d1ea6efbd035e62a4a03ac36646c1e7f221269f4646faae3",
  "invalid/request-id-wrong-type.json":
    "15b353ba2533abb11ec40d620cdabecb3008f5da645d8d7e4788f98bce292d92",
  "invalid/retry-after-ms-above-maximum.json":
    "967f79d150915aeb550d4fee5638a6eac31eadff5ea8e431826974dac55fd32e",
  "invalid/retry-after-ms-fractional.json":
    "1b3a4e6beaf74ec3af3fb4c49c3fde4fb8bcf0f64701546c91682601c9c91ab2",
  "invalid/retry-after-ms-null.json":
    "0d5a6267d25d4ce4db9bb376a6a71226c6d95c17f142e73816a7b64494ccd0f0",
  "invalid/retry-after-ms-wrong-type.json":
    "af48fa16b9f621d087041c3b6d23ab8cb37af2e9df779bf05984b7e6805ba27b",
  "invalid/retry-after-ms-zero.json":
    "fb63789a79a3504f4e3f36f3e4aa5a5f9df5899ff010363f92047cbd7e4ec632",
  "invalid/schema-version-mismatch.json":
    "9f398accf044e89ff2087ffa0da9c72c7351100daeca93cad8a0ad66843fdbfc",
  "invalid/status-complete.json":
    "aba1c7a9402c4e9a2810aa248de4d7da570dd7494f04a41a7c165a381dd1e31a",
  "invalid/status-invalid.json": "d37d6ffb79278bd9c1b61efe2c271139b7d901dbbaf99dcf3f8323ea701cbb4e",
  "invalid/unknown-future-field.json":
    "aef7829535ea5ab67f3bed22d14d512070b759628f333c2a91baddaeae365c9e",
  "invalid/wrong-top-level-type.json":
    "37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570",
  "manifest.json": "d0dfd7822e44b3b7aff342e6e76cf93bfa5f514c4c56a27296e5fb33bb6c4c3f",
  "valid/canonical-token-controls.json":
    "317c8aed115dbfcfc4a95a283cc9efd57ac348365b47ff0d3eeeb3a0173f2bd2",
  "valid/request-id-upper-boundary.json":
    "f274f5b359c5c377b9987ed70339d4ec7145de364107ff74a7c7898108a7e502",
  "valid/retry-after-ms-lower-boundary.json":
    "30e0dba9b4b6bf88cfffd2eea44d2dcb9be6b54f977fe3c0c4ec5c1bb2f5bf39",
  "valid/retry-after-ms-upper-boundary.json":
    "d05fd79c4400670095529c68fe8c0d8d8a6660141a487b1e657b4de51172b8e6",
  "valid/standard.json": "31dfc9a4cb79a2a39cfc658ba7b92f69730057bd8127a24b621adf1410068510",
]

private func requireExactCheckTokenSchemaSurface(_ schema: [String: Any]) throws {
  guard
    Set(schema.keys)
      == ["$schema", "$id", "title", "description", "type", "minLength", "maxLength", "pattern"],
    schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema",
    schema["$id"] as? String == checkTokenSchemaID,
    schema["title"] as? String == "Hezo Link check token V1",
    schema["description"] as? String == checkTokenSchemaDescription,
    schema["type"] as? String == "string",
    checkTokenIntegerValue(schema["minLength"]) == 43,
    checkTokenIntegerValue(schema["maxLength"]) == 43,
    schema["pattern"] as? String == checkTokenPattern
  else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
}

private func resolveFrozenPendingCheckToken(
  from pendingSchema: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  let properties = try requireCheckTokenObject(pendingSchema["properties"])
  let referenceObject = try requireCheckTokenObject(properties["check_token"])
  guard Set(referenceObject.keys) == ["$ref"],
    let reference = referenceObject["$ref"] as? String,
    reference == checkTokenSchemaID,
    let resolved = registry[reference],
    resolved["$id"] as? String == reference
  else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  try requireExactCheckTokenSchemaSurface(resolved)
  return resolved
}

// This intentionally evaluates only the frozen CheckToken V1 scalar grammar. It is independent
// of JSON Schema tooling and is not a general Draft 2020-12 evaluator.
private func checkTokenSchemaFailures(in value: Any) -> Set<String> {
  guard let string = value as? String else {
    return ["type"]
  }

  var failures = Set<String>()
  if string.unicodeScalars.count < 43 {
    failures.insert("minLength")
  }
  if string.unicodeScalars.count > 43 {
    failures.insert("maxLength")
  }
  if isCanonicalCheckTokenContractString(string) == false {
    failures.insert("pattern")
  }
  return failures
}

private func isCanonicalCheckTokenContractString(_ value: String) -> Bool {
  let bytes = Array(value.utf8)
  guard bytes.count == 43, bytes.dropLast().allSatisfy(isBase64URLContractByte),
    let finalByte = bytes.last
  else {
    return false
  }
  return [
    0x41, 0x45, 0x49, 0x4D, 0x51, 0x55, 0x59, 0x63,
    0x67, 0x6B, 0x6F, 0x73, 0x77, 0x30, 0x34, 0x38,
  ].contains(finalByte)
}

private func isBase64URLContractByte(_ byte: UInt8) -> Bool {
  (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
    || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
}

private func checkTokenReferenceLocationsOnDisk() throws -> [String] {
  let schemaRoot =
    checkTokenRepositoryRoot
    .appendingPathComponent("packages/contracts/schemas")
    .standardizedFileURL
  let schemaPaths = try checkTokenRegularFilePathsOnDisk(relativeTo: schemaRoot)
    .filter { $0.hasSuffix(".schema.json") }
    .sorted()

  return try schemaPaths.flatMap { relativePath in
    let schema = try loadCheckTokenObject("packages/contracts/schemas/\(relativePath)")
    return checkTokenReferencePointers(in: schema).map { pointer in
      "\(relativePath)#\(pointer)"
    }
  }
}

private func checkTokenReferencePointers(
  in value: Any,
  pointer: String = ""
) -> [String] {
  if let object = value as? [String: Any] {
    var pointers = [String]()
    for key in object.keys.sorted() {
      guard let child = object[key] else {
        continue
      }
      let childPointer = "\(pointer)/\(checkTokenJSONPointerSegment(key))"
      if key == "$ref", child as? String == checkTokenSchemaID {
        pointers.append(childPointer)
      }
      pointers.append(
        contentsOf: checkTokenReferencePointers(in: child, pointer: childPointer)
      )
    }
    return pointers
  }
  if let array = value as? [Any] {
    return array.enumerated().flatMap { index, child in
      checkTokenReferencePointers(in: child, pointer: "\(pointer)/\(index)")
    }
  }
  return []
}

private func checkTokenJSONPointerSegment(_ segment: String) -> String {
  segment.replacingOccurrences(of: "~", with: "~0")
    .replacingOccurrences(of: "/", with: "~1")
}

private func loadCheckTokenObject(_ relativePath: String) throws -> [String: Any] {
  try requireCheckTokenObject(checkTokenJSONValue(from: loadCheckTokenData(relativePath)))
}

private func loadCheckTokenData(_ relativePath: String) throws -> Data {
  let url = checkTokenRepositoryRoot.appendingPathComponent(relativePath).standardizedFileURL
  guard url.path.hasPrefix(checkTokenRepositoryRoot.path + "/") else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  do {
    return try Data(contentsOf: url)
  } catch {
    throw CheckTokenContractAssetTestError.unreadableAsset
  }
}

private func requireCheckTokenUTF8(_ relativePath: String) throws -> String {
  guard let string = String(data: try loadCheckTokenData(relativePath), encoding: .utf8) else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  return string
}

private func checkTokenJSONValue(from data: Data) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  } catch {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
}

private func requireCheckTokenObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  return object
}

private func requireCheckTokenObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let objects = value as? [[String: Any]] else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  return objects
}

private func requireCheckTokenString(_ value: Any?) throws -> String {
  guard let string = value as? String else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  return string
}

private func requireCheckTokenStringArray(_ value: Any?) throws -> [String] {
  guard let strings = value as? [String] else {
    throw CheckTokenContractAssetTestError.invalidAsset
  }
  return strings
}

private func checkTokenIntegerValue(_ value: Any?) -> Int64? {
  guard let number = value as? NSNumber,
    CFGetTypeID(number) != CFBooleanGetTypeID(),
    number.doubleValue.isFinite,
    number.doubleValue.rounded(.towardZero) == number.doubleValue
  else {
    return nil
  }
  return number.int64Value
}

private func checkTokenRegularFilePathsOnDisk(relativeTo root: URL) throws -> Set<String> {
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
  else {
    throw CheckTokenContractAssetTestError.unreadableAsset
  }

  var paths = Set<String>()
  for case let fileURL as URL in enumerator {
    let values = try fileURL.resourceValues(
      forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
    )
    guard values.isSymbolicLink == false else {
      throw CheckTokenContractAssetTestError.invalidAsset
    }
    guard values.isRegularFile == true else {
      continue
    }
    guard fileURL.path.hasPrefix(root.path + "/") else {
      throw CheckTokenContractAssetTestError.invalidAsset
    }
    paths.insert(String(fileURL.path.dropFirst(root.path.count + 1)))
  }
  return paths
}

private func checkTokenSHA256(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func checkTokenErrorRenderings(_ error: any Error) -> [String] {
  let nsError = error as NSError
  return [
    String(describing: error),
    String(reflecting: error),
    error.localizedDescription,
    nsError.localizedDescription,
  ]
}
