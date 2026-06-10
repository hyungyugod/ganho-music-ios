//
//  GameScene+EasterEgg.swift
//  GanhoMusic Shared
//
//  AIRFORCE easter egg sequence for GameScene.
//

import SpriteKit

// MARK: - Easter Egg
extension GameScene {
    func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        if difficulty == .hard { return }
        airforceTriggered = true

        let overlay = AirforceOverlayNode()
        overlay.position = .zero
        cameraNode.addChild(overlay)
        overlay.showAndDismiss()
        startAirforceRescueSequence()
    }

    private func startAirforceRescueSequence() {
        let sergeant = SergeantParkNode.makeIntroCloseup()
        sergeant.zPosition = ZOrder.sergeantCloseupZPosition
        sergeant.alpha = 0
        sergeant.position = CGPoint(x: 0, y: FeelTuning.sergeantCloseupOffsetY)
        cameraNode.addChild(sergeant)
        let sergeantFadeIn = SKAction.fadeIn(withDuration: FeelTuning.sergeantCloseupFadeInDuration)
        let sergeantStay = SKAction.wait(forDuration: FeelTuning.sergeantCloseupStayDuration)
        let sergeantFadeOut = SKAction.fadeOut(withDuration: FeelTuning.sergeantCloseupFadeOutDuration)
        let sergeantCleanup = SKAction.removeFromParent()
        sergeant.run(.sequence([sergeantFadeIn, sergeantStay, sergeantFadeOut, sergeantCleanup]))

        enemy.startFleeing(duration: GameplayTuning.enemyFleeDuration) { [weak self] in
            guard let self = self else { return }
            let target = self.spawnSystem.currentObstaclesTarget
            // R1 — 구 enumerateChildNodes("projectile") 카운트 → registry 캐시 조회 (대상 동일).
            let currentF = self.registry.projectiles.count
            let deficit = max(0, target - currentF)
            for _ in 0..<deficit {
                self.spawnSystem.fireImmediately()
            }
        }

        let plane = AirplaneNode()
        let planeY = +(size.height / 2 - FeelTuning.airplaneTopOffset)
        let waitPlane = SKAction.wait(forDuration: FeelTuning.airplaneDelayAfterOverlay)
        let attachPlane = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.cameraNode.addChild(plane)
            plane.crossScreen(sceneWidth: self.size.width, atY: planeY)
        }
        cameraNode.run(.sequence([waitPlane, attachPlane]))

        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)

        let waitPurge = SKAction.wait(forDuration: FeelTuning.bombFlashDelay)
        let attachPurge = SKAction.run { [weak self] in
            self?.spawnSystem.purgeAllF()
            // R2 — 폭탄 섬광 시점(bombFlashDelay 도달 = fadeIn 시작) 히트스톱 0.12s (02 §2).
            // 일시정지 중이면 requestHitstop 가드가 무시 (cameraNode 액션은 일시정지에도 진행됨).
            self?.requestHitstop(freeze: FeelTuning.hitstopBombFlash)
        }
        cameraNode.run(.sequence([waitPurge, attachPurge]))
    }
}
