//
//  ExpenseModel.swift
//  Fleet-Tracker
//

import Foundation

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case fuel        = "Fuel"
    case maintenance = "Maintenance"
    case tolls       = "Tolls"
    case parking     = "Parking"
    case food        = "Food & Drink"
    case supplies    = "Supplies"
    case other       = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fuel:        return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .tolls:       return "road.lanes"
        case .parking:     return "p.circle.fill"
        case .food:        return "fork.knife"
        case .supplies:    return "shippingbox.fill"
        case .other:       return "ellipsis.circle.fill"
        }
    }
}

struct ExpenseModel: Identifiable {
    let id:           String
    let uid:          String
    let employeeName: String
    let businessId:   String
    let category:     String
    let amount:       Double
    let note:         String
    let date:         Date
    let receiptURL:   String?   // Firebase Storage URL
    let vehicleId:    String?
}
