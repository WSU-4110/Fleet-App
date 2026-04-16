//
//  FleetManagementView.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

private let vehicleEmojis = ["🚗","🛻","🚙","🚛","🚌","🚐","🚑","🚒","🚓","🚜","🏎️","🚕"]

// ── Shared vehicle icon view ──────────────────────────────────────────────────
// Used in both the fleet list and the employee vehicle picker.

struct VehicleIconView: View {
    let vehicle: VehicleModel
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let urlStr = vehicle.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        Text(vehicle.emoji).font(.system(size: size * 0.6))
                    default:
                        ProgressView()
                    }
                }
            } else {
                Text(vehicle.emoji)
                    .font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }
}

// ── Fleet list ────────────────────────────────────────────────────────────────

struct FleetManagementView: View {
    @ObservedObject var fleetViewModel: FleetViewModel
    @State private var showAddSheet      = false
    @State private var vehicleToEdit:   VehicleModel?
    @State private var vehicleToDelete: VehicleModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if fleetViewModel.vehicles.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "car.2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No vehicles yet").font(.headline)
                        Text("Add your fleet vehicles so drivers can select which car they're using.")
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 32)
                        Button("Add Vehicle") { showAddSheet = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(fleetViewModel.vehicles) { vehicle in
                            HStack(spacing: 14) {
                                VehicleIconView(vehicle: vehicle, size: 48)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(vehicle.displayName)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text(vehicle.licensePlate.isEmpty
                                         ? "No plate" : vehicle.licensePlate)
                                        .font(.caption).foregroundColor(.secondary)
                                }

                                Spacer()

                                // 3-dot context menu
                                Menu {
                                    Button {
                                        vehicleToEdit = vehicle
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        vehicleToDelete   = vehicle
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vehicleToDelete   = vehicle
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Fleet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddVehicleSheet(fleetViewModel: fleetViewModel)
            }
            .sheet(item: $vehicleToEdit) { vehicle in
                EditVehicleSheet(fleetViewModel: fleetViewModel, vehicle: vehicle)
            }
            .confirmationDialog("Delete this vehicle?",
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let v = vehicleToDelete { fleetViewModel.deleteVehicle(v) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// ── Add vehicle sheet ─────────────────────────────────────────────────────────

struct AddVehicleSheet: View {
    @ObservedObject var fleetViewModel: FleetViewModel
    @Environment(\.dismiss) var dismiss

    @State private var make:          String    = ""
    @State private var model:         String    = ""
    @State private var year:          String    = ""
    @State private var licensePlate:  String    = ""
    @State private var selectedEmoji  = "🚗"
    @State private var vehiclePhoto:  UIImage?
    @State private var usePhoto       = false     // toggle between emoji and photo
    @State private var showSourcePicker  = false
    @State private var showImagePicker   = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isSaving       = false
    @State private var errorMessage:  String?

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Details") {
                    TextField("Make  (e.g. Ford)", text: $make)
                        .autocorrectionDisabled(true)
                    TextField("Model  (e.g. F-150)", text: $model)
                        .autocorrectionDisabled(true)
                    TextField("Year  (e.g. 2023)", text: $year)
                        .keyboardType(.numberPad)
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                }

                Section("Icon") {
                    // Toggle between emoji and custom photo
                    Picker("Icon type", selection: $usePhoto) {
                        Text("Emoji").tag(false)
                        Text("Photo").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if usePhoto {
                        // Photo option
                        if let img = vehiclePhoto {
                            HStack {
                                Spacer()
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture { showSourcePicker = true }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        } else {
                            Button {
                                showSourcePicker = true
                            } label: {
                                Label("Take or Choose Photo", systemImage: "camera.fill")
                            }
                        }
                    } else {
                        // Emoji option
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vehicleEmojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .frame(width: 48, height: 48)
                                            .background(selectedEmoji == emoji
                                                        ? Color.blue.opacity(0.15)
                                                        : Color(.systemGroupedBackground))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedEmoji == emoji
                                                            ? Color.blue : Color.clear,
                                                            lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showSourcePicker) {
                Button("Camera")        { sourceType = .camera;       showImagePicker = true }
                Button("Photo Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $vehiclePhoto)
            }
        }
    }

    private func save() {
        isSaving      = true
        errorMessage  = nil
        fleetViewModel.addVehicle(
            make:         make,
            model:        model,
            year:         year,
            licensePlate: licensePlate,
            emoji:        selectedEmoji,
            photo:        usePhoto ? vehiclePhoto : nil
        ) { error in
            isSaving = false
            if let error { errorMessage = error.localizedDescription }
            else         { dismiss() }
        }
    }
}

// ── Edit vehicle sheet ────────────────────────────────────────────────────────

struct EditVehicleSheet: View {
    @ObservedObject var fleetViewModel: FleetViewModel
    let vehicle: VehicleModel
    @Environment(\.dismiss) var dismiss

    @State private var make:         String
    @State private var model:        String
    @State private var year:         String
    @State private var licensePlate: String
    @State private var selectedEmoji: String
    @State private var vehiclePhoto:  UIImage?
    @State private var usePhoto:      Bool
    @State private var showSourcePicker  = false
    @State private var showImagePicker   = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isSaving      = false
    @State private var errorMessage: String?

    init(fleetViewModel: FleetViewModel, vehicle: VehicleModel) {
        self.fleetViewModel = fleetViewModel
        self.vehicle        = vehicle
        _make          = State(initialValue: vehicle.make)
        _model         = State(initialValue: vehicle.model)
        _year          = State(initialValue: vehicle.year)
        _licensePlate  = State(initialValue: vehicle.licensePlate)
        _selectedEmoji = State(initialValue: vehicle.emoji)
        _usePhoto      = State(initialValue: vehicle.photoURL != nil)
    }

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Details") {
                    TextField("Make", text: $make).autocorrectionDisabled(true)
                    TextField("Model", text: $model).autocorrectionDisabled(true)
                    TextField("Year", text: $year).keyboardType(.numberPad)
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                }

                Section("Icon") {
                    Picker("Icon type", selection: $usePhoto) {
                        Text("Emoji").tag(false)
                        Text("Photo").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if usePhoto {
                        if let img = vehiclePhoto {
                            // New photo selected
                            HStack {
                                Spacer()
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .onTapGesture { showSourcePicker = true }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        } else if let urlStr = vehicle.photoURL, let url = URL(string: urlStr) {
                            // Existing photo
                            HStack {
                                Spacer()
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    default:
                                        ProgressView().frame(width: 100, height: 100)
                                    }
                                }
                                .onTapGesture { showSourcePicker = true }
                                Spacer()
                            }
                            .padding(.vertical, 6)

                            Button("Replace Photo") { showSourcePicker = true }
                                .foregroundColor(.blue)
                        } else {
                            Button {
                                showSourcePicker = true
                            } label: {
                                Label("Take or Choose Photo", systemImage: "camera.fill")
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vehicleEmojis, id: \.self) { emoji in
                                    Button { selectedEmoji = emoji } label: {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .frame(width: 48, height: 48)
                                            .background(selectedEmoji == emoji
                                                        ? Color.blue.opacity(0.15)
                                                        : Color(.systemGroupedBackground))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedEmoji == emoji
                                                            ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showSourcePicker) {
                Button("Camera")        { sourceType = .camera;       showImagePicker = true }
                Button("Photo Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $vehiclePhoto)
            }
        }
    }

    private func save() {
        isSaving     = true
        errorMessage = nil
        fleetViewModel.updateVehicle(
            vehicle,
            make:         make,
            model:        model,
            year:         year,
            licensePlate: licensePlate,
            emoji:        selectedEmoji,
            photo:        usePhoto ? vehiclePhoto : nil
        ) { error in
            isSaving = false
            if let error { errorMessage = error.localizedDescription }
            else         { dismiss() }
        }
    }
}
