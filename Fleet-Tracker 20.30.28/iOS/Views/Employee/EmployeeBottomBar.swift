//
//  EmployeeBottomBar.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmployeeBottomBar: View {
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @ObservedObject var fleetViewModel:    FleetViewModel
    var signInViewModel: SignInViewModel
    @Binding var activeRole: UserRole

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                EmployeeSheet(
                    employeeViewModel: employeeViewModel,
                    fleetViewModel:    fleetViewModel,
                    signInViewModel:   signInViewModel,
                    activeRole:        $activeRole
                )
                .presentationDetents([.height(180), .fraction(0.55)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled(true)
            }
    }
}

// ── Inner sheet — owns all its own state and nested sheets ────────────────────

private struct EmployeeSheet: View {
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @ObservedObject var fleetViewModel:    FleetViewModel
    var signInViewModel: SignInViewModel
    @Binding var activeRole: UserRole

    @State private var showVehiclePicker = false
    @State private var showExpenseReport = false

    // Observe tracker directly so status changes instantly re-render
    @ObservedObject private var tracker: MileageTracker
    init(employeeViewModel: EmployeeViewModel, fleetViewModel: FleetViewModel,
         signInViewModel: SignInViewModel, activeRole: Binding<UserRole>) {
        self.employeeViewModel = employeeViewModel
        self.fleetViewModel    = fleetViewModel
        self.signInViewModel   = signInViewModel
        self._activeRole       = activeRole
        self._tracker          = ObservedObject(wrappedValue: employeeViewModel.mileageTracker)
    }

    private var assignedVehicle: VehicleModel? {
        fleetViewModel.vehicles.first { $0.id == employeeViewModel.employee?.assignedVehicleId }
    }

