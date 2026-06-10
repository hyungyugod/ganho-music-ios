//
//  CloudProgressSnapshot.swift
//  GanhoMusic Shared
//
//  UserDefaults 기반 진행도 저장소들을 Firestore summary 문서 형태로 변환한다.
//  R6 §F4 — meta 필드는 *optional 추가만* (Codable 자동 합성이 optional은 decodeIfPresent —
//  필드 부재 구버전 문서도 디코드 성공, T6). non-optional 추가 금지 (기존 문서 디코드 전손).
//

import Foundation

/// R6 — 클라우드 합류용 메타 진행 raw 봉투 (snapshot의 구성 요소 — 단독 사용 없음).
/// 키는 전부 raw 문자열(CharacterID/Difficulty/AchievementID.rawValue) — 로컬 직렬화와 동형.
struct CloudMetaProgress: Codable {
    let starCells: [String: [String: Int]]
    let achievements: [String: Date]
    let dailyClearedDayKeys: [String]
    let counters: [String: Int]
}

struct CloudProgressSnapshot: Codable {
    let highScore: Int
    let stats: GameStats
    let perDifficultyScores: [String: [String: Int]]
    let graduations: [String: Date]
    let updatedAt: Date
    /// R6 — optional meta (구버전 문서 부재 시 nil — 디코드 성공 보장).
    let meta: CloudMetaProgress?

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

    /// R6 — meta 기본값 nil 인자 추가 (기존 호출부 시그니처 호환 — SPEC §F4).
    static func make(highScore: Int,
                     stats: GameStats,
                     perDifficultyScores: [CharacterID: [Difficulty: Int]],
                     graduations: [CharacterID: Date],
                     updatedAt: Date = Date(),
                     meta: CloudMetaProgress? = nil) -> CloudProgressSnapshot {
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
            updatedAt: updatedAt,
            meta: meta
        )
    }
}
