//
//  NotificationModel.swift
//  Fleet-Tracker
//

import Foundation

enum NotificationType: String {
    case clockIn    = "clock_in"
    case clockOut   = "clock_out"
    case speed      = "speed"
    case expense    = "expense"
}

struct AppNotification: Identifiable {
    let id:           String
    let type:         NotificationType
    let title:        String
    let message:      String
    let timestamp:    Date
    var isRead:       Bool
    let employeeName: String
    let severity:     String?   // for speed alerts: "minor" | "major"
}
