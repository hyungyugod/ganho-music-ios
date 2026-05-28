//
//  CharacterUnlockRepository.swift
//  GanhoMusic Shared
//
//  캐릭터 해금 조건의 단일 진실 원천.
//

import Foundation

struct CharacterUnlockRepository {
    private let statisticsRepository: StatisticsRepository

    init(statisticsRepository: StatisticsRepository = StatisticsRepository()) {
        self.statisticsRepository = statisticsRepository
    }

    func isUnlocked(_ id: CharacterID) -> Bool {
        return isUnlocked(id, forPlayCount: playCount)
    }

    func isUnlocked(_ id: CharacterID, forPlayCount playCount: Int) -> Bool {
        return playCount >= requiredPlayCount(for: id)
    }

    func unlockedCharacters(in characters: [CharacterID] = CharacterID.allCases) -> [CharacterID] {
        return characters.filter { isUnlocked($0) }
    }

    func unlockedCharacters(forPlayCount playCount: Int, in characters: [CharacterID] = CharacterID.allCases) -> [CharacterID] {
        return characters.filter { isUnlocked($0, forPlayCount: playCount) }
    }

    func unlockedCharacterIDs(in characters: [CharacterID] = CharacterID.allCases) -> [String] {
        return unlockedCharacters(in: characters).map(\.rawValue)
    }

    func unlockedCharacterIDs(forPlayCount playCount: Int, in characters: [CharacterID] = CharacterID.allCases) -> [String] {
        return unlockedCharacters(forPlayCount: playCount, in: characters).map(\.rawValue)
    }

    func questText(for id: CharacterID) -> String {
        let required = requiredPlayCount(for: id)
        guard required > 0 else { return "기본 지급" }
        return "누적 \(required)판 플레이"
    }

    private var playCount: Int {
        return statisticsRepository.current.playCount
    }

    private func requiredPlayCount(for id: CharacterID) -> Int {
        switch id {
        case .kim: return 0
        case .jung: return 1
        case .geon: return 3
        case .im: return 5
        case .lee: return 10
        }
    }
}
