//
//  VehicleModel.swift
//  Fleet-Tracker
//

import Foundation

struct VehicleModel: Identifiable, Equatable {
    let id:           String
    let businessId:   String
    var make:         String
    var model:        String
    var year:         String
    var licensePlate: String
    var emoji:        String
    var photoURL:     String?  

    var displayName: String { "\(year) \(make) \(model)".trimmingCharacters(in: .whitespaces) }
}
