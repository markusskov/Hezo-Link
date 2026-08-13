import Foundation
import HezoLinkCore
import Testing

struct ProblemV1Tests {
  @Test func canonicalPublicSurfaceAndCompatibilityAliasAreExact() throws {
    requireProblemV1Conformances(ProblemV1.self)
    requireProblemContractErrorConformances(ProblemContractError.self)
    requireSameProblemV1Type(Problem.self)

    #expect(ProblemV1.maximumTypeUTF8ByteCount == 256)
    #expect(ProblemV1.maximumTitleUTF8ByteCount == 128)
    #expect(ProblemV1.maximumDetailUTF8ByteCount == 512)
    #expect(ProblemV1.maximumRequestIDByteCount == 128)
    #expect(ProblemV1.maximumRetryAfterSeconds == 86_400)

    let canonical = try makeProblem()
    let compatibility: Problem = canonical
    let canonicalAgain: ProblemV1 = compatibility
    let canonicalData = try HezoJSON.makeEncoder().encode(canonical)
    let compatibilityData = try HezoJSON.makeEncoder().encode(compatibility)
    let compatibilityDecoded = try HezoJSON.makeResponseDecoder().decode(
      Problem.self,
      from: canonicalData
    )
    let type: ProblemType = canonical.type
    let title: String = canonical.title
    let status: Int = canonical.status
    let code: ProblemCode = canonical.code
    let detail: String = canonical.detail
    let requestID: String = canonical.requestID
    let retryable: Bool = canonical.retryable
    let retryAfterSeconds: Int? = canonical.retryAfterSeconds

    #expect(canonicalAgain == canonical)
    #expect(compatibilityData == canonicalData)
    #expect(compatibilityDecoded == canonical)
    #expect(type.rawValue == "https://errors.hezo.example/temporarily-unavailable")
    #expect(title == "Temporarily unavailable")
    #expect(status == 503)
    #expect(code == .temporarilyUnavailable)
    #expect(detail == "Please try again later.")
    #expect(requestID == "plane-local-random-id")
    #expect(retryable)
    #expect(retryAfterSeconds == 30)
  }

  @Test func problemMatchesGoldenWireContract() throws {
    let problem = try makeProblem()
    let data = try HezoJSON.makeEncoder().encode(problem)
    let wireValue = try #require(String(data: data, encoding: .utf8))
    let expected =
      #"{"code":"temporarily_unavailable","detail":"Please try again later.","request_id":"plane-local-random-id","retry_after_seconds":30,"retryable":true,"status":503,"title":"Temporarily unavailable","type":"https://errors.hezo.example/temporarily-unavailable"}"#
    let decoded = try HezoJSON.makeResponseDecoder().decode(ProblemV1.self, from: data)

    #expect(wireValue == expected)
    #expect(decoded == problem)
  }

