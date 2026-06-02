//
//  AccountProgressScope.swift
//  GanhoMusic Shared
//
//  Sprint 3 - Account-scoped character progress keys.
//

import Foundation

/// UserDefaults 진행도를 현재 계정 단위로 분리하기 위한 얇은 값 객체.
struct AccountProgressScope {

    // MARK: - Properties
    let uid: String
    let isAnonymous: Bool

    var storageSuffix: String {
        return isAnonymous ? "guest.\(uid)" : "user.\(uid)"
    }

    var isLocalFallback: Bool {
        return isAnonymous && uid == GameConfig.accountProgressLocalFallbackUID
    }

    var migrationStorageKey: String {
        return "\(GameConfig.accountProgressLocalFallbackMigrationKey).\(storageSuffix)"
    }
}

enum AccountProgressScopeProvider {

    // MARK: - Current Scope
    static func current(authProfile: AuthProfileSnapshot?) -> AccountProgressScope {
        guard let profile = authProfile,
              !profile.uid.isEmpty else {
            return AccountProgressScope(
                uid: GameConfig.accountProgressLocalFallbackUID,
                isAnonymous: true
            )
        }

        return AccountProgressScope(
            uid: profile.uid,
            isAnonymous: profile.isAnonymous
        )
    }
}
