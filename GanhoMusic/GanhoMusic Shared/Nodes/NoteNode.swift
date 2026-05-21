//
//  NoteNode.swift
//  GanhoMusic Shared
//
//  Phase 2-3 · 분홍 음표 노드 (PhysicsCategory.note + .ganhoPinkNote 첫 활성화)
//  Phase 7-1 · 난이도별 TTL 자가 소멸 SKAction (easy=.infinity → noop, normal/hard만 부착)
//  Sprint 3 · v2 디자인 시스템 — 본체 .clear + 골드 글로우 + 골드 원 + 흰 링 + 1.4s 펄스
//  Sprint 10 Phase E · 원본 game.js drawNote (L730~L785) 12×12 픽셀 1:1 이식.
//    글로우/펄스/링 자식 전부 제거 → PixelSpriteRenderer.notePixelTexture() 단일 텍스처.
//    bob 애니메이션(±2.4px y, 0.7s 주기) 인스턴스 phase 랜덤 — 동시 스폰 동조 방지.
//

import SpriteKit

/// 음표 16×16 — 원본 12×12 픽셀 매트릭스 + ox/oy 2px padding으로 16×16 SKTexture.
/// PhysicsBody는 static — player와 *contact 알림*만 받고 *collision*은 0 (통과).
/// **PhysicsBody size/category/contact/dynamic 완전 보존** (Phase E 변경 금지).
final class NoteNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.noteSize, height: GameConfig.noteSize)
        // Sprint 10 Phase E — 원본 8분 음표 픽셀 텍스처. 글로우/펄스/링 자식 0개.
        let texture = PixelSpriteRenderer.notePixelTexture()
        super.init(texture: texture, color: .clear, size: size)
        name = "note"

        // PhysicsBody 부착 — static, player에게는 통과(collision=0), 알림만(contactTest).
        // **size = noteSize² (16×16) 절대 보존.**
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0                          // player를 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player     // 닿으면 알림
        physicsBody = body

        // Sprint 10 Phase E — bob 애니메이션 ±2.4px y, 0.7s 주기.
        // 인스턴스마다 phase 랜덤 → 같은 프레임 스폰된 음표 5개가 동조하지 않도록 분산.
        // withKey "noteBob" 멱등 — 동일 키 재호출 시 SpriteKit이 이전 액션 자동 교체.
        let phase = TimeInterval.random(in: 0..<GameConfig.noteBobDuration)
        let waitPhase = SKAction.wait(forDuration: phase)
        let up = SKAction.moveBy(x: 0,
                                 y: GameConfig.noteBobAmplitude,
                                 duration: GameConfig.noteBobDuration / 2)
        let down = up.reversed()
        let bob = SKAction.sequence([up, down])
        run(.sequence([waitPhase, .repeatForever(bob)]), withKey: "noteBob")
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