  @Test func nestedSemanticFailureHasExactBoundedContext() throws {
    let candidate = "attacker-controlled-nested-detail"
    let json =
      #"{"problem":{"type":"about:blank","title":"Title","status":200,"code":"invalid_url","detail":"\#(candidate)","request_id":"request-id","retryable":false}}"#
    let data = try #require(json.data(using: .utf8))

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(ProblemV1Envelope.self, from: data)
      Issue.record("Expected the nested invalid Problem V1 to be rejected.")
    } catch let DecodingError.dataCorrupted(context) {
      #expect(context.codingPath.map(\.stringValue) == ["problem"])
      #expect(context.debugDescription == "Invalid public problem value.")
      #expect(context.underlyingError == nil)
      #expect(String(describing: context).contains(candidate) == false)
      #expect(String(reflecting: context).contains(candidate) == false)
    } catch {
      Issue.record("Nested Problem V1 decoding used the wrong error category.")
    }
  }

  @Test func concurrentCanonicalAndCompatibilityRoundTripsAreDeterministic() async throws {
    let canonical = try makeProblem()
    let expected = try HezoJSON.makeEncoder().encode(canonical)

    try await withThrowingTaskGroup(of: Data.self) { group in
      for _ in 0..<64 {
        group.addTask {
          let decoded = try HezoJSON.makeResponseDecoder().decode(ProblemV1.self, from: expected)
          let compatibility: Problem = decoded
          return try HezoJSON.makeEncoder().encode(compatibility)
        }
      }

      for try await encoded in group {
        #expect(encoded == expected)
      }
    }
  }

  @Test func unknownFutureProblemCodeAndObjectFieldAreTolerated() throws {
    let json =
      #"{"type":"about:blank","title":"Future problem","status":503,"code":"future_dependency_failure","detail":"Bounded detail.","request_id":"request-id","retryable":true,"future_optional":true}"#
    let data = try #require(json.data(using: .utf8))
    let decoded = try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)

    #expect(decoded.code.rawValue == "future_dependency_failure")
    #expect(decoded.type.rawValue == "about:blank")
  }

  @Test func constructionRejectsInvalidProblemStates() throws {
    #expect(throws: ProblemContractError.emptyField) {
      try makeProblem(type: "")
    }
    #expect(throws: ProblemContractError.invalidFieldFormat) {
      try makeProblem(type: "not a uri")
    }
    #expect(throws: ProblemContractError.invalidFieldFormat) {
      try makeProblem(type: ":invalid")
    }
    #expect(throws: ProblemContractError.emptyField) {
      try makeProblem(title: "")
    }
    #expect(throws: ProblemContractError.invalidStatus) {
      try makeProblem(status: 200)
    }
    #expect(throws: ProblemContractError.retryDelayNotAllowed) {
      try makeProblem(retryable: false, retryAfterSeconds: 30)
    }
    #expect(throws: ProblemContractError.invalidRetryDelay) {
      try makeProblem(retryAfterSeconds: -1)
    }
    #expect(throws: ProblemContractError.invalidFieldFormat) {
      try makeProblem(detail: "unsafe\nvalue")
    }
    #expect(throws: ProblemContractError.emptyField) {
      try makeProblem(detail: "")
    }
    #expect(throws: ProblemContractError.fieldTooLong) {
      try makeProblem(title: String(repeating: "a", count: 129))
    }
    #expect(throws: ProblemContractError.invalidFieldFormat) {
      try makeProblem(requestID: "unsafe/request")
    }
    #expect(throws: ProblemContractError.emptyField) {
      try makeProblem(requestID: "")
    }
    #expect(throws: ProblemContractError.fieldTooLong) {
      try makeProblem(requestID: String(repeating: "a", count: 129))
    }
  }

  @Test func constructionAcceptsAndRejectsExactPublishedBoundaries() throws {
    let typePrefix = "https://e.test/"
    let maximumType =
      typePrefix
      + String(
        repeating: "a",
        count: Problem.maximumTypeUTF8ByteCount - typePrefix.utf8.count
      )
    let maximumTitle = String(repeating: "a", count: Problem.maximumTitleUTF8ByteCount)
    let maximumDetail = String(repeating: "a", count: Problem.maximumDetailUTF8ByteCount)
    let maximumRequestID = String(repeating: "a", count: Problem.maximumRequestIDByteCount)

    _ = try makeProblem(
      type: maximumType,
      title: maximumTitle,
      status: 400,
      detail: maximumDetail,
      requestID: maximumRequestID,
      retryAfterSeconds: 0
    )
    _ = try makeProblem(status: 599, retryAfterSeconds: Problem.maximumRetryAfterSeconds)

    #expect(throws: ProblemContractError.fieldTooLong) {
      try makeProblem(type: maximumType + "a")
    }
    #expect(throws: ProblemContractError.fieldTooLong) {
      try makeProblem(detail: maximumDetail + "a")
    }
    #expect(throws: ProblemContractError.invalidStatus) {
      try makeProblem(status: 399)
    }
    #expect(throws: ProblemContractError.invalidStatus) {
      try makeProblem(status: 600)
    }
    #expect(throws: ProblemContractError.invalidRetryDelay) {
      try makeProblem(retryAfterSeconds: Problem.maximumRetryAfterSeconds + 1)
    }
  }

  @Test func problemTypeDecodingRejectsInvalidURIWithoutEchoingIt() throws {
    let candidate = "not a uri-secret"
    let json =
      #"{"type":"\#(candidate)","title":"Title","status":422,"code":"invalid_url","detail":"Bounded detail.","request_id":"request-id","retryable":false}"#
    let data = try #require(json.data(using: .utf8))

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)
      Issue.record("Expected invalid problem type to be rejected.")
    } catch {
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    }
  }

  @Test(
    "Problem type accepts valid IP literals",
    arguments: ["https://[::1]/problem", "//[v1.a]/problem"]
  )
  func problemTypeAcceptsValidIPLiteral(_ candidate: String) throws {
    let value = try ProblemType(validating: candidate)

    #expect(value.rawValue == candidate)
  }

  @Test(
    "Problem type rejects malformed IP literals",
    arguments: [
      "[",
      "//[a]/",
      "https://[::1",
      "https://::1]/problem",
      "https://[::1]suffix/problem",
    ]
  )
  func problemTypeRejectsMalformedIPLiteral(_ candidate: String) {
    #expect(throws: ProblemContractError.invalidFieldFormat) {
      try ProblemType(validating: candidate)
    }
  }

  @Test func everyProblemContractErrorHasBoundedDescription() {
    let errors: [ProblemContractError] = [
      .emptyField,
      .fieldTooLong,
      .invalidFieldFormat,
      .invalidStatus,
      .invalidRetryDelay,
      .retryDelayNotAllowed,
    ]

    for error in errors {
      #expect(error.description.isEmpty == false)
      #expect(error.description.utf8.count <= 64)
    }
  }

  @Test func structuralDecodingErrorRemainsStructuralAndBounded() throws {
    let json =
      #"{"title":"Missing type","status":503,"code":"temporarily_unavailable","detail":"Bounded detail.","request_id":"request-id","retryable":true}"#
    let data = try #require(json.data(using: .utf8))

    #expect(throws: DecodingError.self) {
      try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)
    }
  }

  @Test func decodingErrorOmitsInvalidProblemContent() throws {
    let candidate = "attacker-controlled-secret"
    let json =
      #"{"type":"about:blank","title":"Title","status":200,"code":"invalid_url","detail":"\#(candidate)","request_id":"request-id","retryable":false}"#
    let data = try #require(json.data(using: .utf8))

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)
      Issue.record("Expected invalid problem to be rejected.")
    } catch {
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    }
  }

  @Test func descriptionsExcludeAttackerControlledFields() throws {
    let sensitiveType = "https://submitted.example.test/reset?token=secret#route"
    let sensitiveTitle = "attacker supplied title"
    let sensitiveRequestID = "request-secret-identifier"
    let sensitiveDetail = "attacker-controlled-detail"
    let problem = try ProblemV1(
      type: sensitiveType,
      title: sensitiveTitle,
      status: 422,
      code: .invalidURL,
      detail: sensitiveDetail,
      requestID: sensitiveRequestID,
      retryable: false
    )

    let mirrorChildren = Array(problem.customMirror.children)
    #expect(mirrorChildren.count == 1)

    for sensitiveValue in [sensitiveType, sensitiveTitle, sensitiveRequestID, sensitiveDetail] {
      #expect(problem.description.contains(sensitiveValue) == false)
      #expect(problem.debugDescription.contains(sensitiveValue) == false)
      #expect(String(reflecting: problem).contains(sensitiveValue) == false)
      #expect(
        mirrorChildren.allSatisfy {
          String(describing: $0.value).contains(sensitiveValue) == false
        }
      )
    }
    #expect(problem.description == "Problem(status: 422, code: invalid_url, retryable: false)")
  }

  private func makeProblem(
    type: String = "https://errors.hezo.example/temporarily-unavailable",
    title: String = "Temporarily unavailable",
    status: Int = 503,
    detail: String = "Please try again later.",
    requestID: String = "plane-local-random-id",
    retryable: Bool = true,
    retryAfterSeconds: Int? = 30
  ) throws -> ProblemV1 {
    try ProblemV1(
      type: type,
      title: title,
      status: status,
      code: .temporarilyUnavailable,
      detail: detail,
      requestID: requestID,
      retryable: retryable,
      retryAfterSeconds: retryAfterSeconds
    )
  }
}

private struct ProblemV1Envelope: Decodable {
  let problem: ProblemV1
}

private func requireProblemV1Conformances<T>(_: T.Type)
where
  T: Codable & Equatable & Sendable & CustomStringConvertible & CustomDebugStringConvertible
    & CustomReflectable
{}

private func requireProblemContractErrorConformances<T>(_: T.Type)
where T: Error & Equatable & Sendable & CustomStringConvertible {}

private func requireSameProblemV1Type(_: ProblemV1.Type) {}
