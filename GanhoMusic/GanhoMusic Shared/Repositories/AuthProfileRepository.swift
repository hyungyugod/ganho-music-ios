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
        let snapshot = AuthProfileSnapshot(
            uid: user.uid,
            isAnonymous: user.isAnonymous,
            displayName: user.displayName,
            providerIDs: user.providerData.map { $0.providerID },
            updatedAt: Date()
        )
        save(snapshot: snapshot)
    }

    func save(snapshot: AuthProfileSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
