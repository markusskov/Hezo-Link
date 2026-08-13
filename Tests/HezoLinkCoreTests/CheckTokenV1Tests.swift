import Foundation
import HezoLinkCore
import Testing

struct CheckTokenV1Tests {
  @Test func constantsAndPublicConformancesAreExact() throws {
    let value = try CheckTokenV1(validating: checkTokenAllZeroEncoding)
    let error = CheckTokenContractError.invalidFormat

    #expect(CheckTokenV1.encodedCharacterCount == 43)
    #expect(CheckTokenV1.decodedByteCount == 32)
    requireCheckTokenConformances(value)
    requireCheckTokenErrorConformances(error)
  }

  @Test func exactDecodedAndEncodedLengthBoundariesAreEnforced() throws {
    let thirtyOneByteEncoding = base64URLEncoding(of: Data(repeating: 0, count: 31))
    let thirtyTwoByteEncoding = base64URLEncoding(of: Data(repeating: 0, count: 32))
    let thirtyThreeByteEncoding = base64URLEncoding(of: Data(repeating: 0, count: 33))

    #expect(thirtyOneByteEncoding.count == 42)
    #expect(thirtyTwoByteEncoding.count == CheckTokenV1.encodedCharacterCount)
    #expect(thirtyTwoByteEncoding == checkTokenAllZeroEncoding)
    #expect(thirtyThreeByteEncoding.count == 44)
    #expect(
      try CheckTokenV1(validating: thirtyTwoByteEncoding)
        == CheckTokenV1(validating: checkTokenAllZeroEncoding)
    )
    #expect(throws: CheckTokenContractError.invalidFormat) {
      try CheckTokenV1(validating: thirtyOneByteEncoding)
    }
    expectCheckTokenDecodeFailure(
      from: try JSONEncoder().encode(thirtyOneByteEncoding),
      rejectedCandidate: thirtyOneByteEncoding
    )
    #expect(throws: CheckTokenContractError.invalidFormat) {
      try CheckTokenV1(validating: thirtyThreeByteEncoding)
    }
    expectCheckTokenDecodeFailure(
      from: try JSONEncoder().encode(thirtyThreeByteEncoding),
      rejectedCandidate: thirtyThreeByteEncoding
    )
  }

  @Test func everyBase64URLAlphabetByteIsAcceptedAtEveryNonfinalPosition() throws {
    for position in 0..<42 {
      for character in checkTokenBase64URLAlphabet {
        var characters = [Character](repeating: "A", count: 43)
        characters[position] = character
        let candidate = String(characters)
        let token = try CheckTokenV1(validating: candidate)
        let encoded = try HezoJSON.makeEncoder().encode(token)

        #expect(String(data: encoded, encoding: .utf8) == "\"\(candidate)\"")
      }
    }
  }

  @Test(
    "Every canonical final base64url character is admitted",
    arguments: ["A", "E", "I", "M", "Q", "U", "Y", "c", "g", "k", "o", "s", "w", "0", "4", "8"]
  )
  func everyCanonicalFinalCharacterRoundTripsExactly(finalCharacter: String) throws {
    let candidate = String(repeating: "A", count: 42) + finalCharacter
    let token = try CheckTokenV1(validating: candidate)
    let encoded = try HezoJSON.makeEncoder().encode(token)
    let decoded = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: encoded)

    #expect(String(data: encoded, encoding: .utf8) == "\"\(candidate)\"")
    #expect(decoded == token)
  }

  @Test func everyOtherBase64URLFinalCharacterIsRejected() throws {
    let invalidFinalCharacters = checkTokenBase64URLAlphabet.filter {
      checkTokenCanonicalFinalCharacters.contains($0) == false
    }

    #expect(invalidFinalCharacters.count == 48)
    for finalCharacter in invalidFinalCharacters {
      let candidate = String(repeating: "A", count: 42) + String(finalCharacter)
      #expect(throws: CheckTokenContractError.invalidFormat) {
        try CheckTokenV1(validating: candidate)
      }

      let encoded = try JSONEncoder().encode(candidate)
      expectCheckTokenDecodeFailure(from: encoded, rejectedCandidate: candidate)
    }
  }

  @Test func everyNonBase64URLASCIIByteIsRejected() throws {
    let allowedBytes = Set(checkTokenBase64URLAlphabet.utf8)
    let disallowedBytes = (UInt8.min...0x7F).filter { allowedBytes.contains($0) == false }

    #expect(disallowedBytes.contains(0x00))
    #expect(disallowedBytes.contains(0x09))
    #expect(disallowedBytes.contains(0x0A))
    #expect(disallowedBytes.contains(0x0D))
    #expect(disallowedBytes.contains(0x20))
    #expect(disallowedBytes.contains(0x2B))
    #expect(disallowedBytes.contains(0x2F))
    #expect(disallowedBytes.contains(0x3D))
    #expect(disallowedBytes.contains(0x7F))

    for byte in disallowedBytes {
      let candidate = String(decoding: [byte], as: UTF8.self) + String(repeating: "A", count: 42)
      #expect(throws: CheckTokenContractError.invalidFormat) {
        try CheckTokenV1(validating: candidate)
      }

      let encoded = try JSONEncoder().encode(candidate)
      expectCheckTokenDecodeFailure(from: encoded, rejectedCandidate: candidate)
    }
  }

  @Test(
    "Padding, Unicode, and adjacent encoded lengths are rejected",
    arguments: [
      "",
      String(repeating: "A", count: 42),
      String(repeating: "A", count: 44),
      String(repeating: "A", count: 42) + "=",
      String(repeating: "A", count: 43) + "=",
      String(repeating: "A", count: 42) + "é",
      String(repeating: "A", count: 42) + "😀",
      String(repeating: "A", count: 42) + "e\u{301}",
    ]
  )
  func malformedCandidatesAreRejectedByConstructionAndDecoding(candidate: String) throws {
    #expect(throws: CheckTokenContractError.invalidFormat) {
      try CheckTokenV1(validating: candidate)
    }

    let encoded = try JSONEncoder().encode(candidate)
    expectCheckTokenDecodeFailure(from: encoded, rejectedCandidate: candidate)
  }

  @Test(
    "Decoding rejects every non-string JSON shape",
    arguments: ["null", "42", "true", "{}", "[]"]
  )
  func decodingRejectsWrongJSONTypes(json: String) {
    expectCheckTokenDecodeFailure(from: Data(json.utf8))
  }

  @Test func exactWireValuesRoundTripAndRemainDistinct() throws {
    let sequentialBytes = Data((UInt8.min...31))
    let candidates = [
      checkTokenAllZeroEncoding,
      checkTokenAllOneEncoding,
      base64URLEncoding(of: sequentialBytes),
    ]

    #expect(checkTokenAllOneEncoding == String(repeating: "_", count: 42) + "8")
    for candidate in candidates {
      #expect(candidate.count == CheckTokenV1.encodedCharacterCount)
      let token = try CheckTokenV1(validating: candidate)
      let encoded = try HezoJSON.makeEncoder().encode(token)
      let decoded = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: encoded)

      #expect(String(data: encoded, encoding: .utf8) == "\"\(candidate)\"")
      #expect(decoded == token)
    }

    let tokens = try candidates.map(CheckTokenV1.init(validating:))
    #expect(tokens[0] != tokens[1])
    #expect(tokens[1] != tokens[2])
  }

  @Test func descriptionsDebugAndReflectionAreFixedRedactions() throws {
    let candidate = checkTokenAllOneEncoding
    let token = try CheckTokenV1(validating: candidate)
    let mirrorChildren = Array(token.customMirror.children)
    let renderings =
      [
        token.description,
        token.debugDescription,
        String(describing: token),
        String(reflecting: token),
      ] + mirrorChildren.map { String(describing: $0.value) }

    #expect(token.description == "<redacted-check-token>")
    #expect(token.debugDescription == token.description)
    #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(mirrorChildren.first?.value as? String == "<redacted-check-token>")
  }

  @Test func validationAndDecodingErrorsAreBoundedAndPayloadFree() throws {
    let error = CheckTokenContractError.invalidFormat
    let nsError = error as NSError
    let errorRenderings = [
      error.description,
      error.debugDescription,
      error.localizedDescription,
      nsError.localizedDescription,
      String(reflecting: error),
      String(reflecting: nsError),
    ]

    #expect(error.description == "The check token has an invalid format.")
    #expect(error.debugDescription == error.description)
    #expect(error.errorDescription == error.description)
    #expect(errorRenderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
    #expect(Mirror(reflecting: error).children.isEmpty)

    let candidate = "PRIVATE_INVALID_CHECK_TOKEN_CANARY"
    let encoded = try JSONEncoder().encode(candidate)
    expectCheckTokenDecodeFailure(from: encoded, rejectedCandidate: candidate)
  }

  @Test func concurrentEncodeDecodeIsDeterministic() async throws {
    let token = try CheckTokenV1(validating: checkTokenAllOneEncoding)
    let expectedEncoding = try HezoJSON.makeEncoder().encode(token)
    let results = try await withThrowingTaskGroup(of: (CheckTokenV1, Data).self) { group in
      for _ in 0..<64 {
        group.addTask {
          let encoded = try HezoJSON.makeEncoder().encode(token)
          let decoded = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: encoded)
          return (decoded, encoded)
        }
      }

      var values: [(CheckTokenV1, Data)] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == token && $0.1 == expectedEncoding })
  }
}

