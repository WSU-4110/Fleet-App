import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var viewModel = SignInViewModel()
    @StateObject private var employeeViewModel = EmployeeViewModel()
    @State private var menuOpen = false
    @State private var activeRole: UserRole = .none

    enum UserRole { case none, admin, employee }

    var body: some View {
        Group {
            switch activeRole {
            case .admin:
                NavigationStack {
                    ZStack {
                        MapViewWrapper()

                        VStack {
                            Spacer()
                            HStack {
                                PhotoUploadView().padding()
                                Spacer()
                            }
                        }

                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 12) {
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
                                        NavigationLink {
                                            AccessCodeView().navigationTitle("Access Code")
                                        } label: {
                                            HStack {
                                                Image(systemName: "key.fill")
                                                Text("Access Code").font(.caption)
                                            }
                                            .padding(10)
                                            .background(Color.orange.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }

                                        Button {
                                            menuOpen = false
                                            viewModel.signOut()
                                            employeeViewModel.signOut()
                                            activeRole = .none
                                        } label: {
                                            HStack {
                                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                                Text("Logout").font(.caption)
                                            }
                                            .padding(10)
                                            .background(Color.red.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }

            case .employee:
                NavigationStack {
                    ZStack {
                        MapViewWrapper()

                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 12) {
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
                                        Button {
                                            employeeViewModel.clockIn()
                                            menuOpen = false
                                        } label: {
                                            HStack {
                                                Image(systemName: "clock.badge.checkmark")
                                                Text("Clock In").font(.caption)
                                            }
                                            .padding(10)
                                            .background(employeeViewModel.isClockedIn ? Color.gray.opacity(0.6) : Color.green.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                        .disabled(employeeViewModel.isClockedIn)

                                        Button {
                                            employeeViewModel.clockOut()
                                            menuOpen = false
                                        } label: {
                                            HStack {
                                                Image(systemName: "clock.badge.xmark")
                                                Text("Clock Out").font(.caption)
                                            }
                                            .padding(10)
                                            .background(!employeeViewModel.isClockedIn ? Color.gray.opacity(0.6) : Color.orange.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                        .disabled(!employeeViewModel.isClockedIn)

                                        if let clockInTime = employeeViewModel.clockInTime {
                                            Text("In: \(clockInTime.formatted(date: .omitted, time: .shortened))")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .padding(6)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(8)
                                        }

                                        Button {
                                            menuOpen = false
                                            employeeViewModel.signOut()
                                            viewModel.signOut()
                                            activeRole = .none
                                        } label: {
                                            HStack {
                                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                                Text("Logout").font(.caption)
                                            }
                                            .padding(10)
                                            .background(Color.red.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }

            case .none:
                LoginView(viewModel: viewModel, employeeViewModel: employeeViewModel)
            }
        }
        .onChange(of: viewModel.user) {
            if viewModel.user != nil { activeRole = .admin }
            else if employeeViewModel.employee == nil { activeRole = .none }
        }
        .onChange(of: employeeViewModel.employee) {
            if employeeViewModel.employee != nil { activeRole = .employee }
            else if viewModel.user == nil { activeRole = .none }
        }
    }
}
