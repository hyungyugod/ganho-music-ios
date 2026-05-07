//
//  ProjectileNode.swift
//  GanhoMusic Shared
//
//  Phase 2-7 · F 투사체 (수간호사가 player 방향으로 발사)
//

import SpriteKit

/// F 투사체. 발사 시점 player 위치 향한 단위 벡터 × projectileSpeed velocity.
/// 벽/player와 contact 알림. collision=0(통과). GDD §7-5.
final class ProjectileNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.projectileSize, height: GameConfig.projectileSize)
        super.init(texture: nil, color: .ganhoYellowF, size: size)
        name = "projectile"
        zPosition = 5

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.projectile
        body.collisionBitMask    = 0   // 통과 (벽에 막혀서 그 자리에 멈추는 버그 회피)
        body.contactTestBitMask  = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
