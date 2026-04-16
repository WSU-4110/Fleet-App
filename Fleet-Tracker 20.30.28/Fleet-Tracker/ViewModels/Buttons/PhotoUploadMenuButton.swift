//
//  PhotoUploadMenuButton.swift
//  Fleet-Tracker
//

import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct PhotoUploadMenuButton: View {
    @Binding var menuOpen: Bool

    @State private var showSourcePicker = false
    @State private var showImagePicker  = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isUploading   = false
    @State private var uploadSuccess = false

    var body: some View {
        Button {
            showSourcePicker = true
        } label: {
            Label(
                isUploading   ? "Uploading…" :
                uploadSuccess ? "Uploaded!"  : "Upload Photo",
                systemImage: uploadSuccess ? "checkmark.icloud.fill" : "camera.fill"
            )
            .menuItemStyle(color: uploadSuccess
                           ? Color.green.opacity(0.9)
                           : Color.blue.opacity(0.85))
        }
        .disabled(isUploading)
        .confirmationDialog("Choose Photo Source", isPresented: $showSourcePicker) {
            Button("Camera") {
                sourceType = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                sourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
                .onDisappear {
                    if selectedImage != nil { uploadPhoto() }
                }
        }
        .onChange(of: uploadSuccess) {
            if uploadSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    uploadSuccess = false
                }
            }
        }
    }

    private func uploadPhoto() {
        guard let image = selectedImage,
              let data  = image.jpegData(compressionQuality: 0.8),
              let uid   = Auth.auth().currentUser?.uid else { return }

        isUploading   = true
        uploadSuccess = false

        let ref = Storage.storage().reference()
            .child("photos/\(uid)_\(UUID().uuidString).jpg")

        ref.putData(data, metadata: nil) { _, error in
            DispatchQueue.main.async {
                isUploading   = false
                uploadSuccess = error == nil
                selectedImage = nil
            }
        }
    }
}
