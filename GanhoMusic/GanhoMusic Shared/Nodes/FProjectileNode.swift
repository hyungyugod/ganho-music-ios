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
//

import SpriteKit
import UIKit

/// F 투사체. 수간호사가 fireF()에서 burst 단위로 발사.
/// - 텍스처는 TextureAtlasStore 캐시 경유(원색/매혹 2종) — 12×12 매트릭스 렌더 결과 byte-equal.
/// - PhysicsBody는 축정렬 16×16 (시각 24pt와 분리) — 기존 ProjectileNode hitbox 정확 보존(회귀 0).
/// - collision=0(벽 통과) + contact=player|wall → 닿으면 ContactRouter가 분기, 노드는 지연 회수로 풀 복귀.
/// - name="projectile" — ContactRouter 콜백 분기와 정합(R1 변경 금지).
final class FProjectileNode: SKSpriteNode, Poolable {

    // MARK: - Recycle (R1)
    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러 — unregister + pool.recycle 수행.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자기 파괴와 동일 동작).
    var recycleHandler: ((FProjectileNode) -> Void)?

    // MARK: - Enchanted State
    /// 매혹 상태. true면 F가 *수집 가능한 A*로 분류 — 닿으면 점수 가산 + 제거.
    /// SkillSystem이 임간호 .charmStudent 발동/만료 시점에 일괄 토글.
    /// 시각은 texture 교체로 표현(빨강 → 분홍). PhysicsBody hitbox는 불변.
    private(set) var isEnchanted: Bool = false
    private let haloNode: SKShapeNode
    private let outlineNode: SKShapeNode
    private var isNearMissPulsing = false

    // MARK: - Init
    init() {
        let physicsSize = CGSize(
            width:  GameplayTuning.fProjectileSize,
            height: GameplayTuning.fProjectileSize
        )
        let visualSize = CGSize(
            width:  GameplayTuning.fProjectileVisualSize,
            height: GameplayTuning.fProjectileVisualSize
        )
        let texture = TextureAtlasStore.fProjectileTexture(enchanted: false)
        haloNode = SKShapeNode(circleOfRadius: UILayout.projectileDangerHaloRadius)
        outlineNode = SKShapeNode(rectOf: visualSize)
        super.init(texture: texture, color: .clear, size: visualSize)
        name = "projectile"   // ContactRouter 호환 (기존 onProjectileHitPlayer/Wall 콜백 재사용)
        zPosition = 5
        configureReadabilityNodes()

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
    /// 매혹 진입. texture를 분홍(.ganhoPinkNote)으로 교체. 멱등(재호출 안전).
    func applyEnchanted() {
        isEnchanted = true
        texture = TextureAtlasStore.fProjectileTexture(enchanted: true)
        haloNode.strokeColor = UIColor.ganhoIngameRewardMint
            .withAlphaComponent(UILayout.projectileDangerHaloAlpha)
        haloNode.fillColor = UIColor.ganhoIngameReward
            .withAlphaComponent(UILayout.ingameObjectHaloAlpha)
        outlineNode.strokeColor = .ganhoPixelHudWhite
    }

    /// 매혹 해제. texture를 원색(빨강)으로 복원.
    func clearEnchanted() {
        isEnchanted = false
        texture = TextureAtlasStore.fProjectileTexture(enchanted: false)
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(UILayout.projectileDangerHaloAlpha)
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(UILayout.ingameObjectHaloAlpha)
        outlineNode.strokeColor = .ganhoPixelOutlineBlack
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

    /// 재사용 직전 신품 복원: 잔존 TTL 액션 제거 → near-miss 펄스 정리(자식 halo/outline
    /// 액션·scale 원복) → 매혹 해제(원색 텍스처/halo/outline — clearEnchanted 시맨틱) → 시각/물리 원복.
    /// wallPolicy(contactTestBitMask)는 발사 시점에 EnemyNode가 매회 applyWallPolicy로 재적용 — 리셋 불요.
    func resetForReuse() {
        removeAllActions()
        stopNearMissPulse()
        clearEnchanted()
        alpha = 1
        setScale(1)
        position = .zero
        physicsBody?.velocity = .zero
    }

    // MARK: - Readability
    private func configureReadabilityNodes() {
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(UILayout.projectileDangerHaloAlpha)
        haloNode.lineWidth = UILayout.ingameObjectHaloLineWidth
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(UILayout.ingameObjectHaloAlpha)
        haloNode.zPosition = -1
        addChild(haloNode)

        outlineNode.strokeColor = .ganhoPixelOutlineBlack
        outlineNode.lineWidth = UILayout.projectileOutlineWidth
        outlineNode.fillColor = .clear
        outlineNode.zPosition = 1
        addChild(outlineNode)
    }

    func updateNearMissWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        guard !isEnchanted, distance <= profile.projectileNearMissRadius else {
            stopNearMissPulse()
            return
        }
        startNearMissPulseIfNeeded()
    }

    private func startNearMissPulseIfNeeded() {
        guard !isNearMissPulsing else { return }
        isNearMissPulsing = true
        let haloGrow = SKAction.scale(to: GameplayTuning.projectileNearMissPulseScale,
                                      duration: GameplayTuning.projectileNearMissPulseHalfDuration)
        let haloShrink = SKAction.scale(to: 1.0,
                                        duration: GameplayTuning.projectileNearMissPulseHalfDuration)
        let outlineGrow = SKAction.scale(to: GameplayTuning.projectileNearMissPulseScale,
                                         duration: GameplayTuning.projectileNearMissPulseHalfDuration)
        let outlineShrink = SKAction.scale(to: 1.0,
                                           duration: GameplayTuning.projectileNearMissPulseHalfDuration)
        haloNode.run(.repeatForever(.sequence([haloGrow, haloShrink])),
                     withKey: GameplayTuning.projectileNearMissPulseActionKey)
        outlineNode.run(.repeatForever(.sequence([outlineGrow, outlineShrink])),
                        withKey: GameplayTuning.projectileNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        haloNode.removeAction(forKey: GameplayTuning.projectileNearMissPulseActionKey)
        outlineNode.removeAction(forKey: GameplayTuning.projectileNearMissPulseActionKey)
        haloNode.setScale(1.0)
        outlineNode.setScale(1.0)
    }
}
