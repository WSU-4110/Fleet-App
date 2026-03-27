//import UIKit
//import GoogleMaps
//import SwiftUI
//import CoreLocation
//
//class ViewController: UIViewController, CLLocationManagerDelegate {
//    let manager = CLLocationManager()
//    var mapView: GMSMapView!
//    var hasInitialLocation = false
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let defaultCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 6.0)
//        mapView = GMSMapView.map(withFrame: self.view.frame, camera: defaultCamera)
//        self.view.addSubview(mapView)
//
//        manager.delegate = self
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.requestWhenInUseAuthorization()
//        manager.startUpdatingLocation()
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first, !hasInitialLocation else {
//            return
//        }
//
//        hasInitialLocation = true
//
//        let coordinate = location.coordinate
//        let camera = GMSCameraPosition.camera(
//            withLatitude: coordinate.latitude,
//            longitude: coordinate.longitude,
//            zoom: 6.0
//        )
//        mapView.camera = camera
//
//        
//        let marker = GMSMarker()
//        marker.position = coordinate
//        marker.title = "My Location"
//        marker.snippet = "Current position"
//        marker.map = mapView
//    }
//}
//
//struct MapViewWrapper: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> ViewController {
//        ViewController()
//    }
//
//    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
//}

import SwiftUI
import GoogleMaps
import CoreLocation
import Combine

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationTime: String = ""
    
    // ✅ Reference to viewModel to send data to Firebase
    var viewModel: LocationTrackerViewModel?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let formatter = ISO8601DateFormatter()
        let timeString = formatter.string(from: location.timestamp)
        let lat = String(location.coordinate.latitude)
        let lon = String(location.coordinate.longitude)
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationTime = timeString
            
            // ✅ Send to Firebase via viewModel
            self.viewModel?.addLocation(
                locationTime: timeString,
                latitude: lat,
                longitude: lon
            )
        }
    }
}

// MARK: - Google Maps UIViewRepresentable
//struct GoogleMapView: UIViewRepresentable {
//    let coordinate: CLLocationCoordinate2D?
//    
//    func makeUIView(context: Context) -> GMSMapView {
//        let defaultCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 6.0)
//        return GMSMapView.map(withFrame: .zero, camera: defaultCamera)
//    }
//    
//    func updateUIView(_ mapView: GMSMapView, context: Context) {
//        guard let coordinate else { return }
//        
//        let camera = GMSCameraPosition.camera(
//            withLatitude: coordinate.latitude,
//            longitude: coordinate.longitude,
//            zoom: 6.0
//        )
//        mapView.animate(to: camera)
//        
//        mapView.clear()
//        let marker = GMSMarker()
//        marker.position = coordinate
//        marker.title = "My Location"
//        marker.snippet = "Current position"
//        marker.map = mapView
//    }
//}
struct GoogleMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> GMSMapView {
        let defaultCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: defaultCamera)
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        guard let coordinate else { return }
        
        // ✅ Only move camera on first location, never again
        if !context.coordinator.hasSetInitialLocation {
            context.coordinator.hasSetInitialLocation = true
            let camera = GMSCameraPosition.camera(
                withLatitude: coordinate.latitude,
                longitude: coordinate.longitude,
                zoom: 14.0
            )
            mapView.animate(to: camera)
        }
        
        // ✅ Update marker position without resetting camera
        mapView.clear()
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = "My Location"
        marker.snippet = "Current position"
        marker.map = mapView
    }
    
    // ✅ Coordinator tracks whether initial camera has been set
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hasSetInitialLocation = false
    }
}

// MARK: - SwiftUI View
struct MapViewWrapper: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var locationTrackerVM: LocationTrackerViewModel  // ✅ Injected from parent
    
    var body: some View {
        ZStack(alignment: .bottom) {
            GoogleMapView(coordinate: locationManager.userLocation)
                .ignoresSafeArea()
            
            if let location = locationManager.userLocation {
                VStack(spacing: 6) {
                    Text("📍 My Location")
                        .font(.headline)
                    Text("Lat: \(location.latitude, specifier: "%.5f")")
                    Text("Long: \(location.longitude, specifier: "%.5f")")
                    Text("Time: \(locationManager.locationTime)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
        .onAppear {
            // ✅ Connect locationManager to viewModel and fetch user first
            locationManager.viewModel = locationTrackerVM
            locationTrackerVM.fetchUserData()
        }
    }
}
