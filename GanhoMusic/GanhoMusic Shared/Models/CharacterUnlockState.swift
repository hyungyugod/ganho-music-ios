//
//  CharacterUnlockState.swift
//  GanhoMusic Shared
//
//  Sprint 3 - Character locked/unlocked presentation model.
//  R6 §F3 — 잠금 문구를 별 기준으로 교체: "★{요구} 필요 (현재 ★{보유})".
//  요구 별·현재 별 필드 추가 — 실루엣 표시는 CharacterSelectScene+Layout 기존 처리 재사용.
//

import Foundation

struct CharacterUnlockState {

    // MARK: - Properties
    let characterID: CharacterID
    let isUnlocked: Bool
    /// R6 — 잠금 시 요구 별 / 판정 시점 보유 별. 해금 상태면 nil.
    let requiredStars: Int?
    let currentStars: Int?

    var requirementText: String {
        guard !isUnlocked else { return UILayout.characterHomeUnlockedText }
        guard let requiredStars = requiredStars, let currentStars = currentStars else {
            return UILayout.characterHomeLockedText
        }
        return "\(UILayout.R6.unlockStarPrefix)\(requiredStars)\(UILayout.R6.unlockStarRequiredSuffix)"
            + "\(UILayout.R6.unlockStarCurrentPrefix)\(currentStars)\(UILayout.R6.unlockStarCurrentSuffix)"
    }

    // MARK: - Factories
    static func unlocked(_ characterID: CharacterID) -> CharacterUnlockState {
        return CharacterUnlockState(
            characterID: characterID,
            isUnlocked: true,
            requiredStars: nil,
            currentStars: nil
        )
    }

    static func locked(_ characterID: CharacterID,
                       requiredStars: Int,
                       currentStars: Int) -> CharacterUnlockState {
        return CharacterUnlockState(
            characterID: characterID,
            isUnlocked: false,
            requiredStars: requiredStars,
            currentStars: currentStars
        )
    }
}
