//
//  MapView.swift
//  Fleet-Tracker
//

import UIKit
import SwiftUI
import GoogleMaps
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// ── Map type ──────────────────────────────────────────────────────────────────

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard   = "Standard"
    case satellite  = "Satellite"
    case hybrid     = "Hybrid"
    case terrain    = "Terrain"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .standard:  return "map"
        case .satellite: return "globe.americas.fill"
        case .hybrid:    return "map.fill"
        case .terrain:   return "mountain.2.fill"
        }
    }

    var gmsType: GMSMapViewType {
        switch self {
        case .standard:  return .normal
        case .satellite: return .satellite
        case .hybrid:    return .hybrid
        case .terrain:   return .terrain
        }
    }
}

// ── Marker icon helpers ───────────────────────────────────────────────────────

private func emojiMarkerImage(_ emoji: String, size: CGFloat = 44) -> UIImage {
    let label           = UILabel()
    label.text          = emoji
    label.font          = .systemFont(ofSize: size * 0.65)
    label.textAlignment = .center
    label.frame         = CGRect(x: 0, y: 0, width: size, height: size)
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { _ in label.layer.render(in: UIGraphicsGetCurrentContext()!) }
}

private func circularMarkerImage(_ source: UIImage, size: CGFloat = 52) -> UIImage {
    let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
    let renderer = UIGraphicsImageRenderer(size: rect.size)
    return renderer.image { ctx in
        let border: CGFloat = 3
        UIColor.white.setFill()
        UIBezierPath(ovalIn: rect).fill()
        let innerRect = rect.insetBy(dx: border, dy: border)
        ctx.cgContext.addEllipse(in: innerRect)
        ctx.cgContext.clip()
        source.draw(in: innerRect)
    }
}

private func fetchRemoteImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
    guard let url = URL(string: urlString) else { completion(nil); return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async { completion(data.flatMap { UIImage(data: $0) }) }
    }.resume()
}

private func applyIcon(to marker: GMSMarker, employee: EmployeeModel) {
    if let urlStr = employee.pinImageURL {
        fetchRemoteImage(urlString: urlStr) { image in
            guard let image else { return }
            marker.icon = circularMarkerImage(image)
        }
    } else {
        marker.icon = emojiMarkerImage(employee.pinEmoji)
    }
}

// ── Admin map ─────────────────────────────────────────────────────────────────

class AdminMapViewController: UIViewController, CLLocationManagerDelegate {
    var mapView: GMSMapView!
    var employees: [EmployeeModel] = [] { didSet { refreshMarkers() } }
    var mapStyle: GMSMapViewType = .normal { didSet { mapView?.mapType = mapStyle } }

    private var markers: [String: GMSMarker] = [:]
    private let locationManager = CLLocationManager()
    private var hasZoomed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 4)
        options.frame  = view.frame
        mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        view.addSubview(mapView)

        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate, !hasZoomed else { return }
        hasZoomed = true
        locationManager.stopUpdatingLocation()
        mapView.animate(to: GMSCameraPosition.camera(
            withLatitude: coord.latitude, longitude: coord.longitude, zoom: 14))
    }

    func centerOnUser() {
        guard let coord = locationManager.location?.coordinate else { return }
        mapView.animate(to: GMSCameraPosition.camera(withLatitude: coord.latitude, longitude: coord.longitude, zoom: 14))
    }

    private func refreshMarkers() {
        var seen: Set<String> = []
        for emp in employees where emp.isClockedIn {
            guard let lat = emp.latitude, let lon = emp.longitude else { continue }
            seen.insert(emp.uid)
            let speedStr: String
            if let s = emp.speedMPH, s > 0.5 {
                speedStr = String(format: "%.0f mph", s)
            } else {
                speedStr = "Stopped"
            }

            if let marker = markers[emp.uid] {
                marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                marker.title    = emp.name
                marker.snippet  = speedStr
                applyIcon(to: marker, employee: emp)
            } else {
                let marker      = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                marker.title    = emp.name
                marker.snippet  = speedStr
                marker.map      = mapView
                applyIcon(to: marker, employee: emp)
                markers[emp.uid] = marker
            }
        }
        for uid in markers.keys where !seen.contains(uid) {
            markers[uid]?.map = nil
            markers.removeValue(forKey: uid)
        }
    }
}

