//
//  FProjectileNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase D · 수간호사 F 투사체 (원본 1:1 픽셀)
//
//  원본 game.js L783~L812 byte-equal — 12×12 픽셀 매트릭스, #ff3b4e.
//  PhysicsBody 16×16 hitbox 보존 (기존 ProjectileNode와 동일 정책 — collision=0 통과).
//  ContactRouter 호환을 위해 name="projectile" 유지 — onProjectileHitPlayer/Wall 콜백이 그대로 작동.
//  EnemyNode.fireF()가 인스턴스 생성 후 world에 addChild — SpawnSystem 발사 루프 폐기됨(Sprint 10 Phase D).
//

import SpriteKit
import UIKit

/// F 투사체. 수간호사가 fireF()에서 burst 단위로 발사.
/// - PixelSpriteRenderer.fProjectileTexture()로 12×12 매트릭스 → SKTexture 변환 후 시각 노출.
/// - PhysicsBody는 축정렬 16×16 (시각 24pt와 분리) — 기존 ProjectileNode hitbox 정확 보존(회귀 0).
/// - collision=0(벽 통과) + contact=player|wall → 닿으면 ContactRouter가 분기, 노드는 SKAction.removeFromParent로 정리.
/// - name="projectile" — ContactRouter.onProjectileHitPlayer/Wall과 SpawnSystem.stop()의 enumerateChildNodes 둘 다 그대로 동작.
final class FProjectileNode: SKSpriteNode {

    // MARK: - Enchanted State
    /// 매혹 상태. true면 F가 *수집 가능한 A*로 분류 — 닿으면 점수 가산 + 제거.
    /// SkillSystem이 임간호 .charmStudent 발동/만료 시점에 일괄 토글.
    /// 시각은 texture 교체로 표현(빨강 → 분홍). PhysicsBody hitbox는 불변.
    private(set) var isEnchanted: Bool = false
    /// 투사체 하나당 graze 보상은 1회만 지급한다.
    private(set) var didAwardGraze: Bool = false
    private let haloNode: SKShapeNode
    private let outlineNode: SKShapeNode
    private var isNearMissPulsing = false

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
        let texture = PixelSpriteRenderer.fProjectileTexture(color: GameConfig.fProjectileColor)
        haloNode = SKShapeNode(circleOfRadius: GameConfig.projectileDangerHaloRadius)
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
        texture = PixelSpriteRenderer.fProjectileTexture(color: GameConfig.aItemColor)
        haloNode.strokeColor = UIColor.ganhoIngameRewardMint
            .withAlphaComponent(GameConfig.projectileDangerHaloAlpha)
        haloNode.fillColor = UIColor.ganhoIngameReward
            .withAlphaComponent(GameConfig.ingameObjectHaloAlpha)
        outlineNode.strokeColor = .ganhoPixelHudWhite
    }

    /// 매혹 해제. texture를 원색(빨강)으로 복원.
    func clearEnchanted() {
        isEnchanted = false
        texture = PixelSpriteRenderer.fProjectileTexture(color: GameConfig.fProjectileColor)
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(GameConfig.projectileDangerHaloAlpha)
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(GameConfig.ingameObjectHaloAlpha)
        outlineNode.strokeColor = .ganhoPixelOutlineBlack
    }

    func markGrazeAwarded() -> Bool {
        guard !didAwardGraze else { return false }
        didAwardGraze = true
        return true
    }

    // MARK: - Readability
    private func configureReadabilityNodes() {
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(GameConfig.projectileDangerHaloAlpha)
        haloNode.lineWidth = GameConfig.ingameObjectHaloLineWidth
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(GameConfig.ingameObjectHaloAlpha)
        haloNode.zPosition = -1
        addChild(haloNode)

        outlineNode.strokeColor = .ganhoPixelOutlineBlack
        outlineNode.lineWidth = GameConfig.projectileOutlineWidth
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
        let haloGrow = SKAction.scale(to: GameConfig.projectileNearMissPulseScale,
                                      duration: GameConfig.projectileNearMissPulseHalfDuration)
        let haloShrink = SKAction.scale(to: 1.0,
                                        duration: GameConfig.projectileNearMissPulseHalfDuration)
        let outlineGrow = SKAction.scale(to: GameConfig.projectileNearMissPulseScale,
                                         duration: GameConfig.projectileNearMissPulseHalfDuration)
        let outlineShrink = SKAction.scale(to: 1.0,
                                           duration: GameConfig.projectileNearMissPulseHalfDuration)
        haloNode.run(.repeatForever(.sequence([haloGrow, haloShrink])),
                     withKey: GameConfig.projectileNearMissPulseActionKey)
        outlineNode.run(.repeatForever(.sequence([outlineGrow, outlineShrink])),
                        withKey: GameConfig.projectileNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        haloNode.removeAction(forKey: GameConfig.projectileNearMissPulseActionKey)
        outlineNode.removeAction(forKey: GameConfig.projectileNearMissPulseActionKey)
        haloNode.setScale(1.0)
        outlineNode.setScale(1.0)
    }
}
