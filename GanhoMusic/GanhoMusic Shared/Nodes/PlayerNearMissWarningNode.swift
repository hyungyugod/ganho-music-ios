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
        ring = SKShapeNode(circleOfRadius: GameConfig.playerNearMissRingRadius)
        super.init()
        name = "playerNearMissWarning"
        zPosition = GameConfig.playerNearMissRingZPosition
        alpha = 0

        ring.strokeColor = .ganhoIngameDanger
        ring.lineWidth = GameConfig.playerNearMissRingLineWidth
        ring.fillColor = UIColor.ganhoIngameDangerDeep.withAlphaComponent(GameConfig.enemyDangerRingFillAlpha)
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
        alpha = GameConfig.playerNearMissRingMinAlpha + t * GameConfig.playerNearMissRingAlphaRange
        startPulseIfNeeded()
    }

    private func startPulseIfNeeded() {
        guard !isPulsing else { return }
        isPulsing = true
        let grow = SKAction.scale(to: GameConfig.playerNearMissRingPulseScale,
                                  duration: GameConfig.playerNearMissRingPulseHalfDuration)
        let shrink = SKAction.scale(to: 1.0,
                                    duration: GameConfig.playerNearMissRingPulseHalfDuration)
        ring.run(.repeatForever(.sequence([grow, shrink])),
                 withKey: GameConfig.playerNearMissRingPulseActionKey)
    }

    private func stopPulse() {
        guard isPulsing else { return }
        isPulsing = false
        ring.removeAction(forKey: GameConfig.playerNearMissRingPulseActionKey)
        ring.setScale(1.0)
    }
}
