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
        guard !isUnlocked else { return UILayout.characterHomeUnlockedText }
        guard let requiredCharacterID = requiredCharacterID else {
            return UILayout.characterHomeLockedText
        }
        if let requiredScore = requiredScore {
            return "\(requiredCharacterID.displayName) \(requiredScore)\(UILayout.characterHomePointSuffixText) \(UILayout.characterHomeAchievedText)"
        }
        return "\(requiredCharacterID.displayName) \(UILayout.characterHomeUnlockRequirementSuffix)"
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
            requiredScore: GameplayTuning.characterUnlockRequiredScore
        )
    }
}
