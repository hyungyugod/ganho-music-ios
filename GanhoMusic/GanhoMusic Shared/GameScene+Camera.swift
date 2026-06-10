//
//  GameScene+Camera.swift
//  GanhoMusic Shared
//
//  Camera follow — R2부터 CameraDirector 위임 (02_GAME_FEEL §3).
//  지수 보간 추적 + 맵 클램프(기존 halfW/halfH·중앙 폴백 시맨틱 보존) + 셰이크/킥 합성은
//  CameraDirector.update(dt:)가 cameraNode.position의 단일 기록 지점.
//

import SpriteKit

// MARK: - Camera Follow
extension GameScene {
    func updateCameraFollow(dt: TimeInterval) {
        cameraDirector.update(dt: dt)
    }
}
