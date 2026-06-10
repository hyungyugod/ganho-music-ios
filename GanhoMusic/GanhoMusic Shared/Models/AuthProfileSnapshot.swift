//
//  AuthProfileSnapshot.swift
//  GanhoMusic Shared
//
//  FirebaseAuth 세션에서 UI 표시와 로컬 복원에 필요한 비민감 요약만 보관한다.
//

import Foundation

struct AuthProfileSnapshot: Codable {
    let uid: String
    let isAnonymous: Bool
    let displayName: String?
    let nickname: String?
    let providerIDs: [String]
    let updatedAt: Date

    var isAppleLinked: Bool {
        return providerIDs.contains(StorageKeys.authAppleProviderID)
    }

    var preferredDisplayName: String? {
        if let nickname = trimmedNonEmpty(nickname) {
            return nickname
        }
        return trimmedNonEmpty(displayName)
    }

    var needsNicknameSetup: Bool {
        return isAppleLinked && trimmedNonEmpty(nickname) == nil
    }

    private func trimmedNonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
