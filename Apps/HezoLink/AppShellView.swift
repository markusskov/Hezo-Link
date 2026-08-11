import SwiftUI

struct AppShellView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label("Hezo Link", systemImage: "link.badge.plus")
      } description: {
        Text("The local development shell is ready.")
      }
      .navigationTitle("Hezo Link")
    }
  }
}

#Preview {
  AppShellView()
}
