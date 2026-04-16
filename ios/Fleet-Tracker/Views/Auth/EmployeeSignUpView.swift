//
//  EmployeeSignUpView.swift
//  Fleet-Tracker
//

import SwiftUI

struct EmployeeSignUpView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username:   String = ""
    @State private var accessCode: String = ""
    @State private var password:   String = ""

    private var isFormValid: Bool {
        !username.isEmpty && !accessCode.isEmpty && password.count >= 6
    }

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        Text("Join Your Fleet")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Enter the access code from your admin.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 36)

                    // ── Card ──────────────────────────────────────────────
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            AuthTextField(
                                icon: "person.fill",
                                placeholder: "Username",
                                text: $username,
                                isSecure: false
                            )

                            AuthTextField(
                                icon: "key.fill",
                                placeholder: "Access Code",
                                text: $accessCode,
                                isSecure: true
                            )

                            AuthTextField(
                                icon: "lock.fill",
                                placeholder: "Password (min 6 chars)",
                                text: $password,
                                isSecure: true
                            )
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Create account button
                        Button {
                            viewModel.signUp(
                                username:   username,
                                accessCode: accessCode,
                                password:   password
                            )
                        } label: {
                            Text("Create Account")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isFormValid ? Color.blue : Color.blue.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!isFormValid)

                        // Cancel
                        Button {
                            dismiss()
                        } label: {
                            Text("Already have an account? Sign In")
                            .foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.employee?.uid) {
            if viewModel.employee != nil { dismiss() }
        }
    }
}
