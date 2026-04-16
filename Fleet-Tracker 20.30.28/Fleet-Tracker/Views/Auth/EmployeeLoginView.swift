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
        VStack(spacing: 12) {
            Text("Employee Login")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Sign In") {
                viewModel.signIn(name: username, password: password)
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || password.isEmpty)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("New Employee? Sign Up") {
                showSignUp = true
            }
            .font(.caption)
            .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showSignUp) {
            EmployeeSignUpView(viewModel: viewModel)
        }
    }
}
