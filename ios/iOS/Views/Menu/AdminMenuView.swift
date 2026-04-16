//
//  AdminMenuView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminMenuView: View {
    @Binding var menuOpen:  Bool
    @Binding var activeRole: UserRole
    var signInViewModel:   SignInViewModel
    var employeeViewModel: EmployeeViewModel
    @ObservedObject var fleetViewModel: FleetViewModel
    @ObservedObject var notifVM:        NotificationViewModel

    @State private var showManageSheet      = false
    @State private var showResubscribeSheet = false
    @State private var showCancelledToast   = false
    @State private var showAccessCodeSheet  = false
    @State private var showFleetSheet       = false
    @State private var showNotifications    = false
    @State private var showHelp             = false

    private var isCancelled: Bool {
        signInViewModel.subscriptionStatus == "cancelled"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {

            // ── Trigger tile ──────────────────────────────────────────────
            WeatherTile {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        menuOpen.toggle()
                    }
                } label: {
                    Image(systemName: menuOpen ? "xmark" : "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 54, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .overlay(alignment: .topTrailing) {
                if !menuOpen && notifVM.unreadCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                        .offset(x: 2, y: -2)
                }
            }

            // ── Menu tiles ────────────────────────────────────────────────
            if menuOpen {
                VStack(alignment: .trailing, spacing: 8) {

                    menuTile(icon: "key", label: "Access Code") {
                        menuOpen = false; showAccessCodeSheet = true
                    }

                    menuTile(icon: "bell", label: "Notifications",
                             badge: notifVM.unreadCount) {
                        menuOpen = false; showNotifications = true
                    }

                    menuTile(icon: "car.2", label: "Manage Fleet") {
                        menuOpen = false; showFleetSheet = true
                    }

                    if isCancelled {
                        menuTile(icon: "arrow.clockwise", label: "Resubscribe") {
                            menuOpen = false; showResubscribeSheet = true
                        }
                    } else {
                        menuTile(icon: "creditcard", label: "Subscription") {
                            menuOpen = false; showManageSheet = true
                        }
                    }

                    menuTile(icon: "questionmark.circle", label: "Help") {
                        menuOpen = false; showHelp = true
                    }

                    menuTile(icon: "rectangle.portrait.and.arrow.right",
                             label: "Sign Out") {
                        menuOpen = false
                        UserDefaults.standard.removeObject(forKey: "lastRole")
                        signInViewModel.signOut()
                        employeeViewModel.signOut()
                        activeRole = .none
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topTrailing)))
            }

            if showCancelledToast {
                Text("Subscription cancelled")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        // ── Sheets ────────────────────────────────────────────────────────
        .sheet(isPresented: $showNotifications) {
            NotificationsView(notifVM: notifVM)
        }
        .sheet(isPresented: $showAccessCodeSheet) {
            AccessCodeView(businessId: signInViewModel.businessId ?? "")
        }
        .sheet(isPresented: $showFleetSheet) {
            FleetManagementView(fleetViewModel: fleetViewModel)
        }
        .sheet(isPresented: $showManageSheet) {
            ManageSubscriptionView(signInViewModel: signInViewModel) {
                showManageSheet = false
                withAnimation { showCancelledToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showCancelledToast = false }
                }
            }
        }
        .sheet(isPresented: $showResubscribeSheet) {
            ResubscribeView(signInViewModel: signInViewModel)
        }
        .sheet(isPresented: $showHelp) {
            AdminHelpView()
        }
    }

    // ── Tile builder ──────────────────────────────────────────────────────────

    @ViewBuilder
    private func menuTile(icon: String, label: String,
                          badge: Int = 0,
                          action: @escaping () -> Void) -> some View {
        WeatherTile {
            Button(action: action) {
                HStack(spacing: 11) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 20, alignment: .center)

                    Text(label)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    if badge > 0 {
                        Text("\(min(badge, 99))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .frame(width: 210)
            }
            .buttonStyle(.plain)
        }
    }
}

