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

    func signUp(email: String, password: String, name: String, username: String) {
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

            // Build UsersModel with empty location arrays
            let newUser = UsersModel(
                name: name,
                latitude: [],
                longitude: [],
                locationTime: [],
                username: username,
                password: password,
                email: email
            )

            do {
                try Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(from: newUser) { err in
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
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error encoding user data: \(error.localizedDescription)"
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("Sign out failed: \(error)")
        }
    }
}

//final class SignInViewModel: ObservableObject {
//    @Published var user: User?            // tracks our user
//    @Published var errorMessage: String?  // errors
//
//    func signIn(email: String, password: String) {
//        errorMessage = nil
//
//        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    self?.errorMessage = error.localizedDescription
//                }
//                return
//            }
//
//            DispatchQueue.main.async {
//                self?.user = result?.user // update state on successful login
//            }
//        }
//    }
//
//    func signUp(email: String,
//                password: String,
//                name: String,
//                username: String) {
//
//        errorMessage = nil
//
//        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    self?.errorMessage = error.localizedDescription
//                }
//                return
//            }
//
//            guard let createdUser = result?.user else { return }
//            let uid = createdUser.uid
//
//            // Save extra user info in Firestore
//            let db = Firestore.firestore()
//            db.collection("users").document(uid).setData([
//                "name": name,
//                "username": username,
//                "email": email,
//                "createdAt": FieldValue.serverTimestamp()
//            ]) { err in
//                if let err = err {
//                    DispatchQueue.main.async {
//                        self?.errorMessage = err.localizedDescription
//                    }
//                    return
//                }
//
//                // Update UI state so RootView can switch immediately
//                DispatchQueue.main.async {
//                    self?.user = createdUser
//                }
//            }
//        }
//    }
//    func signOut()  {
//        do{
//            try Auth.auth().signOut()
//            self.user=nil
//        }
//        catch{
//            print("Sign out failed /(error)")
//        }
//    }
//}
struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""

    @ObservedObject var viewModel: SignInViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
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
            .padding()
        }
    }
}
