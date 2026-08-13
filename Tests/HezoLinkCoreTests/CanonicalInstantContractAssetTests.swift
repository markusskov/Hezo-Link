import CoreFoundation
import CryptoKit
import Foundation
import HezoLinkCore
import Testing

struct CanonicalInstantContractAssetTests {
  @Test func schemaAndOpenAPIFreezeTheExactStandaloneSurface() throws {
    let schemaData = try canonicalLoadData(canonicalSchemaPath)
    let schema = try canonicalRequireObject(canonicalJSONValue(from: schemaData))

    #expect(canonicalSHA256(schemaData) == canonicalSchemaSHA256)
    #expect(
      Set(schema.keys)
        == ["$schema", "$id", "title", "description", "type", "pattern", "format"]
    )
    #expect(schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema")
    #expect(schema["$id"] as? String == canonicalSchemaID)
    #expect(schema["title"] as? String == "Hezo Link canonical instant V1")
    #expect(schema["description"] as? String == canonicalSchemaDescription)
    #expect(schema["type"] as? String == "string")
    #expect(schema["pattern"] as? String == canonicalPattern)
    #expect(schema["format"] as? String == "date-time")
    #expect(schema["minLength"] == nil)
    #expect(schema["maxLength"] == nil)

    let openAPIData = try canonicalLoadData(canonicalOpenAPIPath)
    let openAPI = try canonicalRequireObject(canonicalJSONValue(from: openAPIData))
    #expect(canonicalSHA256(openAPIData) == canonicalComponentDocumentDigest)
    #expect(Set(openAPI.keys) == ["openapi", "info", "jsonSchemaDialect", "paths", "components"])
    #expect(openAPI["openapi"] as? String == "3.1.0")
    #expect(
      openAPI["jsonSchemaDialect"] as? String
        == "https://json-schema.org/draft/2020-12/schema"
    )
    #expect((openAPI["paths"] as? [String: Any])?.isEmpty == true)
    #expect(openAPI["servers"] == nil)
    #expect(openAPI["security"] == nil)

    let info = try canonicalRequireObject(openAPI["info"])
    #expect(Set(info.keys) == ["title", "version", "description"])
    #expect(info["title"] as? String == "Hezo Link public contract components")
    #expect(info["version"] as? String == "1.10.0")
    #expect(info["description"] as? String == canonicalOpenAPIDescription)

    let components = try canonicalRequireObject(openAPI["components"])
    let schemas = try canonicalRequireObject(components["schemas"])
    #expect(Set(components.keys) == ["schemas"])
    #expect(Set(schemas.keys) == canonicalOpenAPIComponents)
    #expect(schemas.count == 14)
    let component = try canonicalRequireObject(schemas["CanonicalInstantV1"])
    #expect(Set(component.keys) == ["$ref"])
    #expect(component["$ref"] as? String == canonicalOpenAPIReference)

    let referencedURL =
      canonicalRepositoryRoot
      .appendingPathComponent(canonicalOpenAPIPath)
      .deletingLastPathComponent()
      .appendingPathComponent(canonicalOpenAPIReference)
      .standardizedFileURL
    #expect(
      referencedURL
        == canonicalRepositoryRoot.appendingPathComponent(canonicalSchemaPath).standardizedFileURL
    )
  }

  @Test func manifestPinsAllTwentySevenRawCasesKeywordsAndDiskInventory() throws {
    let manifestData = try canonicalLoadData(canonicalManifestPath)
    let manifest = try canonicalRequireObject(canonicalJSONValue(from: manifestData))
    #expect(canonicalSHA256(manifestData) == canonicalManifestSHA256)
    #expect(Set(manifest.keys) == ["schema_version", "contract", "contract_schema", "cases"])
    #expect(canonicalInteger(manifest["schema_version"]) == 1)
    #expect(manifest["contract"] as? String == "canonical-instant-v1")
    #expect(manifest["contract_schema"] as? String == canonicalManifestSchemaReference)

    let cases = try canonicalRequireObjectArray(manifest["cases"])
    #expect(cases.count == canonicalFixtureExpectations.count)
    #expect(cases.count == 27)
    #expect(Set(cases.compactMap { $0["id"] as? String }).count == 27)

    for (fixtureCase, expectation) in zip(cases, canonicalFixtureExpectations) {
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
          fixtureCase["expected_failure_keyword"] as? String == expectation.failureKeywords[0])
      } else {
        #expect(
          Set(fixtureCase.keys)
            == ["id", "path", "expected_schema_valid", "expected_failure_keywords"]
        )
        #expect(
          try canonicalRequireStringArray(fixtureCase["expected_failure_keywords"])
            == expectation.failureKeywords
        )
      }

      let data = try canonicalLoadData("\(canonicalFixtureRoot)/\(expectation.path)")
      #expect(data == Data(expectation.rawJSON.utf8), "Raw bytes drifted: \(expectation.id)")
      let value = try canonicalJSONValue(from: data)
      #expect(expectation.payload.matches(value), "Payload purpose drifted: \(expectation.id)")
      #expect(
        canonicalSchemaFailures(in: value) == Set(expectation.failureKeywords),
        "Failure keywords drifted: \(expectation.id)"
      )
    }

    let fixtureRoot = canonicalRepositoryRoot.appendingPathComponent(canonicalFixtureRoot)
    let paths = try canonicalRegularPaths(relativeTo: fixtureRoot)
    let expectedPaths = Set(canonicalFixtureExpectations.map(\.path) + ["manifest.json"])
    #expect(paths == expectedPaths)

    let referencedURL =
      canonicalRepositoryRoot
      .appendingPathComponent(canonicalManifestPath)
      .deletingLastPathComponent()
      .appendingPathComponent(canonicalManifestSchemaReference)
      .standardizedFileURL
    #expect(
      referencedURL
        == canonicalRepositoryRoot.appendingPathComponent(canonicalSchemaPath).standardizedFileURL
    )
  }

  @Test func evaluatorIndependentlyPinsGregorianCenturyAndReformSemantics() throws {
    let accepted = [
      "0001-01-01T00:00:00Z",
      "0400-02-29T00:00:00Z",
      "1582-10-04T00:00:00Z",
      "1582-10-10T00:00:00Z",
      "1582-10-15T00:00:00Z",
      "1600-02-29T00:00:00Z",
      "2000-02-29T23:59:59Z",
      "9999-12-31T23:59:59Z",
    ]
    let rejectedByCalendar = [
      "0100-02-29T00:00:00Z",
      "1500-02-29T00:00:00Z",
      "1900-02-29T00:00:00Z",
      "2001-02-29T00:00:00Z",
      "2100-02-29T00:00:00Z",
    ]

    for value in accepted {
      #expect(canonicalPatternMatches(value))
      #expect(canonicalDateTimeFormatMatches(value))
      #expect(canonicalSchemaFailures(in: value).isEmpty)
    }
    for value in rejectedByCalendar {
      #expect(canonicalPatternMatches(value))
      #expect(canonicalDateTimeFormatMatches(value) == false)
      #expect(canonicalSchemaFailures(in: value) == ["format"])
    }

    #expect(canonicalSchemaFailures(in: "0000-01-01T00:00:00Z") == ["pattern"])
    #expect(canonicalSchemaFailures(in: "2016-12-31T23:59:60Z") == ["pattern"])
    #expect(canonicalSchemaFailures(in: "2000-02-29t23:59:59z") == ["pattern"])
    #expect(canonicalSchemaFailures(in: "2000-02-29T23:59:59.1Z") == ["pattern"])
    #expect(canonicalSchemaFailures(in: "2000-03-01T00:59:59+01:00") == ["pattern"])
  }

  @Test func exactlyTwoSchemaLocationsConsumeTheAbsoluteReference() throws {
    let schemaRoot = canonicalRepositoryRoot.appendingPathComponent("packages/contracts/schemas")
    let schemaPaths = try canonicalRegularPaths(relativeTo: schemaRoot)
      .filter { $0.hasSuffix(".schema.json") }
      .sorted()
    var locations: [String] = []

    for path in schemaPaths {
      let schema = try canonicalJSONValue(
        from: canonicalLoadData("packages/contracts/schemas/\(path)")
      )
      locations.append(
        contentsOf: canonicalReferencePointers(in: schema).map { "\(path)#\($0)" }
      )
    }

    #expect(
      locations.sorted()
        == [
          "pending-check-response-v1.schema.json#/properties/expires_at/$ref",
          "verdict-reason-v1.schema.json#/properties/observed_at/$ref",
        ]
    )
  }

  @Test func bothConsumersRequireAnExactRegisteredAbsoluteReference() throws {
    let canonicalSchema = try canonicalLoadObject(canonicalSchemaPath)
    let registry = [canonicalSchemaID: canonicalSchema]
    let consumers = [
      (canonicalPendingSchemaPath, "expires_at"),
      (canonicalVerdictReasonSchemaPath, "observed_at"),
    ]

    for (path, field) in consumers {
      let consumer = try canonicalLoadObject(path)
      let properties = try canonicalRequireObject(consumer["properties"])
      let referenceObject = try canonicalRequireObject(properties[field])
      let resolved = try canonicalResolve(referenceObject, registry: registry)
      #expect(resolved["$id"] as? String == canonicalSchemaID)
      #expect(resolved["pattern"] as? String == canonicalPattern)

      #expect(throws: CanonicalAssetError.self) {
        _ = try canonicalResolve(["$ref": canonicalOpenAPIReference], registry: registry)
      }
      #expect(throws: CanonicalAssetError.self) {
        _ = try canonicalResolve(canonicalSchema, registry: registry)
      }
      #expect(throws: CanonicalAssetError.self) {
        _ = try canonicalResolve(referenceObject, registry: [:])
      }

      var mismatched = canonicalSchema
      mismatched["$id"] = "urn:hezo-link:contract:mismatched:v1"
      #expect(throws: CanonicalAssetError.self) {
        _ = try canonicalResolve(referenceObject, registry: [canonicalSchemaID: mismatched])
      }
    }
  }

  @Test func SwiftReaderRoundTripsValidFixturesAndRejectsInvalidOnesPrivately() throws {
    var validCount = 0
    var invalidCount = 0

    for expectation in canonicalFixtureExpectations {
      let data = try canonicalLoadData("\(canonicalFixtureRoot)/\(expectation.path)")
      if expectation.expectedValid {
        validCount += 1
        let expected = try expectation.payload.requireString()
        let value = try HezoJSON.makeResponseDecoder().decode(CanonicalInstantV1.self, from: data)
        let encoded = try HezoJSON.makeEncoder().encode(value)
        #expect(value == (try CanonicalInstantV1(validating: expected)))
        #expect(encoded == Data(expectation.rawJSON.dropLast().utf8))
        #expect(value.description == "<redacted-canonical-instant>")
      } else {
        invalidCount += 1
        do {
          _ = try HezoJSON.makeResponseDecoder().decode(CanonicalInstantV1.self, from: data)
          Issue.record("An invalid CanonicalInstantV1 fixture was accepted: \(expectation.id)")
        } catch let DecodingError.dataCorrupted(context) {
          #expect(context.codingPath.isEmpty)
          #expect(context.debugDescription == "Invalid V1 canonical instant.")
          #expect(context.underlyingError == nil)
          if case .string(let candidate) = expectation.payload {
            #expect(String(describing: context).contains(candidate) == false)
            #expect(String(reflecting: context).contains(candidate) == false)
          }
        } catch {
          Issue.record("CanonicalInstantV1 used an unexpected decode error: \(expectation.id)")
        }
      }
    }

    #expect(validCount == 7)
    #expect(invalidCount == 20)

    let canary = "PRIVATE_CANONICAL_INSTANT_CANARY"
    do {
      _ = try HezoJSON.makeResponseDecoder().decode(
        CanonicalInstantV1.self,
        from: try JSONEncoder().encode(canary)
      )
      Issue.record("The private CanonicalInstantV1 canary was accepted.")
    } catch {
      #expect(String(describing: error).contains(canary) == false)
      #expect(String(reflecting: error).contains(canary) == false)
    }
  }

  @Test func priorConsumerFixtureTreesRemainByteFrozen() throws {
    let pending = try canonicalTreeDigest(canonicalPendingFixtureRoot)
    let verdictReason = try canonicalTreeDigest(canonicalVerdictReasonFixtureRoot)

    #expect(pending.fileCount == 48)
    #expect(pending.digest == canonicalPendingFixtureTreeSHA256)
    #expect(verdictReason.fileCount == 23)
    #expect(verdictReason.digest == canonicalVerdictReasonFixtureTreeSHA256)
  }

  @Test func publicDocumentationKeepsThePrimitiveAndMigrationBoundaryExplicit() throws {
    let readmeData = try canonicalLoadData("packages/contracts/README.md")
    let APIData = try canonicalLoadData("docs/06-api-contracts.md")
    let readme = try #require(String(data: readmeData, encoding: .utf8))
    let API = try #require(String(data: APIData, encoding: .utf8))

    #expect(canonicalSHA256(readmeData) == canonicalReadmeSHA256)
    #expect(canonicalSHA256(APIData) == canonicalContractDocumentDigest)
    #expect(
      readme.contains(
        "The current executable contracts use this standalone scalar in exactly two places"))
    #expect(readme.contains("they do not introduce a historical reform gap"))
    #expect(readme.contains("Acceptance proves syntax and calendar validity only"))
    #expect(API.contains("does not approve another consumer or any enclosing runtime behavior"))
    #expect(API.contains("do not insert a historical calendar-reform gap"))
    #expect(API.contains("contract-conformance correction"))
    #expect(API.contains("does not read or authorize use of a clock"))
  }
}

