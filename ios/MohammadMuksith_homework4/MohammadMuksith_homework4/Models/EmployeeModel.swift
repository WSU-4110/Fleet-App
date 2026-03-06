//
//  EmployeeModel.swift
//  FleetTracker
//
//  Created by Mohammad Muksith on 2/18/26.
//

import Foundation

nonisolated
struct EmployeeModel: Codable, Identifiable {
    var id: UUID = .init()
    var name: String
    var latitude: [String]
    var longitude: [String]
    var locationTime: [String]
    
    enum CodingKeys: CodingKey{
        case name
        case latitude
        case longitude
        case locationTime
    }
}
