//
//  FProjectileNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase D · 수간호사 F 투사체 (원본 1:1 픽셀)
//
//  원본 game.js L783~L812 byte-equal — 12×12 픽셀 매트릭스, #ff3b4e.
//  PhysicsBody 16×16 hitbox 보존 (기존 ProjectileNode와 동일 정책 — collision=0 통과).
//  ContactRouter 호환을 위해 name="projectile" 유지 — onProjectileHitPlayer/Wall 콜백이 그대로 작동.
//  R1 · Poolable 채택 — EnemyNode.fireF()가 풀 경유 provider로 실체화하고, TTL/충돌/스킬 정리는
//    전부 회수 콜백으로 수렴. 카운트/순회는 EntityRegistry.projectiles가 담당(name enumerate 전폐).
//  R2 · 가독성 자식 2종(halo/outline) 삭제 → TextureAtlasStore 베이크 텍스처 1노드화 (자식 0 —
//    hard 평시 노드 게이트). near-miss 펄스는 자식 scale 애니 대신 normal↔pulse 베이크 변형
//    텍스처 교차 (기존 펄스 주기 상수 재사용, withKey 멱등).
//

import SpriteKit
import UIKit

/// F 투사체. 수간호사가 fireF()에서 burst 단위로 발사.
/// - 텍스처는 TextureAtlasStore 베이크 3종(normal/normal-pulse/enchanted) — halo+본체+outline 1장.
/// - PhysicsBody는 축정렬 16×16 (시각과 분리) — 기존 hitbox 정확 보존(회귀 0).
/// - collision=0(벽 통과) + contact=player|wall → 닿으면 ContactRouter가 분기, 노드는 지연 회수로 풀 복귀.
/// - name="projectile" — ContactRouter 콜백 분기와 정합(변경 금지).
final class FProjectileNode: SKSpriteNode, Poolable {