private enum CanonicalAssetError: Error {
  case invalidAsset
  case unreadableAsset
}

private struct CanonicalFixtureExpectation {
  let id: String
  let path: String
  let rawJSON: String
  let payload: CanonicalPayload
  let expectedValid: Bool
  let failureKeywords: [String]
}

private enum CanonicalPayload {
  case string(String)
  case null
  case integer(Int64)
  case boolean(Bool)
  case object
  case array

  func matches(_ value: Any) -> Bool {
    switch self {
    case .string(let expected):
      return value as? String == expected
    case .null:
      return value is NSNull
    case .integer(let expected):
      return canonicalInteger(value) == expected
    case .boolean(let expected):
      guard let number = value as? NSNumber,
        CFGetTypeID(number) == CFBooleanGetTypeID()
      else {
        return false
      }
      return number.boolValue == expected
    case .object:
      return (value as? [String: Any])?.isEmpty == true
    case .array:
      return (value as? [Any])?.isEmpty == true
    }
  }

  func requireString() throws -> String {
    guard case .string(let value) = self else {
      throw CanonicalAssetError.invalidAsset
    }
    return value
  }
}

private let canonicalRepositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let canonicalSchemaPath = "packages/contracts/schemas/canonical-instant-v1.schema.json"
private let canonicalManifestPath =
  "packages/contracts/fixtures/canonical-instant-v1/manifest.json"
