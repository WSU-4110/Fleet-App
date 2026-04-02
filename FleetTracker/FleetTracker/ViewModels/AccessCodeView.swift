//
//  AccessCodeView.swift
//  Fleet-Tracker
//
//  Created by Ashley Li on 3/12/26.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccessCodeView: View {
    @State private var accessCode: String = ""
    @State private var newCode: String = ""
    @State private var isSaved = false
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
            } else {
                Text("Current Code")
                    .font(.headline)

                Text(accessCode.isEmpty ? "No code set" : accessCode)
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)

                TextField("Set new code", text: $newCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .frame(width: 200)

                Button("Update Code") {
                    saveCode()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newCode.isEmpty)

                if isSaved {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .onAppear { fetchCode() }
    }

    func fetchCode() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { doc, _ in
            DispatchQueue.main.async {
                accessCode = doc?.data()?["accessCode"] as? String ?? ""
                isLoading = false
            }
        }
    }

    func saveCode() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "accessCode": newCode.uppercased()
        ]) { _ in
            DispatchQueue.main.async {
                accessCode = newCode.uppercased()
                newCode = ""
                isSaved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSaved = false
                }
            }
        }
    }
}
