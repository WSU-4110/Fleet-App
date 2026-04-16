//
//  ExpenseReportView.swift
//  Fleet-Tracker
//

import SwiftUI

struct ExpenseReportView: View {
    @ObservedObject var employeeViewModel: EmployeeViewModel
    @ObservedObject var fleetViewModel:    FleetViewModel
    @Environment(\.dismiss) var dismiss

    @StateObject private var expenseVM = ExpenseViewModel()
    var notifVM: NotificationViewModel? = nil

    @State private var category:     ExpenseCategory = .fuel
    @State private var amountText:   String          = ""
    @State private var note:         String          = ""
    @State private var date:         Date            = .now
    @State private var receiptImage: UIImage?
    @State private var showImagePicker   = false
    @State private var showSourcePicker  = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showSuccess       = false

    private var amount: Double { Double(amountText) ?? 0 }
    private var isValid: Bool  { amount > 0 }

    private var assignedVehicle: VehicleModel? {
        fleetViewModel.vehicles.first {
            $0.id == employeeViewModel.employee?.assignedVehicleId
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Who ───────────────────────────────────────────────────
                Section("Submitted By") {
                    HStack {
                        Image(systemName: "person.fill").foregroundColor(.secondary)
                        Text(employeeViewModel.employee?.name ?? "Unknown")
                            .foregroundColor(.primary)
                    }
                    if let v = assignedVehicle {
                        HStack {
                            Text(v.emoji)
                            Text(v.displayName).foregroundColor(.primary)
                        }
                    }
                }

                // ── Details ───────────────────────────────────────────────
                Section("Expense Details") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    HStack {
                        Text("$").foregroundColor(.secondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                // ── Receipt photo ─────────────────────────────────────────
                Section("Receipt") {
                    if let img = receiptImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .cornerRadius(10)
                            .onTapGesture { showSourcePicker = true }
                    } else {
                        Button {
                            showSourcePicker = true
                        } label: {
                            Label("Attach Receipt Photo", systemImage: "camera.fill")
                        }
                    }
                }

                if let err = expenseVM.errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Submit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") { submit() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || expenseVM.isSubmitting)
                }
            }
            .overlay {
                if expenseVM.isSubmitting {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Submitting…").font(.caption).foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
                }
            }
            .alert("Expense Submitted", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your \(category.rawValue) expense of $\(String(format: "%.2f", amount)) has been recorded.")
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showSourcePicker) {
                Button("Camera")        { sourceType = .camera;       showImagePicker = true }
                Button("Photo Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $receiptImage)
            }
        }
    }

    private func submit() {
        guard let emp = employeeViewModel.employee,
              let bid = employeeViewModel.businessId else { return }
        expenseVM.notifVM = notifVM ?? employeeViewModel.notifVM

        expenseVM.submitExpense(
            businessId:   bid,
            employeeUid:  emp.uid,
            employeeName: emp.name,
            category:     category,
            amount:       amount,
            note:         note,
            date:         date,
            vehicleId:    emp.assignedVehicleId,
            receiptImage: receiptImage
        ) { success in
            if success { showSuccess = true }
        }
    }
}
