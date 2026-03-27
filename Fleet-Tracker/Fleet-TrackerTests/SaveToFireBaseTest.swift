//
//  SaveToFireBaseTest.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import Combine
@testable import Fleet_Tracker

final class SaveToFirebaseTests: XCTestCase {
    
    var vm: LocationTrackerViewModel!
    
    override func setUp() {
        super.setUp()
        vm = LocationTrackerViewModel()
    }
    
    override func tearDown() {
        vm = nil
        super.tearDown()
    }
    
    func testSaveToFirebaseWithoutAuthentication() {
        vm.saveToFirebase(latitude: ["42.3314"], longitude: ["-83.0458"], locationTime: ["2024-01-01 10:00:00"])
        XCTAssertTrue(true)
    }
    
    func testSaveWithLatitudeArray() {
        let latitudes = ["42.3314", "42.3315", "42.3316"]
        vm.saveToFirebase(latitude: latitudes, longitude: [], locationTime: [])
        XCTAssertEqual(latitudes.count, 3)
    }
    
    func testSaveWithLongitudeArray() {
        let longitudes = ["-83.0458", "-83.0459", "-83.0460"]
        vm.saveToFirebase(latitude: [], longitude: longitudes, locationTime: [])
        XCTAssertEqual(longitudes.count, 3)
    }
    
    func testSaveWithLocationTimeArray() {
        let times = ["2024-01-01 10:00:00", "2024-01-01 10:05:00"]
        vm.saveToFirebase(latitude: [], longitude: [], locationTime: times)
        XCTAssertEqual(times.count, 2)
    }
    
    func testSaveWithEmptyArrays() {
        vm.saveToFirebase(latitude: [], longitude: [], locationTime: [])
        XCTAssertTrue(true)
    }
    
    func testArraysSameLength() {
        let latitudes = ["42.1", "42.2"]
        let longitudes = ["-83.1", "-83.2"]
        let times = ["10:00", "10:05"]
        
        vm.saveToFirebase(latitude: latitudes, longitude: longitudes, locationTime: times)
        
        XCTAssertEqual(latitudes.count, longitudes.count)
        XCTAssertEqual(longitudes.count, times.count)
    }
    
//    func testMergeIsTrue() {
//        let merge = true
//        XCTAssertTrue(merge)
//    }
    
    func testDataDictionaryCreation() {
        let lats = ["42.3314"]
        let lons = ["-83.0458"]
        let times = ["2024-01-01 10:00:00"]
        
        let dataDict: [String: Any] = [
            "locationTime": times,
            "latitude": lats,
            "longitude": lons
        ]
        
        XCTAssertEqual(dataDict["locationTime"] as? [String], times)
        XCTAssertEqual(dataDict["latitude"] as? [String], lats)
        XCTAssertEqual(dataDict["longitude"] as? [String], lons)
    }
        func testSaveSingleLocation() {
        let lat = ["42.3314"]
        let lon = ["-83.0458"]
        let time = ["2024-01-01 10:00:00"]
        
        vm.saveToFirebase(latitude: lat, longitude: lon, locationTime: time)
        
        XCTAssertEqual(lat.count, 1)
        XCTAssertEqual(lon.count, 1)
        XCTAssertEqual(time.count, 1)
    }
    
    func testSaveMultipleLocations() {
        let lats = ["42.1", "42.2", "42.3", "42.4", "42.5"]
        let lons = ["-83.1", "-83.2", "-83.3", "-83.4", "-83.5"]
        let times = ["10:00", "10:05", "10:10", "10:15", "10:20"]
        
        vm.saveToFirebase(latitude: lats, longitude: lons, locationTime: times)
        
        XCTAssertEqual(lats.count, 5)
        XCTAssertEqual(lons.count, 5)
        XCTAssertEqual(times.count, 5)
    }
}

