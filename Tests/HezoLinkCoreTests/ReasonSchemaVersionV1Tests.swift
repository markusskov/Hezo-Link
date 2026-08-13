import Foundation
import HezoLinkCore
import Testing

struct ReasonSchemaVersionV1Tests {
  @Test func casesRawValuesOrderAndPublicConformancesAreExact() {
    let versions = ReasonSchemaVersionV1.allCases
    let wireValues = versions.map(\.rawValue)
    let requestVersion: Int = CheckRequestV1.reasonSchemaVersion

    #expect(versions == [.v1])
    #expect(wireValues == [1])
    #expect(Set(wireValues) == [1])
    #expect(wireValues.count == Set(wireValues).count)
    #expect(requestVersion == ReasonSchemaVersionV1.v1.rawValue)
    requireReasonSchemaVersionConformances(ReasonSchemaVersionV1.v1)
  }

  @Test func canonicalVersionEncodesAsTheExactJSONInteger() throws {
    let encoded = try HezoJSON.makeEncoder().encode(ReasonSchemaVersionV1.v1)

    #expect(encoded == Data("1".utf8))
  }

  @Test func publicContractRemainsEncoderOnly() {
    #expect(isReasonSchemaVersionDecodable(ReasonSchemaVersionV1.self) == false)
  }

  @Test func concurrentEncodingIsDeterministic() async throws {
    let expectedEncoding = Data("1".utf8)
    let results = try await withThrowingTaskGroup(of: Data.self) { group in
      for _ in 0..<64 {
        group.addTask {
          try HezoJSON.makeEncoder().encode(ReasonSchemaVersionV1.v1)
        }
      }

      var values: [Data] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(results.count == 64)
    #expect(results.allSatisfy { $0 == expectedEncoding })
  }
}

private func requireReasonSchemaVersionConformances<Value>(_ value: Value)
where
  Value: RawRepresentable & CaseIterable & Encodable & Equatable & Hashable & Sendable,
  Value.RawValue == Int,
  Value.AllCases == [Value]
{
  _ = value
}

private func isReasonSchemaVersionDecodable<Value>(_: Value.Type) -> Bool {
  false
}

private func isReasonSchemaVersionDecodable<Value: Decodable>(_: Value.Type) -> Bool {
  true
}