private let canonicalFixtureRoot = "packages/contracts/fixtures/canonical-instant-v1"
private let canonicalOpenAPIPath = "packages/contracts/openapi-components.json"
private let canonicalPendingSchemaPath =
  "packages/contracts/schemas/pending-check-response-v1.schema.json"
private let canonicalVerdictReasonSchemaPath =
  "packages/contracts/schemas/verdict-reason-v1.schema.json"
private let canonicalPendingFixtureRoot =
  "packages/contracts/fixtures/pending-check-response-v1"
private let canonicalVerdictReasonFixtureRoot =
  "packages/contracts/fixtures/verdict-reason-v1"
private let canonicalSchemaID = "urn:hezo-link:contract:canonical-instant:v1"
private let canonicalPattern =
  "^(?!0000-)[0-9]{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"
private let canonicalManifestSchemaReference = "../../schemas/canonical-instant-v1.schema.json"
private let canonicalOpenAPIReference = "./schemas/canonical-instant-v1.schema.json"
private let canonicalSchemaSHA256 =
  "689b090db031f88172c7899b08b456eec91b0feaf2861742185c9981efc47f33"
private let canonicalManifestSHA256 =
  "65b1691b3ea823f349f52ae23960c8150500396bdaf17f03cda9872b149b14b0"
