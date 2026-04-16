//
//  SignUpView.swift
//  Fleet-Tracker
//

import SwiftUI

// ── Step tracker ─────────────────────────────────────────────────────────────

private enum SignUpStep {
    case plan, account, payment
}

private enum PaymentMethod {
    case card, applePay, googlePay
}

// ── Root container ────────────────────────────────────────────────────────────

struct SignUpView: View {
    @ObservedObject var viewModel: SignInViewModel
    @Environment(\.dismiss) var dismiss

    @State private var step: SignUpStep = .plan

    @State private var name:     String = ""
    @State private var username: String = ""
    @State private var email:    String = ""
    @State private var password: String = ""
    @State private var selectedPlan: SubscriptionPlan = .pro

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .plan:
                    PlanPickerStep(selected: $selectedPlan, onDismiss: { dismiss() }) {
                        step = .account
                    }

                case .account:
                    AccountDetailsStep(
                        name: $name, username: $username,
                        email: $email, password: $password,
                        plan: selectedPlan,
                        onBack: { step = .plan },
                        onNext: { step = .payment }
                    )

                case .payment:
                    PaymentStep(
                        plan: selectedPlan,
                        viewModel: viewModel,
                        name: name, username: username,
                        email: email, password: password,
                        onBack: { step = .account }
                    )
                }
            }
        }
        .onChange(of: viewModel.user) {
            if viewModel.user != nil { dismiss() }
        }
    }
}

// ── Step 1: Plan picker ───────────────────────────────────────────────────────

private struct PlanPickerStep: View {
    @Binding var selected: SubscriptionPlan
    var onDismiss: () -> Void
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Choose a Plan")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Start your 14-day free trial. Cancel anytime.")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                ForEach(SubscriptionPlan.allCases) { plan in
                    PlanCard(plan: plan, isSelected: selected == plan)
                        .onTapGesture { selected = plan }
                }

                Button("Continue") { onNext() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Choose a Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onDismiss() }
            }
        }
    }
}

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.rawValue).font(.headline)
                    Text(plan.price).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue).font(.title2)
                }
            }

            Text(plan.driverLimit)
                .font(.caption).foregroundColor(.secondary)

            Divider()

            ForEach(plan.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.08),
                        radius: isSelected ? 8 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// ── Step 2: Account details ───────────────────────────────────────────────────

private struct AccountDetailsStep: View {
    @Binding var name:     String
    @Binding var username: String
    @Binding var email:    String
    @Binding var password: String
    let plan: SubscriptionPlan
    var onBack: () -> Void
    var onNext: () -> Void

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Account Details")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("\(plan.rawValue) plan · \(plan.price)")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(spacing: 12) {
                    AuthTextField(icon: "person.fill",        placeholder: "Full Name",           text: $name,     isSecure: false)
                    AuthTextField(icon: "at",                 placeholder: "Username",            text: $username, isSecure: false)
                    AuthTextField(icon: "envelope.fill",      placeholder: "Email",               text: $email,    isSecure: false)
                    AuthTextField(icon: "lock.fill",          placeholder: "Password (min 6 chars)", text: $password, isSecure: true)
                }

                HStack(spacing: 12) {
                    Button("Back") { onBack() }
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Continue") { onNext() }
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.blue : Color.blue.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!isValid)
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }
}

// ── Step 3: Payment ───────────────────────────────────────────────────────────

private struct PaymentStep: View {
    let plan: SubscriptionPlan
    @ObservedObject var viewModel: SignInViewModel
    let name: String
    let username: String
    let email: String
    let password: String
    var onBack: () -> Void

    @State private var selectedMethod: PaymentMethod = .card
    @State private var cardNumber:  String = ""
    @State private var expiry:      String = ""
    @State private var cvv:         String = ""
    @State private var cardName:    String = ""
    @State private var isProcessing = false

