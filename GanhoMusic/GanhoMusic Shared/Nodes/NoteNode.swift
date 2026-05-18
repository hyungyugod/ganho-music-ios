//
//  NoteNode.swift
//  GanhoMusic Shared
//
//  Phase 2-3 · 분홍 음표 노드 (PhysicsCategory.note + .ganhoPinkNote 첫 활성화)
//  Phase 7-1 · 난이도별 TTL 자가 소멸 SKAction (easy=.infinity → noop, normal/hard만 부착)
//

import SpriteKit

/// 분홍 16×16 음표 ♪. 맵에 떠 있고, 박스(PlayerNode)가 닿으면 사라짐.
/// PhysicsBody는 static — player와 *contact 알림*만 받고 *collision*은 0 (통과).
/// 본 단계가 collision↔contact 분리의 첫 사례.
final class NoteNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.noteSize, height: GameConfig.noteSize)
        super.init(texture: nil, color: .ganhoPinkNote, size: size)
        name = "note"

        // PhysicsBody 부착 — static, player에게는 통과(collision=0), 알림만(contactTest)
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0                          // player를 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player     // 닿으면 알림
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Apply Lifetime (Phase 7-1)
    /// 난이도별 TTL 자가 소멸 SKAction을 1회 부착.
    /// 가드: `ttl.isFinite, ttl < gameDuration` — easy(.infinity) / 게임 길이 초과 모두 noop으로 처리.
    /// easy일 때는 SKAction 부착 자체가 0건 → 기존 동작 정확 보존(회귀 0, 주의사항 2).
    /// SpawnSystem.trySpawnNote에서 addChild 직후 1회 호출. withKey 사용으로 멱등(중복 호출 시 자동 교체).
    func applyLifetime(_ ttl: TimeInterval) {
        guard ttl.isFinite, ttl < GameConfig.gameDuration else { return }
        let wait   = SKAction.wait(forDuration: ttl)
        let fade   = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        run(.sequence([wait, fade, remove]), withKey: "noteLifetime")
    }
}
