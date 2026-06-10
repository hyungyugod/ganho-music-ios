//
//  AchievementEvaluator.swift
//  GanhoMusic Shared
//
//  R6 — 업적 16종 판정 순수 로직 (SPEC §F5). repo와 분리 — 1파일 1클래스·300줄 보호.
//  실행 지점은 endGame 1회(recordRun) + 마이그레이션 백필 1회만 — update 경로 호출 0.
//  summary == nil = 백필 모드: 판 단위 조건(콤보·변기·박병장 등)은 자연 false —
//  기존 데이터만으로 판정 가능한 7종만 발화 (SPEC §F2 의도된 한계).
//

import Foundation

/// 업적 판정 입력 봉투 — 전부 읽기 전용 스냅샷 (디스크 접근 0, 순수 함수 계약).
struct AchievementContext {
    /// 이번 판 요약. nil = 마이그레이션 백필 (판 단위 조건 전부 미발화).
    let summary: RunSummary?
    /// 별 셀 (기록 반영 후) — three_star 판정.
    let starCells: [CharacterID: [Difficulty: Int]]
    /// 총 별 (기록 반영 후) — 언락 판정.
    let totalStars: Int
    /// 누적 음표 수 (기록 반영 후).
    let totalNotesCollected: Int
    /// 캐릭터별 스킬 발동 누적 (기록 반영 후).
    let skillActivations: [CharacterID: Int]
    /// 일일 도전 클리어 dayKey 수 (기록 반영 후).
    let dailyClearCount: Int
    /// 캐릭터×난이도 최고점 (perDiffRepo — endGame이 이미 갱신한 뒤의 값).
    let perDifficultyScores: [CharacterID: [Difficulty: Int]]
    /// 캐릭터별 최초 졸업 일시.
    let graduations: [CharacterID: Date]
    /// 누적 XP (GameStats.totalScore — 기록 반영 후).
    let totalXP: Int
    /// 이미 달성한 업적 — 재발화 차단.
    let achieved: Set<AchievementID>
}

/// 업적 16종 판정기. case 없는 enum — 인스턴스화 차단 (순수 static 함수만).
enum AchievementEvaluator {

    /// 미달성 업적 중 이번 평가로 새로 달성된 것 전부. allCases 순회 → 저장 순서 안정.
    static func newlyAchieved(context: AchievementContext) -> [AchievementID] {
        return AchievementID.allCases.filter { id in
            guard !context.achieved.contains(id) else { return false }
            return isSatisfied(id, context: context)
        }
    }

    /// 단일 업적 조건 판정. switch exhaustive — default 금지 (신규 업적 추가 시 컴파일 가드).
    private static func isSatisfied(_ id: AchievementID, context: AchievementContext) -> Bool {
        switch id {
        case .firstGraduation:
            // 최초 성공 판 — 또는 백필: 임의 셀 best ≥ 해당 난이도 목표.
            if let summary = context.summary, summary.score >= summary.effectiveTarget {
                return true
            }
            return anyCellMeetsTarget(context.perDifficultyScores)
        case .combo10:
            return (context.summary?.maxCombo ?? 0) >= MetaTuning.achievementComboLow
        case .combo20:
            return (context.summary?.maxCombo ?? 0) >= MetaTuning.achievementComboHigh
        case .fullComboGraduation:
            guard let summary = context.summary else { return false }
            return summary.score >= summary.effectiveTarget
                && summary.comboBreaks == 0
                && summary.notesCollected >= 1
        case .toiletManiac:
            return (context.summary?.toiletsCollected ?? 0) >= MetaTuning.achievementToiletManiacCount
        case .sergeantWitness:
            return context.summary?.sergeantParkAppeared == true
        case .kimHardClear:
            // 이번 판(kim ∧ hard ∧ 성공) — 또는 백필: kim hard 셀 best ≥ hard 목표.
            if let summary = context.summary,
               summary.characterID == .kim, summary.difficulty == .hard,
               summary.score >= summary.effectiveTarget {
                return true
            }
            return cellMeetsTarget(context.perDifficultyScores, characterID: .kim, difficulty: .hard)
        case .skillMaster:
            // 스킬 보유 4캐릭터(jung/geon/im/lee) 각각 누적 ≥ 10. kim(.none)은 대상 제외.
            let skillCharacters = CharacterID.allCases.filter { $0.skill != .none }
            return skillCharacters.allSatisfy { characterID in
                (context.skillActivations[characterID] ?? 0)
                    >= MetaTuning.achievementSkillMasterPerCharacter
            }
        case .hardAllCharacters:
            return CharacterID.allCases.allSatisfy { characterID in
                cellMeetsTarget(context.perDifficultyScores,
                                characterID: characterID, difficulty: .hard)
            }
        case .notes500:
            return context.totalNotesCollected >= MetaTuning.achievementNotesLow
        case .notes2000:
            return context.totalNotesCollected >= MetaTuning.achievementNotesHigh
        case .daily7:
            return context.dailyClearCount >= MetaTuning.achievementDailyClearGoal
        case .threeStar5:
            return threeStarCellCount(context.starCells) >= MetaTuning.achievementThreeStarCellsLow
        case .threeStar15:
            return threeStarCellCount(context.starCells) >= MetaTuning.achievementThreeStarCellsHigh
        case .allCharactersUnlocked:
            // §F3 라이브 OR 판정 — 기존 규칙 OR 총 별. 저장 0 (재설치·머지 어떤 경로도 자동 보장).
            return CharacterID.allCases.allSatisfy { characterID in
                CharacterUnlockRules.isUnlocked(
                    characterID,
                    graduations: context.graduations,
                    scores: context.perDifficultyScores,
                    totalStars: context.totalStars
                )
            }
        case .level10:
            return MetaProgression.level(forXP: context.totalXP) >= MetaTuning.achievementMaxLevel
        }
    }

    // MARK: - Helpers
    /// 임의 셀 best ≥ 해당 난이도 라이브 목표 (백필용 first_graduation).
    private static func anyCellMeetsTarget(_ scores: [CharacterID: [Difficulty: Int]]) -> Bool {
        for characterID in CharacterID.allCases {
            for difficulty in Difficulty.allCases
            where cellMeetsTarget(scores, characterID: characterID, difficulty: difficulty) {
                return true
            }
        }
        return false
    }

    private static func cellMeetsTarget(_ scores: [CharacterID: [Difficulty: Int]],
                                        characterID: CharacterID,
                                        difficulty: Difficulty) -> Bool {
        let best = scores[characterID]?[difficulty] ?? 0
        return best >= difficulty.targetScore
    }

    private static func threeStarCellCount(_ cells: [CharacterID: [Difficulty: Int]]) -> Int {
        var count = 0
        for (_, byDifficulty) in cells {
            for (_, stars) in byDifficulty where stars >= MetaProgression.maxStarsPerCell {
                count += 1
            }
        }
        return count
    }
}
