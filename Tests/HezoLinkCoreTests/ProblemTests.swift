import Foundation
import Testing

@testable import HezoLinkCore

struct ProblemTests {
  @Test func problemMatchesGoldenWireContract() throws {
    let problem = try makeProblem()
    let data = try HezoJSON.makeEncoder().encode(problem)
    let wireValue = try #require(String(data: data, encoding: .utf8))
    let expected =
      #"{"code":"temporarily_unavailable","detail":"Please try again later.","request_id":"plane-local-random-id","retry_after_seconds":30,"retryable":true,"status":503,"title":"Temporarily unavailable","type":"https://errors.hezo.example/temporarily-unavailable"}"#
    let decoded = try HezoJSON.makeResponseDecoder().decode(Problem.self, from: data)

    #expect(wireValue == expected)
    #expect(decoded == problem)
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
    let problem = try Problem(
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
  ) throws -> Problem {
    try Problem(
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
