//
//  ScoreSystem.swift
//  GanhoMusic Shared
//
//  Phase 2-12 · 점수 / 콤보 상태 + 갱신 로직 분리
//

import Foundation

/// 점수와 콤보 상태를 관리하는 시스템.
/// 외부(GameScene)는 read-only로 score/combo 조회 + 메서드로 상태 변경.
final class ScoreSystem {

    // MARK: - State (read-only 외부 노출)
    /// 현재 점수 (음표 수집 누적).
    private(set) var score: Int = 0
    /// 현재 콤보 (연속 수집 카운트).
    private(set) var combo: Int = 0
    /// R5 — 이번 판 수집 수 (ResultScene ♪ 칩 표시 전용 — 점수·콤보 로직 분기 0).
    /// recordNoteHit 1회당 +1 — 변기 보너스는 recordNoteHit 2회 경유로 자연 +2.
    /// `recordCharmedNoteHit`(매혹 F 변환)은 카운트 제외 — 콤보 시스템(recordNoteHit)을 경유한
    /// "음표 수집"만 센다. 매혹 변환은 콤보 0 점수 전용 경로라 음표 수집으로 보지 않는다.
    private(set) var notesCollected: Int = 0
    /// R6 §F9 — 콤보 윈도우 만료로 콤보가 0으로 끊긴 횟수 (표시·메타 전용, 점수·콤보 로직 분기 0).
    /// tickComboExpiry의 0화 시점에서만 +1 — F 피격 경로는 즉시 게임 종료라 본 카운터 비대상.
    private(set) var comboBreaks: Int = 0
    /// R6 §F9 — 이번 판 변기 보너스 수집 수 (toilet_maniac 업적 판정 전용).
    private(set) var toiletsCollected: Int = 0
    /// R6 §F7 황금 변기 — 변기 점수 가산 배율 (기본 1 = 기존 동작 byte-동일).
    /// 설정값이라 reset() 비대상 — GameScene이 모디파이어 배선 시 1회 set.
    var toiletScoreScale: Int = 1
    /// 마지막 수집 시각. 콤보 윈도우 만료 검사에 사용. 0 = "아직 수집 0건".
    private var lastCollectAt: TimeInterval = 0

    // MARK: - Mutations
    /// 음표 1개 수집을 기록. 콤보 윈도우 검사 + 콤보 갱신 + 점수 가산.
    /// Sprint 10 Phase E — 원본 game.js L811~L817 / L1048~L1052 3단 분기 1:1 이식.
    ///   combo >= 7 → +4, >= 5 → +3, >= 3 → +2, else → +1.
    /// 변기 ×2 보너스(recordToiletBonus)는 본 함수 2회 호출 → 새 분기 자연 적용.
    /// - Parameter now: 현재 게임 시각 (보통 lastUpdateTime).
    @discardableResult
    func recordNoteHit(at now: TimeInterval) -> Int {
        let isInWindow = combo > 0 && now - lastCollectAt < GameplayTuning.comboWindow
        combo = isInWindow ? combo + 1 : 1
        let gain: Int
        if combo >= GameplayTuning.comboBonusThresholdHigh {
            gain = GameplayTuning.scorePerNoteComboHigh   // 4 (combo >= 7)
        } else if combo >= GameplayTuning.comboBonusThresholdMid {
            gain = GameplayTuning.scorePerNoteComboMid    // 3 (combo >= 5)
        } else if combo >= GameplayTuning.comboBonusThreshold {
            gain = GameplayTuning.scorePerNoteCombo       // 2 (combo >= 3)
        } else {
            gain = GameplayTuning.scorePerNote            // 1 (combo < 3)
        }
        score += gain
        notesCollected += 1   // R5 — 표시 전용 카운트 (점수·콤보 로직 무변경)
        lastCollectAt = now
        return gain
    }

    /// 콤보 윈도우 만료 검사. update 안에서 매 프레임 호출.
    /// - Parameter currentTime: 현재 SpriteKit 시각.
    func tickComboExpiry(currentTime: TimeInterval) {
        if combo > 0, currentTime - lastCollectAt > GameplayTuning.comboWindow {
            combo = 0
            comboBreaks += 1   // R6 — 끊김 카운트 (full_combo_graduation 판정 전용, 로직 분기 0)
        }
    }

    /// Phase 9-5 — 임간호 매혹 발동 중 enchanted F를 수집했을 때 호출.
    /// 일반 note hit과 달리 *콤보 누적 없이* 보너스 점수만 가산 — 매혹의 정체성(*공격을 점수로*).
    /// charmStudentBonusScore(4) = scorePerNoteCombo(2)의 2배. 1회 한정 스킬에 합당한 보상.
    /// 시그니처는 기존 recordNoteHit과 분리 — 호출부에서 두 경로가 명확히 갈림(DRY 위배 의도적).
    func recordCharmedNoteHit() {
        score += GameplayTuning.charmStudentBonusScore
    }

    /// Phase 9-6 — 변기 보너스 수집 시 호출. 음표 2개 효과(GDD §7-3).
    /// `recordNoteHit`을 *2회* 호출 → 콤보 윈도우 검사/콤보 누적/마일스톤 분기 자연 발화.
    /// 직접 score/combo set 금지 — 단일 진실 원천(recordNoteHit) 경유로 회귀 방지.
    /// - Parameter now: 현재 게임 시각 (보통 lastUpdateTime).
    ///
    /// 두 번째 호출도 같은 `now`를 사용 → 콤보 윈도우 안에서 확실히 연속 카운트 +1 보장
    /// (isInWindow=true 분기 → combo+1, 첫 호출이 combo=N→N+1, 두 번째가 N+1→N+2 = 콤보+2).
    @discardableResult
    func recordToiletBonus(at now: TimeInterval) -> [Int] {
        let firstGain = recordNoteHit(at: now)
        let secondGain = recordNoteHit(at: now)
        toiletsCollected += 1   // R6 — 변기 수집 카운트 (표시·메타 전용)
        // R6 §F7 황금 변기 배율 훅 (SPEC 승인 — 본 함수의 "직접 score set 금지" 원칙의 명시 예외):
        // 콤보 증가는 recordNoteHit 2회 그대로(기존 +2 유지), *점수 가산분만* (scale-1)배 추가.
        // 기본 scale=1이면 아래 분기 미진입 — 기존 동작 byte-동일.
        if toiletScoreScale > 1 {
            let extra = (firstGain + secondGain) * (toiletScoreScale - 1)
            score += extra
            return [firstGain * toiletScoreScale, secondGain * toiletScoreScale]
        }
        return [firstGain, secondGain]
    }

    /// 모든 상태 리셋. 게임 재시작 등에서 사용 (Phase 3 이후).
    /// toiletScoreScale은 설정값이라 비대상 (모디파이어 배선이 씬 수명과 동행).
    func reset() {
        score = 0
        combo = 0
        notesCollected = 0
        comboBreaks = 0
        toiletsCollected = 0
        lastCollectAt = 0
    }
}
