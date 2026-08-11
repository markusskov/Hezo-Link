import HezoLinkCore
import SwiftUI

struct AppShellView: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var inputSession = ManualURLInputSession()
  @AccessibilityFocusState private var isResultFocused: Bool
  @FocusState private var isURLFieldFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(
            "https://iana.org",
            text: boundedSubmittedURL,
            axis: .vertical
          )
          .textContentType(.URL)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .lineLimit(2...5)
          .focused($isURLFieldFocused)
          .submitLabel(.done)
          .onSubmit(validateLocally)
          .accessibilityLabel("Link address")
          .accessibilityIdentifier("manual-url-input")
        } header: {
          Text("Link address")
        } footer: {
          Text("The address stays in this app session. It is not saved, and no request is sent.")
        }

        Section {
          Button(action: validateLocally) {
            Label("Validate locally", systemImage: "checkmark.shield")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .disabled(inputSession.submittedValue.isEmpty)
          .accessibilityIdentifier("manual-url-validate")

          if !inputSession.submittedValue.isEmpty || inputSession.status != nil {
            Button("Clear", action: clear)
              .frame(maxWidth: .infinity)
              .accessibilityIdentifier("manual-url-clear")
          }
        }

        if let status = inputSession.status {
          Section("Local result") {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                  .font(.headline)
                Text(status.detail)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: status.systemImage)
                .foregroundStyle(status.tint)
            }
            .accessibilityElement(children: .combine)
            .accessibilityFocused($isResultFocused)
            .accessibilityIdentifier("manual-url-result")
          }
        }

        Section {
          Label("No network requests", systemImage: "network.slash")
          Label("No history or analytics", systemImage: "eye.slash")
        } header: {
          Text("Prototype limits")
        } footer: {
          Text("The local syntax profile does not say whether a link is safe.")
        }
      }
      .navigationTitle("Check a link")
      .privacySensitive()
      .overlay {
        if scenePhase != .active {
          ContentUnavailableView {
            Label("Hezo Link", systemImage: "lock.fill")
          } description: {
            Text("Link entry is hidden while the app is inactive.")
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(.background)
        }
      }
    }
  }

  private var boundedSubmittedURL: Binding<String> {
    Binding(
      get: { inputSession.submittedValue },
      set: { candidate in
        inputSession.updateSubmission(candidate)
        if inputSession.status == .urlTooLong {
          moveAccessibilityFocusToResult()
          return
        }
        isResultFocused = false
      }
    )
  }

  private func validateLocally() {
    inputSession.validate()
    moveAccessibilityFocusToResult()
  }

  private func clear() {
    inputSession.clear()
    isResultFocused = false
    isURLFieldFocused = true
  }

  private func moveAccessibilityFocusToResult() {
    isResultFocused = false
    Task { @MainActor in
      await Task.yield()
      guard inputSession.status != nil else { return }
      isResultFocused = true
    }
  }
}

private extension ManualURLInputStatus {
  var title: String {
    switch self {
    case .syntaxAccepted:
      "Format accepted"
    case .unsupportedPort:
      "Port not supported"
    case .invalidURL:
      "Check the address"
    case .unsupportedScheme:
      "Use HTTP or HTTPS"
    case .urlTooLong:
      "Address is too long"
    }
  }

  var detail: String {
    switch self {
    case .syntaxAccepted:
      "The address passed the local format checks. Nothing was sent."
    case .unsupportedPort:
      "The address format is valid, but this port is not available for checks."
    case .invalidURL:
      "Enter a complete HTTP or HTTPS address in the supported format."
    case .unsupportedScheme:
      "This prototype accepts only HTTP and HTTPS link addresses."
    case .urlTooLong:
      "Shorten the address before trying again."
    }
  }

  var systemImage: String {
    switch self {
    case .syntaxAccepted:
      "checkmark.circle.fill"
    case .unsupportedPort:
      "exclamationmark.triangle.fill"
    case .invalidURL, .unsupportedScheme, .urlTooLong:
      "xmark.circle.fill"
    }
  }

  var tint: Color {
    switch self {
    case .syntaxAccepted:
      .green
    case .unsupportedPort:
      .orange
    case .invalidURL, .unsupportedScheme, .urlTooLong:
      .red
    }
  }
}

#Preview {
  AppShellView()
}
