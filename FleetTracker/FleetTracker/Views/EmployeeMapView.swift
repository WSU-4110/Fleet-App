//
//  ContentView.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/12/26.
//

import SwiftUI
import MapKit
import GameKit
import CoreLocation
import CoreLocationUI

struct EmployeeMapView: View {
//    @State var employee: EmployeeModel
    @StateObject private var locationManager = LocationManager()
    @StateObject var vm = EmployeeViewModel()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    let currentDate = Date()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        VStack {
            if let coordinate = locationManager.lastKnownLocation {
                let location = CLLocationCoordinate2D(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                Text("Latitude: \(coordinate.latitude)")
                
                Text("Longitude: \(coordinate.longitude)")
                Map(position: $position) {
                    Marker("", coordinate: location)
                }
                .mapStyle(.standard(elevation: .realistic))
               
            } else {
                Text("Unknown Location")
            }
        }
        .padding()
        .onAppear() {
            locationManager.checkLocationAuthorization()
//            vm.addLocation(locationTime: dateFormatter.string(from: currentDate), latitude: ("\(coordinate.latitude)"), longitude: ("\(coordinate.longitude)"))
        }
        
    }
}

//#Preview {
//    EmployeeMapView()
//}
