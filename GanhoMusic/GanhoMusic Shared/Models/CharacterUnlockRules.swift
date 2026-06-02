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
                           graduations: [CharacterID: Date]) -> Bool {
        guard let previous = previousCharacter(for: id) else { return true }
        return graduations[previous] != nil
    }

    static func state(for id: CharacterID,
                      graduations: [CharacterID: Date]) -> CharacterUnlockState {
        guard let previous = previousCharacter(for: id) else {
            return .unlocked(id)
        }
        if graduations[previous] != nil {
            return .unlocked(id)
        }
        return .locked(id, requiredCharacterID: previous)
    }

    static func states(graduations: [CharacterID: Date]) -> [CharacterID: CharacterUnlockState] {
        var result: [CharacterID: CharacterUnlockState] = [:]
        for id in CharacterID.allCases {
            result[id] = state(for: id, graduations: graduations)
        }
        return result
    }

    static func firstUnlockedCharacter(graduations: [CharacterID: Date]) -> CharacterID {
        for id in CharacterID.allCases where isUnlocked(id, graduations: graduations) {
            return id
        }
        return .kim
    }
}
