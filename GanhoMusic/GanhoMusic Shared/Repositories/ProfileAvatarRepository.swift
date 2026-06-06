//
//  ProfileAvatarRepository.swift
//  GanhoMusic Shared
//
//  계정 scope별 대표 초상화와 기기 로컬 커스텀 사진을 저장한다.
//

import Foundation
import SpriteKit
import UIKit

extension Notification.Name {
    static let ganhoProfilePhotoPickerRequested = Notification.Name("ganhoProfilePhotoPickerRequested")
    static let ganhoProfileAvatarDidChange = Notification.Name("ganhoProfileAvatarDidChange")
}

final class ProfileAvatarRepository {

    // MARK: - Properties
    private let scope: AccountProgressScope
    private let defaults: UserDefaults
    private let fileManager: FileManager

    private var storageKey: String {
        return "\(GameConfig.profileAvatarUserDefaultsKeyPrefix).\(scope.storageSuffix)"
    }

    private var photoDirectoryURL: URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documents.appendingPathComponent(
            GameConfig.profileAvatarPhotoDirectoryName,
            isDirectory: true
        )
    }

    // MARK: - Init
    static func scoped(scope: AccountProgressScope) -> ProfileAvatarRepository {
        return ProfileAvatarRepository(scope: scope)
    }

    init(scope: AccountProgressScope,
         defaults: UserDefaults = .standard,
         fileManager: FileManager = .default) {
        self.scope = scope
        self.defaults = defaults
        self.fileManager = fileManager
    }

    // MARK: - Read
    var current: ProfileAvatarSnapshot {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(ProfileAvatarSnapshot.self, from: data) else {
            return .defaultKim
        }
        if snapshot.selectedID == .customPhoto, customPhotoData(for: snapshot) == nil {
            let fallback = ProfileAvatarSnapshot.defaultKim
            save(snapshot: fallback)
            return fallback
        }
        return snapshot
    }

    var hasSavedSnapshot: Bool {
        return defaults.data(forKey: storageKey) != nil
    }

    func customPhotoTexture(for snapshot: ProfileAvatarSnapshot) -> SKTexture? {
        guard snapshot.selectedID == .customPhoto,
              let image = customPhotoImage(for: snapshot) else {
            return nil
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    // MARK: - Write
    func save(characterID: CharacterID) {
        save(
            snapshot: ProfileAvatarSnapshot(
                selectedID: ProfileAvatarID(characterID: characterID),
                customPhotoFileName: current.customPhotoFileName,
                updatedAt: Date()
            )
        )
    }

    func save(snapshot: ProfileAvatarSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }

    @discardableResult
    func saveCustomPhoto(_ image: UIImage) -> Bool {
        guard let directory = ensurePhotoDirectory(),
              let imageData = normalizedJPEGData(from: image) else {
            return false
        }

        let oldFileName = current.customPhotoFileName
        let fileName = customPhotoFileName()
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL, options: .atomic)
            save(
                snapshot: ProfileAvatarSnapshot(
                    selectedID: .customPhoto,
                    customPhotoFileName: fileName,
                    updatedAt: Date()
                )
            )
            removeCustomPhoto(named: oldFileName, excluding: fileName)
            return true
        } catch {
            return false
        }
    }

    func copyAvatarIfMissing(from source: ProfileAvatarRepository) {
        guard !hasSavedSnapshot else { return }
        let sourceSnapshot = source.current

        guard sourceSnapshot.selectedID == .customPhoto else {
            save(
                snapshot: ProfileAvatarSnapshot(
                    selectedID: sourceSnapshot.selectedID,
                    customPhotoFileName: sourceSnapshot.customPhotoFileName,
                    updatedAt: Date()
                )
            )
            return
        }

        guard let data = source.customPhotoData(for: sourceSnapshot),
              let directory = ensurePhotoDirectory() else {
            save(characterID: .kim)
            return
        }

        let fileName = customPhotoFileName()
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            save(
                snapshot: ProfileAvatarSnapshot(
                    selectedID: .customPhoto,
                    customPhotoFileName: fileName,
                    updatedAt: Date()
                )
            )
        } catch {
            save(characterID: .kim)
        }
    }

    // MARK: - Photo Files
    private func customPhotoImage(for snapshot: ProfileAvatarSnapshot) -> UIImage? {
        guard let data = customPhotoData(for: snapshot) else { return nil }
        return UIImage(data: data)
    }

    private func customPhotoData(for snapshot: ProfileAvatarSnapshot) -> Data? {
        guard let fileName = snapshot.customPhotoFileName,
              let directory = photoDirectoryURL else {
            return nil
        }
        let fileURL = directory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    private func ensurePhotoDirectory() -> URL? {
        guard let directory = photoDirectoryURL else { return nil }
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory
        } catch {
            return nil
        }
    }

    private func removeCustomPhoto(named oldFileName: String?, excluding newFileName: String) {
        guard let oldFileName = oldFileName,
              oldFileName != newFileName,
              let directory = photoDirectoryURL else {
            return
        }
        let fileURL = directory.appendingPathComponent(oldFileName)
        try? fileManager.removeItem(at: fileURL)
    }

    private func customPhotoFileName() -> String {
        let safeSuffix = scope.storageSuffix.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return GameConfig.profileAvatarFileNameSeparator
        }
        let suffix = String(safeSuffix)
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(GameConfig.profileAvatarPhotoFilePrefix)\(suffix)\(GameConfig.profileAvatarFileNameSeparator)\(timestamp)\(GameConfig.profileAvatarPhotoFileExtension)"
    }

    private func normalizedJPEGData(from image: UIImage) -> Data? {
        let maxSide = GameConfig.profileAvatarPhotoMaxPixelDimension
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let longestSide = max(originalSize.width, originalSize.height)
        let scale = min(1.0, maxSide / longestSide)
        let targetSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalized.jpegData(compressionQuality: GameConfig.profileAvatarPhotoJPEGCompression)
    }
}
