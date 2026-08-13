import Foundation
import HezoLinkCore
import Testing

struct CanonicalInstantV1Tests {
  @Test func constantsPublicConformancesAndDateBoundaryAreExact() throws {
    let value = try CanonicalInstantV1(validating: "2026-08-11T10:30:00Z")
    let error = CanonicalInstantContractError.invalidValue

    #expect(CanonicalInstantV1.wireByteCount == 20)
    requireCanonicalInstantConformances(value)
    requireCanonicalInstantErrorConformances(error)
    #expect(value.date == Date(timeIntervalSince1970: 1_786_444_200))
  }

  @Test(
    "Canonical boundaries and real leap dates round-trip exactly",
    arguments: [
      "0001-01-01T00:00:00Z",
      "0004-02-29T00:00:00Z",
      "0400-02-29T00:00:00Z",
      "1582-10-04T00:00:00Z",
      "1582-10-10T00:00:00Z",
      "1582-10-15T00:00:00Z",
      "1600-02-29T23:59:59Z",
      "2000-02-29T12:34:56Z",
      "2024-02-29T00:00:00Z",
      "1970-01-01T00:00:00Z",
      "9999-12-31T23:59:59Z",
    ]
  )
  func validWireValuesAndDatesRoundTripExactly(wireValue: String) throws {
    let value = try CanonicalInstantV1(validating: wireValue)
    let encoded = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(CanonicalInstantV1.self, from: encoded)
    let reconstructed = try CanonicalInstantV1(validating: value.date)

    #expect(wireValue.utf8.count == CanonicalInstantV1.wireByteCount)
    #expect(String(data: encoded, encoding: .utf8) == "\"\(wireValue)\"")
    #expect(decoded == value)
    #expect(decoded.date == value.date)
    #expect(reconstructed == value)
  }

  @Test(
    "Impossible calendar and time fields are rejected",
    arguments: [
      "2024-00-01T00:00:00Z",
      "2024-13-01T00:00:00Z",
      "2024-01-00T00:00:00Z",
      "2024-01-32T00:00:00Z",
      "2024-04-31T00:00:00Z",
      "2023-02-29T00:00:00Z",
      "0100-02-29T00:00:00Z",
      "1500-02-29T00:00:00Z",
      "1900-02-29T00:00:00Z",
      "2100-02-29T00:00:00Z",
      "2024-02-30T00:00:00Z",
      "2024-01-01T24:00:00Z",
      "2024-01-01T00:60:00Z",
      "2024-01-01T00:00:60Z",
    ]
  )
  func impossibleCalendarValuesAreRejected(wireValue: String) throws {
    expectCanonicalInstantConstructionAndDecodeFailure(wireValue)
  }

  @Test(
    "Year zero, fractions, offsets, casing variants, and malformed shapes are rejected",
    arguments: [
      "0000-01-01T00:00:00Z",
      "10000-01-01T00:00:00Z",
      "2024-01-01T00:00:00.0Z",
      "2024-01-01T00:00:00.000Z",
      "2024-01-01T00:00:00+00:00",
      "2024-01-01T01:00:00+01:00",
      "2024-01-01T00:00:00-00:00",
      "2024-01-01T00:00:00z",
      "2024-01-01t00:00:00Z",
      "2024-01-01 00:00:00Z",
      "+2024-01-01T00:00:00Z",
      "2024-1-01T00:00:00Z",
      "2024-01-1T00:00:00Z",
      "2024-01-01T0:00:00Z",
      "2024-01-01T00:0:00Z",
      "2024-01-01T00:00:0Z",
      "2024-01-01",
      " 2024-01-01T00:00:00Z",
      "2024-01-01T00:00:00Z ",
      "",
    ]
  )
  func noncanonicalSpellingsAreRejected(wireValue: String) throws {
    expectCanonicalInstantConstructionAndDecodeFailure(wireValue)
  }

