//
//  ResultReturnContext.swift
//  GanhoMusic Shared
//
//  ResultScene → ScoreboardScene → ResultScene 라운드트립용 값 봉투 (Foundation 의존만).
//  R5 — characterName(String) → characterID(CharacterID) 교체 + maxCombo/notesCollected 동기 추가
//  (newResultScene 시그니처와 1:1). 복귀 시 `isNewGraduation`/`graduatedAt`은 ScoreboardScene이
//  false/nil로 강제 덮어쓰기 — 졸업장 재표시 차단 (기존 정책 보존).
//  R6 — runMeta 추가: 복귀 재생성 시 verdict/★ 정합 유지 (음표 러시 판 필수 — nil 처리 *금지*).
//  단 일일 칩·업적 칩은 재진입 시 비표시 — ScoreboardScene이 표시 플래그만 소거한 사본으로 전달.
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
    let runMeta: RunMetaOutcome?

    /// 복귀 재생성용 runMeta — effectiveTarget(verdict 정합)은 보존, 1회성 표시 플래그
    /// (일일 클리어·신규 업적·R7 신규 해금)만 소거 (isNewGraduation: false 전례와 같은 정책).
    /// R7 §F5/F6 — 토스트·배너 재발화 0 보장 지점.
    /// R12 #9 — comboBreaks/toiletsCollected는 1회성 연출이 아닌 판 통계 → *보존* (소거 비대상).
    var runMetaForReturn: RunMetaOutcome? {
        guard let meta = runMeta else { return nil }
        return RunMetaOutcome(
            effectiveTarget: meta.effectiveTarget,
            earnedStars: meta.earnedStars,
            creditedStars: meta.creditedStars,
            dailyModifier: meta.dailyModifier,
            isDailyFirstClear: false,
            newAchievements: [],
            newlyUnlockedCharacters: [],
            totalStars: meta.totalStars,
            comboBreaks: meta.comboBreaks,
            toiletsCollected: meta.toiletsCollected
        )
    }
}
