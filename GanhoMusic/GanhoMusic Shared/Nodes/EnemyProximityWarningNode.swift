//
//  EnemyProximityWarningNode.swift
//  GanhoMusic Shared
//
//  Distance-based body-contact warning ring for moving danger sources.
//

import SpriteKit

final class EnemyProximityWarningNode: SKNode {

    private let ring: SKShapeNode
    private var isPulsing = false

    init(color: UIColor = .ganhoIngameDanger) {
        ring = SKShapeNode(circleOfRadius: GameConfig.enemyDangerRingRadius)
        super.init()
        name = "enemyProximityWarning"
        zPosition = GameConfig.enemyDangerRingZPosition
        alpha = 0

        ring.strokeColor = color
        ring.lineWidth = GameConfig.enemyDangerRingLineWidth
        ring.fillColor = color.withAlphaComponent(GameConfig.enemyDangerRingFillAlpha)
        ring.zPosition = 0
        addChild(ring)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(distanceToPlayer distance: CGFloat,
                profile: DangerWarningProfile,
                alphaMultiplier: CGFloat = 1.0) {
        let start = profile.enemyWarningStartDistance
        let critical = profile.enemyWarningCriticalDistance
        guard distance <= start else {
            alpha = 0
            stopPulse()
            return
        }
        let range = max(1, start - critical)
        let t = max(0, min(1, (start - distance) / range))
        alpha = (GameConfig.enemyDangerRingMinAlpha + t * GameConfig.enemyDangerRingAlphaRange)
            * alphaMultiplier
        if t > GameConfig.enemyDangerRingPulseThreshold {
            startPulseIfNeeded()
        } else {
            stopPulse()
        }
    }

    private func startPulseIfNeeded() {
        guard !isPulsing else { return }
        isPulsing = true
        let grow = SKAction.scale(to: GameConfig.enemyDangerRingPulseScale,
                                  duration: GameConfig.enemyDangerRingPulseHalfDuration)
        let shrink = SKAction.scale(to: 1.0,
                                    duration: GameConfig.enemyDangerRingPulseHalfDuration)
        ring.run(.repeatForever(.sequence([grow, shrink])),
                 withKey: GameConfig.enemyDangerRingPulseActionKey)
    }

    private func stopPulse() {
        guard isPulsing else { return }
        isPulsing = false
        ring.removeAction(forKey: GameConfig.enemyDangerRingPulseActionKey)
        ring.setScale(1.0)
    }
}
