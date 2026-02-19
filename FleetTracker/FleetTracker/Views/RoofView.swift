//
//  RoofView.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/18/26.
//
import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        if viewModel.user != nil {
            NavigationStack {
                MapScreen()
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
