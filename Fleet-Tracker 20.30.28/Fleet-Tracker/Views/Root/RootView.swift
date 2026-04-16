//
//  RootView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth

// Shared role enum — referenced by RootView, AdminMenuView, and EmployeeMenuView.
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
                        // Admin sees ALL employees as live markers
                        AdminMapView(employees: employeeViewModel.allEmployees)
                            .ignoresSafeArea()

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
                .onAppear  { employeeViewModel.startWatchingAllEmployees() }
                .onDisappear { employeeViewModel.stopWatchingAllEmployees() }

            // ── Employee ───────────────────────────────────────────────────
            case .employee:
                NavigationStack {
                    ZStack {
                        // Employee only sees their own pin
                        EmployeeMapView(pinEmoji: employeeViewModel.employee?.pinEmoji ?? "🚗")
                            .ignoresSafeArea()

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
            if viewModel.user != nil                  { activeRole = .admin }
            else if employeeViewModel.employee == nil { activeRole = .none  }
        }
        .onChange(of: employeeViewModel.employee) {
            if employeeViewModel.employee != nil  { activeRole = .employee }
            else if viewModel.user == nil         { activeRole = .none     }
        }
    }
}
