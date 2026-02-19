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

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let manager=CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate=self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
     
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location=locations.first else {
            return
        }
        let coordinate=location.coordinate
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom:100.0)
        let options = GMSMapViewOptions()
        options.camera = camera
        options.frame = self.view.bounds
        let mapView = GMSMapView(options: options)
               self.view.addSubview(mapView)
               let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude:coordinate.longitude)
               marker.map = mapView
    }
}
struct MapScreen: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
}
