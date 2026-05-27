//
//  GameScene+Feedback.swift
//  GanhoMusic Shared
//
//  Combo milestone and break feedback helpers for GameScene.
//

import SpriteKit

// MARK: - Combo Feedback
extension GameScene {
    func playNoteCollectFeedback(gainedPoints: Int, combo: Int) {
        if gainedPoints >= GameConfig.scorePerNoteComboHigh {
            haptics.medium()
            audio.play(.comboMilestoneSoft)
        } else {
            haptics.light()
            audio.play(.noteCollected)
        }
        hud.pulseCombo(combo: combo)
    }

    func playComboMilestoneFeedback(for milestone: Int) {
        switch milestone {
        case 3, 5:
            haptics.light()
            audio.play(.comboMilestoneSoft)
        case 7, 10:
            haptics.medium()
            audio.play(.comboMilestoneSoft)
        case 20:
            haptics.heavy()
            audio.play(.comboMilestoneStrong)
        default:
            haptics.light()
            audio.play(.comboMilestoneSoft)
        }
    }

    func triggerComboBreak(brokenAt brokenValue: Int) {
        if triggeredComboBreaks.contains(brokenValue) { return }
        triggeredComboBreaks.insert(brokenValue)
        haptics.heavy()
        let breakNode = ComboBreakNode(brokenCombo: brokenValue)
        cameraNode.addChild(breakNode)
        breakNode.animate()
    }

    func checkAndTriggerComboBreak() {
        let combo = scoreSystem.combo
        if combo >= GameConfig.comboBreakThreshold {
            triggerComboBreak(brokenAt: combo)
        }
    }

    func playBodyHitFeedback() {
        haptics.heavy()
        cameraNode.run(CameraShakeAction.make())
        ToastLabelNode.spawn(text: GameConfig.bodyHitToastText,
                             at: player.position,
                             parent: worldNode)
    }

    func playFatalProjectileHitFeedback() {
        haptics.heavy()
        cameraNode.run(CameraShakeAction.make())
        let flash = HitFlashNode()
        cameraNode.addChild(flash)
        flash.flash(sceneSize: size)
        ToastLabelNode.spawn(text: GameConfig.projectileHitToastText,
                             at: player.position,
                             parent: worldNode)
    }

    func playStethoscopeHitFeedback() {
        haptics.medium()
        cameraNode.run(CameraShakeAction.make())
    }
}