    var body: some View {
        NavigationStack {
            List {

                // ── Clock in / out ────────────────────────────────────────
                Section {
                    Button {
                        if employeeViewModel.isClockedIn { employeeViewModel.clockOut() }
                        else { employeeViewModel.clockIn() }
                    } label: {
                        HStack(spacing: 14) {
                            iconBox(
                                systemName: employeeViewModel.isClockedIn
                                    ? "clock.badge.xmark.fill" : "clock.badge.checkmark.fill",
                                color: employeeViewModel.isClockedIn ? .orange : .green
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(employeeViewModel.isClockedIn ? "Clock Out" : "Clock In")
                                    .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                                if let t = employeeViewModel.clockInTime, employeeViewModel.isClockedIn {
                                    Text("Since \(t.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text(employeeViewModel.isClockedIn ? "Tap to end shift" : "Tap to start shift")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if employeeViewModel.isClockedIn {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(String(format: "%.1f mi", tracker.totalMiles))
                                        .font(.subheadline).fontWeight(.semibold)
                                    driveStatusBadge
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    // Break — only when actively driving
                    if employeeViewModel.isClockedIn && (tracker.status == .driving || tracker.status == .onBreak) {
                        Button {
                            if tracker.status == .driving { tracker.takeBreak() }
                            else if tracker.status == .onBreak { tracker.resumeDriving() }
                        } label: {
                            HStack(spacing: 14) {
                                iconBox(systemName: tracker.status == .onBreak ? "play.circle.fill" : "pause.circle.fill",
                                        color: tracker.status == .onBreak ? .green : .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tracker.status == .onBreak ? "Resume Driving" : "Take a Break")
                                        .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                                    Text(tracker.status == .onBreak ? "Continue tracking mileage" : "Pause mileage — you stay on duty")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    // Stop Driving — clocked in but done driving for now
                    if employeeViewModel.isClockedIn && (tracker.status == .driving || tracker.status == .stopped || tracker.status == .notDriving) {
                        Button {
                            if tracker.status == .notDriving { tracker.resumeDriving() }
                            else { tracker.stopDriving() }
                        } label: {
                            HStack(spacing: 14) {
                                iconBox(systemName: tracker.status == .notDriving ? "car.fill" : "octagon.fill",
                                        color: tracker.status == .notDriving ? .green : .red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tracker.status == .notDriving ? "Start Driving" : "Stop Driving")
                                        .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                                    Text(tracker.status == .notDriving ? "Resume mileage tracking" : "Stay on clock, not driving")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ── Pick car ──────────────────────────────────────────────
                Section {
                    Button { showVehiclePicker = true } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                if let v = assignedVehicle {
                                    VehicleIconView(vehicle: v, size: 24)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.blue)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vehicle")
                                    .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                                Text(assignedVehicle?.displayName ?? "No vehicle selected")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).fontWeight(.semibold).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                // ── Submit expense ────────────────────────────────────────
                Section {
                    Button { showExpenseReport = true } label: {
                        HStack(spacing: 14) {
                            iconBox(systemName: "doc.text.fill", color: .indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Submit Expense")
                                    .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                                Text("Upload a receipt or expense")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).fontWeight(.semibold).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                // ── Sign out ──────────────────────────────────────────────
                Section {
                    if employeeViewModel.isClockedIn {
                        // Blocked — must clock out first
                        HStack(spacing: 14) {
                            iconBox(systemName: "rectangle.portrait.and.arrow.right",
                                    color: .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign Out")
                                    .font(.body).fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Text("Clock out before signing out")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(role: .destructive) {
                            employeeViewModel.signOut()
                            signInViewModel.signOut()
                            activeRole = .none
                        } label: {
                            HStack(spacing: 14) {
                                iconBox(systemName: "rectangle.portrait.and.arrow.right",
                                        color: .red)
                                Text("Sign Out")
                                    .font(.body).fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(employeeViewModel.employee?.name ?? "Driver")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Sheets live HERE — inside the view that owns the state
        .sheet(isPresented: $showVehiclePicker) {
            VehiclePickerSheet(fleetViewModel: fleetViewModel,
                               employeeViewModel: employeeViewModel)
        }
        .sheet(isPresented: $showExpenseReport) {
            ExpenseReportView(employeeViewModel: employeeViewModel,
                              fleetViewModel: fleetViewModel,
                              notifVM: employeeViewModel.notifVM)
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func iconBox(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.12))
                .frame(width: 38, height: 38)
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private var driveStatusBadge: some View {
        let (label, color): (String, Color) = {
            switch tracker.status {
            case .driving:    return ("Driving", .green)
            case .onBreak:    return ("On Break", .orange)
            case .notDriving: return ("Not Driving", .secondary)
            case .stopped:    return ("Stopped", .yellow)
            case .notStarted: return ("Ready", .secondary)
            }
        }()
        return Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
    }


}

// ── Shared structs ────────────────────────────────────────────────────────────

struct BottomBarButton: View {
    let icon: String; let label: String; let sublabel: String?
    let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(label).font(.caption2).fontWeight(.medium).foregroundColor(.primary).lineLimit(1)
                if let sub = sublabel { Text(sub).font(.caption2).foregroundColor(.secondary).lineLimit(1) }
            }
            .frame(width: 72, height: 72).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct BarDivider: View {
    var body: some View { Divider().frame(height: 36) }
}

// ── Vehicle picker ────────────────────────────────────────────────────────────

struct VehiclePickerSheet: View {
    @ObservedObject var fleetViewModel: FleetViewModel
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if fleetViewModel.vehicles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "car.2").font(.system(size: 44)).foregroundColor(.secondary)
                        Text("No vehicles in fleet").font(.headline)
                        Text("Ask your admin to add vehicles.").font(.caption).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Button {
                            employeeViewModel.unassignVehicle(); dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Text("🚫").font(.title2).frame(width: 40, height: 40)
                                    .background(Color(.systemGroupedBackground)).cornerRadius(10)
                                Text("No vehicle").font(.subheadline).foregroundColor(.primary)
                                Spacer()
                                if employeeViewModel.employee?.assignedVehicleId == nil {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                        }.buttonStyle(.plain)
                        ForEach(fleetViewModel.vehicles) { vehicle in
                            Button {
                                employeeViewModel.assignVehicle(vehicle.id); dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    VehicleIconView(vehicle: vehicle, size: 44)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(vehicle.displayName).font(.subheadline)
                                            .fontWeight(.semibold).foregroundColor(.primary)
                                        if !vehicle.licensePlate.isEmpty {
                                            Text(vehicle.licensePlate).font(.caption).foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if employeeViewModel.employee?.assignedVehicleId == vehicle.id {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                            }.buttonStyle(.plain)
                        }
                    }.listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Vehicle").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
