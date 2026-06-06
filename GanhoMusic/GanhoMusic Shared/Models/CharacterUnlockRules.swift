//
//  CharacterUnlockRules.swift
//  GanhoMusic Shared
//
//  Sprint 3 - Sequential character unlock rules.
//

import Foundation

enum CharacterUnlockRules {

    // MARK: - Rules
    static func previousCharacter(for id: CharacterID) -> CharacterID? {
        let characters = CharacterID.allCases
        guard let index = characters.firstIndex(of: id),
              index > GameConfig.characterHomeDefaultIndex else {
            return nil
        }
        return characters[index - 1]
    }

    static func isUnlocked(_ id: CharacterID,
                           graduations: [CharacterID: Date],
                           scores: [CharacterID: [Difficulty: Int]]) -> Bool {
        guard let previous = previousCharacter(for: id) else { return true }
        if graduations[previous] != nil { return true }
        return bestUnlockScore(for: previous, scores: scores) >= GameConfig.characterUnlockRequiredScore
    }

    static func state(for id: CharacterID,
                      graduations: [CharacterID: Date],
                      scores: [CharacterID: [Difficulty: Int]]) -> CharacterUnlockState {
        guard let previous = previousCharacter(for: id) else {
            return .unlocked(id)
        }
        if graduations[previous] != nil {
            return .unlocked(id)
        }
        if bestUnlockScore(for: previous, scores: scores) >= GameConfig.characterUnlockRequiredScore {
            return .unlocked(id)
        }
        return .locked(id, requiredCharacterID: previous)
    }

    static func states(graduations: [CharacterID: Date],
                       scores: [CharacterID: [Difficulty: Int]]) -> [CharacterID: CharacterUnlockState] {
        var result: [CharacterID: CharacterUnlockState] = [:]
        for id in CharacterID.allCases {
            result[id] = state(for: id, graduations: graduations, scores: scores)
        }
        return result
    }

    static func firstUnlockedCharacter(graduations: [CharacterID: Date],
                                       scores: [CharacterID: [Difficulty: Int]]) -> CharacterID {
        for id in CharacterID.allCases where isUnlocked(id, graduations: graduations, scores: scores) {
            return id
        }
        return .kim
    }

    private static func bestUnlockScore(for characterID: CharacterID,
                                        scores: [CharacterID: [Difficulty: Int]]) -> Int {
        return scores[characterID]?.values.max() ?? 0
    }
}