    private var cardIsValid: Bool {
        cardNumber.filter(\.isNumber).count == 16 &&
        expiry.count == 5 &&
        cvv.filter(\.isNumber).count == 3 &&
        !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSubscribe: Bool {
        selectedMethod == .card ? cardIsValid : true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Payment")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("\(plan.rawValue) · \(plan.price)")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                // ── Method selector ───────────────────────────────────────
                VStack(spacing: 10) {
                    Text("Payment Method")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        PaymentMethodButton(
                            label: "Credit Card",
                            icon: "creditcard.fill",
                            color: .blue,
                            isSelected: selectedMethod == .card
                        ) { selectedMethod = .card }

                        PaymentMethodButton(
                            label: "Apple Pay",
                            icon: "applelogo",
                            color: .black,
                            isSelected: selectedMethod == .applePay
                        ) { selectedMethod = .applePay }

                        PaymentMethodButton(
                            label: "Google Pay",
                            icon: "g.circle.fill",
                            color: .green,
                            isSelected: selectedMethod == .googlePay
                        ) { selectedMethod = .googlePay }
                    }
                }

                // ── Card fields (only when card selected) ─────────────────
                if selectedMethod == .card {
                    CardPreviewView(cardNumber: cardNumber, cardName: cardName, expiry: expiry)

                    VStack(spacing: 10) {
                        TextField("Name on card", text: $cardName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)

                        TextField("Card number", text: $cardNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .onChange(of: cardNumber) { cardNumber = formatCardNumber(cardNumber) }

                        HStack(spacing: 12) {
                            TextField("MM/YY", text: $expiry)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .onChange(of: expiry) { expiry = formatExpiry(expiry) }

                            SecureField("CVV", text: $cvv)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .onChange(of: cvv) { if cvv.count > 3 { cvv = String(cvv.prefix(3)) } }
                        }
                    }
                }

                // ── Apple Pay / Google Pay placeholder ────────────────────
                if selectedMethod == .applePay || selectedMethod == .googlePay {
                    VStack(spacing: 8) {
                        Group {
                    if selectedMethod == .applePay {
                        Text("")
                            .font(.system(size: 44, weight: .medium))
                    } else {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 44))
                    }
                }
                            .font(.system(size: 44))
                            .foregroundColor(selectedMethod == .applePay ? .black : .green)

                        Text(selectedMethod == .applePay ? "Apple Pay" : "Google Pay")
                            .font(.headline)

                        Text("You'll be redirected to complete\npayment securely.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(14)
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption)
                }

                HStack(spacing: 12) {
                    Button("Back") { onBack() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(isProcessing)

                    Button {
                        processPaymentAndSignUp()
                    } label: {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Subscribe")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubscribe || isProcessing)
                }

                Label("Secured with 256-bit encryption", systemImage: "lock.fill")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private func processPaymentAndSignUp() {
        isProcessing = true
        viewModel.errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            viewModel.signUp(
                email: email, password: password,
                name: name, username: username,
                plan: plan.rawValue
            )
            isProcessing = false
        }
    }

    private func formatCardNumber(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(16))
        return stride(from: 0, to: digits.count, by: 4).map { i -> String in
            let start = digits.index(digits.startIndex, offsetBy: i)
            let end   = digits.index(start, offsetBy: min(4, digits.count - i))
            return String(digits[start..<end])
        }.joined(separator: " ")
    }

    private func formatExpiry(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(4))
        if digits.count > 2 { return "\(digits.prefix(2))/\(digits.dropFirst(2))" }
        return digits
    }
}

// ── Payment method button ─────────────────────────────────────────────────────

private struct PaymentMethodButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                iconView
                    .frame(width: 28, height: 28)
                Text(label)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.systemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1.5)
            )
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if icon == "applelogo" {
            Image("ApplePayLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .colorInvert()   // invert so black → white on dark bg
                .opacity(isSelected ? 1 : 0)   // show inverted when selected
                .overlay(
                    Image("ApplePayLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .opacity(isSelected ? 0 : 1)   // show original when not selected
                )
                .allowsHitTesting(false)
        } else {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : color)
        }
    }
}

// ── Card preview ──────────────────────────────────────────────────────────────

private struct CardPreviewView: View {
    let cardNumber: String
    let cardName:   String
    let expiry:     String

    private var displayNumber: String {
        let digits = String(cardNumber.filter(\.isNumber).prefix(16))
        let padded = digits + String(repeating: "•", count: max(0, 16 - digits.count))
        return stride(from: 0, to: 16, by: 4)
            .map { String(padded.dropFirst($0).prefix(4)) }
            .joined(separator: " ")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.85), Color.indigo],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(height: 190)
                .shadow(radius: 8)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Fleet Tracker")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text(displayNumber)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARD HOLDER")
                            .font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text(cardName.isEmpty ? "YOUR NAME" : cardName.uppercased())
                            .font(.caption).fontWeight(.medium).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXPIRES")
                            .font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text(expiry.isEmpty ? "MM/YY" : expiry)
                            .font(.caption).fontWeight(.medium).foregroundColor(.white)
                    }
                }
            }
            .padding(24)
        }
        .padding(.horizontal, 4)
    }
}
