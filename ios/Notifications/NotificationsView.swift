//
//  NotificationsView.swift
//  Fleet-Tracker
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var notifVM: NotificationViewModel
    @Environment(\.dismiss) var dismiss

    private var grouped: [(String, [AppNotification])] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        let byDate = Dictionary(grouping: notifVM.notifications) {
            df.string(from: $0.timestamp)
        }
        return byDate.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if notifVM.notifications.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No notifications yet")
                            .font(.headline)
                        Text("Clock-in/out events, speed warnings and expense submissions will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(grouped, id: \.0) { date, items in
                            Section(date) {
                                ForEach(items) { notif in
                                    NotificationRow(notification: notif)
                                        .onTapGesture {
                                            if !notif.isRead { notifVM.markRead(notif) }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if notifVM.unreadCount > 0 {
                        Button("Mark All Read") { notifVM.markAllRead() }
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// ── Single notification row ───────────────────────────────────────────────────

struct NotificationRow: View {
    let notification: AppNotification

    var icon: String {
        switch notification.type {
        case .clockIn:  return "clock.badge.checkmark.fill"
        case .clockOut: return "clock.badge.xmark.fill"
        case .speed:    return "exclamationmark.triangle.fill"
        case .expense:  return "doc.text.fill"
        }
    }

    var iconColor: Color {
        switch notification.type {
        case .clockIn:  return .green
        case .clockOut: return .orange
        case .speed:    return notification.severity == "major" ? .red : .orange
        case .expense:  return .blue
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Unread dot
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)

            // Icon
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(notification.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .opacity(notification.isRead ? 0.65 : 1)
    }
}
