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
        dim.zPosition = GameConfig.countdownDimZPositionV9
        dim.name = GameConfig.countdownDimNodeName
        cameraNode.addChild(dim)
        dim.run(.fadeAlpha(to: GameConfig.countdownDimAlphaV9,
                           duration: GameConfig.countdownDimFadeInDuration))

        let node = CountdownNode()
        node.position = .zero
        node.zPosition = GameConfig.countdownNodeZPositionV9
        node.isHidden = false
        node.alpha = 1.0
        cameraNode.addChild(node)
        node.start(
            onTick: { [weak self] _ in
                self?.haptics.light()
            },
            onGo: { [weak self] in
                guard let self = self else { return }
                self.haptics.heavy()
                self.audio.play(.comboMilestoneStrong)
            },
            onComplete: { [weak self] in
                guard let self = self else { return }
                let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownDimFadeOutDuration)
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
                return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
            }
        )
        gameState = .playing
        bgm.play()
    }
}
