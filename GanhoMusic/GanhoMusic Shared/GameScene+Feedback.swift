//
//  GameScene+Feedback.swift
//  GanhoMusic Shared
//
//  수집/마일스톤/피격 피드백 — R2: 히트스톱 + 카메라 v2 셰이크 3단 + ChiptuneSynth + 햅틱 v2.
//  매핑(02_GAME_FEEL §2·§3): 게임오버=strong / 스킬=medium(SkillSystem) / 텔레그래프 발사=soft.
//  청진기 피격(동결)=medium + 0.10s 히트스톱 (SPEC §문서-코드 불일치 2).
//

import SpriteKit

// MARK: - Combo Feedback
extension GameScene {
    /// 음표 수집 — 콤보 1단계당 +반음(최대 +12) square 톤 + transient 0.45 햅틱 (02 §6).
    /// 일반 음표 수집에는 히트스톱 **없음** — 흐름 유지 (02 §2).
    func playNoteCollectFeedback(combo: Int) {
        haptics.noteCollect()
        synth.play(.noteCollect(semitoneOffset: comboSemitoneOffset(for: combo)))
        hud.pulseCombo(combo: combo)
    }

    /// 변기(+2) 수집 — E5→G5 2음 + transient 0.7 햅틱. 히트스톱/스쿼시는 Contact 콜백이 발화.
    func playToiletCollectFeedback(combo: Int) {
        haptics.toiletCollect()
        synth.play(.toiletCollect)
        hud.pulseCombo(combo: combo)
    }

    /// 콤보 n 수집의 반음 오프셋 — 콤보 1(시작) = C5, 이후 +1씩, 최대 +12.
    private func comboSemitoneOffset(for combo: Int) -> Int {
        return min(max(combo - 1, 0), FeelTuning.sfxCollectPitchMaxSemitone)
    }

    /// 콤보 마일스톤 — 5·7·10·20은 히트스톱 0.045s + 줌 펄스 + transient 0.9.
    /// 마일스톤 3은 기존 팝업/사운드만 유지 (SPEC §문서-코드 불일치 1 — switch default 금지 재구성).
    func playComboMilestoneFeedback(for milestone: Int) {
        synth.play(.comboMilestone)
        if FeelTuning.comboHitstopMilestones.contains(milestone) {
            requestHitstop(freeze: FeelTuning.hitstopComboMilestone)
            cameraDirector.zoomPulse(to: FeelTuning.cameraZoomPulseScale,
                                     duration: FeelTuning.cameraZoomPulseDuration)
            haptics.milestone()
        } else {
            haptics.light()   // 마일스톤 3 — 기존 light 등가 유지
        }
    }

    func triggerComboBreak(brokenAt brokenValue: Int) {
        if triggeredComboBreaks.contains(brokenValue) { return }
        triggeredComboBreaks.insert(brokenValue)
        haptics.heavy()
        synth.play(.comboBreak)   // R2 — saw 하강 G4→C4 (BREAK 노드는 기존 유지 — 신규 파티클 없음)
        let breakNode = ComboBreakNode(brokenCombo: brokenValue)
        cameraNode.addChild(breakNode)
        breakNode.animate()
    }

    func checkAndTriggerComboBreak() {
        let combo = scoreSystem.combo
        if combo >= FeelTuning.comboBreakThreshold {
            triggerComboBreak(brokenAt: combo)
        }
    }
}

// MARK: - Hitstop Request (R2)
extension GameScene {
    /// 히트스톱 단일 요청 진입점 — 일시정지 중 신규 요청 무시 (speed/isPaused 소유권 충돌 차단).
    /// 일시정지 진입 시 즉시 cancel은 presentPauseMenu가 담당 (원복 책임 단일화).
    func requestHitstop(freeze: TimeInterval, ramp: TimeInterval = 0) {
        guard gameState != .paused else { return }
        hitstop.request(freeze: freeze, ramp: ramp)
    }
}

// MARK: - Hit Feedback (R2 — 게임오버/동결 연출)
extension GameScene {
    /// 수간호사 접촉(게임오버) — strong 셰이크 + enemy→player 방향 킥 + deathBurst +
    /// 히트스톱 0.10s→0.25s 램프. 게임오버 햅틱/SFX는 endGame이 담당(이중 발화 방지).
    func playBodyHitFeedback() {
        cameraDirector.shake(.strong)
        cameraDirector.kick(direction: vector(from: enemy.position, to: player.position))
        effectDirector.deathBurst(at: player.position)
        requestHitstop(freeze: FeelTuning.hitstopFatalFreeze, ramp: FeelTuning.hitstopFatalRamp)
        ToastLabelNode.spawn(text: GameplayTuning.bodyHitToastText,
                             at: player.position,
                             parent: worldNode)
    }

    /// F 피격(게임오버) — 플래시 + strong 셰이크 + 투사체 진행 방향 킥(0벡터면 enemy→player 폴백) +
    /// deathBurst + 히트스톱 0.10s→0.25s 램프 (02 §2·§3 명세 그대로).
    func playFatalProjectileHitFeedback(projectileVelocity: CGVector) {
        cameraDirector.shake(.strong)
        cameraDirector.kick(direction: kickDirection(projectileVelocity: projectileVelocity))
        let flash = HitFlashNode()
        cameraNode.addChild(flash)
        flash.flash(sceneSize: size)
        effectDirector.deathBurst(at: player.position)
        requestHitstop(freeze: FeelTuning.hitstopFatalFreeze, ramp: FeelTuning.hitstopFatalRamp)
        ToastLabelNode.spawn(text: GameplayTuning.projectileHitToastText,
                             at: player.position,
                             parent: worldNode)
    }

    /// 청진기 피격(2초 동결 — 게임오버 아님) — medium 셰이크 + 방향성 킥 + 히트스톱 0.10s(램프 없음)
    /// + 피격 voice 재사용 (SPEC §문서-코드 불일치 2 — deathBurst/플래시는 F 전용).
    func playStethoscopeHitFeedback(stethoscopeVelocity: CGVector) {
        haptics.medium()
        synth.play(.hit)
        cameraDirector.shake(.medium)
        cameraDirector.kick(direction: kickDirection(projectileVelocity: stethoscopeVelocity))
        requestHitstop(freeze: FeelTuning.hitstopFatalFreeze)
    }

    /// 텔레그래프 발사(F burst·청진기 투척 시점) — soft 셰이크 + 근거리(≤180pt)면 "심장 박동" 햅틱.
    func playTelegraphFireFeedback(from origin: CGPoint) {
        cameraDirector.shake(.soft)
        let distance = hypot(origin.x - player.position.x, origin.y - player.position.y)
        if distance <= FeelTuning.telegraphHapticDistance {
            haptics.telegraphWarning()
        }
    }

    /// 피격 킥 방향 — 투사체 진행 방향(velocity 정규화는 CameraDirector.kick이 수행),
    /// 0벡터면 enemy→player 방향 폴백 (02 §3).
    private func kickDirection(projectileVelocity: CGVector) -> CGVector {
        if hypot(projectileVelocity.dx, projectileVelocity.dy) > 0 {
            return projectileVelocity
        }
        return vector(from: enemy.position, to: player.position)
    }

    private func vector(from origin: CGPoint, to destination: CGPoint) -> CGVector {
        return CGVector(dx: destination.x - origin.x, dy: destination.y - origin.y)
    }
}
