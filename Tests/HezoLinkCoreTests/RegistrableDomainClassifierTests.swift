import Foundation
import Testing

@testable import HezoLinkCore

struct RegistrableDomainClassifierTests {
  struct HostKindExpectation: Sendable {
    let asciiHost: String
    let kind: ValidatedURLHost.Kind
  }

  @Test(
    "Validation preserves the normalized host category",
    arguments: [
      SafeURLCase(
        "domain_name",
        input: "https://kind.test/",
        expected: HostKindExpectation(asciiHost: "kind.test", kind: .domainName)
      ),
      SafeURLCase(
        "ipv4_literal",
        input: "https://192.0.2.1/",
        expected: HostKindExpectation(asciiHost: "192.0.2.1", kind: .ipv4Literal)
      ),
      SafeURLCase(
        "ipv6_literal",
        input: "https://[2001:db8::1]/",
        expected: HostKindExpectation(asciiHost: "2001:db8::1", kind: .ipv6Literal)
      ),
      SafeURLCase(
        "ipv4_mapped_ipv6_literal",
        input: "https://[::ffff:192.0.2.1]/",
        expected: HostKindExpectation(asciiHost: "192.0.2.1", kind: .ipv4Literal)
      ),
    ]
  )
  func hostKindPropagation(testCase: SafeURLCase<HostKindExpectation>) throws {
    let validatedURL = try #require(
      acceptedURL(
        from: ManualURLInputValidator.isolatedTestFixture.validate(testCase.input)
      )
    )

