//
//  USER_SIGNUP.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/19/26.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: SignInViewModel

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)

                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled(true)

                    SecureField("Password (min 6 chars)", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    Button("Create Account") {
                        viewModel.signUp(
                            email: email,
                            password: password,
                            name: name,
                            username: username
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
        }
    }
}
