//
//  NoteNode.swift
//  GanhoMusic Shared
//
//  Phase 2-3 · 분홍 음표 노드 (PhysicsCategory.note + .ganhoPinkNote 첫 활성화)
//  Phase 7-1 · 난이도별 TTL 자가 소멸 SKAction (easy=.infinity → noop, normal/hard만 부착)
//  Sprint 3 · v2 디자인 시스템 — 본체 .clear + 골드 글로우 + 골드 원 + 흰 링 + 1.4s 펄스
//

import SpriteKit

/// 분홍 16×16 음표 ♪. 맵에 떠 있고, 박스(PlayerNode)가 닿으면 사라짐.
/// PhysicsBody는 static — player와 *contact 알림*만 받고 *collision*은 0 (통과).
/// 본 단계가 collision↔contact 분리의 첫 사례.
/// Sprint 3 — SKSpriteNode 본체는 .clear, 시각은 자식 3개(glow + core + 펄스)로 위임.
/// **PhysicsBody size/category/contact/dynamic 완전 보존.**
final class NoteNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.noteSize, height: GameConfig.noteSize)
        // Sprint 3 — 본체 색은 .clear. 시각은 자식 SKShapeNode 3개로 위임.
        super.init(texture: nil, color: .clear, size: size)
        name = "note"

        // PhysicsBody 부착 — static, player에게는 통과(collision=0), 알림만(contactTest)
        // **size = noteSize² (16×16) 절대 보존.**
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0                          // player를 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player     // 닿으면 알림
        physicsBody = body

        // Sprint 3 — 시각 자식 3개. 펄스 SKAction은 init 끝에 1회 부착(멱등 키).

        // 1. 글로우 — 본체 뒤(z=-1)에 골드 α 0.5 큰 원. blendMode=.add로 밝게 빛남.
        let glow = SKShapeNode(circleOfRadius: GameConfig.noteV2GlowRadius)
        glow.fillColor = UIColor.ganhoMusicGold.withAlphaComponent(GameConfig.noteV2GlowAlpha)
        glow.strokeColor = .clear
        glow.zPosition = -1
        glow.blendMode = .add
        addChild(glow)

        // 2. 본체 골드 원 — noteSize/2 반지름. strokeColor=흰 ring(lineWidth=2).
        let core = SKShapeNode(circleOfRadius: GameConfig.noteSize / 2)
        core.fillColor = .ganhoMusicGold
        core.strokeColor = .white
        core.lineWidth = GameConfig.noteV2RingLineWidth
        core.zPosition = 0
        addChild(core)

        // 3. 펄스 — 1.4초 1주기 scaleUp + scaleDown. withKey 멱등.
        let scaleUp = SKAction.scale(
            to: GameConfig.noteV2PulseScale,
            duration: GameConfig.noteV2PulseDuration / 2
        )
        let scaleDown = SKAction.scale(
            to: 1.0,
            duration: GameConfig.noteV2PulseDuration / 2
        )
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        run(.repeatForever(pulse), withKey: GameConfig.noteV2PulseActionKey)
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
