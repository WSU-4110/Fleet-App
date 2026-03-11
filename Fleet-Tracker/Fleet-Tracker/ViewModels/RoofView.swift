import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        Group {
            if viewModel.user != nil {
                NavigationStack {
                    MapViewWrapper()
                        .navigationTitle("FleetTracker")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Logout") {
                                    viewModel.signOut()
                                }
                            }
                        }
                }
            } else {
                LoginView(viewModel: viewModel)
            }
        }
    }
}
