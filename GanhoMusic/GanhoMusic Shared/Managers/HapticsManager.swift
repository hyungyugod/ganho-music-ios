//
//  HapticsManager.swift
//  GanhoMusic Shared
//
//  Phase 6-1 · 시스템 햅틱 피드백 캡슐화 (Manager 패턴 첫 등장)
//  Phase 6-11 · medium() 추가
//  R2 · CoreHaptics v2 (02_GAME_FEEL §6) — 이벤트 기반 패턴 6종 + 미지원/오류 시
//       기존 UIImpactFeedbackGenerator 폴백. 80ms 간격은 패턴 내 relativeTime으로 구현
//       (Timer/asyncAfter 금지). light/medium/heavy는 미매핑 이벤트용으로 유지.
//

import CoreHaptics
import UIKit

/// 햅틱 발생기 캡슐화 매니저. CoreHaptics 우선, 미지원 기기·엔진 오류 시 UIImpact 폴백.
/// Spring 비유: side-effect 책임을 가진 @Service 빈. Repository(영속 책임)와 대비.
final class HapticsManager {

    // MARK: - Fallback Generators (기존 3종 유지 — 미매핑 이벤트 + CoreHaptics 폴백)
    private let lightGenerator: UIImpactFeedbackGenerator
    private let mediumGenerator: UIImpactFeedbackGenerator
    private let heavyGenerator: UIImpactFeedbackGenerator

    // MARK: - CoreHaptics (R2)
    private var coreEngine: CHHapticEngine?

    // MARK: - Init
    init() {
        lightGenerator  = UIImpactFeedbackGenerator(style: .light)
        mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyGenerator  = UIImpactFeedbackGenerator(style: .heavy)
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()

        // R2 — CoreHaptics 엔진. supportsHaptics false(구형 기기/시뮬레이터)면 nil 유지 → 폴백 경로.
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        coreEngine = try? CHHapticEngine()
        // 리셋/중단 핸들러 — 시스템이 엔진을 회수했을 때 재시동. [weak self] 필수.
        coreEngine?.resetHandler = { [weak self] in
            try? self?.coreEngine?.start()
        }
        coreEngine?.stoppedHandler = { _ in }
        try? coreEngine?.start()
    }

    // MARK: - R2 이벤트 API (02 §6 표)
    /// 음표 수집 — transient 0.45 / sharpness 0.7.
    func noteCollect() {
        playTransients([(FeelTuning.hapticNoteIntensity, FeelTuning.hapticNoteSharpness, 0)],
                       fallback: light)
    }

    /// 변기 수집 — transient 0.7.
    func toiletCollect() {
        playTransients([(FeelTuning.hapticToiletIntensity, FeelTuning.hapticDefaultSharpness, 0)],
                       fallback: medium)
    }

    /// 콤보 마일스톤 — transient 0.9.
    func milestone() {
        playTransients([(FeelTuning.hapticMilestoneIntensity, FeelTuning.hapticDefaultSharpness, 0)],
                       fallback: heavy)
    }

    /// 텔레그래프 경고 — transient 0.3 ×2 (80ms 간격) "심장 박동".
    func telegraphWarning() {
        playTransients([
            (FeelTuning.hapticTelegraphIntensity, FeelTuning.hapticDefaultSharpness, 0),
            (FeelTuning.hapticTelegraphIntensity, FeelTuning.hapticDefaultSharpness,
             FeelTuning.hapticTelegraphGap)
        ], fallback: light)
    }

    /// 게임오버 — transient 1.0 + continuous 0.5 (0.3s).
    func gameOver() {
        let events = [
            transientEvent(intensity: FeelTuning.hapticGameOverTransientIntensity,
                           sharpness: FeelTuning.hapticDefaultSharpness, relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous,
                          parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity,
                                                   value: FeelTuning.hapticGameOverContinuousIntensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness,
                                                   value: FeelTuning.hapticDefaultSharpness)
                          ],
                          relativeTime: 0,
                          duration: FeelTuning.hapticGameOverContinuousDuration)
        ]
        playPattern(events: events, fallback: heavy)
    }

    /// 스킬 발동 — transient 0.8 / sharpness 1.0.
    func skillActivate() {
        playTransients([(FeelTuning.hapticSkillIntensity, FeelTuning.hapticSkillSharpness, 0)],
                       fallback: heavy)
    }

    /// UI 탭 — transient 0.35.
    func uiTap() {
        playTransients([(FeelTuning.hapticUITapIntensity, FeelTuning.hapticDefaultSharpness, 0)],
                       fallback: light)
    }

    /// 별 팝 (결과창 — R5 배선용 제공) — transient 0.6.
    func starPop() {
        playTransients([(FeelTuning.hapticStarPopIntensity, FeelTuning.hapticDefaultSharpness, 0)],
                       fallback: medium)
    }

    /// R7 §F2 — near-miss 회피 보상 — transient 0.3 ×1 (telegraphWarning 강도의 단발판).
    func nearMiss() {
        playTransients([(FeelTuning.R7.hapticNearMissIntensity, FeelTuning.hapticDefaultSharpness, 0)],
                       fallback: light)
    }

    // MARK: - Legacy Triggers (미매핑 이벤트 — 카운트다운 틱·tension 초당 틱 등 기존 강도 등가 유지)
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Private (CoreHaptics 재생 + 폴백)
    private func transientEvent(intensity: Float, sharpness: Float,
                                relativeTime: TimeInterval) -> CHHapticEvent {
        return CHHapticEvent(eventType: .hapticTransient,
                             parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                             ],
                             relativeTime: relativeTime)
    }

    private func playTransients(_ specs: [(intensity: Float, sharpness: Float, time: TimeInterval)],
                                fallback: () -> Void) {
        let events = specs.map {
            transientEvent(intensity: $0.intensity, sharpness: $0.sharpness, relativeTime: $0.time)
        }
        playPattern(events: events, fallback: fallback)
    }

    /// 패턴 재생 — 엔진 부재/오류 시 폴백 1회. 어떤 단계도 크래시 없이 graceful.
    private func playPattern(events: [CHHapticEvent], fallback: () -> Void) {
        guard let engine = coreEngine else {
            fallback()
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }
}