// ── WeatherTile ───────────────────────────────────────────────────────────────

struct WeatherTile<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
    }
}

struct MenuRow: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(color).frame(width: 28)
                Text(label).font(.subheadline).foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

// ── ManageSubscriptionView ────────────────────────────────────────────────────

struct ManageSubscriptionView: View {
    var signInViewModel: SignInViewModel
    var onCancelled: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: SubscriptionPlan
    @State private var showCancelConfirm = false
    @State private var isUpgrading = false
    @State private var showUpgradeToast = false

    init(signInViewModel: SignInViewModel, onCancelled: @escaping () -> Void) {
        self.signInViewModel = signInViewModel
        self.onCancelled = onCancelled
        _selectedPlan = State(initialValue: SubscriptionPlan.allCases.first { $0.rawValue == signInViewModel.currentPlan } ?? .pro)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Plan").font(.caption).foregroundColor(.secondary)
                            Text(signInViewModel.currentPlan).font(.headline)
                        }
                        Spacer()
                        Text(SubscriptionPlan.allCases.first { $0.rawValue == signInViewModel.currentPlan }?.price ?? "").font(.subheadline).foregroundColor(.secondary)
                    }.padding().background(Color.blue.opacity(0.08)).cornerRadius(14)

                    ForEach(SubscriptionPlan.allCases) { plan in
                        PlanCardSimple(plan: plan, isSelected: selectedPlan == plan, isCurrent: plan.rawValue == signInViewModel.currentPlan)
                            .onTapGesture { selectedPlan = plan }
                    }

                    let isDifferent = selectedPlan.rawValue != signInViewModel.currentPlan
                    Button {
                        isUpgrading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            signInViewModel.upgradePlan(to: selectedPlan.rawValue) { success in
                                isUpgrading = false
                                if success {
                                    withAnimation { showUpgradeToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showUpgradeToast = false } }
                                }
                            }
                        }
                    } label: {
                        if isUpgrading { ProgressView().tint(.white) }
                        else { Text(isDifferent ? "Switch to \(selectedPlan.rawValue) · \(selectedPlan.price)" : "Current Plan Selected") }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity).disabled(!isDifferent || isUpgrading)

                    if showUpgradeToast {
                        Label("Plan updated!", systemImage: "checkmark.circle.fill")
                            .font(.subheadline).foregroundColor(.green).transition(.opacity)
                    }
                    Divider().padding(.vertical, 4)
                    Button { showCancelConfirm = true } label: {
                        Text("Cancel Subscription").font(.subheadline).foregroundColor(.red)
                    }.padding(.bottom)
                }.padding()
            }
            .navigationTitle("Manage Subscription").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Cancel your subscription?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("Yes, cancel my plan", role: .destructive) {
                    signInViewModel.cancelSubscription { success in if success { dismiss(); onCancelled() } }
                }
                Button("Keep my plan", role: .cancel) {}
            } message: { Text("Your plan stays active until the end of the billing period.") }
        }
    }
}

struct ResubscribeView: View {
    var signInViewModel: SignInViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var isProcessing = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Resubscribe").font(.largeTitle).fontWeight(.bold)
                        Text("Choose a plan to reactivate your account.").font(.subheadline).foregroundColor(.secondary)
                    }.padding(.top)
                    ForEach(SubscriptionPlan.allCases) { plan in
                        PlanCardSimple(plan: plan, isSelected: selectedPlan == plan, isCurrent: false)
                            .onTapGesture { selectedPlan = plan }
                    }
                    Button {
                        isProcessing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            signInViewModel.resubscribe(plan: selectedPlan.rawValue) { success in
                                isProcessing = false
                                if success { showSuccess = true }
                            }
                        }
                    } label: {
                        if isProcessing { ProgressView().tint(.white) }
                        else { Text("Reactivate · \(selectedPlan.price)") }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity).disabled(isProcessing).padding(.top, 4)
                }.padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            .alert("Welcome back!", isPresented: $showSuccess) { Button("Let's go") { dismiss() } }
            message: { Text("Your \(selectedPlan.rawValue) plan is now active.") }
        }
    }
}

