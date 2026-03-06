//
//  EmployeeViewModel.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/18/26.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Combine

enum EmployeeAuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum EmployeeAuthenticationFlow{
    case login
    case signUp
}

@MainActor
class EmployeeViewModel: ObservableObject{
    @AppStorage("isSubmitted") var isSubmitted: Bool = false
    @Published var email = ""
    @Published var password = ""
    @Published var flow: EmployeeAuthenticationFlow = .login
    @Published var isValid  = false
    @Published var employeeAuthenticationState: EmployeeAuthenticationState = .unauthenticated
    @Published var user: User?
    @Published var displayName = ""
    @Published var name = ""
    @Published var latitude = ""
    @Published var longitude = ""
    @Published var locationTime = ""
    @Published var errorMessage = ""
    @Published var submissionError: String?
    @Published var isGuestUser = false
    @Published var isVerified = false
    @Published var currentUser: EmployeeModel?
    @Published var builder = EmployeeModelBuilder()
//    @Published var latitude: [String] = []
    var currentDate = Date()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    init(){
        registerAuthStateHandler()
        
        $email
            .map { email in
                !email.isEmpty
            }
            .assign(to: &$isValid)
        $password
            .map { password in
                !password.isEmpty
            }
            .assign(to: &$isValid)
        
        $user
            .compactMap { user in
                user?.isAnonymous
            }
            .assign(to: &$isGuestUser)
        
        $user
            .compactMap { user in
                user?.isEmailVerified
            }
            .assign(to: &$isVerified)
    }
    
    private var employeeAuthStateHandler: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler() {
        if employeeAuthStateHandler == nil {
            employeeAuthStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.employeeAuthenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.email ?? ""
                self.email = user?.email ?? ""
                //self.password = user?.password ?? ""
                if user != nil {
                    self.fetchUserData()
                }
            }
        }
    }
    
    func switchFlow() {
        flow = flow == .login ? .signUp : .login
        errorMessage = ""
    }
    
    private func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func reset() {
        flow = .login
        email = ""
        password = ""
        errorMessage = ""
    }
    
}

extension EmployeeViewModel {
   
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Error here: \(error.localizedDescription)")
            } else {
                print("✅ Registered user \(self.email) with password \(self.password)")
                self.employeeAuthenticationState = .authenticated
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async -> Bool {
        do {
            try await user?.delete()
            return true
        }
        catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not authenticated.")
            return
        }
        
        Firestore.firestore().collection("EmployeeModel").document(userID).getDocument { document, error in
           
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No data found for the user.")
                return
            }
            
            do {
                let employee = try Firestore.Decoder().decode(EmployeeModel.self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = employee
                }
            } catch {
                print("Error decoding teacher data: \(error.localizedDescription)")
            }
        }
    }
    func addLocation(locationTime: String, latitude: String, longitude: String) {
        guard let user = currentUser else {
            print("currentUser is nil — call fetchUserData() first")
            return
        }
        currentDate = currentDate.addingTimeInterval(30)
        let timeString = dateFormatter.string(from: currentDate)

        // Rebuild from existing data then append the new entry
        _ = builder.setName(user.name)
        for i in user.latitude.indices {
            _ = builder.addLocation(lat: user.latitude[i],
                                     lng: user.longitude[i],
                                     time: user.locationTime[i])
        }
        _ = builder.addLocation(lat: latitude, lng: longitude, time: timeString)

        let updated = builder.build()
        saveToFirebase(latitude: updated.latitude,
                      longitude: updated.longitude,
                      locationTime: updated.locationTime)
        _ = builder.reset()
    }

//    func addLocation(locationTime: String, latitude: String, longitude: String) {
//        
//        guard let user = currentUser else {
//            print("❌ currentUser is nil - call fetchUserData() first")
//            return
//        }
//        var updatedUser = user
//        currentDate = currentDate.addingTimeInterval(30)
//        let timeString = dateFormatter.string(from: currentDate)
//        
//        updatedUser.locationTime.append(timeString)
//        updatedUser.latitude.append(latitude)
//        updatedUser.longitude.append(longitude)
//        
//        saveToFirebase(latitude: user.latitude, longitude: user.longitude, locationTime: user.locationTime)
//        
//
//
//    }
    
    func saveToFirebase(latitude: [String], longitude: [String], locationTime: [String]) {
        let db = Firestore.firestore()
        guard let userID = Auth.auth().currentUser?.uid else {
//            submissionError = "User not logged in."
            return
        }
        let employeeCollectionRef = db.collection("EmployeeModel")

        employeeCollectionRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching employee documents: \(error.localizedDescription)")
                return
            }

//            guard let documents = snapshot?.documents, selectedStudentId < documents.count else {
//                print("Invalid student ID or no documents found")
//                return
//            }

            let employeeRef = employeeCollectionRef.document(userID)

            employeeRef.setData([
                "locationTime": locationTime,
                "latitude": latitude,
                "longitude": longitude
            ], merge: true) { error in
                if let error = error {
                    print("Error updating points: \(error.localizedDescription)")
                } else {
                    print("Points and timestamps successfully updated!")
                }
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

        // Director drives the Builder step by step
        let newEmployee = builder
            .setName(name)
            .addLocation(lat: latitude, lng: longitude, time: locationTime)
            .build()

        do {
            try Firestore.firestore()
                .collection("EmployeeModel")
                .document(userID)
                .setData(from: newEmployee) { error in
                    if let error = error {
                        self.submissionError = "Error: \(error.localizedDescription)"
                    } else {
                        self.isSubmitted = true
                        self.submissionError = nil
                        _ = self.builder.reset()  // clear for next use
                    }
                }
        } catch {
            submissionError = "Encoding error: \(error.localizedDescription)"
        }
    }

    
//    func submitData() {
//        // Validation
//        guard !name.isEmpty  else {
//            submissionError = "All fields are required."
//            return
//        }
//        
//        
//        guard let userID = Auth.auth().currentUser?.uid else {
//            submissionError = "User not logged in."
//            return
//        }
//        let newStudent = EmployeeModel(
//            name: name,
//            latitude: [latitude],
//            longitude: [longitude],
//            locationTime: [locationTime]
//        )
//
//        
//        do {
//            try Firestore.firestore()
//                .collection("EmployeeModel")
//                .document(userID)
//                .setData(from: newStudent) { error in
//                    if let error = error {
//                        self.submissionError = "Error saving data: \(error.localizedDescription)"
//                        print("Error saving data: \(error.localizedDescription)")
//                    } else {
//                        self.isSubmitted = true
//                        self.submissionError = nil
//                        print("Student data successfully written to Firestore.")
//                    }
//                }
//        } catch {
//            submissionError = "Error encoding student data: \(error.localizedDescription)"
//            print("Error encoding student data: \(error.localizedDescription)")
//        }
//    }
    
    

}
