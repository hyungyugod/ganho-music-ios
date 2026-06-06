//
//  CharacterUnlockState.swift
//  GanhoMusic Shared
//
//  Sprint 3 - Character locked/unlocked presentation model.
//

import Foundation

struct CharacterUnlockState {

    // MARK: - Properties
    let characterID: CharacterID
    let isUnlocked: Bool
    let requiredCharacterID: CharacterID?
    let requiredScore: Int?

    var requirementText: String {
        guard !isUnlocked else { return GameConfig.characterHomeUnlockedText }
        guard let requiredCharacterID = requiredCharacterID else {
            return GameConfig.characterHomeLockedText
        }
        if let requiredScore = requiredScore {
            return "\(requiredCharacterID.displayName) \(requiredScore)\(GameConfig.characterHomePointSuffixText) \(GameConfig.characterHomeAchievedText)"
        }
        return "\(requiredCharacterID.displayName) \(GameConfig.characterHomeUnlockRequirementSuffix)"
    }

    // MARK: - Factories
    static func unlocked(_ characterID: CharacterID) -> CharacterUnlockState {
        return CharacterUnlockState(
            characterID: characterID,
            isUnlocked: true,
            requiredCharacterID: nil,
            requiredScore: nil
        )
    }

    static func locked(_ characterID: CharacterID,
                       requiredCharacterID: CharacterID) -> CharacterUnlockState {
        return CharacterUnlockState(
            characterID: characterID,
            isUnlocked: false,
            requiredCharacterID: requiredCharacterID,
            requiredScore: GameConfig.characterUnlockRequiredScore
        )
    }
}
