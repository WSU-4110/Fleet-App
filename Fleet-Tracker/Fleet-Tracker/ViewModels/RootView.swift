import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var viewModel = SignInViewModel()
    @StateObject var locationTrackerVM = LocationTrackerViewModel()

    var body: some View {
        Group {
            if viewModel.user != nil {
                NavigationStack {
                    MapViewWrapper()
                        .environmentObject(locationTrackerVM)
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
