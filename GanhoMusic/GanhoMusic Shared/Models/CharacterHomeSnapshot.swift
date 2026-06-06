//
//  CharacterHomeSnapshot.swift
//  GanhoMusic Shared
//
//  Sprint 2 · Character account home read model.
//

import Foundation

/// CharacterSelectScene 홈에 필요한 계정/통계/기록 요약 값 객체.
/// Repository 접근은 씬에서 끝내고, 패널 노드들은 이 Snapshot만 읽는다.
struct CharacterHomeSnapshot {

    // MARK: - Nested Types
    struct Record {
        let difficulty: Difficulty
        let bestScore: Int
        let targetScore: Int

        var isAchieved: Bool {
            return bestScore >= targetScore
        }
    }

    // MARK: - Properties
    let authProfile: AuthProfileSnapshot?
    let playCount: Int
    let totalScore: Int
    let highScore: Int
    let selectedCharacterID: CharacterID
    let unlockState: CharacterUnlockState
    let records: [Record]
    let graduatedAt: Date?
    let totalGraduationCount: Int

    // MARK: - Defaults
    static let empty = CharacterHomeSnapshot(
        authProfile: nil,
        playCount: 0,
        totalScore: 0,
        highScore: 0,
        selectedCharacterID: .kim,
        unlockState: .unlocked(.kim),
        records: Difficulty.allCases.map { difficulty in
            Record(
                difficulty: difficulty,
                bestScore: 0,
                targetScore: difficulty.targetScore
            )
        },
        graduatedAt: nil,
        totalGraduationCount: 0
    )

    // MARK: - Account Text
    var isAnonymous: Bool {
        return authProfile?.isAnonymous ?? false
    }

    var isAppleLinked: Bool {
        return authProfile?.isAppleLinked ?? false
    }

    var accountStatusText: String {
        if isAppleLinked {
            return GameConfig.authLinkedStatusText
        }
        if isAnonymous {
            return GameConfig.authGuestStatusText
        }
        return GameConfig.authLocalFallbackStatusText
    }

    var profileNameText: String {
        if let name = authProfile?.preferredDisplayName {
            return name
        }
        if isAppleLinked {
            return GameConfig.characterHomeAppleFallbackNameText
        }
        if isAnonymous {
            return GameConfig.characterHomeGuestNameText
        }
        return GameConfig.characterHomeLocalNameText
    }

    var profileSubText: String {
        if isAppleLinked {
            return GameConfig.characterHomeAppleProfileSubText
        }
        if isAnonymous {
            return GameConfig.characterHomeGuestProfileSubText
        }
        return GameConfig.characterHomeLocalProfileSubText
    }

    var profileDetailIdentityText: String {
        var lines: [String] = []
        if let nickname = trimmedNonEmpty(authProfile?.nickname) {
            lines.append("\(GameConfig.profileDetailNicknamePrefixText) \(nickname)")
        }
        if let displayName = trimmedNonEmpty(authProfile?.displayName) {
            lines.append("\(GameConfig.profileDetailDisplayNamePrefixText) \(displayName)")
        }
        if lines.isEmpty {
            lines.append(profileNameText)
        }
        lines.append(profileSubText)
        return lines.joined(separator: "\n")
    }

    private func trimmedNonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    // MARK: - Progress
    var isSelectedCharacterGraduated: Bool {
        return graduatedAt != nil
    }

    var isSelectedCharacterUnlocked: Bool {
        return unlockState.isUnlocked
    }

    var selectedRequirementText: String {
        return unlockState.requirementText
    }

    var achievedRecordCount: Int {
        return records.filter { $0.isAchieved }.count
    }

    func record(for difficulty: Difficulty) -> Record? {
        return records.first { $0.difficulty == difficulty }
    }
}