  @Test func everyASCIIControlByteIsRejected() throws {
    let controlBytes = Array(UInt8.min...0x1F) + [0x7F]

    #expect(controlBytes.count == 33)
    for byte in controlBytes {
      var bytes = Array("2024-01-01T00:00:00Z".utf8)
      bytes[18] = byte
      let candidate = String(decoding: bytes, as: UTF8.self)

      #expect(candidate.utf8.count == CanonicalInstantV1.wireByteCount)
      expectCanonicalInstantConstructionAndDecodeFailure(candidate)
    }
  }

  @Test(
    "Non-ASCII and Unicode-normalization variants are rejected",
    arguments: [
      "２０２４-01-01T00:00:00Z",
      "2024-０1-01T00:00:00Z",
      "2024-01-01T00:00:00Å",
      "2024-01-01T00:00:00A\u{30A}",
      "2024-01-01T00:00:00😀",
      "2024-01-01T00:00:00é",
      "2024-01-01T00:00:00e\u{301}",
    ]
  )
  func nonASCIICandidatesAreRejected(wireValue: String) throws {
    expectCanonicalInstantConstructionAndDecodeFailure(wireValue)
  }

  @Test(
    "Exact Unix-second anchors are independent and stable",
    arguments: [
      ("0001-01-01T00:00:00Z", Int64(-62_135_596_800)),
      ("1582-10-04T00:00:00Z", Int64(-12_220_243_200)),
      ("1582-10-10T00:00:00Z", Int64(-12_219_724_800)),
      ("1582-10-15T00:00:00Z", Int64(-12_219_292_800)),
      ("1969-12-31T23:59:59Z", Int64(-1)),
      ("1970-01-01T00:00:00Z", Int64(0)),
      ("9999-12-31T23:59:59Z", Int64(253_402_300_799)),
    ]
  )
  func exactUnixSecondAnchorsRoundTripBothInitializers(testCase: (String, Int64)) throws {
    let (wireValue, unixSeconds) = testCase
    let expectedDate = Date(timeIntervalSince1970: TimeInterval(unixSeconds))
    let fromWire = try CanonicalInstantV1(validating: wireValue)
    let fromDate = try CanonicalInstantV1(validating: expectedDate)
    let wireEncoding = try HezoJSON.makeEncoder().encode(fromWire)
    let dateEncoding = try HezoJSON.makeEncoder().encode(expectedDate)
    let decodedDate = try HezoJSON.makeResponseDecoder().decode(Date.self, from: wireEncoding)

    #expect(fromWire.date == expectedDate)
    #expect(fromDate == fromWire)
    #expect(decodedDate == expectedDate)
    #expect(String(data: wireEncoding, encoding: .utf8) == "\"\(wireValue)\"")
    #expect(dateEncoding == wireEncoding)
  }

  @Test func GregorianReformGapIsAContinuousProlepticGregorianInterval() throws {
    let october4 = try CanonicalInstantV1(validating: "1582-10-04T00:00:00Z")
    let october10 = try CanonicalInstantV1(validating: "1582-10-10T00:00:00Z")
    let october15 = try CanonicalInstantV1(validating: "1582-10-15T00:00:00Z")

    #expect(october10.date.timeIntervalSince(october4.date) == 6 * 86_400)
    #expect(october15.date.timeIntervalSince(october10.date) == 5 * 86_400)
  }

  @Test(
    "Direct decoding rejects every non-string JSON shape",
    arguments: ["null", "42", "true", "{}", "[]"]
  )
  func decodingRejectsWrongJSONTypes(json: String) {
    expectCanonicalInstantDecodeFailure(from: Data(json.utf8))
  }

  @Test func adjacentDateBoundariesFractionsAndNonfiniteDatesAreRejected() throws {
    let minimum = try CanonicalInstantV1(validating: "0001-01-01T00:00:00Z").date
    let maximum = try CanonicalInstantV1(validating: "9999-12-31T23:59:59Z").date
    let invalidDates = [
      minimum.addingTimeInterval(-1),
      maximum.addingTimeInterval(1),
      Date(timeIntervalSince1970: 1_786_444_200.5),
      Date(timeIntervalSince1970: -0.5),
      Date(timeIntervalSince1970: .infinity),
      Date(timeIntervalSince1970: -.infinity),
      Date(timeIntervalSince1970: .nan),
    ]

    for date in invalidDates {
      #expect(throws: CanonicalInstantContractError.invalidValue) {
        try CanonicalInstantV1(validating: date)
      }
    }