    // MARK: - Recycle (R1)
    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러 — unregister + pool.recycle 수행.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자기 파괴와 동일 동작).
    var recycleHandler: ((FProjectileNode) -> Void)?

    // MARK: - Enchanted State
    /// 매혹 상태. true면 F가 *수집 가능한 A*로 분류 — 닿으면 점수 가산 + 제거.
    /// SkillSystem이 임간호 .charmStudent 발동/만료 시점에 일괄 토글.
    /// 시각은 베이크 텍스처 교체로 표현(빨강 → 분홍). PhysicsBody hitbox는 불변.
    private(set) var isEnchanted: Bool = false
    private var isNearMissPulsing = false

    // MARK: - Near-miss Bonus Tracking (R7 §F2)
    /// R7 — 보너스 반경(22px) 진입 여부. GameScene+NearMiss 폴링이 단독 기록자 —
    /// 비무적 상태 진입 프레임에 set, 반경 밖 이탈 프레임에 1회 보상.
    var nearMissEntered: Bool = false
    /// R7 — 보상 부여 완료 (투사체 1개당 1회 상한).
    var nearMissAwarded: Bool = false

    // MARK: - Init
    init() {
        let physicsSize = CGSize(
            width:  GameplayTuning.fProjectileSize,
            height: GameplayTuning.fProjectileSize
        )
        // R2 — 시각은 베이크 한 변(halo 바깥끝 포함)의 정사각. hitbox와 무관.
        let bakedSide = TextureAtlasStore.fProjectileBakedSideLength
        let visualSize = CGSize(width: bakedSide, height: bakedSide)
        let texture = TextureAtlasStore.fProjectileBakedTexture(.normal)
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

    // MARK: - Enchanted Toggle
    /// 매혹 진입. 베이크 enchanted 텍스처로 교체. 멱등(재호출 안전). 매혹 중 펄스 없음(기존 가드).
    /// R7 §F2 — 보류 중 near-miss 진입 플래그 무효화: 매혹 F는 수집물이라 회피 보상 비대상.
    func applyEnchanted() {
        isEnchanted = true
        nearMissEntered = false
        stopNearMissPulse()
        texture = TextureAtlasStore.fProjectileBakedTexture(.enchanted)
    }

    /// 매혹 해제. 베이크 normal 텍스처로 복원.
    func clearEnchanted() {
        isEnchanted = false
        stopNearMissPulse()
        texture = TextureAtlasStore.fProjectileBakedTexture(.normal)
    }

    // MARK: - Wall Policy / Lifetime
    func applyWallPolicy(passesWalls: Bool) {
        physicsBody?.contactTestBitMask = passesWalls
            ? PhysicsCategory.player
            : PhysicsCategory.player | PhysicsCategory.wall
    }

    /// R1 — TTL 만료 시 removeFromParent → requestRecycle(풀 회수)로 교체. 발사 시점마다
    /// EnemyNode가 재호출하므로 withKey 멱등 + 재사용 노드의 잔존 TTL은 resetForReuse가 차단.
    func applyLifetime(_ lifetime: TimeInterval) {
        guard lifetime.isFinite, lifetime > 0 else { return }
        removeAction(forKey: GameplayTuning.projectileLifetimeActionKey)
        let recycle = SKAction.run { [weak self] in self?.requestRecycle() }
        run(.sequence([
            .wait(forDuration: lifetime),
            recycle
        ]), withKey: GameplayTuning.projectileLifetimeActionKey)
    }

    // MARK: - Poolable (R1)
    /// 회수 단일 진입점 — TTL 만료/purge/스킬 정화 등 모든 회수 요청이 이 메서드로 수렴.
    func requestRecycle() {
        if let handler = recycleHandler {
            handler(self)
        } else {
            removeFromParent()
        }
    }

    /// 재사용 직전 신품 복원: 잔존 TTL 액션 제거 → near-miss 펄스 정리 → 매혹 해제(normal
    /// 베이크 텍스처 복원) → 시각/물리 원복. wallPolicy는 발사 시점에 EnemyNode가 매회 재적용.
    /// R7 §F2 — near-miss 추적 플래그 2종도 반드시 리셋 (반경 안에서 회수된 노드의 보류 상태가
    /// 다음 사용자에게 새면 발사 직후 오발 보상 — SPEC §F2 풀 재사용 리셋 게이트).
    func resetForReuse() {
        removeAllActions()
        stopNearMissPulse()
        clearEnchanted()
        nearMissEntered = false
        nearMissAwarded = false
        alpha = 1
        setScale(1)
        position = .zero
        physicsBody?.velocity = .zero
    }

    // MARK: - Near-miss Pulse (R2 — 자식 0, 베이크 변형 텍스처 교차)
    func updateNearMissWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        guard !isEnchanted, distance <= profile.projectileNearMissRadius else {
            stopNearMissPulse()
            return
        }
        startNearMissPulseIfNeeded()
    }

    /// normal↔pulse 베이크 교차 — 구 자식 scale 펄스(halo/outline ×1.22, 0.08s 반주기)의 텍스처판.
    /// setTexture(resize: false) — sprite size 불변, 베이크 두 장이 같은 캔버스 한 변을 공유.
    private func startNearMissPulseIfNeeded() {
        guard !isNearMissPulsing else { return }
        isNearMissPulsing = true
        let half = GameplayTuning.projectileNearMissPulseHalfDuration
        let toPulse = SKAction.setTexture(
            TextureAtlasStore.fProjectileBakedTexture(.normalPulse), resize: false)
        let toNormal = SKAction.setTexture(
            TextureAtlasStore.fProjectileBakedTexture(.normal), resize: false)
        let cycle = SKAction.sequence([
            toPulse, .wait(forDuration: half),
            toNormal, .wait(forDuration: half)
        ])
        run(.repeatForever(cycle), withKey: GameplayTuning.projectileNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        removeAction(forKey: GameplayTuning.projectileNearMissPulseActionKey)
        texture = TextureAtlasStore.fProjectileBakedTexture(isEnchanted ? .enchanted : .normal)
    }
}
