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
