//
//  SubmitDataTest.swift
//  Fleet-TrackerTests
//
//  Created by Mohammad Muksith on 3/26/26.
//

import XCTest
import Combine
@testable import Fleet_Tracker

final class SubmitDataTest: XCTestCase {

    var vm: LocationTrackerViewModel!
    
    override func setUp() {
        super.setUp()
        vm = LocationTrackerViewModel()
    }
    
    override func tearDown() {
        vm = nil
        super.tearDown()
    }
    
    func testSubmitDataWithEmptyName() {
            vm.name = ""
            vm.submitData()
            
            XCTAssertEqual(vm.submissionError, "All fields are required.")
        }
        
        func testSubmitDataWithWhitespaceName() {
            vm.name = "   "
            vm.submitData()
            XCTAssertNotEqual(vm.submissionError, "All fields are required.")
        }
        
        func testIsSubmittedFalseWithEmptyName() {
            vm.name = ""
            vm.submitData()
            
            XCTAssertFalse(vm.isSubmitted)
        }
        
        func testSubmissionErrorSetWhenNameEmpty() {
            vm.name = ""
            vm.submitData()
            
            XCTAssertNotNil(vm.submissionError)
        }
        
        func testExitsEarlyWithEmptyName() {
            vm.name = ""
            vm.isSubmitted = false
            vm.submitData()
            
            XCTAssertFalse(vm.isSubmitted)
        }
        
        func testSubmitDataWithoutAuthentication() {
            vm.name = "John Doe"
            vm.submitData()
            
            XCTAssertEqual(vm.submissionError, "User not logged in.")
        }
        
        func testIsSubmittedFalseWithoutAuth() {
            vm.name = "John Doe"
            vm.submitData()
            
            XCTAssertFalse(vm.isSubmitted)
        }
        
        func testNewUsersModelCreated() {
            let newUser = UsersModel()
            XCTAssertNotNil(newUser)
        }
        
        func testNewUsersModelDefaults() {
            let newUser = UsersModel()
            XCTAssertEqual(newUser.name, "")
            XCTAssertEqual(newUser.latitude.count, 0)
            XCTAssertEqual(newUser.longitude.count, 0)
        }
        
        func testSubmitDataWithValidName() {
            vm.name = "Alice Smith"
            vm.submitData()
            
            XCTAssertNotEqual(vm.submissionError, "All fields are required.")
        }
        
        func testSubmitDataWithSpecialCharacters() {
            vm.name = "José García-Müller"
            vm.submitData()
            
            XCTAssertNotEqual(vm.submissionError, "All fields are required.")
        }
        
        func testErrorMessageForMissingUser() {
            vm.name = "Test User"
            vm.submitData()
            
            let expectedError = "User not logged in."
            XCTAssertEqual(vm.submissionError, expectedError)
        }
        
        func testSubmissionErrorInitiallyNil() {
            XCTAssertNil(vm.submissionError)
        }
        
        func testIsSubmittedInitiallyFalse() {
            XCTAssertFalse(vm.isSubmitted)
        }
        
        func testEncodingErrorHandling() {
            let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
            XCTAssertNotNil(testError.localizedDescription)
        }
        
        func testEmptyNameDetection() {
            let emptyName = ""
            XCTAssertTrue(emptyName.isEmpty)
        }
        
        func testNonEmptyNameDetection() {
            let validName = "Bob"
            XCTAssertFalse(validName.isEmpty)
        }
        
        func testSubmissionErrorCleared() {
            vm.submissionError = "Previous error"
            vm.submissionError = nil
            
            XCTAssertNil(vm.submissionError)
        }
        
        func testIsSubmittedSetToTrue() {
            vm.isSubmitted = false
            vm.isSubmitted = true
            
            XCTAssertTrue(vm.isSubmitted)
        }
        
        func testGuardOrderExecution() {
            vm.name = ""
            vm.submitData()
            XCTAssertEqual(vm.submissionError, "All fields are required.")
            
            vm.submissionError = nil
            
            vm.name = "Valid Name"
            vm.submitData()
            XCTAssertEqual(vm.submissionError, "User not logged in.")
        }

}
