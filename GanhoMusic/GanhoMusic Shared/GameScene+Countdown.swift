//
//  GameScene+Countdown.swift
//  GanhoMusic Shared
//
//  Countdown overlay and actual gameplay start handoff for GameScene.
//

import SpriteKit

// MARK: - Countdown
extension GameScene {
    func showCountdown() {
        let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
        dim.alpha = 0
        dim.zPosition = ZOrder.countdownDimZPosition
        dim.name = FeelTuning.countdownDimNodeName
        cameraNode.addChild(dim)
        dim.run(.fadeAlpha(to: FeelTuning.countdownDimAlpha,
                           duration: FeelTuning.countdownDimFadeInDuration))

        let node = CountdownNode()
        node.position = .zero
        node.zPosition = ZOrder.countdownNodeZPosition
        node.isHidden = false
        node.alpha = 1.0
        cameraNode.addChild(node)
        node.start(
            onTick: { [weak self] _ in
                guard let self = self else { return }
                self.haptics.light()                  // 미매핑 이벤트 — 기존 강도 등가 유지
                self.synth.play(.countdownTick)       // R2 — square A4 50ms (02 §6)
            },
            onGo: { [weak self] in
                guard let self = self else { return }
                self.haptics.heavy()
                self.synth.play(.countdownGo)         // R2 — square A5 200ms (02 §6)
            },
            onComplete: { [weak self] in
                guard let self = self else { return }
                let fadeOut = SKAction.fadeOut(withDuration: FeelTuning.countdownDimFadeOutDuration)
                let cleanup = SKAction.removeFromParent()
                let startGame = SKAction.run { [weak self] in
                    self?.startGameProperly()
                }
                dim.run(.sequence([fadeOut, cleanup, startGame]))
            }
        )
    }

    func startGameProperly() {
        // Countdown/cutscene 대기 시간을 실제 플레이 dt로 계산하지 않도록 첫 playing 프레임을 새로 시작한다.
        lastUpdateTime = 0
        spawnSystem.apply(difficulty)
        spawnSystem.start(
            scene: self,
            world: worldNode,
            player: player,
            enemy: enemy,
            progressProvider: { [weak self] in
                guard let self = self else { return 0 }
                return Double(1.0 - self.remainingTime / GameplayTuning.gameDuration)
            },
            comboProvider: { [weak self] in
                // R7 §F4 — 리스크 가속 판정용 콤보 공급 (progressProvider 동형 [weak self]).
                return self?.scoreSystem.combo ?? 0
            }
        )
        gameState = .playing
        if FeelTuning.isBGMEnabled {
            bgm.play()
        }
        presentControlsHintIfNeeded()   // R9 #3 — 첫 판 1회 조작 온보딩 (말미 발화)
    }

    /// R9 #3 — 첫 판 조작 온보딩. 플래그 false → 힌트 attach + *즉시* true 저장
    /// (멱등 — 같은 판 재진입·크래시 후에도 1회 원칙). 힌트는 ~3s 후 자동 소멸.
    /// bool(forKey:) 미존재 = false = "아직 안 봄" — shown 플래그 방향이라 기본값 함정 비저촉.
    func presentControlsHintIfNeeded() {
        let defaults = UserDefaults.standard
        var shouldShow = !defaults.bool(
            forKey: StorageKeys.onboardingControlsHintShownUserDefaultsKey
        )
        #if DEBUG
        // 스크린샷 게이트 재현 수단 — 플래그 무시 강제 표시 (GANHO_SKIP_CUTSCENE 전례 동형).
        if ProcessInfo.processInfo.environment["GANHO_FORCE_CONTROLS_HINT"] == "1" {
            shouldShow = true
        }
        #endif
        guard shouldShow else { return }
        defaults.set(true, forKey: StorageKeys.onboardingControlsHintShownUserDefaultsKey)
        let hint = ControlsHintNode(
            dpadPosition: dpad.position,
            skillButtonPosition: skillButton.position,
            controlScale: DeviceLayoutProfile.resolve(for: self).ingameControlScale
        )
        cameraNode.addChild(hint)
    }
}
