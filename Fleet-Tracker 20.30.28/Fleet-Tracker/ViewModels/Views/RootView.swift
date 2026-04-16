//
//  RootView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth

enum UserRole { case none, admin, employee }

struct RootView: View {
    @StateObject private var viewModel         = SignInViewModel()
    @StateObject private var employeeViewModel = EmployeeViewModel()
    @State private var menuOpen   = false
    @State private var activeRole: UserRole = .none

    var body: some View {
        Group {
            switch activeRole {

            // ── Admin ──────────────────────────────────────────────────────
            case .admin:
                NavigationStack {
                    ZStack {
                        MapViewWrapper()

                        VStack {
                            HStack {
                                Spacer()
                                AdminMenuView(
                                    menuOpen:          $menuOpen,
                                    activeRole:        $activeRole,
                                    signInViewModel:   viewModel,
                                    employeeViewModel: employeeViewModel
                                )
                            }
                            Spacer()
                        }
                    }
                }

            // ── Employee ───────────────────────────────────────────────────
            case .employee:
                NavigationStack {
                    ZStack {
                        MapViewWrapper()

                        VStack {
                            HStack {
                                Spacer()
                                EmployeeMenuView(
                                    menuOpen:          $menuOpen,
                                    activeRole:        $activeRole,
                                    employeeViewModel: employeeViewModel,
                                    signInViewModel:   viewModel
                                )
                            }
                            Spacer()
                        }
                    }
                }

            // ── Login ──────────────────────────────────────────────────────
            case .none:
                LoginView(viewModel: viewModel, employeeViewModel: employeeViewModel)
            }
        }
        .onChange(of: viewModel.user) {
            if viewModel.user != nil          { activeRole = .admin }
            else if employeeViewModel.employee == nil { activeRole = .none }
        }
        .onChange(of: employeeViewModel.employee) {
            if employeeViewModel.employee != nil { activeRole = .employee }
            else if viewModel.user == nil         { activeRole = .none }
        }
    }
}
