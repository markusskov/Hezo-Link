import CryptoKit
import Foundation
import Testing

struct URLPolicyOracleManifestTests {
  @Test func packageIntegrityAndPinnedProvenanceHoldOffline() throws {
    try verifyURLPolicyOraclePackage()
  }

  @Test func addressSchemaRejectsNestedUnknownKey() throws {
    let (evaluator, originalPayload) = try oracleSchemaMutationSubject(
      schemaPath: "schemas/address-policy-cases-v1.schema.json",
      payloadPath: "cases/address-policy-cases-v1.json"
    )
    var payload = originalPayload
    guard var cases = payload["cases"] as? [[String: Any]], cases.isEmpty == false,
      var references = cases[0]["rfcReferences"] as? [[String: Any]],
      references.isEmpty == false
    else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    references[0]["unexpected"] = true
    cases[0]["rfcReferences"] = references
    payload["cases"] = cases

    #expect(try evaluator.validates(payload) == false)
  }

  @Test(
    arguments: [
      "companionSemanticValidationRequired",
      "companionSemanticChecks",
    ]
  )
  func manifestSchemaRejectsMissingCompanionSemanticField(_ field: String) throws {
    let (evaluator, originalPayload) = try oracleSchemaMutationSubject(
      schemaPath: "manifest.schema.json",
      payloadPath: "manifest.json"
    )
    var payload = originalPayload
    guard var requirements = payload["validationRequirements"] as? [String: Any],
      requirements.removeValue(forKey: field) != nil
    else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    payload["validationRequirements"] = requirements

    #expect(try evaluator.validates(payload) == false)
  }

