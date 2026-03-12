import UIKit
import GoogleMaps
import SwiftUI
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var mapView: GMSMapView!
    var hasInitialLocation = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaultCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: self.view.frame, camera: defaultCamera)
        self.view.addSubview(mapView)

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first, !hasInitialLocation else {
            return
        }

        hasInitialLocation = true

        let coordinate = location.coordinate
        let camera = GMSCameraPosition.camera(
            withLatitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: 6.0
        )
        mapView.camera = camera

        
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = "My Location"
        marker.snippet = "Current position"
        marker.map = mapView
    }
}

struct MapViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
