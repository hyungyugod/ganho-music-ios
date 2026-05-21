//
//  WallTileNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase C · 원본 1:1 벽 1셀(40×40pt) 단일 노드.
//  MapNode.buildWalls(difficulty:)가 색·크기·물리 정책의 단일 진입점으로 사용한다.
//  존재 이유:
//   1) 옛 GameScene+Setup의 addRectPillar(navyDeep + tileSize × N)을 픽셀 톤(wallTileColorHex)으로
//      대체하면서 1셀=40pt 격자 정합 유지.
//   2) physicsBody 정책(static, friction/restitution 0, category=wall, collision/contactTest 0)을
//      한 곳에 응집 — 외곽 + 4 모서리 방 + 중앙 기둥이 한 종류의 노드로 통일.
//   3) PhysicsCategory.wall(8) 비트는 이미 존재 — 본 노드는 *사용자*만 늘어남(주의사항 3).
//

import SpriteKit

/// 원본 game.js의 m[r][c]=1 한 셀 = 40×40pt 정적 충돌체.
/// 부모 MapNode의 zPosition(-50) 아래 자식으로 부착되며 자체 zPosition은 0(MapNode 자식 적층 기준).
/// anchorPoint .center 기본값 사용 — tileCoordinate(col:row:)의 셀 중심점과 자연 정합.
final class WallTileNode: SKSpriteNode {

    // MARK: - Lifecycle
    /// 1셀 40×40pt + 픽셀 톤 단색 + 정적 physicsBody.
    /// 텍스처 nil — Phase J 픽셀 톤 외곽 효과 도입 시 텍스처로 승격 가능.
    init() {
        let size = CGSize(
            width:  GameConfig.originalMapCellSize,
            height: GameConfig.originalMapCellSize
        )
        let color = UIColor(hex: GameConfig.wallTileColorHex)
        super.init(texture: nil, color: color, size: size)
        name = GameConfig.wallTileNodeName
        zPosition = GameConfig.wallTileZPosition

        // PhysicsBody — 옛 addRectPillar 정책과 byte-equal(주의사항 3·11).
        // isDynamic=false → 외부 힘으로 안 움직임. friction/restitution 0 → 부딪힘 시 미끄러짐 0/반사 0.
        // collisionBitMask 0 → 다른 객체가 이 노드를 밀어내지 않음(외곽 벽 정책과 일치).
        // contactTestBitMask 0 → 충돌 알림은 Player/Projectile/Stethoscope 측에서 받음(대칭).
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic          = false
        body.friction           = 0
        body.restitution        = 0
        body.categoryBitMask    = PhysicsCategory.wall
        body.collisionBitMask   = 0
        body.contactTestBitMask = 0
        physicsBody = body
    }

    /// 코더 init은 사용하지 않음 — SKS 파일이 아닌 코드 부착 전용 노드.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
