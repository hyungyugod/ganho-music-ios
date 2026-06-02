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
        return authProfile?.providerIDs.contains(GameConfig.authAppleProviderID) ?? false
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
        if isAppleLinked {
            let trimmed = authProfile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let name = trimmed, !name.isEmpty else {
                return GameConfig.characterHomeAppleFallbackNameText
            }
            return name
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

    // MARK: - Progress
    var isSelectedCharacterGraduated: Bool {
        return graduatedAt != nil
    }

    var achievedRecordCount: Int {
        return records.filter { $0.isAchieved }.count
    }

    func record(for difficulty: Difficulty) -> Record? {
        return records.first { $0.difficulty == difficulty }
    }
}
