//
//  EmployeeModelBuilder.swift
//  MohammadMuksith_homework4
//
//  Created by Mohammad Muksith on 3/6/26.
//

import Foundation

final class EmployeeModelBuilder {
    private var name: String = ""
    private var latitudes: [String]    = []
    private var longitudes: [String]   = []  
    private var locationTimes: [String] = []

    @discardableResult
    func setName(_ name: String) -> EmployeeModelBuilder {
        self.name = name   
        return self
    }

    @discardableResult
    func addLocation(lat: String, lng: String, time: String) -> EmployeeModelBuilder {
        latitudes.append(lat)
        longitudes.append(lng)
        locationTimes.append(time)
        return self
    }

    @discardableResult
    func reset() -> EmployeeModelBuilder {
        name = ""; latitudes = []; longitudes = []; locationTimes = []
        return self
    }

    func build() -> EmployeeModel {
        precondition(!name.isEmpty, "Name must be set before calling build().")
        return EmployeeModel(name: name,
                             latitude: latitudes,
                             longitude: longitudes,
                             locationTime: locationTimes)
    }
}