  @Test func manifestSchemaRejectsSafetyConstantDrift() throws {
    let (evaluator, originalPayload) = try oracleSchemaMutationSubject(
      schemaPath: "manifest.schema.json",
      payloadPath: "manifest.json"
    )
    var payload = originalPayload
    guard var safety = payload["safety"] as? [String: Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    safety["networkAccessPermitted"] = true
    payload["safety"] = safety

    #expect(try evaluator.validates(payload) == false)
  }

  @Test func addressSchemaRejectsInvalidAcceptedMechanismEnum() throws {
    let (evaluator, originalPayload) = try oracleSchemaMutationSubject(
      schemaPath: "schemas/address-policy-cases-v1.schema.json",
      payloadPath: "cases/address-policy-cases-v1.json"
    )
    var payload = originalPayload
    guard var cases = payload["cases"] as? [[String: Any]], cases.isEmpty == false,
      var expectation = cases[0]["expected"] as? [String: Any],
      expectation["outcome"] as? String == "accepted"
    else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    expectation["mechanism"] = "dns"
    cases[0]["expected"] = expectation
    payload["cases"] = cases

    #expect(try evaluator.validates(payload) == false)
  }

  @Test func evaluatorRejectsUnsupportedAssertionVocabulary() throws {
    let packageRoot =
      urlPolicyOracleRepositoryRoot
      .appendingPathComponent("packages/url-policy-oracles")
      .standardizedFileURL
    var schema = try oracleJSONObject(at: packageRoot, path: "manifest.schema.json")
    schema["unevaluatedProperties"] = false

    do {
      _ = try URLPolicyOracleFrozenSchemaEvaluator(schema: schema)
      Issue.record("Expected the frozen schema vocabulary gate to reject an unknown keyword.")
    } catch URLPolicyOracleTestError.invalidFixture {
      // Expected: vocabulary expansion must be reviewed explicitly.
    } catch {
      Issue.record("Unexpected schema evaluator error: \(error)")
    }
  }
}

private func oracleSchemaMutationSubject(
  schemaPath: String,
  payloadPath: String
) throws -> (URLPolicyOracleFrozenSchemaEvaluator, [String: Any]) {
  let packageRoot =
    urlPolicyOracleRepositoryRoot
    .appendingPathComponent("packages/url-policy-oracles")
    .standardizedFileURL
  let schema = try oracleJSONObject(at: packageRoot, path: schemaPath)
  let payload = try oracleJSONObject(at: packageRoot, path: payloadPath)
  return (try URLPolicyOracleFrozenSchemaEvaluator(schema: schema), payload)
}

func verifyURLPolicyOraclePackage() throws {
  let packageRoot =
    urlPolicyOracleRepositoryRoot
    .appendingPathComponent("packages/url-policy-oracles")
    .standardizedFileURL
  let manifestData = try oracleManifestData(at: packageRoot, path: "manifest.json")
  try verifyPinnedOracleManifest(manifestData, at: packageRoot)
}

private func verifyPinnedOracleManifest(_ manifestData: Data, at packageRoot: URL) throws {
  try requireOracleFixture(
    oracleSHA256Hex(manifestData)
      == "e5c23874821efa03105e8c7eb2702874f8dc1d8270feabd72b916699575f6643"
  )

  let (rawManifest, manifest) = try decodeOracleManifest(manifestData)
  try verifyOracleManifestMetadata(rawManifest, manifest: manifest)
  let (idna, wpt) = try verifyOracleManifestCorpusMetadata(manifest)
  try verifyOracleManifestFiles(manifest, at: packageRoot)
  try verifyOracleManifestSchemas(manifest, at: packageRoot)
  try verifyOracleManifestSemanticBindings(manifest)
  try verifyOracleManifestCorpusCounts(idna: idna, wpt: wpt)
}

private func verifyOracleManifestFiles(
  _ manifest: URLPolicyOracleManifest,
  at packageRoot: URL
) throws {
  let expectedPaths = oracleManifestExpectedPaths
  let identities = oracleManifestFileIdentities(manifest)

  try verifyOracleManifestIdentityGraph(
    manifest,
    identities: identities,
    expectedPaths: expectedPaths
  )
  try verifyOracleManifestArtifacts(identities, at: packageRoot)
  try requireOracleFixture(
    oracleFilesOnDisk(at: packageRoot) == expectedPaths.union(["manifest.json"])
  )
}

private let oracleManifestExpectedPaths: Set<String> = [
  "README.md",
  "cases/address-policy-cases-v1.json",
  "manifest.schema.json",
  "schemas/address-policy-cases-v1.schema.json",
  "upstream/unicode/IdnaTestV2-17.0.0.txt",
  "upstream/unicode/LICENSE.txt",
  "upstream/wpt/LICENSE.md",
  "upstream/wpt/urltestdata-eb7aa8a1.json",
]

private func requireOracleFixture(_ condition: @autoclosure () throws -> Bool) throws {
  guard try condition() else {
    throw URLPolicyOracleTestError.invalidFixture
  }
}

private func decodeOracleManifest(
  _ data: Data
) throws -> ([String: Any], URLPolicyOracleManifest) {
  do {
    guard let rawValue = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    return (rawValue, try JSONDecoder().decode(URLPolicyOracleManifest.self, from: data))
  } catch {
    throw URLPolicyOracleTestError.invalidFixture
  }
}

private func verifyOracleManifestMetadata(
  _ rawManifest: [String: Any],
  manifest: URLPolicyOracleManifest
) throws {
  let topLevelKeys: Set<String> = [
    "schemaVersion", "manifestId", "purpose", "policyScope", "safety",
    "validationRequirements", "upstreamCorpora", "licenses", "projectCases", "schemas",
    "documentation",
  ]
  try requireOracleFixture(Set(rawManifest.keys) == topLevelKeys)
  try requireOracleFixture(manifest.schemaVersion == 1)
  try requireOracleFixture(manifest.manifestId == "hezo-url-policy-oracles-v1")
  try requireOracleFixture(
    manifest.purpose == "offline-parser-conformance-and-differential-testing"
  )
  try requireOracleFixture(manifest.policyScope == "manual-url-syntax-profile-2")
  try verifyOracleManifestSafety(manifest.safety)
  try verifyOracleManifestValidationRequirements(manifest.validationRequirements)
}

private func verifyOracleManifestSafety(_ safety: URLPolicyOracleManifest.Safety) throws {
  try requireOracleFixture(safety.executionBoundary == "offline-only")
  try requireOracleFixture(safety.networkAccessPermitted == false)
  try requireOracleFixture(safety.operationalUsePermitted == false)
  try requireOracleFixture(safety.containsCapturedInputs == false)
  try requireOracleFixture(safety.containsOperationalInputs == false)
  try requireOracleFixture(safety.containsPotentiallyResolvableNames)
  try requireOracleFixture(safety.containsSecrets == false)
  try requireOracleFixture(
    safety.networkBehavior == "must-not-resolve-connect-fetch-or-navigate"
  )
  try requireOracleFixture(
    safety.failureBehavior == "fail-closed-on-integrity-schema-count-or-provenance-mismatch"
  )
}

private func verifyOracleManifestValidationRequirements(
  _ requirements: URLPolicyOracleManifest.ValidationRequirements
) throws {
  try requireOracleFixture(
    requirements.jsonSchemaDialect == "https://json-schema.org/draft/2020-12/schema"
  )
  try requireOracleFixture(requirements.strictSchemaModeRequired)
  try requireOracleFixture(requirements.digestVerificationRequired)
  try requireOracleFixture(requirements.countVerificationRequired)
  try requireOracleFixture(requirements.lfLineEndingsRequired)
  try requireOracleFixture(requirements.finalNewlineRequired)
  try requireOracleFixture(requirements.unmanifestedArtifactUsePermitted == false)
  try requireOracleFixture(requirements.companionSemanticValidationRequired)
  try requireOracleFixture(
    requirements.companionSemanticChecks
      == [
        "unique-project-case-ids",
        "declared-vs-projected-category-and-outcome-counts",
        "distinct-rfc-document-count",
        "rfc-reference-tuple-coherence",
        "transformation-role-coherence",
      ]
  )
}

private func verifyOracleManifestCorpusMetadata(
  _ manifest: URLPolicyOracleManifest
) throws -> (URLPolicyOracleManifest.Corpus, URLPolicyOracleManifest.Corpus) {
  try requireOracleFixture(manifest.upstreamCorpora.count == 2)
  try requireOracleFixture(manifest.licenses.count == 2)
  try requireOracleFixture(manifest.schemas.count == 2)
  let idna = manifest.upstreamCorpora[0]
  let wpt = manifest.upstreamCorpora[1]
  try verifyOracleIDNAMetadata(idna)
  try verifyOracleWPTMetadata(wpt)
  try verifyOracleAddressMetadata(manifest.projectCases.counts)
  return (idna, wpt)
}

private func verifyOracleIDNAMetadata(_ corpus: URLPolicyOracleManifest.Corpus) throws {
  try requireOracleFixture(corpus.kind == "unicode-idna-test-v2")
  try requireOracleFixture(corpus.format == "UTS-46-IdnaTestV2")
  try requireOracleFixture(corpus.source.publisher == "Unicode Consortium")
  try requireOracleFixture(
    corpus.source.sourceURL == "https://www.unicode.org/Public/17.0.0/idna/IdnaTestV2.txt"
  )
  try requireOracleFixture(
    corpus.source.revision == "Unicode 17.0.0; UTS #46 test data dated 2025-05-01"
  )
  try requireOracleFixture(corpus.source.licenseSpdx == "Unicode-3.0")
  try requireOracleFixture(corpus.source.licensePath == "upstream/unicode/LICENSE.txt")
  try requireOracleFixture(corpus.counts.testCaseCount == 6_391)
  try requireOracleFixture(corpus.counts.commentLineCount == 109)
  try requireOracleFixture(corpus.counts.blankLineCount == 8)
}

private func verifyOracleWPTMetadata(_ corpus: URLPolicyOracleManifest.Corpus) throws {
  try requireOracleFixture(corpus.kind == "wpt-urltestdata")
  try requireOracleFixture(corpus.format == "WPT-urltestdata-JSON")
  try requireOracleFixture(corpus.source.publisher == "Web Platform Tests project")
  try requireOracleFixture(
    corpus.source.sourceURL
      == "https://raw.githubusercontent.com/web-platform-tests/wpt/eb7aa8a1d700d76170f68cf5c8da748928abd32f/url/resources/urltestdata.json"
  )
  try requireOracleFixture(
    corpus.source.revision == "eb7aa8a1d700d76170f68cf5c8da748928abd32f"
  )
  try requireOracleFixture(corpus.source.licenseSpdx == "BSD-3-Clause")
  try requireOracleFixture(corpus.source.licensePath == "upstream/wpt/LICENSE.md")
  try requireOracleFixture(corpus.counts.topLevelEntryCount == 1_004)
  try requireOracleFixture(corpus.counts.commentEntryCount == 113)
  try requireOracleFixture(corpus.counts.testCaseCount == 891)
  try requireOracleFixture(corpus.counts.successCaseCount == 624)
  try requireOracleFixture(corpus.counts.failureCaseCount == 267)
  try requireOracleFixture(corpus.counts.objectCommentCount == 8)
}

private func verifyOracleAddressMetadata(
  _ counts: URLPolicyOracleManifest.ProjectCounts
) throws {
  try requireOracleFixture(counts.caseCount == 42)
  try requireOracleFixture(counts.acceptedCaseCount == 18)
  try requireOracleFixture(counts.rejectedCaseCount == 24)
  try requireOracleFixture(counts.rfcDocumentCount == 9)
}

private func verifyOracleManifestSemanticBindings(
  _ manifest: URLPolicyOracleManifest
) throws {
  try verifyOracleManifestTransformations(manifest)
  try verifyOracleLicenseBindings(manifest)
  try verifyOracleProjectPayload(manifest)
}

private func verifyOracleManifestTransformations(
  _ manifest: URLPolicyOracleManifest
) throws {
  for corpus in manifest.upstreamCorpora {
    try verifyFrozenCopyTransformations(corpus.transformations)
  }
  for license in manifest.licenses {
    try verifyFrozenCopyTransformations(license.transformations)
  }

  let projectTransformations = manifest.projectCases.transformations
  try requireOracleFixture(projectTransformations.count == 1)
  guard let projectTransformation = projectTransformations.first else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  try requireOracleFixture(projectTransformation.operation == "project-authored")
  try requireOracleFixture(projectTransformation.contentChanged)
  try requireOracleFixture(projectTransformation.description.isEmpty == false)
}

private func verifyFrozenCopyTransformations(
  _ transformations: [URLPolicyOracleManifest.Transformation]
) throws {
  let allowedOperations: Set<String> = [
    "byte-for-byte-copy",
    "repository-path-rename-only",
  ]
  let operations = transformations.map(\.operation)
  try requireOracleFixture(transformations.isEmpty == false)
  try requireOracleFixture(Set(operations).count == operations.count)
  try requireOracleFixture(Set(operations).isSubset(of: allowedOperations))
  try requireOracleFixture(operations.contains("byte-for-byte-copy"))
  try requireOracleFixture(transformations.allSatisfy { $0.contentChanged == false })
  try requireOracleFixture(transformations.allSatisfy { $0.description.isEmpty == false })
}

private func verifyOracleLicenseBindings(_ manifest: URLPolicyOracleManifest) throws {
  let licensesByArtifact = Dictionary(grouping: manifest.licenses, by: \.forArtifactKind)
  try requireOracleFixture(licensesByArtifact.count == manifest.upstreamCorpora.count)
  try requireOracleFixture(licensesByArtifact.values.allSatisfy { $0.count == 1 })

  for corpus in manifest.upstreamCorpora {
    guard let license = licensesByArtifact[corpus.kind]?.first else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    try requireOracleFixture(license.kind == "license-text")
    try requireOracleFixture(license.spdxIdentifier == corpus.source.licenseSpdx)
    try requireOracleFixture(license.file.path == corpus.source.licensePath)
    try verifyOracleLicenseSource(license, for: corpus.kind)
  }
}

private func verifyOracleLicenseSource(
  _ license: URLPolicyOracleManifest.License,
  for corpusKind: String
) throws {
  switch corpusKind {
  case "unicode-idna-test-v2":
    try requireOracleFixture(license.sourceURL == "https://www.unicode.org/license.txt")
    try requireOracleFixture(
      license.sourceRevision == "Unicode License V3 (Unicode-3.0); copyright line 1991-2026"
    )
  case "wpt-urltestdata":
    let expectedRoot =
      "https://raw.githubusercontent.com/web-platform-tests/wpt/"
      + "eb7aa8a1d700d76170f68cf5c8da748928abd32f/"
    try requireOracleFixture(license.sourceURL == expectedRoot + "LICENSE.md")
    try requireOracleFixture(
      license.sourceRevision == "eb7aa8a1d700d76170f68cf5c8da748928abd32f"
    )
  default:
    throw URLPolicyOracleTestError.invalidFixture
  }
}

private func verifyOracleProjectPayload(_ manifest: URLPolicyOracleManifest) throws {
  let fixture = try loadURLPolicyAddressFixture(
    "packages/url-policy-oracles/\(manifest.projectCases.file.path)"
  )
  let cases = fixture.cases
  let projectedCategoryCounts = Dictionary(grouping: cases, by: \.category).mapValues(\.count)
  let acceptedCount = cases.filter { $0.expected.outcome == "accepted" }.count
  let rejectedCount = cases.filter { $0.expected.outcome == "rejected" }.count
  let identifiers = cases.map(\.id)

  try requireOracleFixture(cases.count == manifest.projectCases.counts.caseCount)
  try requireOracleFixture(Set(identifiers).count == identifiers.count)
  try requireOracleFixture(projectedCategoryCounts == fixture.categoryCounts)
  try requireOracleFixture(
    projectedCategoryCounts == manifest.projectCases.counts.categoryCounts
  )
  try requireOracleFixture(acceptedCount == manifest.projectCases.counts.acceptedCaseCount)
  try requireOracleFixture(rejectedCount == manifest.projectCases.counts.rejectedCaseCount)
  try requireOracleFixture(acceptedCount + rejectedCount == cases.count)
  try verifyOracleRFCReferences(
    cases,
    authoringBasis: manifest.projectCases.authoringBasis,
    declaredDocumentCount: manifest.projectCases.counts.rfcDocumentCount
  )
}

private struct OracleRFCReferenceKey: Hashable {
  let document: String
  let section: String
  let url: String
}

private func verifyOracleRFCReferences(
  _ cases: [URLPolicyAddressFixture.Case],
  authoringBasis: [URLPolicyOracleManifest.RFCReference],
  declaredDocumentCount: Int
) throws {
  let expectedDocuments: Set<String> = [
    "RFC 3056", "RFC 3849", "RFC 3986", "RFC 4291", "RFC 4380",
    "RFC 5737", "RFC 5952", "RFC 6052", "RFC 9844",
  ]
  let payloadReferences = cases.flatMap(\.rfcReferences)
  let payloadKeys = payloadReferences.map {
    OracleRFCReferenceKey(document: $0.document, section: $0.section, url: $0.url)
  }
  let authoringKeys = authoringBasis.map {
    OracleRFCReferenceKey(document: $0.document, section: $0.section, url: $0.url)
  }
  let payloadDocuments = Set(payloadKeys.map(\.document))
  let authoringDocuments = Set(authoringKeys.map(\.document))

  try requireOracleFixture(cases.allSatisfy { $0.rfcReferences.isEmpty == false })
  for testCase in cases {
    let caseKeys = testCase.rfcReferences.map {
      OracleRFCReferenceKey(document: $0.document, section: $0.section, url: $0.url)
    }
    try requireOracleFixture(Set(caseKeys).count == caseKeys.count)
  }
  try requireOracleFixture(payloadKeys.allSatisfy(oracleRFCReferenceIsCoherent))
  try requireOracleFixture(authoringKeys.allSatisfy(oracleRFCReferenceIsCoherent))
  try requireOracleFixture(Set(authoringKeys).count == authoringKeys.count)
  try requireOracleFixture(authoringKeys.count == expectedDocuments.count)
  try requireOracleFixture(payloadDocuments == expectedDocuments)
  try requireOracleFixture(authoringDocuments == expectedDocuments)
  try requireOracleFixture(payloadDocuments.count == declaredDocumentCount)
  try requireOracleFixture(authoringDocuments.count == declaredDocumentCount)
}

private func oracleRFCReferenceIsCoherent(_ reference: OracleRFCReferenceKey) -> Bool {
  guard reference.document.hasPrefix("RFC ") else {
    return false
  }
  let documentNumber = reference.document.dropFirst(4)
  let sectionParts = reference.section.split(separator: ".", omittingEmptySubsequences: false)
  let documentIsNumeric =
    documentNumber.isEmpty == false
    && documentNumber.utf8.allSatisfy { (0x30...0x39).contains($0) }
  let sectionIsNumeric =
    sectionParts.isEmpty == false
    && sectionParts.allSatisfy { part in
      part.isEmpty == false && part.utf8.allSatisfy { (0x30...0x39).contains($0) }
    }
  let expectedURL =
    "https://www.rfc-editor.org/rfc/rfc\(documentNumber).html#section-\(reference.section)"
  return documentIsNumeric && sectionIsNumeric && reference.url == expectedURL
}

private func oracleManifestFileIdentities(
  _ manifest: URLPolicyOracleManifest
) -> [URLPolicyOracleManifest.FileIdentity] {
  manifest.upstreamCorpora.map(\.file)
    + manifest.licenses.map(\.file)
    + [manifest.projectCases.file]
    + manifest.schemas.map(\.file)
    + [manifest.documentation.file]
}

private func verifyOracleManifestIdentityGraph(
  _ manifest: URLPolicyOracleManifest,
  identities: [URLPolicyOracleManifest.FileIdentity],
  expectedPaths: Set<String>
) throws {
  try requireOracleFixture(identities.count == expectedPaths.count)
  try requireOracleFixture(Set(identities.map(\.path)) == expectedPaths)
  try requireOracleFixture(Set(identities.map(\.path)).count == identities.count)
  try requireOracleFixture(
    manifest.projectCases.schemaPath == "schemas/address-policy-cases-v1.schema.json"
  )
  let addressSchemaSHA = manifest.schemas.first {
    $0.role == "address-policy-cases-schema"
  }?.file.sha256
  try requireOracleFixture(manifest.projectCases.schemaSha256 == addressSchemaSHA)
}

private func verifyOracleManifestArtifacts(
  _ identities: [URLPolicyOracleManifest.FileIdentity],
  at packageRoot: URL
) throws {
  for identity in identities {
    let data = try oracleManifestData(at: packageRoot, path: identity.path)
    try requireOracleFixture(data.count == identity.byteCount)
    try requireOracleFixture(oracleSHA256Hex(data) == identity.sha256)
    try requireOracleFixture(String(data: data, encoding: .utf8) != nil)
    try requireOracleFixture(data.contains(0x0D) == false)
    try requireOracleFixture(data.last == 0x0A)
    let lineCount = data.reduce(into: 0) { count, byte in
      if byte == 0x0A { count += 1 }
    }
    try requireOracleFixture(lineCount == identity.physicalLineCount)
    try requireOracleFixture(identity.encoding == "UTF-8")
    try requireOracleFixture(identity.lineEnding == "LF")
    try requireOracleFixture(identity.finalNewline)
  }
}

private func verifyOracleManifestCorpusCounts(
  idna: URLPolicyOracleManifest.Corpus,
  wpt: URLPolicyOracleManifest.Corpus
) throws {
  let idnaCases = try loadURLPolicyIDNACases(
    "packages/url-policy-oracles/\(idna.file.path)"
  )
  let wptCorpus = try loadURLPolicyWPTCorpus(
    "packages/url-policy-oracles/\(wpt.file.path)"
  )
  try requireOracleFixture(idnaCases.count == idna.counts.testCaseCount)
  try requireOracleFixture(wptCorpus.comments.count == wpt.counts.commentEntryCount)
  try requireOracleFixture(wptCorpus.cases.count == wpt.counts.testCaseCount)
  try requireOracleFixture(
    wptCorpus.cases.filter(\.expectsFailure).count == wpt.counts.failureCaseCount
  )
  try requireOracleFixture(
    wptCorpus.cases.filter { $0.expectsFailure == false }.count
      == wpt.counts.successCaseCount
  )
  try requireOracleFixture(
    wptCorpus.cases.filter(\.hasObjectComment).count == wpt.counts.objectCommentCount
  )
}

private func verifyOracleManifestSchemas(
  _ manifest: URLPolicyOracleManifest,
  at packageRoot: URL
) throws {
  let manifestPayload = try oracleJSONObject(at: packageRoot, path: "manifest.json")
  let manifestSchema = try oracleJSONObject(at: packageRoot, path: "manifest.schema.json")
  let addressPayload = try oracleJSONObject(
    at: packageRoot,
    path: manifest.projectCases.file.path
  )
  let addressSchema = try oracleJSONObject(
    at: packageRoot,
    path: manifest.projectCases.schemaPath
  )
  try requireOracleFixture(
    manifestSchema["$schema"] as? String
      == "https://json-schema.org/draft/2020-12/schema"
  )
  try requireOracleFixture(
    manifestSchema["$id"] as? String == "urn:hezo-link:url-policy-oracles:manifest:v1"
  )
  try requireOracleFixture(manifestSchema["additionalProperties"] as? Bool == false)
  try requireOracleFixture(
    addressSchema["$schema"] as? String
      == "https://json-schema.org/draft/2020-12/schema"
  )
  try requireOracleFixture(
    addressSchema["$id"] as? String
      == "urn:hezo-link:url-policy-oracles:address-policy-cases:v1"
  )
  try requireOracleFixture(addressSchema["additionalProperties"] as? Bool == false)
  let manifestEvaluator = try URLPolicyOracleFrozenSchemaEvaluator(schema: manifestSchema)
  let addressEvaluator = try URLPolicyOracleFrozenSchemaEvaluator(schema: addressSchema)
  try requireOracleFixture(try manifestEvaluator.validates(manifestPayload))
  try requireOracleFixture(try addressEvaluator.validates(addressPayload))
}

private struct URLPolicyOracleManifest: Decodable {
  let schemaVersion: Int
  let manifestId: String
  let purpose: String
  let policyScope: String
  let safety: Safety
  let validationRequirements: ValidationRequirements
  let upstreamCorpora: [Corpus]
  let licenses: [License]
  let projectCases: ProjectCases
  let schemas: [SchemaArtifact]
  let documentation: Documentation