private let canonicalComponentDocumentDigest =
  "7849793c07cdf9d4f65aaafd359c68427d054778bedc4b542c324164c7f26511"
private let canonicalReadmeSHA256 =
  "87267d2b4b717aa27900a897b76feb564c3178602b53e5ebf40225846b18260c"
private let canonicalContractDocumentDigest =
  "fc54aa418a681644b0b1f1783230d3cd3e2ff32225e3d2b2fe57ab76c08ba5e3"
private let canonicalPendingFixtureTreeSHA256 =
  "8c878df826a48db1537b6845feb8f6dd514fe7e71678022c3a3dc2f2668f9b7d"
private let canonicalVerdictReasonFixtureTreeSHA256 =
  "62e6c284efe9b799a3abe2c21cd3748be402ee24156bf2564bd20671490ea11c"
private let canonicalSchemaDescription =
  "Canonical real proleptic-Gregorian UTC whole-second instant in years 0001 through 9999. Validators must assert the date-time format so impossible calendar dates are rejected. This syntax alone defines no clock, freshness, lifetime, expiry, retention, polling, storage, persistence, network, completed-response, or report semantics."
private let canonicalOpenAPIDescription =
  "Reusable offline check-input, request-ID, check-token, canonical-instant, problem, check-response-status, pending-check-response, verdict, and standalone verdict-supporting schemas. This document declares no deployed service or operation."
