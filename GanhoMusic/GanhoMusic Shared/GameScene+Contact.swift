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
                self.synth.play(.noteCollect(semitoneOffset: 0))
                self.deferRemoveAfterContact(projectile)
                return
            }
            if self.player.isInvulnerable { return }
            // R2 — 투사체 진행 방향으로 방향성 킥 (0벡터면 enemy→player 폴백).
            let velocity = node.physicsBody?.velocity ?? .zero
            self.playFatalProjectileHitFeedback(projectileVelocity: velocity)
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
            self.playNoteCollectFeedback(combo: currentCombo)

            // R10 #8 — 음표 수집 미니 히트스톱 (0.015s ≈ 1프레임). longer-wins 합성은
            // HitstopController 기존 로직 그대로 (02 §2 동반 갱신 — 충돌 조항 해소).
            self.requestHitstop(freeze: FeelTuning.hitstopNoteCollect)

            // R2 — SparkleEffectNode(수집당 노드 9개) → EffectDirector.collectBurst (이미터 풀).
            let burstOrigin = note.position
            self.effectDirector.collectBurst(at: burstOrigin)

            // R1 — 점수 팝업 풀 경유 (obtain→addChild→animate→풀 회수).
            ScorePopupNode.spawn(at: burstOrigin,
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
            // R2 — 수집 팝(1.15배 후 소멸) + 이중 가산 차단(P0): 콜백 진입 즉시
            // contactTestBitMask 차단(beginCollectPop) + registry unregister(자석/순회 즉시 제외).
            // 회수는 팝 종료 후 SKAction 경유 — 델리게이트 내 즉시 removeFromParent 금지 유지.
            if let noteNode = note as? NoteNode {
                self.registry.unregister(noteNode)
                noteNode.beginCollectPop()
            } else {
                self.deferRemoveAfterContact(note)
            }
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
            // R2 — medium 셰이크 + 방향성 킥 + 히트스톱 0.10s (동결 — 게임오버 아님).
            let velocity = node.physicsBody?.velocity ?? .zero
            self.playStethoscopeHitFeedback(stethoscopeVelocity: velocity)
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
            self.synth.play(.noteCollect(semitoneOffset: 0))
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
            self.playToiletCollectFeedback(combo: currentCombo)

            // R2 — 변기 수집: SparkleEffectNode → toiletSplash + 히트스톱 0.03s + 플레이어 스쿼시 (02 §2).
            self.effectDirector.toiletSplash(at: toiletOrigin)
            self.requestHitstop(freeze: FeelTuning.hitstopToiletCollect)
            self.player.playImpactSquash()

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
