//
//  EmployeeSignUpView.swift
//  Fleet-Tracker
//

import SwiftUI

struct EmployeeSignUpView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username: String   = ""
    @State private var accessCode: String = ""
    @State private var password: String   = ""

    private var isFormValid: Bool {
        !username.isEmpty && !accessCode.isEmpty && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Employee Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)

                SecureField("Access Code", text: $accessCode)
                    .textFieldStyle(.roundedBorder)

                SecureField("Create Password (min 6 chars)", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("Create Account") {
                    viewModel.signUp(username: username, accessCode: accessCode, password: password)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.employee?.uid) {
                if viewModel.employee != nil { dismiss() }
            }
        }
    }
}
