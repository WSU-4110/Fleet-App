//
//  EmployeeMenuView.swift
//  Fleet-Tracker
//

import SwiftUI

struct EmployeeMenuView: View {
    @Binding var menuOpen: Bool
    @Binding var activeRole: UserRole
    var employeeViewModel: EmployeeViewModel
    var signInViewModel: SignInViewModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            // Hamburger toggle
            Button {
                withAnimation(.spring()) { menuOpen.toggle() }
            } label: {
                Image(systemName: menuOpen ? "xmark" : "line.3.horizontal")
                    .font(.title2)
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            if menuOpen {
                // Photo Upload
                PhotoUploadMenuButton(menuOpen: $menuOpen)

                // Clock In
                ClockInButton(employeeViewModel: employeeViewModel, menuOpen: $menuOpen)

                // Clock Out
                ClockOutButton(employeeViewModel: employeeViewModel, menuOpen: $menuOpen)

                // Clock-in timestamp
                if let clockInTime = employeeViewModel.clockInTime {
                    Text("In: \(clockInTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 140, alignment: .leading)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }

                // Logout
                Button {
                    menuOpen = false
                    employeeViewModel.signOut()
                    signInViewModel.signOut()
                    activeRole = .none
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .menuItemStyle(color: Color.red.opacity(0.9))
                }
            }
        }
        .padding()
    }
}
