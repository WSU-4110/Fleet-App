//
//  AddLocationTest.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import Combine
@testable import Fleet_Tracker

final class AddLocationTest: XCTestCase {
    
    var vm: LocationTrackerViewModel!
    var cancellables: Set<AnyCancellable> = []
    override func setUp() {
        super.setUp()
        vm = LocationTrackerViewModel()
    }
    override func tearDown() {
        vm = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testAddLocationWithNilCurrentUser() {
            vm.currentUser = nil
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            
            XCTAssertNil(vm.currentUser)
        }
        
        func testAddLocationWithValidUser() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            let initialCount = vm.currentUser?.locationTime.count ?? 0
            
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            
            let finalCount = vm.currentUser?.locationTime.count ?? 0
            XCTAssertGreaterThan(finalCount, initialCount)
        }
        
        func testAddLocationSkipsWithinFiveMinutes() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date()  // Just now
            
            let initialCount = vm.currentUser?.locationTime.count ?? 0
            
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            
            let finalCount = vm.currentUser?.locationTime.count ?? 0
            XCTAssertEqual(initialCount, finalCount)
        }
        
        func testAddLocationAfterFiveMinutes() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            let initialCount = vm.currentUser?.locationTime.count ?? 0
            
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            
            let finalCount = vm.currentUser?.locationTime.count ?? 0
            XCTAssertGreaterThan(finalCount, initialCount)
        }
        
        func testLastSavedDateUpdates() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            let beforeDate = vm.lastSavedDate
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            let afterDate = vm.lastSavedDate
            
            XCTAssertNotEqual(beforeDate, afterDate)
        }
        
        func testAllArraysAreUpdated() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            let testTime = "2024-01-01 10:00:00"
            let testLat = "42.3314"
            let testLon = "-83.0458"
            
            vm.addLocation(locationTime: testTime, latitude: testLat, longitude: testLon)
            
            XCTAssertTrue(vm.currentUser?.locationTime.contains(testTime) ?? false)
            XCTAssertTrue(vm.currentUser?.latitude.contains(testLat) ?? false)
            XCTAssertTrue(vm.currentUser?.longitude.contains(testLon) ?? false)
        }
        
        func testArraysStaySynchronized() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.3314", longitude: "-83.0458")
            
            let timeCount = vm.currentUser?.locationTime.count ?? 0
            let latCount = vm.currentUser?.latitude.count ?? 0
            let lonCount = vm.currentUser?.longitude.count ?? 0
            
            XCTAssertEqual(timeCount, latCount)
            XCTAssertEqual(latCount, lonCount)
        }
        
        func testMultipleLocationsAdded() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            vm.addLocation(locationTime: "2024-01-01 10:00:00", latitude: "42.1", longitude: "-83.1")
            vm.addLocation(locationTime: "2024-01-01 10:05:00", latitude: "42.2", longitude: "-83.2")
            
            XCTAssertEqual(vm.currentUser?.locationTime.count, 2)
            XCTAssertEqual(vm.currentUser?.latitude.count, 2)
            XCTAssertEqual(vm.currentUser?.longitude.count, 2)
        }
        
        func testAddLocationWithEmptyStrings() {
            var user = UsersModel()
            vm.currentUser = user
            vm.lastSavedDate = Date(timeIntervalSinceNow: -301)
            
            vm.addLocation(locationTime: "", latitude: "", longitude: "")
            
            XCTAssertTrue(vm.currentUser?.locationTime.contains("") ?? false)
        }

}
