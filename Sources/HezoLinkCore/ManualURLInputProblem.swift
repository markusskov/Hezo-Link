import Foundation

private func validatedManualURLProblemCode(_ rawValue: String) -> ProblemCode {
  guard let code = ProblemCode(rawValue: rawValue) else {
    preconditionFailure("An internal manual-URL problem code is invalid.")
  }
  return code
}

private let unsupportedSchemeProblemCode = validatedManualURLProblemCode("unsupported_scheme")
private let urlTooLongProblemCode = validatedManualURLProblemCode("url_too_long")

public extension StableContractValue where Kind == ProblemCodeKind {
  /// The submitted URL uses a syntactically present but unsupported scheme.
  static var unsupportedScheme: Self {
    unsupportedSchemeProblemCode
  }

  /// The submitted URL exceeds the pre-parse UTF-8 byte limit.
  static var urlTooLong: Self {
    urlTooLongProblemCode
  }
}

/// A finite, log-safe problem produced by manual URL input validation.
///
/// Cases intentionally have no associated values, so rejected attacker-controlled text cannot be
/// retained in errors or bridged error metadata.
public enum ManualURLInputProblem: Error, Equatable, Sendable, CustomStringConvertible,
  CustomDebugStringConvertible, LocalizedError
{
  /// The input is not an accepted absolute HTTP(S) URL under the current syntax profile.
  case invalidURL

  /// A syntactically present scheme is not HTTP or HTTPS.
  case unsupportedScheme

  /// The exact input exceeds the 8 KiB UTF-8 limit.
  case urlTooLong

  /// The stable public machine code for this problem.
  public var code: ProblemCode {
    switch self {
    case .invalidURL:
      .invalidURL
    case .unsupportedScheme:
      .unsupportedScheme
    case .urlTooLong:
      .urlTooLong
    }
  }

  /// A bounded description that never includes rejected input or parser diagnostics.
  public var description: String {
    switch self {
    case .invalidURL:
      "The submitted value is not a supported URL."
    case .unsupportedScheme:
      "The submitted URL scheme is unsupported."
    case .urlTooLong:
      "The submitted URL exceeds the local size limit."
    }
  }

  /// A bounded debug description that never includes rejected input or parser diagnostics.
  public var debugDescription: String {
    description
  }

  /// A bounded localized description that never includes rejected input or parser diagnostics.
  public var errorDescription: String? {
    description
  }
}
