//
//  MenuButtonStyle.swift
//  Fleet-Tracker
//

import SwiftUI

// ── Shared style ────────────────────────────────────────────────────────────
// Every item in the admin/employee dropdown uses this modifier so font,
// padding, icon size, and corner radius are always identical.

struct MenuItemStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .imageScale(.medium)          // keeps SF Symbol icons uniform
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minWidth: 140, alignment: .leading)  // all pills same width
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

extension View {
    func menuItemStyle(color: Color) -> some View {
        modifier(MenuItemStyle(color: color))
    }
}
