//
//  MetaProgression.swift
//  GanhoMusic Shared
//
//  R5 — 메타 진행(별·레벨·칭호) 표시 전용 파생 함수. R6 메타 시스템의 선행 기반.
//  수치는 02_GAME_FEEL §7-1(별 임계)·§7-2(레벨 테이블) 표를 byte-수치 그대로 복사 — 임의 변경 금지.
//  R5는 영속화 0 — 별/레벨은 기존 저장값(PerDifficultyScore·GameStats.totalScore)에서 순수 파생만.
//  UserDefaults 신규 키 0개 (불변 조건 2). R6가 이 표·함수를 그대로 소비하고 영속화만 추가한다.
//

import CoreGraphics
import Foundation

/// 메타 진행 파생 네임스페이스. case 없는 enum — 인스턴스화 차단.
enum MetaProgression {

    // MARK: - 별 임계 (02 §7-1 표 그대로)

    /// 난이도별 (★1, ★★2, ★★★3) 임계 점수. switch exhaustive — default 금지.
    /// ⚠️ 문서-코드 불일치 (구현 시 발견 — SELF_CHECK 기재): 02 §7-1의 ★1(=목표)은
    /// easy 60 / normal 50 / hard 30이지만 라이브 `GameplayTuning.targetScoreByDifficulty`는
    /// easy 70 / normal 50 / hard 40. SPEC §주의사항 7("기존 라이브 상수 값 변경 0")에 따라
    /// 라이브 목표는 불변이며, 본 표는 설계서 수치를 그대로 채택한다 — 정합은 R6 튜닝 결정 사항.
    static func starThresholds(for difficulty: Difficulty) -> (one: Int, two: Int, three: Int) {
        switch difficulty {
        case .easy:   return (one: 60, two: 78, three: 96)
        case .normal: return (one: 50, two: 65, three: 80)
        case .hard:   return (one: 30, two: 39, three: 48)
        }
    }

    /// 셀당 최대 별 수 (★★★).
    static let maxStarsPerCell: Int = 3

    /// 판 점수 → 별 0...3. 점수에 단조이므로 셀 최고점 → 셀 최고 별로도 그대로 쓰인다 (Scoreboard).
    static func stars(score: Int, difficulty: Difficulty) -> Int {
        let thresholds = starThresholds(for: difficulty)
        if score >= thresholds.three { return 3 }
        if score >= thresholds.two { return 2 }
        if score >= thresholds.one { return 1 }
        return 0
    }

    // MARK: - 레벨 테이블 (02 §7-2 표 그대로 — Lv5→6 증분 +780 비균질도 설계서 수치 그대로)

    /// (누적 XP 하한, 칭호) — index 0 = Lv1. XP 정의 = GameStats.totalScore (판 종료 점수 합산).
    static let levelTable: [(xp: Int, title: String)] = [
        (xp: 0,     title: "간호 실습생"),
        (xp: 100,   title: "신입 간호사"),
        (xp: 280,   title: "주임 간호사"),
        (xp: 520,   title: "책임 간호사"),
        (xp: 820,   title: "선임 간호사"),
        (xp: 1_600, title: "수석 간호사"),
        (xp: 2_080, title: "교육 간호사"),
        (xp: 2_620, title: "감독 간호사"),
        (xp: 3_220, title: "간호 과장"),
        (xp: 3_880, title: "음악박사")
    ]

    /// 누적 XP → 레벨 1...10 (만렙 클램프). 음수 XP는 Lv1.
    static func level(forXP xp: Int) -> Int {
        var resolved = 1
        for (index, entry) in levelTable.enumerated() where xp >= entry.xp {
            resolved = index + 1
        }
        return resolved
    }

    /// 레벨 → 칭호. 범위 밖은 양끝 클램프 (강제 언래핑 회피).
    static func title(forLevel level: Int) -> String {
        let clampedIndex = min(max(level - 1, 0), levelTable.count - 1)
        return levelTable[clampedIndex].title
    }

    /// 현재 레벨 구간 내 진행률 0...1 — XP 바용. Lv10(만렙)은 1.0 고정.
    static func levelProgress(forXP xp: Int) -> CGFloat {
        let currentLevel = level(forXP: xp)
        guard currentLevel < levelTable.count else { return 1.0 }
        let floorXP = levelTable[currentLevel - 1].xp
        let ceilXP = levelTable[currentLevel].xp
        guard ceilXP > floorXP else { return 1.0 }
        let ratio = CGFloat(xp - floorXP) / CGFloat(ceilXP - floorXP)
        return min(max(ratio, 0), 1)
    }

    // MARK: - DEBUG 정합 검증 (SPEC 기능 1 — ★1 == targetScore 자동 검증)

    #if DEBUG
    /// ★1 임계 == `GameplayTuning.targetScoreByDifficulty` 정합 검증 (불변 조건 3).
    /// 현재 라이브 목표(70/50/40)가 02 §7-1(60/50/30)과 불일치 — assert로 두면 DEBUG 부팅마다
    /// 크래시해 검증 자체가 불가능하므로, 알려진 불일치는 경고 출력으로 노출한다 (허위 은폐 금지).
    /// 표 내부 단조성(★1<★2<★3, 레벨 XP 순증)은 진짜 불변이라 assert로 잠근다.
    static func debugAuditAlignment() {
        for difficulty in Difficulty.allCases {
            let thresholds = starThresholds(for: difficulty)
            assert(thresholds.one < thresholds.two && thresholds.two < thresholds.three,
                   "MetaProgression 별 임계 단조성 위반 — \(difficulty)")
            let liveTarget = GameplayTuning.targetScoreByDifficulty[difficulty]
                ?? GameplayTuning.targetScoreByDifficultyFallback
            if thresholds.one != liveTarget {
                print("[MetaProgression] ⚠️ ★1 임계(\(thresholds.one)) ≠ 라이브 목표(\(liveTarget))"
                      + " — \(difficulty.rawValue). 02 §7-1 vs GameplayTuning 불일치, R6 튜닝 결정 사항.")
            }
        }
        for index in 1..<levelTable.count {
            assert(levelTable[index].xp > levelTable[index - 1].xp,
                   "MetaProgression 레벨 XP 단조성 위반 — Lv\(index + 1)")
        }
    }
    #endif
}
