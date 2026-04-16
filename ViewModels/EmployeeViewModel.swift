//
//  EmployeeViewModel.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import CoreLocation
import MapKit
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class EmployeeViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var employee: EmployeeModel?
    @Published var errorMessage: String?
    @Published var isClockedIn: Bool = false
    @Published var clockInTime: Date?
    @Published var allEmployees: [EmployeeModel] = []

    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var allEmployeesListener: ListenerRegistration?

    // Stores the current open timesheet doc ID so clockOut can update it directly
    private var activeTimesheetID: String?

    @Published private(set) var businessId: String?

    // Injected by RootView so clock events write notifications
    var notifVM: NotificationViewModel?

    // Mileage tracking
    let mileageTracker = MileageTracker()

    override init() {
        super.init()
        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        restoreSessionIfNeeded()
    }

    // Restore employee session on app relaunch
    private func restoreSessionIfNeeded() {
        guard Auth.auth().currentUser != nil else { return }
        // Only restore if last role was employee
        guard UserDefaults.standard.string(forKey: "lastRole") == "employee" else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        findAndFetchEmployee(uid: uid)
    }

    // ── Geocoding helper ─────────────────────────────────────────────────────

    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        // CLGeocoder deprecated in iOS 26 — acceptable for current deployment target
        CLGeocoder().reverseGeocodeLocation(location) { marks, _ in
            if let p = marks?.first {
                let parts = [p.subThoroughfare, p.thoroughfare, p.locality].compactMap { $0 }
                completion(parts.isEmpty ? nil : parts.joined(separator: " "))
            } else {
                completion(nil)
            }
        }
    }

    // ── Date/time helpers ─────────────────────────────────────────────────────

    private func dateFields(from date: Date, prefix: String) -> [String: Any] {
        let cal  = Calendar.current
        let df   = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        df.dateFormat = "yyyy-MM-dd"
        let dateStr = df.string(from: date)

        df.dateFormat = "HH:mm:ss"
        let timeStr = df.string(from: date)

        df.dateFormat = "EEEE"
        let dayStr = df.string(from: date)

        df.dateFormat = "h:mm a"
        let timeReadable = df.string(from: date)

        return [
            "\(prefix)Date":        dateStr,       // "2026-04-15"
            "\(prefix)Time":        timeStr,        // "14:32:00"
            "\(prefix)TimeReadable": timeReadable,  // "2:32 PM"
            "\(prefix)DayOfWeek":   dayStr,         // "Wednesday"
            "\(prefix)Week":        cal.component(.weekOfYear, from: date),
            "\(prefix)Month":       cal.component(.month,       from: date),
            "\(prefix)Year":        cal.component(.year,        from: date)
        ]
    }

    // ── Convenience paths ─────────────────────────────────────────────────────

    private func employeesRef() -> CollectionReference? {
        guard let bid = businessId else { return nil }
        return db.collection("businesses").document(bid).collection("employees")
    }

    private func timesheetsRef() -> CollectionReference? {
        guard let bid = businessId else { return nil }
        return db.collection("businesses").document(bid).collection("timesheets")
    }

    // ── Sign up ───────────────────────────────────────────────────────────────

    func signUp(username: String, accessCode: String, password: String) {
        errorMessage = nil

        db.collection("businesses")
            .whereField("accessCode", isEqualTo: accessCode.uppercased())
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                    return
                }

                guard let bizDoc = snapshot?.documents.first else {
                    DispatchQueue.main.async { self.errorMessage = "Invalid access code" }
                    return
                }

                let bid        = bizDoc.documentID
                let loginEmail = "\(username.lowercased().replacingOccurrences(of: " ", with: "_"))@fleettracker.com"

                Auth.auth().createUser(withEmail: loginEmail, password: password) { result, error in
                    if let error {
                        DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                        return
                    }
                    guard let uid = result?.user.uid else { return }

                    let batch = self.db.batch()

                    // Write employee doc into business subcollection
                    let empRef = self.db.collection("businesses").document(bid)
                        .collection("employees").document(uid)
                    batch.setData([
                        "uid":         uid,
                        "username":    username,
                        "businessId":  bid,
                        "pinEmoji":    "🚗",
                        "isClockedIn": false,
                        "createdAt":   FieldValue.serverTimestamp()
                    ], forDocument: empRef)

                    // Top-level employeeUsers collection — visible in Firebase Console
                    // Makes it easy to see all employees across all businesses
                    let employeeUserRef = self.db.collection("employeeUsers").document(uid)
                    batch.setData([
                        "uid":        uid,
                        "username":   username,
                        "businessId": bid,
                        "createdAt":  FieldValue.serverTimestamp()
                    ], forDocument: employeeUserRef)

                    // Write index doc with username so future logins are fast
                    let indexRef = self.db.collection("employeeIndex").document(uid)
                    batch.setData([
                        "businessId": bid,
                        "username":   username
                    ], forDocument: indexRef)

                    batch.commit { err in
                        DispatchQueue.main.async {
                            if let err {
                                self.errorMessage = err.localizedDescription
                            } else {
                                UserDefaults.standard.set("employee", forKey: "lastRole")
                                self.businessId = bid
                                self.employee   = EmployeeModel(uid: uid, name: username)
                            }
                        }
                    }
                }
            }
    }

    // ── Sign in ───────────────────────────────────────────────────────────────

    func signIn(name: String, password: String) {
        errorMessage = nil
        let loginEmail = "\(name.lowercased().replacingOccurrences(of: " ", with: "_"))@fleettracker.com"
        Auth.auth().signIn(withEmail: loginEmail, password: password) { [weak self] result, error in
            if let error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription.contains("password")
                        ? "Invalid username or password"
                        : error.localizedDescription
                }
                return
            }
            guard let uid = result?.user.uid else { return }
            UserDefaults.standard.set("employee", forKey: "lastRole")
            self?.findAndFetchEmployee(uid: uid)
        }
    }

    private func findAndFetchEmployee(uid: String) {
        // Fast path: check the index first
        db.collection("employeeIndex").document(uid).getDocument { [weak self] doc, _ in
            guard let self else { return }

            if let bid = doc?.data()?["businessId"] as? String {
                self.businessId = bid
                self.fetchEmployee(uid: uid)
                return
            }

            // Slow path: scan all businesses via collection group query
            // Requires a Firestore composite index on employees.uid
            self.db.collectionGroup("employees")
                .whereField("uid", isEqualTo: uid)
                .getDocuments { [weak self] snapshot, error in
                    guard let self else { return }

                    if let error {
                        DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                        return
                    }

                    guard let empDoc = snapshot?.documents.first,
                          let bid    = empDoc.data()["businessId"] as? String else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Account not found. Please contact your admin."
                        }
                        return
                    }

                    // Cache for next login
                    self.db.collection("employeeIndex").document(uid)
                        .setData(["businessId": bid])

                    self.businessId = bid
                    self.fetchEmployee(uid: uid)
                }
        }
    }

    private var employeeListener: ListenerRegistration?

    func fetchEmployee(uid: String) {
        guard let ref = employeesRef() else { return }
        // Use a live listener so vehicle changes, pin changes etc update in real time
        employeeListener?.remove()
        employeeListener = ref.document(uid).addSnapshotListener { [weak self] doc, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }

            guard let data = doc?.data() else {
                DispatchQueue.main.async { self.errorMessage = "Employee record not found." }
                return
            }
            // Restore location tracking if they were clocked in
            let wasClocked = data["isClockedIn"] as? Bool ?? false
            if wasClocked {
                self.locationManager.startUpdatingLocation()
            }

            DispatchQueue.main.async {
                let pin        = data["pinEmoji"]         as? String ?? "🚗"
                let imgURL     = data["pinImageURL"]      as? String
                let vehicleId  = data["assignedVehicleId"] as? String
                let lat        = data["latitude"]          as? Double
                let lon        = data["longitude"]         as? Double
                let clockedIn  = data["isClockedIn"]       as? Bool ?? false

                self.employee = EmployeeModel(
                    uid:               uid,
                    name:              data["username"]    as? String ?? "",
                    pinEmoji:          pin,
                    pinImageURL:       imgURL,
                    isClockedIn:       clockedIn,
                    latitude:          lat,
                    longitude:         lon,
                    assignedVehicleId: vehicleId
                )
                self.isClockedIn = clockedIn
                if let ts = data["clockInTime"] as? Timestamp {
                    self.clockInTime = ts.dateValue()
                }
                // Save vehicle to UserDefaults so it survives view recreation
                if let vid = vehicleId {
                    UserDefaults.standard.set(vid, forKey: "lastVehicleId_\(uid)")
                }
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    // ── Sign out ──────────────────────────────────────────────────────────────

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "lastRole")
        locationManager.stopUpdatingLocation()
        employeeListener?.remove()
        allEmployeesListener?.remove()
        try? Auth.auth().signOut()
        employee          = nil
        isClockedIn       = false
        clockInTime       = nil
        allEmployees      = []
        businessId        = nil
        activeTimesheetID = nil
    }

    // ── Pin ───────────────────────────────────────────────────────────────────

    func updatePin(_ emoji: String) {
        guard let uid = employee?.uid, let ref = employeesRef() else { return }
        ref.document(uid).updateData([
            "pinEmoji":    emoji,
            "pinImageURL": NSNull()
        ]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.employee?.pinEmoji    = emoji
                self?.employee?.pinImageURL = nil
            }
        }
    }

    func uploadCustomPin(image: UIImage, completion: @escaping (Error?) -> Void) {
        guard let uid  = employee?.uid,
              let data = image.jpegData(compressionQuality: 0.8),
              let ref  = employeesRef() else { return }

        let storageRef = Storage.storage().reference()
            .child("pinIcons/\(uid)_\(UUID().uuidString).jpg")

        storageRef.putData(data, metadata: nil) { [weak self] _, error in
            if let error { DispatchQueue.main.async { completion(error) }; return }
            storageRef.downloadURL { url, error in
                guard let url else { DispatchQueue.main.async { completion(error) }; return }
                let urlString = url.absoluteString
                ref.document(uid).updateData(["pinImageURL": urlString]) { err in
                    DispatchQueue.main.async {
                        self?.employee?.pinImageURL = urlString
                        completion(err)
                    }
                }
            }
        }
    }

    // ── Clock ─────────────────────────────────────────────────────────────────

    func clockIn() {
        guard let uid  = employee?.uid,
              let eRef = employeesRef(),
              let tRef = timesheetsRef() else { return }
        let now = Date()

        eRef.document(uid).updateData([
            "isClockedIn": true,
            "clockInTime": Timestamp(date: now),
            "uid":         uid   // ensure uid field always exists for admin watcher
        ]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isClockedIn = true
                self?.clockInTime = now
                self?.mileageTracker.startTracking()
                // Ensure location updates are running
                self?.locationManager.startUpdatingLocation()
                // Notify admin
                if let bid = self?.businessId, let name = self?.employee?.name {
                    self?.notifVM?.writeClockIn(businessId: bid, employeeName: name, uid: uid)
                }
            }
        }

        // Store the doc ref so clockOut can update it directly — no query needed
        var data: [String: Any] = [
            "uid":        uid,
            "name":       employee?.name ?? "",
            "businessId": businessId ?? "",
            "clockIn":    Timestamp(date: now),
            "clockOut":   NSNull()
        ]
        // Explicit date/time fields for easy querying
        for (k, v) in dateFields(from: now, prefix: "clockIn") { data[k] = v }
        if let vid = employee?.assignedVehicleId { data["vehicleId"] = vid }

        var ref: DocumentReference?
        ref = tRef.addDocument(data: data) { [weak self] error in
            if error == nil {
                self?.activeTimesheetID = ref?.documentID
            }
        }
    }

    func clockOut() {
        guard let uid  = employee?.uid,
              let eRef = employeesRef(),
              let tRef = timesheetsRef() else { return }
        let now = Date()

        // Snapshot last known location before clearing
        let lastLat = employee?.latitude  // may be nil if never moved
        let lastLon = employee?.longitude
        let lastVehicleId = employee?.assignedVehicleId

        // Build employee doc update — preserve last known location for the roster
        var empUpdate: [String: Any] = [
            "isClockedIn":  false,
            "clockOutTime": Timestamp(date: now)
        ]
        for (k, v) in dateFields(from: now, prefix: "clockOut") { empUpdate[k] = v }
        // Keep lat/lon on the doc so roster can still show last known location
        // Add lastKnownLat/Lon as separate fields so they survive future location updates
        if let lat = lastLat { empUpdate["lastKnownLatitude"]  = lat }
        if let lon = lastLon { empUpdate["lastKnownLongitude"] = lon }
        if let vid = lastVehicleId { empUpdate["lastKnownVehicleId"] = vid }

        // Reverse geocode last location and save address to Firestore
        if let lat = lastLat, let lon = lastLon {
            let loc = CLLocation(latitude: lat, longitude: lon)
            reverseGeocode(location: loc) { addr in
                var update = empUpdate
                if let addr { update["lastKnownAddress"] = addr }
                eRef.document(uid).updateData(update)
            }
        } else {
            eRef.document(uid).updateData(empUpdate)
        }

        // Stop mileage tracking and save summary
        let mileageSummary = mileageTracker.stopTracking()
        mileageTracker.reset()

        // Update local state
        isClockedIn = false
        clockInTime = nil
        // Notify admin
        if let bid = businessId, let name = employee?.name {
            notifVM?.writeClockOut(businessId: bid, employeeName: name, uid: uid)
        }

        // Save mileage summary to employee doc and timesheet
        let mileageData: [String: Any] = [
            "lastShiftMiles":        mileageSummary.totalMiles,
            "lastShiftBreaks":       mileageSummary.breakCount,
            "lastShiftBreakMinutes": mileageSummary.totalBreakMinutes
        ]
        eRef.document(uid).updateData(mileageData)

        // Build timesheet clock-out data
        var clockOutData: [String: Any] = ["clockOut": Timestamp(date: now)]
        for (k, v) in dateFields(from: now, prefix: "clockOut") { clockOutData[k] = v }
        if let start = clockInTime {
            clockOutData["durationMinutes"] = Int(now.timeIntervalSince(start) / 60)
        }
        if let vid = lastVehicleId  { clockOutData["vehicleId"]      = vid }
        if let lat = lastLat        { clockOutData["lastLatitude"]    = lat }
        if let lon = lastLon        { clockOutData["lastLongitude"]   = lon }
        clockOutData["totalMiles"]        = mileageSummary.totalMiles
        clockOutData["breakCount"]        = mileageSummary.breakCount
        clockOutData["breakMinutes"]      = mileageSummary.totalBreakMinutes

        if let tsID = activeTimesheetID {
            tRef.document(tsID).updateData(clockOutData)
            activeTimesheetID = nil
        } else {
            tRef.whereField("uid", isEqualTo: uid)
                .order(by: "clockIn", descending: true)
                .limit(to: 1)
                .getDocuments { snapshot, _ in
                    snapshot?.documents.first?.reference.updateData(clockOutData)
                }
        }
    }

    // ── Location broadcasting ─────────────────────────────────────────────────

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc  = locations.last,
              let uid  = employee?.uid,
              let ref  = employeesRef() else { return }
        let coord = loc.coordinate
        var locData: [String: Any] = [
            "latitude":  coord.latitude,
            "longitude": coord.longitude,
            "lastSeen":  FieldValue.serverTimestamp()
        ]
        // loc.speed is -1 when unavailable — only write real speed values
        if loc.speed >= 0 {
            locData["speedMPH"] = loc.speed * 2.23694
        }
        for (k, v) in dateFields(from: Date(), prefix: "lastSeen") { locData[k] = v }
        ref.document(uid).updateData(locData)

        // Keep local model in sync so clockOut can read the last position
        DispatchQueue.main.async { [weak self] in
            self?.employee?.latitude  = coord.latitude
            self?.employee?.longitude = coord.longitude
            if loc.speed >= 0 {
                self?.employee?.speedMPH = loc.speed * 2.23694
            }
        }

        // Feed into mileage tracker — only counts when clocked in and driving
        if isClockedIn {
            mileageTracker.processLocation(loc)
        }
    }

    // ── Vehicle assignment ────────────────────────────────────────────────────

    func assignVehicle(_ vehicleId: String) {
        guard let uid = employee?.uid, let ref = employeesRef() else { return }
        ref.document(uid).updateData(["assignedVehicleId": vehicleId]) { [weak self] _ in
            DispatchQueue.main.async { self?.employee?.assignedVehicleId = vehicleId }
        }
    }

    func unassignVehicle() {
        guard let uid = employee?.uid, let ref = employeesRef() else { return }
        ref.document(uid).updateData(["assignedVehicleId": NSNull()]) { [weak self] _ in
            DispatchQueue.main.async { self?.employee?.assignedVehicleId = nil }
        }
    }

    // ── Admin: watch all employees ────────────────────────────────────────────

    private func parseEmployeeDocs(_ docs: [QueryDocumentSnapshot], businessId: String) {
        var result: [EmployeeModel] = []
        for doc in docs {
            let d = doc.data()
            // uid may be stored as field OR is the document ID itself
            let uid  = d["uid"] as? String ?? doc.documentID
            guard !uid.isEmpty,
                  let name = d["username"] as? String else { continue }

            let clockedIn   = d["isClockedIn"] as? Bool ?? false
            let clockInTime = (d["clockInTime"] as? Timestamp)?.dateValue()

            let clockOutTime: Date?
            if let ts = d["clockOutTime"] as? Timestamp {
                clockOutTime = ts.dateValue()
            } else if let dateStr = d["clockOutDate"] as? String,
                      let timeStr = d["clockOutTime"] as? String {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                clockOutTime = df.date(from: "\(dateStr) \(timeStr)")
            } else {
                clockOutTime = nil
            }

            let lat: Double?
            let lon: Double?
            let vehicleId: String?
            if clockedIn {
                lat       = d["latitude"]          as? Double
                lon       = d["longitude"]         as? Double
                vehicleId = d["assignedVehicleId"] as? String
            } else {
                lat       = d["lastKnownLatitude"]  as? Double ?? d["latitude"]  as? Double
                lon       = d["lastKnownLongitude"] as? Double ?? d["longitude"] as? Double
                vehicleId = d["lastKnownVehicleId"] as? String ?? d["assignedVehicleId"] as? String
            }

            let lastAddress = d["lastKnownAddress"] as? String
            let speedMPH: Double?
            if clockedIn { speedMPH = d["speedMPH"] as? Double ?? d["speedKPH"] as? Double }
            else         { speedMPH = nil }

            result.append(EmployeeModel(
                uid:               uid,
                name:              name,
                pinEmoji:          d["pinEmoji"]    as? String ?? "🚗",
                pinImageURL:       d["pinImageURL"] as? String,
                isClockedIn:       clockedIn,
                clockInTime:       clockInTime,
                clockOutTime:      clockOutTime,
                latitude:          lat,
                longitude:         lon,
                lastAddress:       lastAddress,
                speedMPH:          speedMPH,
                assignedVehicleId: vehicleId,
                lastShiftMiles:    d["lastShiftMiles"] as? Double
            ))
        }
        allEmployees = result
    }

    func startWatchingAllEmployees(businessId: String) {
        // Remove existing listener before starting a new one
        allEmployeesListener?.remove()
        self.businessId = businessId

        let ref = db.collection("businesses").document(businessId).collection("employees")

        // One-time fetch first — populates data immediately without waiting for listener
        ref.getDocuments { [weak self] snapshot, _ in
            guard let self, let docs = snapshot?.documents else { return }
            DispatchQueue.main.async { self.parseEmployeeDocs(docs, businessId: businessId) }
        }

        allEmployeesListener = ref
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("Employee listener error: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    var result: [EmployeeModel] = []
                    for doc in docs {
                        let d = doc.data()
                        let uid  = d["uid"] as? String ?? doc.documentID
                        guard !uid.isEmpty,
                              let name = d["username"] as? String else { continue }

                        let clockedIn   = d["isClockedIn"] as? Bool ?? false
                        let clockInTime = (d["clockInTime"] as? Timestamp)?.dateValue()

                        // clockOutTime may be a Timestamp or reconstructed from date+time strings
                        let clockOutTime: Date?
                        if let ts = d["clockOutTime"] as? Timestamp {
                            clockOutTime = ts.dateValue()
                        } else if let dateStr = d["clockOutDate"] as? String,
                                  let timeStr = d["clockOutTime"] as? String {
                            let df = DateFormatter()
                            df.locale = Locale(identifier: "en_US_POSIX")
                            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            clockOutTime = df.date(from: "\(dateStr) \(timeStr)")
                        } else {
                            clockOutTime = nil
                        }

                        let lat: Double?
                        let lon: Double?
                        let vehicleId: String?
                        if clockedIn {
                            lat       = d["latitude"]          as? Double
                            lon       = d["longitude"]         as? Double
                            vehicleId = d["assignedVehicleId"] as? String
                        } else {
                            // Fall back to latitude/longitude if lastKnown fields not yet written
                            lat       = d["lastKnownLatitude"]  as? Double ?? d["latitude"]  as? Double
                            lon       = d["lastKnownLongitude"] as? Double ?? d["longitude"] as? Double
                            vehicleId = d["lastKnownVehicleId"] as? String ?? d["assignedVehicleId"] as? String
                        }

                        let lastAddress  = d["lastKnownAddress"] as? String
                        let speedKPH: Double?
                        if clockedIn { speedKPH = d["speedMPH"] as? Double ?? d["speedKPH"] as? Double }  // support both field names
                        else         { speedKPH = nil }

                        result.append(EmployeeModel(
                            uid:               uid,
                            name:              name,
                            pinEmoji:          d["pinEmoji"]    as? String ?? "🚗",
                            pinImageURL:       d["pinImageURL"] as? String,
                            isClockedIn:       clockedIn,
                            clockInTime:       clockInTime,
                            clockOutTime:      clockOutTime,
                            latitude:          lat,
                            longitude:         lon,
                            lastAddress:       lastAddress,
                            speedMPH:          speedKPH,
                            assignedVehicleId: vehicleId,
                            lastShiftMiles:    d["lastShiftMiles"] as? Double
                        ))
                    }
                    self?.allEmployees = result
                }
            }
    }

    func stopWatchingAllEmployees() {
        allEmployeesListener?.remove()
    }
}
