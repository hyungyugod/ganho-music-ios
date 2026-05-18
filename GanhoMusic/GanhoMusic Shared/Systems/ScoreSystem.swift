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
    /// 마지막 수집 시각. 콤보 윈도우 만료 검사에 사용. 0 = "아직 수집 0건".
    private var lastCollectAt: TimeInterval = 0

    // MARK: - Mutations
    /// 음표 1개 수집을 기록. 콤보 윈도우 검사 + 콤보 갱신 + 점수 가산.
    /// - Parameter now: 현재 게임 시각 (보통 lastUpdateTime).
    func recordNoteHit(at now: TimeInterval) {
        let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
        combo = isInWindow ? combo + 1 : 1
        score += combo >= GameConfig.comboBonusThreshold
            ? GameConfig.scorePerNoteCombo
            : GameConfig.scorePerNote
        lastCollectAt = now
    }

    /// 콤보 윈도우 만료 검사. update 안에서 매 프레임 호출.
    /// - Parameter currentTime: 현재 SpriteKit 시각.
    func tickComboExpiry(currentTime: TimeInterval) {
        if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
            combo = 0
        }
    }

    /// Phase 9-5 — 임간호 매혹 발동 중 enchanted F를 수집했을 때 호출.
    /// 일반 note hit과 달리 *콤보 누적 없이* 보너스 점수만 가산 — 매혹의 정체성(*공격을 점수로*).
    /// charmStudentBonusScore(4) = scorePerNoteCombo(2)의 2배. 1회 한정 스킬에 합당한 보상.
    /// 시그니처는 기존 recordNoteHit과 분리 — 호출부에서 두 경로가 명확히 갈림(DRY 위배 의도적).
    func recordCharmedNoteHit() {
        score += GameConfig.charmStudentBonusScore
    }

    /// 모든 상태 리셋. 게임 재시작 등에서 사용 (Phase 3 이후).
    func reset() {
        score = 0
        combo = 0
        lastCollectAt = 0
    }
}
