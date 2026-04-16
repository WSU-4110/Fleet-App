//
//  LoginView.swift
//  Fleet-Tracker
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isEmployeeMode = false

    @ObservedObject var viewModel: SignInViewModel
    @ObservedObject var employeeViewModel: EmployeeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Login Type", selection: $isEmployeeMode) {
                    Text("Admin").tag(false)
                    Text("Employee").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)

                if isEmployeeMode {
                    EmployeeLoginView(viewModel: employeeViewModel)
                } else {
                    Text("Login with email")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled(true)

                    Button("Login") {
                        viewModel.signIn(email: email, password: password)
                    }
                    .buttonStyle(.borderedProminent)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    NavigationLink("Sign Up") {
                        SignUpView(viewModel: viewModel)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }
}
