//
//  EmployeeViewModel.swift
//  Fleet-Tracker
//
//  Created by Ashley Li on 3/12/26.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class EmployeeViewModel: ObservableObject {
    @Published var employee: EmployeeModel?
    @Published var errorMessage: String?
    @Published var isClockedIn: Bool = false
    @Published var clockInTime: Date?

    private let db = Firestore.firestore()

    func signUp(username: String, accessCode: String, password: String) { // access code
        errorMessage = nil

        db.collection("users").whereField("accessCode", isEqualTo: accessCode.uppercased())
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if snapshot?.documents.isEmpty == true {
                    DispatchQueue.main.async {
                        self.errorMessage = "Invalid access code"
                    }
                    return
                }

                let loginEmail = "\(username.lowercased().replacingOccurrences(of: " ", with: "_"))@fleettracker.com"

                Auth.auth().createUser(withEmail: loginEmail, password: password) { result, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }

                    guard let uid = result?.user.uid else { return }

                    self.db.collection("employees").document(uid).setData([
                        "username": username,
                        "uid": uid,
                        "createdAt": FieldValue.serverTimestamp(),
                        "isClockedIn": false
                    ]) { err in
                        DispatchQueue.main.async {
                            if let err = err {
                                self.errorMessage = err.localizedDescription
                            } else {
                                self.employee = EmployeeModel(uid: uid, name: username)
                            }
                        }
                    }
                }
            }
    }

    func signIn(name: String, password: String) { // employees sign in
        errorMessage = nil

        let loginEmail = "\(name.lowercased().replacingOccurrences(of: " ", with: "_"))@fleettracker.com"

        Auth.auth().signIn(withEmail: loginEmail, password: password) { [weak self] result, error in
            if error != nil {
                DispatchQueue.main.async {
                    self?.errorMessage = "Invalid username or password"
                }
                return
            }

            guard let uid = result?.user.uid else { return }
            self?.fetchEmployee(uid: uid)
        }
    }

    func fetchEmployee(uid: String) {
        db.collection("employees").document(uid).getDocument { [weak self] doc, _ in
            guard let data = doc?.data() else { return }
            DispatchQueue.main.async {
                self?.employee = EmployeeModel(uid: uid, name: data["name"] as? String ?? "")
                self?.isClockedIn = data["isClockedIn"] as? Bool ?? false
                if let ts = data["clockInTime"] as? Timestamp {
                    self?.clockInTime = ts.dateValue()
                }
            }
        }
    }

    func clockIn() { // clock In
        guard let uid = employee?.uid else { return }
        let now = Date()

        db.collection("employees").document(uid).updateData([
            "isClockedIn": true,
            "clockInTime": Timestamp(date: now)
        ]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isClockedIn = true
                self?.clockInTime = now
            }
        }

        db.collection("timesheets").addDocument(data: [
            "uid": uid,
            "name": employee?.name ?? "",
            "clockIn": Timestamp(date: now),
            "clockOut": NSNull()
        ])
    }

    func clockOut() { // clokc out
        guard let uid = employee?.uid else { return }
        let now = Date()

        db.collection("employees").document(uid).updateData([
            "isClockedIn": false,
            "clockOutTime": Timestamp(date: now)
        ]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isClockedIn = false
                self?.clockInTime = nil
            }
        }

        db.collection("timesheets")
            .whereField("uid", isEqualTo: uid)
            .whereField("clockOut", isEqualTo: NSNull())
            .getDocuments { snapshot, _ in
                snapshot?.documents.last?.reference.updateData([
                    "clockOut": Timestamp(date: now)
                ])
            }
    }

    func signOut() {
        try? Auth.auth().signOut()
        employee = nil
        isClockedIn = false
        clockInTime = nil
    }
}