private let canonicalOpenAPIComponents: Set<String> = [
  "CheckRequestV1", "RequestIDV1", "CheckTokenV1", "CanonicalInstantV1", "ProblemV1",
  "VerdictReasonV1", "VerdictLabelV1", "RecommendedActionV1", "ConfidenceCategoryV1",
  "EvaluatedScopeV1", "VerdictReasonsV1", "CheckResponseStatusV1",
  "PendingCheckResponseV1", "VerdictV1",
]

private let canonicalFixtureExpectations: [CanonicalFixtureExpectation] = [
  canonicalStringFixture(
    "valid-lower-boundary", "valid/lower-boundary.json", "0001-01-01T00:00:00Z", true),
  canonicalStringFixture(
    "valid-upper-boundary", "valid/upper-boundary.json", "9999-12-31T23:59:59Z", true),
  canonicalStringFixture(
    "valid-gregorian-leap-day", "valid/gregorian-leap-day.json", "2000-02-29T23:59:59Z", true),
  canonicalStringFixture(
    "valid-early-century-leap-day", "valid/early-century-leap-day.json", "0400-02-29T00:00:00Z",
    true),
  canonicalStringFixture(
    "valid-gregorian-reform-gap", "valid/gregorian-reform-gap.json", "1582-10-10T00:00:00Z", true),
  canonicalStringFixture(
    "valid-post-reform-century-leap-day", "valid/post-reform-century-leap-day.json",
    "1600-02-29T00:00:00Z", true),
  canonicalStringFixture(
    "valid-representative", "valid/representative.json", "2026-08-11T10:15:00Z", true),
  canonicalStringFixture(
    "reject-year-zero", "invalid/year-zero.json", "0000-01-01T00:00:00Z", false, ["pattern"]),
  canonicalStringFixture(
    "reject-impossible-calendar-date", "invalid/impossible-calendar-date.json",
    "2001-02-29T23:59:59Z", false, ["format"]),
  canonicalStringFixture(
    "reject-early-century-non-leap-day", "invalid/early-century-non-leap-day.json",
    "0100-02-29T00:00:00Z", false, ["format"]),
  canonicalStringFixture(
    "reject-pre-reform-century-non-leap-day", "invalid/pre-reform-century-non-leap-day.json",
    "1500-02-29T00:00:00Z", false, ["format"]),
  canonicalStringFixture(
    "reject-post-reform-century-non-leap-day", "invalid/post-reform-century-non-leap-day.json",
    "1900-02-29T00:00:00Z", false, ["format"]),
  canonicalStringFixture(
    "reject-future-century-non-leap-day", "invalid/future-century-non-leap-day.json",
    "2100-02-29T00:00:00Z", false, ["format"]),
  canonicalStringFixture(
    "reject-fractional-second", "invalid/fractional-second.json", "2000-02-29T23:59:59.001Z", false,
    ["pattern"]),
  canonicalStringFixture(
    "reject-numeric-offset", "invalid/numeric-offset.json", "2000-03-01T00:59:59+01:00", false,
    ["pattern"]),
  canonicalStringFixture(
    "reject-lowercase-t", "invalid/lowercase-t.json", "2000-02-29t23:59:59Z", false, ["pattern"]),
  canonicalStringFixture(
    "reject-lowercase-z", "invalid/lowercase-z.json", "2000-02-29T23:59:59z", false, ["pattern"]),
  canonicalStringFixture(
    "reject-leap-second", "invalid/leap-second.json", "2016-12-31T23:59:60Z", false, ["pattern"]),
  canonicalStringFixture(
    "reject-short", "invalid/short.json", "2026-08-11T10:15:00", false, ["pattern", "format"]),
  canonicalStringFixture(
    "reject-long", "invalid/long.json", "2026-08-11T10:15:00ZZ", false, ["pattern", "format"]),
  CanonicalFixtureExpectation(
    id: "reject-control", path: "invalid/control.json", rawJSON: "\"2026-08-11T10:15:0\\u0000Z\"\n",
    payload: .string("2026-08-11T10:15:0\u{0}Z"), expectedValid: false,
    failureKeywords: ["pattern", "format"]),
  canonicalStringFixture(
    "reject-non-ascii", "invalid/non-ascii.json", "2026-08-11T10:15:0éZ", false,
    ["pattern", "format"]),
  CanonicalFixtureExpectation(
    id: "reject-null", path: "invalid/null.json", rawJSON: "null\n", payload: .null,
    expectedValid: false, failureKeywords: ["type"]),
  CanonicalFixtureExpectation(
    id: "reject-wrong-type-number", path: "invalid/wrong-type-number.json", rawJSON: "946684800\n",
    payload: .integer(946_684_800), expectedValid: false, failureKeywords: ["type"]),
  CanonicalFixtureExpectation(
    id: "reject-wrong-type-boolean", path: "invalid/wrong-type-boolean.json", rawJSON: "true\n",
    payload: .boolean(true), expectedValid: false, failureKeywords: ["type"]),
  CanonicalFixtureExpectation(
    id: "reject-wrong-type-object", path: "invalid/wrong-type-object.json", rawJSON: "{}\n",
    payload: .object, expectedValid: false, failureKeywords: ["type"]),
  CanonicalFixtureExpectation(
    id: "reject-wrong-type-array", path: "invalid/wrong-type-array.json", rawJSON: "[]\n",
    payload: .array, expectedValid: false, failureKeywords: ["type"]),
]

