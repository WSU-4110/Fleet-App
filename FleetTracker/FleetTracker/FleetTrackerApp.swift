//
//  FleetTrackerApp.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/12/26.
//

import SwiftUI
import Firebase
import FirebaseAuth
import Combine
import FirebaseFirestore
import GoogleMaps

@main
struct FleetTrackerApp: App {
    init(){
        FirebaseApp.configure()
        GMSServices.provideAPIKey("AIzaSyBpW-EBzPtp8Rpbg5TaUoIcmCj70TVoT_c")
    }
    var body: some Scene {
        WindowGroup {
            Rootview()
            
        }
    }
}
