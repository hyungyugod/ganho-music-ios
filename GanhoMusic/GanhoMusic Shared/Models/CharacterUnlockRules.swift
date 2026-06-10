//
//  CharacterUnlockRules.swift
//  GanhoMusic Shared
//
//  Sprint 3 - Sequential character unlock rules.
//  R6 §F3 — 별 기반 언락 합류: 해금 ⟺ (기존 규칙: 이전 캐릭터 졸업 OR 25점) OR (총 별 ≥ 요구).
//  기존 규칙을 스냅샷 저장하지 않는 *살아있는 OR* — 재설치·클라우드 복원·기기 간 머지
//  어떤 경로로도 "이미 해금된 사용자 유지"가 자동 보장 (02 §7-3, 저장 0).
//

import Foundation

enum CharacterUnlockRules {

    // MARK: - Rules
    static func previousCharacter(for id: CharacterID) -> CharacterID? {
        let characters = CharacterID.allCases
        guard let index = characters.firstIndex(of: id),
              index > UILayout.characterHomeDefaultIndex else {
            return nil
        }
        return characters[index - 1]
    }

    /// R6 — 캐릭터별 요구 별 (kim 0 / jung 3 / geon 8 / im 15 / lee 24).
    static func requiredStars(for id: CharacterID) -> Int {
        return MetaTuning.unlockStarRequirement[id] ?? MetaTuning.unlockStarRequirementFallback
    }

    static func isUnlocked(_ id: CharacterID,
                           graduations: [CharacterID: Date],
                           scores: [CharacterID: [Difficulty: Int]],
                           totalStars: Int) -> Bool {
        guard let previous = previousCharacter(for: id) else { return true }
        if totalStars >= requiredStars(for: id) { return true }   // R6 별 규칙 (라이브 OR)
        if graduations[previous] != nil { return true }
        return bestUnlockScore(for: previous, scores: scores) >= GameplayTuning.characterUnlockRequiredScore
    }

    static func state(for id: CharacterID,
                      graduations: [CharacterID: Date],
                      scores: [CharacterID: [Difficulty: Int]],
                      totalStars: Int) -> CharacterUnlockState {
        guard previousCharacter(for: id) != nil else {
            return .unlocked(id)
        }
        if isUnlocked(id, graduations: graduations, scores: scores, totalStars: totalStars) {
            return .unlocked(id)
        }
        return .locked(id, requiredStars: requiredStars(for: id), currentStars: totalStars)
    }

    static func states(graduations: [CharacterID: Date],
                       scores: [CharacterID: [Difficulty: Int]],
                       totalStars: Int) -> [CharacterID: CharacterUnlockState] {
        var result: [CharacterID: CharacterUnlockState] = [:]
        for id in CharacterID.allCases {
            result[id] = state(for: id, graduations: graduations,
                               scores: scores, totalStars: totalStars)
        }
        return result
    }

    static func firstUnlockedCharacter(graduations: [CharacterID: Date],
                                       scores: [CharacterID: [Difficulty: Int]],
                                       totalStars: Int) -> CharacterID {
        for id in CharacterID.allCases
        where isUnlocked(id, graduations: graduations, scores: scores, totalStars: totalStars) {
            return id
        }
        return .kim
    }

    private static func bestUnlockScore(for characterID: CharacterID,
                                        scores: [CharacterID: [Difficulty: Int]]) -> Int {
        return scores[characterID]?.values.max() ?? 0
    }
}
