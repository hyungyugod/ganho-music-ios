//
//  AItemNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase D · 임간호 매혹 활성 시 F가 A로 변환된 수집형 아이템 (원본 1:1 픽셀)
//
//  원본 game.js drawAItem byte-equal — 12×12 픽셀 매트릭스, #ff6fa8.
//  PhysicsBody 16×16 hitbox — F와 동일 (수집 판정 동일 손맛).
//  ContactRouter 신규 비트(aItem = 256) — onAItemCollected/onAItemHitWall 콜백으로 분기.
//  EnemyNode.fireF()가 isCharmed=true 분기에서 F 대신 인스턴스 생성.
//
//  분기 영속성: 발사 시점 매혹 여부로 결정 — 매혹 만료 후에도 화면에 남은 A는 계속 A 유지.
//  SkillSystem.onDurationExpired charmStudent 케이스의 enumerateChildNodes(withName: "projectile")는
//  A 노드(name="aItem")와 0 매치 — 자연 noop (SPEC §5).
//

import SpriteKit
import UIKit

/// 수집형 A 아이템. 임간호 매혹 활성 중 수간호사가 발사한 F가 시각·게임플레이 모두 A로 변환된 결과.
/// - 12×12 픽셀 매트릭스, 분홍 #ff6fa8.
/// - PhysicsBody 16×16 (F와 동일).
/// - collision=0(벽 통과 시 onAItemHitWall로 정리), contact=player|wall.
/// - 수집 시 ContactRouter.onAItemCollected → ScoreSystem.recordCharmedNoteHit (×2 가산) + SKAction.removeFromParent.
final class AItemNode: SKSpriteNode {

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
        let texture = PixelSpriteRenderer.aItemTexture(color: GameConfig.aItemColor)
        super.init(texture: texture, color: .clear, size: visualSize)
        name = "aItem"   // ContactRouter handleAItemContact 분기 키 + GameScene+Setup의 enumerate 키
        zPosition = 5

        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.aItem
        body.collisionBitMask    = 0   // 벽 통과 — onAItemHitWall에서 노드 정리
        body.contactTestBitMask  = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
