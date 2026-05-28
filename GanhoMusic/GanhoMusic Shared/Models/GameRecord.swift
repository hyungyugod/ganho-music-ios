//
//  GameRecord.swift
//  GanhoMusic Shared
//
//  Firestore에 저장할 1판 기록 값 객체.
//

import Foundation

struct GameRecord: Codable, Equatable, Sendable {
    var characterID: String
    var difficulty: String
    var score: Int
    var bestScore: Int
    var isNewBest: Bool
    var playCount: Int
    var totalScore: Int
    var graduated: Bool
    var playedAt: Date

    static func make(
        characterID: CharacterID,
        difficulty: Difficulty,
        score: Int,
        bestScore: Int,
        isNewBest: Bool,
        stats: GameStats,
        graduated: Bool,
        playedAt: Date = Date()
    ) -> GameRecord {
        return GameRecord(
            characterID: characterID.rawValue,
            difficulty: difficulty.rawValue,
            score: score,
            bestScore: bestScore,
            isNewBest: isNewBest,
            playCount: stats.playCount,
            totalScore: stats.totalScore,
            graduated: graduated,
            playedAt: playedAt
        )
    }
}
