//
//  CloudProgressSnapshot.swift
//  GanhoMusic Shared
//
//  UserDefaults 기반 진행도 저장소들을 Firestore summary 문서 형태로 변환한다.
//

import Foundation

struct CloudProgressSnapshot: Codable {
    let highScore: Int
    let stats: GameStats
    let perDifficultyScores: [String: [String: Int]]
    let graduations: [String: Date]
    let updatedAt: Date

    var typedPerDifficultyScores: [CharacterID: [Difficulty: Int]] {
        var result: [CharacterID: [Difficulty: Int]] = [:]
        for (characterRaw, scoresByDifficulty) in perDifficultyScores {
            guard let characterID = CharacterID(rawValue: characterRaw) else { continue }
            var bucket: [Difficulty: Int] = [:]
            for (difficultyRaw, score) in scoresByDifficulty {
                guard let difficulty = Difficulty(rawValue: difficultyRaw) else { continue }
                bucket[difficulty] = score
            }
            result[characterID] = bucket
        }
        return result
    }

    var typedGraduations: [CharacterID: Date] {
        var result: [CharacterID: Date] = [:]
        for (characterRaw, date) in graduations {
            guard let characterID = CharacterID(rawValue: characterRaw) else { continue }
            result[characterID] = date
        }
        return result
    }

    static func make(highScore: Int,
                     stats: GameStats,
                     perDifficultyScores: [CharacterID: [Difficulty: Int]],
                     graduations: [CharacterID: Date],
                     updatedAt: Date = Date()) -> CloudProgressSnapshot {
        var rawScores: [String: [String: Int]] = [:]
        for (characterID, scoresByDifficulty) in perDifficultyScores {
            var inner: [String: Int] = [:]
            for (difficulty, score) in scoresByDifficulty {
                inner[difficulty.rawValue] = score
            }
            rawScores[characterID.rawValue] = inner
        }

        var rawGraduations: [String: Date] = [:]
        for (characterID, date) in graduations {
            rawGraduations[characterID.rawValue] = date
        }

        return CloudProgressSnapshot(
            highScore: highScore,
            stats: stats,
            perDifficultyScores: rawScores,
            graduations: rawGraduations,
            updatedAt: updatedAt
        )
    }
}
