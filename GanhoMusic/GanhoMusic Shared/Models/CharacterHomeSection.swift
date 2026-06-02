//
//  CharacterHomeSection.swift
//  GanhoMusic Shared
//
//  Sprint 2 · CharacterSelectScene account home sections.
//

import Foundation

/// 캐릭터 홈 내부 메뉴 섹션. 씬 전환이 아니라 홈 내부 focus 상태만 바꾼다.
enum CharacterHomeSection: String, CaseIterable {
    case characterSelect
    case profile
    case achievements
    case records

    var title: String {
        switch self {
        case .characterSelect:
            return GameConfig.characterHomeMenuCharacterText
        case .profile:
            return GameConfig.characterHomeMenuProfileText
        case .achievements:
            return GameConfig.characterHomeMenuAchievementsText
        case .records:
            return GameConfig.characterHomeMenuRecordsText
        }
    }
}
