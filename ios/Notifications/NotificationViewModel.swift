//
//  NotificationViewModel.swift
//  Fleet-Tracker
//

import Foundation
import Combine
import FirebaseFirestore

final class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount:   Int = 0

    private let db  = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var businessId: String?

    func configure(businessId: String) {
        self.businessId = businessId
        stopListening()
        listenToNotifications()
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    // ── Listen to unified notifications collection ────────────────────────────

    private func listenToNotifications() {
        guard let bid = businessId else { return }

        let listener = db.collection("businesses").document(bid)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.notifications = docs.compactMap { doc in
                        let d = doc.data()
                        guard let typeRaw  = d["type"]         as? String,
                              let title    = d["title"]        as? String,
                              let message  = d["message"]      as? String,
                              let empName  = d["employeeName"] as? String,
                              let ts       = d["timestamp"]    as? Timestamp else { return nil }
                        let type = NotificationType(rawValue: typeRaw) ?? .clockIn
                        return AppNotification(
                            id:           doc.documentID,
                            type:         type,
                            title:        title,
                            message:      message,
                            timestamp:    ts.dateValue(),
                            isRead:       d["isRead"] as? Bool ?? false,
                            employeeName: empName,
                            severity:     d["severity"] as? String
                        )
                    }
                    self?.unreadCount = self?.notifications.filter { !$0.isRead }.count ?? 0
                }
            }
        listeners.append(listener)
    }

    // ── Write helpers (called from EmployeeViewModel and SpeedMonitor) ────────

    func writeClockIn(businessId: String, employeeName: String, uid: String) {
        write(businessId: businessId, type: .clockIn,
              title: "Clocked In",
              message: "\(employeeName) clocked in at \(Date().formatted(date: .omitted, time: .shortened))",
              employeeName: employeeName, uid: uid)
    }

    func writeClockOut(businessId: String, employeeName: String, uid: String) {
        write(businessId: businessId, type: .clockOut,
              title: "Clocked Out",
              message: "\(employeeName) clocked out at \(Date().formatted(date: .omitted, time: .shortened))",
              employeeName: employeeName, uid: uid)
    }

    func writeExpense(businessId: String, employeeName: String, uid: String,
                      category: String, amount: Double) {
        let amountStr = String(format: "$%.2f", amount)
        write(businessId: businessId, type: .expense,
              title: "Expense Submitted",
              message: "\(employeeName) submitted a \(category) expense for \(amountStr)",
              employeeName: employeeName, uid: uid)
    }

    func writeSpeedAlert(businessId: String, employeeName: String, uid: String,
                         message: String, severity: String) {
        write(businessId: businessId, type: .speed,
              title: severity == "major" ? "⚠️ Speeding Alert" : "Speed Warning",
              message: message,
              employeeName: employeeName, uid: uid, severity: severity)
    }

    private func write(businessId: String, type: NotificationType,
                       title: String, message: String,
                       employeeName: String, uid: String, severity: String? = nil) {
        var data: [String: Any] = [
            "type":         type.rawValue,
            "title":        title,
            "message":      message,
            "employeeName": employeeName,
            "uid":          uid,
            "timestamp":    FieldValue.serverTimestamp(),
            "isRead":       false
        ]
        if let sev = severity { data["severity"] = sev }

        db.collection("businesses").document(businessId)
            .collection("notifications").addDocument(data: data)
    }

    // ── Mark read ─────────────────────────────────────────────────────────────

    func markRead(_ notification: AppNotification) {
        guard let bid = businessId else { return }
        db.collection("businesses").document(bid)
            .collection("notifications").document(notification.id)
            .updateData(["isRead": true])
        if let i = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[i].isRead = true
        }
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    func markAllRead() {
        guard let bid = businessId else { return }
        let batch = db.batch()
        notifications.filter { !$0.isRead }.forEach { n in
            let ref = db.collection("businesses").document(bid)
                .collection("notifications").document(n.id)
            batch.updateData(["isRead": true], forDocument: ref)
        }
        batch.commit()
        notifications = notifications.map {
            var n = $0; n.isRead = true; return n
        }
        unreadCount = 0
    }
}
