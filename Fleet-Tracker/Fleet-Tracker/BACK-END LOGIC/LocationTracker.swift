import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Combine

@MainActor
class LocationTrackerViewModel: ObservableObject {
    @Published var currentUser: UsersModel?
    @Published var isSubmitted = false
    @Published var submissionError: String?
    var lastSavedDate: Date? = nil
    
    var name = ""
    var latitude = ""
    var longitude = ""
    var locationTime = ""
    var currentDate = Date()
    
    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

//    func fetchUserData() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("User is not authenticated.")
//            return
//        }
//
//        Firestore.firestore().collection("users").document(userID).getDocument { document, error in
//            if let error = error {
//                print("Error fetching user data: \(error.localizedDescription)")
//                return
//            }
//
//            guard let data = document?.data() else {
//                print("No data found for the user.")
//                return
//            }
//
//            do {
//                let employee = try Firestore.Decoder().decode(UsersModel.self, from: data)
//                DispatchQueue.main.async {
//                    self.currentUser = employee
//                }
//            } catch {
//                print("Error decoding employee data: \(error.localizedDescription)")
//            }
//        }
//    }
    func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not authenticated.")
            return
        }

        Firestore.firestore().collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            // ✅ If document exists, decode it
            if let data = document?.data(), !data.isEmpty {
                do {
                    let employee = try Firestore.Decoder().decode(UsersModel.self, from: data)
                    DispatchQueue.main.async {
                        self.currentUser = employee
                        print("✅ User loaded: \(employee.name)")
                    }
                } catch {
                    print("Error decoding employee data: \(error.localizedDescription)")
                    // ✅ Decoding failed, create a fresh document
                    self.createEmptyUserDocument(userID: userID)
                }
            } else {
                // ✅ Document doesn't exist, create it
                print("No document found, creating one...")
                self.createEmptyUserDocument(userID: userID)
            }
        }
    }

    // ✅ Creates a blank user document in Firestore
    func createEmptyUserDocument(userID: String) {
        let emptyUser = UsersModel()

        do {
            try Firestore.firestore()
                .collection("users")
                .document(userID)
                .setData(from: emptyUser, merge: true) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("✅ Empty user document created")
                        DispatchQueue.main.async {
                            self.currentUser = emptyUser
                        }
                    }
                }
        } catch {
            print("Error encoding empty user: \(error.localizedDescription)")
        }
    }
    
    func addLocation(locationTime: String, latitude: String, longitude: String) {
        guard let user = currentUser else {
            print("❌ currentUser is nil - call fetchUserData() first")
            return
        }

        // ✅ Only save every 5 minutes
        let now = Date()
        if let lastSaved = lastSavedDate, now.timeIntervalSince(lastSaved) < 5 {
            return  // Skip if less than 5 minutes has passed
        }
        lastSavedDate = now

        var updatedUser = user
        updatedUser.locationTime.append(locationTime)
        updatedUser.latitude.append(latitude)
        updatedUser.longitude.append(longitude)

        currentUser = updatedUser

        saveToFirebase(
            latitude: updatedUser.latitude,
            longitude: updatedUser.longitude,
            locationTime: updatedUser.locationTime
        )
    }


    func saveToFirebase(latitude: [String], longitude: [String], locationTime: [String]) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        // ✅ Fixed: removed unnecessary getDocuments, write directly
        Firestore.firestore().collection("users").document(userID).setData([
            "locationTime": locationTime,
            "latitude": latitude,
            "longitude": longitude
        ], merge: true) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            } else {
                print("Location successfully updated!")
            }
        }
    }

    func submitData() {
        guard !name.isEmpty else {
            submissionError = "All fields are required."
            return
        }

        guard let userID = Auth.auth().currentUser?.uid else {
            submissionError = "User not logged in."
            return
        }
        let newEmployee = UsersModel()

        do {
            try Firestore.firestore()
                .collection("users")
                .document(userID)
                .setData(from: newEmployee) { error in
                    if let error = error {
                        self.submissionError = "Error saving data: \(error.localizedDescription)"
                    } else {
                        self.isSubmitted = true
                        self.submissionError = nil
                        print("Employee data successfully written to Firestore.")
                    }
                }
        } catch {
            submissionError = "Error encoding employee data: \(error.localizedDescription)"
        }
    }
}
