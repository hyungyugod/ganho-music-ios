//
//  PlayerNearMissWarningNode.swift
//  GanhoMusic Shared
//
//  Player-centered near-miss warning ring for incoming projectile danger.
//

import SpriteKit

final class PlayerNearMissWarningNode: SKNode {

    private let ring: SKShapeNode
    private var isPulsing = false

    override init() {
        ring = SKShapeNode(circleOfRadius: GameplayTuning.playerNearMissRingRadius)
        super.init()
        name = "playerNearMissWarning"
        zPosition = ZOrder.playerNearMissRingZPosition
        alpha = 0

        ring.strokeColor = .ganhoIngameDanger
        ring.lineWidth = GameplayTuning.playerNearMissRingLineWidth
        ring.fillColor = UIColor.ganhoIngameDangerDeep.withAlphaComponent(GameplayTuning.enemyDangerRingFillAlpha)
        ring.zPosition = 0
        addChild(ring)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(closestProjectileDistance distance: CGFloat?, profile: DangerWarningProfile) {
        guard let distance = distance, distance <= profile.projectileNearMissRadius else {
            alpha = 0
            stopPulse()
            return
        }
        let t = max(0, min(1, (profile.projectileNearMissRadius - distance) / profile.projectileNearMissRadius))
        alpha = GameplayTuning.playerNearMissRingMinAlpha + t * GameplayTuning.playerNearMissRingAlphaRange
        startPulseIfNeeded()
    }

    private func startPulseIfNeeded() {
        guard !isPulsing else { return }
        isPulsing = true
        let grow = SKAction.scale(to: GameplayTuning.playerNearMissRingPulseScale,
                                  duration: GameplayTuning.playerNearMissRingPulseHalfDuration)
        let shrink = SKAction.scale(to: 1.0,
                                    duration: GameplayTuning.playerNearMissRingPulseHalfDuration)
        ring.run(.repeatForever(.sequence([grow, shrink])),
                 withKey: GameplayTuning.playerNearMissRingPulseActionKey)
    }

    private func stopPulse() {
        guard isPulsing else { return }
        isPulsing = false
        ring.removeAction(forKey: GameplayTuning.playerNearMissRingPulseActionKey)
        ring.setScale(1.0)
    }
}