  struct Safety: Decodable {
    let executionBoundary: String
    let networkAccessPermitted: Bool
    let operationalUsePermitted: Bool
    let containsCapturedInputs: Bool
    let containsOperationalInputs: Bool
    let containsPotentiallyResolvableNames: Bool
    let containsSecrets: Bool
    let networkBehavior: String
    let failureBehavior: String
  }

  struct ValidationRequirements: Decodable {
    let jsonSchemaDialect: String
    let strictSchemaModeRequired: Bool
    let digestVerificationRequired: Bool
    let countVerificationRequired: Bool
    let lfLineEndingsRequired: Bool
    let finalNewlineRequired: Bool
    let unmanifestedArtifactUsePermitted: Bool
    let companionSemanticValidationRequired: Bool
    let companionSemanticChecks: [String]
  }

  struct FileIdentity: Decodable {
    let path: String
    let mediaType: String
    let encoding: String
    let byteCount: Int
    let sha256: String
    let lineEnding: String
    let physicalLineCount: Int
    let finalNewline: Bool
  }

  struct Source: Decodable {
    let publisher: String
    let sourceURL: String
    let revision: String
    let licenseSpdx: String
    let licensePath: String
  }

  struct Transformation: Decodable {
    let operation: String
    let contentChanged: Bool
    let description: String
  }