private func canonicalStringFixture(
  _ id: String,
  _ path: String,
  _ value: String,
  _ expectedValid: Bool,
  _ failureKeywords: [String] = []
) -> CanonicalFixtureExpectation {
  CanonicalFixtureExpectation(
    id: id,
    path: path,
    rawJSON: "\"\(value)\"\n",
    payload: .string(value),
    expectedValid: expectedValid,
    failureKeywords: failureKeywords
  )
}

private func canonicalSchemaFailures(in value: Any) -> Set<String> {
  guard let string = value as? String else {
    return ["type"]
  }
  var failures = Set<String>()
  if canonicalPatternMatches(string) == false {
    failures.insert("pattern")
  }
  if canonicalDateTimeFormatMatches(string) == false {
    failures.insert("format")
  }
  return failures
}

private func canonicalPatternMatches(_ value: String) -> Bool {
  let bytes = Array(value.utf8)
  guard bytes.count == 20,
    bytes[4] == 0x2D, bytes[7] == 0x2D, bytes[10] == 0x54,
    bytes[13] == 0x3A, bytes[16] == 0x3A, bytes[19] == 0x5A,
    let year = canonicalDecimal(bytes, 0..<4), year != 0,
    let month = canonicalDecimal(bytes, 5..<7), (1...12).contains(month),
    let day = canonicalDecimal(bytes, 8..<10), (0...31).contains(day),
    let hour = canonicalDecimal(bytes, 11..<13), (0...23).contains(hour),
    let minute = canonicalDecimal(bytes, 14..<16), (0...59).contains(minute),
    let second = canonicalDecimal(bytes, 17..<19), (0...59).contains(second)
  else {
    return false
  }
  return true
}

