//
//  EmployeeModel.swift
//  Fleet-Tracker
//

import Foundation

struct EmployeeModel: Equatable {
    let uid:               String
    let name:              String
    var pinEmoji:          String
    var pinImageURL:       String?
    var isClockedIn:       Bool
    var clockInTime:       Date?
    var clockOutTime:      Date?
    var latitude:          Double?
    var longitude:         Double?
    var lastAddress:       String?
    var speedMPH:          Double?
    var assignedVehicleId: String?
    var lastShiftMiles:    Double?     // saved on clock-out

    init(uid: String, name: String, pinEmoji: String = "🚗",
         pinImageURL: String? = nil, isClockedIn: Bool = false,
         clockInTime: Date? = nil, clockOutTime: Date? = nil,
         latitude: Double? = nil, longitude: Double? = nil,
         lastAddress: String? = nil, speedMPH: Double? = nil,
         assignedVehicleId: String? = nil,
         lastShiftMiles: Double? = nil) {
        self.uid               = uid
        self.name              = name
        self.pinEmoji          = pinEmoji
        self.pinImageURL       = pinImageURL
        self.isClockedIn       = isClockedIn
        self.clockInTime       = clockInTime
        self.clockOutTime      = clockOutTime
        self.latitude          = latitude
        self.longitude         = longitude
        self.lastAddress       = lastAddress
        self.speedMPH          = speedMPH
        self.assignedVehicleId = assignedVehicleId
        self.lastShiftMiles    = lastShiftMiles
    }
}
