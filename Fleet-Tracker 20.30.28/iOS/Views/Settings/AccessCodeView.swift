//
//  AccessCodeView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccessCodeView: View {
    /// Passed in from AdminMenuView — already loaded on SignInViewModel
    let businessId: String

    @State private var accessCode:    String = ""
    @State private var isLoading      = true
    @State private var isCopied       = false
    @State private var isRegenerating = false
    @State private var errorMessage:  String?

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView("Loading code…")
            } else {
                VStack(spacing: 8) {
                    Text("Employee Access Code")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(accessCode.isEmpty ? "No code set" : accessCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.black.opacity(0.08))
                        .cornerRadius(12)
                        .textSelection(.enabled)
                }

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = accessCode
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy",
                              systemImage: isCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .tint(isCopied ? .green : .primary)

                    Button { regenerateCode() } label: {
                        Label("New Code", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(isRegenerating)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Text("Share this code with new employees during sign-up.\nGenerating a new code immediately invalidates the old one.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear { fetchCode() }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        var code  = ""
        for _ in 0..<12 {
            let i = Int.random(in: 0..<chars.count)
            code.append(chars[chars.index(chars.startIndex, offsetBy: i)])
        }
        return "\(code.prefix(3))-\(code.dropFirst(3).prefix(4))-\(code.dropFirst(7))"
    }

    private func fetchCode() {
        guard !businessId.isEmpty else {
            errorMessage = "Business ID not found. Please sign out and back in."
            isLoading    = false
            return
        }

        db.collection("businesses").document(businessId).getDocument { doc, error in
            DispatchQueue.main.async {
                if let error {
                    errorMessage = error.localizedDescription
                    isLoading    = false
                    return
                }
                let existing = doc?.data()?["accessCode"] as? String ?? ""
                if existing.isEmpty {
                    saveCode(generateCode())
                } else {
                    accessCode = existing
                    isLoading  = false
                }
            }
        }
    }

    private func regenerateCode() {
        isRegenerating = true
        errorMessage   = nil
        saveCode(generateCode())
    }

    private func saveCode(_ code: String) {
        guard !businessId.isEmpty else {
            isRegenerating = false
            isLoading      = false
            return
        }
        db.collection("businesses").document(businessId).updateData([
            "accessCode": code
        ]) { error in
            DispatchQueue.main.async {
                if let error {
                    errorMessage   = error.localizedDescription
                } else {
                    accessCode     = code
                }
                isLoading      = false
                isRegenerating = false
            }
        }
    }
}
