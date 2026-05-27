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
        cameraNode.addChild(overlay)
        overlay.showAndDismiss()

        let sergeant = SergeantParkNode.makeIntroCloseup()
        sergeant.zPosition = GameConfig.sergeantCloseupZPosition
        sergeant.alpha = 0
        sergeant.position = CGPoint(x: 0, y: GameConfig.sergeantCloseupOffsetY)
        cameraNode.addChild(sergeant)
        let sergeantFadeIn = SKAction.fadeIn(withDuration: GameConfig.sergeantCloseupFadeInDuration)
        let sergeantStay = SKAction.wait(forDuration: GameConfig.sergeantCloseupStayDuration)
        let sergeantFadeOut = SKAction.fadeOut(withDuration: GameConfig.sergeantCloseupFadeOutDuration)
        let sergeantCleanup = SKAction.removeFromParent()
        sergeant.run(.sequence([sergeantFadeIn, sergeantStay, sergeantFadeOut, sergeantCleanup]))

        enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in
            guard let self = self else { return }
            let target = self.spawnSystem.currentObstaclesTarget
            var currentF = 0
            self.worldNode.enumerateChildNodes(withName: "projectile") { _, _ in currentF += 1 }
            let deficit = max(0, target - currentF)
            for _ in 0..<deficit {
                self.spawnSystem.fireImmediately()
            }
        }

        let plane = AirplaneNode()
        let planeY = +(size.height / 2 - GameConfig.airplaneTopOffset)
        let waitPlane = SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)
        let attachPlane = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.cameraNode.addChild(plane)
            plane.crossScreen(sceneWidth: self.size.width, atY: planeY)
        }
        cameraNode.run(.sequence([waitPlane, attachPlane]))

        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)

        let waitPurge = SKAction.wait(forDuration: GameConfig.bombFlashDelay)
        let attachPurge = SKAction.run { [weak self] in
            self?.spawnSystem.purgeAllF()
        }
        cameraNode.run(.sequence([waitPurge, attachPurge]))
    }
}
