//
//  UserProfileRepository.swift
//  GanhoMusic Shared
//
//  닉네임 기반 개인 기록 프로필 저장소 (UserDefaults + Codable JSON)
//

import Foundation

/// Firebase Auth 연결 전에도 동일한 사용자 경험을 제공하기 위한 로컬 프로필 저장소.
/// 서버 로그인 후에는 같은 `UserProfile` 값을 Firestore profiles/{uid} 문서와 동기화한다.
final class UserProfileRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.userProfileUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 저장된 프로필. 없거나 손상되었으면 게스트 프로필을 생성해 저장한 뒤 반환한다.
    var current: UserProfile {
        if let data = defaults.data(forKey: key),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        let profile = UserProfile.makeGuest()
        save(profile)
        return profile
    }

    // MARK: - Write
    @discardableResult
    func updateNickname(_ nickname: String, now: Date = Date()) -> UserProfile {
        var profile = current
        let normalized = Self.normalizedNickname(nickname)
        profile.nickname = normalized.isEmpty ? GameConfig.defaultNickname : normalized
        profile.updatedAt = now
        save(profile)
        return profile
    }

    @discardableResult
    func updatePhoto(localPath: String?, remoteURL: String?, now: Date = Date()) -> UserProfile {
        var profile = current
        profile.localPhotoPath = localPath
        if let remoteURL {
            profile.photoURL = remoteURL
        }
        profile.updatedAt = now
        save(profile)
        return profile
    }

    @discardableResult
    func updateSelectedCharacter(_ characterID: CharacterID, now: Date = Date()) -> UserProfile {
        var profile = current
        profile.selectedCharacterID = characterID
        profile.updatedAt = now
        save(profile)
        return profile
    }

    func replace(with profile: UserProfile) {
        save(profile)
    }

    // MARK: - Helpers
    private func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: key)
    }

    static func normalizedNickname(_ nickname: String) -> String {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > GameConfig.nicknameMaxLength else { return trimmed }
        return String(trimmed.prefix(GameConfig.nicknameMaxLength))
    }
}
