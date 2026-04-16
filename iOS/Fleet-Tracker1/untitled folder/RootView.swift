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
    @State private var activeRole: UserRole       = .none
    @State private var mapStyle:   MapStyleOption = .standard
    @State private var showRoster      = true
    @State private var centerAdmin    = false
    @State private var centerEmployee = false

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

                        // Map controls — top right, below the menu button
                        VStack {
                            HStack {
                                Spacer()
                                MapControls(
                                    selected:         $mapStyle,
                                    showStyleMenu:    true,
                                    onCenterLocation: { centerAdmin = true }
                                )
                                .padding(.trailing, 12)
                                .padding(.top, 120)
                            }
                            Spacer()
                        }

                        VStack {
                            HStack {
                                Spacer()
                                AdminMenuView(
                                    menuOpen:          $menuOpen,
                                    activeRole:        $activeRole,
                                    signInViewModel:   viewModel,
                                    employeeViewModel: employeeViewModel,
                                    fleetViewModel:    fleetViewModel,
                                    notifVM:           notifVM
                                )
                            }
                            // Speed alert banner sits below the menu
                            SpeedAlertBanner(speedMonitor: speedMonitor)
                                .padding(.top, 4)
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
                .onDisappear {
                    employeeViewModel.stopWatchingAllEmployees()
                    fleetViewModel.stopWatching()
                }

            // ── Employee ───────────────────────────────────────────────────
            case .employee:
                ZStack(alignment: .bottom) {
                    EmployeeMapView(
                        employee: employeeViewModel.employee,
                        mapStyle: mapStyle.gmsType,
                        onCenter: centerEmployee ? { vc in vc.centerOnUser(); DispatchQueue.main.async { centerEmployee = false } } : nil
                    )
                    .ignoresSafeArea()

                    // Map controls — top right
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

                    VStack(spacing: 0) {
                        Spacer()
                        EmployeeBottomBar(
                            employeeViewModel: employeeViewModel,
                            fleetViewModel:    fleetViewModel,
                            signInViewModel:   viewModel,
                            activeRole:        $activeRole
                        )
                    }
                }
                .ignoresSafeArea(edges: .bottom)

            // ── Login ──────────────────────────────────────────────────────
            case .none:
                LoginView(viewModel: viewModel, employeeViewModel: employeeViewModel)
            }
        }
        .onAppear {
            // Small delay to let Firebase Auth restore session first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                restoreSession()
            }
        }
        .onChange(of: viewModel.user) {
            if viewModel.user != nil                  { activeRole = .admin }
            else if employeeViewModel.employee == nil { activeRole = .none  }
        }
        .onChange(of: viewModel.businessId) {
            guard let bid = viewModel.businessId, !bid.isEmpty else { return }
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
        if let bid = viewModel.businessId, !bid.isEmpty {
            activeRole = .admin
            startAdminWatching(bid: bid)
        } else if let bid = employeeViewModel.businessId, !bid.isEmpty {
            activeRole = .employee
            fleetViewModel.startWatching(businessId: bid)
            employeeViewModel.notifVM = notifVM
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
