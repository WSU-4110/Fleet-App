//
//  EmployeeRosterView.swift
//  Fleet-Tracker
//

import SwiftUI
import CoreLocation
import MapKit

struct EmployeeRosterView: View {
    let employees: [EmployeeModel]
    let vehicles:  [VehicleModel]

    // Only geocode live locations for clocked-in employees
    @State private var liveAddresses: [String: String] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if employees.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No drivers yet")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        let active  = employees.filter {  $0.isClockedIn }
                        let offline = employees.filter { !$0.isClockedIn }

                        if !active.isEmpty {
                            Section("On Duty — \(active.count)") {
                                ForEach(active, id: \.uid) { emp in
                                    EmployeeRosterRow(
                                        employee: emp,
                                        address:  liveAddresses[emp.uid],
                                        vehicle:  vehicles.first { $0.id == emp.assignedVehicleId }
                                    )
                                }
                            }
                        }

                        if !offline.isEmpty {
                            Section("Off Duty — \(offline.count)") {
                                ForEach(offline, id: \.uid) { emp in
                                    EmployeeRosterRow(
                                        employee: emp,
                                        // Off-duty: use pre-saved address from Firestore
                                        address:  emp.lastAddress ?? liveAddresses[emp.uid],
                                        vehicle:  vehicles.first { $0.id == emp.assignedVehicleId }
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Drivers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { geocodeActive() }
        .onChange(of: employees) { geocodeActive() }
    }

    private func geocodeActive() {
        for emp in employees {
            guard let lat = emp.latitude,
                  let lon = emp.longitude else { continue }

            // For off-duty employees, use saved address if available — skip geocoding
            if !emp.isClockedIn, let saved = emp.lastAddress {
                liveAddresses[emp.uid] = saved
                continue
            }

            // Skip if already geocoded and not clocked in (address won't change)
            if !emp.isClockedIn && liveAddresses[emp.uid] != nil { continue }

            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { marks, _ in
                let parts = (marks?.first).map { p in
                    [p.subThoroughfare, p.thoroughfare, p.locality].compactMap { $0 }
                } ?? []
                DispatchQueue.main.async {
                    liveAddresses[emp.uid] = parts.isEmpty ? "Unknown location" : parts.joined(separator: " ")
                }
            }
        }
    }
}

// ── Single row ────────────────────────────────────────────────────────────────

struct EmployeeRosterRow: View {
    let employee: EmployeeModel
    let address:  String?
    let vehicle:  VehicleModel?

    private var speedText: String? {
        guard employee.isClockedIn else { return nil }
        guard let s = employee.speedMPH else { return "No speed data" }
        if s < 1 { return "Stopped" }
        return String(format: "%.0f mph", s)
    }

    private var speedColor: Color {
        guard let s = employee.speedMPH else { return .secondary }
        if s < 1    { return .secondary }
        if s > 80   { return .red }
        if s > 65   { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: 14) {
            // Status dot
            Circle()
                .fill(employee.isClockedIn ? Color.green : Color.gray.opacity(0.35))
                .frame(width: 10, height: 10)

            // Pin emoji
            Text(employee.pinEmoji)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 3) {
                // Name + status badge + speed
                HStack(spacing: 6) {
                    Text(employee.name)
                        .font(.subheadline).fontWeight(.semibold)

                    Text(employee.isClockedIn ? "On Duty" : "Off")
                        .font(.caption2).fontWeight(.medium)
                        .foregroundColor(employee.isClockedIn ? .green : .secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(employee.isClockedIn
                                    ? Color.green.opacity(0.12)
                                    : Color.gray.opacity(0.12))
                        .cornerRadius(4)

                    if let speed = speedText {
                        Text(speed)
                            .font(.caption2).fontWeight(.medium)
                            .foregroundColor(speedColor)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(speedColor.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                // Vehicle
                if let v = vehicle {
                    HStack(spacing: 4) {
                        Text(v.emoji)
                        Text(v.displayName)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .lineLimit(1)
                }

                // Mileage
                if employee.isClockedIn {
                    Label(String(format: "%.1f mi driven", employee.lastShiftMiles ?? 0),
                          systemImage: "gauge.with.dots.needle.67percent")
                        .font(.caption).foregroundColor(.secondary)
                } else if let miles = employee.lastShiftMiles, miles > 0 {
                    Label(String(format: "Last shift: %.1f mi", miles),
                          systemImage: "gauge.with.dots.needle.67percent")
                        .font(.caption).foregroundColor(.secondary)
                }

                // Time info
                if employee.isClockedIn, let t = employee.clockInTime {
                    Text("Since \(t.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                } else if let t = employee.clockOutTime {
                    Text("Clocked out \(t.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                }

                // Location
                if let addr = address {
                    Label(
                        employee.isClockedIn ? addr : "Last seen: \(addr)",
                        systemImage: employee.isClockedIn
                            ? "mappin.and.ellipse"
                            : "mappin.slash"
                    )
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
                } else if employee.isClockedIn && employee.latitude != nil {
                    Label("Locating…", systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundColor(.secondary)
                } else if !employee.isClockedIn {
                    Label("No location recorded", systemImage: "mappin.slash")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
