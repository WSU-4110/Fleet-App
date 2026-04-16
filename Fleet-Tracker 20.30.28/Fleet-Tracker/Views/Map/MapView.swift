//
//  MapView.swift
//  Fleet-Tracker
//

import UIKit
import SwiftUI
import GoogleMaps
import CoreLocation

// ── Emoji → UIImage helper ───────────────────────────────────────────────────

private func emojiMarkerImage(_ emoji: String, size: CGFloat = 44) -> UIImage {
    let label = UILabel()
    label.text      = emoji
    label.font      = .systemFont(ofSize: size * 0.65)
    label.textAlignment = .center
    label.frame     = CGRect(x: 0, y: 0, width: size, height: size)

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { _ in label.layer.render(in: UIGraphicsGetCurrentContext()!) }
}

// ── Admin map: shows every employee ─────────────────────────────────────────

class AdminMapViewController: UIViewController {
    var mapView: GMSMapView!
    var employees: [EmployeeModel] = [] {
        didSet { refreshMarkers() }
    }
    private var markers: [String: GMSMarker] = [:]  // keyed by uid

    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 4)
        mapView = GMSMapView.map(withFrame: view.frame, camera: camera)
        view.addSubview(mapView)
    }

    private func refreshMarkers() {
        var seen: Set<String> = []
        for emp in employees {
            guard let lat = emp.latitude, let lon = emp.longitude else { continue }
            seen.insert(emp.uid)
            if let marker = markers[emp.uid] {
                marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                marker.icon     = emojiMarkerImage(emp.pinEmoji)
                marker.title    = emp.name
            } else {
                let marker = GMSMarker()
                marker.position  = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                marker.icon      = emojiMarkerImage(emp.pinEmoji)
                marker.title     = emp.name
                marker.map       = mapView
                markers[emp.uid] = marker
            }
        }
        // Remove stale markers for employees who lost location
        for uid in markers.keys where !seen.contains(uid) {
            markers[uid]?.map = nil
            markers.removeValue(forKey: uid)
        }
    }
}

struct AdminMapView: UIViewControllerRepresentable {
    var employees: [EmployeeModel]

    func makeUIViewController(context: Context) -> AdminMapViewController {
        AdminMapViewController()
    }

    func updateUIViewController(_ vc: AdminMapViewController, context: Context) {
        vc.employees = employees
    }
}

// ── Employee map: shows only the current user ────────────────────────────────

class EmployeeMapViewController: UIViewController, CLLocationManagerDelegate {
    var mapView: GMSMapView!
    var pinEmoji: String = "🚗" {
        didSet { selfMarker?.icon = emojiMarkerImage(pinEmoji) }
    }

    private let locationManager = CLLocationManager()
    private var selfMarker: GMSMarker?
    private var hasZoomed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 4)
        mapView = GMSMapView.map(withFrame: view.frame, camera: camera)
        view.addSubview(mapView)

        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }

        if selfMarker == nil {
            let marker   = GMSMarker()
            marker.position = coord
            marker.icon  = emojiMarkerImage(pinEmoji)
            marker.title = "You"
            marker.map   = mapView
            selfMarker   = marker
        } else {
            selfMarker?.position = coord
        }

        if !hasZoomed {
            hasZoomed = true
            mapView.camera = GMSCameraPosition.camera(
                withLatitude:  coord.latitude,
                longitude:     coord.longitude,
                zoom:          14
            )
        }
    }
}

struct EmployeeMapView: UIViewControllerRepresentable {
    var pinEmoji: String

    func makeUIViewController(context: Context) -> EmployeeMapViewController {
        EmployeeMapViewController()
    }

    func updateUIViewController(_ vc: EmployeeMapViewController, context: Context) {
        vc.pinEmoji = pinEmoji
    }
}
