//
//  MetaTuning.swift
//  GanhoMusic Shared
//
//  R6 메타 시스템 도메인 상수 (SPEC §F1~F9 — 매직 넘버 0 원칙).
//  별 배율·언락 별 임계·일일 모디파이어 수치·업적 임계·일일 보상 배율의 단일 진실 원천.
//  수치 출처: refactor/02_GAME_FEEL §7 (배율 1.2/1.5/1.3/2/0.5, 언락 3/8/15/24, 업적 임계).
//

import CoreGraphics
import Foundation

/// R6 메타 시스템 상수 네임스페이스. case 없는 enum — 인스턴스화 차단.
enum MetaTuning {

    // MARK: - 별 임계 파생 배율 (SPEC §F1 — 02 §7-1 표의 비율을 라이브 목표에서 파생)
    /// ★★2 임계 = 목표 × 1.3 (02 표: 60→78, 50→65, 30→39 전부 ×1.3).
    static let starTwoMultiplier: Double = 1.3
    /// ★★★3 임계 = 목표 × 1.6 (02 표: 60→96, 50→80, 30→48 전부 ×1.6).
    static let starThreeMultiplier: Double = 1.6
    /// 파생식 오버플로 가드 상한 — 목표가 이 값을 넘으면 파생을 포기하고 목표 그대로 사용
    /// (Difficulty.targetScore의 dict 조회 실패 Int.max 폴백 × 1.6 → Double→Int 트랩 방지).
    static let starThresholdDerivationMaxTarget: Int = 1_000_000

    // MARK: - 캐릭터 언락 별 임계 (02 §7-3 그대로 — kim 기본 / jung 3 / geon 8 / im 15 / lee 24)
    /// 신규 판정 = (기존 규칙: 이전 캐릭터 졸업 OR 25점) OR (총 별 ≥ 요구) — 라이브 OR (SPEC §F3).
    static let unlockStarRequirement: [CharacterID: Int] = [
        .kim: 0, .jung: 3, .geon: 8, .im: 15, .lee: 24
    ]
    /// dict 조회 실패 시 폴백 — 도달 불가지만 강제 언래핑 회피용 (충족 불가 큰 값).
    static let unlockStarRequirementFallback: Int = Int.max

    // MARK: - 일일 도전 (02 §7-4 — 배율은 전부 여기, raw 키는 DailyModifier)
    /// 최초 클리어 보상 — 셀 적립 별 = min(3, earned × 2).
    static let dailyStarMultiplier: Int = 2
    /// 스피드 나이트 — 적 이동 속도 배율 (+20%).
    static let speedNightEnemySpeedScale: CGFloat = 1.2
    /// 음표 러시 — 음표 스폰 간격 나누기 (스폰 1.5배).
    static let noteRushSpawnIntervalDivisor: Double = 1.5
    /// 음표 러시 — 목표 점수 배율 (+30%, ceil 정수화. ★ 임계도 thresholds(forTarget:)로 자동 동반).
    static let noteRushTargetMultiplier: Double = 1.3
    /// 황금 변기 — 변기 점수 가산 배율 (콤보 증가는 기존 +2 유지 — ScoreSystem 배율 훅).
    static let goldenToiletScoreScale: Int = 2
    /// 황금 변기 — 스폰 기대치 +1 구현: 확정 1회 추가 스폰 지연(초).
    /// 현행 기대 ≈0.45~0.56개/판이라 확률 미세조정 대신 *확정 +1* — 황금 변기 날에 변기 0개인
    /// 빈 체험을 막고 기대치는 정확히 +1 (SPEC §F7 "간격/확률 조정"의 결정적 구현).
    static let goldenToiletGuaranteedSpawnDelay: TimeInterval = 6.0
    /// 기합 충만 — 스킬 쿨다운 배율 (50%).
    static let fullSpiritCooldownScale: Double = 0.5
    /// 소등 — 시야 축소 비네트 가림막 알파 (중앙 창 밖 4면).
    static let lightsOutShroudAlpha: CGFloat = 0.62
    /// 소등 — 중앙 시야 창 크기 비율 (화면 최소 변 기준).
    static let lightsOutWindowRatio: CGFloat = 0.58
    /// 일일 도전 남은 시간 — 시(時) 단위 환산 분모.
    static let dailySecondsPerHour: TimeInterval = 3_600

    // MARK: - 업적 임계 (02 §7-5 — 16종 판정 수치)
    /// 콤보 10 / 콤보 20.
    static let achievementComboLow: Int = 10
    static let achievementComboHigh: Int = 20
    /// 변기 마니아 — 한 판 변기 수집 수. 현행 변기 기대치 ≈0.56개/판이라 사실상
    /// golden_toilet 날 전용의 의도된 희귀 업적 — 수치 조정은 R7 소관 (SPEC §주의사항 5).
    static let achievementToiletManiacCount: Int = 4
    /// 스킬 마스터 — jung/geon/im/lee 스킬 발동 누적 각각의 요구치.
    static let achievementSkillMasterPerCharacter: Int = 10
    /// 누적 음표 500 / 2,000.
    static let achievementNotesLow: Int = 500
    static let achievementNotesHigh: Int = 2_000
    /// 일일 도전 클리어 dayKey 수.
    static let achievementDailyClearGoal: Int = 7
    /// 3별 셀 수 — 5개 / 15개(올클리어 = 전 셀).
    static let achievementThreeStarCellsLow: Int = 5
    static let achievementThreeStarCellsHigh: Int =
        CharacterID.allCases.count * Difficulty.allCases.count
    /// 음악박사 — 만렙 레벨 (XP 임계는 MetaProgression.levelTable이 단일 진실 원천).
    static let achievementMaxLevel: Int = 10

    // MARK: - 마이그레이션
    /// meta.migrationVersion 현재 버전 — 멱등 가드 (최초 1).
    static let metaMigrationVersion: Int = 1
}