private func canonicalDateTimeFormatMatches(_ value: String) -> Bool {
  let pattern =
    #"^([0-9]{4})-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(?:\.[0-9]+)?(?:[Zz]|[+-](?:[01][0-9]|2[0-3]):[0-5][0-9])$"#
  guard let expression = try? NSRegularExpression(pattern: pattern) else {
    return false
  }
  let range = NSRange(value.startIndex..<value.endIndex, in: value)
  guard let match = expression.firstMatch(in: value, range: range), match.range == range,
    let year = canonicalCapture(1, match: match, value: value),
    let month = canonicalCapture(2, match: match, value: value),
    let day = canonicalCapture(3, match: match, value: value)
  else {
    return false
  }

  let leap =
    year.isMultiple(of: 400)
    || (year.isMultiple(of: 4) && year.isMultiple(of: 100) == false)
  let maximumDay: Int
  switch month {
  case 2:
    maximumDay = leap ? 29 : 28
  case 4, 6, 9, 11:
    maximumDay = 30
  default:
    maximumDay = 31
  }
  return (1...maximumDay).contains(day)
}

private func canonicalDecimal(_ bytes: [UInt8], _ range: Range<Int>) -> Int? {
  var result = 0
  for index in range {
    guard (0x30...0x39).contains(bytes[index]) else {
      return nil
    }
    result = result * 10 + Int(bytes[index] - 0x30)
  }
  return result
}

private func canonicalCapture(
  _ index: Int,
  match: NSTextCheckingResult,
  value: String
) -> Int? {
  guard let range = Range(match.range(at: index), in: value) else {
    return nil
  }
  return Int(value[range])
}

private func canonicalResolve(
  _ referenceObject: [String: Any],
  registry: [String: [String: Any]]
) throws -> [String: Any] {
  guard Set(referenceObject.keys) == ["$ref"],
    let reference = referenceObject["$ref"] as? String,
    reference == canonicalSchemaID,
    let schema = registry[reference],
    schema["$id"] as? String == reference,
    schema["type"] as? String == "string",
    schema["pattern"] as? String == canonicalPattern,
    schema["format"] as? String == "date-time"
  else {
    throw CanonicalAssetError.invalidAsset
  }
  return schema
}

