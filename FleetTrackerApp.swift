//
//  FleetTrackerApp.swift
//  FleetTracker
//
//  Created by Ashley Li on 3/27/26.
//

import SwiftUI
import FirebaseCore

@main
struct FleetTrackerApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
