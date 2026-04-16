import SwiftUI
import FirebaseStorage
import FirebaseAuth

struct PhotoUploadView: View {
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: "camera.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
            }

            Button {
                showSourcePicker = true
            } label: {
                Label("Add Photo", systemImage: "camera")
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if selectedImage != nil {
                Button {
                    uploadPhoto()
                } label: {
                    if isUploading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Upload", systemImage: "icloud.and.arrow.up")
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isUploading)
            }

            if uploadSuccess {
                Label("Uploaded!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
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
        }
    }

    func uploadPhoto() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let uid = Auth.auth().currentUser?.uid else { return }

        isUploading = true
        errorMessage = nil
        uploadSuccess = false

        let filename = "\(uid)_\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("photos/\(filename)")

        storageRef.putData(imageData, metadata: nil) { _, error in
            DispatchQueue.main.async {
                isUploading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    uploadSuccess = true
                    selectedImage = nil
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.selectedImage = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
