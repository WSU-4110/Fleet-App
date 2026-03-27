import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage
import Combine

class PhotoUploadViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isUploading: Bool = false
    @Published var uploadSuccess: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        self.selectedImage = nil
        self.isUploading = false
        self.uploadSuccess = false
        self.errorMessage = nil
    }

    func hasSelectedImage() -> Bool {
        return selectedImage != nil
    }

    func resetState() {
        isUploading = false
        uploadSuccess = false
        errorMessage = nil
        selectedImage = nil
    }

    func setError(_ message: String) {
        errorMessage = message
        isUploading = false
        uploadSuccess = false
    }

    func setSuccess() {
        uploadSuccess = true
        isUploading = false
        selectedImage = nil
    }

    func isValidImage(_ image: UIImage) -> Bool {
        return image.jpegData(compressionQuality: 0.8) != nil
    }

    func generateFilename(uid: String) -> String {
        return "\(uid)_\(UUID().uuidString).jpg"
    }

    func uploadPhoto() {
        guard let image = selectedImage,
              let _ = image.jpegData(compressionQuality: 0.8),
              let uid = Auth.auth().currentUser?.uid else { return }

        isUploading = true
        errorMessage = nil
        uploadSuccess = false

        let filename = generateFilename(uid: uid)
        let storageRef = Storage.storage().reference().child("photos/\(filename)")

        storageRef.putData(UIImage().jpegData(compressionQuality: 0.8)!, metadata: nil) { _, error in
            DispatchQueue.main.async {
                if let error {
                    self.setError(error.localizedDescription)
                } else {
                    self.setSuccess()
                }
            }
        }
    }
}
