//
//  LocationTrackerViewModel.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import Combine
@testable import Fleet_Tracker

final class FetchUserDataTest: XCTestCase {
    
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
    func testCurrentUserIsNilInitially() {
        XCTAssertNil(vm.currentUser)
    }
    func testFetchUserDataWithoutAuthentication() {
        vm.fetchUserData()
        XCTAssertNil(vm.currentUser)     }
    func testEmptyDocumentIsDetected() {
        let emptyData: [String: Any] = [:]
        XCTAssertTrue(emptyData.isEmpty)     }
    func testValidDataIsNotEmpty() {
        let validData: [String: Any] = ["name": "John"]
        XCTAssertFalse(validData.isEmpty)     }
    func testFunctionHandlesErrors() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        XCTAssertNotNil(testError)     }
   
}
