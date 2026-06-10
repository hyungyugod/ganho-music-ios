//
//  NoteNode.swift
//  GanhoMusic Shared
//
//  Phase 2-3 · 분홍 음표 노드 (PhysicsCategory.note + .ganhoPinkNote 첫 활성화)
//  Phase 7-1 · 난이도별 TTL 자가 소멸 SKAction (easy=.infinity → noop, normal/hard만 부착)
//  Sprint 3 · v2 디자인 시스템 — 본체 .clear + 골드 글로우 + 골드 원 + 흰 링 + 1.4s 펄스
//  Sprint 10 Phase E · 원본 game.js drawNote (L730~L785) 12×12 픽셀 1:1 이식.
//    글로우/펄스/링 자식 전부 제거 → 음표 단일 텍스처.
//    bob 애니메이션(±2.4px y, 0.7s 주기) 인스턴스 phase 랜덤 — 동시 스폰 동조 방지.
//  R1 · Poolable 채택 — TTL 자기 파괴(removeFromParent)를 회수 콜백으로 교체.
//    텍스처는 TextureAtlasStore 캐시 경유 — 풀 예열 16회가 1회 렌더로 수렴.
//  R1 2회차 · 가독성 halo+sparkle 자식 2종(액션 없는 정적 셰이프)을 텍스처에 베이크 —
//    음표당 3→1노드(평시 노드 게이트). 시각 결과 동일(레이어 순서·좌표·색·알파 보존),
//    physicsBody 16×16(크기·비트마스크)는 byte-equal 불변.
//

import SpriteKit

/// 음표 단일 스프라이트 — 본체 16×16 픽셀아트(원본 12×12 + 2px padding) + 가독성 halo/sparkle을
/// TextureAtlasStore가 베이크한 텍스처 1장 (R1 2회차 — 자식 0개).
/// PhysicsBody는 static — player와 *contact 알림*만 받고 *collision*은 0 (통과).
/// **PhysicsBody size/category/contact/dynamic 완전 보존** (Phase E·R1 변경 금지).
final class NoteNode: SKSpriteNode, Poolable {

    // MARK: - Recycle (R1)
    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러 — unregister + pool.recycle 수행.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자기 파괴와 동일 동작).
    var recycleHandler: ((NoteNode) -> Void)?

    // MARK: - Init
    init() {
        // Sprint 10.5 Phase B — 시각/hitbox 분리. 본체 픽셀아트는 베이크 내부에서 noteSize(32)pt —
        //   사용자 요청 "사람의 반(캐릭터 32×40 대비 80%)" 유지.
        // R1 2회차 — halo 스트로크 바깥끝까지 베이크돼 sprite size는 베이크 한 변(38)으로 확대.
        //   hitboxSize = 16 — 게임 밸런스 회귀 0 (Phase E 이전 동일, 베이크와 무관하게 불변).
        let bakedSide = TextureAtlasStore.noteBakedSideLength
        let visualSize = CGSize(width: bakedSide, height: bakedSide)
        let hitboxSize = CGSize(width: 16, height: 16)
        // R1 — 원본 8분 음표 픽셀 + halo/sparkle 베이크 텍스처를 TextureAtlasStore 캐시 경유로.
        let texture = TextureAtlasStore.noteTexture()
        super.init(texture: texture, color: .clear, size: visualSize)
        name = "note"

        // PhysicsBody 부착 — static, player에게는 통과(collision=0), 알림만(contactTest).
        // **hitbox = 16×16 보존, 시각만 베이크 크기로 확대 (Sprint 10.5 Phase B / R1 2회차).**
        let body = SKPhysicsBody(rectangleOf: hitboxSize)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0                          // player를 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player     // 닿으면 알림
        physicsBody = body

        startBobbing()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Bob (Sprint 10 Phase E / R1 — init·resetForReuse 공용 추출)
    /// bob 애니메이션 ±2.4px y, 0.7s 주기. 인스턴스마다 phase 랜덤 →
    /// 같은 프레임 스폰된 음표 5개가 동조하지 않도록 분산.
    /// withKey "noteBob" 멱등 — 동일 키 재호출 시 SpriteKit이 이전 액션 자동 교체.
    private func startBobbing() {
        let phase = TimeInterval.random(in: 0..<GameplayTuning.noteBobDuration)
        let waitPhase = SKAction.wait(forDuration: phase)
        let up = SKAction.moveBy(x: 0,
                                 y: GameplayTuning.noteBobAmplitude,
                                 duration: GameplayTuning.noteBobDuration / 2)
        let down = up.reversed()
        let bob = SKAction.sequence([up, down])
        run(.sequence([waitPhase, .repeatForever(bob)]), withKey: UILayout.noteBobActionKey)
    }

    // MARK: - Apply Lifetime (Phase 7-1 / R1 — 회수 콜백화)
    /// 난이도별 TTL 자가 회수 SKAction을 1회 부착.
    /// 가드: `ttl.isFinite, ttl < gameDuration` — easy(.infinity) / 게임 길이 초과 모두 noop으로 처리.
    /// easy일 때는 SKAction 부착 자체가 0건 → 기존 동작 정확 보존(회귀 0, 주의사항 2).
    /// SpawnSystem.spawnNote에서 addChild 직후 1회 호출. withKey 사용으로 멱등(중복 호출 시 자동 교체).
    /// R1 — 마지막 단계가 removeFromParent → requestRecycle (풀 회수)로 교체.
    func applyLifetime(_ ttl: TimeInterval) {
        guard ttl.isFinite, ttl < GameplayTuning.gameDuration else { return }
        let wait    = SKAction.wait(forDuration: ttl)
        let fade    = SKAction.fadeOut(withDuration: 0.2)
        let recycle = SKAction.run { [weak self] in self?.requestRecycle() }
        run(.sequence([wait, fade, recycle]), withKey: UILayout.noteLifetimeActionKey)
    }

    // MARK: - Poolable (R1)
    /// 회수 단일 진입점 — TTL 만료 등 노드 자신이 시작하는 회수가 이 메서드로 수렴.
    func requestRecycle() {
        if let handler = recycleHandler {
            handler(self)
        } else {
            removeFromParent()
        }
    }

    /// 재사용 직전 신품 복원: 잔존 TTL/pull/bob 액션 제거 → 시각 상태 원복 → bob 재시작
    /// (init과 동일하게 phase 랜덤 — 재사용 노드도 신품과 같은 분산 정책).
    /// R1 2회차 — halo/sparkle이 텍스처에 베이크돼 자식 0개: 자식 리셋 항목 자체가 없음
    /// (베이크 전에도 두 자식은 정적이라 리셋 코드 0건이었음 — 본체 상태 복원만으로 신품 동등).
    func resetForReuse() {
        removeAllActions()
        alpha = 1
        setScale(1)
        position = .zero
        physicsBody?.velocity = .zero
        startBobbing()
    }
}
