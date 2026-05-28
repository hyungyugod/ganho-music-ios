//
//  ProfilePhotoRepository.swift
//  GanhoMusic Shared
//
//  프로필 사진 로컬 저장 + Firebase Storage 업로드.
//

import Foundation
import UIKit

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
#endif

final class ProfilePhotoRepository {
    private let localProfileRepository: UserProfileRepository

    init(localProfileRepository: UserProfileRepository = UserProfileRepository()) {
        self.localProfileRepository = localProfileRepository
    }

    @discardableResult
    func save(image: UIImage) async -> UserProfile {
        let localPath = saveLocalJPEG(image: image)
        let remoteURL = await uploadIfAvailable(localPath: localPath)
        return localProfileRepository.updatePhoto(localPath: localPath, remoteURL: remoteURL)
    }

    private func saveLocalJPEG(image: UIImage) -> String? {
        let scaled = image.scaledToFit(maxSide: 512)
        guard let data = scaled.jpegData(compressionQuality: 0.82),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = directory.appendingPathComponent("profile-photo.jpg")
        do {
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            FirebaseDiagnostics.error("Local profile photo save failed.", error: error)
            return nil
        }
    }

    private func uploadIfAvailable(localPath: String?) async -> String? {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
        guard FirebaseBootstrap.configureIfAvailable(),
              let uid = Auth.auth().currentUser?.uid,
              let localPath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: localPath)) else {
            return nil
        }

        do {
            let ref = Storage.storage().reference().child("profilePhotos/\(uid)/avatar.jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            try await Firestore.firestore()
                .collection("profiles")
                .document(uid)
                .setData([
                    "photoURL": url.absoluteString,
                    "updatedAt": Timestamp(date: Date())
                ], merge: true)
            FirebaseDiagnostics.info("Profile photo uploaded uid=\(uid).")
            return url.absoluteString
        } catch {
            FirebaseDiagnostics.error("Profile photo upload failed.", error: error)
            return nil
        }
        #else
        return nil
        #endif
    }
}

private extension UIImage {
    func scaledToFit(maxSide: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxSide else { return self }
        let scale = maxSide / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