  struct RFCReference: Decodable {
    let document: String
    let section: String
    let url: String
  }

  struct CorpusCounts: Decodable {
    let testCaseCount: Int
    let commentLineCount: Int?
    let blankLineCount: Int?
    let topLevelEntryCount: Int?
    let commentEntryCount: Int?
    let successCaseCount: Int?
    let failureCaseCount: Int?
    let objectCommentCount: Int?
  }

  struct Corpus: Decodable {
    let kind: String
    let format: String
    let file: FileIdentity
    let source: Source
    let counts: CorpusCounts
    let transformations: [Transformation]
  }

  struct License: Decodable {
    let kind: String
    let forArtifactKind: String
    let spdxIdentifier: String
    let file: FileIdentity
    let sourceURL: String
    let sourceRevision: String
    let transformations: [Transformation]
  }

  struct ProjectCounts: Decodable {
    let caseCount: Int
    let acceptedCaseCount: Int
    let rejectedCaseCount: Int
    let rfcDocumentCount: Int
    let categoryCounts: [String: Int]
  }

  struct ProjectCases: Decodable {
    let kind: String
    let file: FileIdentity
    let schemaPath: String
    let schemaSha256: String
    let authoringBasis: [RFCReference]
    let counts: ProjectCounts
    let transformations: [Transformation]
  }

