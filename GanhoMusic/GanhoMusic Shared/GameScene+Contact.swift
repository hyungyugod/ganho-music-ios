//
//  GameScene+Contact.swift
//  GanhoMusic Shared
//
//  ContactRouter callback registration for GameScene.
//

import SpriteKit

// MARK: - Contact Router
extension GameScene {
    func configureContactRouter() {
        contactRouter.onEnemyHit = { [weak self] in
            guard let self = self else { return }
            if self.player.isInvulnerable { return }
            self.playBodyHitFeedback()
            self.endGame()
        }

        contactRouter.onProjectileHitPlayer = { [weak self] node in
            guard let self = self else { return }
            if let projectile = node as? FProjectileNode, projectile.isEnchanted {
                self.scoreSystem.recordCharmedNoteHit()
                self.haptics.light()
                self.audio.play(.noteCollected)
                self.deferRemoveAfterContact(projectile)
                return
            }
            if self.player.isInvulnerable { return }
            self.playFatalProjectileHitFeedback()
            self.checkAndTriggerComboBreak()
            self.endGame()
        }

        contactRouter.onProjectileHitWall = { [weak self] node in
            self?.deferRemoveAfterContact(node)
        }

        contactRouter.onNoteCollected = { [weak self] note in
            guard let self = self else { return }
            let gainedPoints = self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
            let currentCombo = self.scoreSystem.combo
            self.playNoteCollectFeedback(gainedPoints: gainedPoints, combo: currentCombo)

            let sparkleOrigin = note.position
            let sparkle = SparkleEffectNode(context: .ingame)
            sparkle.position = sparkleOrigin
            self.worldNode.addChild(sparkle)
            sparkle.emit()

            ScorePopupNode.spawn(at: sparkleOrigin, gainedPoints: gainedPoints, parent: self.worldNode)

            if GameConfig.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                popup.position = CGPoint(x: 0, y: GameConfig.comboPopupStartOffsetY)
                self.cameraNode.addChild(popup)
                popup.animate()
            }
            self.deferRemoveAfterContact(note)
        }

        contactRouter.onStoneGuardContact = { [weak self] in
            self?.triggerAirforceEasterEgg()
        }

        contactRouter.onStethoscopeHitPlayer = { [weak self] node in
            guard let self = self else { return }
            if self.player.isInvulnerable {
                self.deferRemoveAfterContact(node)
                return
            }
            self.playStethoscopeHitFeedback()
            ToastLabelNode.spawn(text: GameConfig.stethoscopeToastText,
                                 at: self.player.position,
                                 parent: self.worldNode)
            let toastWait = SKAction.wait(forDuration: GameConfig.stethoscopeToastDuration)
            let freezeKick = SKAction.run { [weak self] in
                self?.player.freeze(duration: GameConfig.playerFreezeDuration)
            }
            self.run(.sequence([toastWait, freezeKick]))
            self.deferRemoveAfterContact(node)
        }

        contactRouter.onStethoscopeHitWall = { [weak self] node in
            self?.deferRemoveAfterContact(node)
        }

        contactRouter.onAItemCollected = { [weak self] node in
            guard let self = self else { return }
            self.scoreSystem.recordCharmedNoteHit()
            self.haptics.light()
            self.audio.play(.noteCollected)
            self.deferRemoveAfterContact(node)
        }

        contactRouter.onAItemHitWall = { [weak self] node in
            self?.deferRemoveAfterContact(node)
        }

        contactRouter.onToiletCollected = { [weak self] toilet in
            guard let self = self else { return }
            let toiletOrigin = toilet.position
            let gains = self.scoreSystem.recordToiletBonus(at: self.lastUpdateTime)
            let currentCombo = self.scoreSystem.combo
            self.playNoteCollectFeedback(gainedPoints: gains.max() ?? GameConfig.scorePerNote, combo: currentCombo)

            let sparkle = SparkleEffectNode(context: .ingame)
            sparkle.position = toiletOrigin
            self.worldNode.addChild(sparkle)
            sparkle.emit()

            ToastLabelNode.spawn(text: GameConfig.toiletToastText,
                                 at: toiletOrigin,
                                 parent: self.worldNode)

            if let firstGain = gains.first, let secondGain = gains.dropFirst().first {
                ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x - GameConfig.toiletScorePopupFanOutX,
                                                 y: toiletOrigin.y),
                                     gainedPoints: firstGain,
                                     parent: self.worldNode)
                ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x + GameConfig.toiletScorePopupFanOutX,
                                                 y: toiletOrigin.y),
                                     gainedPoints: secondGain,
                                     parent: self.worldNode)
            }

            if GameConfig.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                popup.position = CGPoint(x: 0, y: GameConfig.comboPopupStartOffsetY)
                self.cameraNode.addChild(popup)
                popup.animate()
            }
            self.deferRemoveAfterContact(toilet)
        }
    }

    // MARK: - Contact Cleanup
    /// 물리 contact 콜백 중 노드 제거를 다음 액션 틱으로 미뤄 SpriteKit 물리 처리와 분리.
    private func deferRemoveAfterContact(_ node: SKNode) {
        node.run(.sequence([
            .wait(forDuration: 0),
            .removeFromParent()
        ]))
    }
}
