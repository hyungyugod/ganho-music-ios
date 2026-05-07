//
//  EnemyNode.swift
//  GanhoMusic Shared
//
//  Phase 2-6 · 수간호사 적 NPC (직선 추적 AI + 접촉 시 게임오버)
//

import SpriteKit

/// 수간호사 적 NPC. GameScene이 매 프레임 update(deltaTime:targetPosition:)을 호출하면
/// player를 향해 정규화 벡터 × enemyBaseSpeed로 velocity 갱신. 직선 추적.
/// PlayerNode 패턴(2-2) 정확 일치 — dynamic body, gravity/friction/damping 0.
final class EnemyNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.enemyWidth,
            height: GameConfig.enemyHeight
        )
        super.init(texture: nil, color: .ganhoBloodAccent, size: size)
        name = "enemy"

        // PhysicsBody 부착 — PlayerNode와 동일 정책(dynamic, 회전/마찰/탄성/감쇠 0).
        // collision은 wall만(외곽 벽/중앙 기둥에 막힘), contactTest는 player(닿으면 알림).
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.enemy
        body.collisionBitMask    = PhysicsCategory.wall    // 벽/기둥에 막힘
        body.contactTestBitMask  = PhysicsCategory.player  // player와 닿으면 알림
        physicsBody = body

        // Phase 2-6 hotfix 1 — 다른 노드(벽/음표/기둥) 위에 항상 그려지도록 zPosition 명시.
        // HUD(100)/D-Pad(기본 0이지만 cameraNode 자식이라 별도 트리)보다 낮음 — UI를 가리지 않음.
        zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. player 위치를 향한 단위 벡터 × enemyBaseSpeed → velocity.
    /// magnitude == 0 가드(NaN 방지).
    /// - Parameters:
    ///   - deltaTime: dt — 본 sprint에서는 미사용 (velocity 기반, 엔진이 dt 처리).
    ///                Phase 2-8 시간 보간 도입 시 시그니처 추가 변경 없이 사용 가능.
    ///   - targetPosition: 추적 대상 좌표(worldNode 좌표계). 보통 player.position.
    func update(deltaTime: TimeInterval, targetPosition: CGPoint) {
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else {
            physicsBody?.velocity = .zero
            return
        }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.enemyBaseSpeed,
            dy: unitY * GameConfig.enemyBaseSpeed
        )
    }
}