private let checkTokenBase64URLAlphabet =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
private let checkTokenCanonicalFinalCharacters = Set("AEIMQUYcgkosw048")
private let checkTokenAllZeroEncoding = String(repeating: "A", count: 43)
private let checkTokenAllOneEncoding = base64URLEncoding(of: Data(repeating: 0xFF, count: 32))

private func requireCheckTokenConformances<Value>(_ value: Value)
where
  Value: Codable & Equatable & Sendable & CustomStringConvertible
    & CustomDebugStringConvertible & CustomReflectable
{
  _ = value
}

private func requireCheckTokenErrorConformances<Value>(_ value: Value)
where
  Value: Error & Equatable & Sendable & CustomStringConvertible & CustomDebugStringConvertible
    & LocalizedError
{
  _ = value
}

private func base64URLEncoding(of data: Data) -> String {
  data.base64EncodedString()
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
}

private func expectCheckTokenDecodeFailure(
  from data: Data,
  rejectedCandidate: String? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeResponseDecoder().decode(CheckTokenV1.self, from: data)
    Issue.record("An invalid decoded check token must be rejected.", sourceLocation: sourceLocation)
  } catch let error as DecodingError {
    guard case .dataCorrupted(let context) = error else {
      Issue.record(
        "Expected DecodingError.dataCorrupted, got \(String(describing: error)).",
        sourceLocation: sourceLocation
      )
      return
    }

    let expectedError = DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: [],
        debugDescription: "Invalid V1 check token."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(
      renderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 256 },
      sourceLocation: sourceLocation
    )
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(context.debugDescription == "Invalid V1 check token.", sourceLocation: sourceLocation)
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
    if let rejectedCandidate, rejectedCandidate.isEmpty == false {
      #expect(
        renderings.allSatisfy { $0.contains(rejectedCandidate) == false },
        sourceLocation: sourceLocation
      )
    }
  } catch {
    Issue.record(
      "Check-token decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}
