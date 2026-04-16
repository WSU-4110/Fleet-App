//
//  AdminMenuView.swift
//  Fleet-Tracker
//

import SwiftUI

struct AdminMenuView: View {
    @Binding var menuOpen: Bool
    @Binding var activeRole: UserRole
    var signInViewModel: SignInViewModel
    var employeeViewModel: EmployeeViewModel

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

                // Access Code
                NavigationLink {
                    AccessCodeView().navigationTitle("Access Code")
                } label: {
                    Label("Access Code", systemImage: "key.fill")
                        .menuItemStyle(color: Color.orange.opacity(0.9))
                }

                // Logout
                Button {
                    menuOpen = false
                    signInViewModel.signOut()
                    employeeViewModel.signOut()
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
