//
//  GameScene+Camera.swift
//  GanhoMusic Shared
//
//  Camera follow and map-edge clamp logic for GameScene.
//

import SpriteKit

// MARK: - Camera Follow
extension GameScene {
    func updateCameraFollow() {
        let halfW = size.width / 2
        let halfH = size.height / 2
        let worldW = GameConfig.originalMapWorldWidth
        let worldH = GameConfig.originalMapWorldHeight

        let lowerX = halfW
        let upperX = worldW - halfW
        let lowerY = halfH
        let upperY = worldH - halfH

        let targetX: CGFloat
        if upperX < lowerX {
            targetX = worldW / 2
        } else {
            targetX = max(lowerX, min(upperX, player.position.x))
        }

        let targetY: CGFloat
        if upperY < lowerY {
            targetY = worldH / 2
        } else {
            targetY = max(lowerY, min(upperY, player.position.y))
        }

        cameraNode.position = CGPoint(x: targetX, y: targetY)
    }
}
