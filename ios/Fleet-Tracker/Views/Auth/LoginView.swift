//
//  LoginView.swift
//  Fleet-Tracker
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isEmployeeMode   = false

    @ObservedObject var viewModel: SignInViewModel
    @ObservedObject var employeeViewModel: EmployeeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background gradient ───────────────────────────────────
                LinearGradient(
                    colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // ── Logo area ─────────────────────────────────────
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 90, height: 90)
                                Image(systemName: "truck.box.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            Text("Fleet Tracker")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Manage your fleet, anywhere.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                        // ── Card ──────────────────────────────────────────
                        VStack(spacing: 24) {

                            // Role picker
                            HStack(spacing: 0) {
                                roleTab(title: "Admin", selected: !isEmployeeMode) {
                                    withAnimation(.spring(duration: 0.2)) { isEmployeeMode = false }
                                }
                                roleTab(title: "Employee", selected: isEmployeeMode) {
                                    withAnimation(.spring(duration: 0.2)) { isEmployeeMode = true }
                                }
                            }
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            if isEmployeeMode {
                                EmployeeLoginView(viewModel: employeeViewModel)
                            } else {
                                adminLoginFields
                            }
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
        }
    }

    // ── Admin login fields ────────────────────────────────────────────────────

    private var adminLoginFields: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Welcome back")
                    .font(.title2).fontWeight(.bold)
                Text("Sign in to your admin account")
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
                viewModel.signIn(username: username, password: password)
            } label: {
                Text("Sign In")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        username.isEmpty || password.isEmpty
                        ? Color.blue.opacity(0.4)
                        : Color.blue
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(username.isEmpty || password.isEmpty)

            NavigationLink {
                SignUpView(viewModel: viewModel)
            } label: {
                Text("Don't have an account? Sign Up")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
    }

    // ── Role tab ──────────────────────────────────────────────────────────────

    private func roleTab(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(selected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color(.systemBackground).opacity(0.9) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(3)
        }
        .buttonStyle(.plain)
    }
}

// ── Shared auth text field ────────────────────────────────────────────────────

struct AuthTextField: View {
    let icon:        String
    let placeholder: String
    @Binding var text: String
    let isSecure:    Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
            } else {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// ── Hex color helper ──────────────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
