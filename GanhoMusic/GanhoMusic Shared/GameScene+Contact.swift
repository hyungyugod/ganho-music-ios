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

            // R1 — 점수 팝업 풀 경유 (obtain→addChild→animate→풀 회수).
            ScorePopupNode.spawn(at: sparkleOrigin,
                                 gainedPoints: gainedPoints,
                                 parent: self.worldNode,
                                 pool: self.scorePopupPool)

            if FeelTuning.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                popup.position = CGPoint(x: 0, y: FeelTuning.comboPopupStartOffsetY)
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
            ToastLabelNode.spawn(text: GameplayTuning.stethoscopeToastText,
                                 at: self.player.position,
                                 parent: self.worldNode)
            let toastWait = SKAction.wait(forDuration: GameplayTuning.stethoscopeToastDuration)
            let freezeKick = SKAction.run { [weak self] in
                self?.player.freeze(duration: GameplayTuning.playerFreezeDuration)
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
            self.playNoteCollectFeedback(gainedPoints: gains.max() ?? GameplayTuning.scorePerNote, combo: currentCombo)

            let sparkle = SparkleEffectNode(context: .ingame)
            sparkle.position = toiletOrigin
            self.worldNode.addChild(sparkle)
            sparkle.emit()

            ToastLabelNode.spawn(text: FeelTuning.toiletToastText,
                                 at: toiletOrigin,
                                 parent: self.worldNode)

            if let firstGain = gains.first, let secondGain = gains.dropFirst().first {
                // R1 — 점수 팝업 풀 경유 (변기 보너스는 동시 2장 — 예열 8장이 흡수).
                ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x - GameplayTuning.toiletScorePopupFanOutX,
                                                 y: toiletOrigin.y),
                                     gainedPoints: firstGain,
                                     parent: self.worldNode,
                                     pool: self.scorePopupPool)
                ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x + GameplayTuning.toiletScorePopupFanOutX,
                                                 y: toiletOrigin.y),
                                     gainedPoints: secondGain,
                                     parent: self.worldNode,
                                     pool: self.scorePopupPool)
            }

            if FeelTuning.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                popup.position = CGPoint(x: 0, y: FeelTuning.comboPopupStartOffsetY)
                self.cameraNode.addChild(popup)
                popup.animate()
            }
            self.deferRemoveAfterContact(toilet)
        }
    }

    // MARK: - Contact Cleanup
    /// 물리 contact 콜백 중 노드 제거/회수를 다음 액션 틱으로 미뤄 SpriteKit 물리 처리와 분리.
    /// R1 — 마지막 단계만 removeFromParent → recycleDynamicNode(풀 4종 회수 / 비풀 제거)로 교체.
    /// `.wait(forDuration: 0)` 지연은 그대로 유지 — 충돌 델리게이트 진행 중 즉시 제거 금지 규칙을
    /// 회수에도 동일 적용(물리 시뮬레이션 단계와 노드 제거 분리).
    private func deferRemoveAfterContact(_ node: SKNode) {
        let cleanup = SKAction.run { [weak self, weak node] in
            guard let node = node else { return }
            self?.recycleDynamicNode(node)
        }
        node.run(.sequence([
            .wait(forDuration: 0),
            cleanup
        ]))
    }
}
