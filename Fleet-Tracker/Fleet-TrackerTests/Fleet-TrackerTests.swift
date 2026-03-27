import XCTest
import UIKit
@testable import Fleet_Tracker

final class PhotoUploadViewModelTests: XCTestCase {

    var viewModel: PhotoUploadViewModel!

    override func setUp() {
        super.setUp()
        viewModel = PhotoUploadViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testHasSelectedImage_WhenNoImage_ReturnsFalse() {
        viewModel.selectedImage = nil
        XCTAssertFalse(viewModel.hasSelectedImage())
    }

    func testHasSelectedImage_WhenImageSet_ReturnsTrue() {
        viewModel.selectedImage = UIImage(systemName: "star")
        XCTAssertTrue(viewModel.hasSelectedImage())
    }

    func testResetState_ClearsAllValues() {
        viewModel.isUploading = true
        viewModel.uploadSuccess = true
        viewModel.errorMessage = "Some error"
        viewModel.selectedImage = UIImage(systemName: "star")

        viewModel.resetState()

        XCTAssertFalse(viewModel.isUploading)
        XCTAssertFalse(viewModel.uploadSuccess)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedImage)
    }

    func testSetError_SetsMessageAndStopsUploading() {
        viewModel.isUploading = true
        viewModel.setError("Upload failed")

        XCTAssertEqual(viewModel.errorMessage, "Upload failed")
        XCTAssertFalse(viewModel.isUploading)
        XCTAssertFalse(viewModel.uploadSuccess)
    }

    func testSetSuccess_ClearsImageAndMarksSuccess() {
        viewModel.selectedImage = UIImage(systemName: "star")
        viewModel.isUploading = true

        viewModel.setSuccess()

        XCTAssertTrue(viewModel.uploadSuccess)
        XCTAssertFalse(viewModel.isUploading)
        XCTAssertNil(viewModel.selectedImage)
    }

    func testGenerateFilename_ContainsUIDAndJpgExtension() {
        let uid = "testUser123"
        let filename = viewModel.generateFilename(uid: uid)

        XCTAssertTrue(filename.hasPrefix(uid))
        XCTAssertTrue(filename.hasSuffix(".jpg"))
    }

    func testIsValidImage_WithValidImage_ReturnsTrue() {
        let image = UIImage(systemName: "star")!
        XCTAssertTrue(viewModel.isValidImage(image))
    }
}
