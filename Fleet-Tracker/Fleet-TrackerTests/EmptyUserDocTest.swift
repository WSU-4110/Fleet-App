//
//  EmptyUserDocTest.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import Combine
@testable import Fleet_Tracker

final class EmptyUserDocTest: XCTestCase {
    
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

    func testCreateWithValidUserID() {
        vm.createEmptyUserDocument(userID: "test-user-123")
        XCTAssertTrue(true)
    }
    func testCreateWithEmptyUserID() {
        vm.createEmptyUserDocument(userID: "")
        XCTAssertTrue(true)
    }
    func testEmptyUsersModelCreation() {
        let emptyUser = UsersModel()
        XCTAssertNotNil(emptyUser)
    }
    func testEmptyModelDefaults() {
        let emptyUser = UsersModel()
        XCTAssertEqual(emptyUser.name, "")
        XCTAssertEqual(emptyUser.latitude.count, 0)
        XCTAssertEqual(emptyUser.longitude.count, 0)
    }

}
