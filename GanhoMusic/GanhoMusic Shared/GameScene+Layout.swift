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
        layoutCameraZoom()
        layoutDPad()
        layoutHUD()
        layoutSkillButton()
        layoutRunButton()
        layoutHUDSkillSlot()
        layoutPauseButton()
        updateCameraFollow()
    }

    func layoutCameraZoom() {
        let profile = DeviceLayoutProfile.resolve(for: self)
        cameraNode.setScale(profile.cameraScale(for: size))
    }

    func controlMargin(base: CGFloat, radius: CGFloat, scale: CGFloat) -> CGFloat {
        return base + max(0, radius * (scale - GameConfig.regularLayoutScale))
    }

    func layoutDPad() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameControlScale
        dpad.setScale(scale)
        let marginX = controlMargin(
            base: GameConfig.dpadMarginX,
            radius: GameConfig.dpadTouchRadius,
            scale: scale
        )
        let marginY = controlMargin(
            base: GameConfig.dpadMarginY,
            radius: GameConfig.dpadTouchRadius,
            scale: scale
        )
        dpad.position = CGPoint(
            x: +(halfW - safe.right - marginX),
            y: -(halfH - safe.bottom - marginY)
        )
    }

    func layoutHUD() {
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameHUDScale
        hud.setScale(scale)
        let marginY = controlMargin(
            base: GameConfig.hudTopMargin,
            radius: GameConfig.hudSlotHeight / 2,
            scale: scale
        )
        hud.position = CGPoint(
            x: 0,
            y: +(halfH - safe.top - marginY)
        )
    }
}
