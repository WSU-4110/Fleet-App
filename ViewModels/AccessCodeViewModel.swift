//
//  AccessCodeViewModel.swift
//  FleetTracker
//
//  Created by Ashley Li on 3/12/26.
//
import Foundation
import Combine

final class AccessCodeViewModel: ObservableObject {
    @Published var accessCode: String = ""
    @Published var newCode: String = ""

    func isNewCodeEmpty() -> Bool {
        return newCode.isEmpty
    }

    func uppercasedNewCode() -> String {
        return newCode.uppercased()
    }

    func displayCode() -> String {
        return accessCode.isEmpty ? "No code set" : accessCode
    }
}
