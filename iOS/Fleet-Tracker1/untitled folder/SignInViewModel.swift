//
//  SignInViewModel.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class SignInViewModel: ObservableObject {
    @Published var user: User?
    @Published var businessId: String?
    @Published var subscriptionStatus: String = "active"  // "active" | "cancelled"
    @Published var currentPlan: String = "Pro"
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                if let uid = user?.uid {
                    self?.fetchBusinessId(adminUID: uid)
                } else {
                    self?.businessId = nil
                }
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // ── Fetch businessId ─────────────────────────────────────────────────────

    func fetchBusinessId(adminUID: String) {
        db.collection("users").document(adminUID).getDocument { [weak self] doc, _ in
            guard let self else { return }
            guard let bid = doc?.data()?["businessId"] as? String else { return }
            DispatchQueue.main.async { self.businessId = bid }

            // Also fetch subscription status from the business doc
            self.db.collection("businesses").document(bid).getDocument { bDoc, _ in
                DispatchQueue.main.async {
                    self.subscriptionStatus = bDoc?.data()?["subscriptionStatus"] as? String ?? "active"
                    self.currentPlan        = bDoc?.data()?["plan"] as? String ?? "Pro"
                }
            }
        }
    }

    // ── Sign in with username ─────────────────────────────────────────────────
    // Looks up the email stored against this username in Firestore,
    // then signs in with Firebase Auth using that email + password.

    func signIn(username: String, password: String) {
        errorMessage = nil

        // Direct document lookup — no query, no index needed
        db.collection("usernameIndex").document(username.lowercased()).getDocument { [weak self] doc, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }

            guard let email = doc?.data()?["email"] as? String else {
                DispatchQueue.main.async { self.errorMessage = "Username not found." }
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    if error != nil {
                        self.errorMessage = "Invalid username or password."
                    } else {
                        self.user = result?.user
                    }
                }
            }
        }
    }

    // ── Sign up ───────────────────────────────────────────────────────────────

    func signUp(email: String, password: String, name: String, username: String, plan: String = "Pro") {
        errorMessage = nil

        // Check username isn't already taken — direct doc lookup, no index needed
        db.collection("usernameIndex").document(username.lowercased()).getDocument { [weak self] doc, _ in
                guard let self else { return }

                if doc?.exists == true {
                    DispatchQueue.main.async { self.errorMessage = "Username already taken." }
                    return
                }

                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error {
                        DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                        return
                    }
                    guard let createdUser = result?.user else { return }
                    let uid        = createdUser.uid
                    let accessCode = self.generateAccessCode()
                    let businessRef = self.db.collection("businesses").document()
                    let businessId  = businessRef.documentID
                    let batch       = self.db.batch()

                    batch.setData([
                        "ownerId":            uid,
                        "ownerName":          name,
                        "plan":               plan,
                        "subscriptionStatus": "active",
                        "accessCode":         accessCode,
                        "createdAt":          FieldValue.serverTimestamp()
                    ], forDocument: businessRef)

                    let userRef = self.db.collection("users").document(uid)
                    batch.setData([
                        "name":       name,
                        "username":   username,
                        "email":      email,
                        "businessId": businessId,
                        "createdAt":  FieldValue.serverTimestamp()
                    ], forDocument: userRef)

                    // Username index — direct lookup doc so login needs no query or index
                    let usernameRef = self.db.collection("usernameIndex").document(username.lowercased())
                    batch.setData(["email": email, "uid": uid], forDocument: usernameRef)

                    batch.commit { err in
                        DispatchQueue.main.async {
                            if let err { self.errorMessage = err.localizedDescription }
                            else       { self.businessId = businessId; self.user = createdUser }
                        }
                    }
                }
            }
    }

    // ── Sign out ─────────────────────────────────────────────────────────────

    func signOut() {
        do {
            try Auth.auth().signOut()
            user       = nil
            businessId = nil
        } catch {
            print("Sign out failed: \(error)")
        }
    }

    // ── Cancel subscription ──────────────────────────────────────────────────

    func cancelSubscription(completion: @escaping (Bool) -> Void) {
        guard let bid = businessId else { completion(false); return }
        db.collection("businesses").document(bid).updateData([
            "subscriptionStatus": "cancelled",
            "cancelledAt":        FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil { self?.subscriptionStatus = "cancelled" }
                completion(error == nil)
            }
        }
    }

    // ── Upgrade plan ─────────────────────────────────────────────────────────

    func upgradePlan(to plan: String, completion: @escaping (Bool) -> Void) {
        guard let bid = businessId else { completion(false); return }
        db.collection("businesses").document(bid).updateData([
            "plan":      plan,
            "upgradedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil { self?.currentPlan = plan }
                completion(error == nil)
            }
        }
    }

    // ── Resubscribe ──────────────────────────────────────────────────────────

    func resubscribe(plan: String, completion: @escaping (Bool) -> Void) {
        guard let bid = businessId else { completion(false); return }
        db.collection("businesses").document(bid).updateData([
            "subscriptionStatus": "active",
            "plan":               plan,
            "resubscribedAt":     FieldValue.serverTimestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.subscriptionStatus = "active"
                    self?.currentPlan        = plan
                }
                completion(error == nil)
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private func generateAccessCode() -> String {
        let chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        var code  = ""
        for _ in 0..<12 {
            let i = Int.random(in: 0..<chars.count)
            code.append(chars[chars.index(chars.startIndex, offsetBy: i)])
        }
        return "\(code.prefix(3))-\(code.dropFirst(3).prefix(4))-\(code.dropFirst(7))"
    }
}
