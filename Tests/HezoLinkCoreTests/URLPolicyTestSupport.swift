import Testing

struct SafeCase<Payload: Sendable>: Sendable, CustomTestStringConvertible {
  let id: String
  let payload: Payload

  init(_ id: String, payload: Payload) {
    preconditionSafeCaseID(id)
    self.id = id
    self.payload = payload
  }

  var testDescription: String {
    id
  }
}

struct SafeURLCase<Expectation: Sendable>: Sendable, CustomTestStringConvertible {
  let id: String
  let input: String
  let expected: Expectation

  init(_ id: String, input: String, expected: Expectation) {
    preconditionSafeCaseID(id)
    self.id = id
    self.input = input
    self.expected = expected
  }

  var testDescription: String {
    id
  }
}

struct SafeSensitiveValue: Sendable, CustomTestStringConvertible {
  let id: String
  let value: String

  init(_ id: String, value: String) {
    preconditionSafeCaseID(id)
    self.id = id
    self.value = value
  }

  var testDescription: String {
    id
  }
}

private func preconditionSafeCaseID(_ id: String) {
  precondition(
    id.isEmpty == false
      && id.utf8.allSatisfy { byte in
        (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte)
          || (0x61...0x7A).contains(byte) || byte == 0x2D || byte == 0x5F
      },
    "URL-policy case IDs must contain only safe ASCII identifier characters."
  )
}
