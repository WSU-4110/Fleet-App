//
//  AccessCodeView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccessCodeView: View {
    @State private var accessCode: String = ""
    @State private var isLoading = true
    @State private var isCopied = false
    @State private var isRegenerating = false

    private let db = Firestore.firestore()

    // Generates a cryptographically random 12-character code using
    // uppercase letters + digits, excluding visually ambiguous chars
    // (0, O, 1, I, L) to reduce transcription errors.
    private func generateCode() -> String {
        let chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        var code = ""
        for _ in 0..<12 {
            let index = Int.random(in: 0..<chars.count)
            code.append(chars[chars.index(chars.startIndex, offsetBy: index)])
        }
        // Format as XXX-XXXX-XXXXX for readability
        let a = String(code.prefix(3))
        let b = String(code.dropFirst(3).prefix(4))
        let c = String(code.dropFirst(7))
        return "\(a)-\(b)-\(c)"
    }

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView()
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
                    // Copy to clipboard
                    Button {
                        UIPasteboard.general.string = accessCode
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .tint(isCopied ? .green : .primary)

                    // Regenerate
                    Button {
                        regenerateCode()
                    } label: {
                        Label("New Code", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(isRegenerating)
                }

                Text("Share this code with new employees during sign-up.\nGenerate a new code at any time — old codes stop working immediately.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear { fetchCode() }
    }

    func fetchCode() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { doc, _ in
            DispatchQueue.main.async {
                let existing = doc?.data()?["accessCode"] as? String ?? ""
                if existing.isEmpty {
                    // First launch — auto-generate one
                    let newCode = generateCode()
                    saveCode(newCode)
                } else {
                    accessCode = existing
                    isLoading = false
                }
            }
        }
    }

    func regenerateCode() {
        isRegenerating = true
        let newCode = generateCode()
        saveCode(newCode)
    }

    func saveCode(_ code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "accessCode": code
        ]) { _ in
            DispatchQueue.main.async {
                accessCode = code
                isLoading = false
                isRegenerating = false
            }
        }
    }
}
