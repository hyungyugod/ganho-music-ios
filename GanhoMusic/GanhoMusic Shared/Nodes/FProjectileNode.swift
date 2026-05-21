//
//  FProjectileNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase D · 수간호사 F 투사체 (원본 1:1 픽셀)
//
//  원본 game.js L783~L812 byte-equal — 12×12 픽셀 매트릭스, #ff3b4e.
//  PhysicsBody 16×16 hitbox 보존 (기존 ProjectileNode와 동일 정책 — collision=0 통과).
//  ContactRouter 호환을 위해 name="projectile" 유지 — onProjectileHitPlayer/Wall 콜백이 그대로 작동.
//  EnemyNode.fireF()가 인스턴스 생성 후 world에 addChild — SpawnSystem 발사 루프 폐기됨(Sprint 10 Phase D).
//

import SpriteKit
import UIKit

/// F 투사체. 수간호사가 fireF()에서 burst 단위로 발사.
/// - PixelSpriteRenderer.fProjectileTexture()로 12×12 매트릭스 → SKTexture 변환 후 시각 노출.
/// - PhysicsBody는 축정렬 16×16 (시각 24pt와 분리) — 기존 ProjectileNode hitbox 정확 보존(회귀 0).
/// - collision=0(벽 통과) + contact=player|wall → 닿으면 ContactRouter가 분기, 노드는 SKAction.removeFromParent로 정리.
/// - name="projectile" — ContactRouter.onProjectileHitPlayer/Wall과 SpawnSystem.stop()의 enumerateChildNodes 둘 다 그대로 동작.
final class FProjectileNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let physicsSize = CGSize(
            width:  GameConfig.fProjectileSize,
            height: GameConfig.fProjectileSize
        )
        let visualSize = CGSize(
            width:  GameConfig.fProjectileVisualSize,
            height: GameConfig.fProjectileVisualSize
        )
        let texture = PixelSpriteRenderer.fProjectileTexture(color: GameConfig.fProjectileColor)
        super.init(texture: texture, color: .clear, size: visualSize)
        name = "projectile"   // ContactRouter 호환 (기존 onProjectileHitPlayer/Wall 콜백 재사용)
        zPosition = 5

        // PhysicsBody — 기존 ProjectileNode와 동일 정책. dynamic + collision=0(통과) + contact=player|wall.
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.projectile
        body.collisionBitMask    = 0   // 벽 통과 — 그 자리 멈춤 버그 회피
        body.contactTestBitMask  = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
