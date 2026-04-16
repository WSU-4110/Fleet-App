//
//  SpeedMonitor.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

private let minorOverLimit: Double = 10   // 10 over → alert after 60s
private let majorOverLimit: Double = 20   // 20 over → alert immediately
private let alertCooldown:  TimeInterval = 300  // 5 min between repeat alerts

final class SpeedMonitor: ObservableObject {

    @Published var activeAlerts: [SpeedAlert] = []

    var notifVM: NotificationViewModel?

    private let db           = Firestore.firestore()
    private let speedService = SpeedLimitService.shared
    private var businessId:  String?

    private var minorOverTimers: [String: Date] = [:]
    private var majorAlertSent:  [String: Date] = [:]
    private var minorAlertSent:  [String: Date] = [:]

    func configure(businessId: String) {
        self.businessId = businessId
        listenForAlerts()
    }

    // ── Called every time employee list updates ───────────────────────────────

    func checkSpeeds(employees: [EmployeeModel]) {
        for emp in employees where emp.isClockedIn {
            guard let speedKPH = emp.speedMPH,
                  let lat      = emp.latitude,
                  let lon      = emp.longitude else { continue }

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            // Use cached limit first (instant), then refresh in background
            let cachedLimit = speedService.cachedLimit(at: coord)
            evaluate(emp: emp, speedKPH: speedKPH, limitKPH: cachedLimit)

            // Fetch real limit from Roads API (updates cache for next check)
            speedService.speedLimit(at: coord) { [weak self] realLimit in
                // Re-evaluate with the real limit once we have it
                self?.evaluate(emp: emp, speedKPH: speedKPH, limitKPH: realLimit)
            }
        }
    }

    // ── Core evaluation ───────────────────────────────────────────────────────

    private func evaluate(emp: EmployeeModel, speedKPH: Double, limitKPH: Double) {
        let overBy = speedKPH - limitKPH

        if overBy >= majorOverLimit {
            handleMajorSpeeding(emp: emp, speed: speedKPH, overBy: overBy, limit: limitKPH)
        } else if overBy >= minorOverLimit {
            handleMinorSpeeding(emp: emp, speed: speedKPH, overBy: overBy, limit: limitKPH)
        } else {
            minorOverTimers.removeValue(forKey: emp.uid)
        }
    }

    // ── Major speeding ────────────────────────────────────────────────────────

    private func handleMajorSpeeding(emp: EmployeeModel, speed: Double,
                                      overBy: Double, limit: Double) {
        let now = Date()
        if let last = majorAlertSent[emp.uid], now.timeIntervalSince(last) < alertCooldown { return }
        majorAlertSent[emp.uid] = now
        minorOverTimers.removeValue(forKey: emp.uid)

        writeAlert(
            uid:      emp.uid,
            name:     emp.name,
            speed:    speed,
            overBy:   overBy,
            limit:    limit,
            severity: "major",
            message:  "\(emp.name) is driving \(String(format: "%.0f", speed)) mph in a \(String(format: "%.0f", limit)) mph zone — \(String(format: "%.0f", overBy)) mph over the limit.",
            vehicleId: emp.assignedVehicleId
        )
    }

    // ── Minor speeding ────────────────────────────────────────────────────────

    private func handleMinorSpeeding(emp: EmployeeModel, speed: Double,
                                      overBy: Double, limit: Double) {
        let now = Date()
        if minorOverTimers[emp.uid] == nil {
            minorOverTimers[emp.uid] = now
            return
        }
        guard let startedAt = minorOverTimers[emp.uid] else { return }
        guard now.timeIntervalSince(startedAt) >= 60 else { return }
        if let last = minorAlertSent[emp.uid], now.timeIntervalSince(last) < alertCooldown { return }

        minorAlertSent[emp.uid] = now
        minorOverTimers.removeValue(forKey: emp.uid)

        writeAlert(
            uid:      emp.uid,
            name:     emp.name,
            speed:    speed,
            overBy:   overBy,
            limit:    limit,
            severity: "minor",
            message:  "\(emp.name) has been driving \(String(format: "%.0f", speed)) mph in a \(String(format: "%.0f", limit)) mph zone for over 60 seconds.",
            vehicleId: emp.assignedVehicleId
        )
    }

    // ── Write to Firestore ────────────────────────────────────────────────────

    private func writeAlert(uid: String, name: String, speed: Double, overBy: Double,
                             limit: Double, severity: String, message: String,
                             vehicleId: String?) {
        guard let bid = businessId else { return }

        var data: [String: Any] = [
            "uid":        uid,
            "name":       name,
            "speed":      speed,
            "overBy":     overBy,
            "speedLimit": limit,
            "severity":   severity,
            "message":    message,
            "timestamp":  FieldValue.serverTimestamp(),
            "read":       false
        ]
        if let vid = vehicleId { data["vehicleId"] = vid }

        db.collection("businesses").document(bid)
            .collection("speedAlerts").addDocument(data: data)

        notifVM?.writeSpeedAlert(
            businessId:   bid,
            employeeName: name,
            uid:          uid,
            message:      message,
            severity:     severity
        )
    }

    // ── Listen for unread alerts ──────────────────────────────────────────────

    private func listenForAlerts() {
        guard let bid = businessId else { return }
        db.collection("businesses").document(bid)
            .collection("speedAlerts")
            .whereField("read", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    var alerts: [SpeedAlert] = []
                    for doc in docs {
                        let d = doc.data()
                        guard let name     = d["name"]      as? String,
                              let message  = d["message"]   as? String,
                              let severity = d["severity"]  as? String,
                              let ts       = d["timestamp"] as? Timestamp else { continue }
                        alerts.append(SpeedAlert(
                            id:         doc.documentID,
                            name:       name,
                            message:    message,
                            severity:   severity,
                            timestamp:  ts.dateValue(),
                            speed:      d["speed"]      as? Double ?? 0,
                            speedLimit: d["speedLimit"] as? Double ?? SpeedLimitService.fallbackLimitMPH
                        ))
                    }
                    self?.activeAlerts = alerts
                }
            }
    }

    func markAlertRead(_ alert: SpeedAlert) {
        guard let bid = businessId else { return }
        db.collection("businesses").document(bid)
            .collection("speedAlerts").document(alert.id)
            .updateData(["read": true])
        activeAlerts.removeAll { $0.id == alert.id }
    }

    func markAllRead() {
        activeAlerts.forEach { markAlertRead($0) }
    }
}

// ── Alert model ───────────────────────────────────────────────────────────────

struct SpeedAlert: Identifiable {
    let id:         String
    let name:       String
    let message:    String
    let severity:   String
    let timestamp:  Date
    let speed:      Double
    let speedLimit: Double
}
