//
//  ResultReturnContext.swift
//  GanhoMusic Shared
//
//  ResultScene → ScoreboardScene → ResultScene 라운드트립용 값 봉투 (Foundation 의존만).
//  R5 — characterName(String) → characterID(CharacterID) 교체 + maxCombo/notesCollected 동기 추가
//  (newResultScene 시그니처와 1:1). 복귀 시 `isNewGraduation`/`graduatedAt`은 ScoreboardScene이
//  false/nil로 강제 덮어쓰기 — 졸업장 재표시 차단 (기존 정책 보존).
//

import Foundation

struct ResultReturnContext {
    let finalScore: Int
    let bestScore: Int
    let isNewBest: Bool
    let stats: GameStats
    let characterID: CharacterID
    let difficulty: Difficulty
    let maxCombo: Int
    let notesCollected: Int
    let isNewGraduation: Bool
    let graduatedAt: Date?
}
