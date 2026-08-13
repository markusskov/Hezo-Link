import Foundation

/// A bounded failure category for a public reason set.
public enum VerdictReasonsError: Error, Equatable, Sendable, CustomStringConvertible {
  /// More than five reasons were supplied.
  case tooManyReasons

  /// A log-safe description that contains no reason content.
  public var description: String {
    "Public verdict reason count exceeds the contract limit."
  }
}

/// Zero through five ordered public verdict reasons.
public struct VerdictReasonsV1: Codable, Equatable, Sendable {
  /// The maximum number of reasons in a public verdict.
  public static let maximumCount = 5

  /// The validated ordered reasons.
  public let values: [VerdictReasonV1]

  /// The number of reasons.
  public var count: Int {
    values.count
  }

  /// Creates a bounded reason set.
  public init(_ values: [VerdictReasonV1]) throws {
    guard values.count <= Self.maximumCount else {
      throw VerdictReasonsError.tooManyReasons
    }
    self.values = values
  }

  /// Decodes at most five reasons without first allocating an unbounded array.
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var values: [VerdictReasonV1] = []
    values.reserveCapacity(Self.maximumCount)

    while container.isAtEnd == false {
      guard values.count < Self.maximumCount else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Public verdict reason count exceeds the contract limit."
        )
      }
      values.append(try container.decode(VerdictReasonV1.self))
    }

    self.values = values
  }

  /// Encodes the reason set as the public JSON array.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for value in values {
      try container.encode(value)
    }
  }
}

/// The source-compatible spelling of the public verdict-reasons collection.
public typealias VerdictReasons = VerdictReasonsV1
