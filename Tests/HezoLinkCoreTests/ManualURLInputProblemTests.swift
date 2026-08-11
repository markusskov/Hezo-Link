import Foundation
import Testing

@testable import HezoLinkCore

struct ManualURLInputProblemTests {
  struct Expectation: Sendable {
    let problem: ManualURLInputProblem
    let code: ProblemCode
    let description: String
  }

  @Test(
    "Problems expose exact stable codes and bounded constant descriptions",
    arguments: [
      SafeCase(
        "invalid_url",
        payload: Expectation(
          problem: .invalidURL,
          code: .invalidURL,
          description: "The submitted value is not a supported URL."
        )
      ),
      SafeCase(
        "unsupported_scheme",
        payload: Expectation(
          problem: .unsupportedScheme,
          code: .unsupportedScheme,
          description: "The submitted URL scheme is unsupported."
        )
      ),
      SafeCase(
        "url_too_long",
        payload: Expectation(
          problem: .urlTooLong,
          code: .urlTooLong,
          description: "The submitted URL exceeds the local size limit."
        )
      ),
    ]
  )
  func stablePublicSurface(testCase: SafeCase<Expectation>) {
    let expectation = testCase.payload
    let problem = expectation.problem
    let renderedValues = [
      problem.description,
      problem.debugDescription,
      problem.errorDescription ?? "",
      problem.localizedDescription,
      String(describing: problem),
      String(reflecting: problem),
      (problem as NSError).localizedDescription,
    ]
    let codeMatches = problem.code == expectation.code
    let rawCodeMatches = problem.code.rawValue == testCase.id
    let descriptionsMatch = renderedValues.allSatisfy { $0 == expectation.description }
    let descriptionIsBounded = expectation.description.utf8.count <= 64

    #expect(codeMatches, "Each finite problem must map to its stable public code.")
    #expect(rawCodeMatches, "The public problem code must use the documented wire vocabulary.")
    #expect(descriptionsMatch, "All ordinary error renderings must use one constant description.")
    #expect(descriptionIsBounded, "Manual URL error descriptions must remain tightly bounded.")
  }

  @Test func problemRenderingsCannotContainARejectedCanary() {
    let canary = "URL_INPUT_CANARY_d4a61"
    let validator = ManualURLInputValidator.isolatedTestFixture
    let overlong =
      "https://host.test/?token=\(canary)"
      + String(
        repeating: "a",
        count: SubmittedURL.maximumUTF8ByteCount
      )
    let outcomes = [
      validator.validate("https://user:\(canary)@host.test/"),
      validator.validate("ftp://\(canary).test/"),
      validator.validate(overlong),
    ]
    let problems = outcomes.compactMap { outcome -> ManualURLInputProblem? in
      guard case .rejected(let problem) = outcome else {
        return nil
      }
      return problem
    }
    let renderings = problems.flatMap { problem in
      [
        problem.description,
        problem.debugDescription,
        problem.errorDescription ?? "",
        problem.localizedDescription,
        String(describing: problem),
        String(reflecting: problem),
        String(describing: problem as NSError),
        String(reflecting: problem as NSError),
      ]
    }
    let canaryWasExcluded =
      problems == [.invalidURL, .unsupportedScheme, .urlTooLong]
      && renderings.allSatisfy { $0.contains(canary) == false }

    #expect(canaryWasExcluded, "Finite manual URL problems must never retain rejected input.")
  }
}
