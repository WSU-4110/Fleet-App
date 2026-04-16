//
//  PinPickerView.swift
//  Fleet-Tracker
//

import SwiftUI

// The selectable vehicle/pin options
private let pinOptions: [String] = [
    "🚗", "🚕", "🚙", "🚌", "🚎",
    "🏎️", "🚓", "🚑", "🚒", "🚐",
    "🛻", "🚚", "🚛", "🚜", "🏍️",
    "🛵", "🚲", "🛺", "🚁", "✈️"
]

struct PinPickerView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) var dismiss

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose your map pin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(pinOptions, id: \.self) { emoji in
                        Button {
                            viewModel.updatePin(emoji)
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 36))
                                .frame(width: 60, height: 60)
                                .background(
                                    viewModel.employee?.pinEmoji == emoji
                                    ? Color.blue.opacity(0.2)
                                    : Color.gray.opacity(0.1)
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.employee?.pinEmoji == emoji
                                            ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("Map Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