struct PlanCardSimple: View {
    let plan: SubscriptionPlan; let isSelected: Bool; let isCurrent: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(plan.rawValue).font(.headline)
                    if isCurrent {
                        Text("Current").font(.caption2).fontWeight(.semibold)
                            .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue).cornerRadius(4)
                    }
                }
                Text(plan.driverLimit).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(plan.price).font(.subheadline).foregroundColor(.secondary)
            if isSelected {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).padding(.leading, 8)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground))
            .shadow(color: isSelected ? .blue.opacity(0.25) : .black.opacity(0.07), radius: isSelected ? 8 : 4))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
    }
}

// ── AdminHelpView ─────────────────────────────────────────────────────────────

struct AdminHelpItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct AdminHelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep: Int = 0
    @State private var slideDirection: CGFloat = 1

    private let helpItems: [AdminHelpItem] = [
        AdminHelpItem(icon: "key", color: .orange, title: "Access Code",
            description: "Generate, view, or share the code employees use to join your business account. Keep the code private. Anyone with the code can register as a driver."),
        AdminHelpItem(icon: "bell", color: .red, title: "Notifications",
            description: "Review alerts like speed violations. Unread notifications show as a red badge on the menu button."),
        AdminHelpItem(icon: "car.2", color: .green, title: "Manage Fleet",
            description: "Add, edit, or remove vehicles. Each vehicle can be assigned a name, plate number, and other details visible to drivers."),
        AdminHelpItem(icon: "creditcard", color: .purple, title: "Subscription",
            description: "View your current plan, switch tiers, or cancel. If lapsed, this becomes 'Resubscribe' so you can reactivate."),
        AdminHelpItem(icon: "rectangle.portrait.and.arrow.right", color: .gray, title: "Sign Out",
            description: "Securely signs you out and returns to the login screen. Your fleet data and roster are safely stored."),
    ]

    var isLastStep: Bool { currentStep == helpItems.count - 1 }
    var item: AdminHelpItem { helpItems[currentStep] }

    var body: some View {
        NavigationStack {
            ZStack {
                item.color.opacity(0.06).ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: currentStep)

                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        ForEach(helpItems.indices, id: \.self) { idx in
                            Capsule()
                                .fill(idx == currentStep ? item.color : Color.primary.opacity(0.12))
                                .frame(width: idx == currentStep ? 22 : 6, height: 6)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 20).padding(.bottom, 36)

                    VStack(spacing: 24) {
                        ZStack {
                            Circle().fill(item.color.opacity(0.08)).frame(width: 120, height: 120)
                            Circle().fill(item.color.opacity(0.15)).frame(width: 96, height: 96)
                            Circle().fill(item.color.opacity(0.22)).frame(width: 76, height: 76)
                            Image(systemName: item.icon)
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(item.color)
                        }
                        .animation(.spring(response: 0.4), value: currentStep)

                        VStack(spacing: 10) {
                            Text(item.title).font(.title2).fontWeight(.bold).multilineTextAlignment(.center)
                            Text(item.description).font(.callout).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center).lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 28).padding(.vertical, 36)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: item.color.opacity(0.1), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: slideDirection > 0 ? .trailing : .leading).combined(with: .opacity),
                        removal:   .move(edge: slideDirection > 0 ? .leading : .trailing).combined(with: .opacity)
                    ))

                    Spacer()

                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button {
                                slideDirection = -1
                                withAnimation(.spring(response: 0.35)) { currentStep -= 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            slideDirection = 1
                            withAnimation(.spring(response: 0.35)) {
                                if isLastStep { dismiss() } else { currentStep += 1 }
                            }
                        } label: {
                            Text(isLastStep ? "Done" : "Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(item.color)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: item.color.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Admin Guide").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
    }
}
