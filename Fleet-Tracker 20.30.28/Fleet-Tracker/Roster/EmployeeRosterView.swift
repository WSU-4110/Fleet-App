//
//  EmployeeRosterView.swift
//  Fleet-Tracker
//

import SwiftUI
import CoreLocation

struct EmployeeRosterView: View {
    let employees:    [EmployeeModel]
    let vehicles:     [VehicleModel]

    @State private var addresses: [String: String] = [:]

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
                    List(employees, id: \.uid) { employee in
                        EmployeeRosterRow(
                            employee: employee,
                            address:  addresses[employee.uid],
                            vehicle:  vehicles.first { $0.id == employee.assignedVehicleId }
                        )
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Drivers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { geocodeAll() }
        .onChange(of: employees) { geocodeAll() }
    }

    private func geocodeAll() {
        for emp in employees {
            guard let lat = emp.latitude, let lon = emp.longitude,
                  addresses[emp.uid] == nil else { continue }
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { marks, _ in
                guard let p = marks?.first else { return }
                let parts   = [p.subThoroughfare, p.thoroughfare, p.locality].compactMap { $0 }
                DispatchQueue.main.async {
                    addresses[emp.uid] = parts.isEmpty ? "Unknown location" : parts.joined(separator: " ")
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
        guard let s = employee.speedKPH, s > 0.5 else { return nil }
        return String(format: "%.0f km/h", s)
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
                // Name + status badge
                HStack(spacing: 6) {
                    Text(employee.name)
                        .font(.subheadline).fontWeight(.semibold)

                    Text(employee.isClockedIn ? "On Duty" : "Off")
                        .font(.caption2).fontWeight(.medium)
                        .foregroundColor(employee.isClockedIn ? .green : .secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(employee.isClockedIn
                                    ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                        .cornerRadius(4)

                    // Speed badge — only shown when moving
                    if let speed = speedText {
                        Text(speed)
                            .font(.caption2).fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                // Vehicle
                if let v = vehicle {
                    Label("\(v.emoji) \(v.displayName)", systemImage: "")
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Clock-in time
                if let t = employee.clockInTime {
                    Text("Since \(t.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                }

                // Address
                if let addr = address {
                    Label(addr, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundColor(.secondary).lineLimit(1)
                } else if employee.latitude != nil {
                    Label("Locating…", systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Label("No location", systemImage: "mappin.slash")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}
