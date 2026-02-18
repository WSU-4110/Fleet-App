//
//  FleetTrackerApp.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/12/26.
//

import SwiftUI
import Firebase
import Combine

@main
struct FleetTrackerApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            EmployeeRegisterView()
        }
    }
}