  struct SchemaArtifact: Decodable {
    let kind: String
    let role: String
    let dialect: String
    let file: FileIdentity
  }

  struct Documentation: Decodable {
    let kind: String
    let file: FileIdentity
  }
}

private func oracleManifestData(at packageRoot: URL, path: String) throws -> Data {
  let candidate = packageRoot.appendingPathComponent(path).standardizedFileURL
  let resolvedRoot = packageRoot.resolvingSymlinksInPath()
  let resolvedCandidate = candidate.resolvingSymlinksInPath()
  guard resolvedCandidate.path.hasPrefix(resolvedRoot.path + "/") else {
    throw URLPolicyOracleTestError.invalidFixture
  }
  do {
    return try Data(contentsOf: resolvedCandidate, options: [.mappedIfSafe])
  } catch {
    throw URLPolicyOracleTestError.unreadableFixture
  }
}

private func oracleJSONObject(at packageRoot: URL, path: String) throws -> [String: Any] {
  let data = try oracleManifestData(at: packageRoot, path: path)
  do {
    guard let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    return value
  } catch is URLPolicyOracleTestError {
    throw URLPolicyOracleTestError.invalidFixture
  } catch {
    throw URLPolicyOracleTestError.invalidFixture
  }
}

private func oracleSHA256Hex(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func oracleFilesOnDisk(at packageRoot: URL) throws -> Set<String> {
  guard
    let enumerator = FileManager.default.enumerator(
      at: packageRoot,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )
  else {
    throw URLPolicyOracleTestError.unreadableFixture
  }
  var paths: Set<String> = []
  for case let url as URL in enumerator {
    let values = try url.resourceValues(forKeys: [.isRegularFileKey])
    guard values.isRegularFile == true else {
      continue
    }
    let prefix = packageRoot.path + "/"
    guard url.path.hasPrefix(prefix) else {
      throw URLPolicyOracleTestError.invalidFixture
    }
    paths.insert(String(url.path.dropFirst(prefix.count)))
  }
  return paths
}
