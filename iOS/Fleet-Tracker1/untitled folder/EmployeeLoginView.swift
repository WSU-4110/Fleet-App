//
//  EmployeeLoginView.swift
//  Fleet-Tracker
//

import SwiftUI

struct EmployeeLoginView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showSignUp = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Welcome back")
                    .font(.title2).fontWeight(.bold)
                Text("Sign in to your driver account")
                    .font(.caption).foregroundColor(.secondary)
            }

            AuthTextField(icon: "person.fill", placeholder: "Username",
                          text: $username, isSecure: false)
            AuthTextField(icon: "lock.fill", placeholder: "Password",
                          text: $password, isSecure: true)

            if let err = viewModel.errorMessage {
                Text(err).font(.caption).foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                viewModel.signIn(name: username, password: password)
            } label: {
                Text("Sign In")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        username.isEmpty || password.isEmpty
                        ? Color.blue.opacity(0.4) : Color.blue
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(username.isEmpty || password.isEmpty)

            Button {
                showSignUp = true
            } label: {
                Text("New driver? Sign Up")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .sheet(isPresented: $showSignUp) {
            EmployeeSignUpView(viewModel: viewModel)
        }
    }
}