struct AdminMapView: UIViewControllerRepresentable {
    var employees: [EmployeeModel]
    var mapStyle: GMSMapViewType
    var onCenter: ((AdminMapViewController) -> Void)? = nil

    func makeUIViewController(context: Context) -> AdminMapViewController {
        AdminMapViewController()
    }
    func updateUIViewController(_ vc: AdminMapViewController, context: Context) {
        vc.employees = employees
        vc.mapStyle  = mapStyle
        onCenter?(vc)
    }
}

// ── Employee map ──────────────────────────────────────────────────────────────

class EmployeeMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    var mapView: GMSMapView!
    var employee: EmployeeModel? { didSet {
        guard let emp = employee, let marker = selfMarker else { return }
        applyIcon(to: marker, employee: emp)
    }}
    var mapStyle: GMSMapViewType = .normal { didSet { mapView?.mapType = mapStyle } }

    private let locationManager = CLLocationManager()
    private var selfMarker:    GMSMarker?
    private var hasZoomed     = false
    private var routePath     = GMSMutablePath()
    private var routePolyline: GMSPolyline?

    override func viewDidLoad() {
        super.viewDidLoad()
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 4)
        options.frame  = view.frame
        mapView = GMSMapView(options: options)
        mapView.delegate = self
        mapView.settings.consumesGesturesInView = true
        view.addSubview(mapView)

        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    func centerOnUser() {
        guard let coord = locationManager.location?.coordinate else { return }
        mapView.animate(to: GMSCameraPosition.camera(withLatitude: coord.latitude, longitude: coord.longitude, zoom: 14))
    }

    // Block Google Maps from opening when tapping map elements
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Consume the tap — do nothing, prevents external app launch
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true  // return true = tap handled, don't show info window or open Maps
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        if selfMarker == nil {
            let marker      = GMSMarker()
            marker.position = coord
            marker.title    = "You"
            marker.map      = mapView
            if let emp = employee { applyIcon(to: marker, employee: emp) }
            selfMarker = marker
        } else {
            selfMarker?.position = coord
        }
        if !hasZoomed {
            hasZoomed = true
            mapView.animate(to: GMSCameraPosition.camera(
                withLatitude: coord.latitude, longitude: coord.longitude, zoom: 14))
        }

        // Add to route path and redraw polyline
        routePath.add(coord)
        routePolyline?.map = nil
        let polyline          = GMSPolyline(path: routePath)
        polyline.strokeWidth  = 4
        polyline.strokeColor  = UIColor.systemBlue.withAlphaComponent(0.7)
        polyline.geodesic     = true
        polyline.map          = mapView
        routePolyline         = polyline
    }
}

struct EmployeeMapView: UIViewControllerRepresentable {
    var employee:           EmployeeModel?
    var mapStyle:           GMSMapViewType
    var onCenter:           ((EmployeeMapViewController) -> Void)? = nil

    func makeUIViewController(context: Context) -> EmployeeMapViewController {
        EmployeeMapViewController()
    }
    func updateUIViewController(_ vc: EmployeeMapViewController, context: Context) {
        vc.employee            = employee
        vc.mapStyle            = mapStyle
        onCenter?(vc)
    }
}

// ── Weather-style map controls ───────────────────────────────────────────────

struct MapControls: View {
    @Binding var selected: MapStyleOption
    var showStyleMenu: Bool = false
    var onCenterLocation: (() -> Void)? = nil


    private let buttonSize: CGFloat = 54
    private let iconSize:   CGFloat = 22

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {

            // ── Pill ──────────────────────────────────────────────────────
            VStack(spacing: 0) {

                // Layers / map style button — always cycles, no dropdown
                Button {
                    let all  = MapStyleOption.allCases
                    let idx  = all.firstIndex(of: selected) ?? 0
                    selected = all[(idx + 1) % all.count]
                } label: {
                    Image(systemName: "square.3.layers.3d.top.filled")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: buttonSize - 16, height: 1)

                // Location arrow
                Button {
                    onCenterLocation?()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 5)

        }
    }
}

typealias MapStylePicker = MapControls
