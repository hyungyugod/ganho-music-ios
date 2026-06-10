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
        // R2 — 줌/크기 변경 직후 즉시 클램프 스냅 (구 updateCameraFollow 절대 대입 시맨틱).
        cameraDirector.snapToClampedTarget()
    }

    func layoutCameraZoom() {
        let profile = DeviceLayoutProfile.resolve(for: self)
        cameraNode.setScale(profile.cameraScale(for: size))
    }

    func controlMargin(base: CGFloat, radius: CGFloat, scale: CGFloat) -> CGFloat {
        return base + max(0, radius * (scale - UILayout.regularLayoutScale))
    }

    func layoutDPad() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameControlScale
        dpad.setScale(scale)
        let marginX = controlMargin(
            base: GameplayTuning.dpadMarginX,
            radius: GameplayTuning.dpadTouchRadius,
            scale: scale
        )
        let marginY = controlMargin(
            base: GameplayTuning.dpadMarginY,
            radius: GameplayTuning.dpadTouchRadius,
            scale: scale
        )
        dpad.position = CGPoint(
            x: -(halfW - safe.left - marginX),
            y: -(halfH - safe.bottom - marginY)
        )
    }

    func layoutHUD() {
        let halfH = size.height / 2
        let safe = SceneSafeArea.insets(for: self)
        let scale = DeviceLayoutProfile.resolve(for: self).ingameHUDScale
        hud.setScale(scale)
        let marginY = controlMargin(
            base: UILayout.hudTopMargin,
            radius: UILayout.hudSlotHeight / 2,
            scale: scale
        )
        hud.position = CGPoint(
            x: 0,
            y: +(halfH - safe.top - marginY)
        )
    }
}