    let negativeZero = try CanonicalInstantV1(validating: Date(timeIntervalSince1970: -0.0))
    let positiveZero = try CanonicalInstantV1(validating: Date(timeIntervalSince1970: 0.0))
    #expect(negativeZero == positiveZero)
    #expect(negativeZero.date.timeIntervalSince1970.sign == .plus)
  }

  @Test func extremeFiniteDatesFailWithoutOverflow() {
    let invalidDates = [
      Date(timeIntervalSince1970: TimeInterval(Int64.min)),
      Date(timeIntervalSince1970: TimeInterval(Int64.max)),
      Date(timeIntervalSinceReferenceDate: -.greatestFiniteMagnitude),
      Date(timeIntervalSinceReferenceDate: .greatestFiniteMagnitude),
    ]

    for date in invalidDates {
      #expect(throws: CanonicalInstantContractError.invalidValue) {
        try CanonicalInstantV1(validating: date)
      }
    }
  }

  @Test func distinctWireValuesRemainDistinct() throws {
    let first = try CanonicalInstantV1(validating: "2026-08-11T10:30:00Z")
    let same = try CanonicalInstantV1(validating: first.date)
    let second = try CanonicalInstantV1(validating: "2026-08-11T10:30:01Z")

    #expect(first == same)
    #expect(first != second)
    #expect(first.date != second.date)
  }

  @Test func descriptionsDebugAndReflectionAreFixedRedactions() throws {
    let candidate = "2026-08-11T10:30:00Z"
    let value = try CanonicalInstantV1(validating: candidate)
    let mirrorChildren = Array(value.customMirror.children)
    let renderings =
      [
        value.description,
        value.debugDescription,
        String(describing: value),
        String(reflecting: value),
      ] + mirrorChildren.map { String(describing: $0.value) }

    #expect(value.description == "<redacted-canonical-instant>")
    #expect(value.debugDescription == value.description)
    #expect(renderings.allSatisfy { $0.contains(candidate) == false })
    #expect(mirrorChildren.count == 1)
    #expect(mirrorChildren.first?.label == "value")
    #expect(mirrorChildren.first?.value as? String == "<redacted-canonical-instant>")
  }

  @Test func validationAndDirectDecodingErrorsAreExactBoundedAndPayloadFree() throws {
    let error = CanonicalInstantContractError.invalidValue
    let nsError = error as NSError
    let errorRenderings = [
      error.description,
      error.debugDescription,
      error.localizedDescription,
      nsError.localizedDescription,
      String(reflecting: error),
      String(reflecting: nsError),
    ]

    #expect(error.description == "The canonical instant has an invalid value.")
    #expect(error.debugDescription == error.description)
    #expect(error.errorDescription == error.description)
    #expect(errorRenderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 128 })
    #expect(Mirror(reflecting: error).children.isEmpty)

    let candidate = "PRIVATE_INSTANT_CANARY"
    expectCanonicalInstantDecodeFailure(
      from: try JSONEncoder().encode(candidate),
      rejectedCandidate: candidate
    )
  }

  @Test func directDecodeErrorKeepsTheContainingCodingPath() {
    let candidate = "PRIVATE_INSTANT_CANARY"
    let data = Data("{\"instant\":\"\(candidate)\"}".utf8)

    do {
      _ = try JSONDecoder().decode(CanonicalInstantEnvelope.self, from: data)
      Issue.record("An invalid nested canonical instant must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      #expect(context.debugDescription == "Invalid V1 canonical instant.")
      #expect(context.codingPath.map(\.stringValue) == ["instant"])
      #expect(context.underlyingError == nil)
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    } catch {
      Issue.record("Canonical-instant decoding used an unexpected error category.")
    }
  }

  @Test func concurrentConstructionEncodeAndDecodeAreDeterministic() async throws {
    let value = try CanonicalInstantV1(validating: "2026-08-11T10:30:00Z")
    let expectedEncoding = try HezoJSON.makeEncoder().encode(value)
    let results = try await withThrowingTaskGroup(of: (CanonicalInstantV1, Data).self) { group in
      for _ in 0..<64 {
        group.addTask {
          let reconstructed = try CanonicalInstantV1(validating: value.date)
          let encoded = try HezoJSON.makeEncoder().encode(reconstructed)
          let decoded = try HezoJSON.makeResponseDecoder().decode(
            CanonicalInstantV1.self,
            from: encoded
          )
          return (decoded, encoded)
        }
      }

      var values: [(CanonicalInstantV1, Data)] = []
      for try await result in group {
        values.append(result)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0.0 == value && $0.1 == expectedEncoding })
  }

  @Test func HezoJSONUsesTheSameExactCanonicalWireContractForDates() throws {
    let cases = [
      "0001-01-01T00:00:00Z",
      "1970-01-01T00:00:00Z",
      "2000-02-29T12:34:56Z",
      "9999-12-31T23:59:59Z",
    ]

    for wireValue in cases {
      let date = try CanonicalInstantV1(validating: wireValue).date
      let encoded = try HezoJSON.makeEncoder().encode(date)
      let decoded = try HezoJSON.makeResponseDecoder().decode(Date.self, from: encoded)

      #expect(String(data: encoded, encoding: .utf8) == "\"\(wireValue)\"")
      #expect(decoded == date)
    }
  }

  @Test func HezoJSONKeepsExactLegacyDateEncodingErrors() throws {
    let minimum = try CanonicalInstantV1(validating: "0001-01-01T00:00:00Z").date
    let maximum = try CanonicalInstantV1(validating: "9999-12-31T23:59:59Z").date

    expectHezoDateEncodingFailure(
      Date(timeIntervalSince1970: 1_786_444_200.5),
      debugDescription: "Contract instants require UTC whole-second precision."
    )
    expectHezoDateEncodingFailure(
      Date(timeIntervalSince1970: .nan),
      debugDescription: "Contract instants require UTC whole-second precision."
    )
    expectHezoDateEncodingFailure(
      minimum.addingTimeInterval(-1),
      debugDescription: "Contract instant is outside the canonical UTC range."
    )
    expectHezoDateEncodingFailure(
      maximum.addingTimeInterval(1),
      debugDescription: "Contract instant is outside the canonical UTC range."
    )
  }

  @Test func HezoJSONKeepsExactLegacyDateDecodingErrorsAndCodingPaths() {
    let candidate = "2026-02-30T12:34:56Z"
    let data = Data("{\"instant\":\"\(candidate)\"}".utf8)

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(LegacyDateEnvelope.self, from: data)
      Issue.record("A noncanonical legacy Date must be rejected.")
    } catch let error as DecodingError {
      guard case .dataCorrupted(let context) = error else {
        Issue.record("Expected DecodingError.dataCorrupted.")
        return
      }

      #expect(context.debugDescription == "Invalid canonical UTC contract instant.")
      #expect(context.codingPath.map(\.stringValue) == ["instant"])
      #expect(context.underlyingError == nil)
      #expect(String(describing: error).contains(candidate) == false)
      #expect(String(reflecting: error).contains(candidate) == false)
    } catch {
      Issue.record("HezoJSON used an unexpected legacy Date error category.")
    }
  }

  @Test func HezoJSONKeepsLegacyWrongTypeFailureSeparateFromCanonicality() {
    let data = Data("{\"instant\":42}".utf8)

    do {
      _ = try HezoJSON.makeResponseDecoder().decode(LegacyDateEnvelope.self, from: data)
      Issue.record("A numeric legacy Date must be rejected.")
    } catch let error as DecodingError {
      guard case .typeMismatch(let type, let context) = error else {
        Issue.record("Expected DecodingError.typeMismatch.")
        return
      }

      #expect(ObjectIdentifier(type) == ObjectIdentifier(String.self))
      #expect(context.debugDescription == "Expected to decode String but found number instead.")
      #expect(context.codingPath.map(\.stringValue) == ["instant"])
      #expect(context.underlyingError == nil)
    } catch {
      Issue.record("HezoJSON used an unexpected wrong-type Date error category.")
    }
  }
}

