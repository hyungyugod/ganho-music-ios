//
//  StoneGuardNode.swift
//  GanhoMusic Shared
//
//  Phase 4-1 · 석조무사 NPC — 4 waypoint 시계방향 패트롤 (SKAction)
//  GDD §7-6: 맵 4지점 사각 순환, 55 px/s, 본 sprint는 시각 등장만 (PhysicsBody 없음).
//  Phase 4-2 · PhysicsBody 부착 (collision=0 통과형, contactTest=.player)
//

import SpriteKit

/// 석조무사 NPC. 추적 AI(EnemyNode)와 달리 *정해진 길*만 걷는 두 번째 AI 패턴.
/// init 시점에 startPatrol()을 호출 — SKAction.repeatForever(.sequence([.move × 4]))으로
/// 4 waypoint를 시계방향으로 무한 순회한다. 본 sprint는 PhysicsBody 미부착(시각 등장만).
final class StoneGuardNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.stoneGuardWidth,
            height: GameConfig.stoneGuardHeight
        )
        // 색상: 수간호사(.ganhoBloodAccent 빨강)와의 시각 대비. 새 ColorTokens 신설 금지 — .ganhoPaper 재사용.
        super.init(texture: nil, color: .ganhoPaper, size: size)
        name = "stoneGuard"
        // EnemyNode와 동일한 zPosition 5 — 다른 노드(벽/음표/기둥) 위에 그려짐.
        zPosition = 5

        // Phase 4-2 — PhysicsBody 부착. EnemyNode 패턴 답습하되 collision=0(통과형).
        // patrol은 SKAction.move 기반 → isDynamic=false (velocity 미사용).
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.stoneGuard
        body.collisionBitMask    = 0                            // 통과형 — 아무도 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player       // player와 닿으면 알림
        physicsBody = body

        startPatrol()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Patrol
    /// 4 waypoint 시계방향 무한 순환 SKAction을 self.run으로 실행.
    /// init 시점 호출 — setupStoneGuard()가 (200, 100)에 노드를 둔 직후 worldNode 트리에 들어가면
    /// 첫 .move(to: w[1])부터 자동으로 (760, 100)을 향해 시작된다.
    private func startPatrol() {
        let waypoints = GameConfig.stoneGuardWaypoints
        var moves: [SKAction] = []
        for i in 0..<waypoints.count {
            let from = waypoints[i]
            let to   = waypoints[(i + 1) % waypoints.count]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameConfig.stoneGuardSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop)
    }
}
