//
//  EmployeeView.swift
//  Fleet-Tracker
//
//  Created by Ashley Li on 3/12/26.
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

struct EmployeeSignUpView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username: String = ""
    @State private var accessCode: String = ""
    @State private var password: String = ""

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

struct ClockInView: View {
    @ObservedObject var viewModel: EmployeeViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome, \(viewModel.employee?.name ?? "")!")
                .font(.headline)
                .foregroundColor(.white)

            if let clockInTime = viewModel.clockInTime {
                Text("Clocked in at \(clockInTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button {
                if viewModel.isClockedIn {
                    viewModel.clockOut()
                } else {
                    viewModel.clockIn()
                }
            } label: {
                Label(
                    viewModel.isClockedIn ? "Clock Out" : "Clock In",
                    systemImage: viewModel.isClockedIn ? "clock.badge.xmark" : "clock.badge.checkmark"
                )
                .padding(10)
                .background(viewModel.isClockedIn ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button("Sign Out") {
                viewModel.signOut()
            }
            .font(.caption)
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}
