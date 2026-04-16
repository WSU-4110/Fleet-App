//
//  ClockButtons.swift
//  Fleet-Tracker
//

import SwiftUI

struct ClockInButton: View {
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @Binding var menuOpen: Bool

    var body: some View {
        Button {
            employeeViewModel.clockIn()
            menuOpen = false
        } label: {
            Label("Clock In", systemImage: "clock.badge.checkmark")
                .menuItemStyle(color: employeeViewModel.isClockedIn
                               ? Color.gray.opacity(0.6)
                               : Color.green.opacity(0.9))
        }
        .disabled(employeeViewModel.isClockedIn)
    }
}

struct ClockOutButton: View {
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @Binding var menuOpen: Bool

    var body: some View {
        Button {
            employeeViewModel.clockOut()
            menuOpen = false
        } label: {
            Label("Clock Out", systemImage: "clock.badge.xmark")
                .menuItemStyle(color: !employeeViewModel.isClockedIn
                               ? Color.gray.opacity(0.6)
                               : Color.orange.opacity(0.9))
        }
        .disabled(!employeeViewModel.isClockedIn)
    }
}
