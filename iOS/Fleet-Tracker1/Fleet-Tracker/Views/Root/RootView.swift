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
    @StateObject private var fleetViewModel    = FleetViewModel()
    @StateObject private var speedMonitor      = SpeedMonitor()
    @StateObject private var notifVM           = NotificationViewModel()
    @State private var menuOpen    = false
    @State private var activeRole: UserRole = {
        switch UserDefaults.standard.string(forKey: "lastRole") {
        case "admin":    return .admin
        case "employee": return .employee
        default:         return .none
        }
    }()
    @State private var mapStyle:   MapStyleOption = .standard
    @State private var showRoster      = true
    @State private var centerAdmin      = false
    @State private var centerEmployee  = false
    @State private var sessionRestored  = false

    var body: some View {
        Group {
            switch activeRole {

            // ── Admin ──────────────────────────────────────────────────────
            case .admin:
                NavigationStack {
                    ZStack {
                        AdminMapView(
                            employees: employeeViewModel.allEmployees,
                            mapStyle:  mapStyle.gmsType,
                            onCenter:  centerAdmin ? { vc in vc.centerOnUser(); DispatchQueue.main.async { centerAdmin = false } } : nil
                        )
                        .ignoresSafeArea()

                        // Pill + menu stacked together top-right
                        VStack {
                            HStack(alignment: .top) {
                                // Speed alert banner on the left
                                SpeedAlertBanner(speedMonitor: speedMonitor)
                                    .padding(.top, 8)

                                Spacer()

                                // Pill and 3-dot menu stacked vertically on the right
                                // Both pinned to the same 54pt column so edges align
                                VStack(alignment: .trailing, spacing: 10) {
                                    MapControls(
                                        selected:         $mapStyle,
                                        showStyleMenu:    true,
                                        onCenterLocation: { centerAdmin = true }
                                    )
                                    .frame(width: 54)  // match tile width

                                    AdminMenuView(
                                        menuOpen:          $menuOpen,
                                        activeRole:        $activeRole,
                                        signInViewModel:   viewModel,
                                        employeeViewModel: employeeViewModel,
                                        fleetViewModel:    fleetViewModel,
                                        notifVM:           notifVM
                                    )
                                    .frame(width: 54, alignment: .trailing)
                                }
                                .padding(.trailing, 12)
                                .padding(.top, 52)
                            }
                            .padding(.leading, 12)
                            Spacer()
                        }
                    }
                    .sheet(isPresented: $showRoster) {
                        EmployeeRosterView(
                            employees: employeeViewModel.allEmployees,
                            vehicles:  fleetViewModel.vehicles
                        )
                        .presentationDetents([.height(60), .fraction(0.35), .fraction(0.65), .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                        .interactiveDismissDisabled(true)
                    }
                }


            // ── Employee ───────────────────────────────────────────────────
            case .employee:
                ZStack {
                    EmployeeMapView(
                        employee:           employeeViewModel.employee,
                        mapStyle:           mapStyle.gmsType,
                        onCenter:           centerEmployee ? { vc in vc.centerOnUser(); DispatchQueue.main.async { centerEmployee = false } } : nil
                    )
                    .ignoresSafeArea()

                    // Map controls pill — top right
                    VStack {
                        HStack {
                            Spacer()
                            MapControls(
                                selected:         $mapStyle,
                                showStyleMenu:    false,
                                onCenterLocation: { centerEmployee = true }
                            )
                            .padding(.trailing, 12)
                            .padding(.top, 60)
                        }
                        Spacer()
                    }

                    // Pull-up sheet — self contained
                    EmployeeBottomBar(
                        employeeViewModel: employeeViewModel,
                        fleetViewModel:    fleetViewModel,
                        signInViewModel:   viewModel,
                        activeRole:        $activeRole
                    )
                }

            // ── Login ──────────────────────────────────────────────────────
            case .none:
                LoginView(viewModel: viewModel, employeeViewModel: employeeViewModel)
            }
        }
        .onAppear {
            // Try immediately with what we have
            restoreSession()
            sessionRestored = true
            // Then retry after Firebase settles in case nothing was ready yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                restoreSession()
            }
        }
        .onChange(of: viewModel.user) {
            if viewModel.user != nil {
                // Only become admin if that's the saved role
                if UserDefaults.standard.string(forKey: "lastRole") != "employee" {
                    activeRole = .admin
                }
            } else if employeeViewModel.employee == nil {
                activeRole = .none
            }
        }
        .onChange(of: viewModel.businessId) {
            guard let bid = viewModel.businessId, !bid.isEmpty else { return }
            guard UserDefaults.standard.string(forKey: "lastRole") != "employee" else { return }
            activeRole = .admin
            startAdminWatching(bid: bid)
        }
        .onChange(of: employeeViewModel.employee) {
            if employeeViewModel.employee != nil  { activeRole = .employee }
            else if viewModel.user == nil         { activeRole = .none     }

        }
        .onChange(of: employeeViewModel.businessId) {
            guard let bid = employeeViewModel.businessId, !bid.isEmpty else { return }
            fleetViewModel.startWatching(businessId: bid)
            employeeViewModel.notifVM = notifVM
        }
        .onChange(of: employeeViewModel.allEmployees) {
            if activeRole == .admin {
                speedMonitor.checkSpeeds(employees: employeeViewModel.allEmployees)
            }
        }
    }

    // ── Called on appear AND on every relevant state change ──────────────────
    // Ensures listeners are always running regardless of launch order

    // Restores session on launch after Firebase Auth has a moment to settle
    private func restoreSession() {
        let lastRole = UserDefaults.standard.string(forKey: "lastRole")

        if lastRole == "employee" {
            // Employee path — EmployeeViewModel restores via its own auth listener
            if let bid = employeeViewModel.businessId, !bid.isEmpty {
                activeRole = .employee
                fleetViewModel.startWatching(businessId: bid)
                employeeViewModel.notifVM = notifVM
            }
        } else if lastRole == "admin" || lastRole == nil {
            // Admin path
            if let bid = viewModel.businessId, !bid.isEmpty {
                activeRole = .admin
                startAdminWatching(bid: bid)
            }
        }
    }

    private func startAdminWatching(bid: String) {
        employeeViewModel.startWatchingAllEmployees(businessId: bid)
        fleetViewModel.startWatching(businessId: bid)
        speedMonitor.configure(businessId: bid)
        notifVM.configure(businessId: bid)
        speedMonitor.notifVM = notifVM
    }
}
