//
//  RunSummary.swift
//  GanhoMusic Shared
//
//  R6 — 한 판 메타 입력/출력 값 객체 (SPEC §F9). endGame → MetaProgressRepository.recordRun의
//  단일 운반체(입력 RunSummary)와 그 반환(출력 RunMetaOutcome)을 한 트랜잭션 쌍으로 둔다
//  (SPEC 신규 10파일 고정 — 출력 봉투의 별도 파일 미지정).
//

import Foundation

/// 한 판 종료 시점의 메타 기록 입력. 전부 `let` — endGame 1회 작성 후 불변.
struct RunSummary {
    let characterID: CharacterID
    let difficulty: Difficulty
    let score: Int
    let maxCombo: Int
    /// 콤보 윈도우 만료(2.5s)로 콤보가 0으로 끊긴 횟수 (ScoreSystem.comboBreaks).
    let comboBreaks: Int
    let notesCollected: Int
    let toiletsCollected: Int
    /// 이번 판 스킬 발동 횟수 (SkillSystem 발동 확정 지점 1곳 — kim(.none)은 자연 0).
    let skillActivations: Int
    /// 박병장 등장 여부 — sergeantParkDebuted ∨ airforceTriggered (GameScene 기존 플래그 2종).
    /// AIRFORCE 이스터에그도 박병장(공군 동기) 서사의 등장 시맨틱 — sergeant_witness 판정.
    let sergeantParkAppeared: Bool
    /// 이번 판에 적용된 일일 모디파이어. nil = 일반 판.
    let dailyModifier: DailyModifier?
    /// 이번 판의 실효 목표 (음표 러시 ×1.3 ceil 포함 — GameScene.effectiveTargetScore).
    let effectiveTarget: Int
    /// 플레이한 날의 dayKey (yyyyMMdd) — 일일 최초 클리어 판정.
    let playedDayKey: String
    /// R7 §F6 — endGame이 저장 5종 *이전*에 찍은 해금 캐릭터 스냅샷 (라이브 OR 판정).
    /// recordRun이 기록 반영 후 동일 식으로 재평가해 delta = 이번 판 잠금→해금 전이를 산출.
    let unlockedCharactersBefore: [CharacterID]
}

/// recordRun의 반환 봉투 — ResultScene `runMeta`로 전달 (SPEC §F6).
struct RunMetaOutcome {
    /// 이번 판 실효 목표 — ResultScene verdict/★/부족 칩의 단일 기준 (모순 0 계약).
    let effectiveTarget: Int
    /// 이번 판 획득 별 (0...3, 실효 목표 기준).
    let earnedStars: Int
    /// 셀에 적립 시도된 별 — 일일 최초 클리어면 min(3, earned×2), 아니면 earned.
    let creditedStars: Int
    /// 이번 판 모디파이어 (표시용).
    let dailyModifier: DailyModifier?
    /// 해당 dayKey 최초 성공 여부 — 결과창 전용 배지 칩 (02 §7-4).
    let isDailyFirstClear: Bool
    /// 이번 판으로 새로 달성한 업적 — "업적 +{n}" 칩 (n ≥ 1일 때만 노드 생성).
    let newAchievements: [AchievementID]
    /// R7 §F6 — 이번 판으로 잠금→해금 전이된 캐릭터 (allCases 순서). 결과창 전용 배너 1회 —
    /// 영속 0 (라이브 OR 원칙), Scoreboard 복귀 시 runMetaForReturn이 빈 배열로 소거.
    let newlyUnlockedCharacters: [CharacterID]
    /// 기록 반영 후 총 별 (0...45) — 언락 진행 가시화.
    let totalStars: Int
    /// R12 #9 — 결과창 통계 칩 "끊김 n회". RunSummary.comboBreaks 복사 (recordRun).
    /// 1회성 연출 아님 — ResultReturnContext.runMetaForReturn이 *보존* (소거 비대상).
    let comboBreaks: Int
    /// R12 #9 — 결과창 통계 칩 "변기 n개". RunSummary.toiletsCollected 복사 — 보존 동일.
    let toiletsCollected: Int
}
