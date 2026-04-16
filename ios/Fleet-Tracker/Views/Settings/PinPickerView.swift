//
//  PinPickerView.swift
//  Fleet-Tracker
//

import SwiftUI

// ── Vehicle pin options ───────────────────────────────────────────────────────

struct VehiclePin: Identifiable {
    let id: String
    let label: String
    let emoji: String
}

private let vehiclePins: [VehiclePin] = [
    VehiclePin(id: "sedan",       label: "Sedan",       emoji: "🚗"),
    VehiclePin(id: "pickup",      label: "Pickup",      emoji: "🛻"),
    VehiclePin(id: "suv",         label: "SUV",         emoji: "🚙"),
    VehiclePin(id: "semi",        label: "Commercial",  emoji: "🚛"),
    VehiclePin(id: "van",         label: "Van",         emoji: "🚐"),
    VehiclePin(id: "tractor",     label: "Tractor",     emoji: "🚜"),
    VehiclePin(id: "truck",       label: "Box Truck",   emoji: "🚚"),
    VehiclePin(id: "cement",      label: "Cement",      emoji: "🚛"),
    VehiclePin(id: "tuk",         label: "Tuk-Tuk",     emoji: "🛺"),
]

// ── View ──────────────────────────────────────────────────────────────────────

struct PinPickerView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab   = 0
    @State private var showPicker    = false
    @State private var pickedImage: UIImage?
    @State private var isUploading   = false
    @State private var uploadError: String?

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Pin type", selection: $selectedTab) {
                    Text("Vehicle").tag(0)
                    Text("Custom Icon").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    vehicleGrid
                } else {
                    customIconTab
                }

                Spacer()
            }
            .navigationTitle("Map Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $pickedImage)
                    .onDisappear {
                        if let img = pickedImage { uploadPin(img) }
                    }
            }
        }
    }

    // ── Vehicle grid ──────────────────────────────────────────────────────────

    private var vehicleGrid: some View {
        ScrollView {
            // Featured defaults at the top
            VStack(alignment: .leading, spacing: 12) {
                Text("Default Vehicles")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vehiclePins.prefix(4)) { pin in
                        pinCell(pin)
                    }
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                Text("More")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vehiclePins.dropFirst(4)) { pin in
                        pinCell(pin)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func pinCell(_ pin: VehiclePin) -> some View {
        let isSelected = viewModel.employee?.pinEmoji == pin.emoji
                      && viewModel.employee?.pinImageURL == nil

        Button {
            viewModel.updatePin(pin.emoji)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text(pin.emoji)
                    .font(.system(size: 34))
                    .frame(width: 64, height: 54)
                    .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )

                Text(pin.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // ── Custom icon tab ───────────────────────────────────────────────────────

    private var customIconTab: some View {
        VStack(spacing: 24) {
            Group {
                if let urlStr = viewModel.employee?.pinImageURL,
                   let url    = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            ProgressView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue, lineWidth: 2))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                Text("No icon set")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
            .padding(.top, 8)

            Text("Upload an image from your library.\nIt will be used as your map marker.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if isUploading {
                ProgressView("Uploading…")
            } else {
                Button {
                    showPicker = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.borderedProminent)
            }

            if let err = uploadError {
                Text(err)
                    .font(.caption).foregroundColor(.red)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
        }
        .padding()
    }

    // ── Upload ────────────────────────────────────────────────────────────────

    private func uploadPin(_ image: UIImage) {
        isUploading = true
        uploadError = nil
        viewModel.uploadCustomPin(image: image) { error in
            isUploading = false
            if let error { uploadError = error.localizedDescription }
            else         { dismiss() }
        }
    }
}
