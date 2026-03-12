//
//  USER_LOGIN.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/18/26.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

final class SignInViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func signIn(email: String, password: String) {
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            DispatchQueue.main.async {
                self?.user = result?.user
            }
        }
    }

    func signUp(email: String,
                password: String,
                name: String,
                username: String) {

        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let createdUser = result?.user else { return }
            let uid = createdUser.uid

            let db = Firestore.firestore()
            db.collection("users").document(uid).setData([
                "name": name,
                "username": username,
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ]) { err in
                if let err = err {
                    DispatchQueue.main.async {
                        self?.errorMessage = err.localizedDescription
                    }
                    return
                }

                DispatchQueue.main.async {
                    self?.user = createdUser
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("Sign out failed \(error)")
        }
    }
}

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isEmployeeMode = false

    @ObservedObject var viewModel: SignInViewModel
    @ObservedObject var employeeViewModel = EmployeeViewModel()

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