    #expect(validatedURL.asciiHost == testCase.expected.asciiHost)
    #expect(validatedURL.hostKind == testCase.expected.kind)
  }

  @Test func longestExactRuleSuppliesTheICANNResult() throws {
    let result = try classifiedResult(for: "https://example.co.uk/")

    #expect(result.publicSuffixASCII == "co.uk")
    #expect(result.registrableDomainASCII == "example.co.uk")
    #expect(result.section == .icann)
    #expect(result.listRevision == RegistrableDomainClassifier.listRevision)
  }

  @Test func wildcardRuleConsumesExactlyOneAdditionalLabel() throws {
    let result = try classifiedResult(for: "https://example.test.ck/")

    #expect(result.publicSuffixASCII == "test.ck")
    #expect(result.registrableDomainASCII == "example.test.ck")
    #expect(result.section == .icann)
  }

  @Test func exceptionRuleRemovesItsLeftmostLabel() throws {
    let result = try classifiedResult(for: "https://example.www.ck/")

    #expect(result.publicSuffixASCII == "ck")
    #expect(result.registrableDomainASCII == "www.ck")
    #expect(result.section == .icann)
  }

  @Test func implicitDefaultAppliesWhenNoListedRuleMatches() throws {
    let result = try classifiedResult(for: "https://example.test/")

    #expect(result.publicSuffixASCII == "test")
    #expect(result.registrableDomainASCII == "example.test")
    #expect(result.section == .implicitDefault)
  }

  @Test func privateRuleOutranksItsShorterICANNAncestor() throws {
    let result = try classifiedResult(for: "https://example.blogspot.com/")

    #expect(result.publicSuffixASCII == "blogspot.com")
    #expect(result.registrableDomainASCII == "example.blogspot.com")
    #expect(result.section == .privateDomain)
  }

  @Test func publicSuffixHostHasNoRegistrableDomain() throws {
    let classifier = try RegistrableDomainClassifier()
    let classification = classifier.classifyASCIIHostForTesting("co.uk")
    let result = try #require(classifiedResult(from: classification))

    #expect(result.publicSuffixASCII == "co.uk")
    #expect(result.registrableDomainASCII == nil)
    #expect(result.section == .icann)
  }

  @Test(
    "IP literals are outside public-suffix classification",
    arguments: [
      "https://192.0.2.1/",
      "https://[2001:db8::1]/",
      "https://[::ffff:192.0.2.1]/",
    ]
  )
  func ipLiteralsAreNotApplicable(input: String) throws {
    let validatedURL = try #require(
      acceptedURL(from: ManualURLInputValidator().validate(input))
    )
    let classifier = try RegistrableDomainClassifier()

    #expect(classifier.classify(validatedURL) == .notApplicable)
  }

  @Test func unavailableInjectedSnapshotHasABoundedFailure() {
    #expect(throws: RegistrableDomainClassifierError.resourceUnavailable) {
      try RegistrableDomainClassifier {
        throw InjectedSnapshotError.unavailable
      }
    }
  }

  @Test func changedSnapshotBytesFailClosed() throws {
    let snapshot = try RegistrableDomainClassifier.bundledSnapshotDataForTesting()
    var bytes = Array(snapshot)
    let mutationIndex = try #require(bytes.indices.dropFirst(32).first)
    bytes[mutationIndex] ^= 0x01
    let corruptedSnapshot = Data(bytes)

    #expect(throws: RegistrableDomainClassifierError.invalidSnapshot) {
      try RegistrableDomainClassifier {
        corruptedSnapshot
      }
    }
  }

  @Test func truncatedSnapshotFailsClosed() throws {
    let snapshot = try RegistrableDomainClassifier.bundledSnapshotDataForTesting().dropLast()

    #expect(throws: RegistrableDomainClassifierError.invalidSnapshot) {
      try RegistrableDomainClassifier {
        Data(snapshot)
      }
    }
  }

  @Test func classificationRenderingAndReflectionAreRedacted() throws {
    let canary = "private-domain-canary-8f51"
    let validatedURL = try #require(
      acceptedURL(
        from: ManualURLInputValidator.isolatedTestFixture.validate(
          "https://\(canary.lowercased()).test/path?secret=value#private"
        )
      )
    )
    let classification = try RegistrableDomainClassifier().classify(validatedURL)
    let result = try #require(classifiedResult(from: classification))
    let renderings =
      [
        classification.description,
        classification.debugDescription,
        String(describing: classification),
        String(reflecting: classification),
        result.description,
        result.debugDescription,
        String(describing: result),
        String(reflecting: result),
      ]
      + classification.customMirror.children.map { String(describing: $0.value) }
      + result.customMirror.children.map { String(describing: $0.value) }

    #expect(
      renderings.allSatisfy {
        $0.contains(canary) == false
          && $0.contains(canary.lowercased()) == false
          && $0.contains("secret=value") == false
      },
      "Ordinary classification diagnostics must never reveal classified URL content."
    )
  }

  @Test func snapshotErrorsDoNotReflectInjectedContent() {
    let canary = "PRIVATE_SNAPSHOT_CANARY_923d"
    let error: RegistrableDomainClassifierError
    do {
      _ = try RegistrableDomainClassifier {
        Data(canary.utf8)
      }
      Issue.record("Expected corrupt injected bytes to fail closed.")
      return
    } catch let caught as RegistrableDomainClassifierError {
      error = caught
    } catch {
      Issue.record("Expected the bounded classifier error category.")
      return
    }

    let renderings =
      [
        error.description,
        error.debugDescription,
        error.localizedDescription,
        error.errorDescription ?? "",
        String(describing: error),
        String(reflecting: error),
      ] + error.customMirror.children.map { String(describing: $0.value) }

    #expect(error == .invalidSnapshot)
    #expect(renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
    #expect(renderings.allSatisfy { $0.contains(canary) == false })
  }

  @Test("Concurrent classification is deterministic", .timeLimit(.minutes(1)))
  func concurrentClassificationIsDeterministic() async throws {
    let classifier = try RegistrableDomainClassifier()
    let validatedURL = try #require(
      acceptedURL(
        from: ManualURLInputValidator.isolatedTestFixture.validate(
          "https://concurrent.example.blogspot.com/"
        )
      )
    )
    let expected = classifier.classify(validatedURL)
    let outcomes = await withTaskGroup(of: RegistrableDomainClassification.self) { group in
      for _ in 0..<64 {
        group.addTask {
          classifier.classify(validatedURL)
        }
      }

      var values: [RegistrableDomainClassification] = []
      for await value in group {
        values.append(value)
      }
      return values
    }

    #expect(outcomes.count == 64)
    #expect(outcomes.allSatisfy { $0 == expected })
  }

  private func classifiedResult(for rawURL: String) throws -> RegistrableDomainResult {
    let validatedURL = try #require(
      acceptedURL(from: ManualURLInputValidator.isolatedTestFixture.validate(rawURL))
    )
    return try #require(
      classifiedResult(from: try RegistrableDomainClassifier().classify(validatedURL))
    )
  }

  private func acceptedURL(from outcome: ManualURLInputValidation) -> ValidatedManualURL? {
    guard case .accepted(let validatedURL) = outcome else {
      return nil
    }
    return validatedURL
  }

  private func classifiedResult(
    from classification: RegistrableDomainClassification
  ) -> RegistrableDomainResult? {
    guard case .classified(let result) = classification else {
      return nil
    }
    return result
  }
}

private enum InjectedSnapshotError: Error {
  case unavailable
}
