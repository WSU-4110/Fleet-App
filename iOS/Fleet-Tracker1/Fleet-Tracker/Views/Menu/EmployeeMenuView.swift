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
    @ObservedObject var fleetViewModel: FleetViewModel

    @State private var showPinPicker     = false
    @State private var showExpenseReport = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {

            // ── Circle pill button (always visible) ──────────────────────
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    menuOpen.toggle()
                }
            } label: {
                Image(systemName: menuOpen ? "xmark" : "line.3.horizontal")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
            }

            // ── Menu card drops BELOW the circle ─────────────────────────
            if menuOpen {
                VStack(spacing: 0) {
                    MenuRow(icon: "doc.text.fill", label: "Upload Expense", color: .blue) {
                        closeAndRun { showExpenseReport = true }
                    }

                    Divider().padding(.leading, 44)

                    MenuRow(icon: "mappin.circle.fill",
                            label: "\(employeeViewModel.employee?.pinEmoji ?? "🚗")  Change Pin",
                            color: .purple) {
                        closeAndRun { showPinPicker = true }
                    }

                    Divider().padding(.leading, 44)

                    MenuRow(icon: "rectangle.portrait.and.arrow.right",
                            label: "Logout", color: .red) {
                        closeAndRun {
                            employeeViewModel.signOut()
                            signInViewModel.signOut()
                            activeRole = .none
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
                .frame(width: 230)
                .transition(.asymmetric(
                    insertion:  .move(edge: .top).combined(with: .opacity),
                    removal:    .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity)
                ))
            }
        }
        .padding(.top, 52)
        .padding(.trailing, 12)
        .sheet(isPresented: $showPinPicker) {
            PinPickerView(viewModel: employeeViewModel)
        }
        .sheet(isPresented: $showExpenseReport) {
            ExpenseReportView(
                employeeViewModel: employeeViewModel,
                fleetViewModel:    fleetViewModel,
                notifVM:           employeeViewModel.notifVM
            )
        }
    }

    private func closeAndRun(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            menuOpen = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            action()
        }
    }
}
