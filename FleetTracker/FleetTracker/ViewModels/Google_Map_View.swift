//
//  Google_Map_View.swift
//  FleetTracker
//
//  Created by Maher Yousif on 2/19/26.
//

import GoogleMaps
import UIKit
import SwiftUI
import CoreLocation

final class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    private let manager = CLLocationManager()

    private var mapView: GMSMapView!
    private var userMarker = GMSMarker()

    private var hasCenteredOnce = false
    private var isFollowingUser = true

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create map ONCE
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 15)
        mapView = GMSMapView(frame: view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        view.addSubview(mapView)

        // Marker ONCE
        userMarker.map = mapView

        // Location manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    // Stop "follow" when user interacts (prevents zoom snapping back in)
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture { isFollowingUser = false }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate

        // Always update marker position
        userMarker.position = coordinate

        // Only move camera if following OR first fix
        if isFollowingUser || !hasCenteredOnce {
            hasCenteredOnce = true

            // Keep user's current zoom (don't force zoom=15 every update)
            let currentZoom = mapView.camera.zoom
            mapView.animate(to: GMSCameraPosition.camera(
                withLatitude: coordinate.latitude,
                longitude: coordinate.longitude,
                zoom: currentZoom
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
    }

    // Optional: call this from a button to re-enable follow mode
    func recenter() {
        isFollowingUser = true
        if let coord = manager.location?.coordinate {
            mapView.animate(toLocation: coord)
        }
    }
}

struct MapScreen: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}
