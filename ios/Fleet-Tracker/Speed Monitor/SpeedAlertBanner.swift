//
//  SpeedAlertBanner.swift
//  Fleet-Tracker
//

import SwiftUI

struct SpeedAlertBanner: View {
    @ObservedObject var speedMonitor: SpeedMonitor
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            if !speedMonitor.activeAlerts.isEmpty {
                // Header pill
                Button {
                    withAnimation(.spring(duration: 0.25)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.subheadline)

                        Text(speedMonitor.activeAlerts.count == 1
                             ? "1 Speed Alert"
                             : "\(speedMonitor.activeAlerts.count) Speed Alerts")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundColor(.white.opacity(0.8))

                        Button {
                            speedMonitor.markAllRead()
                        } label: {
                            Text("Clear")
                                .font(.caption).fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        speedMonitor.activeAlerts.contains { $0.severity == "major" }
                        ? Color.red.opacity(0.92)
                        : Color.orange.opacity(0.92)
                    )
                    .cornerRadius(expanded ? 0 : 12)
                }
                .buttonStyle(.plain)

                // Expanded alert list
                if expanded {
                    VStack(spacing: 0) {
                        ForEach(speedMonitor.activeAlerts) { alert in
                            HStack(spacing: 10) {
                                Image(systemName: alert.severity == "major"
                                      ? "exclamationmark.2"
                                      : "exclamationmark")
                                    .foregroundColor(alert.severity == "major" ? .red : .orange)
                                    .font(.subheadline)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(alert.message)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    speedMonitor.markAlertRead(alert)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Color(.systemBackground))

                            if alert.id != speedMonitor.activeAlerts.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 12)
    }
}
