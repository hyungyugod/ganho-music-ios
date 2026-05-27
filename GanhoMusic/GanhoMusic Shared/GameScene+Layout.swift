//
//  GameScene+Layout.swift
//  GanhoMusic Shared
//
//  Screen-fixed camera UI layout for GameScene.
//

import SpriteKit

// MARK: - Layout
extension GameScene {
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutDPad()
        layoutHUD()
        layoutSkillButton()
        layoutHUDSkillSlot()
        layoutPauseButton()
    }

    func layoutDPad() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        dpad.position = CGPoint(
            x: +(halfW - safe.right - GameConfig.dpadMarginX),
            y: -(halfH - safe.bottom - GameConfig.dpadMarginY)
        )
    }

    func layoutHUD() {
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        hud.position = CGPoint(
            x: 0,
            y: +(halfH - safe.top - GameConfig.hudTopMargin)
        )
    }
}
