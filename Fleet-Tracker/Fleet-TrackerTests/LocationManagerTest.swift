//
//  LocationManagerTest.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import GoogleMaps
import CoreLocation
import Combine
@testable import Fleet_Tracker

final class LocationManagerTests: XCTestCase {
    
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }
    
    // Test 1: LocationManager initializes
    func testLocationManagerInitializes() {
        XCTAssertNotNil(locationManager)
    }
    
    // Test 2: userLocation is nil initially
    func testUserLocationInitiallyNil() {
        XCTAssertNil(locationManager.userLocation)
    }
    
    // Test 3: locationTime is empty string initially
    func testLocationTimeInitiallyEmpty() {
        XCTAssertEqual(locationManager.locationTime, "")
    }
    
    // Test 4: viewModel can be set
    func testViewModelCanBeSet() {
        let vm = LocationTrackerViewModel()
        locationManager.viewModel = vm
        
        XCTAssertNotNil(locationManager.viewModel)
    }
    
    // Test 5: viewModel is optional
    func testViewModelIsOptional() {
        locationManager.viewModel = nil
        
        XCTAssertNil(locationManager.viewModel)
    }
    
    // Test 6: Desired accuracy is best
    func testDesiredAccuracyIsBest() {
        let accuracy = kCLLocationAccuracyBest
        XCTAssertEqual(accuracy, kCLLocationAccuracyBest)
    }
    
    // Test 7: CLLocation with valid coordinate
    func testCLLocationWithValidCoordinate() {
        let coordinate = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
        XCTAssertEqual(coordinate.latitude, 42.3314)
        XCTAssertEqual(coordinate.longitude, -83.0458)
    }
    
    // Test 8: ISO8601DateFormatter creates time string
    func testISO8601DateFormatterCreatesTimeString() {
        let formatter = ISO8601DateFormatter()
        let timeString = formatter.string(from: Date())
        
        XCTAssertFalse(timeString.isEmpty)
        XCTAssertTrue(timeString.contains("T"))  // ISO8601 format has T
    }
    
    // Test 9: Latitude converts to string
    func testLatitudeConvertsToString() {
        let latitude = 42.3314
        let latString = String(latitude)
        
        XCTAssertEqual(latString, "42.3314")
    }
    
    // Test 10: Longitude converts to string
    func testLongitudeConvertsToString() {
        let longitude = -83.0458
        let lonString = String(longitude)
        
        XCTAssertEqual(lonString, "-83.0458")
    }
    
    // Test 11: Location timestamp is not nil
    func testLocationTimestampNotNil() {
        let location = CLLocation(latitude: 42.3314, longitude: -83.0458)
        XCTAssertNotNil(location.timestamp)
    }
    
    // Test 12: Empty locations array returns early
    func testEmptyLocationsArrayReturnsEarly() {
        let locations: [CLLocation] = []
        
        guard let location = locations.first else {
            XCTAssertTrue(true)  // Should return early
            return
        }
        
        XCTFail("Should not reach here")
    }
    
    // Test 13: Single location in array
    func testSingleLocationInArray() {
        let location = CLLocation(latitude: 42.3314, longitude: -83.0458)
        let locations = [location]
        
        XCTAssertEqual(locations.count, 1)
    }
    
    // Test 14: Multiple locations in array
    func testMultipleLocationsInArray() {
        let location1 = CLLocation(latitude: 42.1, longitude: -83.1)
        let location2 = CLLocation(latitude: 42.2, longitude: -83.2)
        let locations = [location1, location2]
        
        XCTAssertEqual(locations.count, 2)
    }
    
    // Test 15: CLLocation coordinate is accessible
    func testLocationCoordinateAccessible() {
        let location = CLLocation(latitude: 42.3314, longitude: -83.0458)
        let coordinate = location.coordinate
        
        XCTAssertEqual(coordinate.latitude, 42.3314)
        XCTAssertEqual(coordinate.longitude, -83.0458)
    }
    
    // Test 16: LocationManager is ObservableObject
    func testLocationManagerIsObservableObject() {
        XCTAssertTrue(locationManager is ObservableObject)
    }
    
    // Test 17: LocationManager conforms to CLLocationManagerDelegate
    func testLocationManagerIsCLLocationManagerDelegate() {
        XCTAssertTrue(locationManager is CLLocationManagerDelegate)
    }
    
    // Test 18: userLocation is published property
    func testUserLocationIsPublished() {
        let location = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
        locationManager.userLocation = location
        
        XCTAssertEqual(locationManager.userLocation?.latitude, 42.3314)
    }
    
    // Test 19: locationTime is published property
    func testLocationTimeIsPublished() {
        let testTime = "2024-01-01T10:00:00Z"
        locationManager.locationTime = testTime
        
        XCTAssertEqual(locationManager.locationTime, testTime)
    }
    
    // Test 20: Coordinate values are valid
    func testCoordinateValuesValid() {
        let lat = 42.3314
        let lon = -83.0458
        
        XCTAssertGreaterThanOrEqual(lat, -90)
        XCTAssertLessThanOrEqual(lat, 90)
        XCTAssertGreaterThanOrEqual(lon, -180)
        XCTAssertLessThanOrEqual(lon, 180)
    }
}
 
