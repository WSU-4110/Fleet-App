//
//  UsersModel.swift
//  Fleet-Tracker
//
//  Created by Mohammad Muksith on 3/11/26.
//

import Foundation
//
//struct UsersModel: Codable, Identifiable {
//    var id: UUID = .init()
//    var name: String
//    var latitude: [String]
//    var longitude: [String]
//    var locationTime: [String]
//    var username: String
//    var password: String
//    var email: String
//    
//    enum CodingKeys: CodingKey{
//        case name
//        case latitude
//        case longitude
//        case locationTime
//        case username
//        case password
//        case email
//    }
//}

struct UsersModel: Codable, Identifiable {
    var id: UUID = .init()
    var name: String = ""
    var latitude: [String] = []
    var longitude: [String] = []
    var locationTime: [String] = []
    var username: String = ""
    var password: String = ""
    var email: String = ""

    enum CodingKeys: CodingKey {
        case name
        case latitude
        case longitude
        case locationTime
        case username
        case password
        case email
    }
}