private struct CanonicalInstantEnvelope: Decodable {
  let instant: CanonicalInstantV1
}

private struct LegacyDateEnvelope: Codable {
  let instant: Date
}

private func requireCanonicalInstantConformances<Value>(_ value: Value)
where
  Value: Codable & Equatable & Sendable & CustomStringConvertible
    & CustomDebugStringConvertible & CustomReflectable
{
  _ = value
}

private func requireCanonicalInstantErrorConformances<Value>(_ value: Value)
where
  Value: Error & Equatable & Sendable & CustomStringConvertible & CustomDebugStringConvertible
    & LocalizedError
{
  _ = value
}

private func expectCanonicalInstantConstructionAndDecodeFailure(
  _ candidate: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(throws: CanonicalInstantContractError.invalidValue, sourceLocation: sourceLocation) {
    try CanonicalInstantV1(validating: candidate)
  }

  do {
    let data = try JSONEncoder().encode(candidate)
    expectCanonicalInstantDecodeFailure(
      from: data,
      rejectedCandidate: candidate,
      sourceLocation: sourceLocation
    )
  } catch {
    Issue.record("The invalid test candidate could not be encoded.", sourceLocation: sourceLocation)
  }
}

private func expectCanonicalInstantDecodeFailure(
  from data: Data,
  rejectedCandidate: String? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try JSONDecoder().decode(CanonicalInstantV1.self, from: data)
    Issue.record("An invalid canonical instant must be rejected.", sourceLocation: sourceLocation)
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
        debugDescription: "Invalid V1 canonical instant."
      )
    )
    let renderings = [String(describing: error), String(reflecting: error)]
    let nsError = error as NSError
    let boundedRenderings =
      renderings
      + [
        error.localizedDescription,
        nsError.localizedDescription,
        String(reflecting: nsError),
      ]
    let expectedRenderings = [
      String(describing: expectedError), String(reflecting: expectedError),
    ]
    #expect(renderings == expectedRenderings, sourceLocation: sourceLocation)
    #expect(
      boundedRenderings.allSatisfy { $0.isEmpty == false && $0.utf8.count <= 512 },
      sourceLocation: sourceLocation
    )
    #expect(
      context.debugDescription == "Invalid V1 canonical instant.",
      sourceLocation: sourceLocation
    )
    #expect(context.codingPath.isEmpty, sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
    if let rejectedCandidate, rejectedCandidate.isEmpty == false {
      #expect(
        boundedRenderings.allSatisfy { $0.contains(rejectedCandidate) == false },
        sourceLocation: sourceLocation
      )
    }
  } catch {
    Issue.record(
      "Canonical-instant decoding used an unexpected error category.",
      sourceLocation: sourceLocation
    )
  }
}

private func expectHezoDateEncodingFailure(
  _ date: Date,
  debugDescription: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  do {
    _ = try HezoJSON.makeEncoder().encode(LegacyDateEnvelope(instant: date))
    Issue.record("An invalid legacy Date must be rejected.", sourceLocation: sourceLocation)
  } catch let error as EncodingError {
    guard case .invalidValue(let rejectedValue, let context) = error else {
      Issue.record("Expected EncodingError.invalidValue.", sourceLocation: sourceLocation)
      return
    }

    let rejectedDate = rejectedValue as? Date
    if date.timeIntervalSince1970.isNaN {
      #expect(rejectedDate?.timeIntervalSince1970.isNaN == true, sourceLocation: sourceLocation)
    } else {
      #expect(rejectedDate == date, sourceLocation: sourceLocation)
    }
    #expect(context.debugDescription == debugDescription, sourceLocation: sourceLocation)
    #expect(context.codingPath.map(\.stringValue) == ["instant"], sourceLocation: sourceLocation)
    #expect(context.underlyingError == nil, sourceLocation: sourceLocation)
  } catch {
    Issue.record(
      "HezoJSON used an unexpected Date encoding error category.",
      sourceLocation: sourceLocation
    )
  }
}
