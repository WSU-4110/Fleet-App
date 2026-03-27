//
//  AshleyLi_UnitTest.swift
//  AshleyLi_UnitTest
//
//  Created by Ashley Li on 3/26/26.
//

import XCTest
@testable import FleetTracker

final class AshleyLi_UnitTest: XCTestCase {

    var employeeViewModel: EmployeeViewModel!
    var accessCodeViewModel: AccessCodeViewModel!

    override func setUp() {
        super.setUp()
        employeeViewModel = EmployeeViewModel()
        accessCodeViewModel = AccessCodeViewModel()
    }

    override func tearDown() {
        employeeViewModel = nil
        accessCodeViewModel = nil
        super.tearDown()
    }

    func testIsNewCodeEmpty_WhenEmpty_ReturnsTrue() {
        accessCodeViewModel.newCode = ""
        XCTAssertTrue(accessCodeViewModel.isNewCodeEmpty(), "Should return true when newCode is empty")
    }

    func testUppercasedNewCode_ReturnsUppercase() {
        accessCodeViewModel.newCode = "abc123"
        XCTAssertEqual(accessCodeViewModel.uppercasedNewCode(), "ABC123")
    }

    func testDisplayCode_WhenEmpty_ReturnsPlaceholder() {
        accessCodeViewModel.accessCode = ""
        XCTAssertEqual(accessCodeViewModel.displayCode(), "No code set")
    }

    func testApplyClockIn_SetsClockInStateCorrectly() {
        let date = Date()
        employeeViewModel.applyClockIn(date: date)
        XCTAssertTrue(employeeViewModel.isClockedIn)
        XCTAssertEqual(employeeViewModel.clockInTime, date)
    }

    func testApplyClockOut_ClearsClockInState() {
        employeeViewModel.applyClockIn(date: Date())
        employeeViewModel.applyClockOut()
        XCTAssertFalse(employeeViewModel.isClockedIn)
        XCTAssertNil(employeeViewModel.clockInTime)
    }

    func testApplySignOut_ClearsAllState() {
        employeeViewModel.setEmployee(EmployeeModel(uid: "123", name: "John"))
        employeeViewModel.applyClockIn(date: Date())
        employeeViewModel.applySignOut()
        XCTAssertNil(employeeViewModel.employee)
        XCTAssertFalse(employeeViewModel.isClockedIn)
        XCTAssertNil(employeeViewModel.clockInTime)
    }
}
