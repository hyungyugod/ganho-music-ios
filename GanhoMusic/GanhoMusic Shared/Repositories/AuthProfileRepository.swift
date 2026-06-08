//
//  AuthProfileRepository.swift
//  GanhoMusic Shared
//
//  FirebaseAuth user에서 비민감 요약만 추출해 UserDefaults에 저장한다.
//

import Foundation
import FirebaseAuth

final class AuthProfileRepository {

    // MARK: - Properties
    private let defaults: UserDefaults
    private let key: String

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.authProfileUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    var current: AuthProfileSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AuthProfileSnapshot.self, from: data)
    }

    // MARK: - Write
    func save(user: User) {
        let existing = current
        let isSameUser = existing?.uid == user.uid
        let firebaseDisplayName = sanitizedOptionalText(user.displayName)
        let preservedDisplayName = isSameUser
            ? sanitizedOptionalText(existing?.displayName) ?? firebaseDisplayName
            : firebaseDisplayName
        let preservedNickname = isSameUser
            ? sanitizedOptionalText(existing?.nickname)
            : nil
        let snapshot = AuthProfileSnapshot(
            uid: user.uid,
            isAnonymous: user.isAnonymous,
            displayName: preservedDisplayName,
            nickname: preservedNickname,
            providerIDs: user.providerData.map { $0.providerID },
            updatedAt: Date()
        )
        save(snapshot: snapshot)
    }

    func save(snapshot: AuthProfileSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    @discardableResult
    func saveProfile(uid: String,
                     isAnonymous: Bool,
                     displayName: String?,
                     nickname: String?,
                     providerIDs: [String]) -> AuthProfileSnapshot {
        let snapshot = AuthProfileSnapshot(
            uid: uid,
            isAnonymous: isAnonymous,
            displayName: sanitizedOptionalText(displayName),
            nickname: sanitizedOptionalText(nickname),
            providerIDs: providerIDs,
            updatedAt: Date()
        )
        save(snapshot: snapshot)
        return snapshot
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func sanitizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
