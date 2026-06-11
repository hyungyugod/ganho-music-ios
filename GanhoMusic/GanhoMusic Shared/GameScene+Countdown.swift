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
    }
}
