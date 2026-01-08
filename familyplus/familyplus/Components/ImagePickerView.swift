//
//  ImagePickerView.swift
//  familyplus
//
//  SwiftUI wrapper for PHPicker and Camera for selecting/capturing images
//

import SwiftUI
import PhotosUI
import AVFoundation
import Combine
import UIKit

// MARK: - Image Source

enum ImagePickerSource {
    case photoLibrary
    case camera
}

// MARK: - Image Picker View

struct ImagePickerView: UIViewControllerRepresentable {
    let source: ImagePickerSource
    let selectionLimit: Int
    let onImagesSelected: ([UIImage]) -> Void
    let onCancel: () -> Void

    init(
        source: ImagePickerSource = .photoLibrary,
        selectionLimit: Int = 10,
        onImagesSelected: @escaping ([UIImage]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.source = source
        self.selectionLimit = selectionLimit
        self.onImagesSelected = onImagesSelected
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .photoLibrary:
            return makePhotoPicker(context: context)
        case .camera:
            return makeCameraPicker(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Photo Library Picker

    private func makePhotoPicker(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: - Camera Picker

    private func makeCameraPicker(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // Return empty controller if camera not available
            let alert = UIAlertController(
                title: "Camera Unavailable",
                message: "This device doesn't have a camera.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.onCancel()
            })
            return alert
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        // MARK: - PHPicker Delegate

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                parent.onCancel()
                return
            }

            let dispatchGroup = DispatchGroup()
            var images: [UIImage] = []
            let lock = NSLock()

            for result in results {
                dispatchGroup.enter()

                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { dispatchGroup.leave() }

                    if let image = object as? UIImage {
                        lock.lock()
                        images.append(image)
                        lock.unlock()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.parent.onImagesSelected(images)
            }
        }

        // MARK: - UIImagePicker Delegate (Camera)

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagesSelected([image])
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

// MARK: - Permission Manager

class ImagePickerPermissionManager: ObservableObject {
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined

    init() {
        checkPermissions()
    }

    func checkPermissions() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPhotoLibraryAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            photoLibraryStatus = status
        }
        return status == .authorized || status == .limited
    }

    func requestCameraAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        return granted
    }

    var canAccessPhotoLibrary: Bool {
        photoLibraryStatus == .authorized || photoLibraryStatus == .limited
    }

    var canAccessCamera: Bool {
        cameraStatus == .authorized
    }

    var photoLibraryDenied: Bool {
        photoLibraryStatus == .denied || photoLibraryStatus == .restricted
    }

    var cameraDenied: Bool {
        cameraStatus == .denied || cameraStatus == .restricted
    }
}

// MARK: - Image Source Selector View

struct ImageSourceSelectorView: View {
    @Environment(\.theme) var theme
    @StateObject private var permissionManager = ImagePickerPermissionManager()

    let onSourceSelected: (ImagePickerSource) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Photo Library Button
            sourceButton(
                icon: "photo.on.rectangle.angled",
                title: "Photo Library",
                subtitle: "Select from your photos",
                color: .blue,
                isEnabled: !permissionManager.photoLibraryDenied,
                action: {
                    Task {
                        if permissionManager.canAccessPhotoLibrary {
                            onSourceSelected(.photoLibrary)
                        } else {
                            let granted = await permissionManager.requestPhotoLibraryAccess()
                            if granted {
                                onSourceSelected(.photoLibrary)
                            }
                        }
                    }
                }
            )

            // Camera Button
            sourceButton(
                icon: "camera.fill",
                title: "Camera",
                subtitle: "Take a photo",
                color: .green,
                isEnabled: !permissionManager.cameraDenied && UIImagePickerController.isSourceTypeAvailable(.camera),
                action: {
                    Task {
                        if permissionManager.canAccessCamera {
                            onSourceSelected(.camera)
                        } else {
                            let granted = await permissionManager.requestCameraAccess()
                            if granted {
                                onSourceSelected(.camera)
                            }
                        }
                    }
                }
            )

            // Settings hint if permissions denied
            if permissionManager.photoLibraryDenied || permissionManager.cameraDenied {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.caption)
                    Text("Enable permissions in Settings")
                        .font(.caption)
                }
                .foregroundColor(theme.secondaryTextColor)
                .padding(.top, 8)
                .onTapGesture {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sourceButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isEnabled ? 0.15 : 0.05))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isEnabled ? color : theme.secondaryTextColor.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isEnabled ? theme.textColor : theme.secondaryTextColor.opacity(0.5))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor.opacity(isEnabled ? 0.5 : 0.2))
            }
            .padding(16)
            .background(theme.cardBackgroundColor)
            .cornerRadius(16)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview {
    ImageSourceSelectorView { source in
        print("Selected source: \(source)")
    }
}
