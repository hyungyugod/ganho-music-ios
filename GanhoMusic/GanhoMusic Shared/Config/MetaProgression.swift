//
//  MetaProgression.swift
//  GanhoMusic Shared
//
//  R5 — 메타 진행(별·레벨·칭호) 표시 전용 파생 함수. R6 메타 시스템의 기반.
//  R6 §F1 retune — 별 임계를 절대 수치 표에서 라이브 목표 점수 *파생식*으로 전환:
//  "★1 = 목표"(02 §7-1 표 헤더 불변 의도)가 절대 수치보다 우선 — verdict/★ 모순 0 (R5 P2-2 해소).
//  레벨 테이블(§7-2)은 byte-수치 그대로 무변경. XP 정의 = GameStats.totalScore 현행 유지.
//

import CoreGraphics
import Foundation

/// 메타 진행 파생 네임스페이스. case 없는 enum — 인스턴스화 차단.
enum MetaProgression {

    // MARK: - 별 임계 (R6 §F1 — 목표 파생식. 결과: easy 70/91/112 · normal 50/65/80 · hard 40/52/64)

    /// 목표 점수 → (★1, ★★2, ★★★3) 임계. ★1 = 목표 그대로 (모순 0의 핵심),
    /// ★2/★3 = 목표 × 1.3 / × 1.6 반올림 (02 §7-1 표의 비율 byte 보존: 60→78→96 등 전부 동일 비).
    /// normal은 02 표와 byte-동일(50/65/80). easy +16.7%·hard +33.3%는 라이브 목표(70/40)
    /// 파생의 귀결 — "R6 retune 게이트, 모순 0" 사용자 지시로 승인된 변경 (SPEC §F1).
    /// 향후 R7이 목표를 튜닝해도 자동 정합 — 파생식 자체가 계약 (±20% 재량 대상 아님).
    static func thresholds(forTarget target: Int) -> (one: Int, two: Int, three: Int) {
        // dict 조회 실패 폴백(Int.max) × 1.6 → Double→Int 변환 트랩 방지 가드.
        guard target > 0, target <= MetaTuning.starThresholdDerivationMaxTarget else {
            return (one: target, two: target, three: target)
        }
        let two = Int((Double(target) * MetaTuning.starTwoMultiplier).rounded())
        let three = Int((Double(target) * MetaTuning.starThreeMultiplier).rounded())
        return (one: target, two: two, three: three)
    }

    /// 난이도 래퍼 — 라이브 목표(`difficulty.targetScore`) 경유 파생 (§F1 결과 표가 R6의 진실).
    static func starThresholds(for difficulty: Difficulty) -> (one: Int, two: Int, three: Int) {
        return thresholds(forTarget: difficulty.targetScore)
    }

    /// 셀당 최대 별 수 (★★★).
    static let maxStarsPerCell: Int = 3

    /// 판 점수 → 별 0...3 (임의 목표 기준 — 음표 러시 effectiveTarget도 같은 식 자동 동반).
    static func stars(score: Int, target: Int) -> Int {
        let thresholds = thresholds(forTarget: target)
        if score >= thresholds.three { return 3 }
        if score >= thresholds.two { return 2 }
        if score >= thresholds.one { return 1 }
        return 0
    }

    /// 판 점수 → 별 0...3. 점수에 단조이므로 셀 최고점 → 셀 최고 별로도 그대로 쓰인다.
    static func stars(score: Int, difficulty: Difficulty) -> Int {
        return stars(score: score, target: difficulty.targetScore)
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

    // MARK: - DEBUG 정합 검증 (R6 §F1 — 경고 print 분기 제거, assert 승격)

    #if DEBUG
    /// ★1 임계 == `GameplayTuning.targetScoreByDifficulty` 정합 검증.
    /// R6 retune으로 ★1이 라이브 목표 *파생*이 되어 불일치가 구조적으로 소멸 —
    /// R5의 "알려진 불일치 경고 print" 분기를 제거하고 assert로 승격 (DEBUG 부팅 크래시 0 = 정합 증명).
    /// 표 내부 단조성(★1<★2<★3, 레벨 XP 순증)도 그대로 assert로 잠근다.
    static func debugAuditAlignment() {
        for difficulty in Difficulty.allCases {
            let thresholds = starThresholds(for: difficulty)
            assert(thresholds.one < thresholds.two && thresholds.two < thresholds.three,
                   "MetaProgression 별 임계 단조성 위반 — \(difficulty)")
            let liveTarget = GameplayTuning.targetScoreByDifficulty[difficulty]
                ?? GameplayTuning.targetScoreByDifficultyFallback
            assert(thresholds.one == liveTarget,
                   "MetaProgression ★1 임계(\(thresholds.one)) ≠ 라이브 목표(\(liveTarget)) — \(difficulty.rawValue)")
        }
        for index in 1..<levelTable.count {
            assert(levelTable[index].xp > levelTable[index - 1].xp,
                   "MetaProgression 레벨 XP 단조성 위반 — Lv\(index + 1)")
        }
    }
    #endif
}
