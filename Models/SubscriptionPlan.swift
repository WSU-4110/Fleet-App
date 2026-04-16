//
//  SubscriptionPlan.swift
//  Fleet-Tracker
//

import Foundation

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case starter  = "Starter"
    case pro      = "Pro"
    case business = "Business"

    var id: String { rawValue }

    var price: String {
        switch self {
        case .starter:  return "$9.99/mo"
        case .pro:      return "$24.99/mo"
        case .business: return "$59.99/mo"
        }
    }

    var driverLimit: String {
        switch self {
        case .starter:  return "Up to 5 drivers"
        case .pro:      return "Up to 20 drivers"
        case .business: return "Unlimited drivers"
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            return ["Live GPS tracking", "Clock in / out", "Photo uploads"]
        case .pro:
            return ["Everything in Starter", "Timesheet reports", "Priority support"]
        case .business:
            return ["Everything in Pro", "Multi-admin access", "Custom branding"]
        }
    }
}