private func canonicalReferencePointers(in value: Any, pointer: String = "") -> [String] {
  if let object = value as? [String: Any] {
    return object.flatMap { key, child -> [String] in
      let childPointer = "\(pointer)/\(canonicalPointerSegment(key))"
      var matches: [String] = []
      if key == "$ref", child as? String == canonicalSchemaID {
        matches.append(childPointer)
      }
      matches.append(contentsOf: canonicalReferencePointers(in: child, pointer: childPointer))
      return matches
    }
  }
  if let array = value as? [Any] {
    return array.enumerated().flatMap { index, child in
      canonicalReferencePointers(in: child, pointer: "\(pointer)/\(index)")
    }
  }
  return []
}

private func canonicalPointerSegment(_ value: String) -> String {
  value.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
}

private func canonicalTreeDigest(_ relativeRoot: String) throws -> (fileCount: Int, digest: String)
{
  let root = canonicalRepositoryRoot.appendingPathComponent(relativeRoot).standardizedFileURL
  let paths = try canonicalRegularPaths(relativeTo: root).sorted()
  var hasher = SHA256()
  for path in paths {
    hasher.update(data: Data(path.utf8))
    hasher.update(data: Data([0]))
    hasher.update(data: try Data(contentsOf: root.appendingPathComponent(path)))
    hasher.update(data: Data([0]))
  }
  return (paths.count, canonicalHex(hasher.finalize()))
}

private func canonicalRegularPaths(relativeTo root: URL) throws -> Set<String> {
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
      options: []
    )
  else {
    throw CanonicalAssetError.unreadableAsset
  }

  var result = Set<String>()
  for case let URL as URL in enumerator {
    let values = try URL.resourceValues(
      forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey]
    )
    if values.isSymbolicLink == true {
      throw CanonicalAssetError.invalidAsset
    }
    if values.isDirectory == true {
      continue
    }
    guard values.isRegularFile == true else {
      throw CanonicalAssetError.invalidAsset
    }
    let prefix = root.path + "/"
    guard URL.path.hasPrefix(prefix) else {
      throw CanonicalAssetError.invalidAsset
    }
    result.insert(String(URL.path.dropFirst(prefix.count)))
  }
  return result
}

private func canonicalLoadObject(_ path: String) throws -> [String: Any] {
  try canonicalRequireObject(canonicalJSONValue(from: canonicalLoadData(path)))
}

private func canonicalLoadData(_ path: String) throws -> Data {
  let URL = canonicalRepositoryRoot.appendingPathComponent(path).standardizedFileURL
  guard URL.path.hasPrefix(canonicalRepositoryRoot.path + "/"),
    FileManager.default.fileExists(atPath: URL.path)
  else {
    throw CanonicalAssetError.unreadableAsset
  }
  return try Data(contentsOf: URL)
}

private func canonicalJSONValue(from data: Data) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  } catch {
    throw CanonicalAssetError.invalidAsset
  }
}

private func canonicalRequireObject(_ value: Any?) throws -> [String: Any] {
  guard let object = value as? [String: Any] else {
    throw CanonicalAssetError.invalidAsset
  }
  return object
}

private func canonicalRequireObjectArray(_ value: Any?) throws -> [[String: Any]] {
  guard let array = value as? [[String: Any]] else {
    throw CanonicalAssetError.invalidAsset
  }
  return array
}

private func canonicalRequireStringArray(_ value: Any?) throws -> [String] {
  guard let array = value as? [String] else {
    throw CanonicalAssetError.invalidAsset
  }
  return array
}

private func canonicalInteger(_ value: Any?) -> Int64? {
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

private func canonicalSHA256(_ data: Data) -> String {
  canonicalHex(SHA256.hash(data: data))
}

private func canonicalHex<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
  bytes.map { String(format: "%02x", $0) }.joined()
}
